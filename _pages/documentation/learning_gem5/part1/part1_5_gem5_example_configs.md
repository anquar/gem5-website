---
layout: documentation
title: 使用默认配置脚本
doc: Learning gem5
parent: part1
permalink: /documentation/learning_gem5/part1/example_configs/
author: Jason Lowe-Power
---

gem5 v24.1: 使用 gem5 标准库配置脚本
=================================================================

gem5 标准库的引入改变了 gem5 配置脚本的编写方式。
下面 gem5 v21.0 部分中提到的许多旧配置脚本现在已被弃用，取而代之的是位于 `configs/example/gem5_library` 的 gem5 标准库配置脚本。

简要查看目录结构如下：

```txt
gem5_library
    |
    |- caches       #包含 octopi 缓存的配置脚本
    |
    |- checkpoints  #用于获取和从检查点恢复的脚本
    |
    |- dramsys      #用于将 gem5 与 dramsys 一起使用的脚本
    |
    |- looppoints   #用于获取和从 looppoints 恢复的脚本
    |
    |- multisim     #用于使用 multisim 一次启动多个模拟的脚本
    |
    |- spatter_gen  #用于 SpatterGen 的脚本
    |
    |- (各种未分类到子目录的示例配置脚本)

```

直接放置在 `gem5_library` 目录中的示例配置脚本类似于您在 Learning gem5 之前部分中看到的脚本，但种类更多，例如不同的 ISA、板和工作负载。可以在 [这里](https://github.com/gem5/gem5/tree/stable/configs/example/gem5_library) 查看这些脚本的源代码。

gem5 v21.0: 使用默认配置脚本
=======================================

在本章中，我们将探索使用 gem5 附带的默认配置脚本。gem5 附带了许多配置脚本，让您可以非常快速地使用 gem5。然而，一个常见的陷阱是在没有完全理解正在模拟什么的情况下使用这些脚本。在使用 gem5 进行计算机架构研究时，完全理解您正在模拟的系统非常重要。本章将引导您了解默认配置脚本的一些重要选项和部分。

在最后几章中，您已经从头开始创建了自己的配置脚本。这非常强大，因为它允许您指定每一个系统参数。但是，有些系统非常复杂（例如，全系统 ARM 或 x86 机器）。幸运的是，gem5 开发人员提供了许多脚本来引导构建系统的过程。

目录结构概览
---------------------------------

所有 gem5 的配置文件都可以在 `configs/` 中找到。
目录结构如下所示：

    configs/boot:
    bbench-gb.rcS  bbench-ics.rcS  hack_back_ckpt.rcS  halt.sh

    configs/common:
    Benchmarks.py   Caches.py  cpu2000.py    FileSystemConfig.py  GPUTLBConfig.py   HMC.py       MemConfig.py   Options.py     Simulation.py
    CacheConfig.py  cores      CpuConfig.py  FSConfig.py          GPUTLBOptions.py  __init__.py  ObjectList.py  SimpleOpts.py  SysPaths.py

    configs/dist:
    sw.py

    configs/dram:
    lat_mem_rd.py  low_power_sweep.py  sweep.py

    configs/example:
    apu_se.py  etrace_replay.py  garnet_synth_traffic.py  hmctest.py    hsaTopology.py  memtest.py  read_config.py  ruby_direct_test.py      ruby_mem_test.py     sc_main.py
    arm        fs.py             hmc_hello.py             hmc_tgen.cfg  memcheck.py     noc_config  riscv           ruby_gpu_random_test.py  ruby_random_test.py  se.py

    configs/learning_gem5:
    part1  part2  part3  README

    configs/network:
    __init__.py  Network.py

    configs/nvm:
    sweep_hybrid.py  sweep.py

    configs/ruby:
    AMD_Base_Constructor.py  CHI.py        Garnet_standalone.py  __init__.py              MESI_Three_Level.py  MI_example.py      MOESI_CMP_directory.py  MOESI_hammer.py
    CHI_config.py            CntrlBase.py  GPU_VIPER.py          MESI_Three_Level_HTM.py  MESI_Two_Level.py    MOESI_AMD_Base.py  MOESI_CMP_token.py      Ruby.py

    configs/splash2:
    cluster.py  run.py

    configs/topologies:
    BaseTopology.py  Cluster.py  CrossbarGarnet.py  Crossbar.py  CustomMesh.py  __init__.py  MeshDirCorners_XY.py  Mesh_westfirst.py  Mesh_XY.py  Pt2Pt.py

每个目录的简要说明如下：

**boot/**
:   这些是用于全系统模式的 rcS 文件。这些文件在 Linux 启动后由模拟器加载，并由 shell 执行。其中大多数用于在全系统模式下运行时控制基准测试。有些是实用函数，如 `hack_back_ckpt.rcS`。这些文件在全系统模拟一章中有更深入的介绍。

**common/**
:   此目录包含许多用于创建模拟系统的辅助脚本和函数。例如，`Caches.py` 类似于我们在前几章中创建的 `caches.py` 和 `caches_opts.py` 文件。

    `Options.py` 包含可以在命令行上设置的各种选项。比如 CPU 数量、系统时钟等等。如果要查看想要更改的选项是否已经有命令行参数，这是一个很好的去处。

    `CacheConfig.py` 包含用于为经典内存系统设置缓存参数的选项和函数。

    `MemConfig.py` 提供了一些用于设置内存系统的辅助函数。

    `FSConfig.py` 包含为许多不同类型的系统设置全系统模拟所需的函数。全系统模拟将在其自己的章节中进一步讨论。

    `Simulation.py` 包含许多用于设置和运行 gem5 的辅助函数。此文件中包含的大量代码管理保存和恢复检查点。下面 `examples/` 中的示例配置文件使用此文件中的函数来执行 gem5 模拟。这个文件相当复杂，但也允许在如何运行模拟方面有很大的灵活性。

**dram/**
:   包含用于测试 DRAM 的脚本。

**example/**
:   此目录包含一些示例 gem5 配置脚本，可以直接用来运行 gem5。具体来说，`se.py` 和 `fs.py` 非常有用。有关这些文件的更多信息可以在下一节中找到。此目录中还有一些其他实用配置脚本。

**learning_gem5/**
:   此目录包含 learning\_gem5 书中找到的所有 gem5 配置脚本。

**network/**
:   此目录包含 HeteroGarnet 网络的配置脚本。

**nvm/**
:   此目录包含使用 NVM 接口的示例脚本。

**ruby/**
:   此目录包含 Ruby 及其包含的缓存一致性协议的配置脚本。更多详细信息可以在 Ruby 一章中找到。

**splash2/**
:   此目录包含运行 splash2 基准测试套件的脚本，带有一些用于配置模拟系统的选项。

**topologies/**
:   此目录包含在创建 Ruby 缓存层次结构时可以使用的拓扑实现。更多详细信息可以在 Ruby 一章中找到。

使用 `se.py` 和 `fs.py`
-------------------------

在本节中，我将讨论一些可以传递给 `se.py` 和 `fs.py` 命令行的常见选项。有关如何运行全系统模拟的更多详细信息，请参见全系统模拟一章。在这里，我将讨论这两个文件通用的选项。

本节中讨论的大多数选项都可以在 Options.py 中找到，并在函数 `addCommonOptions` 中注册。本节不详细介绍所有选项。要查看所有选项，请使用 `--help` 运行配置脚本，或阅读脚本的源代码。

首先，让我们简单地运行 hello world 程序，不带任何参数：

```
build/X86/gem5.opt configs/example/se.py --cmd=tests/test-progs/hello/bin/x86/linux/hello
```

我们得到以下输出：

    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 version 21.0.0.0
    gem5 compiled May 17 2021 18:05:59
    gem5 started May 18 2021 00:33:42
    gem5 executing on amarillo, pid 85168
    command line: build/X86/gem5.opt configs/example/se.py --cmd=tests/test-progs/hello/bin/x86/linux/hello

    Global frequency set at 1000000000000 ticks per second
    warn: No dot file generated. Please install pydot to generate the dot file and pdf.
    warn: DRAM device capacity (8192 Mbytes) does not match the address range assigned (512 Mbytes)
    0: system.remote_gdb: listening for remote gdb on port 7005
    **** REAL SIMULATION ****
    info: Entering event queue @ 0.  Starting simulation...
    Hello world!
    Exiting @ tick 5943000 because exiting with last active thread context

然而，这根本不是一个非常有趣的模拟！默认情况下，gem5 使用 atomic CPU 并使用原子内存访问，因此没有报告真正的时序数据！要确认这一点，您可以查看 `m5out/config.ini`。CPU 显示在第 51 行：

    [system.cpu]
    type=X86AtomicSimpleCPU
    children=interrupts isa mmu power_state tracer workload
    branchPred=Null
    checker=Null
    clk_domain=system.cpu_clk_domain
    cpu_id=0
    do_checkpoint_insts=true
    do_statistics_insts=true

要实际上以 timing 模式运行 gem5，让我们指定一个 CPU 类型。与此同时，我们也可以指定 L1 缓存的大小。

```
build/X86/gem5.opt configs/example/se.py --cmd=tests/test-progs/hello/bin/x86/linux/hello --cpu-type=TimingSimpleCPU --l1d_size=64kB --l1i_size=16kB
```

    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 version 21.0.0.0
    gem5 compiled May 17 2021 18:05:59
    gem5 started May 18 2021 00:36:10
    gem5 executing on amarillo, pid 85269
    command line: build/X86/gem5.opt configs/example/se.py --cmd=tests/test-progs/hello/bin/x86/linux/hello --cpu-type=TimingSimpleCPU --l1d_size=64kB --l1i_size=16kB

    Global frequency set at 1000000000000 ticks per second
    warn: No dot file generated. Please install pydot to generate the dot file and pdf.
    warn: DRAM device capacity (8192 Mbytes) does not match the address range assigned (512 Mbytes)
    0: system.remote_gdb: listening for remote gdb on port 7005
    **** REAL SIMULATION ****
    info: Entering event queue @ 0.  Starting simulation...
    Hello world!
    Exiting @ tick 454646000 because exiting with last active thread context

现在，让我们检查 config.ini 文件并确保这些选项正确传播到了最终系统。如果您在 `m5out/config.ini` 中搜索 "cache"，您会发现没有创建任何缓存！即使我们指定了缓存的大小，我们也没有指定系统应该使用缓存，所以它们没有被创建。正确的命令行应该是：

```
build/X86/gem5.opt configs/example/se.py --cmd=tests/test-progs/hello/bin/x86/linux/hello --cpu-type=TimingSimpleCPU --l1d_size=64kB --l1i_size=16kB --caches
```

    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 version 21.0.0.0
    gem5 compiled May 17 2021 18:05:59
    gem5 started May 18 2021 00:37:03
    gem5 executing on amarillo, pid 85560
    command line: build/X86/gem5.opt configs/example/se.py --cmd=tests/test-progs/hello/bin/x86/linux/hello --cpu-type=TimingSimpleCPU --l1d_size=64kB --l1i_size=16kB --caches

    Global frequency set at 1000000000000 ticks per second
    warn: No dot file generated. Please install pydot to generate the dot file and pdf.
    warn: DRAM device capacity (8192 Mbytes) does not match the address range assigned (512 Mbytes)
    0: system.remote_gdb: listening for remote gdb on port 7005
    **** REAL SIMULATION ****
    info: Entering event queue @ 0.  Starting simulation...
    Hello world!
    Exiting @ tick 31680000 because exiting with last active thread context

在最后一行，我们看到总时间从 454646000 ticks 变为 31680000，快得多！看起来缓存现在可能已启用了。但是，仔细检查 `config.ini` 文件总是一个好主意。

    [system.cpu.dcache]
    type=Cache
    children=power_state replacement_policy tags
    addr_ranges=0:18446744073709551615
    assoc=2
    clk_domain=system.cpu_clk_domain
    clusivity=mostly_incl
    compressor=Null
    data_latency=2
    demand_mshr_reserve=1
    eventq_index=0
    is_read_only=false
    max_miss_count=0
    move_contractions=true
    mshrs=4
    power_model=
    power_state=system.cpu.dcache.power_state
    prefetch_on_access=false
    prefetcher=Null
    replace_expansions=true
    replacement_policy=system.cpu.dcache.replacement_policy
    response_latency=2
    sequential_access=false
    size=65536
    system=system
    tag_latency=2
    tags=system.cpu.dcache.tags
    tgts_per_mshr=20
    warmup_percentage=0
    write_allocator=Null
    write_buffers=8
    writeback_clean=false
    cpu_side=system.cpu.dcache_port
    mem_side=system.membus.cpu_side_ports[2]

`se.py` 和 `fs.py` 的一些常见选项
---------------------------------------

当您运行以下命令时，会打印所有可能的选项：

```
build/X86/gem5.opt configs/example/se.py --help
```

以下是该列表中的一些重要选项：


* `--cpu-type=CPU_TYPE`

    * 要运行的 cpu 类型。这是一个始终设置的重要参数。默认值为 atomic，不执行时序模拟。

* `--sys-clock=SYS_CLOCK`

    * 以系统速度运行的块的顶级时钟。

* `--cpu-clock=CPU_CLOCK`

    * 以 CPU 速度运行的块的时钟。这与上面的系统时钟是分开的。

* `--mem-type=MEM_TYPE`

    * 要使用的内存类型。选项包括不同的 DDR 内存和 ruby 内存控制器。

* `--caches`

    * 使用经典缓存执行模拟。

* `--l2cache`

    * 如果使用经典缓存，则使用 L2 缓存执行模拟。

* `--ruby`

    * 使用 Ruby 而不是经典缓存作为缓存系统模拟。

* `-m TICKS, --abs-max-tick=TICKS`

    * 运行到指定的绝对模拟 tick，包括从恢复的检查点开始的 tick。如果您只想模拟一定的模拟时间，这很有用。

* `-I MAXINSTS, --maxinsts=MAXINSTS`

    * 要模拟的总指令数（默认值：永远运行）。如果您想在执行了一定数量的指令后停止模拟，这很有用。

* `-c CMD, --cmd=CMD`

    * 在系统调用仿真模式下运行的二进制文件。

* `-o OPTIONS, --options=OPTIONS`

    * 传递给二进制文件的选项，在整个字符串周围使用 ” ”。这在运行带选项的命令时很有用。您可以通过此变量传递参数和选项（例如，–whatever）。

* `--output=OUTPUT`

    * 将 stdout 重定向到文件。如果您想将模拟应用程序的输出重定向到文件而不是打印到屏幕，这很有用。注意：要重定向 gem5 输出，您必须在配置脚本之前传递一个参数。

* `--errout=ERROUT`

    * 将 stderr 重定向到文件。类似于上面。
