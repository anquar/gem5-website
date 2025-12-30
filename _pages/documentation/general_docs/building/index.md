---
layout: documentation
title: 构建 gem5
doc: gem5 documentation
parent: building_extras
permalink: /documentation/general_docs/building
authors: Bobby R. Bruce
---

# 构建 gem5

## 支持的操作系统和环境

gem5 的设计考虑了 Linux 环境。我们定期在 **Ubuntu 22.04** 和 **Ubuntu 24.04** 上进行测试，以确保 gem5 在这些环境中运行良好。不过，**如果安装了正确的依赖项，任何基于 Linux 的操作系统都应该可以运行**。我们确保 gem5 可以使用 gcc 和 clang 进行编译（有关编译器版本信息，请参见下面的 [依赖项](#dependencies)）。

从 gem5 21.0 开始，**我们仅支持使用 Python 3.6+ 构建和运行 gem5**。gem5 20.0 是我们最后一个提供 Python 2 支持的版本。

如果无法在合适的 OS/环境中运行 gem5，我们提供了预先准备好的 [Docker](https://www.docker.com/) 镜像，可用于编译和运行 gem5。有关更多信息，请参阅下面的 [Docker](#docker) 部分。

## 依赖项

* **git** : gem5 使用 git 进行版本控制。
* **gcc**: gcc 用于编译 gem5。**必须使用版本 >=10**。我们支持最高到 gcc 版本 13。
* **Clang**: 也可以使用 Clang。目前，我们支持 Clang 7 到 Clang 16（含）。
* **SCons** : gem5 使用 SCons 作为其构建环境。必须使用 SCons 3.0 或更高版本。
* **Python 3.6+** : gem5 依赖于 Python 开发库。gem5 可以在使用 Python 3.6+ 的环境中编译和运行。
* **protobuf 2.1+** (可选): protobuf 库用于 trace 生成和回放。
* **Boost** (可选): Boost 库是一组通用的 C++ 库。如果您希望使用 SystemC 实现，它是必要的依赖项。

### 在 Ubuntu 24.04 上设置 (gem5 >= v24.0)

如果在 Ubuntu 24.04 或相关的 Linux 发行版上编译 gem5，您可以使用 APT 安装所有这些依赖项：

```bash
sudo apt install build-essential scons python3-dev git pre-commit zlib1g zlib1g-dev \
    libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev \
    libboost-all-dev  libhdf5-serial-dev python3-pydot python3-venv python3-tk mypy \
    m4 libcapstone-dev libpng-dev libelf-dev pkg-config wget cmake doxygen clang-format
```

### 在 Ubuntu 22.04 上设置 (gem5 >= v21.1)

如果在 Ubuntu 22.04 或相关的 Linux 发行版上编译 gem5，您可以使用 APT 安装所有这些依赖项：

```bash
sudo apt install build-essential git m4 scons zlib1g zlib1g-dev \
    libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev \
    python3-dev libboost-all-dev pkg-config python3-tk clang-format-15
```

您可能需要将 `clang-format-15` 配置为系统的默认 `clang-format`。

```bash
# 将 clang-format-15 和 git-clang-format-15 配置为系统默认值。
sudo update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-15 150 \
        --slave /usr/bin/clang-format-diff clang-format-diff /usr/bin/clang-format-diff-15 \
        --slave /usr/bin/git-clang-format git-clang-format /usr/bin/git-clang-format-15

# [可选] 添加其他替代版本，并选择版本 15 作为默认版本。
sudo update-alternatives --config clang-format
```

### 在 Ubuntu 20.04 上设置 (gem5 >= v21.0)

如果在 Ubuntu 20.04 或相关的 Linux 发行版上编译 gem5，您可以使用 APT 安装所有这些依赖项：

```bash
sudo apt install build-essential git m4 scons zlib1g zlib1g-dev \
    libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev \
    python3-dev python-is-python3 libboost-all-dev pkg-config gcc-10 g++-10 \
    python3-tk clang-format-18
```

您可能需要将 `clang-format-18` 配置为系统的默认 `clang-format`。

```bash
# 将 clang-format-18 和 git-clang-format-18 配置为系统默认值。
sudo update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-18 180 \
        --slave /usr/bin/clang-format-diff clang-format-diff /usr/bin/clang-format-diff-18 \
        --slave /usr/bin/git-clang-format git-clang-format /usr/bin/git-clang-format-18

# [可选] 添加其他替代版本，并选择版本 18 作为默认版本。
sudo update-alternatives --config clang-format
```

### Docker

对于难以设置构建和运行 gem5 环境的用户，我们提供以下 Docker 镜像：

包含所有可选依赖项的 Ubuntu 24.04:
[ghcr.io/gem5/ubuntu-24.04_all-dependencies:v24-0](
https://ghcr.io/gem5/ubuntu-24.04_all-dependencies:v24-0)
([源 Dockerfile](https://github.com/gem5/gem5/blob/v24.0.0.0/util/dockerfiles/ubuntu-24.04_all-dependencies/Dockerfile)).

具有最小依赖项的 Ubuntu 24.04:
[ghcr.io/gem5/ubuntu-24.04_min-dependencies:v24-0](
https://ghcr.io/gem5/ubuntu-24.04_min-dependencies:v24-0)
([源 Dockerfile](https://github.com/gem5/gem5/blob/v24.0.0.0/util/dockerfiles/ubuntu-24.04_min-dependencies/Dockerfile)).

包含所有可选依赖项的 Ubuntu 22.04:
[ghcr.io/gem5/ubuntu-22.04_all-dependencies:v23-0](
https://ghcr.io/gem5/ubuntu-22.04_all-dependencies:v23-0) ([源 Dockerfile](
https://github.com/gem5/gem5/blob/v23.0.1.0/util/dockerfiles/ubuntu-22.04_all-dependencies/Dockerfile)).

包含所有可选依赖项的 Ubuntu 20.04:
[ghcr.io/gem5/ubuntu-20.04_all-dependencies:v23-0](
https://ghcr.io/gem5/ubuntu-20.04_all-dependencies:v23-0) ([源 Dockerfile](
https://github.com/gem5/gem5/blob/v23.0.1.0/util/dockerfiles/ubuntu-20.04_all-dependencies/Dockerfile)).

包含所有可选依赖项的 Ubuntu 18.04:
[ghcr.io/gem5/ubuntu-18.04_all-dependencies:v23-0](
https://ghcr.io/gem5/ubuntu-18.04_all-dependencies:v23-0) ([源 Dockerfile](
https://github.com/gem5/gem5/blob/v23.0.1.0/util/dockerfiles/ubuntu-18.04_all-dependencies/Dockerfile)).

获取 docker 镜像：

```bash
docker pull <image>
```

例如，对于包含所有可选依赖项的 Ubuntu 20.04：

```bash
docker pull ghcr.io/gem5/ubuntu-20.04_all-dependencies:v23-0
```

然后，要在此环境中工作，我们建议使用以下命令：

```bash
docker run -u $UID:$GID --volume <gem5 directory>:/gem5 --rm -it <image>
```

其中 `<gem5 directory>` 是文件系统中 gem5 的完整路径，`<image>` 是拉取的镜像（例如，`ghcr.io/gem5/ubuntu-22.04_all-dependencies:v23-0`）。

在此环境中，您将能够从 `/gem5` 目录构建和运行 gem5。

## 获取代码

```bash
git clone https://github.com/gem5/gem5
```

## 使用 SCons 构建

gem5 的构建系统基于 SCons，这是一个用 Python 实现的开源构建系统。您可以在 <http://www.scons.org> 找到有关 scons 的更多信息。主要的 scons 文件称为 SConstruct，位于源代码树的根目录中。其他 scons 文件名为 SConscript，遍布整个树中，通常位于它们关联的文件附近。

在 gem5 目录的根目录下，可以使用以下命令使用 SCons 构建 gem5：

```bash
scons build/{ISA}/gem5.{variant} -j {cpus}
```

其中 `{ISA}` 是目标（客户机）指令集架构，`{variant}` 指定编译设置。对于大多数意图和目的，`opt` 是一个很好的编译目标。`-j` 标志是可选的，允许并行编译，其中 `{cpus}` 指定线程数。单线程从头编译在某些系统上可能需要长达 2 小时。因此，我们强烈建议尽可能分配更多线程。但是，gem5 的编译是计算和内存密集型的，增加线程数也会增加内存使用量。如果使用内存较少的机器，建议使用较少的线程（例如 `-j 1` 或 `-j 2`）。

有效的 ISA 有：

* ALL - 推荐，截至 gem5 v24.1，它包含所有 ISA 和所有 Ruby 协议
* ARM
* NULL
* MIPS
* POWER
* RISCV
* SPARC
* X86

有效的构建变体 (variant) 有：

* **debug** 关闭了优化。这确保变量不会被优化掉，函数不会被意外内联，并且控制流不会以令人惊讶的方式运行。这使得此版本更容易在 gdb 等工具中使用，但如果没有优化，此版本比其他版本慢得多。当使用 gdb 和 valgrind 等工具并且不想掩盖任何细节时，您应该选择它，否则建议使用更优化的版本。
* **opt** 开启了优化，并保留了 assert 和 DPRINTF 等调试功能。这在模拟速度和出现问题时洞察发生的情况之间取得了很好的平衡。此版本在大多数情况下是最好的。
* **fast** 开启了优化，并编译掉了调试功能。这在性能方面全力以赴，但以运行时错误检查和打开调试输出的能力为代价。如果您非常有信心一切正常并且想要从模拟器获得峰值性能，建议使用此版本。

下表总结了这些版本。

|构建变体|优化|运行时调试支持|
|-------------|-------------|--------------------------|
|**debug**    |             |X                         |
|**opt**      |X            |X                         |
|**fast**     |X            |                          |

例如，要在 4 个线程上使用 `opt` 和所有 ISA 构建 gem5：

```bash
scons build/ALL/gem5.opt -j 4
```

此外，用户可以使用 "gprof" 和 "pperf" 构建选项来启用分析：

* **gprof** 允许将 gem5 与 gprof 分析工具一起使用。可以通过使用 `--gprof` 标志编译来启用它。例如，`scons build/ALL/gem5.debug --gprof`。
* **pprof** 允许将 gem5 与 pprof 分析工具一起使用。可以通过使用 `--pprof` 标志编译来启用它。例如，`scons build/ALL/gem5.debug --pprof`。

## 使用 Kconfig 构建

请参阅 [这里](https://www.gem5.org/documentation/general_docs/kconfig_build_system/)

## 用法

编译完成后，可以使用以下命令运行 gem5：

```console
./build/{ISA}/gem5.{variant} [gem5 options] {simulation script} [script options]
```

如果您是从预编译的二进制文件构建 gem5，可以使用以下命令运行 gem5：

```console
gem5 [gem5 options] {simulation script} [script options]
```

使用 `--help` 标志运行将显示所有可用选项：

```txt
Usage
=====
  gem5.opt [gem5 options] script.py [script options]

gem5 is copyrighted software; use the --copyright option for details.

Options
=======
--help, -h              show this help message and exit
--build-info, -B        Show build information
--copyright, -C         Show full copyright information
--readme, -R            Show the readme
--outdir=DIR, -d DIR    Set the output directory to DIR [Default: m5out]
--redirect-stdout, -r   Redirect stdout (& stderr, without -e) to file
--redirect-stderr, -e   Redirect stderr to file
--silent-redirect       Suppress printing a message when redirecting stdout or
                        stderr
--stdout-file=FILE      Filename for -r redirection [Default: simout.txt]
--stderr-file=FILE      Filename for -e redirection [Default: simerr.txt]
--listener-mode={on,off,auto}
                        Port (e.g., gdb) listener mode (auto: Enable if
                        running interactively) [Default: auto]
--allow-remote-connections
                        Port listeners will accept connections from anywhere
                        (0.0.0.0). Default is only localhost.
--interactive, -i       Invoke the interactive interpreter after running the
                        script
--pdb                   Invoke the python debugger before running the script
--path=PATH[:PATH], -p PATH[:PATH]
                        Prepend PATH to the system path when invoking the
                        script
--quiet, -q             Reduce verbosity
--verbose, -v           Increase verbosity
-m mod                  run library module as a script (terminates option
                        list)
-c cmd                  program passed in as string (terminates option list)
-P                      Don't prepend the script directory to the system path.
                        Mimics Python 3's `-P` option.
-s                      IGNORED, only for compatibility with python. don'tadd
                        user site directory to sys.path; also PYTHONNOUSERSITE

Statistics Options
------------------
--stats-file=FILE       Sets the output file for statistics [Default:
                        stats.txt]
--stats-help            Display documentation for available stat visitors

Configuration Options
---------------------
--dump-config=FILE      Dump configuration output file [Default: config.ini]
--json-config=FILE      Create JSON output of the configuration [Default:
                        config.json]
--dot-config=FILE       Create DOT & pdf outputs of the configuration
                        [Default: config.dot]
--dot-dvfs-config=FILE  Create DOT & pdf outputs of the DVFS configuration
                        [Default: none]

Debugging Options
-----------------
--debug-break=TICK[,TICK]
                        Create breakpoint(s) at TICK(s) (kills process if no
                        debugger attached)
--debug-help            Print help on debug flags
--debug-flags=FLAG[,FLAG]
                        Sets the flags for debug output (-FLAG disables a
                        flag)
--debug-start=TICK      Start debug output at TICK
--debug-end=TICK        End debug output at TICK
--debug-file=FILE       Sets the output file for debug. Append '.gz' to the
                        name for it to be compressed automatically [Default:
                        cout]
--debug-activate=EXPR[,EXPR]
                        Activate EXPR sim objects
--debug-ignore=EXPR     Ignore EXPR sim objects
--remote-gdb-port=REMOTE_GDB_PORT
                        Remote gdb base port (set to 0 to disable listening)

Help Options
------------
--list-sim-objects      List all built-in SimObjects, their params and default
                        values
```

## 使用 EXTRAS

[EXTRAS](/documentation/general_docs/building/EXTRAS) scons 变量可用于将其他源文件目录构建到 gem5 中，方法是将其设置为这些其他目录的冒号分隔列表。EXTRAS 是一种在 gem5 代码库之上构建而无需将新源与上游源混合的便捷方式。然后，您可以独立于主代码库管理您的新代码体。
