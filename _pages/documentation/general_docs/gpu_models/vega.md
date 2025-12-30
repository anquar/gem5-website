---
layout: documentation
title: AMD VEGA GPU 模型
doc: gem5 documentation
parent: gpu_models
permalink: /documentation/general_docs/gpu_models/vega
---

# **系统仿真 AMD VEGA GPU 模型**

Table of Contents

1. [Using the model](#Using-the-model)
2. [ROCm](#ROCm)
3. [Documentation and Tutorials](#Documentation-and-Tutorials)

The AMD VEGA GPU is a model that simulates a GPU at the VEGA ISA level, as opposed to the intermediate language level. This page will give you a general overview of how to use this model, the software stack the model uses, and provide resources that detail the model and how it is implemented.

## **Using the model**

目前，gem5 中的 AMD VEGA GPU 模型在 stable 和 develop 分支上受支持。

[gem5 仓库](https://github.com/gem5/gem5)附带一个位于 `util/dockerfiles/gcn-gpu/` 的 dockerfile。此 dockerfile 包含运行 GPU 模型所需的驱动程序和库。docker 镜像的预构建版本托管在 `ghcr.io/gem5-test/gcn-gpu:v23-1`。
[gem5-resources 仓库](https://github.com/gem5/gem5-resources/)还附带许多可用于验证模型正确运行的示例应用程序。我们建议用户从 [square](https://resources.gem5.org/resources/square) 开始，因为它是一个简单、经过大量测试的应用程序，应该运行得相对较快。

#### 使用镜像
docker 镜像可以从 ghcr.io 构建或拉取。

从源代码构建 docker 镜像：
```
# 工作目录：gem5/util/dockerfiles/gcn-gpu
docker build -t <image_name> .
```

拉取预构建的 docker 镜像（注意 `v23-1` 标签，以获取此版本的
正确镜像）：

```
docker pull ghcr.io/gem5-test/gcn-gpu:v23-1
```

您也可以将 `ghcr.io/gem5-test/gcn-gpu:v23-1` 作为 docker run 命令中的镜像，而无需事先拉取，它将自动拉取。
#### 使用镜像构建 gem5
有关如何在 docker 中构建 gem5 的示例，请参阅 [gem5 resources](https://github.com/gem5/gem5-resources/tree/stable/src/gpu/square/) 中的 square。注意：这些说明假设您自动拉取最新镜像。

#### 使用镜像构建和运行 GPU 应用程序
有关如何在 docker 中构建和运行 GPU 应用程序的示例，请参阅 [gem5 resources](https://github.com/gem5/gem5-resources/tree/stable/src/gpu/)。

## **ROCm**

AMD VEGA GPU 模型设计具有足够的保真度，不需要模拟运行时。相反，模型使用 Radeon Open Compute 平台 (ROCm)。ROCm 是来自 AMD 的开放平台，实现了[异构系统架构 (HSA)](http://www.hsafoundation.com/) 原则。有关 HSA 标准的更多信息可以在 HSA Foundation 的网站上找到。有关 ROCm 的更多信息可以在 [ROCm 网站](https://rocmdocs.amd.com/en/latest/)上找到。

#### ROCm 的模拟支持
该模型目前适用于系统调用仿真 (SE) 模式和全系统 (FS) 模式。

在 SE 模式下，所有内核级驱动程序功能都在 gem5 的 SE 模式层内完全建模。特别是，模拟的 GPU 驱动程序支持它从用户空间代码接收的必要 `ioctl()` 命令。模拟 GPU 驱动程序的源代码可以在以下位置找到：

* GPU 计算驱动程序：`src/gpu-compute/gpu_compute_driver.[hh|cc]`

* HSA 设备驱动程序：`src/dev/hsa/hsa_driver.[hh|cc]`

HSA 驱动程序代码为 HSA 代理建模基本功能，HSA 代理是可以由 HSA 运行时定位并接受架构查询语言 (AQL) 数据包的设备。AQL 数据包是所有 HSA 代理的标准格式，主要用于在 GPU 上启动内核。基类 `HSADriver` 持有设备 HSA 数据包处理器的指针，并定义任何 HSA 设备的接口。HSA 代理不必是 GPU，它可以是通用加速器、CPU、NIC 等。

`GPUComputeDriver` 派生自 `HSADriver`，是 `HSADriver` 的设备特定实现。它提供 GPU 特定 `ioctl()` 调用的实现。

`src/dev/hsa/kfd_ioctl.h` 头文件必须与 ROCt 附带的 `kfd_ioctl.h` 头文件匹配。模拟驱动程序依赖该文件来解释 thunk 使用的 `ioctl()` 代码。

在 FS 模式下，使用真实的 amdgpu Linux 驱动程序并像在真实机器上一样安装。驱动程序的源代码可以在 [ROCK-Kernel-Driver](https://github.com/RadeonOpenCompute/ROCK-Kernel-Driver) 仓库中找到。

#### ROCm 工具链和软件堆栈
AMD VEGA GPU 模型在 FS 模式下支持高达 5.4 的 ROCm 版本，在 SE 模式下支持 4.0。

SE 模式下需要以下 ROCm 组件：
* [异构计算编译器 (HCC)](https://github.com/RadeonOpenCompute/hcc)
* [Radeon Open Compute 运行时 (ROCr)](https://github.com/RadeonOpenCompute/ROCR-Runtime)
* [Radeon Open Compute thunk (ROCt)](https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface)
* [HIP](https://github.com/ROCm-Developer-Tools/HIP)

以下附加组件用于构建和运行机器学习程序：
* [hipBLAS](https://github.com/ROCmSoftwarePlatform/hipBLAS/)
* [rocBLAS](https://github.com/ROCmSoftwarePlatform/rocBLAS/)
* [MIOpen](https://github.com/ROCmSoftwarePlatform/MIOpen/)
* [rocm-cmake](https://github.com/RadeonOpenCompute/rocm-cmake/)
* [PyTorch](https://pytorch.org/)（仅 FS 模式）
* [Tensorflow](https://www.tensorflow.org/) - 特别是 tensorflow-rocm python 包（仅 FS 模式）

有关在本地安装这些组件的信息，可以在 Ubuntu 16 机器上按照 GCN3 dockerfile（`util/dockerfiles/gcn-gpu/`）中的命令操作。

## **文档和教程**

请注意，VEGA ISA 是从 GCN3 派生的更新的超集 ISA。因此，以下论文、教程和文档的内容也适用于 VEGA。

#### GPU 模型
描述了具有 GCN3 ISA 的 gem5 GPU 模型（在撰写本文时）。VEGA 是从 GCN3 派生的更新的超集 ISA。因此以下论文的内容）
* [HPCA 2018](https://ieeexplore.ieee.org/document/8327041)

#### gem5 GCN3 ISCA 教程
涵盖有关 gem5 中的 GPU 架构、GCN3 ISA 和 HW-SW 接口的信息。还提供了 ROCm 的介绍。
* [gem5 GCN3 ISCA 网页](http://www.gem5.org/events/isca-2018)
* [gem5 GCN3 ISCA 幻灯片](http://old.gem5.org/wiki/images/1/19/AMD_gem5_APU_simulator_isca_2018_gem5_wiki.pdf)

#### VEGA ISA
* [VEGA ISA](https://gpuopen.com/documentation/amd-isa-documentation/)

#### ROCm 文档
包含有关 ROCm 堆栈的进一步文档，以及使用 ROCm 的编程指南。
* [ROCm 网页](https://rocmdocs.amd.com/en/latest/)

#### AMDGPU LLVM 信息
* [LLVM AMDGPU](https://llvm.org/docs/AMDGPUUsage.html)
