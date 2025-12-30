---
layout: documentation
title: Hello World 教程
parent: gem5-standard-library
doc: gem5 documentation
permalink: /documentation/gem5-stdlib/hello-world-tutorial
author: Bobby R. Bruce
---

## 使用 gem5 标准库构建 "Hello World" 示例

在本教程中，我们将介绍如何使用 gem5 组件创建一个非常基础的模拟。
此模拟将设置一个由单核处理器组成的系统，在 Atomic 模式下运行，直接连接到主内存，没有缓存、I/O 或其他组件。
系统将在系统调用仿真 (SE) 模式下运行 X86 二进制文件。
该二进制文件将从 gem5-resources 获取，执行时会将 "Hello World!" 字符串打印到 stdout。

首先，我们必须编译 gem5 的 ALL 构建：

```sh
# 在 gem5 目录的根目录下
scons build/ALL/gem5.opt -j <线程数>
```

从 gem5 v24.1 开始，ALL 构建包括所有 Ruby 协议和所有 ISA。如果您使用的是预构建的 gem5 二进制文件，则不需要此步骤。

然后应该创建一个新的 Python 文件（我们将在下文中将其称为 `hello-world.py`）。
该文件的前几行应该是所需的导入：

```python
from gem5.components.boards.simple_board import SimpleBoard
from gem5.components.cachehierarchies.classic.no_cache import NoCache
from gem5.components.memory.single_channel import SingleChannelDDR3_1600
from gem5.components.processors.cpu_types import CPUTypes
from gem5.components.processors.simple_processor import SimpleProcessor
from gem5.isas import ISA
from gem5.resources.resource import obtain_resource
from gem5.simulate.simulator import Simulator
```

所有这些库都包含在编译的 gem5 二进制文件中。
因此，您无需从其他地方获取它们。
`from gem5.` 表示我们从 `gem5` 标准库导入，以 `from gem5.components` 开头的行是从 gem5 组件包导入组件。
`from gem5.resources` 行表示我们从资源包导入，`from gem5.simulate` 表示从 Simulate 包导入。
所有这些包，`components`、`resources` 和 `simulate` 都是 gem5 标准库的一部分。

接下来我们开始指定系统。
gem5 库要求用户指定四个主要组件：_board_（开发板）、_cache hierarchy_（缓存层次结构）、_memory system_（内存系统）和 _processor_（处理器）。

让我们从 _cache hierarchy_（缓存层次结构）开始：

```python
cache_hierarchy = NoCache()
```

这里我们使用 `NoCache()`。
这意味着，对于我们的系统，我们声明没有缓存层次结构（即没有缓存）。
在 gem5 库中，缓存层次结构是处理器核心和主内存之间存在的任何东西的广义术语。
这里我们声明处理器直接连接到主内存。

接下来我们声明 _memory system_（内存系统）：

```python
memory = SingleChannelDDR3_1600("1GiB")
```

在 `gem5.components.memory` 中有许多内存组件可供选择。
这里我们使用单通道 DDR3 1600，并将其大小设置为 1 GiB。
应该注意的是，在这里设置大小在技术上是可选的。
如果未设置，`SingleChannelDDR3_1600` 将默认为 8 GiB。

然后我们考虑 _processor_（处理器）：

```python
processor = SimpleProcessor(cpu_type=CPUTypes.ATOMIC, num_cores=1, isa=ISA.X86)
```

`gem5.components` 中的处理器是一个包含多个 gem5 CPU 核心的对象，这些核心可以是特定类型或不同类型（`ATOMIC`、`TIMING`、`KVM`、`O3` 等）。
本示例中使用的 `SimpleProcessor` 是一个所有 CPU 核心都是相同类型的处理器。
它需要两个参数：`cpu_type`（我们设置为 `ATOMIC`）和 `num_cores`（核心数，我们设置为 1）。

最后我们指定要使用的 _board_（开发板）：

```python
board = SimpleBoard(
    clk_freq="3GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
)
```

虽然每个开发板的构造函数可能不同，但它们通常要求用户指定 _processor_（处理器）、_memory system_（内存系统）和 _cache hierarchy_（缓存层次结构），以及要使用的时钟频率。
在本示例中，我们使用 `SimpleBoard`。
`SimpleBoard` 是一个非常基础的系统，没有 I/O，仅支持 SE 模式，并且只能与"经典"缓存层次结构一起工作。

此时，在脚本中我们已经指定了模拟系统所需的一切。
当然，为了运行有意义的模拟，我们必须为此系统指定要运行的工作负载。
为此，我们添加以下行：

```python
binary = obtain_resource("x86-hello64-static")
board.set_se_binary_workload(binary)
```

`obtain_resource` 函数接受一个字符串，该字符串指定要从 [gem5-resources](/documentation/general_docs/gem5_resources) 获取哪个资源用于模拟。
所有 gem5 资源都可以在 [gem5 Resources 网站](https://resources.gem5.org) 上找到。

如果主机系统上不存在该资源，它将自动下载。
在本示例中，我们将使用 `x86-hello-64-static` 资源；
这是一个 x86、64 位、静态编译的二进制文件，会将 "Hello World!" 打印到 stdout。
指定资源后，我们通过开发板的 `set_se_binary_workload` 函数设置工作负载。
顾名思义，`set_se_binary_workload` 是用于设置在系统调用执行模式下执行的二进制文件的函数。

您可以在 [gem5 resources 网站](https://resources.gem5.org/) 上查看和搜索可用资源。

这就是设置模拟所需的一切。
从这一点开始，您只需要构造并运行 `Simulator`：

```python
simulator = Simulator(board=board)
simulator.run()
```

As a recap, your script should look like the following:

```python
from gem5.components.boards.simple_board import SimpleBoard
from gem5.components.cachehierarchies.classic.no_cache import NoCache
from gem5.components.memory.single_channel import SingleChannelDDR3_1600
from gem5.components.processors.cpu_types import CPUTypes
from gem5.components.processors.simple_processor import SimpleProcessor
from gem5.isas import ISA
from gem5.resources.resource import obtain_resource
from gem5.simulate.simulator import Simulator

# Obtain the components.
cache_hierarchy = NoCache()
memory = SingleChannelDDR3_1600("1GiB")
processor = SimpleProcessor(cpu_type=CPUTypes.ATOMIC, num_cores=1, isa=ISA.X86)

# Add them to the board.
board = SimpleBoard(
    clk_freq="3GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
)

# Set the workload.
binary = obtain_resource("x86-hello64-static")
board.set_se_binary_workload(binary)

# Setup the Simulator and run the simulation.
simulator = Simulator(board=board)
simulator.run()
```

然后可以使用以下命令执行：

```sh
./build/ALL/gem5.opt hello-world.py
```

如果您使用的是预构建的二进制文件，可以使用以下命令执行模拟：

```sh
gem5 hello-world.py
```

如果设置正确，输出将类似于：

```text
info: Using default config
Global frequency set at 1000000000000 ticks per second
src/mem/dram_interface.cc:690: warn: DRAM device capacity (8192 Mbytes) does not match the address range assigned (1024 Mbytes)
src/base/statistics.hh:279: warn: One of the stats is a legacy stat. Legacy stat is a stat that does not belong to any statistics::Group. Legacy stat is deprecated.
board.remote_gdb: Listening for connections on port 7005
src/sim/simulate.cc:199: info: Entering event queue @ 0.  Starting simulation...
src/sim/syscall_emul.hh:1117: warn: readlink() called on '/proc/self/exe' may yield unexpected results in various settings.
src/sim/mem_state.cc:448: info: Increasing stack size by one page.
Hello world!
```

从这一点应该很明显，可以更改 _board_（开发板）的参数以测试其他设计。
例如，如果我们想测试 `TIMING` CPU 设置，我们会将 _processor_（处理器）更改为：

```python
processor = SimpleProcessor(cpu_type=CPUTypes.TIMING, num_cores=1, isa=ISA.X86)
```

这就是所需的一切。
gem5 标准库将根据需要重新配置设计。

作为另一个示例，考虑将一个组件替换为另一个组件。
在这个设计中，我们决定使用 `NoCache`，但我们可以使用另一个经典缓存层次结构，例如 `PrivateL1CacheHierarchy`。
为此，我们将更改 `cache_hierarchy` 参数：

```python
# We import the cache hierarchy we want.
from gem5.components.cachehierarchies.classic.private_l1_cache_hierarchy import PrivateL1CacheHierarchy

...

# Then set it.
cache_hierarchy = PrivateL1CacheHierarchy(l1d_size="32KiB", l1i_size="32KiB")
```

请注意，`PrivateL1CacheHierarchy` 要求用户指定要构造的 L1 数据和指令缓存大小。
设计的其他部分无需更改。
gem5 标准库将根据需要整合缓存层次结构。

总结本教程中学到的内容：

* 可以使用 gem5 组件包使用 _processor_（处理器）、_cache hierarchy_（缓存层次结构）、_memory system_（内存系统）和 _board_（开发板）组件构建系统。
* 一般来说，同类型的组件尽可能可以互换。例如，不同的 _cache hierarchy_（缓存层次结构）组件可以在设计中交换进出，而无需在其他组件中进行重新配置。
* _boards_（开发板）包含设置工作负载的函数。
* 资源包可用于从 gem5-resources 获取预构建的资源。
这些通常是通过设置工作负载函数可以运行的工作负载。
* Simulate 包可用于在 gem5 模拟中运行开发板。
