---
layout: documentation
title: 全系统 AMD GPU 模型
doc: gem5 documentation
parent: gpu_models
permalink: /documentation/general_docs/gpu_models/gpufs
---

# **全系统 AMD GPU 模型**

全系统 AMD GPU 模型在 "gfx9" ISA 级别模拟 GPU，而不是中间语言级别。本页将为您提供如何使用此模型、模型使用的软件堆栈的概述，并提供详细说明模型及其实现方式的资源。**建议使用全系统而不是系统仿真，因为全系统支持最新版本的 GPU 软件堆栈。**

## 要求

全系统 GPU 模型主要设计用于使用原生软件堆栈模拟独立 GPU，无需修改。这意味着模拟的 CPU 部分未配置为详细模拟——只有 GPU 是详细的。[ROCm 软件堆栈](https://rocm.docs.amd.com/en/latest/)将使用限制为 [ROCm 文档](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/reference/system-requirements.html)中列出的官方支持的 gfx9 设备。目前 gem5 为 Vega10 (gfx900)、MI210/MI250X (gfx90a) 和 MI300X (gfx942) 提供配置。

*注意*：旧版本 ROCm 中以前支持的 "gfx9" 设备在大多数情况下仍然有效（gfx900、gfx906）。如 ROCm 文档中所述，这些可能导致预构建 ROCm 库的运行时错误。

代码的 CPU 部分理想情况下使用 KVM CPU 模型进行快进。由于软件堆栈是 x86，您需要启用 KVM 的 x86 Linux 主机才能高效运行全系统。原子 CPU 也可以用于在非 x86 主机上运行或 KVM 不可用的地方。有关详细信息，请参阅[不使用 KVM 运行](#Running-without-kvm)部分。

## **使用模型**

本指南中的几个地方假设 gem5 和 gem5-resources 位于同一基础目录中。

[gem5 仓库](https://github.com/gem5/gem5)包含 GPU 模型的基础代码。
[gem5-resources 仓库](https://github.com/gem5/gem5-resources/)包含创建全系统磁盘镜像所需的文件，并附带许多可用于开始使用模型的示例应用程序。我们建议用户从 [square](https://resources.gem5.org/resources/square) 开始，因为它是一个简单、经过大量测试的应用程序，应该运行得相对较快。

#### 构建 gem5

GPU 模型需要 GPU_VIPER 缓存一致性协议，该协议在 Ruby 中实现，全系统软件堆栈仅在模拟 X86 环境中受支持。VEGA_X86 构建选项使用 GPU_VIPER 协议和 x86。因此，必须使用 VEGA_X86 构建选项构建 gem5：

```
scons build/VEGA_X86/gem5.opt
```

全系统 GPU 模型的构建方式与仅 CPU 版本的 gem5 类似。有关如何构建 gem5 的信息，包括构建线程数、链接器选项和 gem5 二进制目标，请参阅[构建 gem5](https://www.gem5.org/documentation/general_docs/building)文档。

#### 构建磁盘镜像和内核

就像仅 CPU 版本的 gem5 一样，全系统 GPU 模型需要磁盘镜像和内核才能运行。[gem5-resources 仓库](https://github.com/gem5/gem5-resources/)提供一步式磁盘镜像构建器，用于为 GPU 模型创建安装了所有软件要求的磁盘镜像。

从克隆了 gem5 和 gem5-resources 的基础目录，导航到 [gem5-resources/src/x86-ubuntu-gpu-ml](https://github.com/gem5/gem5-resources/tree/stable/src/x86-ubuntu-gpu-ml)。此目录包含文件 `./build.sh` 以一步创建磁盘镜像。构建磁盘依赖于使用 [QEMU](https://www.qemu.org/) 作为后端的 [packer](https://www.packer.io/) 工具。有关故障排除，请参阅 [BUILDING.md](https://github.com/gem5/gem5-resources/blob/stable/src/x86-ubuntu-gpu-ml/BUILDING.md) 指南。通常，可以使用以下命令一步创建磁盘镜像：

```
./build.sh
```

此过程大约需要 15-20 分钟，主要受下载速度限制，因为大部分时间都花在下载 Ubuntu 软件包上。

构建磁盘镜像也会提取 Linux 内核。提取的 Linux 内核*必须*与磁盘镜像一起使用。换句话说，您不能向 gem5 输入任意内核，否则 GPU 驱动程序可能无法成功加载。

此过程后，您的环境应包含：
* 磁盘镜像：`gem5-resources/src/x86-ubuntu-gpu-ml/disk-image/x86-ubuntu-gpu-ml`
* 内核：`gem5-resources/src/x86-ubuntu-gpu-ml/vmlinux-gpu-ml`

#### 构建 GPU 应用程序

GPU 模型设计用于运行未修改的 GPU 二进制文件。如果您有一个在 AMD GPU 硬件上运行的应用程序，并且该硬件在 gem5 中受支持，您可以在 gem5 中运行相同的二进制文件。请注意，由于这是模拟，应用程序需要缩小到合理的大小，以便在现实的时间内进行模拟。

为 GPU 模型构建应用程序类似于[交叉编译](https://www.gem5.org/documentation/general_docs/compiling_workloads/)，当模拟的 ISA 与主机不匹配时。您必须在本地安装开发工具，或者可以使用像 Docker 这样的容器化。gem5 在 [util/dockerfiles/gpu-fs](https://github.com/gem5/gem5/tree/stable/util/dockerfiles/gpu-fs) 中提供了用于构建 GPU 应用程序的 Docker 镜像。您可以构建此镜像或使用 gem5 在 `ghcr.io/gem5/gpu-fs` 提供的镜像。此 docker 镜像提供特定版本的 ROCm。Dockerfile 中的 ROCm 版本必须与用于模拟 gem5 的磁盘镜像上的 ROCm 版本匹配。docker 和磁盘镜像版本在 gem5 发布时同步。下面的说明显示了使用 GitHub 容器注册表 (ghcr.io) 上预构建的 gem5 docker 的示例。

[Square](https://github.com/gem5/gem5-resources/tree/stable/src/gpu/square) 是 gem5-resources 中提供的一个简单应用程序，可用于开始使用模型。通常，gem5-resources 的 `src/gpu` 目录包含用于构建原生应用程序的 `Makefile.default` 和包含使用 [m5ops](https://www.gem5.org/documentation/general_docs/m5ops/) 注释的应用程序的 `Makefile.gpufs`，该应用程序仅在 gem5 内运行。

要使用 gem5 提供的 docker 镜像构建 square，请导航到 square 目录并使用 `Makefile.default` Makefile：

```
cd gem5-resources/src/gpu/square
docker run --rm -u $UID:$GID -v $PWD:$PWD -w $PWD ghcr.io/gem5/gpu-fs make -f Makefile.default
```

然后 square 二进制文件应位于 `gem5-resources/src/gpu/square/bin.default/square.default`

#### 测试 GPU 应用程序

GPU 模型提供多个 gfx9 配置来模拟 GPU 应用程序。配置指定 ISA（例如，gfx942、gfx90a）并且通常是最小尺寸的设备。*它们不旨在表示真实的硬件测量*。在 gem5 仓库中，这些是：
* MI300X：`configs/example/gpufs/mi300.py`
* MI210 / MI250：`configs/example/gpufs/mi200.py`

GPU 模型使用基于配置脚本的配置（即，不是[标准库](https://www.gem5.org/documentation/gem5-stdlib/overview)），它使用命令行参数作为修改模拟参数的主要方式。但是，大多数常见配置选项由顶级脚本设置（例如，`configs/example/gpufs/mi300.py`）。主要必需的参数是磁盘镜像、内核和应用程序。

使用上面创建的磁盘镜像和内核以及上面构建的 square 二进制文件，可以使用以下命令运行 square：

```
build/VEGA_X86/gem5.opt configs/example/gpufs/mi300.py --disk-image gem5-resources/src/x86-ubuntu-gpu-ml/disk-image/x86-ubuntu-gpu-ml --kernel gem5-resources/src/x86-ubuntu-gpu-ml/vmlinux-gpu-ml --app gem5-resources/src/gpu/square/bin.default/square.default
```

在全系统中，模拟器的输出和模拟系统的输出显示在两个不同的位置。默认情况下，gem5 输出打印到运行 gem5 的终端。模拟终端输出位于 gem5 输出目录中，默认为 `m5out`。

一旦 gem5 完成（或运行时），全系统模拟的输出可以在 `m5out/system.pc.com_1.device` 中看到。对于 square 示例，应用程序在成功完成时会将 "PASSED!" 打印到模拟终端输出。

#### 使用 Python 或 shell 脚本

Python 脚本（如 PyTorch、TensorFlow 等）和 shell 脚本可以直接作为 `--app` 命令行的值传递。例如，以下最小的 PyTorch 应用程序在保存为 `pytorch_test.py` 时可以直接运行：

```
#!/usr/bin/env python3

import torch

x = torch.rand(5, 3).to('cuda')
y = torch.rand(3, 5).to('cuda')

z = x @ y
```

例如：

```
build/VEGA_X86/gem5.opt configs/example/gpufs/mi300.py --disk-image gem5-resources/src/x86-ubuntu-gpu-ml/disk-image/x86-ubuntu-gpu-ml --kernel gem5-resources/src/x86-ubuntu-gpu-ml/vmlinux-gpu-ml --app ./pytorch_test.py
```

#### 输入文件

GPU 模型配置文件设计用于将提供给 `--app` 选项的文件复制到模拟器中。**全系统 gem5 无法从主机系统读取文件！**如果您的应用程序需要输入文件，必须将它们复制到磁盘镜像中。有关如何执行此操作的说明，请参阅[扩展磁盘镜像](https://github.com/gem5/gem5-resources/blob/stable/src/x86-ubuntu-gpu-ml/BUILDING.md)。

如果您的应用程序需要输入文件，建议创建一个 shell 脚本并将 shell 脚本传递给 `--app` 选项。shell 脚本应该使用相对于磁盘镜像路径的路径编写，因为它将在 gem5 内运行。例如，如果您的应用程序需要 `foo.dat`，请创建一个 shell 脚本，例如：

```
#!/bin/bash

# We have previously copied foo.dat to /data outside of simulation.
cd /data
my_gpu_app -i foo.dat
```

## 高级用法

#### 不使用 KVM 运行

AtomicSimpleCPU 也可以用于主机不是 x86 或 KVM 不可用的情况。要启用原子 CPU，您需要修改配置（例如，`configs/example/gpufs/mi300.py`）并将 `args.cpu_type = "X86KvmCPU"` 替换为 `args.cpu_type = "AtomicSimpleCPU"`。

请注意，这可能会使模拟的 CPU 部分减慢 100 倍。可以使用[检查点](https://www.gem5.org/documentation/general_docs/checkpoints/)来加速。

#### 检查点

提供的配置脚本允许在 Linux 启动后立即进行检查点。建议在使用原子 CPU 时使用此功能。要在启动后创建检查点，只需在命令行中添加 `--checkpoint-dir` 以及放置检查点的目录。例如：

```
build/VEGA_X86/gem5.opt configs/example/gpufs/mi300.py --disk-image gem5-resources/src/x86-ubuntu-gpu-ml/disk-image/x86-ubuntu-gpu-ml --kernel gem5-resources/src/x86-ubuntu-gpu-ml/vmlinux-gpu-ml --app gem5-resources/src/gpu/square/bin.default/square.default --checkpoint-dir square-cpt
```

然后可以恢复检查点，重新模拟应用程序将花费更少的时间。要恢复检查点，请将 `--checkpoint-dir` 选项替换为 `--restore-dir`：

```
build/VEGA_X86/gem5.opt configs/example/gpufs/mi300.py --disk-image gem5-resources/src/x86-ubuntu-gpu-ml/disk-image/x86-ubuntu-gpu-ml --kernel gem5-resources/src/x86-ubuntu-gpu-ml/vmlinux-gpu-ml --app gem5-resources/src/gpu/square/bin.default/square.default --restore-dir square-cpt
```

也可以使用 `m5_checkpoint(..)` [伪指令]()或在退出事件后在 python 配置中进行检查点来获取检查点。例如，可以使用 `--exit-at-gpu-task=-1` 启用内核退出事件，并且可以通过检查 `configs/example/gpufs/runfs.py` 中的当前任务编号来修改配置以在第 *N* 个内核处创建检查点。

请注意，当前不支持在 GPU 内核内进行检查点。因此，必须在没有 GPU 内核运行时进行检查点。

#### 构建 GPU 自定义应用程序

如果您想构建不属于 gem5-resources 的应用程序，您将希望构建针对 `gfx90a`（MI210 和 MI250）、`gfx942`（MI300X）或两者的 GPU 应用程序。例如：

```
hipcc my_gpu_app.cpp -o my_gpu_app --offload-arch=gfx90a,gfx942
```

您可以在 x86 Linux 主机上不使用 docker 镜像进行构建，方法是按照 [ROCm Linux 文档](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/)中的步骤设置包管理器后安装 rocm-dev 包。

#### 修改 GPU 配置

`configs/example/gpufs/` 中的配置是与 `configs/example/gpufs/runfs.py` 接口的辅助配置，并为特定设备设置有意义的默认值。此文件中一些感兴趣的参数是计算单元数、GPU 拓扑、系统内存大小和 CPU 类型。

其中一些参数*仅*修改 gem5 中的值，不会更改模拟设备。特别是 dgpu_mem_size 参数不会更改设备驱动程序看到的内存量，并且在 C++ 中硬编码为 16GB。更改此值将导致 gem5 致命错误。

支持的 cpu_types 是 X86KvmCPU 和 AtomicSimpleCPU，因为时序 CPU 不支持模拟独立 GPU 所需的不连续 Ruby 网络。

与 GPU 相关的其他参数可以在 `configs/example/gpufs/system/amdgpu.py` 中找到，该文件为 GPU 创建计算单元。有关所有可用选项，请参阅 `src/gpu-compute/GPU.py` 中的 ComputeUnit 类。请注意，并非所有可能的选项组合都可以测试。队列大小和延迟等选项通常可以安全修改。
