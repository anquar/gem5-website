---
layout: documentation
title: 扩展 gem5 以支持 ARM
doc: Learning gem5
parent: part1
permalink: /documentation/learning_gem5/part1/extending_configs
author: Julian T. Angeles, Thomas E. Hansen
---

扩展 gem5 以支持 ARM
======================

本章假设您已经使用 gem5 构建了一个基本的 x86 系统并创建了一个简单的配置脚本。

下载 ARM 二进制文件
------------------------

让我们从下载一些 ARM 基准测试二进制文件开始。从 gem5 文件夹的根目录开始：

```
mkdir -p cpu_tests/benchmarks/bin/arm
cd cpu_tests/benchmarks/bin/arm
wget dist.gem5.org/dist/v22-0/test-progs/cpu-tests/bin/arm/Bubblesort
wget dist.gem5.org/dist/v22-0/test-progs/cpu-tests/bin/arm/FloatMM
```

我们将使用这些来进一步测试我们的 ARM 系统。

构建 gem5 以运行 ARM 二进制文件
---------------------------------

就像我们第一次构建基本的 x86 系统时所做的那样，我们运行相同的命令，只是这次我们要使用默认的 ARM 配置进行编译。为此，我们只需将 x86 替换为 ARM：

```
scons build/ARM/gem5.opt -j 20
```

编译完成后，您应该在 `build/ARM/gem5.opt` 处拥有一个可工作的 gem5 可执行文件。

修改 simple.py 以运行 ARM 二进制文件
---------------------------------------

在我们用新系统运行任何 ARM 二进制文件之前，我们必须对 simple.py 进行一些微调。

如果您还记得我们创建简单配置脚本的时候，我们注意到除了 x86 系统之外，任何 ISA 都不需要将 PIO 和中断端口连接到内存总线。所以让我们删除这 3 行：

```
system.cpu.createInterruptController()
#system.cpu.interrupts[0].pio = system.membus.mem_side_ports
#system.cpu.interrupts[0].int_requestor = system.membus.cpu_side_ports
#system.cpu.interrupts[0].int_responder = system.membus.mem_side_ports

system.system_port = system.membus.cpu_side_ports
```

您可以删除或注释掉它们，如上所示。接下来，我们将进程命令设置为我们的一个 ARM 基准测试二进制文件：

```
process.cmd = ['cpu_tests/benchmarks/bin/arm/Bubblesort']
```

如果您想测试一个简单的 hello 程序，就像以前一样，只需将 x86 替换为 arm：

```
process.cmd = ['tests/test-progs/hello/bin/arm/linux/hello']
```

运行 gem5
------------

像以前一样运行它，只是将 X86 替换为 ARM：

```
build/ARM/gem5.opt configs/tutorial/simple.py
```

如果您将进程设置为 Bubblesort 基准测试，您的输出应如下所示：

```
gem5 Simulator System.  http://gem5.org
gem5 is copyrighted software; use the --copyright option for details.

gem5 compiled Oct  3 2019 16:02:35
gem5 started Oct  6 2019 13:22:25
gem5 executing on amarillo, pid 77129
command line: build/ARM/gem5.opt configs/tutorial/simple.py

Global frequency set at 1000000000000 ticks per second
warn: DRAM device capacity (8192 Mbytes) does not match the address range assigned (512 Mbytes)
0: system.remote_gdb: listening for remote gdb on port 7002
Beginning simulation!
info: Entering event queue @ 0.  Starting simulation...
info: Increasing stack size by one page.
warn: readlink() called on '/proc/self/exe' may yield unexpected results in various settings.
      Returning '/home/jtoya/gem5/cpu_tests/benchmarks/bin/arm/Bubblesort'
-50000
Exiting @ tick 258647411000 because exiting with last active thread context
```

ARM 全系统模拟
--------------------------
要运行 ARM FS 模拟，需要对设置进行一些更改。

如果您还没有这样做，请从 gem5 仓库的根目录，运行以下命令 `cd` 进入 `util/term/` 目录

```bash
$ cd util/term/
```

然后运行以下命令编译 `m5term` 二进制文件

```bash
$ make
```

gem5 仓库附带了示例系统设置和配置。这些可以在 `configs/example/arm/` 目录中找到。

一系列全系统 Linux 镜像文件可在 [此处](https://www.gem5.org/documentation/general_docs/fullsystem/guest_binaries) 获得。
将这些保存在一个目录中并记住其路径。例如，您可以将它们存储在

```
/path/to/user/gem5/fs_images/
```

在本例的其余部分，将假定 `fs_images` 目录包含提取的 FS 镜像。

下载镜像后，在终端中执行以下命令：

```bash
$ export IMG_ROOT=/absolute/path/to/fs_images/<image-directory-name>
```

将 "\<image-directory-name\>" 替换为从下载的镜像文件中提取的目录名称，不带尖括号。

我们现在准备好运行 FS ARM 模拟了。从 gem5 仓库的根目录运行：

```bash
$ ./build/ARM/gem5.opt configs/example/arm/fs_bigLITTLE.py \
    --caches \
    --bootloader="$IMG_ROOT/binaries/<bootloader-name>" \
    --kernel="$IMG_ROOT/binaries/<kernel-name>" \
    --disk="$IMG_ROOT/disks/<disk-image-name>" \
    --bootscript=path/to/bootscript.rcS
```

将尖括号中的任何内容替换为目录或文件的名称，不带尖括号。

然后，您可以通过在不同的终端窗口中运行以下命令来连接到模拟：

```bash
$ ./util/term/m5term 3456
```

通过运行以下命令可以获得 `fs_bigLITTLE.py` 脚本支持的完整详细信息：

```bash
$ ./build/ARM/gem5.opt configs/example/arm/fs_bigLITTLE.py --help
```

> **FS 模拟旁白：**
>
> 请注意，FS 模拟需要很长时间；就像“加载内核需要 1 小时”那么长！有一些方法可以“快进”模拟，然后在感兴趣的点恢复详细模拟，但这超出了本章的范围。
