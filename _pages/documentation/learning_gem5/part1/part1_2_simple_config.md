---
layout: documentation
title: 创建简单的配置脚本
doc: Learning gem5
parent: part1
permalink: /documentation/learning_gem5/part1/simple_config/
author: Jason Lowe-Power
---


创建简单的配置脚本
======================================

本章教程将指导您如何为 gem5 设置一个简单的模拟脚本并首次运行 gem5。
假设您已完成教程的第一章，并成功构建了带有可执行文件 `build/ALL/gem5.opt` 的 gem5。

我们的配置脚本将模拟一个非常简单的系统。我们只有一个简单的 CPU 核心。该 CPU 核心将连接到系统级内存总线。并且我们将有一个单 DDR3 内存通道，也连接到内存总线。

gem5 配置脚本
--------------------------

gem5 二进制文件将一个 Python 脚本作为参数，该脚本用于设置并执行模拟。在这个脚本中，您创建一个要模拟的系统，创建系统的所有组件，并指定系统组件的所有参数。然后，您可以从脚本开始模拟。

gem5 中有许多示例配置脚本，位于 `configs/examples` 中。
与 gem5 初学者最相关的脚本位于 `configs/examples/gem5-library` 中。
这些脚本旨在与 gem5 标准库一起使用，该库提供可以连接在一起形成完整系统的组件。

---

> **SimObjects 旁白**
>
> gem5 的模块化设计是围绕 **SimObject** 类型构建的。模拟系统中的大多数组件都是 SimObject：CPU、缓存、内存控制器、总线等。gem5 将所有这些对象从其 `C++` 实现导出到 Python。因此，您可以从 Python 配置脚本创建任何 SimObject，设置其参数，并指定 SimObject 之间的交互。
>
> 有关更多信息，请参阅 [SimObject 详细信息](http://doxygen.gem5.org/release/current/classgem5_1_1SimObject.html#details)。

---

为 gem5 v24.1 设置配置脚本
================================================

**注意：本节内容取自 2024 gem5 bootcamp 第一部分第 2 节。bootcamp 的幻灯片可以在 [这里](https://bootcamp.gem5.org/#01-Introduction/02-getting-started) 找到**

让我们从创建一个新的配置文件并打开它开始：

```bash
mkdir configs/tutorial/part1/
touch configs/tutorial/part1/simple.py
```

这只是一个普通的 Python 文件，将由 gem5 可执行文件中的嵌入式 Python 执行。因此，您可以使用 Python 中可用的任何功能和库。

要设置基本配置脚本，我们可以从添加导入开始：

```python
from gem5.prebuilt.demo.x86_demo_board import X86DemoBoard
from gem5.resources.resource import obtain_resource
from gem5.simulate.simulator import Simulator
```

接下来，向您的脚本添加一个主板 (board)：

```python
board = X86DemoBoard()
```

X86DemoBoard 是一个预构建的主板，不需要进一步配置，可以按原样用作完整系统。但是，不建议将其用于研究。

源代码可以在 gem5 仓库的 [src/python/gem5/prebuilt/demo/x86_demo_board.py](https://github.com/gem5/gem5/blob/stable/src/python/gem5/prebuilt/demo/x86_demo_board.py) 中找到。

它具有以下属性：

* 3GiB DualChannelDDR4_2400 内存
* 使用 gem5 `TIMING` 模型的 2 核处理器
* 具有 64 KiB 数据和指令缓存的私有 L1，以及 8MiB L2 缓存的共享 L2 缓存层次结构。

从 gem5 v24.1 开始，X86DemoBoard 可以支持 SE（系统调用仿真）和 FS（全系统）模拟。

接下来，让我们设置要在主板上运行的工作负载：

```python
board.set_workload(
    obtain_resource("x86-ubuntu-24.04-boot-no-systemd")
)
```

函数 `obtain_resource` 下载工作负载和资源。
对于 `x86-ubuntu-24.04-boot-no-systemd`，它下载磁盘镜像和内核，并设置默认参数。

该工作负载启动不带 systemd 的 Ubuntu。
工作负载中有三个退出事件，模拟可以在每个退出事件处退出或执行其他操作。
要更改退出事件的行为，我们需要设置退出事件处理程序。

但是，在这个例子中，我们只运行 200 亿个 tick，即 20 毫秒的模拟：

```python
sim = Simulator(board)
sim.run(20_000_000_000) # 20 billion ticks or 20 ms
```

设置配置脚本后，使用以下命令运行模拟：

```bash
./build/ALL/gem5.opt configs/tutorial/part1/simple.py
```

如果您使用的是预构建的 gem5 二进制文件，请使用以下命令：

```bash
gem5 configs/tutorial/part1/simple.py
```

输出应如下所示：

```txt
gem5 Simulator System.  https://www.gem5.org
gem5 is copyrighted software; use the --copyright option for details.

gem5 version 24.1.0.0
gem5 compiled Dec 13 2024 14:59:49
gem5 started Dec 16 2024 13:07:46
gem5 executing on amarillo, pid 543078
command line: ./build/ALL/gem5.opt gem5-dev/testing-website-tutorial/tutorial/part1/simple.py

warn: The X86DemoBoard is solely for demonstration purposes. This board is not known to be be representative of any real-world system. Use with caution.
info: Using default config
warn: Max ticks has already been set prior to setting it through the run call. In these cases the max ticks set through the `run` function is used
Global frequency set at 1000000000000 ticks per second
warn: board.workload.acpi_description_table_pointer.rsdt adopting orphan SimObject param 'entries'
src/mem/dram_interface.cc:690: warn: DRAM device capacity (16384 Mbytes) does not match the address range assigned (2048 Mbytes)
src/mem/dram_interface.cc:690: warn: DRAM device capacity (16384 Mbytes) does not match the address range assigned (2048 Mbytes)
src/sim/kernel_workload.cc:46: info: kernel located at: /home/bees/.cache/gem5/x86-linux-kernel-5.4.0-105-generic
      0: board.pc.south_bridge.cmos.rtc: Real-time clock set to Sun Jan  1 00:00:00 2012
board.pc.com_1.device: Listening for connections on port 3467
src/base/statistics.hh:279: warn: One of the stats is a legacy stat. Legacy stat is a stat that does not belong to any statistics::Group. Legacy stat is deprecated.
src/dev/intel_8254_timer.cc:128: warn: Reading current count from inactive timer.
board.remote_gdb: Listening for connections on port 7003
src/sim/simulate.cc:199: info: Entering event queue @ 0.  Starting simulation...
build/ALL/arch/x86/generated/exec-ns.cc.inc:27: warn: instruction 'fninit' unimplemented

```

为 gem5 v21.0 设置配置脚本
==============

创建配置文件
----------------------

让我们从创建一个新的配置文件并打开它开始：

```bash
mkdir configs/tutorial/part1/
touch configs/tutorial/part1/simple.py
```

这只是一个普通的 Python 文件，将由 gem5 可执行文件中的嵌入式 Python 执行。因此，您可以使用 Python 中可用的任何功能和库。

接下来，我们将创建第一个 SimObject：我们要模拟的系统。`System` 对象将是我们模拟系统中所有其他对象的父对象。`System` 对象包含大量功能性（非时序级）信息，如物理内存范围、根时钟域、根电压域、内核（在全系统模拟中）等。要创建系统 SimObject，我们只需像普通的 Python 类一样实例化它：

```python
system = System()
```

既然我们已经有了要模拟的系统的引用，让我们设置系统上的时钟。我们首先必须创建一个时钟域。然后我们可以在该域上设置时钟频率。在 SimObject 上设置参数与在 Python 中设置对象的成员完全相同，因此我们可以简单地将时钟设置为 1 GHz。最后，我们必须为此时钟域指定一个电压域。由于我们现在不关心系统功耗，我们将只使用电压域的默认选项。

```python
system.clk_domain = SrcClockDomain()
system.clk_domain.clock = '1GHz'
system.clk_domain.voltage_domain = VoltageDomain()
```

有了系统后，让我们设置如何模拟内存。我们将使用 *timing* 模式进行内存模拟。您几乎总是使用 timing 模式进行内存模拟，除非在特殊情况下，如快进 (fast-forwarding) 和从检查点恢复。我们还将设置一个大小为 512 MB 的单一内存范围，这是一个非常小的系统。请注意，在 Python 配置脚本中，每当需要大小时，您都可以用通用术语和单位（如 `'512MB'`）指定该大小。同样，对于时间，您可以使用时间单位（例如，`'5ns'`）。它们将分别自动转换为通用表示形式。

```python
system.mem_mode = 'timing'
system.mem_ranges = [AddrRange('512MB')]
```

现在，我们可以创建一个 CPU。我们将从 gem5 中针对 X86 ISA 的最简单的基于时序的 CPU 开始，*X86TimingSimpleCPU*。此 CPU 模型在单个时钟周期内执行每条指令，内存请求除外，内存请求流经内存系统。要创建 CPU，您可以简单地实例化该对象：

```python
system.cpu = X86TimingSimpleCPU()
```

如果我们想使用 RISCV ISA，我们可以使用 `RiscvTimingSimpleCPU`，或者如果我们想使用 ARM ISA，我们可以使用 `ArmTimingSimpleCPU`。但是，在本练习中我们将继续使用 X86 ISA。


接下来，我们将创建系统级内存总线：

```
system.membus = SystemXBar()
```

既然我们有了内存总线，让我们将 CPU 上的缓存端口连接到它。在这种情况下，由于我们要模拟的系统没有任何缓存，我们将把 I-cache 和 D-cache 端口直接连接到 membus。在这个示例系统中，我们没有缓存。

```
system.cpu.icache_port = system.membus.cpu_side_ports
system.cpu.dcache_port = system.membus.cpu_side_ports
```

---
> **gem5 端口旁白**
>
> 为了将内存系统组件连接在一起，gem5 使用端口抽象。每个内存对象可以有两种端口，*请求端口 (request ports)* 和 *响应端口 (response ports)*。请求从请求端口发送到响应端口，响应从响应端口发送到请求端口。连接端口时，必须将请求端口连接到响应端口。
>
> 从 Python 配置文件连接端口很容易。您只需将请求端口设置 `=` 为响应端口，它们就会被连接。例如：
>
> ```python
> system.cpu.icache_port = system.l1_cache.cpu_side
> ```
>
> 在这个例子中，cpu 的 `icache_port` 是一个请求端口，cache 的 `cpu_side` 是一个响应端口。请求端口和响应端口可以在 `=` 的任一侧，并且将建立相同的连接。建立连接后，请求者可以向响应者发送请求。幕后有很多魔法在设置连接，其细节对大多数用户来说并不重要。
>
> gem5 Python 配置中两个端口 `=` 的另一个显著魔法是，允许一侧有一个端口，另一侧有一个端口数组。例如：
>
> ```python
> system.cpu.icache_port = system.membus.cpu_side_ports
> ```
>
> 在这个例子中，cpu 的 `icache_port` 是一个请求端口，membus 的 `cpu_side_ports` 是一个响应端口数组。在这种情况下，将在 `cpu_side_ports` 上生成一个新的响应端口，并且这个新创建的端口将连接到请求端口。
>
> 我们将在 [MemObject 章节](http://www.gem5.org/documentation/learning_gem5/part2/memoryobject/) 中更详细地讨论端口和 MemObject。

---

接下来，我们需要连接其他几个端口以确保我们的系统正常运行。我们需要在 CPU 上创建一个 I/O 控制器并将其连接到内存总线。此外，我们需要将系统中的一个特殊端口连接到 membus。此端口是一个仅功能性端口，允许系统读取和写入内存。

将 PIO 和中断端口连接到内存总线是 x86 特有的要求。其他 ISA（例如 ARM）不需要这 3 行额外的代码。

```
system.cpu.createInterruptController()
system.cpu.interrupts[0].pio = system.membus.mem_side_ports
system.cpu.interrupts[0].int_requestor = system.membus.cpu_side_ports
system.cpu.interrupts[0].int_responder = system.membus.mem_side_ports

system.system_port = system.membus.cpu_side_ports
```

接下来，我们需要创建一个内存控制器并将其连接到 membus。对于这个系统，我们将使用一个简单的 DDR3 控制器，它将负责我们要模拟的系统的整个内存范围。

```
system.mem_ctrl = MemCtrl()
system.mem_ctrl.dram = DDR3_1600_8x8()
system.mem_ctrl.dram.range = system.mem_ranges[0]
system.mem_ctrl.port = system.membus.mem_side_ports
```

完成这些最后的连接后，我们就完成了模拟系统的实例化！我们的系统应该如下图所示。

![没有缓存的简单系统配置。](/pages/static/figures/simple_config.png)

接下来，我们需要设置我们希望 CPU 执行的进程。由于我们是在系统调用仿真模式 (SE mode) 下执行，我们将只让 CPU 指向编译好的可执行文件。我们将执行一个简单的“Hello world”程序。gem5 附带了一个已经编译好的程序，所以我们将使用它。您可以指定任何为 x86 构建且经过静态编译的应用程序。

> **全系统 vs 系统调用仿真**
>
> gem5 可以以两种不同的模式运行，称为“系统调用仿真 (syscall emulation)”和“全系统 (full system)”，即 SE 和 FS 模式。在全系统模式（稍后在 full-system-part 中介绍）中，gem5 模拟整个硬件系统并运行未修改的内核。全系统模式类似于运行虚拟机。
>
> 另一方面，系统调用仿真模式不模拟系统中的所有设备，而是专注于模拟 CPU 和内存系统。系统调用仿真更容易配置，因为您不需要实例化真实系统所需的所有硬件设备。但是，系统调用仿真仅仿真 Linux 系统调用，因此仅模拟用户模式代码。
>
> 如果您的研究问题不需要模拟操作系统，并且您想要额外的性能，则应使用 SE 模式。但是，如果您需要对系统进行高保真建模，或者像页表遍历这样的 OS 交互很重要，那么您应该使用 FS 模式。

首先，我们必须创建进程（另一个 SimObject）。然后我们将进程命令设置为我们要运行的命令。这是一个类似于 argv 的列表，可执行文件在第一个位置，可执行文件的参数在列表的其余部分。然后我们将 CPU 设置为使用该进程作为其工作负载，最后在 CPU 中创建功能执行上下文。

```
binary = 'tests/test-progs/hello/bin/x86/linux/hello'

# for gem5 V21 and beyond
system.workload = SEWorkload.init_compatible(binary)

process = Process()
process.cmd = [binary]
system.cpu.workload = process
system.cpu.createThreads()
```

我们需要做的最后一件事是实例化系统并开始执行。首先，我们创建 `Root` 对象。然后我们实例化模拟。实例化过程遍历我们在 Python 中创建的所有 SimObject，并创建 `C++` 等效对象。

请注意，您不必实例化 python 类，然后显式地将参数指定为成员变量。您也可以将参数作为命名参数传递，如下面的 `Root` 对象所示。

```
root = Root(full_system = False, system = system)
m5.instantiate()
```

最后，我们可以启动实际的模拟！顺便说一句，gem5 现在使用 Python 3 风格的 `print` 函数，因此 `print` 不再是语句，必须作为函数调用。

```
print("Beginning simulation!")
exit_event = m5.simulate()
```

模拟完成后，我们可以检查系统的状态。

```
print('Exiting @ tick {} because {}'
      .format(m5.curTick(), exit_event.getCause()))
```

运行 gem5
------------

既然我们已经创建了一个简单的模拟脚本（完整版本可以在 gem5 代码库的 [configs/learning\_gem5/part1/simple.py](https://github.com/gem5/gem5/blob/stable/configs/learning_gem5/part1/simple.py) 中找到），我们准备好运行 gem5 了。gem5 可以接受许多参数，但只需要一个位置参数，即模拟脚本。所以，我们可以简单地从 gem5 根目录运行 gem5，如下所示：

```
build/ALL/gem5.opt configs/tutorial/part1/simple.py
```

输出应该是：

    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 version 21.0.0.0
    gem5 compiled May 17 2021 18:05:59
    gem5 started May 17 2021 22:05:20
    gem5 executing on amarillo, pid 75197
    command line: build/X86/gem5.opt configs/tutorial/part1/simple.py

    Global frequency set at 1000000000000 ticks per second
    warn: No dot file generated. Please install pydot to generate the dot file and pdf.
    warn: DRAM device capacity (8192 Mbytes) does not match the address range assigned (512 Mbytes)
    0: system.remote_gdb: listening for remote gdb on port 7005
    Beginning simulation!
    info: Entering event queue @ 0.  Starting simulation...
    Hello world!
    Exiting @ tick 490394000 because exiting with last active thread context

可以更改配置文件中的参数，结果应该会有所不同。例如，如果您将系统时钟加倍，模拟应该会更快完成。或者，如果您将 DDR 控制器更改为 DDR4，性能应该会更好。

此外，您可以将 CPU 模型更改为 `X86MinorCPU` 以模拟按序 CPU，或更改为 `X86O3CPU` 以模拟乱序 CPU。但是，请注意 `X86O3CPU` 目前不适用于 simple.py，因为 `X86O3CPU` 需要具有独立指令和数据缓存的系统（`X86O3CPU` 确实适用于下一节中的配置）。

所有 gem5 BaseCPU 都采用命名格式 `{ISA}{Type}CPU`。因此，如果我们想要一个 RISCV Minor CPU，我们会使用 `RiscvMinorCPU`。

有效的 ISA 有：
* Riscv
* Arm
* X86
* Sparc
* Power
* Mips

CPU 类型有：
* AtomicSimpleCPU
* O3CPU
* TimingSimpleCPu
* KvmCPU
* MinorCPU

接下来，我们将向配置文件添加缓存以模拟更复杂的系统。
