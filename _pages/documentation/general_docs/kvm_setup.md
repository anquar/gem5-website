---
layout: page
title: 在您的机器上设置和使用 KVM
permalink: /documentation/general_docs/using_kvm/
author: Mahyar Samani and Bobby R. Bruce
---

基于内核的虚拟机 (KVM) 是一个 Linux 内核模块，允许创建由内核管理的虚拟机。
在最新的 x86 和 ARM 处理器上，KVM 支持硬件辅助虚拟化，使虚拟机能够以接近原生速度运行。
gem5 的 `KVMCPU` 在 gem5 中启用了此功能，但代价是架构统计信息不会被 gem5 记录。
使用 `KVMCPU` 时，可以通过 `perf` 可选地收集一些统计信息，但此选项需要 `root` 权限。

为了使用 gem5 的 `KVMCPU` 来快进您的模拟，您必须拥有兼容 KVM 的处理器并在您的机器上安装 KVM。
本页将指导您在机器上启用 KVM 并在 gem5 中使用它。

注意：以下教程假设使用 X86 Linux 主机。
本教程的各个部分可能不适用于其他架构或不同的操作系统。
目前 KVM 支持可用于 X86 和 ARM 模拟（分别使用 X86 和 ARM 主机）。

## 确保系统兼容性

要查看您的处理器是否支持硬件虚拟化，请运行以下命令：

```console
grep -E -c '(vmx|svm)' /proc/cpuinfo
```

如果命令返回 0，您的处理器不支持硬件虚拟化。
如果命令返回 1 或更多，您的处理器确实支持硬件虚拟化

您可能仍需要确保在 BIOS 中启用了它。
执行此操作的过程因制造商和型号而异。
请查阅您的主板手册以获取更多信息。

最后，建议您在主机上使用 64 位内核。
在主机上使用 32 位内核的限制如下：

* 您只能为虚拟机分配 2GB 内存
* 您只能创建 32 位虚拟机。

这可能会严重限制 KVM 在 gem5 模拟中的有用性。

## 启用 KVM

为了让 KVM 直接与 gem5 一起工作，必须安装以下依赖项：

```console
sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
```

接下来，您需要将用户添加到 `kvm` 和 `libvirt` 组。
运行以下两个命令：

```console
sudo adduser `id -un` libvirt
sudo adduser `id -un` kvm
```

之后，您需要退出然后重新连接到您的帐户。
如果您使用 SSH，请断开所有会话并重新登录。
现在，如果您运行下面的 `groups` 命令，您应该看到 `kvm` 和 `libvirt`。

## 验证 KVM 是否工作

"configs/example/gem5_library/x86-ubuntu-run-with-kvm.py" 文件是一个 gem5 配置，它将创建一个使用 KVM 启动 Ubuntu 24.04 镜像的模拟。
可以使用以下命令执行：

```console
scons build/ALL/gem5.opt -j`nproc`
./build/ALL/gem5.opt configs/example/gem5_library/x86-ubuntu-run-with-kvm.py
```

如果您使用预构建的 gem5 二进制文件，请使用以下命令：

```console
gem5 configs/example/gem5_library/x86-ubuntu-run-with-kvm.py

```

如果模拟成功运行，您已成功安装 KVM 并可以在 gem5 中使用它。

## `KVMCPU`、快进和 `perf`

`perf` 是 Linux 中的一项功能，允许用户访问性能计数器。
默认情况下，`KVMCPU` 启用 `perf` 以收集统计信息，例如执行的指令数。
通常，`perf` 需要一些系统权限来设置。
否则，您会遇到相关的权限问题，例如 `kernel.perf_event_paranoid` 值太高。

但是，如果您想快进模拟并且不打算收集快进阶段的统计信息，您可以在使用 `KVMCPU` 时选择不使用 `perf`。
`KVMCPU` SimObject 有一个名为 `usePerf` 的参数，它指定 `KVMCPU` 是否应该使用 `perf` 收集统计信息。
此选项默认启用。

以下是关闭 `perf` 的示例，
[https://github.com/gem5/gem5/blob/stable/configs/example/gem5\_library/x86-ubuntu-run-with-kvm-no-perf.py](https://github.com/gem5/gem5/blob/stable/configs/example/gem5_library/x86-ubuntu-run-with-kvm-no-perf.py)。
