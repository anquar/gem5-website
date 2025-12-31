---
layout: post
title:  "gem5-19 上的 X86 Linux 启动状态"
author: Ayaz Akram
date:   2020-03-09
categories: project
---

![gem5-linux-logo](/assets/img/blog/gem5-linux.png)

推送到 gem5 的更改频率随时间增加。
这使得及时了解 gem5 的哪些功能正常工作、哪些不正常变得非常重要。
考虑到 gem5 是一个全系统模拟器，应该能够模拟现代操作系统，Linux 内核的启动是确定 gem5 工作状态的一个非常重要的基准。
然而，gem5 对最新 Linux 内核版本的支持状态很难发现，而且 gem5 网站上以前可用的 Linux 内核或配置文件相当旧。
[gem5-19](https://www.gem5.org/project/2020/02/25/gem5-19.html) 最近也已发布。

因此，我们运行了测试以发现 gem5-19 在启动最新 Linux 内核版本方面的能力。
在这篇文章中，我们将讨论这些测试的结果。

## 配置空间

在 gem5 上模拟 Linux 启动时，可能的配置空间很大。
为了测试 gem5-19，我们评估了多种配置，考虑了五个 Linux 内核、四个 CPU 模型、两个内存系统、两种 Linux 启动类型和四个 CPU 核心数量。

我们使用 X86 ISA 进行了这些测试。
我们的方法应该可以轻松扩展到其他 ISA，但我们还没有运行这些测试。
我们欢迎其他贡献者运行这些测试！

以下是这些配置的详细信息：

### Linux 内核

我们使用下面显示的五个最新 LTS（长期支持）内核评估了 gem5。
我们计划继续测试 LTS 内核版本以及每个 gem5 发布版本的最新内核。

- v4.4.186（发布于 2016-01-10）
- v4.9.186（发布于 2016-12-11）
- v4.14.134（发布于 2017-11-12）
- v4.19.83（发布于 2018-10-22）
- v5.4（发布于 2019-11-24）

### CPU 模型

我们使用了 gem5 支持的四种 CPU 模型：

- **kvmCPU：** 不进行任何时序模拟的 CPU，而是使用实际硬件运行模拟代码。它主要用于快速转发。
- **AtomicSimpleCPU：** 该 CPU 也不进行任何时序模拟，并使用原子内存访问。它主要用于快速转发和缓存预热。
- **TimingSimpleCPU：** 这是一个单周期 CPU 模型，除了内存操作（它使用时序内存访问）。
- **O3CPU：** 这是一个详细且高度可配置的乱序 CPU 模型（它对 CPU 和内存都进行时序模拟）。

### 内存系统

gem5 支持两种主要内存系统（在这些测试中使用）：

- **Classic：** 经典内存系统速度快且易于配置，支持原子访问，但缺乏缓存一致性保真度和灵活性（它建模了一个简化的 coherence 协议）。
- **Ruby：** Ruby 内存系统使用详细的缓存一致性协议对详细缓存进行建模。但是，它不支持原子访问，并且与经典内存系统相比速度较慢。

### 启动类型

启动类型是指内核加载后将接管的过程类型。
我们使用两种不同的选项：

- **init：** 使用 m5 exit 指令退出系统的自定义 init 脚本。
- **systemd：** Systemd 是默认的 init 系统，通过初始化不同的服务和管理用户进程使系统准备就绪。

## gem5art

我们使用 [gem5art](https://gem5art.readthedocs.io/en/latest/index.html)（用于**组件**、**可重现性**和**测试**的库）来执行这些实验。
gem5art 帮助我们以更加结构化和可重现的方式进行 gem5 实验。
但是，我们将把关于 gem5art 的详细讨论推迟到未来的博客文章。
用于运行这些实验的 gem5 配置脚本可在 [gem5art 仓库](https://github.com/darchr/gem5art/tree/master/docs/gem5-configs/configs-boot-tests/)中找到，有关如何使用 gem5art 运行这些实验的详细信息可以在 [gem5art 启动教程](https://gem5art.readthedocs.io/en/latest/tutorials/boot-tutorial.html)中找到。
我们使用的磁盘镜像和 Linux 内核二进制文件可从以下链接获得（**警告：**这些文件的大小从几 MB 到 2GB 不等）：

- [磁盘镜像（GZIPPED）](http://dist.gem5.org/dist/current/images/x86/ubuntu-18-04/base.img.gz)（**注意：**此磁盘镜像中的 /root/.bashrc 包含 `m5 exit`，这将使客户机在启动后立即终止模拟）
- [vmlinux-4.4.186](http://dist.gem5.org/dist/current/kernels/x86/static/vmlinux-4.4.189)
- [vmlinux-4.9.186](http://dist.gem5.org/dist/current/kernels/x86/static/vmlinux-4.9.186)
- [vmlinux-4.14.134](http://dist.gem5.org/dist/current/kernels/x86/static/vmlinux-4.14.134)
- [vmlinux-4.19.83](http://dist.gem5.org/dist/current/kernels/x86/static/vmlinux-4.19.83)
- [vmlinux-5.4.49](http://dist.gem5.org/dist/current/kernels/x86/static/vmlinux-5.4.49)

## Linux 启动状态

图 1 和图 2 分别显示了使用经典内存系统进行 init 和 systemd 启动类型的实验结果。
图 3 和图 4 分别显示了使用 Ruby 内存系统进行 init 和 systemd 启动类型的实验结果。
所有可能的状态输出（如下面的图所示）定义如下：

- **timeout：** 实验在合理的时间内未完成（8 小时：选择此时间是因为我们发现类似的成功案例在同一主机上未超过此限制）。
- **not-supported：** gem5 中尚未支持的案例。
- **success：** Linux 成功启动的案例。
- **sim-crash：** gem5 崩溃的案例。
- **kernel-panic：** 内核在模拟期间进入 panic 的案例。

使用经典内存系统时，KVM 和 Atomic CPU 模型总是有效。
TimingSimple CPU 在单核时总是有效，但在多 CPU 核心时无法启动内核。
O3 CPU 模型在大多数情况下无法模拟内核启动（唯一的成功是使用两个 Linux 内核版本的 init 启动类型）。

![Linux boot status for classic memory system and init boot](/assets/img/blog/boot_classic_init.png)
<br>
*图 1：经典内存系统和 init 启动的 Linux 启动状态*


![Linux boot status for classic memory system and systemd boot](/assets/img/blog/boot_classic_systemd.png)
<br>
*图 2：经典内存系统和 systemd 启动的 Linux 启动状态*

如图 3 和图 4 所示，对于 Ruby 内存系统，KVM 和 Atomic CPU 模型似乎有效，除了少数情况下即使 KVM CPU 模型也会超时。
TimingSimple CPU 最多可工作 2 个核心，但在 4 和 8 个核心时失败。
O3 CPU 模型在所有情况下都无法模拟 Linux 启动或超时。

![Linux boot status for ruby memory system and init boot](/assets/img/blog/boot_ruby_init.png)
<br>
*图 3：Ruby 内存系统和 init 启动的 Linux 启动状态*

![Linux boot status for ruby memory system and systemd boot](/assets/img/blog/boot_ruby_systemd.png)
<br>
*图 4：Ruby 内存系统和 systemd 启动的 Linux 启动状态*

这些实验的原始数据/结果可从[此链接](http://dist.gem5.org/boot-test-results/boot_tests.zip)获得（警告：文件大小约 40MB）。

## 前进方向

研究人员大多在 Linux 启动期间快速转发模拟以避免上述问题，或者最终使用较旧的内核版本。
这导致模拟结果和从这些实验中得出的结论存在不确定性。
作为社区，我们不应忽视这些问题，并尝试使 gem5 能够成功运行这些启动测试。
有几个 JIRA 问题
([GEM5-359](https://gem5.atlassian.net/projects/GEM5/issues/GEM5-359), [GEM5-360](https://gem5.atlassian.net/projects/GEM5/issues/GEM5-360))
开放以记录这些问题，希望最终能够修复它们。
与使用 Ruby 内存系统的 TimingSimple CPU 相关的 gem5 [问题](https://gem5.googlesource.com/public/gem5/+/de24aafc161f348f678e0e0fc30b1ff2d145043b)已在 develop 分支上修复，并将成为 gem5-20 的一部分。

此外，我们需要为 gem5 的新版本重复这些测试，并在新的 Linux 内核可用时进行测试。
我们希望通过 gem5 网站上的新页面尽快让 gem5 社区了解这些测试的结果。
