---
layout: documentation
title: "架构支持"
doc: gem5 documentation
parent: architecture_support
permalink: /documentation/general_docs/architecture_support/
---

# 架构支持

{: .outdated-notice}
本页面的信息和超链接可能不准确。

## Alpha

Gem5 模拟基于 DEC Tsunami 的系统。
除了支持 4 个核心的普通 Tsunami 系统外，我们还有一个扩展支持 64 个核心（需要自定义 PALcode 和修补的 Linux 内核）。
模拟系统看起来像一个 Alpha 21264，包括 BWX、MVI、FIX 和 CIX 到用户级代码。
由于历史原因，处理器执行基于 EV5 的 PALcode。

它可以启动未修改的 Linux 2.4/2.6、FreeBSD 或 L4Ka::Pistachio 以及系统调用仿真模式下的应用程序。
多年前，可以启动 HP/Compaq 的 Tru64 5.1 操作系统。
但是，我们不再积极维护该功能，并且目前无法工作。

## ARM

gem5 中的 ARM 架构模型支持 ARM® 架构的 [ARMv8-A](https://developer.arm.com/docs/den0024/latest/armv8-a-architecture-and-processors/armv8-a) 配置文件以及多处理器扩展。
这包括 AArch32 和 AArch64 状态。
在 AArch32 中，这包括对 [Thumb®](https://www.embedded.com/introduction-to-arm-thumb/)、Thumb-2、VFPv3（32 双寄存器变体）和 [NEON™](https://developer.arm.com/architectures/instruction-sets/simd-isas/neon) 以及大物理地址扩展 (LPAE) 的支持。
当前不支持的架构可选功能是 [TrustZone®](https://developer.arm.com/ip-products/security-ip/trustzone)、ThumbEE、[Jazelle®](https://en.wikipedia.org/wiki/Jazelle) 和 [虚拟化](https://developer.arm.com/docs/100942/0100/aarch64-virtualization)。

在全系统模式下，gem5 能够启动使用 ARM 编译器构建的单处理器或多处理器 Linux 和裸机应用程序。
较新的 Linux 版本开箱即用（如果与 gem5 的 DTB 一起使用），我们也提供具有自定义配置和自定义驱动程序的 gem5 特定 Linux 内核。此外，静态链接的 Linux 二进制文件可以在 ARM 的系统调用仿真模式下运行。

## POWER

gem5 对 POWER ISA 的支持目前仅限于系统调用仿真，并且基于 [POWER ISA v3.0B](https://ftp.libre-soc.org/PowerISA_public.v3.0B.pdf)。
模拟了一个大端 32 位处理器。
大多数常用指令均可用（足以运行所有 SPEC CPU2000 整数基准测试）。
浮点指令可用，但支持可能不完整。
特别是，浮点状态和控制寄存器 (FPSCR) 通常根本不更新。
不支持向量指令。

对 POWER 的全系统支持需要大量工作，目前尚未开发。
但是，如果有兴趣进行此操作，可以从 [Tim](mailto:timothy.jones@cl.cam.ac.uk) 那里获得一组正在进行的补丁。

## SPARC

gem5 模拟器模拟 UltraSPARC T1 处理器（UltraSPARC Architecture 2005）的单个核心。

它可以像 Sun T1 架构模拟器工具一样启动 Solaris（使用特定定义构建管理程序并使用 HSMID 虚拟磁盘驱动程序）。
全系统 SPARC 的多处理器支持从未完成。
通过系统调用仿真，gem5 支持运行 Linux 或 Solaris 二进制文件。
新版本的 Solaris 不再支持生成 gem5 所需的静态编译二进制文件。

## x86

gem5 模拟器中的 X86 支持包括具有 64 位扩展的通用 x86 CPU，更类似于 AMD 的架构版本而不是 Intel 的，但不完全像任何一个。
未修改的 Linux 内核版本可以在 UP 和 SMP 配置中启动，并且可以使用补丁来加速启动。
实现了 SSE 和 3dnow，但大多数 x87 浮点未实现。
大多数工作都集中在 64 位模式上，但也提供了一些对兼容模式和传统模式的支持。
实模式足以引导 AP，但尚未经过广泛测试。
Linux 和标准 Linux 二进制文件所使用的架构功能已实现并且应该可以工作，但其他领域可能不行。
系统调用仿真模式支持 64 位和 32 位 Linux 二进制文件。

## MIPS


## RISC-V
