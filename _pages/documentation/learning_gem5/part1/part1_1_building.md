---
layout: documentation
title: 构建 gem5
doc: Learning gem5
parent: part1
permalink: /documentation/learning_gem5/part1/building/
author: Jason Lowe-Power
---

构建 gem5
=============

本章涵盖了如何设置 gem5 开发环境和构建 gem5 的细节。

如果您有预构建的二进制文件
-----------------------------

如果您使用预构建的二进制文件运行 gem5，您可以跳过本节。
预构建的二进制文件使用 ALL 构建，可用于运行所有 ISA 和所有 Ruby 一致性协议。

gem5 的要求
---------------------

有关更多详细信息，请参阅 [gem5 要求](http://www.gem5.org/documentation/general_docs/building#dependencies)。

在 Ubuntu 上，您可以使用以下命令安装所有必需的依赖项。要求详情如下。

```bash
sudo apt install build-essential git m4 scons zlib1g zlib1g-dev libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev python-dev python
```

1. git ([Git](https://git-scm.com/)):
    :   gem5 项目使用 [Git](https://git-scm.com/) 进行版本控制。[Git](https://git-scm.com/) 是一个分布式版本控制系统。有关 [Git](https://git-scm.com/) 的更多信息，请点击链接。Git 应该在大多数平台上默认安装。但是，要在 Ubuntu 中安装 Git，请使用：

    ```bash
    sudo apt install git
    ```

2. gcc 10+
    :   您可能需要使用环境变量指向非默认版本的 gcc。

        在 Ubuntu 上，您可以使用以下命令安装开发环境：

        ```bash
        sudo apt install build-essential
        ```

       **我们支持 GCC 版本 >=10，最高到 GCC 13**

3.  [SCons 3.0+](http://www.scons.org/)
    :   gem5 使用 SCons 作为其构建环境。SCons 就像加强版的 make，并使用 Python 脚本进行构建过程的所有方面。这允许一个非常灵活（虽然较慢）的构建系统。

        要在 Ubuntu 上获取 SCons，请使用：

    ```bash
    sudo apt install scons
    ```

4.  Python 3.6+
    :   gem5 依赖于 Python 开发库。要在 Ubuntu 上安装这些，请使用：

    ```bash
    sudo apt install python3-dev
    ```

5.  [protobuf](https://developers.google.com/protocol-buffers/) 2.1+ (**可选**)
    :   “Protocol buffers 是一种语言中立、平台中立的可扩展机制，用于序列化结构化数据。”在 gem5 中，[protobuf](https://developers.google.com/protocol-buffers/) 库用于 Trace 生成和回放。[protobuf](https://developers.google.com/protocol-buffers/) 不是必需的包，除非您打算将其用于 Trace 生成和回放。

    ```bash
    sudo apt install libprotobuf-dev protobuf-compiler libgoogle-perftools-dev
    ```

6. [Boost](https://www.boost.org/) (**可选**)
    :   Boost 库是一组通用的 C++ 库。如果您希望使用 SystemC 实现，它是必要的依赖项。
        ```
        sudo apt install libboost-all-dev
        ```

获取代码
----------------

更改目录到您想要下载 gem5 源代码的位置。然后，使用 `git clone` 命令克隆仓库。

```bash
git clone https://github.com/gem5/gem5
```

您现在可以切换到包含所有 gem5 代码的 `gem5` 目录。

您的第一次 gem5 构建
---------------------

让我们从构建一个基本的 x86 系统开始。从 gem5 v22.1 开始，您可以编译 ALL 构建，其中包括所有 ISA。从 gem5 v24.1 开始，ALL 构建还包括所有 Ruby 缓存一致性协议。如果您正在使用 ruby-intro-chapter，这一点很重要。

要构建 gem5，我们将使用 SCons。SCons 使用 SConstruct 文件 (`gem5/SConstruct`) 设置许多变量，然后使用每个子目录中的 SConscript 文件来查找并编译所有 gem5 源代码。

SCons 在首次执行时会自动创建一个 `gem5/build` 目录。在此目录中，您将找到 SCons、编译器等生成的文件。对于您用来编译 gem5 的每组选项（ISA 和缓存一致性协议），都会有一个单独的目录。

`build_opts` 目录中有许多默认编译选项。这些文件指定了用于构建 gem5 的具有非默认值的参数。我们将使用 ALL 默认值。您可以查看文件 `build_opts/ALL` 以查看具有非默认值的 (kconfig) 设置。
对于 gem5 <= 23.0，您也可以在命令行上指定这些选项以覆盖任何默认值。对于 gem5 >= 23.1，您可以使用 kconfig 工具（如 setconfig、menuconfig 或 guiconfig）修改现有构建目录中的这些设置。

```bash
python3 `which scons` build/ALL/gem5.opt -j9
```

> **gem5 二进制类型**
>
> gem5 中的 SCons 脚本目前有 3 种不同的二进制文件可以构建：debug、opt 和 fast。这些名称大多是不言自明的，详情如下。
>
> debug
> :   使用无优化和调试符号构建。当使用调试器进行调试时，如果通过 opt 版本 gem5 运行发现需要查看的变量被优化掉了，这个二进制文件很有用。与其它二进制文件相比，使用 debug 运行很慢。
>
> opt
> :   此二进制文件是在大多数优化开启（例如 -O3）的情况下构建的，但也包含调试符号。此二进制文件比 debug 快得多，但仍包含足够的调试信息来调试大多数问题。
>
> fast
> :   在开启所有优化（包括支持平台上的链接时优化）且没有调试符号的情况下构建。此外，删除了任何 assert，但仍包括 panic 和 fatal。fast 是性能最高的二进制文件，并且比 opt 小得多。但是，只有当您觉得代码不太可能有重大错误时，才适合使用 fast。
>

传递给 SCons 的主要参数是您想要构建的内容，`build/ALL/gem5.opt`。在这种情况下，我们正在构建 gem5.opt（带有调试符号的优化二进制文件）。我们要在目录 build/ALL 中构建 gem5。由于此目录目前不存在，SCons 将在 `build_opts` 中查找 ALL 构建的参数。（注意：我在这里使用 -j9 在我的机器的 8 个核心中的 9 个线程上执行构建。您应该为您的机器选择一个合适的数字，通常是核心数+1。）

输出应该如下所示（对于 gem5 >= 24.1）：

```txt
    scons: Reading SConscript files ...
    Mkdir("/local.chinook/gem5/gem5-tutorial/gem5/build/ALL/gem5.build")
    Checking for linker -Wl,--as-needed support... (cached) yes
    Checking for compiler -gz support... (cached) yes
    Checking for linker -gz support... (cached) yes
    Info: Using Python config: python3-config
    Checking for C header file Python.h... (cached) yes
    Checking Python version... (cached) 3.12.3
    Checking for accept(0,0,0) in C++ library None... (cached) yes
    Checking for zlibVersion() in C++ library z... (cached) yes
    Checking for C library tcmalloc_minimal... (cached) yes
    Building in /home/bees/gem5-4th-worktree/build/ALL
    "build_tools/kconfig_base.py" "/home/bees/gem5-4th-worktree/build/ALL/gem5.build/Kconfig" "/home/bees/gem5-4th-worktree/src/Kconfig"
    Checking for C header file fenv.h... (cached) yes
    Checking for C header file png.h... (cached) yes
    Checking for clock_nanosleep(0,0,NULL,NULL) in C library None... (cached) yes
    Checking for C header file valgrind/valgrind.h... (cached) yes
    Checking for pkg-config package hdf5-serial... (cached) yes
    Checking for H5Fcreate("", 0, 0, 0) in C library hdf5... (cached) yes
    Checking for H5::H5File("", 0) in C++ library hdf5_cpp... (cached) yes
    Checking for pkg-config package protobuf... (cached) yes
    Checking for shm_open("/test", 0, 0) in C library None... (cached) yes
    Checking for backtrace_symbols_fd((void *)1, 0, 0) in C library None... (cached) yes
    Checking size of struct kvm_xsave ... (cached) yes
    Checking for C header file capstone/capstone.h... (cached) yes
    Checking for C header file linux/kvm.h... (cached) yes
    Checking for timer_create(CLOCK_MONOTONIC, NULL, NULL) in C library None... (cached) yes
    Checking for member exclude_host in struct perf_event_attr...(cached) yes
    Checking for C header file linux/if_tun.h... (cached) yes
    Checking whether __i386__ is declared... (cached) no
    Checking whether __x86_64__ is declared... (cached) yes
    Checking for compiler -Wno-self-assign-overloaded support... (cached) yes
    Checking for linker -Wno-free-nonheap-object support... (cached) yes
    BUILD_TLM not set, not building CHI-TLM integration

    scons: done reading SConscript files.
    scons: Building targets ...
    [     CXX] ALL/base/Graphics.py.cc -> .o
    [    LINK]  -> ALL/gem5py_m5
    [     CXX] src/base/atomicio.cc -> ALL/base/atomicio.o
    [     CXX] src/base/bitfield.cc -> ALL/base/bitfield.o

     ....
     .... <lots of output>
     ....
 [SO Param] m5.objects.Uart, Uart8250 -> ALL/params/Uart8250.hh
 [     CXX] ALL/python/_m5/param_SimpleUart.cc -> .o
 [     CXX] ALL/enums/TerminalDump.cc -> .o
 [     CXX] ALL/python/_m5/param_Uart8250.cc -> .o
 [     CXX] src/dev/serial/serial.cc -> ALL/dev/serial/serial.o
 [     CXX] src/dev/serial/simple.cc -> ALL/dev/serial/simple.o
 [     CXX] src/dev/serial/terminal.cc -> ALL/dev/serial/terminal.o
 [     CXX] src/dev/serial/uart.cc -> ALL/dev/serial/uart.o
 [     CXX] src/dev/serial/uart8250.cc -> ALL/dev/serial/uart8250.o
 [     CXX] ALL/debug/Terminal.cc -> .o
 [     CXX] ALL/debug/TerminalVerbose.cc -> .o
 [     CXX] ALL/debug/Uart.cc -> .o
 [     CXX] ALL/python/m5/defines.py.cc -> .o
 [     CXX] ALL/python/m5/info.py.cc -> .o
 [     CXX] src/base/date.cc -> ALL/base/date.o
 [    LINK]  -> ALL/gem5.opt
scons: done building targets.
```

编译完成后，您应该在 `build/ALL/gem5.opt` 处拥有一个可工作的 gem5 可执行文件。编译可能需要很长时间，通常需要 15 分钟或更长时间，特别是如果您在 AFS 或 NFS 等远程文件系统上进行编译。

常见错误
-------------

### 错误的 gcc 版本

```txt
    Error: gcc version 5 or newer required.
           Installed version: 4.4.7
```

更新您的环境变量以指向正确的 gcc 版本，或安装更新版本的 gcc。请参阅 building-requirements-section。

### Python 在非默认位置

如果您使用非默认版本的 Python（例如，当 2.5 是默认版本时使用 3.6 版），使用 SCons 构建 gem5 时可能会出现问题。RHEL6 版本的 SCons 使用硬编码的 Python 位置，这会导致问题。在这种情况下，gem5 通常构建成功，但可能无法运行。下面是您在运行 gem5 时可能看到的一个可能错误。

```txt
    Traceback (most recent call last):
      File "........../gem5-stable/src/python/importer.py", line 93, in <module>
        sys.meta_path.append(importer)
    TypeError: 'dict' object is not callable
```

要解决此问题，您可以通过运行 `` python3 `which scons` build/ALL/gem5.opt `` 而不是 `scons build/ALL/gem5.opt` 来强制 SCons 使用您环境的 Python 版本。

### 未安装 M4 宏处理器

如果未安装 M4 宏处理器，您将看到类似以下的错误：

```txt
    ...
    Checking for member exclude_host in struct perf_event_attr...yes
    Error: Can't find version of M4 macro processor.  Please install M4 and try again.
```

仅仅安装 M4 宏包可能无法解决此问题。您可能还需要安装所有 `autoconf` 工具。在 Ubuntu 上，您可以使用以下命令。

```bash
sudo apt-get install automake
```

### Protobuf 3.12.3 问题

使用 protobuf 编译 gem5 可能会导致以下错误，

```txt
In file included from build/X86/cpu/trace/trace_cpu.hh:53,
                 from build/X86/cpu/trace/trace_cpu.cc:38:
build/X86/proto/inst_dep_record.pb.h:49:51: error: 'AuxiliaryParseTableField' in namespace 'google::protobuf::internal' does not name a type; did you mean 'AuxillaryParseTableField'?
   49 |   static const ::PROTOBUF_NAMESPACE_ID::internal::AuxiliaryParseTableField aux[]
```

问题的根本原因在此处讨论：[https://gem5.atlassian.net/browse/GEM5-1032]。

要解决此问题，您可能需要更新 ProtocolBuffer 的版本，

```bash
sudo apt update
sudo apt install libprotobuf-dev protobuf-compiler libgoogle-perftools-dev
```

之后，您可能需要**在**重新编译 gem5 之前清理 gem5 构建文件夹，

```bash
python3 `which scons` --clean --no-cache        # 清理构建文件夹
python3 `which scons` build/ALL/gem5.opt -j 9   # 重新编译 gem5
```

如果问题仍然存在，您可能需要**在**再次编译 gem5 之前完全删除 gem5 构建文件夹，

```bash
rm -rf build/                                   # 完全删除 gem5 构建文件夹
python3 `which scons` build/ALL/gem5.opt -j 9   # 重新编译 gem5
```
