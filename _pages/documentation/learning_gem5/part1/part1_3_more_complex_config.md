---
layout: documentation
title: 向配置脚本添加缓存
doc: Learning gem5
parent: part1
permalink: /documentation/learning_gem5/part1/cache_config/
author: Jason Lowe-Power
---

gem5 v24.1 更复杂的配置
===============================

**注意：下一节中的材料取自 2024 gem5 bootcamp 第一部分第 2 节。幻灯片链接在 [这里](https://bootcamp.gem5.org/#02-Using-gem5/01-stdlib)**

在上一节中，我们学习了设置 gem5 Python 配置脚本的基础知识。
上一节的配置脚本使用了 X86DemoBoard，它预先配置了缓存、内存等。
在本节中，我们将学习如何使用 gem5 标准库中的其他组件来设置模拟。

什么是 gem5 标准库？
----------------------------------

gem5 标准库提供了一组预定义的组件，可用于在配置脚本中定义系统。
如果没有标准库，您将不得不定义模拟的每个部分，即使是最基本的模拟，也可能导致脚本包含数百行代码。

主要思想
---------

由于其模块化、面向对象的设计，gem5 可以被看作是一组可以插入在一起形成模拟的组件。
组件的类型包括板 (boards)、处理器 (processors)、内存系统 (memory systems) 和缓存层次结构 (cache hierarchies)：

- Board (板): 系统的“骨干”。您将组件插入板中。板还包含系统级的东西，如设备、工作负载等。板的工作是协商其他组件之间的连接。
- Processor (处理器): 处理器连接到板并具有一个或多个核心。
- Cache hierarchy (缓存层次结构): 缓存层次结构是一组可以连接到处理器和内存系统的缓存。
- Memory system (内存系统): 内存系统是一组可以连接到缓存层次结构的内存控制器和内存设备。

与 gem5 模型的名为
---------------------------

gem5 中的 C++ 代码指定了参数化模型（在大多数 gem5 文献中通常称为 "SimObjects"）。
然后在 gem5 标准库中的预制 Python 脚本中实例化这些模型。

标准库是一种将这些模型包装在标准 API 中成为我们所谓的组件的方法。

gem5 模型是细粒度的概念，而组件是粗粒度的，通常包含许多用合理参数实例化的模型。
例如，一个 gem5 模型可以是一个核心，而一个组件可以是一个具有多个核心的处理器，它还指定了总线连接并将参数设置为合理的值。

如果您想创建一个新组件，鼓励您扩展（即子类化）标准库中的组件或创建新组件。
这允许您选择组件内的模型及其参数的值。

设置配置脚本
-----------------------------------
首先，让我们制作一个配置文件：

```bash
mkdir configs/tutorial/part1/
touch configs/tutorial/part1/components.py
```

让我们添加导入：

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

接下来，让我们添加我们的缓存层次结构：

```python
cache_hierarchy = MESITwoLevelCacheHierarchy(
    l1d_size="16KiB",
    l1d_assoc=8,
    l1i_size="16KiB",
    l1i_assoc=8,
    l2_size="256KiB",
    l2_assoc=16,
    num_l2_banks=1,
)
```

MESITwoLevelCacheHierarchy 是一个代表两级 MESI 缓存层次结构的组件。
这使用了 Ruby 内存模型。有关 gem5 中缓存的更多信息，请参见 [这里](https://bootcamp.gem5.org/#02-Using-gem5/05-cache-hierarchies)。

缓存层次结构的组件使用 L1 和 L2 缓存的大小和关联度进行参数化。

接下来，让我们添加一个内存系统：

```python
memory = SingleChannelDDR4_2400()
```

此组件代表单通道 DDR3 内存系统。

有一个 size 参数可用于指定模拟系统的内存系统大小。
您可以减小大小以节省模拟时间，或使用内存类型的默认值（例如，一个 DDR3 通道默认为 8 GiB）。
还有多通道内存可用。您可以查看 [这些](https://bootcamp.gem5.org/#02-Using-gem5/06-memory) gem5 2024 bootcamp 幻灯片以获取更多信息。

接下来，让我们添加一个处理器：

```python
processor = SimpleProcessor(cpu_type=CPUTypes.TIMING, isa=ISA.ARM, num_cores=1)
```

`SimpleProcessor` 是一个允许您自定义底层核心模型的组件。
`cpu_type` 参数指定要使用的 CPU 模型类型。

接下来，让我们添加一个板并插入组件：

```python
board = SimpleBoard(
    clk_freq="3GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
)
```

SimpleBoard 可以在系统调用仿真 (SE) 模式下运行任何 ISA。
它是 "Simple" 的，因为 SE 模式相对简单。
大多数板都绑定到特定 ISA，并且需要更复杂的设计来运行全系统 (FS) 模拟。
您可以在 `src/python/gem5/components/boards` 的 gem5 标准库中找到板。演示板位于 `src/python/gem5/prebuilt/demo` 中。

接下来，设置工作负载：

```python
board.set_workload(obtain_resource("arm-gapbs-bfs-run"))
```

obtain_resource 函数下载运行指定工作负载所需的文件。
在这种情况下，"arm-gapbs-bfs-run" 是来自 GAP Benchmark Suite 的 BFS 工作负载。
您可以在 gem5 资源网站 [这里](https://resources.gem5.org/resources/arm-gapbs-bfs-run?version=1.0.0) 查看有关此资源的更多信息。
通常，您可以在 [gem5 资源网站](https://resources.gem5.org/) 浏览所有 gem5 资源。

接下来，设置模拟：

```python
simulator = Simulator(board=board)
simulator.run()
```

您现在可以使用以下命令运行模拟

```bash
./build/ALL/gem5.opt configs/tutorial/part1/components.py

```

输出应如下所示：

```txt
gem5 Simulator System.  https://www.gem5.org
gem5 is copyrighted software; use the --copyright option for details.

gem5 version 24.1.0.0
gem5 compiled Dec 13 2024 14:59:49
gem5 started Dec 16 2024 16:34:29
gem5 executing on amarillo, pid 575999
command line: ./build/ALL/gem5.opt gem5-dev/testing-website-tutorial/tutorial/part1/components.py

info: Using default config
Global frequency set at 1000000000000 ticks per second
src/base/statistics.hh:279: warn: One of the stats is a legacy stat. Legacy stat is a stat that does not belong to any statistics::Group. Legacy stat is deprecated.
src/base/statistics.hh:279: warn: One of the stats is a legacy stat. Legacy stat is a stat that does not belong to any statistics::Group. Legacy stat is deprecated.
board.remote_gdb: Listening for connections on port 7003
src/sim/simulate.cc:199: info: Entering event queue @ 0.  Starting simulation...
src/mem/ruby/system/Sequencer.cc:704: warn: Replacement policy updates recently became the responsibility of SLICC state machines. Make sure to setMRU() near callbacks in .sm files!
src/sim/syscall_emul.cc:86: warn: ignoring syscall set_robust_list(...)
src/sim/syscall_emul.cc:97: warn: ignoring syscall rseq(...)
      (further warnings will be suppressed)
src/sim/mem_state.cc:448: info: Increasing stack size by one page.
src/sim/syscall_emul.hh:1117: warn: readlink() called on '/proc/self/exe' may yield unexpected results in various settings.
      Returning '/home/bees/.cache/gem5/arm-gapbs-bfs'
src/arch/arm/insts/pseudo.cc:174: warn:         instruction 'bti' unimplemented
src/sim/syscall_emul.cc:86: warn: ignoring syscall mprotect(...)
src/sim/syscall_emul.cc:86: warn: ignoring syscall sched_getaffinity(...)
src/sim/mem_state.cc:448: info: Increasing stack size by one page.
src/sim/mem_state.cc:448: info: Increasing stack size by one page.
Generate Time:       0.00503
Build Time:          0.00201
Graph has 1024 nodes and 10496 undirected edges for degree: 10
Trial Time:          0.00011
Trial Time:          0.00010
Trial Time:          0.00010
Trial Time:          0.00009
Trial Time:          0.00011
Trial Time:          0.00010
Trial Time:          0.00010
Trial Time:          0.00010
Trial Time:          0.00010
Trial Time:          0.00010
Trial Time:          0.00013
Average Time:        0.00010

```

gem5 stdlib 文件结构
--------------------------

gem5 stdlib 位于 `src/python/gem5/`。
这里感兴趣的是 `components` 和 `prebuilt` 文件夹：

```txt
gem5/src/python/gem5/components
----/boards
----/cachehierarchies
----/memory
----/processors

gem5/src/python/gem5/prebuilt
----/demo
----/riscvmatched
```

`components` 文件夹包含可用于构建系统的组件。`prebuilt` 文件夹包含各种预构建系统，包括用于 X86、Arm 和 RISC-V isa 的演示系统，以及 riscvmatched，它是 SiFive Unmatched 的模型。

```txt
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

Board 是组件插入的地方。SimpleBoard 只有 SE 模式，ArmBoard 只有 FS 模式，X86Board 和 RiscvBoard 既有 FS 模式也有 SE 模式。

```txt
gem5/src/python/gem5/components
----/boards
----/cachehierarchies
    ----/chi
    ----/classic
    ----/ruby
----/memory
----/processors
```

Cache hierarchy 组件具有到处理器和内存的固定接口。

- Ruby: 详细的缓存一致性和互连
- CHI: 基于 Arm CHI 的协议，在 Ruby 中实现
- Classic caches: 交叉开关的层次结构，具有不灵活的一致性

从 gem5 v24.1 开始，可以将任何 Ruby 缓存一致性协议与 ALL gem5 构建一起使用。
这是预编译二进制文件中包含的构建。

```txt
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

memory 目录包含预配置的 (LP)DDR3/4/5 DIMM。提供单通道和多通道内存系统。
与 DRAMSim 和 DRAMSys 集成，虽然不需要精度，但对于比较很有用。
`hbm` 目录是一个 HBM 堆栈。

```txt
gem5/src/python/gem5/components
----/boards
----/cachehierarchies
----/memory
----/processors
    ----/generators
    ----/simple
    ----/switchable
```

`processors` 目录主要包含可配置的处理器以供构建。

Generators 创建合成流量，但像处理器一样行动。它们有线性、随机和更有趣的模式。

Simple processors 只有默认参数和一个 ISA。

Switchable processors 允许您在模拟期间更改处理器类型。

关于处理器的更多信息
------------------

处理器由核心组成。
核心有一个 "BaseCPU" 作为成员。这是实际的 CPU 模型。
`Processor` 是与 `CacheHierarchy` 和 `Board` 接口的东西
处理器是有组织的、结构化的核心集。它们通过标准接口定义核心如何相互连接以及与外部组件和板连接。

**gem5 有三种（或四种或五种）不同的处理器模型**

它们如下：

`CPUTypes.TIMING`: 一个简单的按序 CPU 模型
这是一个“单周期” CPU。每条指令花费时间来获取并立即执行。
内存操作花费内存系统的延迟。
适合做以内存为中心的研究，但不适合大多数研究。

`CPUTypes.O3`: 一个乱序 CPU 模型
基于 Alpha 21264 的高度详细模型。
具有 ROB、物理寄存器、LSQ 等。
如果您想配置它，请不要使用 SimpleProcessor。

`CPUTypes.MINOR`: 一个按序核心模型
一个高性能的按序核心模型。
可配置的四级流水线
如果您想配置它，请不要使用 SimpleProcessor。

`CPUTypes.ATOMIC`: 用于“原子”模式（稍后详细介绍）
`CPUTypes.KVM`: 这在 [2024 gem5 bootcamp](https://bootcamp.gem5.org/#02-Using-gem5/08-accelerating-simulation) 中有详细介绍。


FS vs SE 模式
-------------

SE 模式将应用程序系统调用转发给主机操作系统。这意味着我们不需要模拟操作系统即可运行应用程序。

此外，我们可以访问主机资源，例如要动态链接的库文件。

不要将 SE 模式视为“FS 但更快”：您必须了解您正在模拟什么以及它是否会影响结果。
并非所有系统调用都会被实现：我们很乐意实现所有系统调用，但 Linux 变化很快。我们尝试涵盖常见的用例，但我们无法涵盖所有内容。如果缺少系统调用，您可以实现它、忽略它或使用 FS 模式。
具有提升权限的二进制文件在 SE 模式下不起作用：如果您运行的二进制文件需要提升权限，则需要在 FS 模式下运行它。

FS 模式执行 SE 模式执行的所有操作（以及更多！），但可能需要更长的时间才能到达感兴趣的区域。您每次都必须等待操作系统启动（除非您加速模拟）。

但是，由于 SE 模式不模拟操作系统，因此您可能会错过通过系统调用、I/O 或操作系统触发的重要事件，这意味着您的模拟系统无法正确反映真实系统。

仔细思考 SE 模式正在做什么，以及它是否适合您的用例。如果有疑问，请使用 FS 模式。如果您不确定，使用 SE 模式通常不值得冒险。

完整启动示例
-----------------

有关在 X86 系统上运行 Ubuntu 24.04 完整启动的配置文件示例，请参阅 [gem5 stdlib 文档](../../gem5-stdlib/2-tutorial-x86-fs.md)。值得注意的是，我们需要定义一个退出事件处理程序才能完成整个启动：

```python
def exit_event_handler():
    print("First exit: kernel booted")
    yield False  # gem5 is now executing systemd startup
    print("Second exit: Started `after_boot.sh` script")
    # The after_boot.sh script is executed after the kernel and systemd have
    # booted.
    # Here we switch the CPU type to Timing.
    print("Switching to Timing CPU")
    processor.switch()
    yield False  # gem5 is now executing the `after_boot.sh` script
    print("Third exit: Finished `after_boot.sh` script")
    # The after_boot.sh script will run a script if it is passed via
    # m5 readfile. This is the last exit event before the simulation exits.
    yield True

simulator = Simulator(
    board=board,
    on_exit_event={
        ExitEvent.EXIT: exit_event_handler(),
    },
)
```

在第一个退出事件中，生成器产生 False 以继续模拟。在第二个退出事件中，生成器切换 CPU，然后再次产生 False。在第三个退出事件中，它产生 `True` 以结束模拟。

有各种类型的退出事件。模拟器对这些事件有默认行为，但它们可以被覆盖。

```python
ExitEvent.EXIT
ExitEvent.CHECKPOINT
ExitEvent.FAIL
ExitEvent.SWITCHCPU
ExitEvent.WORKBEGIN
ExitEvent.WORKEND
ExitEvent.USER_INTERRUPT
ExitEvent.MAX_TICK
```

关键思想：Simulator 对象控制模拟
--------------------------------------------------

定位 gem5 的概念：

models (或 SimObjects) 是细粒度对象，在 Python 脚本中连接在一起形成模拟。
components 是粗粒度对象，定义为 Python 脚本中的一组配置模型，并作为标准库的一部分交付
标准库允许用户指定一个板，并通过指定连接到它的组件来指定板的属性。
Simulator 接收一个板并启动模拟，并给出一个 API，允许控制模拟：指定模拟停止和重新启动条件，"即时"替换组件，定义模拟何时停止和启动等。
有关 Simulator 源代码，请参见 [src/python/gem5/simulate/simulator.py](https://github.com/gem5/gem5/blob/stable/src/python/gem5/simulate/simulator.py)。

Simulator 参数如下：

board: 要模拟的 Board（必需）
full_system: 是否模拟全系统（默认值：False，可以从板推断，在大多数情况下不需要指定）
on_exit_event: 一个复杂的数据结构，允许您控制模拟。模拟器因多种原因退出，这允许您自定义发生的情况。我们刚刚看了一个例子。
checkpoint_path: 如果我们从检查点恢复，这是检查点的路径。稍后会有更多关于检查点的内容。
id: 此模拟的可选名称。用于 multisim。将来会有更多关于此的内容。

一些有用的函数如下：

run(): 运行模拟
get/set_max_ticks(max_tick): 设置停止模拟的绝对 tick。生成一个可以处理的 MAX_TICK 退出事件。
schedule_max_insts(inst_number): 设置在停止之前运行的指令数。生成一个可以处理的 MAX_INSTS 退出事件。请注意，如果运行多个核心，如果任何核心达到此指令数，就会发生这种情况。
get_stats(): 获取模拟的统计信息。返回统计信息字典。

有关更多详细信息，请参阅 [src/python/gem5/simulate/simulator.py](https://github.com/gem5/gem5/blob/stable/src/python/gem5/simulate/simulator.py)。

创建新的标准库组件
-----------------------------------------

gem5 标准库是围绕扩展和封装设计的，而不是参数化。
如果您想创建一个具有不同参数的组件，请使用面向对象语义进行扩展。

我们现在将创建一个新组件。我们将特化/扩展 "BaseCPUProcessor" 以创建一个具有单个乱序核心的 ARM 处理器。

首先，让我们添加导入：

```python
from gem5.components.boards.simple_board import SimpleBoard
from gem5.components.cachehierarchies.ruby.mesi_two_level_cache_hierarchy import (
    MESITwoLevelCacheHierarchy,
)
from gem5.components.memory.single_channel import SingleChannelDDR4_2400
from gem5.resources.resource import obtain_resource
from gem5.simulate.simulator import Simulator
from gem5.isas import ISA

from gem5.components.processors.base_cpu_core import BaseCPUCore
from gem5.components.processors.base_cpu_processor import BaseCPUProcessor

from m5.objects import ArmO3CPU
from m5.objects import TournamentBP
```

接下来，让我们创建一个新的子类来特化核心的参数：

```python
class MyOutOfOrderCore(BaseCPUCore):
    def __init__(self, width, rob_size, num_int_regs, num_fp_regs):
        super().__init__(ArmO3CPU(), ISA.ARM)
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

接下来，让我们使用此核心创建一个处理器。`BaseCPUProcessor` 假设有一个是 `BaseCPUCores` 的核心列表。我们将只制作一个核心并将参数传递给它：

```python
class MyOutOfOrderProcessor(BaseCPUProcessor):
    def __init__(self, width, rob_size, num_int_regs, num_fp_regs):
        cores = [MyOutOfOrderCore(width, rob_size, num_int_regs, num_fp_regs)]
        super().__init__(cores)
```

接下来，让我们使用这些组件为模拟设置处理器：

```python
my_ooo_processor = MyOutOfOrderProcessor(
    width=8, rob_size=192, num_int_regs=256, num_fp_regs=256
)
```

最后，让我们设置模拟的其余部分：

```python
main_memory = SingleChannelDDR4_2400(size="2GB")

cache_hierarchy = MESITwoLevelCacheHierarchy(
    l1d_size="16kB",
    l1d_assoc=8,
    l1i_size="16kB",
    l1i_assoc=8,
    l2_size="256kB",
    l2_assoc=16,
    num_l2_banks=1,
)
board = SimpleBoard(
    processor=my_ooo_processor,
    memory=main_memory,
    cache_hierarchy=cache_hierarchy,
    clk_freq="3GHz",
)

board.set_workload(obtain_resource("arm-gapbs-bfs-run"))

simulator = Simulator(board)
simulator.run()
```

您现在可以使用以下命令运行此模拟，假设您的配置脚本名为 `config.py`：

```bash
./build/ALL/gem5.opt config.py
```

如果您有预构建的二进制文件，只需使用以下命令：

```bash
gem5 config.py
```

gem5 v21.0: 向配置脚本添加缓存
====================================================

以 [以前的配置脚本为起点](http://www.gem5.org/documentation/learning_gem5/part1/simple_config/)，本章将演练一个更复杂的配置。我们将向系统添加一个缓存层次结构，如下图所示。此外，本章还将涵盖了解 gem5 统计输出并将命令行参数添加到您的脚本。

![具有两级缓存层次结构的系统配置。](/pages/static/figures/advanced_config.png)

创建缓存对象
----------------------

我们将使用经典缓存 (classic caches)，而不是 ruby-intro-chapter，因为我们正在模拟单 CPU 系统，并且我们不关心模拟缓存一致性。我们将扩展 Cache SimObject 并为我们的系统配置它。首先，我们必须了解用于配置 Cache 对象的参数。

> **经典缓存和 Ruby**
>
> gem5 目前有两个完全不同的子系统来模拟系统中的片上缓存，“经典缓存”和“Ruby”。历史原因是 gem5 是来自密歇根州的 m5 和来自威斯康星州的 GEMS 的组合。GEMS 使用 Ruby 作为其缓存模型，而经典缓存来自 m5 代码库（因此称为“经典”）。这两个模型之间的区别在于 Ruby 旨在详细模拟缓存一致性。Ruby 的一部分是 SLICC，一种用于定义缓存一致性协议的语言。另一方面，经典缓存实现了简化且不灵活的 MOESI 一致性协议。
>
> 要选择使用哪个模型，您应该问自己要模拟什么。如果您正在模拟对缓存一致性协议的更改，或者一致性协议可能会对您的结果产生一阶影响，请使用 Ruby。否则，如果一致性协议对您不重要，请使用经典缓存。
>
> gem5 的一个长期目标是将这两个缓存模型统一为一个整体模型。

### 缓存 (Cache)

Cache SimObject 声明可以在 src/mem/cache/Cache.py 中找到。
此 Python 文件定义了您可以设置的 SimObject 参数。在底层，当实例化 SimObject 时，这些参数将传递给对象的 C++ 实现。`Cache` SimObject 继承自如下所示的 `BaseCache` 对象。

在 `BaseCache` 类中，有许多 *参数*。例如，`assoc` 是一个整数参数。某些参数，如 `write_buffers` 具有默认值，在这种情况下为 8。默认参数是 `Param.*` 的第一个参数，除非第一个参数是字符串。每个参数的字符串参数是对该参数是什么的描述（例如，`tag_latency = Param.Cycles("Tag lookup latency")` 意味着 `` tag_latency `` 控制“此缓存的命中延迟”）。

许多这些参数没有默认值，因此我们必须在调用 `m5.instantiate()` 之前设置这些参数。

* * * * *

现在，要创建具有特定参数的缓存，我们首先要在与 simple.py 相同的目录 `configs/tutorial/part1` 中创建一个名为 `caches.py` 的新文件。第一步是导入我们将在此文件中扩展的 SimObject。

```
from m5.objects import Cache
```

接下来，我们可以像对待任何其他 Python 类一样对待 BaseCache 对象并扩展它。我们可以将新缓存命名为任何我们想要的名称。让我们从制作 L1 缓存开始。

```
class L1Cache(Cache):
    assoc = 2
    tag_latency = 2
    data_latency = 2
    response_latency = 2
    mshrs = 4
    tgts_per_mshr = 20
```

在这里，我们设置了一些没有默认值的 BaseCache 参数。要查看所有可能的配置选项，并查找哪些是必需的，哪些是可选的，您必须查看 SimObject 的源代码。在这种情况下，我们使用的是 BaseCache。

我们已经扩展了 `BaseCache` 并设置了 `BaseCache` SimObject 中没有默认值的大多数参数。接下来，让我们再创建两个 L1Cache 的子类，L1DCache 和 L1ICache

```
class L1ICache(L1Cache):
    size = '16kB'

class L1DCache(L1Cache):
    size = '64kB'
```

让我们也创建一个具有一些合理参数的 L2 缓存。

```
class L2Cache(Cache):
    size = '256kB'
    assoc = 8
    tag_latency = 20
    data_latency = 20
    response_latency = 20
    mshrs = 20
    tgts_per_mshr = 12
```

既然我们已经指定了 `BaseCache` 所需的所有必要参数，我们所要做的就是实例化我们的子类并将缓存连接到互连。但是，将大量对象连接到复杂的互连会使配置文件迅速增长并变得不可读。因此，让我们首先向我们的 `Cache` 子类添加一些辅助函数。请记住，这些只是 Python 类，所以我们可以对它们做任何你可以用 Python 类做的事情。

对于 L1 缓存，让我们添加两个函数，`connectCPU` 用于将 CPU 连接到缓存，`connectBus` 用于将缓存连接到总线。我们需要将以下代码添加到 `L1Cache` 类中。

```
def connectCPU(self, cpu):
    # 需要在基类中定义这个！
    raise NotImplementedError

def connectBus(self, bus):
    self.mem_side = bus.cpu_side_ports
```

接下来，我们要为指令和数据缓存定义单独的 `connectCPU` 函数，因为 I-cache 和 D-cache 端口有不同的名称。我们的 `L1ICache` 和 `L1DCache` 类现在变成：

```
class L1ICache(L1Cache):
    size = '16kB'

    def connectCPU(self, cpu):
        self.cpu_side = cpu.icache_port

class L1DCache(L1Cache):
    size = '64kB'

    def connectCPU(self, cpu):
        self.cpu_side = cpu.dcache_port
```

最后，让我们向 `L2Cache` 添加函数以分别连接到内存侧和 CPU 侧总线。

```
def connectCPUSideBus(self, bus):
    self.cpu_side = bus.mem_side_ports

def connectMemSideBus(self, bus):
    self.mem_side = bus.cpu_side_ports
```

完整文件可以在 gem5 源代码中的 [`configs/learning_gem5/part1/caches.py`](https://github.com/gem5/gem5/blob/stable/configs/learning_gem5/part1/caches.py) 找到。

将缓存添加到简单的配置文件
------------------------------------

现在，让我们将刚创建的缓存添加到我们在 [上一章](http://www.gem5.org/documentation/learning_gem5/part1/simple_config/) 中创建的配置脚本中。

首先，让我们将脚本复制到一个新名称。

```
cp ./configs/tutorial/part1/simple.py ./configs/tutorial/part1/two_level.py
```

首先，我们需要将 `caches.py` 文件中的名称导入到命名空间中。我们可以将以下内容添加到文件顶部（在 m5.objects 导入之后），就像使用任何 Python 源文件一样。

```
from caches import *
```

现在，在创建 CPU 之后，让我们创建 L1 缓存：

```
system.cpu.icache = L1ICache()
system.cpu.dcache = L1DCache()
```

并使用我们创建的辅助函数将缓存连接到 CPU 端口。

```
system.cpu.icache.connectCPU(system.cpu)
system.cpu.dcache.connectCPU(system.cpu)
```

您需要 *删除* 以下两行将缓存端口直接连接到内存总线的代码。

```
system.cpu.icache_port = system.membus.cpu_side_ports
system.cpu.dcache_port = system.membus.cpu_side_ports
```

我们不能直接将 L1 缓存连接到 L2 缓存，因为 L2 缓存只期望单个端口连接到它。因此，我们需要创建一个 L2 总线将 L1 缓存连接到 L2 缓存。然后，我们可以使用我们的辅助函数将 L1 缓存连接到 L2 总线。

```
system.l2bus = L2XBar()

system.cpu.icache.connectBus(system.l2bus)
system.cpu.dcache.connectBus(system.l2bus)
```

接下来，我们可以创建 L2 缓存并将其连接到 L2 总线和内存总线。

```
system.l2cache = L2Cache()
system.l2cache.connectCPUSideBus(system.l2bus)
system.membus = SystemXBar()
system.l2cache.connectMemSideBus(system.membus)
```

请注意，`system.membus = SystemXBar()` 已在 `system.l2cache.connectMemSideBus` 之前定义，以便我们可以将其传递给 `system.l2cache.connectMemSideBus`。文件中的其他所有内容都保持不变！现在我们有了一个具有两级缓存层次结构的完整配置。如果您运行当前文件，`hello` 现在应该在 57467000 个 tick 完成。完整脚本可以在 gem5 源代码中的 [`configs/learning_gem5/part1/two_level.py`](https://github.com/gem5/gem5/blob/stable/configs/learning_gem5/part1/two_level.py) 找到。

向您的脚本添加参数
--------------------------------

在执行 gem5 实验时，您不想每次想用不同参数测试系统时都编辑配置脚本。为了解决这个问题，您可以向 gem5 配置脚本添加命令行参数。同样，因为配置脚本只是 Python，您可以使用支持参数解析的 Python 库。虽然 pyoptparse 已正式弃用，但许多随 gem5 提供的配置脚本使用它而不是 pyargparse，因为 gem5 的最低 Python 版本以前是 2.5。现在的最低 Python 版本是 3.6，因此在编写不需要与当前 gem5 脚本交互的新脚本时，Python 的 argparse 是更好的选择。要开始使用 :pyoptparse，您可以查阅在线 Python 文档。

要向我们的两级缓存配置添加选项，在导入缓存后，让我们添加一些选项。

```
import argparse

parser = argparse.ArgumentParser(description='A simple system with 2-level cache.')
parser.add_argument("binary", default="", nargs="?", type=str,
                    help="Path to the binary to execute.")
parser.add_argument("--l1i_size",
                    help=f"L1 instruction cache size. Default: 16kB.")
parser.add_argument("--l1d_size",
                    help="L1 data cache size. Default: Default: 64kB.")
parser.add_argument("--l2_size",
                    help="L2 cache size. Default: 256kB.")

options = parser.parse_args()
```
请注意，如果您想像上面那样传递二进制文件的路径并通过选项使用它，您应该将其指定为 `options.binary`。
例如：

```
system.workload = SEWorkload.init_compatible(options.binary)
```

现在，您可以运行
`build/ALL/gem5.opt configs/tutorial/part1/two_level.py --help`，它将显示您刚添加的选项。

接下来，我们需要将这些选项传递给我们在配置脚本中创建的缓存。为此，我们将简单地更改 two\_level\_opts.py 以将选项作为参数传递给缓存的构造函数，并添加适当的构造函数，如下所示。

```
system.cpu.icache = L1ICache(options)
system.cpu.dcache = L1DCache(options)
...
system.l2cache = L2Cache(options)
```

在 caches.py 中，我们需要向每个类添加构造函数（Python 中的 `__init__` 函数）。从我们的基本 L1 缓存开始，我们将只添加一个空构造函数，因为我们没有任何适用于基本 L1 缓存的参数。但是，这种情况下我们不能忘记调用父类的构造函数。如果跳过对父类构造函数的调用，gem5 的 SimObject 属性查找函数将失败，并且当您尝试实例化缓存对象时结果将是 "`RuntimeError: maximum recursion depth exceeded`"。所以，在 `L1Cache` 中，我们需要在静态类成员之后添加以下内容。

```
def __init__(self, options=None):
    super(L1Cache, self).__init__()
    pass
```

接下来，在 `L1ICache` 中，我们需要使用我们创建的选项 (`l1i_size`) 来设置大小。在下面的代码中，有针对未将 `options` 传递给 `L1ICache` 构造函数以及未在命令行上指定选项的保护措施。在这些情况下，我们将只使用我们已经为大小指定的默认值。

```
def __init__(self, options=None):
    super(L1ICache, self).__init__(options)
    if not options or not options.l1i_size:
        return
    self.size = options.l1i_size
```

我们可以对 `L1DCache` 使用相同的代码：

```
def __init__(self, options=None):
    super(L1DCache, self).__init__(options)
    if not options or not options.l1d_size:
        return
    self.size = options.l1d_size
```

以及统一的 `L2Cache`：

```
def __init__(self, options=None):
    super(L2Cache, self).__init__()
    if not options or not options.l2_size:
        return
    self.size = options.l2_size
```

有了这些更改，您现在可以从命令行将缓存大小传递到您的脚本中，如下所示。

```
build/ALL/gem5.opt configs/tutorial/part1/two_level.py --l2_size='1MB' --l1d_size='128kB'
```

    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 version 21.0.0.0
    gem5 compiled May 17 2021 18:05:59
    gem5 started May 18 2021 00:00:33
    gem5 executing on amarillo, pid 83118
    command line: build/X86/gem5.opt configs/tutorial/part1/two_level.py --l2_size=1MB --l1d_size=128kB

    Global frequency set at 1000000000000 ticks per second
    warn: No dot file generated. Please install pydot to generate the dot file and pdf.
    warn: DRAM device capacity (8192 Mbytes) does not match the address range assigned (512 Mbytes)
    0: system.remote_gdb: listening for remote gdb on port 7005
    Beginning simulation!
    info: Entering event queue @ 0.  Starting simulation...
    Hello world!
    Exiting @ tick 57467000 because exiting with last active thread context

完整脚本可以在 gem5 源代码中的 [`configs/learning_gem5/part1/caches.py`](https://github.com/gem5/gem5/blob/stable/configs/learning_gem5/part1/caches.py) 和 [`configs/learning_gem5/part1/two_level.py`](https://github.com/gem5/gem5/blob/stable/configs/learning_gem5/part1/two_level.py) 找到。
