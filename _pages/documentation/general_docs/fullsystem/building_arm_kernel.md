---
layout: documentation
title: "构建 ARM 内核"
doc: gem5 documentation
parent: fullsystem
permalink: /documentation/general_docs/fullsystem/building_arm_kernel
---

# 构建 ARM 内核

本页包含为在 ARM 上运行的 gem5 构建最新内核的说明。

如果您不想自己构建内核（或磁盘镜像），您仍然可以[下载
预构建版本](./guest_binaries)。

## 先决条件
这些说明适用于运行无头系统。这是一个更"服务器"风格的系统，没有帧缓冲区。描述是使用下面链接的仓库中最新已知工作标签创建的，但每个部分中的表格列出了已知可用的先前标签。要在 x86 主机上构建内核，您需要 ARM 交叉编译器和设备树编译器。如果您运行的是相当新版本的 Ubuntu 或 Debian，可以通过 apt 获取所需的软件：

```
apt-get install  gcc-arm-linux-gnueabihf gcc-aarch64-linux-gnu device-tree-compiler
```

如果您不能使用这些预制的编译器，从 ARM 获取
所需编译器的下一个最简单方法是：
- [Cortex A 交叉编译器](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads)
- [Cortex RM 交叉编译器](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads)

下载（其中一个）并确保二进制文件在您的 `PATH` 上。

根据您的交叉编译器的确切来源，下面使用的编译器名称将需要小的更改。

要实际运行内核，您需要下载或编译 gem5 的
引导加载程序。有关详细信息，请参阅本文档中的[引导加载程序](#bootloaders)部分。

## Linux 4.x
较新的 gem5 ARM 内核（v4.x 及更高版本）基于原始 Linux 内核，通常有少量补丁以使它们更好地与 gem5 配合工作。补丁是可选的，您也应该能够使用原始内核。但是，这需要您自己配置内核。较新的内核都使用 VExpress\_GEM5\_V1 gem5 平台，适用于 AArch32 和 AArch64。

# 内核检出
要检出内核，请执行以下命令：

```
git clone https://gem5.googlesource.com/arm/linux
```

该仓库包含每个 gem5 内核发布的标签和主要 Linux 修订版的工作分支。查看[项目页面](https://gem5-review.googlesource.com/#/admin/projects/arm/linux)以获取标签和分支列表。克隆命令默认将检出最新的发布分支。要检出 v4.14 分支，请在仓库中执行以下操作：
```
git checkout -b gem5/v4.14
```

# 内核构建
要编译内核，请在仓库中执行以下命令：

```
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- gem5_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j `nproc`
```

测试刚刚构建的内核：

```
./build/ARM/gem5.opt configs/example/arm/starter_fs.py --kernel=/tmp/linux-arm-gem5/vmlinux \
    --disk-image=ubuntu-18.04-arm64-docker.img
```

# 引导加载程序
gem5 有两个不同的引导加载程序。一个用于 32 位内核，一个用于 64 位内核。可以使用以下命令编译它们：

```
make -C system/arm/bootloader/arm
make -C system/arm/bootloader/arm64
```

# 设备树 Blob
描述硬件给操作系统的所需 DTB 文件随 gem5 一起提供。要构建它们，请执行此命令：

```
make -C system/arm/dt
```

我们建议仅在您计划修改它们时使用这些设备树文件。如果不是，我们建议您依赖 DTB 自动生成：通过运行不带 --dtb 选项的 FS 脚本，gem5 将根据实例化的平台自动生成 DTB。

编译二进制文件后，将它们放在您的
`M5_PATH` 中的 binaries 目录中。
