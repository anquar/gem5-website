---
layout: post
title: "迈向 GPU 应用的全系统模拟"
author: Matthew Poremba
date:   2023-02-13
---

十多年来，gem5 一直支持两种模拟模式：全系统 (FS) 模式，其中模拟器使用磁盘镜像和内核启动 Linux 实例并在磁盘镜像上运行应用程序；系统仿真 (SE) 模式，其中模拟器在主机上运行应用程序并拦截系统调用并为它们提供仿真。
直到几年前，在 SE 模式下运行的二进制文件需要静态链接才能运行。
现在可以运行动态链接的二进制文件，假设动态库在主机上可用。
对于越来越复杂和专业的应用程序，例如 GPU 应用程序，动态库可能在主机系统上不可用，或者可能是与模拟应用程序所需的版本不同的版本。
在这些情况下，首选使用 FS 模式。

不可用或不同版本库的问题也出现在 gem5 中的 GPU 模型中。
GPU 模型目前在 SE 模式下运行，需要旧版本的 [AMD 的 ROCm™ 堆栈](https://www.amd.com/en/graphics/servers-solutions-rocm)。
这有几个问题：(1) 用户可能没有 GPU，因此不需要在本地安装 ROCm™ 堆栈 (2) 用户可能不在与 ROCm™ 安装程序兼容的系统上以安装库或 (3) 用户已安装 ROCm™ 但没有 gem5 所需的特定版本。
这些问题目前通过使用 docker 镜像构建和运行 gem5 来解决。
使用 FS 模式时不需要这样做，使 GPUFS 更容易与常规模拟一起运行。

在过去两年中，一直在进行工作以实现模拟 GPU 设备，其中包含与上游 GPU 驱动程序通信所需的所有组件。
有了这项工作，现在可以使用 FS 模式来模拟 GPU 应用程序。
随着 gem5 的 22.1 发布，我们宣布 GPU FS 模式 (GPUFS) 作为模拟 GPU 应用程序的首选方法，并将最终完全取代 SE 模式。
根据我们最近的测试，几乎所有在 SE 模式下工作的应用程序都将在 FS 模式下工作。
本博客文章的其余部分讨论了 FS 模式的用例以及额外的好处和已知问题。

# 用例
GPUFS 的用例与 SE 模式 GPU 模拟相同。
也就是说，我们模拟单个 GPU 应用程序，收集统计信息，然后退出模拟。
虽然 GPUFS 在理论上提供了进行更高级模拟的能力，例如模拟并发 GPU 应用程序或模拟多个 GPU 设备，但这些在*当前模型*中*不*受支持。


# 全系统的好处
GPUFS 的主要好处是避免动态库问题。
目前 SE 模式 GPU 模拟需要在 docker 镜像内运行。
这本身有许多面向用户的复杂性，例如不允许运行 docker 的环境（例如，大学）以及 GPU 模拟和非 GPU 模拟可能不同的构建目录，以及许多开发人员的复杂性，包括测试和跟上旧过时库的下载位置。

使用模拟 GPU 设备，用户将能够快速转发 GPU 应用程序中的内存复制。
基本的 GPU 应用程序有三个主要的 GPU 相关库调用：(1) 将数据复制到 GPU，(2) 在 GPU 上启动内核，以及 (3) 将数据复制到主机。
在真实系统上，可以使用从主机内存读取并写入设备内存的 GPU 内核或使用 DMA 引擎的帮助来复制数据。
使用 GPUFS，实现了系统 DMA 引擎以在 GPU 内存之间复制数据。
这些引擎可以在 gem5 内功能性地模拟以加速模拟。
因此，用户可以通过避免复制内核的详细模拟，在几分钟的模拟时间内将几 GB 的数据复制到 GPU 内存。

GPUFS 还更容易允许用户和开发人员在每个 gem5 发布时更新 ROCm™ 堆栈到最新版本。
这允许用户能够使用最新 ROCm™ 堆栈的功能，这可能意味着花费更少的时间将应用程序向后移植到较旧的 ROCm™ 版本。
GPUFS 目前已在 ROCm 4.2、4.3、5.0 和 5.4 上测试，但任何高于 4.0 的版本都应该可以工作。
此测试仅在核心 ROCm 包上进行，因此第一方库（rocBLAS、rocFFT、rocSPARSE 等）尚未经过彻底测试。

全系统模式使用完整的 ROCm 堆栈，包括内核驱动程序，而不是使用为 SE 模式开发的仿真驱动程序。
这意味着用户可以修改 Linux 内核驱动程序以研究在 SE 模式下难以完成的领域。
示例包括虚拟内存研究，例如利用灵活的页面大小和探索页面错误处理，为新的 SDMA 和 PM4 处理器实现新的包类型，或使用虚拟化功能。

# 使用全系统
与一般的 FS 模式一样，用户需要磁盘镜像和内核来运行 GPUFS。
在 gem5-resources 仓库的 `src/gpu-fs/disk-image` 下提供了打包脚本。
此外，内核可供下载或可以从磁盘镜像中传输。
此磁盘镜像和内核由与官方 ROCm™ 发布说明兼容的操作系统和内核版本组成。
A prebuilt [GPUFS disk image](http://dist.gem5.org/dist/v22-1/images/x86/ubuntu-18-04/x86-gpu-fs-20220512.img.gz) and [GPUFS kernel](http://dist.gem5.org/dist/v22-1/kernels/x86/static/vmlinux-5.4.0-105-generic) are available for download.

Scripts are provided for the user which can take a GPU application as an argument and copy it into the disk image upon simulation start to run a GPU application without needing to modify or mount the disk image.
The traditional “rcS” script approach can also be used to run applications which exist on the binary already, applications which may need further input files, or applications the user wishes to build from source files in the disk image.
Applications can be built using a docker image provided at gcr.io/gem5-test/gpu-fs:v22-1 or building a local docker image using `util/dockerfiles/gpu-fs/` in the gem5 repository.
Using this docker allows users to build GPU applications without needing to install ROCm™ on their host machine and without wasting simulation time building source files on the disk image.
If desired, users may also install the required ROCm™ version locally, even without an AMD GPU, and build applications on their host machine.

More information on how to setup GPUFS is provided in the README.md file in the gem5-resources repository at `src/gpu-fs/README.md`.

# Known issues
There are some known issues that are actively being addressed which will not be completed until a future release after gem5 22.1.
These issues are below.
If you are using GPUFS and run into an issue that is not listed here, we encourage you to report the issue to gem5-users, JIRA, or the gem5 slack channel.
A useful bug report will include both terminal output and gem5 output preferably with the following debug flags: `--debug-flags=AMDGPUDevice,SDMAEngine,PM4PacketProcessor,HSAPacketProcessor,GPUCommandProc`.

* Currently KVM and X86 are required to run full system.  Atomic and Timing CPUs are not yet compatible with the disconnected Ruby network required for GPUFS and is a work in progress.
* Some memory accesses generate incorrect addresses causing hard page faults leading to simulation panics.  This is currently being investigated with high priority.
* The `printf` function does not work within GPU kernels.  As a workaround, a gem5-specific print function is being developed.

# Recap
Full system GPU simulation (GPUFS) is now the preferred method to run GPU applications in gem5 22.1+.
GPUFS is intended to be used for the same use cases are SE mode GPU simulation.
It has the benefits of avoiding simulation within docker, improved simulation speed by functionally simulating memory copies, and an easier update path for gem5 developers.

As users move to GPUFS, we expect there will be some bug reports.
Users are encouraged to submit reports to the gem5-users mailing list, JIRA, or gem5 slack channel.
