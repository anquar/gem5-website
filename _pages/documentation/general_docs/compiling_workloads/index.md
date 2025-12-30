---
layout: documentation
title: "编译工作负载"
doc: gem5 documentation
parent: compiling_workloads
permalink: /documentation/general_docs/compiling_workloads/
author: "Hoa Nguyen"
---

# 编译工作负载

## 交叉编译器

交叉编译器是在一个 ISA 上运行但生成在另一个 ISA 上运行的二进制文件的编译器。
如果您打算模拟使用特定 ISA（例如 Alpha）的系统，但没有实际的 Alpha 硬件，您可能需要一个。

有各种交叉编译器的来源。以下是其中一些。

1. [ARM](https://packages.debian.org/stretch/gcc-arm-linux-gnueabihf)。
2. [RISC-V](https://github.com/riscv/riscv-gnu-toolchain)。

## QEMU

或者，您可以使用 QEMU 和磁盘镜像在仿真中运行所需的 ISA。
要创建更新的磁盘镜像，请参阅[此页面](/documentation/general_docs/fullsystem/disk)。
以下是在 Ubuntu 12.04 64 位上使用 qemu 处理镜像文件的 YouTube 视频。
<iframe width="560" height="315" src="https://www.youtube.com/embed/Oh3NK12fnbg" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
