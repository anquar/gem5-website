---
layout: post
title:  "在 gem5 中模拟现代 GPU 应用"
author: Kyle Roarty and Matthew D. Sinclair
date:   2020-05-27
---

2018 年，AMD 添加了对基于其 GCN3 架构的更新 gem5 GPU 模型的支持。拥有高保真 GPU 模型允许对优化现代 GPU 应用进行更准确的研究。然而，获取此模型在 gem5 中运行 GPU 应用所需的必要库和驱动程序的复杂性使其难以使用。本文描述了我们在提高 GPU 模型可用性方面所做的工作，通过简化设置过程、扩展可运行的应用程序类型以及优化 GPU 模型使用的软件堆栈部分。

### 运行 GPU 模型

为了提供准确、高保真的模拟，AMD GPU 模型直接与 Radeon Open Compute 平台 (ROCm) 驱动程序接口。虽然 gem5 可以模拟整个系统（全系统模式或 FS 模式），包括设备和操作系统，但目前 AMD GPU 模型使用系统调用仿真 (SE) 模式。SE 模式只模拟用户空间执行，并在模拟器中提供系统服务（例如 malloc），而不是执行内核空间代码。因此，必须仿真的 ROCm 软件堆栈的唯一部分是 KFD（Kernel Fusion Driver）。因此，为了使用 AMD GPU 模型，用户必须首先在其机器上安装 ROCm。

这带来了挑战，因为 gem5 的 GPU 模型支持特定版本的 ROCm（版本 1.6），并且安装驱动程序并与 gem5 正确交互很困难。此外，要运行现代应用程序，如机器学习 (ML)，也称为机器智能 (MI) 应用程序，需要安装额外的库（例如 MIOpen、MIOpenGEMM、rocBLAS 和 hipBLAS）。但是，这些库的版本必须与 ROCm 版本 1.6 兼容。总的来说，找出确切的软件版本并安装它们既耗时又容易出错，并且创造了进入障碍，阻止用户使用 GPU 模型。

为了帮助解决这个问题，我们创建并验证了一个 Docker 镜像，其中包含在 gem5 中运行 GPU 模型所需的适当软件和库。使用此容器，用户可以运行 gem5 GPU 模型，以及构建他们想在 GPU 模型中运行的 ROCm 应用程序。此 Docker 容器已集成到公共 gem5 仓库中，我们打算将该镜像用于 GPU 模型的持续集成。此外，由于 AMD GPU 模型目前建模具有统一地址空间和一致性缓存的紧密耦合 CPU-GPU 系统，此 Docker 还包括对 HIP 和 MIOpen 的必要更改，以尽可能在这些库中移除离散 GPU 副本。

### Using the Docker image

The Dockerfile and an associated README are located at `util/dockerfiles/gcn-gpu`. This documentation can also be found at the [GCN3](/documentation/general_docs/gpu_models/GCN3) page of the gem5 website. Finally, we have also created a video demonstration of using the Docker in our gem5 workshop presentation.  Next, we briefly summarize how to use the docker image.

#### Building the image

```
cd util/dockerfiles/gcn-gpu
docker build -t <image_name> .
```

#### Running commands using the image

```
docker run --rm [-v /absolute/path/to/directory:/mapped/location -v...] [-w /working/directory] <image_name> [command]
```

* `--rm` removes the container after running (recommended, as containers are meant to be single-use)
* `-v` takes an absolute path from the local machine, and places it at the mapped location in the container
* `-w` sets the working directory of the container, where the passed in command is executed

To build gem5 in a container, the following command could be used: (Assuming the image is built as gem5-gcn)

```
docker run --rm -v /path/to/gem5:/gem5 -w /gem5 gem5-gcn scons -sQ -j$(nproc) build/GCN3_X86/gem5.opt
```

### 优化 MI 工作负载的软件堆栈

创建 Docker 镜像使在 gem5 中运行 HIP 应用程序变得容易。然而，运行现代应用程序（如 MI 应用程序）更加复杂，需要额外的更改。在很大程度上，这些问题源于 MI 库使用的功能在设计时没有考虑模拟。

MIOpen 是一个专为在 AMD GPU 上执行而设计的开源 MI 库。MIOpen 具有 HIP 和 OpenCL 后端，并为许多常见的 DNN 算法实现了优化的汇编内核。它在编译时选择使用哪个后端。然后，在运行时，MIOpen 将使用适当的后端在 AMD GPU 上执行给定的 MI 应用程序。虽然这种支持对真实 GPU 很有效，但模拟使用哪个后端、运行哪个 GPU 内核以及它要操作的数据配置既耗时，也不是模拟感兴趣区域的一部分。

例如，MIOpen 调用后端搜索针对给定参数优化的适当内核。在真实硬件上，此过程运行多个不同的内核选项，然后选择最快的一个并使用 clang-ocl 编译它。作为此过程的一部分，MIOpen 在本地缓存内核二进制文件，以供后续使用相同内核。由于在线编译在计算上很密集，并且目前在 gem5 中不受支持，我们通过在真实 GPU 上预先运行应用程序来获取 MIOpen 的缓存内核二进制文件，从而绕过 gem5 中的在线内核编译。或者，如果 AMD GPU 不可用，也可以使用 clang-ocl 在命令行上编译必要的内核。

此外，GEMM 内核在 MI 应用程序中非常常见。对于这些内核，MIOpen 使用 MIOpenGEMM 识别并为输入矩阵的参数创建最佳内核。不幸的是，MIOpenGEMM 通过动态创建可能的 GEMM 内核数据库，然后选择与应用程序矩阵最匹配的内核来实现这一点。由于这是动态发生的，每次程序运行时，都很难绕过此过程。因此，为了避免模拟此过程的开销，我们从较新版本的 ROCm 中反向移植了支持，允许 MIOpen 使用 rocBLAS 而不是 MIOpenGEMM。使用 rocBLAS 而不是 MIOpenGEMM 从模拟的关键路径中移除了重复的动态数据库创建，因为 rocBLAS 在安装时生成最优解决方案的数据库。

总的来说，这些更改避免了模拟不属于应用程序感兴趣区域的工作，并使我们能够在 gem5 中模拟许多原生 MI 应用程序。

### 下一步是什么？

我们的工作提高了 gem5 GPU 模型的可用性，并展示了如何在 gem5 中运行各种 GPU 应用程序，包括原生 MI 应用程序。如上所述，我们目前正在将 Docker 集成到 gem5 的 develop 分支中，以在未来的 GPU 提交上启用持续集成测试。展望未来，我们希望这项工作可以作为在模拟器中运行高级框架（如 Caffe、TensorFlow 和 PyTorch）的跳板。然而，由于高级框架具有大型模型和显著的运行时，为了使模拟这些框架更容易使用，我们计划扩展检查点支持以包括 GPU 模型，使我们能够专注于模拟潜在的感兴趣区域。

# Workshop Presentation

<iframe width="560" height="315"
src="https://www.youtube.com/embed/HhLiMrjqCvA" frameborder="0"
allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
allowfullscreen></iframe>

# 致谢

这项工作部分得到了国家科学基金会资助 ENS-1925485 的支持。
