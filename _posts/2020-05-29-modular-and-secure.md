---
layout: post
title:  "面向物联网的模块化和安全系统架构"
author: Nils Asmussen, Hermann Härtig, and Gerhard Fettweis
date:   2020-05-29
---

引言
------------

"物联网 (IoT)" 已经在工业生产中普及，预计也将在许多其他领域变得无处不在。例如，此类连接设备在更好地自动化和优化关键基础设施（如电网和交通网络）方面具有巨大潜力，并且在医疗保健应用中也很有前景。然而，为所有这些设备的计算硬件和系统软件提供一刀切的解决方案是不可行的，主要是由于成本压力和能源限制，但也因为每个领域需要不同的计算能力、传感器和执行器。相反，硬件和驱动它的软件都需要定制解决方案。系统设计人员应该能够从可重用的构建块中轻松组装这些专用计算机及其操作系统 (OS)，这需要在硬件和 OS 级别都具有模块化。

除了模块化之外，由于 IoT 设备与物理世界的交互以及它们与互联网的连接，安全性至关重要，这使得攻击者能够对环境或人类造成伤害。因此，使用加密通信是不够的，IoT 设备本身也需要得到保护。在软件层面，单体 OS 中子系统之间的高复杂性和缺乏隔离使它们不适合这种安全关键用例。相反，基于微内核的系统（如 L4 [1]）由于其模块化架构和子系统之间的强隔离而成为有前景的候选者。事实上，已经表明，基于微内核的系统可以通过将影响限制在单个子系统内，至少降低 96% 的 Linux 关键 CVE 的严重性，并且可以完全消除 40% 的 CVE [2]。

我们认为，基于微内核的系统将系统拆分为多个隔离组件的想法可以也应该应用于硬件。例如，片上系统设计人员经常从第三方供应商购买硬件组件（IP 块）。然而，调制解调器或加速器等 IP 块可能很复杂，因此不应被信任。此外，最近发现的针对现代通用核心的侧信道攻击，如 Meltdown [3]、Spectre [4] 和 ZombieLoad [5]，提出了我们是否仍应信任这些复杂核心来正确执行不同软件组件之间的隔离边界的问题。因此，我们相信硬件组件（如调制解调器、加速器和核心）应该像基于微内核系统中的软件组件一样被强烈分离。

系统架构
-------------------
<p align="center">
  <img src="{{site.url}}/assets/img/blog/modular-and-secure/modular-and-secure-fig-1.png"/>
</p>



我们的系统架构 [6]，如图 1a 所示，建立在瓦片架构之上，该架构已经允许以模块化方式将硬件组件集成到单独的瓦片中。然而，尽管瓦片在物理上是分离的，但它们通常仍然对连接瓦片的片上网络 (NoC) 具有无限制的访问。我们建议在每个瓦片和 NoC 之间添加一个新的简单硬件组件，以限制瓦片对 NoC 的访问。此硬件组件称为可信通信单元 (TCU)。除了将瓦片彼此隔离之外，TCU 还允许建立和使用瓦片之间的通信通道。

称为 M³ 的操作系统（如图 1b 所示）被设计为基于微内核的系统，并利用 TCU 来隔离硬件和软件组件，同时有选择地允许它们进行通信。M³ 的内核专门在专用的*内核瓦片*上运行，而服务和应用程序在*用户瓦片*上运行。内核作为系统中唯一的特权组件，是唯一可以在瓦片之间建立通信通道的组件。用户瓦片随后可以使用已建立的通道直接与其他用户瓦片通信，而无需涉及内核。但是，用户瓦片无法更改或添加新通道。由于瓦片之间的物理分离，M³ 对瓦片没有特定要求，例如用户/内核模式或内存管理单元。因此，不仅计算核心，而且任意硬件组件（如调制解调器、加速器或设备）都可以作为用户瓦片集成，内核可以以统一的方式控制它们的通信权限。

使用 gem5 进行模拟
--------------------

除了基于 FPGA 的实现工作外，我们还在 gem5 中构建系统架构原型以评估其可行性。为了模拟系统架构，我们将每个瓦片表示为 `System` 对象，并使用 `NoncoherentXBar` 连接瓦片。`System` 对象为 M³ 实现了自定义加载器，以将内核和其他组件加载到各个瓦片上。在我们的模拟中，我们使用 x86、ARMv7 和 RISC-V。但是，我们的硬件实现将使用 RISC-V 核心，因为它们简单且开放。由于 gem5 仅支持 RISC-V 的系统仿真，我们为 gem5 贡献了 RISC-V 的全系统支持，这使我们能够运行我们的 OS 并利用虚拟内存。

结论
----------

与物理世界和互联网接口的 IoT 设备需要安全性和模块化。我们正在研究一种新的系统架构，该架构采用基于微内核系统的软件思想，并将其应用于硬件。关键思想是建立在瓦片架构之上，并为每个瓦片添加一个称为可信通信单元的新简单硬件组件，用于隔离和通信。称为 M³ 的基于微内核的 OS 建立在此硬件平台之上，并在原本隔离的瓦片之间建立通信通道。我们相信，硬件和软件级别的模块化以及组件之间的强隔离使我们能够为未来的 IoT 设备提供合适的基础。

Bibliography
------------

[1] Hermann Hartig, Michael Hohmuth, Norman Feske, Christian Helmuth, Adam Lackorzynski, Frank Mehnert, and Michael Peter. The nizza secure-system architecture. In 2005 International Conference on Collaborative Computing: Networking, Applications and Worksharing, pages 10–pp. IEEE, 2005.

[2] Simon Biggs, Damon Lee, and Gernot Heiser. The Jury Is In: Monolithic OS Design Is Flawed: Microkernel-based Designs Improve Security. Proceedings of the 9th Asia-Pacific Workshop on Systems. 2018.

[3] Moritz Lipp, Michael Schwarz, Daniel Gruss, Thomas Prescher, Werner Haas, Stefan Mangard, Paul Kocher, Daniel Genkin, Yuval Yarom, and Mike Hamburg. Meltdown. CoRR, abs/1801.01207, 2018.

[4] Paul Kocher, Daniel Genkin, Daniel Gruss, Werner Haas, Mike Hamburg, Moritz Lipp, Stefan Mangard, Thomas Prescher, Michael Schwarz, and Yuval Yarom. Spectre attacks: Exploiting speculative execution. CoRR, abs/1801.01203, 2018.

[5] Schwarz, Michael, Moritz Lipp, Daniel Moghimi, Jo Van Bulck, Julian Stecklina, Thomas Prescher, and Daniel Gruss. ZombieLoad: Cross-privilege-boundary data sampling. In Proceedings of the 2019 ACM SIGSAC Conference on Computer and Communications Security, pp. 753-768. 2019.

[6] Nils Asmussen, Marcus Völp, Benedikt Nöthen, Hermann Härtig, and Gerhard Fettweis. M³: A hardware/operating-system co-design to tame heterogeneous manycores. In Proceedings of the wenty-First International Conference on Architectural Support for Programming Languages and Operating Systems, ASPLOS'16, pages 189–203. ACM, 2016.

研讨会演示
---------------------

<iframe width="960" height="540"
src="https://www.youtube.com/embed/2jPiXOhboko" frameborder="0"
allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
allowfullscreen style="max-width: 960px;"></iframe>
