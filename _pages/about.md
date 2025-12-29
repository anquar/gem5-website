---
layout: page
title: 关于 gem5
parent: about
permalink: /about/
---


gem5 模拟器是一个用于计算机系统架构研究的模块化平台，涵盖了系统级架构以及处理器微架构。

gem5 是一个开源的计算机架构模拟器，广泛应用于学术界和工业界。
它已经发展了 15 年，最初是密歇根大学的 m5 项目和威斯康星大学的 GEMS 项目。
自 [2011 年 m5 和 GEMS 合并](/publications/#original-paper) 以来，gem5 已被超过 [2900 篇出版物](https://scholar.google.com/scholar?cites=5769943816602695435) 引用。
许多工业界的研究实验室，包括 ARM Research, AMD Research, Google, Micron, Metempsy, HP, Samsung 等，都在使用 gem5。

---

## 特性

#### 多种可互换的 CPU 模型
gem5 提供四种基于解释的 CPU 模型：一个简单的单周期 CPU；一个详细的按序 (in-order) CPU 模型；以及一个详细的乱序 (out-of-order) CPU 模型。
这些 CPU 模型使用通用的高级 ISA 描述。此外，gem5 还具有基于 KVM 的 CPU，利用虚拟化技术加速模拟。

#### 事件驱动的内存系统
gem5 具有详细的、[事件驱动的内存系统](/documentation/general_docs/memory_system)，包括缓存、交叉开关 (Crossbars)、监听过滤器 (Snoop Filters) 和快速准确的 DRAM 控制器模型，用于捕捉当前和新兴内存技术的影响，例如 LPDDR3/4/5, DDR3/4, GDDR5, HBM1/2/3, HMC, WideIO1/2。这些组件可以灵活排列，例如模拟具有异构内存的复杂多级非一致性缓存层次结构。

#### 多 ISA 支持
gem5 将 ISA 语义与其 CPU 模型解耦，从而有效 [支持多种 ISA](/documentation/general_docs/architecture_support)。目前 gem5 支持 Alpha, ARM, SPARC, MIPS, POWER, RISC-V 和 x86 ISA。
但在所有宿主平台上并非都支持所有客户机平台（最明显的是 Alpha 需要小端序硬件）。

#### 同构和异构多核
CPU 模型和缓存可以组合成任意拓扑结构，创建同构和异构的多核系统。MOESI 监听缓存一致性协议保持缓存的一致性。

#### 全系统模拟能力 (Full-system capability)
  - **ARM**: gem5 可以模拟多达 64 个（异构）核心的 Realview ARM 平台，并结合按序和乱序 CPU 启动 [未修改的 Linux](/documentation/general_docs/fullsystem/building_arm_kernel) 和 [Android](/documentation/general_docs/fullsystem/building_android_m)。ARM 实现支持 32 位或 64 位内核及应用程序。
  - **x86**: gem5 模拟器支持标准的 PC 平台并可启动未修改的 Linux。
  - **RISC-V**: 对 RISC-V 特权 ISA 规范的支持正在进行中。
  - **SPARC**: gem5 模拟器以足够的细节模拟 UltraSPARC T1 处理器的单个核心，能够以类似于 Sun T1 架构模拟器工具的方式启动 Solaris（使用特定的定义构建管理程序并使用 HSMID 虚拟磁盘驱动程序）。
  - **Alpha**: gem5 以足够的细节模拟 DEC Tsunami 系统，能够启动未修改的 Linux 2.4/2.6, FreeBSD 或 L4Ka::Pistachio。我们就曾启动过 HP/Compaq 的 Tru64 5.1 操作系统，虽然我们不再积极维护该功能。

#### 仅应用程序支持 (SE 模式)
在仅应用程序（非全系统）模式下，gem5 可以通过 Linux 仿真执行各种架构/操作系统的二进制文件。

#### 多系统能力
可以在单个模拟进程中实例化多个系统。结合全系统建模，此功能允许模拟整个客户端-服务器网络。

#### 功耗和能量建模
gem5 的对象排列在操作系统可见的电源和时钟域中，支持一系列功耗和能效实验。凭借对操作系统控制的动态电压频率调整 (DVFS) 的开箱即用支持，gem5 为未来高能效系统的研究提供了一个完整的平台。
但是，现有的 DVFS 文档已过时。您可以在 [旧 wiki](http://old.gem5.org/Running_gem5.html#Experimenting_with_DVFS) 上找到此页面。

#### 基于 Trace 的 CPU
这是一种回放弹性 Trace 的 CPU 模型，这些 Trace 是由连接到乱序 CPU 模型的探针生成的，包含依赖关系和时序注释。
[Trace CPU 模型](/documentation/general_docs/cpu_models/TraceCPU) 的重点是以快速且相当准确的方式实现内存系统（缓存层次结构、互连和主存）的性能探索，而不是使用详细的 CPU 模型。

#### 与 SystemC 的协同模拟
gem5 可以 [包含在 SystemC 模拟中](http://old.gem5.org/wiki/images/4/4c/2015_ws_09_2015-06-14_Gem5_ISCA.pptx)，作为 SystemC 事件内核中的一个线程有效运行，并保持两个世界之间的事件和时间线同步。
此功能使 gem5 组件能够与广泛的片上系统 (SoC) 组件模型（如互连、设备和加速器）进行互操作。
提供了 SystemC 事务级建模 (TLM) 的封装器。

#### NoMali GPU 模型
gem5 附带一个集成的 [NoMali GPU 模型](http://old.gem5.org/wiki/images/5/53/2015_ws_04_ISCA_2015_NoMali.pdf)，兼容 Linux 和 Android GPU 驱动程序栈，从而消除了软件渲染的需求。
NoMali GPU 不产生任何输出，但确以 CPU 为中心的实验能产生具有代表性的结果。

---
## 许可协议

gem5 模拟器在 Berkeley 风格的开源许可证下发布。
简而言之，您可以自由使用我们的代码，只要保留我们的版权信息即可。有关更多详细信息，请参阅源下载中包含的 LICENSE 文件。请注意，gem5 中源自其他来源的部分也受原始来源的许可限制约束。

---
## 致谢

gem5 模拟器的开发得到了多个来源的慷慨支持，包括国家科学基金会 (NSF)、AMD、ARM、Hewlett-Packard、IBM、Intel、MIPS 和 Sun。致力于 gem5 的个人也得到了 Intel、Lucent 和 Alfred P. Sloan 基金会的奖学金支持。

本材料中表达的任何意见、发现、结论或建议均为作者个人观点，不一定反映国家科学基金会 (NSF) 或任何其他赞助商的观点。
