---
layout: bootcamp
title: 在 gem5 中开发 SimObjects
permalink: /bootcamp/developing-gem5/extending-gem5-models
section: developing-gem5
---
<!-- _class: title -->

## 扩展 gem5 模型的有用工具

---

## gem5 的隐藏功能

gem5 内部有许多有用的工具，但没有适当的文档。
在本节中，我们将介绍

- 探针点（Probe point）
<!-- - Bitset
- Random number generation -->
<!-- - Signal ports? a big maybe. if I have extra time I'll dive in to gem5/src/dev/IntPin.py -->

### 行动提示

如果您从未构建过 /gem5/build/X86/gem5.fast，请使用以下命令进行构建，因为 gem5 需要很长时间才能构建完成。

```bash
cd gem5
scons build/X86/gem5.fast -j$(nproc)
```

---

<!-- _class: start -->

## 探针点（Probe Point）

---

## 探针点（Probe Point）

gem5 中与探针点相关的三个组件：

1. [ProbeManger](https://github.com/gem5/gem5/blob/stable/src/sim/probe/probe.hh#L163)
2. [ProbePoint](https://github.com/gem5/gem5/blob/stable/src/sim/probe/probe.hh#L146)
3. [ProbeListener](https://github.com/gem5/gem5/blob/stable/src/sim/probe/probe.hh#L126)

### 探针点的用例

- 在不向组件代码库添加太多内容的情况下分析组件
- 创建更灵活的退出事件
- 跟踪高级行为
- 更多用途

---

<!-- _class: center-image -->

## 关于探针点的更多信息

- 每个 SimObject 都有一个 ProbeManager
- ProbeManager 管理 SimObject 的所有已注册 ProbePoint 和连接的 ProbeListener
- 一个 ProbePoint 可以通知多个 ProbeListener，一个 ProbeListener 可以监听多个 ProbePoint
- 一个 ProbeListener 只能附加到一个 SimObject

![](/bootcamp/03-Developing-gem5-models/09-extending-gem5-models-imgs/probepoint-diagram.drawio.svg)

---

## 如何使用探针点？

1. 在 SimObject 中创建一个 ProbePoint
2. 将 ProbePoint 注册到 SimObject 的 ProbeManager
3. 创建一个 ProbeListener
4. 将 ProbeListener 连接到 SimObject 并将其注册到 SimObject 的 ProbeManager

让我们用一个简单的例子来试试！

---

## 动手实践时间！

### 01-local-inst-tracker

目前，gem5 没有直接的方法在多核仿真中执行（提交）一定数量的指令后触发退出事件。我们可以使用探针点轻松创建一个。我们将首先创建一个监听每个核心 `ppRetiredInsts` ProbePoint 的 ProbeListener，然后在 `02-global-inst-tracker` 中，我们将创建一个 SimObject 来管理所有 ProbeListener，以便在仿真执行（提交）一定数量的指令后触发退出事件。

### 目标

1. 创建一个名为 local-instruction-tracker 的 ProbeListener
2. 将 ProbeListener 连接到 BaseCPU，并将我们的 ProbeListener 注册到 BaseCPU 的 ProbeManager
3. 使用 local-instruction-tracker 运行一个简单的仿真

---

## 动手实践时间！

### 01-local-inst-tracker

所有完成的材料可以在 [`materials/03-Developing-gem5-models/09-extending-gem5-models/01-local-inst-tracker/complete`](/materials/03-Developing-gem5-models/09-extending-gem5-models/01-local-inst-tracker/complete) 下找到。

让我们开始在 `/src/cpu/probes` 下创建 `inst_tracker.hh` 和 `inst_tacker.cc`。

在 `inst_tracker.hh` 文件中，我们需要包含头文件和必要的库：

```cpp
#ifndef __CPU_PROBES_INST_TRACKER_HH__
#define __CPU_PROBES_INST_TRACKER_HH__

#include "sim/sim_exit.hh"
#include "sim/probe/probe.hh"
#include "params/LocalInstTracker.hh"
```

---

## 01-local-inst-tracker

然后，我们可以创建一个名为 `LocalInstTracker` 的 `ProbeListenerObject`。`ProbeListenerObject` 是 `ProbeListener` 的最小包装器，允许我们将其附加到要监听的 SimObject。

```cpp
namespace gem5
{
class LocalInstTracker : public ProbeListenerObject
{
  public:
    LocalInstTracker(const LocalInstTrackerParams &params);
    virtual void regProbeListeners();
}
}
```

现在，我们有了 `LocalInstTracker` 的构造函数和一个虚函数 `regProbeListeners()`。`regProbeListeners` 在仿真开始时自动调用。我们将使用它来附加到 ProbePoint。

---

## 01-local-inst-tracker

我们的目标是计算附加核心已提交的指令数量，因此我们可以监听 `BaseCPU` SimObject 中已存在的 `ppRetiredInsts` ProbePoint。

让我们看一下 `ppRetiredInsts` ProbePoint。
它是一个 `PMU probe point`，如 [src/cpu/base.hh](https://github.com/gem5/gem5/blob/stable/src/sim/probe/pmu.hh) 中所示，它将使用 `uint64_t` 变量通知监听器。
在 [src/cpu/base.cc:379](https://github.com/gem5/gem5/blob/stable/src/cpu/base.cc#L379) 中，我们可以看到它使用字符串 `"RetiredInsts"` 注册到 `BaseCPU` SimObject 的 ProbeManager。所有 ProbePoint 都使用唯一的字符串变量注册到 ProbeManager，因此我们稍后可以使用此字符串将监听器附加到此 ProbePoint。最后，我们可以在 [src/cpu/base.cc:393](https://github.com/gem5/gem5/blob/stable/src/cpu/base.cc#L393) 中发现，当有指令提交时，此 ProbePoint 会使用整数 `1` 通知其监听器。
既然我们知道了目标 ProbePoint，就可以为 LocalInstTracker 设置它了。

---

## 01-local-inst-tracker

在 `inst_tracker.hh` 中，我们需要添加两样东西：

1. 我们将从 ProbePoint 接收的参数类型。在我们的例子中，这是一个 `uint64_t` 变量

```cpp
typedef ProbeListenerArg<LocalInstTracker, uint64_t> LocalInstTrackerListener;
```

2. 我们需要一个函数来处理来自 ProbePoint 的通知。由于我们要计算已提交的指令数量，并在达到某个阈值时退出，让我们为此创建两个 `uint64_t` 变量

```cpp
void checkPc(const uint64_t& inst);
uint64_t instCount;
uint64_t instThreshold;
```

---

## 01-local-tracker

这里是一个可选部分。探针点工具允许在仿真期间动态附加和分离。因此，我们可以为 LocalInstTracker 创建一种开始和停止监听的方法。

在 `inst_tracker.hh` 中，

```cpp
bool listening;
void stopListening();
void startListening() {
  listening = true;
  regProbeListeners();
}
```

---

## 01-local-tracker

在 `inst_tracker.cc` 中，让我们先定义构造函数

```cpp
LocalInstTracker::LocalInstTracker(const LocalInstTrackerParams &p)
    : ProbeListenerObject(p),
      instCount(0),
      instThreshold(p.inst_threshold),
      listening(p.start_listening)
{}
```

这意味着我们将 `instCount` 初始化为 0，使用参数 `inst_threshold` 初始化 `instThreshold`，使用参数 `start_listening` 初始化 listening。

---

## 01-local-tracker

然后，让我们定义 `regProbeListeners` 函数，该函数在仿真开始时自动调用，也如我们上面定义的，当调用 `startListening` 时也会调用。

```cpp
void
LocalInstTracker::regProbeListeners()
{
    if (listening) {
        listeners.push_back(new LocalInstTrackerListener(this, "RetiredInsts",
            &LocalInstTracker::checkPc));
    }
}
```

正如我们所见，它使用我们之前定义的 `LocalInstTrackerListener` 类型。它将我们的监听器与使用字符串变量 `"RetiredInsts"` 注册的 ProbePoint 连接起来。当 ProbePoint 通知管理器时，它将使用通知的变量（在我们的例子中是 `uint64_t` 变量）调用我们的函数 `checkPc`。

---

## 01-local-tracker

对于我们的 `checkPc` 函数，它应该计算已提交的指令，检查是否达到阈值，然后在达到时触发退出事件。

```cpp
void
LocalInstTracker::checkPc(const uint64_t& inst)
{
    instCount ++;
    if (instCount >= instThreshold) {
        exitSimLoopNow("a thread reached the max instruction count");
    }
}
```

`exitSimLoopNow` 将立即创建一个事件，使用字符串变量。它将立即退出仿真。此字符串变量在标准库中被归类为 `ExitEvent.MAX_INSTS`。

---

最后，让我们定义用于动态分离的 `stopListening` 函数

```cpp
void
LocalInstTracker::stopListening()
{
    listening = false;
    for (auto l = listeners.begin(); l != listeners.end(); ++l) {
        delete (*l);
    }
    listeners.clear();
}
```

这是一个非常粗略的示例，说明如何完成此操作。它不检查监听器附加到哪个 ProbePoint，因此如果我们的 ProbeListener 监听多个 ProbePoint，我们需要检查注册的字符串变量以分离正确的 ProbeListener。
对于我们这里的简单情况，这种粗略的方法就足够了。
有关如何完成动态分离的更多详细信息，请参阅 [src/sim/probe/probe.hh](https://github.com/gem5/gem5/blob/stable/src/sim/probe/probe.hh)

---

## 01-local-tracker

除了上述功能外，我们还可以添加一些 getter 和 setter 函数，例如

```cpp
void changeThreshold(uint64_t newThreshold) {
  instThreshold = newThreshold;
}
void resetCounter() {
  instCount = 0;
}
bool ifListening() const {
  return listening;
}
uint64_t getThreshold() const {
  return instThreshold;
}
```

---

<!-- _class: code-60-percent -->

## 01-local-inst-tracker

现在，让我们设置 LocalInstTracker 的 Python 对象。
让我们在同一目录 `src/cpu/probes` 下创建一个名为 `InstTracker.py` 的文件。

```python
from m5.objects.Probe import ProbeListenerObject
from m5.params import *
from m5.util.pybind import *

class LocalInstTracker(ProbeListenerObject):
    type = "LocalInstTracker"
    cxx_header = "cpu/probes/inst_tracker.hh"
    cxx_class = "gem5::LocalInstTracker"

    cxx_exports = [
        PyBindMethod("stopListening"),
        PyBindMethod("startListening"),
        PyBindMethod("changeThreshold"),
        PyBindMethod("resetCounter"),
        PyBindMethod("ifListening"),
        PyBindMethod("getThreshold")
    ]

    inst_threshold = Param.Counter("The instruction threshold to trigger an"
                                                                " exit event")
    start_listening = Param.Counter(True, "Start listening for instructions")

```

---

## 01-local-inst-tracker

与所有新对象一样，我们需要在 Scons 中注册它，因此让我们修改 [src/cpu/probes/SConscript](https://github.com/gem5/gem5/blob/stable/src/cpu/probes/SConscript) 并添加

```python
SimObject(
    "InstTracker.py",
    sim_objects=["LocalInstTracker"],
)
Source("inst_tracker.cc")
```

现在我们已经为 `LocalInstTracker` 设置好了一切！

让我们再次构建 gem5

```bash
cd gem5
scons build/X86/gem5.fast -j$(nproc)
```

---

## 01-local-inst-tracker

构建完成后，我们可以使用 [materials/03-Developing-gem5-models/09-extending-gem5-models/01-local-inst-tracker/simple-sim.py](https://github.com/gem5bootcamp/2024/blob/main/materials/03-Developing-gem5-models/09-extending-gem5-models/01-local-inst-tracker/simple-sim.py) 测试我们的 `LocalInstTracker`

```bash
cd /workspaces/2024/materials/03-Developing-gem5-models/09-extending-gem5-models/01-local-inst-tracker
/workspaces/2024/gem5/build/X86/gem5.fast -re --outdir=simple-sim-m5out simple-sim.py
```

此 SE 脚本运行一个简单的 openmp 工作负载，对数字数组求和。此工作负载的源代码可以在 [materials/03-Developing-gem5-models/09-extending-gem5-models/simple-omp-workload/simple_workload.c](https://github.com/gem5bootcamp/2024/blob/main/materials/03-Developing-gem5-models/09-extending-gem5-models/simple-omp-workload/simple_workload.c) 中找到。

```c
m5_work_begin(0, 0);
for (j = 0; j < ARRAY_SIZE; j++) {
    #pragma omp parallel for reduction(+:sum)
    for (i = 0; i < NUM_ITERATIONS; i++) {
        sum += array[j];
    }
}
m5_work_end(0, 0);
```

---

## 01-local-inst-tracker

对于我们的 SE 脚本，我们首先将 LocalInstTracker 附加到每个核心对象，阈值为 100,000 条指令。我们不会从仿真开始就监听核心的已提交指令。

```python
from m5.objects import LocalInstTracker
for core in processor.get_cores():
    tracker = LocalInstTracker(
        start_listening = False,
        inst_threshold = 100000
    )
    core.core.probeListener = tracker
    all_trackers.append(tracker)
```

---

## 01-local-inst-tracker

当仿真触发 workbegin 退出事件时，我们将开始监听，因此我们需要一个 workbegin 处理程序来执行此操作

```python
def workbegin_handler():
    print("Reached workbegin, now start listening for instructions")
    for tracker in all_trackers:
        tracker.startListening()
    yield False
```

让我们创建一个 workend 退出事件处理程序：

```python
def workend_handler():
    print("Reached workend")
    yield False
```

---

## 01-local-inst-tracker

我们知道，在达到阈值后，我们的 LocalInstTracker 将触发 `ExitEvent.MAX_INSTS` 退出事件，因此我们也需要为其创建一个处理程序

```python
def max_inst_handler():
    counter = 1
    while counter < len(processor.get_cores()):
        print("Max Inst exit event triggered")
        print(f"Reached {counter}")
        counter += 1
        print("Fall back to simulation")
        yield False
    print(f"All {counter} cores have reached the max instruction threshold")
    print("Now stop listening for instructions")
    for tracker in all_trackers:
        tracker.stopListening()
    yield False
```

---

## 01-local-inst-tracker

使用 `simulator` 设置这些处理程序后

```python
simulator = Simulator(
    board=board,
    on_exit_event={
        ExitEvent.MAX_INSTS: max_inst_handler(),
        ExitEvent.WORKBEGIN: workbegin_handler(),
        ExitEvent.WORKEND: workend_handler(),
    }
)
```

我们应该期望在 `WORKBEGIN` 事件之后有 8 个 `MAX_INSTS` 事件。

---

<!-- _class: code-50-percent -->

## 01-local-inst-tracker

我们应该期望在 `simout.txt` 中看到以下日志

```bash
Global frequency set at 1000000000000 ticks per second
Running with 8 threads
Reached workbegin, now start listening for instructions
Max Inst exit event triggered
Reached 1
Fall back to simulation
Max Inst exit event triggered
Reached 2
Fall back to simulation
Max Inst exit event triggered
Reached 3
Fall back to simulation
Max Inst exit event triggered
Reached 4
Fall back to simulation
Max Inst exit event triggered
Reached 5
Fall back to simulation
Max Inst exit event triggered
Reached 6
Fall back to simulation
Max Inst exit event triggered
Reached 7
Fall back to simulation
All 8 cores have reached the max instruction threshold
Now stop listening for instructions
Reached workend
Sum: 332833500000
Simulation Done
```

---

<!-- _class: center-image two-col -->

## 01-local-inst-tracker

恭喜！我们现在有了 LocalInstTracker！
但是，这个本地指令退出事件可以使用 `BaseCPU` 中的 [scheduleInstStop](https://github.com/studyztp/gem5/blob/studyztp/probe-user-inst/src/cpu/BaseCPU.py#L72) 函数来完成。我们的目标是拥有一个跟踪全局已提交指令的指令退出事件，这在 gem5 中还没有简单的接口来实现。
由于每个 ProbeListener 只能附加到一个 SimObject，我们可以修改 LocalInstTracker 以通知全局对象来跟踪所有 ProbeListener 中的所有已提交指令。

<!-- do a visualization here -->
![](/bootcamp/03-Developing-gem5-models/09-extending-gem5-models-imgs/global-listener.drawio.svg)

---

## 02-global-inst-tracker

本节的所有材料可以在 [`materials/03-Developing-gem5-models/09-extending-gem5-models/02-global-inst-tracker`](/materials/03-Developing-gem5-models/09-extending-gem5-models/02-global-inst-tracker) 下找到。

我们可以创建一个新的 SimObject 来帮助我们跟踪所有 ProbeListener。
让我们开始修改 `inst_tracker.hh`，添加一个名为 `GlobalInstTracker` 的新 SimObject 类。

```cpp
#include "params/GlobalInstTracker.hh"
class GlobalInstTracker : public SimObject
{
  public:
    GlobalInstTracker(const GlobalInstTrackerParams &params);
}
```

---

## 02-global-inst-tracker

由于所有计数和阈值检查都将由 `GlobalInstTracker` 完成，让我们将所有相关变量和函数移动到 `GlobalInstTracker`。

```cpp
  private:
  uint64_t instCount;
  uint64_t instThreshold;

public:
  void changeThreshold(uint64_t newThreshold) {
    instThreshold = newThreshold;
  }
  void resetCounter() {
    instCount = 0;
  }
  uint64_t getThreshold() const {
    return instThreshold;
  }
```

---

<!-- _class: code-70-percent -->

## 02-global-inst-tracker

所以我们的 `LocalInstTracker` 现在应该只像下面这样。请注意，它有一个指向 `GlobalInstTracker` 的指针。这就是我们如何从 `LocalInstTracker` 通知 `GlobalInstTracker`。

```cpp
class LocalInstTracker : public ProbeListenerObject
{
  public:
    LocalInstTracker(const LocalInstTrackerParams &params);
    virtual void regProbeListeners();
    void checkPc(const uint64_t& inst);
  private:
    typedef ProbeListenerArg<LocalInstTracker, uint64_t>
      LocalInstTrackerListener;
    bool listening;
    GlobalInstTracker *globalInstTracker;

  public:
    void stopListening();
    void startListening() {
      listening = true;
      regProbeListeners();
    }
};
```

---

<!-- _class: code-70-percent -->

## 02-global-inst-tracker

现在，我们需要决定 `GlobalInstTracker` 如何处理来自 `LocalInstTracker` 的通知。
我们希望它计算全局已提交指令的数量，检查是否达到阈值，如果达到则触发退出事件。
因此，在 `inst_tracker.hh` 中，让我们也为 `GlobalInstTracker` 添加一个 `checkPc` 函数。

```cpp
void checkPc(const uint64_t& inst);
```

In `inst_tracker.cc`, let's define it as

```cpp
void
GlobalInstTracker::checkPc(const uint64_t& inst)
{
    instCount ++;
    if (instCount >= instThreshold) {
        exitSimLoopNow("a thread reached the max instruction count");
    }
}
```

---

## 02-global-inst-tracker

现在，我们需要修改 `LocalInstTracker` 的原始 `checkPc` 函数以通知 `GlobalInstTracker`

```cpp
void
LocalInstTracker::checkPc(const uint64_t& inst)
{
    globalInstTracker->checkPc(inst);
}
```

不要忘记更改 `LocalInstTracker` 的构造函数

```cpp
LocalInstTracker::LocalInstTracker(const LocalInstTrackerParams &p)
    : ProbeListenerObject(p),
      globalInstTracker(p.global_inst_tracker),
      listening(p.start_listening)
{}
```

---

## 02-global-inst-tracker

我们几乎完成了 C++ 部分。让我们不要忘记 `inst_tracker.cc` 中 `GlobalInstTracker` 的构造函数

```cpp
GlobalInstTracker::GlobalInstTracker(const GlobalInstTrackerParams &p)
    : SimObject(p),
      instCount(0),
      instThreshold(p.inst_threshold)
{}
```

之后，我们需要为新的 `GlobalInstTracker` 和修改后的 `LocalInstTracker` 修改 `InstTracker.py`

---

<!-- _class: two-col  -->

```python
from m5.objects import SimObject
from m5.objects.Probe import ProbeListenerObject
from m5.params import *
from m5.util.pybind import *


class GlobalInstTracker(SimObject):
    type = "GlobalInstTracker"
    cxx_header = "cpu/probes/inst_tracker.hh"
    cxx_class = "gem5::GlobalInstTracker"

    cxx_exports = [
        PyBindMethod("changeThreshold"),
        PyBindMethod("resetCounter"),
        PyBindMethod("getThreshold")
    ]

    inst_threshold = Param.Counter("The instruction threshold to trigger an"
                                                                " exit event")
```

###

```python
class LocalInstTracker(ProbeListenerObject):
    type = "LocalInstTracker"
    cxx_header = "cpu/probes/inst_tracker.hh"
    cxx_class = "gem5::LocalInstTracker"

    cxx_exports = [
        PyBindMethod("stopListening"),
        PyBindMethod("startListening")
    ]

    global_inst_tracker = Param.GlobalInstTracker("Global instruction tracker")
    start_listening = Param.Counter(True, "Start listening for instructions")

```

---

## 02-global-inst-tracker

最后，[gem5/src/cpu/probes/SConscript](https://github.com/gem5/gem5/blob/stable/src/cpu/probes/SConscript)

```python
SimObject(
    "InstTracker.py",
    sim_objects=["GlobalInstTracker", "LocalInstTracker"],
)
Source("inst_tracker.cc")
```

让我们使用新的 `GlobalInstTracker` 构建 gem5！

```bash
cd gem5
scons build/X86/gem5.fast -j$(nproc)
```

---

## 02-global-inst-tracker

在 [materials/03-Developing-gem5-models/09-extending-gem5-models/02-global-inst-tracker/simple-sim.py](https://github.com/gem5bootcamp/2024/blob/main/materials/03-Developing-gem5-models/09-extending-gem5-models/02-global-inst-tracker/simple-sim.py) 中有一个简单的 SE 脚本。

我们可以使用以下命令测试我们的 `GlobalInstTracker`

```bash
cd /workspaces/2024/materials/03-Developing-gem5-models/09-extending-gem5-models/02-global-inst-tracker
/workspaces/2024/gem5/build/X86/gem5.fast -re --outdir=simple-sim-m5out simple-sim.py
```

此脚本运行与我们在 01-local-inst-tracker 中相同的工作负载，但使用 `GlobalInstTracker` 设置。

---

## 02-global-inst-tracker

它创建一个 `GlobalInstTracker`，当每个 `LocalInstTracker` 附加到核心时，它将自身作为引用传递给 `global_inst_tracker` 参数

```python
from m5.objects import LocalInstTracker, GlobalInstTracker

global_inst_tracker = GlobalInstTracker(
    inst_threshold = 100000
)
all_trackers = []
for core in processor.get_cores():
    tracker = LocalInstTracker(
        global_inst_tracker = global_inst_tracker,
        start_listening = False,
    )
    core.core.probeListener = tracker
    all_trackers.append(tracker)
```

---

## 02-global-inst-tracker

当触发 workbegin 时，我们开始监听，然后在所有核心累计提交 100,000 条指令后退出仿真。
此外，我们在 workbegin 时重置统计信息，以便我们可以验证 `GlobalInstTracker` 是否真正完成了它的工作。

如果仿真完成，我们可以统计统计信息。
有一个辅助 Python 文件 [materials/03-Developing-gem5-models/09-extending-gem5-models/02-global-inst-tracker/count_commited_inst.py](https://github.com/gem5bootcamp/2024/blob/main/materials/03-Developing-gem5-models/09-extending-gem5-models/02-global-inst-tracker/count_commited_inst.py)，可以帮助我们轻松计算所有 8 个核心的总已提交指令数。

让我们运行它
```python
python3 count_commited_inst.py
```
如果 `GlobalInstTracker` 正常工作，我们应该看到以下内容。

```bash
Total committed instructions: 100000
```

---

## 总结

探针点（ProbePoint）是一个有用的工具，可以在不向组件代码库添加太多内容的情况下分析或为我们的仿真添加辅助功能。
