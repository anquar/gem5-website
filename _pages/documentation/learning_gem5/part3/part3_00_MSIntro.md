---
layout: documentation
title: Ruby 简介
doc: Learning gem5
parent: part3
permalink: /documentation/learning_gem5/part3/MSIintro/
author: Jason Lowe-Power
---


## Ruby 简介

Ruby 来自 [multifacet GEMS 项目](http://research.cs.wisc.edu/gems/)。
Ruby 提供了详细的缓存内存和缓存一致性模型以及详细的网络模型 (Garnet)。

Ruby 很灵活。它可以模拟许多不同类型的一致性实现，包括广播、目录、令牌、基于区域的一致性，并且很容易扩展到新的一致性模型。

Ruby 主要是经典内存系统的直接替代品。
经典 gem5 MemObject 和 Ruby 之间有接口，但在很大程度上，经典缓存和 Ruby 不兼容。

在本书的这一部分，我们将首先介绍如何创建一个示例协议，从协议描述到调试和运行协议。

在深入研究协议之前，我们将首先讨论 Ruby 的一些架构。Ruby 中最重要的结构是控制器或状态机。控制器是通过编写 SLICC 状态机文件来实现的。

SLICC 是一种特定于领域的语言（Specification Language including Cache Coherence，包括缓存一致性的规范语言），用于指定一致性协议。SLICC 文件以 ".sm" 结尾，因为它们是 *状态机 (state machine)* 文件。每个文件描述状态、在某些事件上从开始到结束状态的转换以及转换期间采取的操作。

每个一致性协议都由多个 SLICC 状态机文件组成。这些文件使用 SLICC 编译器编译，该编译器用 Python 编写，是 gem5 源代码的一部分。SLICC 编译器获取状态机文件并输出一组 C++ 文件，这些文件与 gem5 的所有其他文件一起编译。这些文件包括 SimObject 声明文件以及 SimObject 和其他 C++ 对象的实现文件。

目前，gem5 一次仅支持编译单个一致性协议。例如，您可以将 MI\_example 编译到 gem5 中（默认、性能较差的协议），或者您可以使用 MESI\_Two\_Level。但是，要使用 MESI\_Two\_Level，您必须重新编译 gem5，以便 SLICC 编译器可以为该协议生成正确的文件。我们在编译部分 \<MSI-building-section\> 进一步讨论了这一点。

现在，让我们深入了解我们的第一个一致性协议的实现！
