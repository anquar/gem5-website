---
layout: bootcamp
title: 编程事件驱动模拟
permalink: /bootcamp/developing-gem5/event-driven-sim
section: developing-gem5
author: Mahyar Samani, Jason Lowe-Power
---
<!-- _class: title -->

## 编程事件驱动模拟

**重要提示**：本幻灯片基于已在 [SimObjects 简介](01-sim-objects-intro.md) 和 [调试 gem5](02-debugging-gem5.md) 中开发的内容。

---
<!-- _class: title -->

## 补充：事件驱动模拟回顾

---

## gem5 架构：模拟

gem5 是一个 **_离散事件模拟器_**

在每个时间步，gem5：

1. 将队列头部的事件出队
2. 执行该事件
3. 调度新事件

![Example of discrete event simulation bg right:55% fit](/bootcamp/03-Developing-gem5-models/../01-Introduction/01-simulation-background-imgs/des-1.drawio.svg)

---

<!-- _paginate: hold -->

## gem5 architecture: Simulation

gem5 is a **_discrete event simulator_**

At each timestep, gem5:

1. Event at the head is dequeued
2. The event is executed
3. New events are scheduled

![Example of discrete event simulation bg right:55% fit](/bootcamp/03-Developing-gem5-models/../01-Introduction/01-simulation-background-imgs/des-2.drawio.svg)

---

<!-- _paginate: hold -->

## gem5 architecture: Simulation

gem5 is a **_discrete event simulator_**

At each timestep, gem5:

1. Event at the head is dequeued
2. The event is executed
3. New events are scheduled

> **所有 SimObject 都可以将事件入队到事件队列中**

![Example of discrete event simulation bg right:55% fit](/bootcamp/03-Developing-gem5-models/../01-Introduction/01-simulation-background-imgs/des-3.drawio.svg)

---

## 离散事件模拟示例

![Example of discrete event simulation fit](/bootcamp/03-Developing-gem5-models/../01-Introduction/01-simulation-background-imgs/des-example-1.drawio.svg)

---

<!-- _paginate: hold -->

## Discrete event simulation example

![Example of discrete event simulation fit](/bootcamp/03-Developing-gem5-models/../01-Introduction/01-simulation-background-imgs/des-example-2.drawio.svg)

---

<!-- _paginate: hold -->

## Discrete event simulation example

![Example of discrete event simulation fit](/bootcamp/03-Developing-gem5-models/../01-Introduction/01-simulation-background-imgs/des-example-3.drawio.svg)

要模拟需要时间的事物，在将来调度 _下一个_ 事件（当前事件的延迟）。
可以调用函数而不是调度事件，但它们会在 _同一个 tick_ 中发生。

---

## 离散事件模拟

"时间"需要一个单位。
在 gem5 中，我们使用一个名为 "Tick" 的单位。

需要将模拟的 "tick" 转换为用户可理解的时间，例如秒。

这是全局模拟 tick 速率。
通常这是每个 tick 1 ps 或每秒 $10^{12}$ 个 tick。

---
<!-- _class: code-60-percent -->

## 事件驱动模拟：抽象思考

`事件驱动模拟` 是一种模拟方法，模拟器对 `事件` 的发生做出反应。每种类型的 `事件` 都有其特定的反应。

对 `事件` 的反应通过调用特定函数来定义，该函数称为 `回调` 函数。

`回调` 函数本身可能会引起新的 `事件` 发生。新的 `事件` 可以与导致调用 `回调` 函数的 `事件` 类型相同或不同。

---

## 事件驱动模拟：抽象思考（续）

让我们看一个例子来更好地理解它。假设在时间 $t_0$ 发生事件 $A$。模拟器将通过调用 $A.callback$ 来做出反应。假设下面是 $A.callback$ 的定义。

```python
# This is a pseudo-code (it's not python or C++)
def A::callback():
    print("Reacting to Event A")
    delay = 1000
    curr_time = Simulator.get_current_time()
    schedule(B, current_time + delay)
```

这样，每次事件 $A$ 发生时，事件 $B$ 将在 1000 个时间单位后发生。然后，模拟器将通过调用 $B.callback$ 来做出反应。

---

## 事件驱动模拟：实践视角

事件驱动模拟器需要提供以下功能：

- 时间概念：模拟器需要跟踪模拟的全局时间并允许访问当前时间。它还需要让时间向前推进。
- `事件` 接口：模拟器需要为模拟器中的 `事件` 定义基础接口，以便它们可以定义和引发（即让发生/调度）新的 `事件`。 <!-- "they" is ambiguous here -->
  - `事件` 的基础接口应该允许将 `事件` 绑定到 `回调` 函数。

---

## 事件驱动模拟：实践视角（续）

让我们看看如果你要编写自己的硬件模拟器，这会是什么样子。

1- 在开始时（$t = 0$），模拟器将调度一个使 CPU 核心获取指令的事件。让我们将这种类型的事件称为 `CPU::fetch`。

2- 当模拟器到达（$t = 0$）时，模拟器将对此时调度的所有 `事件` 做出反应。如果我们有 2 个核心，这意味着模拟器需要调用 `cpu_0::fetch::callback` 和 `cpu_1::fetch::callback`。

3- `CPU::fetch::callback` 然后必须找出下一个程序计数器是什么，并向指令缓存发送请求以获取指令。因此，它将在将来调度一个像 `CPU::accessICache` 这样的事件。

为了施加获取的延迟，我们将在 `current_time + fetch_delay` 调度 `CPU::accessICache`，即 `schedule(CPU::accessICache, currentTime() + fetch_delay)`。这将在将来 `fetch_delay` 个时间单位后引发两个 `CPU::accessICache` 事件（例如 `cpu_0::accessICache` 和 `cpu_1::accessICache`）。

---

## 事件驱动模拟：实践视角（续）

4- 当模拟器完成对在 $t = 0$ 发生的所有事件的反应后，它将把时间移动到最近的事件调度发生时间（在这种情况下是 $t = 0 + fetch\_delay$）。

5- 在时间 $t= fetch\_delay$，模拟器将调用 `cpu_0::accessICache::callback` 和 `cpu_1::accessICache::callback` 来对这两个事件做出反应。这些事件可能会访问指令缓存，然后可能会调度事件来处理缓存未命中，如 `Cache::handleMiss`。

6- 这个过程将持续到我们正在模拟的程序完成。

---
<!-- _class: code-80-percent -->

## gem5 中的事件驱动模拟

让我们查看 [src/sim/eventq.hh](/gem5/src/sim/eventq.hh)。在那里，您将看到一个类 `Event` 的声明，它有一个名为 `process` 的函数，如下所示。

```cpp
  public:

    /*
     * 当事件被处理（发生）时调用此成员函数。
     * 没有默认实现；每个子类必须提供自己的实现。
     * 事件在处理后不会自动删除（以允许静态分配的事件对象）。
     *
     * 如果设置了 AutoDestroy 标志，对象在处理后会被删除。
     *
     * @ingroup api_eventq
     */
    virtual void process() = 0;
```

---
<!-- _class: code-50-percent -->

## 事件的一个假设示例

现在让我们看看类 `Event` 如何在模拟 CPU 的 `SimObject` 中使用。**注意**：这是一个假设示例，完全不是 gem5 中已实现的内容。

```cpp
class CPU: public ClockedObject
{
  public:
    void processFetch(); // Function to model fetch
  private:
    class FetchEvent: public Event
    {
      private:
        CPU* owner;
      public:
        FetchEvent(CPU* owner): Event(), owner(owner)
        {}
        virtual void process() override
        {
            owner->processFetch(); // call processFetch from the CPU that owns this
        }
    };
    FetchEvent nextFetch;
};
```

在这个示例中，每次 `FetchEvent` 的实例发生时（`cpu_0::nextFetch` 而不是 `CPU::nextFetch`），模拟器将从拥有该事件的 `CPU` 实例调用 `processFetch`。

---
<!-- _class: code-50-percent -->

## EventFunctionWrapper

除了类 `Event` 之外，您可以在 [src/sim/eventq.hh](/gem5/src/sim/eventq.hh) 中找到 `EventFunctionWrapper` 的声明。此类用一个可调用对象包装一个 `event`，当调用 `Event::process` 时将调用该对象。来自 `src/sim/eventq.hh` 的以下行值得查看。

```cpp
  public:
    /**
     * 此函数将函数包装成事件，以便稍后执行。
     * @ingroup api_eventq
     */
    EventFunctionWrapper(const std::function<void(void)> &callback,
                         const std::string &name,
                         bool del = false,
                         Priority p = Default_Pri)
        : Event(p), callback(callback), _name(name)
    {
        if (del)
            setFlags(AutoDelete);
    }
    void process() { callback(); }
```

对于 `EventFunctionWrapper`，函数 `process` 被定义为对 `callback` 的调用，该 `callback` 作为参数传递给 `EventFunctionWrapper` 的构造函数。此外，我们需要通过构造函数为每个对象指定一个名称。

---
<!-- _class: code-50-percent -->

## 补充：m5.simulate: SimObject::startup

以下是来自 [src/python/m5/simulate.py](/gem5/src/python/m5/simulate.py) 中 `m5.simulate` 定义的代码片段：

```python
def simulate(*args, **kwargs):
    # ...
    if need_startup:
        root = objects.Root.getInstance()
        for obj in root.descendants():
            obj.startup()
        need_startup = False
```

通过调用 `m5.simulate`，gem5 将调用系统中每个 `SimObject` 的函数 `startup`。让我们查看 [src/sim/sim_object.hh](/gem5/src/sim/sim_object.hh) 中 `SimObject` 的头文件中的 `startup`。

```cpp
    /**
     * startup() 是模拟前的最终初始化调用。
     * 所有状态都已初始化（包括未序列化的状态，如果有的话，
     * 例如 curTick() 值），因此这是为需要它们的对象调度初始事件
     * 的适当位置。
    */
    virtual void startup();
```

`startup` 是我们调度触发模拟的初始 `事件` 的地方（在我们的假设场景中是 `CPU::nextFetch`）。

---
<!-- _class: start -->

## 步骤 1：SimObject 事件

---
<!-- _class: code-70-percent -->

## 练习 1：nextHelloEvent

## nextHelloEvent

练习 1 的完成文件位于目录 [materials/03-Developing-gem5-models/03-event-driven-sim/step-1](/materials/03-Developing-gem5-models/03-event-driven-sim/step-1/) 下。

现在，让我们向 `HelloSimObject` 添加一个 `event`，以定期打印 `Hello ...` 一定次数（即 `num_hellos`）。让我们将其添加到 [src/bootcamp/hello-sim-object.hh](/gem5/src/bootcamp/hello-sim-object/hello_sim_object.hh) 中 `HelloSimObject` 的头文件中。

首先，我们需要包含 `sim/eventq.hh`，以便我们可以添加一个类型为 `EventFunctionWrapper` 的成员。添加以下行来完成此操作。**记住**：确保遵循正确的包含顺序。

```cpp
#include "sim/eventq.hh
```

---

## nextHelloEvent

接下来，我们需要声明一个类型为 `EventFunctionWrapper` 的成员，我们将其称为 `nextHelloEvent`。

我们还需要定义一个 `std::function<void>()` 作为 `nextHelloEvent` 的 `callback` 函数。
- `std::function<void>()` 是一个返回类型为 `void` 且没有输入参数的可调用对象。

为此，请将以下行添加到 `HelloSimObject` 类的声明中。

```cpp
  private:
    EventFunctionWrapper nextHelloEvent;
    void processNextHelloEvent();
```

---
<!-- _class: code-50-percent -->

## nextHelloEvent：头文件

这是您的 `hello_sim_object.hh` 在所有更改后应该看起来的样子。

```cpp
#ifndef __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__
#define __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__

#include "params/HelloSimObject.hh"
#include "sim/eventq.hh"
#include "sim/sim_object.hh"

namespace gem5
{

class HelloSimObject: public SimObject
{
  private:
    EventFunctionWrapper nextHelloEvent;
    void processNextHelloEvent();

  public:
    HelloSimObject(const HelloSimObjectParams& params);
};

} // namespace gem5

#endif // __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__
```

---
<!-- _class: code-70-percent -->

## nextHelloEvent：HelloSimObject：构造函数

现在，让我们更改 `HelloSimObject` 构造函数的定义以初始化 `nextHelloEvent`。让我们在 `HelloSimObject::HelloSimObject` 的初始化列表中添加以下行，您可以在 `src/bootcamp/hello-sim-object/hello_sim_object.cc` 中找到它。

```cpp
    nextHelloEvent([this](){ processNextHelloEvent(); }, name() + "nextHelloEvent")
```

这是 `HelloSimObject::HelloSimObject` 在更改后应该看起来的样子。

```cpp
HelloSimObject::HelloSimObject(const HelloSimObjectParams& params):
    SimObject(params),
    nextHelloEvent([this](){ processNextHelloEvent(); }, name() + "nextHelloEvent")
{
    for (int i = 0; i < params.num_hellos; i++) {
        std::cout << "i: " << i << ", Hello from HelloSimObject's constructor!" << std::endl;
    }
    DPRINTF(HelloExampleFlag, "%s: Hello from HelloSimObject's constructor!\n", __func__);
}
```

---
<!-- _class: code-50-percent -->

## nextHelloEvent 回调：processNextHelloEvent

现在，让我们定义 `processNextHelloEvent`，以每 `500 Ticks` 打印 `Hello ...` `num_hellos` 次。为了跟踪我们已打印的 `Hello ...` 语句数量，让我们声明一个 `private` 成员来计数。将以下声明添加到 `src/bootcamp/hello-sim-object/hello_sim_object.hh` 中 `HelloSimObject` 类的 `private` 作用域。

```cpp
  private:
    int remainingHellosToPrintByEvent;
```

这是 `HelloSimObject` 的声明在更改后应该看起来的样子。

```cpp
class HelloSimObject: public SimObject
{
  private:
    int remainingHellosToPrintByEvent;

    EventFunctionWrapper nextHelloEvent;
    void processNextHelloEvent();

  public:
    HelloSimObject(const HelloSimObjectParams& params);
};
```

---
<!-- _class: code-80-percent -->

## nextHelloEvent 回调：processNextHelloEvent（续）

现在，让我们更新 `HelloSimObject` 的构造函数，将 `remainingHellosToPrintByEvent` 初始化为 `params.num_hellos`。通过在 `nextHelloEvent` 的初始化行上方添加以下行来完成此操作。

```cpp
    remainingHellosToPrintByEvent(params.num_hellos)
```

让我们还通过向 `HelloSimObject::HelloSimObject` 的主体开头添加如下所示的 `fatal_if` 语句，确保用户为 `num_hellos` 传递正数。

```cpp
    fatal_if(params.num_hellos <= 0, "num_hellos should be positive!");
```

---

## nextHelloEvent 回调：processNextHelloEvent：即将完成

这是 `HelloSimObject::HelloSimObject` 在更改后应该看起来的样子。

```cpp
HelloSimObject::HelloSimObject(const HelloSimObjectParams& params):
    SimObject(params),
    remainingHellosToPrintByEvent(params.num_hellos),
    nextHelloEvent([this](){ processNextHelloEvent(); }, name() + "nextHelloEvent")
{
    fatal_if(params.num_hellos <= 0, "num_hellos should be positive!");
    for (int i = 0; i < params.num_hellos; i++) {
        std::cout << "i: " << i << ", Hello from HelloSimObject's constructor!" << std::endl;
    }
    DPRINTF(HelloExampleFlag, "%s: Hello from HelloSimObject's constructor!\n", __func__);
}
```

---
<!-- _class: code-50-percent -->

## nextHelloEvent 回调：processNextHelloEvent：最后一步！

现在我们已经准备好定义 `HelloSimObject::processNextHelloEvent`。让我们将以下代码添加到 `src/bootcamp/hello-sim-object/hello_sim_object.cc`。

```cpp
void
HelloSimObject::processNextHelloEvent()
{
    std::cout << "tick: " << curTick() << ", Hello from HelloSimObject::processNextHelloEvent!" << std::endl;
    remainingHellosToPrintByEvent--;
    if (remainingHellosToPrintByEvent > 0) {
        schedule(nextHelloEvent, curTick() + 500);
    }
}
```

查看代码，每次 `nextHelloEvent` 发生时（即调用 `processNextHelloEvent`），我们执行以下操作：

- 打印 `Hello ...`。
- 递减 `remainingHellosToPrintByEvent`。
- 检查是否还有剩余的打印要做。如果有，我们将在未来 500 个 tick 调度 `nextHelloEvent`。**注意**：`curTick` 是一个返回当前模拟器时间（以 `Ticks` 为单位）的函数。

---
<!-- _class: code-50-percent -->

## HelloSimObject::startup：头文件

让我们在 `HelloSimObject` 中添加 `startup` 的声明。我们将使用 `startup` 来调度 `nextHelloEvent` 的第一次出现。由于 `startup` 是 `HelloSimObject` 从 `SimObject` 继承的 `public` 和 `virtual` 函数，我们将在 `HelloSimObject` 的 `public` 作用域中添加以下行。我们将添加 `override` 指令，告诉编译器我们打算覆盖 `SimObject` 中的原始定义。

```cpp
  public:
    virtual void startup() override;
```

这是 `HelloSimObject` 的声明在更改后应该看起来的样子。

```cpp
class HelloSimObject: public SimObject
{
  private:
    int remainingHellosToPrintByEvent;

    EventFunctionWrapper nextHelloEvent;
    void processNextHelloEvent();

  public:
    HelloSimObject(const HelloSimObjectParams& params);
    virtual void startup() override;
};
```

---

## HelloSimObject::startup：源文件

现在，让我们定义 `HelloSimObject::startup` 来调度 `nextHelloEvent`。由于 `startup` 在模拟开始时（即 $t = 0\ Ticks$）被调用，并且**只调用一次**，让我们放置 `panic_if` 语句来断言它们。此外，`nextHelloEvent` 此时不应该被调度，所以让我们也断言这一点。

将以下代码添加到 `src/bootcamp/hello-sim-object/hello_sim_object.cc` 以定义 `HelloSimObject::startup`。

```cpp
void
HelloSimObject::startup()
{
    panic_if(curTick() != 0, "startup called at a tick other than 0");
    panic_if(nextHelloEvent.scheduled(), "nextHelloEvent is scheduled before HelloSimObject::startup is called!");
    schedule(nextHelloEvent, curTick() + 500);
}
```

---
<!-- _class: code-50-percent -->

## 当前版本：Python 脚本

我们已经准备好编译 gem5 以应用更改。但在编译之前，让我们查看每个文件应该看起来的样子。

- [src/bootcamp/hello-sim-object/SConscript](/materials/03-Developing-gem5-models/03-event-driven-sim/step-1/src/bootcamp/hello-sim-object/SConscript):

```python
Import("*")

SimObject("HelloSimObject.py", sim_objects=["HelloSimObject"])

Source("hello_sim_object.cc")

DebugFlag("HelloExampleFlag")
```

- [src/bootcamp/hello-sim-object/HelloSimObject.py](/materials/03-Developing-gem5-models/03-event-driven-sim/step-1/src/bootcamp/hello-sim-object/HelloSimObject.py):

```python
from m5.objects.SimObject import SimObject
from m5.params import *

class HelloSimObject(SimObject):
    type = "HelloSimObject"
    cxx_header = "bootcamp/hello-sim-object/hello_sim_object.hh"
    cxx_class = "gem5::HelloSimObject"

    num_hellos = Param.Int("Number of times to say Hello.")
```

---
<!-- _class: code-50-percent -->

## 当前版本：头文件

- 这是 [src/bootcamp/hello-sim-object/hello_sim_object.hh](/materials/03-Developing-gem5-models/03-event-driven-sim/step-1/src/bootcamp/hello-sim-object/hello_sim_object.hh) 应该看起来的样子。

```cpp
#ifndef __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__
#define __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__

#include "params/HelloSimObject.hh"
#include "sim/eventq.hh"
#include "sim/sim_object.hh"

namespace gem5
{

class HelloSimObject: public SimObject
{
  private:
    int remainingHellosToPrintByEvent;

    EventFunctionWrapper nextHelloEvent;
    void processNextHelloEvent();

  public:
    HelloSimObject(const HelloSimObjectParams& params);
    virtual void startup() override;
};

} // namespace gem5

#endif // __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__
```

---
<!-- _class: two-col -->

## 当前版本：源文件

- 这是 [src/bootcamp/hello-sim-object/hello_sim_object.cc](/materials/03-Developing-gem5-models/03-event-driven-sim/step-1/src/bootcamp/hello-sim-object/hello_sim_object.cc) 应该看起来的样子。

```cpp
#include "bootcamp/hello-sim-object/hello_sim_object.hh"

#include <iostream>

namespace gem5
{

HelloSimObject::HelloSimObject(const HelloSimObjectParams& params):
    SimObject(params),
    remainingHellosToPrintByEvent(params.num_hellos),
    nextHelloEvent([this](){ processNextHelloEvent(); }, name() + "nextHelloEvent")
{
    fatal_if(params.num_hellos <= 0, "num_hellos should be positive!");
    for (int i = 0; i < params.num_hellos; i++) {
        std::cout << "i: " << i << ", Hello from HelloSimObject's constructor!" << std::endl;
    }
    DPRINTF(HelloExampleFlag, "%s: Hello from HelloSimObject's constructor!\n", __func__);
}
```

### Continued

```cpp
void
HelloSimObject::startup()
{
    panic_if(curTick() != 0, "startup called at a tick other than 0");
    panic_if(nextHelloEvent.scheduled(), "nextHelloEvent is scheduled before HelloSimObject::startup is called!");
    schedule(nextHelloEvent, curTick() + 500);
}

void
HelloSimObject::processNextHelloEvent()
{
    std::cout << "tick: " << curTick() << ", Hello from HelloSimObject::processNextHelloEvent!" << std::endl;
    remainingHellosToPrintByEvent--;
    if (remainingHellosToPrintByEvent > 0) {
        schedule(nextHelloEvent, curTick() + 500);
    }
}

} // namespace gem5
```

---

## 让我们编译和模拟

如果您想使用完成的示例，请将您的工作移动到另一个文件夹，并在 gem5 基础目录中运行以下命令以复制示例。

```bash
cp -r ../materials/03-Developing-gem5-models/03-event-driven-sim/step-1/src/bootcamp src
```

如果您想使用完成的配置脚本，请在 gem5 基础目录中运行以下命令：

```sh
cp -r ../materials/03-Developing-gem5-models/03-event-driven-sim/step-1/configs/bootcamp configs
```

---

## 让我们编译和模拟（续）

在 gem5 基础目录中运行以下命令以重新构建 gem5。

```sh
scons build/NULL/gem5.opt -j$(nproc)
```

现在，通过在 gem5 基础目录中运行以下命令来模拟您的配置。

```sh
./build/NULL/gem5.opt configs/bootcamp/hello-sim-object/second-hello-example.py
```

在下一张幻灯片中，有您应该看到的内容的录制。

---

<script src="https://asciinema.org/a/UiLAZT0Ryi75nkLQSs0AC0OWI.js" id="asciicast-UiLAZT0Ryi75nkLQSs0AC0OWI" async="true"></script>

---
<!-- _class: start -->

## 步骤 1 结束

---
<!-- _class: start -->

## 步骤 2：SimObjects 作为参数

---
<!-- _class: code-50-percent -->

## 练习 2：GoodByeSimObject

在这一步中，我们将学习如何将 `SimObject` 添加为参数。为此，让我们首先构建我们的第二个 `SimObject`，称为 `GoodByeSimObject`。如您所记得的，我们需要在 Python 中声明 `GoodByeSimObject`。让我们打开 `src/bootcamp/hello-sim-object/HelloSimObject.py` 并向其中添加以下代码。

```python
class GoodByeSimObject(SimObject):
    type = "GoodByeSimObject"
    cxx_header = "bootcamp/hello-sim-object/goodbye_sim_object.hh"
    cxx_class = "gem5::GoodByeSimObject"
```

另外，让我们通过编辑 `SConscript` 来注册 `GoodByeSimObject`。打开 `src/bootcamp/hello-sim-object/SConscript` 并将 `GoodByeSimObject` 添加到 `HelloSimObject.py` 中的 `SimObjects` 列表中。这是该行在更改后应该看起来的样子。

```python
SimObject("HelloSimObject.py", sim_objects=["HelloSimObject", "GoodByeSimObject"])
```

---

## GoodByeExampleFlag

让我们将 `goodbye_sim_object.cc`（我们稍后将创建）添加为源文件。通过将以下行添加到 `src/bootcamp/hello-sim-object/SConscript` 来完成此操作。

```python
Source("goodbye_sim_object.cc")
```


让我们还添加 `GoodByeExampleFlag`，以便我们可以在 `GoodByeSimObject` 中使用它来打印调试信息。通过将以下行添加到 `src/bootcamp/hello-sim-object/SConscript` 来完成此操作。

```python
DebugFlag("GoodByeExampleFlag")
```

---

## GoodByeExampleFlag（续）

### CompoundFlag

除了 `DebugFlags` 之外，我们还可以定义 `CompoundFlags`，当它们被启用时，会启用一组 `DebugFlags`。让我们定义一个名为 `GreetFlag` 的 `CompoundFlag`，它将启用 `HelloExampleFlag`、`GoodByeExampleFlag`。为此，请将以下行添加到 `src/bootcamp/hello-sim-object/SConscript`。

```python
CompoundFlag("GreetFlag", ["HelloExampleFlag", "GoodByeExampleFlag"])
```

---
<!-- _class: code-80-percent -->

## 当前版本：HelloSimObject.py

这是 [HelloSimObject.py](/materials/03-Developing-gem5-models/03-event-driven-sim/step-2/src/bootcamp/hello-sim-object/HelloSimObject.py) 在更改后应该看起来的样子。

```python
from m5.objects.SimObject import SimObject
from m5.params import *

class HelloSimObject(SimObject):
    type = "HelloSimObject"
    cxx_header = "bootcamp/hello-sim-object/hello_sim_object.hh"
    cxx_class = "gem5::HelloSimObject"

    num_hellos = Param.Int("Number of times to say Hello.")

class GoodByeSimObject(SimObject):
    type = "GoodByeSimObject"
    cxx_header = "bootcamp/hello-sim-object/goodbye_sim_object.hh"
    cxx_class = "gem5::GoodByeSimObject"
```

---

## 当前版本：SConscript

这是 [SConscript](../../materials/03-Developing-gem5-models/03-event-driven-sim/step-2/src/bootcamp/hello-sim-object/SConscript) 在更改后应该看起来的样子。

```python
Import("*")

SimObject("HelloSimObejct.py", sim_objects=["HelloSimObject", "GoodByeSimObject"])

Source("hello_sim_object.cc")
Source("goodbye_sim_object.cc")

DebugFlag("HelloExampleFlag")
DebugFlag("GoodByeExampleFlag")
CompoundFlag("GreetFlag", ["HelloExampleFlag", "GoodByeExampleFlag"])
```

---
<!-- _class: code-25-percent -->

## GoodByeSimObject：规范

在我们的设计中，让 `GoodByeSimObject` 调试打印一个 `GoodBye ...` 语句。它将在调用 `sayGoodBye` 函数时执行此操作，该函数将调度一个 `event` 来说 GoodBye。

在接下来的幻灯片中，您可以找到 [src/bootcamp/hello-sim-object/goodbye_sim_object.hh](../../materials/03-Developing-gem5-models/03-event-driven-sim/step-2/src/bootcamp/hello-sim-object/goodbye_sim_object.hh) 和 [src/bootcamp/hello-sim-object/goodbye_sim_object.cc](../../materials/03-Developing-gem5-models/03-event-driven-sim/step-2/src/bootcamp/hello-sim-object/goodbye_sim_object.cc) 的完成版本。

**重要提示**：我不会详细介绍这些文件的细节，请仔细查看此文件，并确保您理解每一行应该做什么。

---
<!-- _class: code-60-percent -->

## GoodByeSimObject：头文件

```cpp
#ifndef __BOOTCAMP_HELLO_SIM_OBJECT_GOODBYE_SIM_OBJECT_HH__
#define __BOOTCAMP_HELLO_SIM_OBJECT_GOODBYE_SIM_OBJECT_HH__

#include "params/GoodByeSimObject.hh"
#include "sim/eventq.hh"
#include "sim/sim_object.hh"

namespace gem5
{

class GoodByeSimObject: public SimObject
{
  private:
    EventFunctionWrapper nextGoodByeEvent;
    void processNextGoodByeEvent();

  public:
    GoodByeSimObject(const GoodByeSimObject& params);

    void sayGoodBye();
};

} // namespace gem5

#endif // __BOOTCAMP_HELLO_SIM_OBJECT_GOODBYE_SIM_OBJECT_HH__
```

---

## GoodByeSimObject：源文件

<!-- _class: code-60-percent -->

```cpp
#include "bootcamp/hello-sim-object/goodbye_sim_object.hh"

#include "base/trace.hh"
#include "debug/GoodByeExampleFlag.hh"

namespace gem5
{

GoodByeSimObject::GoodByeSimObject(const GoodByeSimObjectParams& params):
    SimObject(params),
    nextGoodByeEvent([this]() { processNextGoodByeEvent(); }, name() + "nextGoodByeEvent" )
{}

void
GoodByeSimObject::sayGoodBye() {
    panic_if(nextGoodByeEvent.scheduled(), "GoodByeSimObject::sayGoodBye called while nextGoodByeEvent is scheduled!");
    schedule(nextGoodByeEvent, curTick() + 500);
}

void
GoodByeSimObject::processNextGoodByeEvent()
{
    DPRINTF(GoodByeExampleFlag, "%s: GoodBye from GoodByeSimObejct::processNextGoodByeEvent!\n", __func__);
}

} // namespace gem5
```

---

## GoodByeSimObject 作为参数

在这一步中，我们将向 `HelloSimObject` 添加一个类型为 `GoodByeSimObject` 的参数。为此，我们只需在 `src/bootcamp/hello-sim-object/HelloSimObject.py` 中 `HelloSimObject` 的声明中添加以下行。

```python
    goodbye_object = Param.GoodByeSimObject("GoodByeSimObject to say goodbye after done saying hello.")
```

这是 `HelloSimObject` 的声明在更改后应该看起来的样子。

```python
class HelloSimObject(SimObject):
    type = "HelloSimObject"
    cxx_header = "bootcamp/hello-sim-object/hello_sim_object.hh"
    cxx_class = "gem5::HelloSimObject"

    num_hellos = Param.Int("Number of times to say Hello.")

    goodbye_object = Param.GoodByeSimObject("GoodByeSimObject to say goodbye after done saying hello.")
```

---

## HelloSimObject：头文件

<!-- _class: code-70-percent -->

添加 `goodbye_object` 参数将向 `HelloSimObjectParams` 添加一个类型为 `gem5::HelloSimObject*` 的新成员。我们将在以后看到这一点。

我们可以使用该参数来初始化指向 `GoodByeSimObject` 对象的指针，当我们用完要打印的 `Hello ...` 语句时，我们将使用它来调用 `sayGoodBye`。

首先，让我们通过在 `src/bootcamp/hello-sim-object/hello_sim_object.hh` 中添加以下行来包含 `GoodByeSimObject` 的头文件。**记住**：遵循 gem5 的包含顺序约定。

```cpp
#include "bootcamp/hello-sim-object/goodbye_sim_object.hh"
```

现在，让我们向 `HelloSimObject` 添加一个指向 `GoodByeSimObject` 的新成员。将以下行添加到 `src/bootcamp/hello-sim-object/hello_sim_object.hh`。

```cpp
  private:
    GoodByeSimObject* goodByeObject;
```

---
<!-- _class: code-60-percent -->

## HelloSimObject：源文件

现在，让我们通过在 `HelloSimObject::HelloSimObject` 的初始化列表中添加以下行来从参数初始化 `goodByeObject`。

```cpp
    goodByeObject(params.goodbye_object)
```

现在，让我们在 `processNextHelloEvent` 中为 `if (remainingHellosToPrintByEvent > 0)` 添加一个 `else` 主体，以从 `goodByeObject` 调用 `sayGoodBye`。以下是 `src/bootcamp/hello-sim-object/hello_sim_object.cc` 中 `processNextHelloEvent` 在更改后应该看起来的样子。

```cpp
void
HelloSimObject::processNextHelloEvent()
{
    std::cout << "tick: " << curTick() << ", Hello from HelloSimObject::processNextHelloEvent!" << std::endl;
    remainingHellosToPrintByEvent--;
    if (remainingHellosToPrintByEvent > 0) {
        schedule(nextHelloEvent, curTick() + 500);
    } else {
        goodByeObject->sayGoodBye();
    }
}
```

---
<!-- _class: code-50-percent -->

## 当前版本：HelloSimObject：头文件

这是 [src/bootcamp/hello-sim-object/hello_sim_object.hh](/../../materials/03-Developing-gem5-models/03-event-driven-sim/step-2/src/bootcamp/hello-sim-object/hello_sim_object.hh) 在更改后应该看起来的样子。

```cpp
#ifndef __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__
#define __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__

#include "bootcamp/hello-sim-object/goodbye_sim_object.hh"
#include "params/HelloSimObject.hh"
#include "sim/eventq.hh"
#include "sim/sim_object.hh"

namespace gem5
{

class HelloSimObject: public SimObject
{
  private:
    int remainingHellosToPrintByEvent;
    GoodByeSimObject* goodByeObject;

    EventFunctionWrapper nextHelloEvent;
    void processNextHelloEvent();

  public:
    HelloSimObject(const HelloSimObjectParams& params);
    virtual void startup() override;
};

} // namespace gem5

#endif // __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__
```

---
<!-- _class: two-col -->

## 当前版本：HelloSimObject：源文件

这是 [src/bootcamp/hello-sim-object/hello_sim_object.cc](../../materials/03-Developing-gem5-models/03-event-driven-sim/step-2/src/bootcamp/hello-sim-object/hello_sim_object.cc) 在更改后应该看起来的样子。

```cpp
#include "bootcamp/hello-sim-object/hello_sim_object.hh"

#include <iostream>

#include "base/trace.hh"
#include "debug/HelloExampleFlag.hh"

namespace gem5
{

HelloSimObject::HelloSimObject(const HelloSimObjectParams& params):
    SimObject(params),
    remainingHellosToPrintByEvent(params.num_hellos),
    goodByeObject(params.goodbye_object),
    nextHelloEvent([this](){ processNextHelloEvent(); }, name() + "nextHelloEvent")
{
    fatal_if(params.num_hellos <= 0, "num_hellos should be positive!");
    for (int i = 0; i < params.num_hellos; i++) {
        std::cout << "i: " << i << ", Hello from HelloSimObject's constructor!" << std::endl;
    }
    DPRINTF(HelloExampleFlag, "%s: Hello from HelloSimObject's constructor!\n", __func__);
}
```

### Continued

```cpp
void
HelloSimObject::startup()
{
    panic_if(curTick() != 0, "startup called at a tick other than 0");
    panic_if(nextHelloEvent.scheduled(), "nextHelloEvent is scheduled before HelloSimObject::startup is called!");
    schedule(nextHelloEvent, curTick() + 500);
}

void
HelloSimObject::processNextHelloEvent()
{
    std::cout << "tick: " << curTick() << ", Hello from HelloSimObject::processNextHelloEvent!" << std::endl;
    remainingHellosToPrintByEvent--;
    if (remainingHellosToPrintByEvent > 0) {
        schedule(nextHelloEvent, curTick() + 500);
    } else {
        goodByeObject->sayGoodBye();
    }
}

} // namespace gem5
```

---

## 让我们构建

如果您想运行完成的示例，请将您的工作移动到另一个目录，然后在 gem5 基础目录中运行以下命令。

```sh
cp -r ../materials/03-Developing-gem5-models/03-event-driven-sim/step-2/src/bootcamp src
```

在所有更改后，在 gem5 基础目录中运行以下命令以重新构建 gem5。

```sh
scons build/NULL/gem5.opt -j$(nproc)
```

---

## 让我们构建（续）

编译完成后，查看 `build/NULL/params/HelloSimObject.hh`。注意 `gem5::GoodByeSimObject * goodbye_object` 已被添加。以下是 `HelloSimObjectParams` 的声明。

```cpp
namespace gem5
{
struct HelloSimObjectParams
    : public SimObjectParams
{
    gem5::HelloSimObject * create() const;
    gem5::GoodByeSimObject * goodbye_object;
    int num_hellos;
};

} // namespace gem5
```

---

## 配置脚本

让我们通过复制 `configs/bootcamp/hello-sim-object/second-hello-example.py` 来创建一个新的配置脚本（`third-hello-example.py`）。通过在 gem5 基础目录中运行以下命令来完成此操作。

```sh
cp configs/bootcamp/hello-sim-object/second-hello-example.py configs/bootcamp/hello-sim-object/third-hello-example.py
```

现在，我们需要为 `HelloSimObject` 的 `goodbye_object` 参数赋值。我们将为此参数创建一个 `GoodByeSimObject` 对象。

让我们从导入 `GoodByeSimObject` 开始。只需将 `GoodByeSimObject` 添加到 `from m5.objects.HelloSimObject import HelloSimObject` 即可。这是导入语句在更改后应该看起来的样子。

```python
from m5.objects.HelloSimObject import HelloSimObject, GoodByeSimObject
```

---
<!-- _class: code-70-percent -->

## 配置脚本（续）

现在，让我们添加以下行以从 `root.hello` 为 `goodbye_object` 赋值。

```python
root.hello.goodbye_object = GoodByeSimObject()
```

这是 `configs/bootcamp/hello-sim-object/third-hello-example.py` 在更改后应该看起来的样子。

```python
import m5
from m5.objects.Root import Root
from m5.objects.HelloSimObject import HelloSimObject, GoodByeSimObject

root = Root(full_system=False)
root.hello = HelloSimObject(num_hellos=5)
root.hello.goodbye_object = GoodByeSimObject()

m5.instantiate()
exit_event = m5.simulate()

print(f"Exited simulation because: {exit_event.getCause()}.")
```

---

## 让我们模拟

如果您想运行完成的脚本，请在 gem5 基础文件夹中运行以下命令，将完成的 `third-hello-example.py` 移动到 gem5 目录中：

```bash
cp -r ../materials/03-Developing-gem5-models/03-event-driven-sim/step-2/configs/bootcamp/hello-sim-object/third-hello-example.py configs/bootcamp/hello-sim-object
```

现在让我们分别使用启用 `GoodByeExampleFlag` 和启用 `GreetFlag` 来模拟 `third-hello-example.py`，并比较输出。

在 gem5 基础目录中运行以下命令，以启用 `GoodByeExampleFlag` 来模拟 `third-hello-example.py`。

```sh
./build/NULL/gem5.opt --debug-flags=GoodByeExampleFlag configs/bootcamp/hello-sim-object/third-hello-example.py
```

在下一张幻灯片中，有我运行上述命令时的终端录制。

---

<script src="https://asciinema.org/a/9vTP6wE1Yu0ihlKjA4j7TxEMm.js" id="asciicast-9vTP6wE1Yu0ihlKjA4j7TxEMm" async="true"></script>

---

## 让我们模拟：第 2 部分

在 gem5 基础目录中运行以下命令，以启用 `GreetFlag` 来模拟 `third-hello-example.py`。

```sh
./build/NULL/gem5.opt --debug-flags=GreetFlag configs/bootcamp/hello-sim-object/third-hello-example.py
```

在下一张幻灯片中，有我运行上述命令时的终端录制。

---

<script src="https://asciinema.org/a/2cz336gLt2ZZBysroLhVbqBHs.js" id="asciicast-2cz336gLt2ZZBysroLhVbqBHs" async="true"></script>

---
<!-- _class: start -->

## 步骤 2 结束
