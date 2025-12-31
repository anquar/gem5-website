---
layout: post
title:  "Ruby 内存系统的灵活缓存一致性协议"
author: Tiago Mück
date:   2020-05-29
---

gem5 的 Ruby 内存子系统提供了灵活的片上网络模型和详细建模的多种缓存一致性协议。然而，简单的实验有时很难完成。例如，仅通过添加另一个共享缓存级别来修改现有配置需要：

1. 切换到完全新的协议来建模所需的缓存层次结构；
2. 或修改现有协议；

虽然 (1) 并不总是可行，但 (2) 是一项非平凡的任务，因为 Ruby 协议可能非常复杂且难以调试。这在 gem5 "经典"内存子系统和 Ruby 之间造成了主要的灵活性差距。

# 新协议实现

我们正在开发一个新的协议实现，旨在解决这种可配置性限制。我们的新协议提供了一个单一的缓存控制器，可以在缓存层次结构的多个级别重用，并配置为建模 MESI 和 MOESI 缓存一致性协议的多个实例。此实现基于 [Arm 的 AMBA 5 CHI 规范](https://static.docs.arm.com/ihi0050/d/IHI0050D_amba_5_chi_architecture_spec.pdf)，并为大型 SoC 设计的设计空间探索提供了可扩展的框架。

# 演示

要了解更多信息，请查看我们的研讨会演示：

<iframe width="960" height="540" src="https://www.youtube.com/embed/OOEqCZekJbA" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen style="max-width: 960px;"></iframe>
