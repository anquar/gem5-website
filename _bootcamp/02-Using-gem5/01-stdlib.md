---
layout: bootcamp
title: gem5 标准库
permalink: /bootcamp/using-gem5/stdlib
section: using-gem5
---
<!-- _class: title -->

## gem5 标准库

---

## 为什么需要标准库？

如果不使用标准库，你必须定义模拟的*每个部分*：每个 SimObject，正确连接到每个端口，无论多小的部分都要定义。
即使是最基本的模拟，这也可能导致脚本有数百行代码。

这会导致：

- 大量重复代码。
- 容易出错的配置。
- 不同模拟设置之间缺乏可移植性。

此外，虽然对于 gem5 用户来说没有"一刀切"的解决方案，但大多数用户对他们的模拟有相似的需求和要求，只需要对某些常用配置系统进行少量修改。
在创建标准库之前，用户会定期共享长而复杂的脚本并不断修改它们。
这些做法促使了 gem5 标准库的创建。

---

## 什么是标准库？

gem5 标准库的目的是提供一组预定义的组件，可用于构建为你完成大部分工作的模拟。

对于标准库不支持的部分，提供了 API，使你能够轻松扩展库以供自己使用。

---

## 比喻：将组件插入到板子上

![overview of some standard library components and their relationships bg fit 90%](/bootcamp/02-Using-gem5/01-stdlib-imgs/stdlib-design.drawio.svg)

---

## 主要思想

由于其模块化、面向对象的设计，gem5 可以被视为一组可以组合在一起形成模拟的组件。

组件的类型包括*板子*、*处理器*、*内存系统*和*缓存层次结构*：

- **板子 (Board)**：系统的"骨干"。你将组件插入到板子上。板子还包含系统级的东西，如设备、工作负载等。板子的工作是协商其他组件之间的连接。
- **处理器 (Processor)**：处理器连接到板子，并有一个或多个*核心*。
- **缓存层次结构 (Cache hierarchy)**：缓存层次结构是一组可以连接到处理器和内存系统的缓存。
- **内存系统 (Memory system)**：内存系统是一组可以连接到缓存层次结构的内存控制器和内存设备。

---

## 关于与 gem5 模型关系的简要说明

gem5 中的 C++ 代码指定了*参数化的***模型**（在大多数 gem5 文献中通常称为 "SimObjects"）。这些模型然后在 Python 脚本中实例化。

标准库是一种将这些模型*包装*在标准 API 中的方法，我们称之为*组件*。标准库由预制的 Python 脚本组成，这些脚本实例化 gem5 提供的这些模型。

gem5 模型是细粒度的概念，我们进一步将其划分为子模型或硬核参数意义不大（例如，一个*核心*）。组件在更粗粒度的概念上工作，通常包含许多用合理参数实例化的模型。例如，一个*处理器*包含多个核心，并指定它们如何连接到总线和彼此，所有参数都设置为合理的值。

如果你想创建一个新组件，建议*扩展*（即子类化）标准库中的组件或创建新组件。这允许你选择组件内的模型及其参数值。我们将在接下来的讲座中看到一些这样的例子。

---

## 让我们开始吧！

<!-- _class: code-80-percent -->

在 [`materials/02-Using-gem5/01-stdlib/01-components.py`](https://github.com/gem5bootcamp/2024/blob/main/materials/02-Using-gem5/01-stdlib/01-components.py) 中，你会看到已经为你包含了一些导入。

```python
from gem5.components.boards.simple_board import SimpleBoard
from gem5.components.processors.simple_processor import SimpleProcessor
from gem5.components.cachehierarchies.ruby.mesi_two_level_cache_hierarchy import (
    MESITwoLevelCacheHierarchy,
)
from gem5.components.memory.single_channel import SingleChannelDDR4_2400
from gem5.components.processors.cpu_types import CPUTypes
from gem5.isas import ISA
from gem5.resources.resource import obtain_resource
from gem5.simulate.simulator import Simulator
```

---

## 让我们构建一个带缓存层次结构的系统

```python
cache_hierarchy = MESITwoLevelCacheHierarchy(
    l1d_size="16kB",
    l1d_assoc=8,
    l1i_size="16kB",
    l1i_assoc=8,
    l2_size="256kB",
    l2_assoc=16,
    num_l2_banks=1,
)
```

`MESITwoLevelCacheHierarchy` 是一个表示两级 MESI 缓存层次结构的组件。
这使用了 [Ruby 内存模型](05-cache-hierarchies.md)。

缓存层次结构的组件使用 L1 和 L2 缓存的大小和关联度进行参数化。

---

## 接下来，让我们添加一个内存系统

```python
memory = SingleChannelDDR4_2400()
```

此组件表示单通道 DDR3 内存系统。

有一个 `size` 参数可用于指定模拟系统的内存系统大小。你可以减小大小以节省模拟时间，或使用内存类型的默认值（例如，一个 DDR3 通道默认为 8 GiB）。

还有多通道内存可用。
我们将在[内存系统](06-memory.md)中更详细地介绍这一点。

---

## 接下来，让我们添加一个处理器

```python
processor = SimpleProcessor(cpu_type=CPUTypes.TIMING, isa=ISA.ARM, num_cores=1)
```

`SimpleProcessor` 是一个允许你自定义底层核心模型的组件。

`cpu_type` 参数指定要使用的 CPU 模型类型。

---

## 接下来，将组件插入到板子上

`SimpleBoard` 是一个可以在系统调用仿真 (SE) 模式下运行任何 ISA 的板子。
它之所以"简单"是因为 SE 模式相对简单。
大多数板子绑定到特定的 ISA，需要更复杂的设计来运行全系统 (FS) 模拟。

```python
board = SimpleBoard(
    clk_freq="3GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
)
```

---

## 接下来，设置工作负载

```python
board.set_workload(obtain_resource("arm-gapbs-bfs-run"))
```

`obtain_resource` 函数下载运行指定工作负载所需的文件。在这种情况下，"arm-gapbs-bfs-run" 是来自 GAP 基准测试套件的 BFS 工作负载。

---

### gem5 资源

我们将在训练营的后面回到 gem5 资源，但现在，你可以将其视为下载和管理模拟所需文件的一种方式，但实际上并不指定模拟的计算机系统硬件。
通常它用于下载和管理工作负载、磁盘镜像、模拟所需的检查点。

这里我们可以搜索可用资源：<https://resources.gem5.org/>。

这是 arm-gapbs-bfs-run 资源：<https://resources.gem5.org/resources/arm-gapbs-bfs-run?version=1.0.0>。

---

## 接下来，设置模拟

设置模拟：

```python
simulator = Simulator(board=board)
simulator.run()
```

（稍后会详细介绍，但这是控制模拟循环的对象）。

### 运行它

```bash
gem5-mesi 01-components.py
```

---

<!-- _class: code-70-percent -->

## 输出

```text
Generate Time:       0.00462
Build Time:          0.00142
Graph has 1024 nodes and 10496 undirected edges for degree: 10
Trial Time:          0.00010
Trial Time:          0.00008
Trial Time:          0.00008
Trial Time:          0.00008
Trial Time:          0.00008
Trial Time:          0.00009
Trial Time:          0.00008
Trial Time:          0.00008
Trial Time:          0.00008
Trial Time:          0.00011
Average Time:        0.00009
```

### stats.txt

```text
simSeconds                                   0.009093
simTicks                                   9093461436
```

---

<!-- _class: two-col -->

## gem5 中包含的组件

```text
gem5/src/python/gem5/components
----/boards
----/cachehierarchies
----/memory
----/processors

gem5/src/python/gem5/prebuilt
----/demo/x86_demo_board
----/riscvmatched
```

###

- gem5 标准库位于 [`src/python/gem5`](../../gem5/src/python/gem5/)
- 两种类型
  - 预构建：具有设定参数的完整系统
  - 组件：用于构建系统的组件
- 预构建
  - Demo：只是用于构建的示例
  - riscvmatched：SiFive Unmatched 的模型

---

<!-- _class: two-col -->

## 组件：板子

```text
gem5/src/python/gem5/components
----/boards
    ----/simple
    ----/arm_board
    ----/riscv_board
    ----/x86_board
----/cachehierarchies
----/memory
----/processors
```

###

- 板子：要插入的东西
  - 具有 "set_workload" 和 "connect_things"
- Simple：仅 SE 模式，可配置
- Arm、RISC-V 和 X86 版本用于全系统模拟

---

<!-- _class: two-col -->

## 组件：缓存层次结构

```text
gem5/src/python/gem5/components
----/boards
----/cachehierarchies
    ----/chi
    ----/classic
    ----/ruby
----/memory
----/processors
```

###

- 与处理器和内存有固定接口
- **Ruby：**详细的缓存一致性和互连
- **CHI：**在 Ruby 中实现的基于 Arm CHI 的协议
- **经典缓存：**具有不灵活一致性的交叉开关层次结构

---

## 关于缓存层次结构的更多信息

- 快速提醒：不同的协议需要不同的 gem5 二进制文件
- 任何二进制文件都可以使用经典缓存
- 每个 gem5 二进制文件只能使用一个 Ruby 协议

### 在你的代码空间中，我们有一些预构建的二进制文件

- `gem5`: CHI (Fully configurable; based on Arm CHI)
- `gem5-mesi`: MESI_Two_Level (Private L1s, Shared L2)
- `gem5-vega`: GPU_VIPER (CPU: Private L1/L2 core pairs, shared L3; GPU: Private L1, shared L2)

---

<!-- _class: two-col -->

## 组件：内存系统

```text
gem5/src/python/gem5/components
----/boards
----/cachehierarchies
----/memory
    ----/single_channel
    ----/multi_channel
    ----/dramsim
    ----/dramsys
    ----/hbm
----/processors
```

###

- 预配置的 (LP)DDR3/4/5 DIMM
  - 单通道和多通道
- 与 DRAMSim 和 DRAMSys 集成
  - 不需要用于准确性，但对比较很有用
- HBM：一个 HBM 堆栈

---

<!-- _class: two-col -->

## 组件：处理器

```text
gem5/src/python/gem5/components
----/boards
----/cachehierarchies
----/memory
----/processors
    ----/generators
    ----/simple
    ----/switchable
```

###

- 主要是"可配置的"处理器，用于构建。
- 生成器
  - 合成流量，但表现得像处理器。
  - 具有线性、随机和更有趣的模式
- Simple
  - 仅默认参数，一个 ISA。
- Switchable
  - 我们稍后会看到，但你可以在模拟期间从一个切换到另一个。

---

## 关于处理器的更多信息

- 处理器由核心组成。
- 核心有一个 "BaseCPU" 作为成员。这是实际的 CPU 模型。
- `Processor` 是与 `CacheHierarchy` 和 `Board` 接口的内容
- 处理器是有组织的、结构化的核心集合。它们定义核心如何相互连接以及如何通过标准接口与外部组件和板子连接。

### gem5 有三种（或四种或五种）不同的处理器模型

更多详细信息将在[CPU 模型](04-cpu-models.md)部分中介绍。

- `CPUTypes.TIMING`：一个简单的按序 CPU 模型
  - 这是一个"单周期" CPU。每条指令需要取指时间并立即执行。
  - 内存操作采用内存系统的延迟。
  - 适用于进行以内存为中心的研究，但对大多数研究来说不够好。

---

## CPU 类型

CPU 类型的其他选项

- `CPUTypes.O3`：乱序 CPU 模型
  - 基于 Alpha 21264 的高度详细模型。
  - 具有 ROB、物理寄存器、LSQ 等。
  - 如果你想配置这个，不要使用 `SimpleProcessor`。
- `CPUTypes.MINOR`：按序核心模型
  - 高性能按序核心模型。
  - 可配置的四级流水线
  - 如果你想配置这个，不要使用 `SimpleProcessor`。
- `CPUTypes.ATOMIC`：用于"原子"模式（稍后详细介绍）
- `CPUTypes.KVM`：稍后详细介绍

---

## 一个稍微复杂的示例

我们已经介绍了一个基本的"入门"示例，然后介绍了我们提供的各种组件。
让我们创建一个更复杂的示例，结合标准库提供的更多功能。

在这个示例中，我们将在 X86 板子上创建一个使用多个核心的系统，在全系统模式下运行。

### 首先：让我们讨论 SE 模式和 FS 模式

SE 模式将应用程序系统调用中继到主机 OS。这意味着我们不需要模拟 OS 来运行应用程序。

此外，我们可以访问主机资源，例如要动态链接的库文件。

---

## FS 模式

![FS mode bg 25%](/bootcamp/02-Using-gem5/01-stdlib-imgs/fs-mode.png)

---

## SE 模式

![SE mode bg 45%](/bootcamp/02-Using-gem5/01-stdlib-imgs/se-mode.png)

---

## FS 和 SE 模式：常见陷阱

- **不要将 SE 模式视为"更快但功能相同的 FS 模式"**：你必须了解你正在模拟什么以及它是否会影响结果。
- **并非所有系统调用都会被实现**：我们希望实现所有系统调用，但 Linux 变化很快。我们试图覆盖常见用例，但我们无法覆盖所有内容。如果缺少系统调用，你可以实现它、忽略它或使用 FS 模式。
- **具有提升权限的二进制文件在 SE 模式下不起作用**：如果你正在运行需要提升权限的二进制文件，你需要在 FS 模式下运行它。

---

## SE 模式：如有疑问，使用 FS 模式

FS 模式可以做 SE 模式所做的一切（甚至更多！），但可能需要更长时间才能到达感兴趣的区域。每次都必须等待 OS 启动（除非你[加速模拟](08-accelerating-simulation.md)）。

但是，由于 SE 模式不模拟 OS，你可能会错过通过系统调用、I/O 或操作系统触发的重要事件，这可能意味着你的模拟系统不能正确反映真实系统。

**仔细思考 SE 模式在做什么以及它是否适合你的用例。**如有疑问，使用 FS 模式。如果你不确定，使用 SE 模式（通常）不值得冒险。

---

## 如何使用标准库指定 FS 模式

转到 [`materials/02-Using-gem5/01-stdlib/01-02-fs-mode.py`](https://github.com/gem5bootcamp/2024/blob/main/materials/02-Using-gem5/01-stdlib/01-02-fs-mode.py) 并处理此示例。

---

## 模板代码（导入）

```python
from gem5.components.boards.x86_board import X86Board
from gem5.components.cachehierarchies.ruby.mesi_two_level_cache_hierarchy import (
    MESITwoLevelCacheHierarchy,
)
from gem5.components.memory.single_channel import SingleChannelDDR3_1600
from gem5.components.processors.cpu_types import CPUTypes
from gem5.components.processors.simple_switchable_processor import (
    SimpleSwitchableProcessor,
)
from gem5.isas import ISA
from gem5.resources.resource import obtain_resource
from gem5.simulate.exit_event import ExitEvent
from gem5.simulate.simulator import Simulator
```

---

## 更多模板代码

这添加了一个两级缓存层次结构和一个内存系统。

```python
cache_hierarchy = MESITwoLevelCacheHierarchy(
    l1d_size="16kB",
    l1d_assoc=8,
    l1i_size="16kB",
    l1i_assoc=8,
    l2_size="256kB",
    l2_assoc=16,
    num_l2_banks=1,
)

memory = SingleChannelDDR3_1600(size="3GB")
```

---

## 让我们添加一个 SimpleSwitchableProcessor

这里我们设置处理器。这是一个特殊的可切换处理器，必须指定起始核心类型和切换核心类型。一旦配置被实例化，用户可以调用 `processor.switch()` 从起始核心类型切换到切换核心类型。在这个模拟中，我们首先使用 Timing 核心来模拟 OS 启动，然后切换到乱序 (O3) 核心来运行我们希望在启动后运行的命令。

```python
processor = SimpleSwitchableProcessor(
    starting_core_type=CPUTypes.TIMING,
    switch_core_type=CPUTypes.O3,
    isa=ISA.X86,
    num_cores=2,
)
```

---

## 接下来，将组件插入到板子上

这里我们设置板子。X86Board 允许进行全系统 X86 模拟。

```python
board = X86Board(
    clk_freq="3GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
)
```

---

## Linux 启动时要做什么

这里我们设置全系统工作负载。
X86Board 的 `set_kernel_disk_workload` 函数接受一个内核、一个磁盘镜像，以及可选地，一个要运行的命令。

这是系统启动后要运行的命令。第一个 `m5 exit` 将停止模拟，以便我们可以将 CPU 核心从 KVM 切换到 timing，然后继续模拟以运行 echo 命令，休眠一秒，然后再次调用 `m5 exit` 以终止模拟。模拟结束后，你可以检查 `m5out/system.pc.com_1.device` 以查看 echo 输出。

```python
command = (
    "m5 exit;"
    + "echo 'This is running on O3 CPU cores.';"
    + "sleep 1;"
    + "m5 exit;"
)
```

---

## 设置工作负载

这是一种稍微复杂的方式来指定工作负载。
这里我们指定内核、磁盘镜像以及系统启动后要运行的命令。

```python
board.set_kernel_disk_workload(
    kernel=obtain_resource("x86-linux-kernel-4.4.186"),
    disk_image=obtain_resource("x86-ubuntu-18.04-img"),
    readfile_contents=command,
)
```

---

## 创建模拟器对象

这里我们设置模拟器。我们将板子传递给模拟器并运行它，但也指定当模拟以 `EXIT` 退出事件退出时要做什么。在这种情况下，我们在第一个退出事件上调用 `processor.switch` 函数。对于第二个，将触发默认操作，退出模拟器。

警告：这使用生成器表达式来创建要调用的函数元组。

```python
simulator = Simulator(
    board=board,
    on_exit_event={ExitEvent.EXIT: (func() for func in [processor.switch])},
)

simulator.run()
```

---

## 退出事件生成器做什么？

与此等效的是运行以下命令：

```python
simulator = Simulator(board=board)

simulator.run()
processor.switch()
simulator.run()
```

---

## 模拟循环

![Simulation Loop bg 90%](/bootcamp/02-Using-gem5/01-stdlib-imgs/simulation-loop.png)

---

## 退出事件

回到我们实现的内容：

```python
simulator = Simulator(
    board=board,
    on_exit_event={ExitEvent.EXIT: (func() for func in [processor.switch])},
)

simulator.run()
```

我们传递对象以通过 Python 生成器表达式精确指定在每个退出事件类型上要做什么。在这种情况下，生成器产生 `processor.switch`，当退出事件 `ExitEvent.EXIT` 被触发时调用它。
当第二个退出被触发时，由于没有剩余内容可产生，将触发默认操作。默认操作是退出模拟循环。

---

## 退出事件类型

- ExitEvent.EXIT
- ExitEvent.CHECKPOINT
- ExitEvent.FAIL
- ExitEvent.SWITCHCPU
- ExitEvent.WORKBEGIN
- ExitEvent.WORKEND
- ExitEvent.USER_INTERRUPT
- ExitEvent.MAX_TICK

模拟器对这些事件有默认行为，但它们可以被覆盖。

---

## 关键思想：`Simulator` 对象控制模拟

为了阐述我们对 gem5 的理解：

- *models* (or *SimObjects*) are the fine-grained objects that are connected together in Python scripts to form a simulation.
- *components* are the coarse-grained objects that are connected defined as a set of configured models in Python scripts to form and delivered as part of the Standard Library
- The standard library allows users to specify a board and specify the properties of the board by specify the components that are connected to it.
- The Simulator takes a board and launches the simulation and gives an API which allows for control of the simulation: specifying the simulation stopping and restarting condition, replacing components "on the fly", defining when the simulation should stop and start, etc.

有关模拟器源代码，请参见 [`src/python/gem5/simulate/simulator.py`](../../gem5/src/python/gem5/simulate/simulator.py)。

我们将在[加速模拟](08-accelerating-simulation.md)中了解更多信息。

---

## 模拟器参数

- **`board`**: The `Board` to simulate (required)
- **`full_system`**: Whether to simulate a full system (default: `False`, can be inferred from the board, not needed specified in most cases)
- **`on_exit_event`**: A complex data structure that allows you to control the simulation. The simulator exits for many reasons, this allows you to customize what happens. We just saw an example.
- **`checkpoint_path`**: If we're restoring from a checkpoint, this is the path to the checkpoint. More on checkpoints later.
- **`id`**: An optional name for this simulation. Used in multisim. More on this in the future.

---

## Some useful functions

- **`run()`**: Run the simulation
- **`get/set_max_ticks(max_tick)`**: Set the absolute tick to stop simulation. Generates a `MAX_TICK` exit event that can be handled.
- **`schedule_max_insts(inst_number)`**: Set the number of instructions to run before stopping. Generates a `MAX_INSTS` exit event that can be handled. Note that if running multiple cores, this happens if *any* core reaches this number of instructions.
- **`get_stats()``**: Get the statistics from the simulation. Returns a dictionary of statistics.

有关更多详细信息，请参见 [`src/python/gem5/simulate/simulator.py`](../../gem5/src/python/gem5/simulate/simulator.py)。

我们将在训练营的其他部分详细介绍如何使用 `Simulator` 对象。

---

## 标准库组件

我们已经看到了如何使用标准库组件。

现在我们还没有看到如何创建新组件。

### 围绕*扩展*和*封装*设计

> 不是为"参数化"设计的

如果你想创建具有不同参数的处理器/缓存层次结构等：
使用面向对象的语义进行扩展。

让我们看一个示例。

---

## 快速回顾 gem5 的架构

我们现在将创建一个新组件。

我们将专门化/扩展 "BaseCPUProcessor" 以创建一个具有单个乱序核心的 ARM 处理器。

![diagram of models, stdlib, and simulation control bg right:60% fit](/bootcamp/02-Using-gem5/01-stdlib-imgs/gem5-software-arch.drawio.svg)

---

## 让我们创建一个具有乱序核心的处理器

使用 [`materials/02-Using-gem5/01-stdlib/02-processor.py`](https://github.com/gem5bootcamp/2024/blob/main/materials/02-Using-gem5/01-stdlib/02-processor.py) 作为起点。

与上一个示例基本相同，但现在我们有以下代码，而不是使用 `SimpleProcessor`：

```python
my_ooo_processor = MyOutOfOrderProcessor(
    width=8, rob_size=192, num_int_regs=256, num_fp_regs=256
)
```

---

<!-- _class: two-col -->

## 创建 BaseCPUProcessor/Core 的子类

要专门化参数，请创建一个子类。

> 记住，不要直接更改 `BaseCPUProcessor` 的参数。

```python
from m5.objects import ArmO3CPU
from m5.objects import TournamentBP
class MyOutOfOrderCore(BaseCPUCore):
    def __init__(self, width, rob_size,
                 num_int_regs, num_fp_regs):
        super().__init__(ArmO3CPU(), ISA.Arm)
```

参见 [`...gem5/components/processors/base_cpu_core.py`](../../gem5/src/python/gem5/components/processors/base_cpu_core.py)
和 [`src/cpu/o3/BaseO3CPU.py`](../../gem5/src/cpu/o3/BaseO3CPU.py)

```python
  self.core.fetchWidth = width
  self.core.decodeWidth = width
  self.core.renameWidth = width
  self.core.issueWidth = width
  self.core.wbWidth = width
  self.core.commitWidth = width

  self.core.numROBEntries = rob_size
  self.core.numPhysIntRegs = num_int_regs
  self.core.numPhysFloatRegs = num_fp_regs

  self.core.branchPred = TournamentBP()

  self.core.LQEntries = 128
  self.core.SQEntries = 128
```

---

## 现在来看 `MyOutOfOrderProcessor`

`BaseCPUProcessor` 假设一个核心列表，这些核心是 `BaseCPUCores`。

```python
class MyOutOfOrderProcessor(BaseCPUProcessor):
    def __init__(self, width, rob_size, num_int_regs, num_fp_regs):
        cores = [MyOutOfOrderCore(width, rob_size, num_int_regs, num_fp_regs)]
        super().__init__(cores)
```

我们只创建一个核心，并将参数传递给它。

---

## 现在，运行它并比较！

```bash
gem5-mesi 02-processor.py
```

需要 2-3 分钟

### 问题

- 这比简单的按序更快吗？
- 使用 `--outdir=m5out/ooo` 和 `--outdir=simple`
- 比较 stats.txt（哪个统计信息？）

---

## 统计信息比较

### Simple CPU

```text
simSeconds                                   0.009073
board.processor.cores.core.ipc               0.362353
```

### 我们的乱序 CPU

```text
simSeconds                                   0.003114
board.processor.cores.core.ipc               1.055705
```

### 主机秒数：`17.09` vs `43.39`

O3 CPU 的模拟时间超过 2 倍。更高的保真度需要更多时间。

---

## 总结

- gem5 标准库是一组组件，可用于构建为你完成大部分工作的模拟。
- 标准库围绕*扩展*和*封装*设计。
- 组件的主要类型是*板子*、*处理器*、*内存系统*和*缓存层次结构*。
- 标准库设计为模块化和面向对象。
- `Simulator` 对象控制模拟。
