---
layout: documentation
title: 标准库概览
parent: gem5-standard-library
doc: gem5 documentation
permalink: /documentation/gem5-stdlib/overview
author: Bobby R. Bruce
---

## gem5 标准库概览

与编程语言中的标准库类似，gem5 标准库旨在为 gem5 用户提供常用的组件、特性和功能，以提高他们的生产力。
gem5 标准库在 [v21.1](https://github.com/gem5/gem5/tree/v21.1.0.0) 版本中以 alpha 发布状态引入（当时称为 "gem5 components"），并在 [v21.2](https://github.com/gem5/gem5/tree/v21.2.0.0) 版本中正式发布。

对于 gem5 标准库的新用户，以下教程可能有助于理解如何使用 gem5 标准库来改进 gem5 模拟的创建。
这些教程包括构建系统调用仿真和全系统模拟的教程，以及如何扩展库和贡献的指南。
gem5 仓库中的 [`configs/examples/gem5_library`](https://github.com/gem5/gem5/tree/stable/configs/example/gem5_library) 目录也包含使用该库的示例脚本。

以下小节对 gem5 标准库的包及其预期用途进行了广泛概述。

**注意：与标准库相关的文档/教程等已针对 v24.1 版本进行了更新。
请确保在继续之前使用正确版本的 gem5。**

作为 [gem5 2022 训练营](/events/boot-camp-2022) 的一部分，标准库作为教程进行了讲授。
该教程的幻灯片可以在[这里](https://raw.githubusercontent.com/gem5bootcamp/gem5-bootcamp-env/main/assets/slides/using-gem5-02-gem5-stdlib-tutorial.pdf)找到。
该教程的视频录制可以在[这里](https://www.youtube.com/watch?v=vbruiMyIFsA)找到。

标准库也在 [2024 gem5 训练营](https://bootcamp.gem5.org/#02-Using-gem5/01-stdlib) 期间进行了介绍。

<!-- Could use a nice picture here showing the main modules of the stdlib and how they relate -->

## gem5 标准库组件包及其设计理念

gem5 标准库组件包是 gem5 标准库的核心部分。
通过它，用户可以使用标准化 API 从简单组件构建复杂系统，这些组件可以连接在一起。

指导组件包开发的隐喻是使用现成组件构建计算机。
在构建计算机时，某人可以选择组件，将它们插入开发板，并假设开发板和组件之间的接口已经设计成可以"即插即用"的方式。
例如，某人可以从开发板上移除一个处理器并添加另一个兼容相同插槽的处理器，而无需更改设置中的其他所有内容。
虽然这种设计理念总是存在局限性，但组件包具有高度模块化和可扩展的设计，同类型的组件尽可能可以相互替换。

组件包的核心是 _board_（开发板）的概念。
它在真实系统中的作用类似于主板。
虽然它可能包含嵌入式缓存、控制器和其他复杂组件，但它的主要目的是为要添加的其他硬件暴露标准化接口，并处理它们之间的通信。
例如，可以将内存设备和处理器添加到开发板，开发板负责通信，而内存或处理器的设计者无需考虑这一点，假设它们符合已知的 API。

通常，gem5 组件包 _board_ 需要声明这三个组件：

1. _processor_（处理器）：系统处理器。处理器组件包含至少一个 _core_（核心），可以是 Atomic、O3、Timing 或 KVM。
2. _memory_（内存）系统：内存系统，例如 DDR3_1600。
3. _cache hierarchies_（缓存层次结构）：此组件定义处理器和主内存之间的所有组件，最显著的是缓存设置。在最简单的设置中，这将直接将内存连接到处理器。

全系统模拟所需的其他设备（在模拟之间很少改变）由开发板处理。

因此，组件的典型用法可能如下所示：

```python

cache_hierarchy = MESITwoLevelCacheHierarchy(
    l1d_size="16kB",
    l1d_assoc=8,
    l1i_size="16kB",
    l1i_assoc=8,
    l2_size="256kB",
    l2_assoc=16,
    num_l2_banks=1,
)

memory = SingleChannelDDR3_1600(size="3GB")

processor = SimpleProcessor(cpu_type=CPUTypes.TIMING, num_cores=1)

board = X86Board(
    clk_freq="3GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
)
```

以下教程将详细介绍如何使用组件包创建 gem5 模拟。

## gem5 资源包

gem5 标准库的资源包用于获取和整合资源。
在 gem5 的上下文中，资源是模拟中使用的或由模拟使用的东西，但不直接用于构建要模拟的系统。
通常这些是应用程序、内核、磁盘镜像、基准测试程序或测试。

由于这些资源可能难以找到或难以创建，我们作为 [gem5-resources](/documentation/general_docs/gem5_resources) 的一部分提供预构建的资源。
例如，通过 gem5-resources，用户可以下载与 gem5 已知兼容的 Ubuntu 18.04 磁盘镜像。
他们无需自己设置。

gem5 标准库资源包的核心特性是它允许用户为他们的模拟 _自动获取_ 预构建的 gem5 资源。
用户可以在他们的 Python 配置文件中指定需要特定的 gem5 资源，运行时，包将检查主机系统上是否有本地副本，如果没有，则下载它。

教程将更详细地演示如何使用资源包，但现在，典型的模式如下：

```python
from gem5.resources.resource import Resource

resource = Resource("riscv-disk-img")

print(f"The resources is available at {resource.get_local_path()}")
```

这将获取 `riscv-disk-img` 资源并将其存储在本地，以供 gem5 模拟使用。

资源包引用的资源可以在 [gem5 Resources 网站](https://resources.gem5.org) 和 [gem5 Resources 仓库](https://github.com/gem5/gem5-resources) 上查看。强烈建议使用该网站获取有关可用资源以及可以从哪里下载它们的信息。

## Simulate 包

Simulate 包用于运行 gem5 模拟。
虽然此模块代表用户处理一些样板代码，但其主要目的是为我们称为 _Exit Events_（退出事件）的内容提供默认行为和 API。
退出事件是模拟因特定原因而退出的时候。

退出事件的典型示例是 `Workbegin` 退出事件。
这用于指定已到达感兴趣区域 (ROI)。
通常，此退出将用于允许用户开始记录统计信息或切换到更详细的 CPU 模型。
在标准库之前，用户需要精确指定在此类退出事件处的预期行为。
模拟将退出，配置脚本将包含指定下一步要做什么的 Python 代码。
现在，使用 Simulate 包，此类事件有默认行为（统计信息被重置），并且有一个简单的接口可以用用户需要的内容覆盖此行为。

有关退出事件的更多信息可以在 [M5ops 文档](https://www.gem5.org/documentation/general_docs/m5ops/) 中找到。