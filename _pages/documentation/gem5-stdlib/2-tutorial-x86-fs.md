---
layout: documentation
title: X86 全系统教程
parent: gem5-standard-library
doc: gem5 documentation
permalink: /documentation/gem5-stdlib/x86-full-system-tutorial
author: Bobby R. Bruce
---

## 使用 gem5 标准库构建 X86 全系统模拟

gem5 标准库背后的关键思想之一是允许用户以最少的努力模拟大型、复杂的系统。
这是通过对要模拟的系统性质做出合理的假设，并以"有意义"的方式连接组件来实现的。
虽然这会减少一些灵活性，但它大大简化了在 gem5 中模拟典型硬件设置的过程。
总体理念是使 _常见情况_ 变得简单。

在本教程中，我们将构建一个 X86 模拟，能够运行全系统模拟、启动 Ubuntu 操作系统并运行基准测试程序。
该系统将利用 gem5 切换核心的能力，允许在 KVM 快进模式下启动操作系统，并切换到详细的 CPU 模型以运行基准测试程序，并在双核设置中使用 MESI 两级 Ruby 缓存层次结构。
如果不使用 gem5 库，这将需要数百行 Python 代码，迫使用户指定每个 IO 组件和缓存层次结构的确切设置等细节。
在这里，我们将演示使用 gem5 标准库可以多么简单地完成此任务。

首先，我们构建 ALL 二进制文件。这将允许我们运行任何 ISA 的模拟，包括 X86：

```sh
scons build/ALL/gem5.opt -j <线程数>
```

如果您使用的是预构建的 gem5 二进制文件，则不需要此步骤。

首先，创建一个新的 Python 文件。
我们将在下文中将其称为 `x86-ubuntu-run.py`。

首先，我们添加导入语句：

```python
from gem5.coherence_protocol import CoherenceProtocol
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
from gem5.utils.requires import requires
```

与其他 Python 脚本一样，这些只是我们脚本中需要的类/函数。
它们都作为 gem5 二进制文件的一部分包含在内，因此无需从其他地方获取。

一个好的开始是使用 `requires` 函数来指定运行脚本需要什么类型的 gem5 二进制文件/设置：

```python
requires(
    isa_required=ISA.X86,
    coherence_protocol_required=CoherenceProtocol.MESI_TWO_LEVEL,
    kvm_required=True,
)
```

这里我们声明需要编译 gem5 以运行 X86 ISA 并支持 MESI 两级协议。
我们还要求主机系统具有 KVM。
**注意：请确保您的主机系统支持 KVM。如果您的系统不支持，请在此处删除 `kvm_required` 检查**。
KVM 只有在主机平台和模拟的 ISA 相同时才能工作（例如，X86 主机和 X86 模拟）。您可以在[这里](https://www.gem5.org/documentation/general_docs/using_kvm/)了解更多关于在 gem5 中使用 KVM 的信息。

这个 `requires` 调用不是必需的，但为运行脚本的用户提供了良好的安全网。
由于不兼容的 gem5 二进制文件而发生的错误可能不会有太大意义。

接下来我们开始指定系统中的组件。
我们从 _cache hierarchy_（缓存层次结构）开始：

```python
cache_hierarchy = MESITwoLevelCacheHierarchy(
    l1d_size="32KiB",
    l1d_assoc=8,
    l1i_size="32KiB",
    l1i_assoc=8,
    l2_size="256KiB",
    l2_assoc=16,
    num_l2_banks=1,
)
```

这里我们设置一个 MESI 两级 (ruby) 缓存层次结构。
通过构造函数，我们将 L1 数据缓存和 L1 指令缓存设置为 32 KiB，将 L2 缓存设置为 256 KiB。

接下来我们设置 _memory system_（内存系统）：

```python
memory = SingleChannelDDR3_1600(size="2GiB")
```

这非常简单且直观：大小为 2GiB 的单通道 DDR3 1600 设置。
**注意：** 默认情况下，`SingleChannelDDR3_1600` 组件的大小为 8GiB。
但是，由于 [X86Board 的已知限制](https://gem5.atlassian.net/browse/GEM5-1142)，我们不能使用大于 3GiB 的内存系统。
因此，我们必须设置大小。

接下来我们设置 _processor_（处理器）：

```python
processor = SimpleSwitchableProcessor(
    starting_core_type=CPUTypes.KVM,
    switch_core_type=CPUTypes.TIMING,
    isa=ISA.X86,
    num_cores=2,
)
```

这里我们使用 gem5 标准库的特殊 `SimpleSwitchableProcessor`。
此处理器可用于用户希望在模拟期间将一种类型的核心切换为另一种类型的模拟。
`starting_core_type` 参数指定开始模拟时使用的 CPU 类型。
在这种情况下是 KVM 核心。
**（注意：如果您的主机系统不支持 KVM，此模拟将无法运行。您必须将其更改为其他 CPU 类型，例如 `CPUTypes.ATOMIC`）**
`switch_core_type` 参数指定在模拟中要切换到的 CPU 类型。
在这种情况下，我们将从 KVM 核心切换到 TIMING 核心。
最后一个参数 `num_cores` 指定处理器内的核心数。

使用此处理器，用户可以调用 `processor.switch()` 在起始核心和切换核心之间切换，我们将在本教程后面演示这一点。

接下来我们将这些组件添加到 _board_（开发板）：

```python
board = X86Board(
    clk_freq="3GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
)
```

这里我们使用 `X86Board`。
这是一个用于在全系统模式下模拟典型 X86 系统的开发板。
至少，开发板需要指定 `clk_freq`、`processor`、`memory` 和 `cache_hierarchy` 参数。
这完成了我们的系统设计。

现在我们在系统上设置要运行的工作负载：

```python
workload = obtain_resource("x86-ubuntu-24.04-boot-with-systemd")
board.set_workload(workload)
```

`obtain_resource` 函数获取 X86 Ubuntu 24.04 启动工作负载。
此工作负载包含内核资源、内核参数、磁盘镜像资源，以及一个字符串，指示在调用 `board.set_workload()` 时 gem5 使用的底层函数。
您可以在 gem5 Resources 网站页面的 [Raw](https://resources.gem5.org/resources/x86-ubuntu-24.04-boot-with-systemd/raw?database=gem5-resources&version=3.0.0) 选项卡下查看此工作负载的这些详细信息。

您也可以使用 `set_kernel_disk_workload()` 而不是 `set_workload()`，并分别设置磁盘镜像和内核资源。
当您想使用自己的资源，或使用 [gem5 resources 网站](resources.gem5.org) 上未作为工作负载提供的资源组合时，可以使用此方法。

**注意：如果用户希望使用自己的资源（即，不是作为 gem5-resources 的一部分预构建的资源），他们可以按照[这里](../general_docs/gem5_resources)的教程。在 [2024 gem5 训练营网站](https://bootcamp.gem5.org/#02-Using-gem5/02-gem5-resources) 上也有教程可用。**

使用 `set_kernel_disk_workload()` 函数时，您还可以传递一个可选的 `readfile_contents` 参数。
这将在系统启动后作为 bash 脚本运行，如果磁盘镜像已安装基准测试程序，可用于在系统启动后启动基准测试程序。
可以在[这里](https://resources.gem5.org/resources/x86-ubuntu-24.04-npb-ua-b/raw?database=gem5-resources&version=2.0.0)找到一个示例。

最后，我们通过以下方式指定如何运行模拟：

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
    # readfile_contents. This is the last exit event before the simulation exits.
    yield True


simulator = Simulator(
    board=board,
    on_exit_event={
        ExitEvent.EXIT: exit_event_handler(),
    },
)
simulator.run()
```

这里需要注意的重要事项是 `on_exit_event` 参数。
这里我们可以覆盖默认行为。

`on_exit_event` 参数是一个退出事件和 [Python 生成器](https://wiki.python.org/moin/Generators) 的 Python 字典。
在本教程中，我们使用 `exit_event_handler` 生成器来处理类型为 `ExitEvent.EXIT` 的退出事件。
工作负载使用的 Ubuntu 24.04 磁盘镜像资源中有三个 `EXIT` 退出事件。
如果未定义退出事件处理程序，模拟将在第一个退出事件后结束，该事件在内核完成启动后发生。
产生 `False` 允许模拟继续，而产生 `True` 结束模拟。
在第二个退出事件之后，我们将核心从 KVM 切换到 TIMING，然后产生 `False` 以继续模拟。
在第三个退出事件之后，我们产生 `True`，结束模拟。

这完成了我们脚本的设置。要执行脚本，我们运行：

```bash
./build/ALL/gem5.opt x86-ubuntu-run.py
```

如果您使用的是预构建的二进制文件，可以使用以下命令执行模拟：

```sh
gem5 hello-world.py
```

您可以在 `m5out/system.pc.com_1.device` 中查看模拟器的输出。

下面是完整的配置脚本。
它密切反映了 gem5 仓库中 `configs/example/gem5_library/x86-ubuntu-run-with-kvm.py` 的示例脚本。

```python
from gem5.coherence_protocol import CoherenceProtocol
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
from gem5.utils.requires import requires

requires(
    isa_required=ISA.X86,
    coherence_protocol_required=CoherenceProtocol.MESI_TWO_LEVEL,
    kvm_required=True,
)

cache_hierarchy = MESITwoLevelCacheHierarchy(
    l1d_size="32KiB",
    l1d_assoc=8,
    l1i_size="32KiB",
    l1i_assoc=8,
    l2_size="256KiB",
    l2_assoc=16,
    num_l2_banks=1,
)

memory = SingleChannelDDR3_1600(size="2GiB")

processor = SimpleSwitchableProcessor(
    starting_core_type=CPUTypes.KVM,
    switch_core_type=CPUTypes.TIMING,
    isa=ISA.X86,
    num_cores=2,
)

board = X86Board(
    clk_freq="3GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
)

workload = obtain_resource("x86-ubuntu-24.04-boot-with-systemd")
board.set_workload(workload)


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
    # readfile_contents. This is the last exit event before the simulation exits.
    yield True


simulator = Simulator(
    board=board,
    on_exit_event={
        ExitEvent.EXIT: exit_event_handler(),
    },
)
simulator.run()

```

总结本教程中学到的内容：

* `requires` 函数可用于指定脚本的 gem5 和主机要求。
* `SimpleSwitchableProcessor` 可用于创建可以切换核心的设置。
* `X86Board` 可用于设置全系统模拟。
* 其工作负载可以通过 `set_workload()` 为工作负载资源设置，或通过 `set_kernel_disk_workload()` 为单独的内核和磁盘镜像资源设置。
* `set_kernel_disk_workload()` 函数接受 `readfile_contents` 参数。
这将在系统启动完成后作为脚本执行。
* `Simulator` 模块允许使用 Python 生成器覆盖退出事件。
