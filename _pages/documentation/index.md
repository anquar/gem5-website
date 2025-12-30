---
layout: documentation
title: gem5 文档
doc: gem5 documentation
parent: gem5_documentation
permalink: /documentation/
author: Jason Lowe-Power
---

# gem5 文档

## gem5 Bootcamp 2024

自 gem5 v24.0 起，学习如何使用 gem5 的最全面、最新的指南是来自 [2024 年夏季 gem5 bootcamp](https://bootcamp.gem5.org/) 的材料。

## Learning gem5

**注意：Learning gem5 的许多部分已经过时。部分章节已基于 2024 gem5 bootcamp 的内容更新至 gem5 v24.1，但其他部分尚未更新。请谨慎使用！**

[Learning gem5](learning_gem5/introduction/) 是由 Jason Lowe-Power 撰写的关于使用 gem5 进行计算机体系结构研究的详细入门指南。
对于计划在研究项目中大量使用 gem5 的初级研究人员来说，这是一个很好的资源。

它详细介绍了 gem5 的工作原理，从[如何创建配置脚本](learning_gem5/part1/simple_config)开始。
然后继续描述[如何修改和扩展](learning_gem5/part2/environment) gem5 以用于您的研究，包括[创建 `SimObject`](learning_gem5/part2/helloobject)、[使用 gem5 的事件驱动模拟基础设施](learning_gem5/part2/events)以及[添加内存系统对象](learning_gem5/part2/memoryobject)。
在 [Learning gem5 第三部分](learning_gem5/part3/MSIintro)中，详细讨论了 [Ruby 缓存一致性模型](/documentation/general_docs/ruby)，包括 MSI 缓存一致性协议的完整实现。

更多 Learning gem5 部分即将推出，包括：
* CPU 模型和指令集架构 (ISA)
* 调试 gem5
* **您的想法！**

注意：这已从 learning.gem5.org 迁移过来，由于迁移存在一些小问题（例如，链接缺失、格式错误）。
如果您发现任何错误，请联系 Jason (jason@lowepower.com) 或创建 PR！

## gem5 101

[gem5 101](learning_gem5/gem5_101) 是一套主要来自威斯康星大学研究生计算机体系结构课程（CS 752、CS 757 和 CS 758）的作业，将帮助您学习使用 gem5 进行研究。

## gem5 API 文档

您可以在此处找到基于 doxygen 的文档：<http://doxygen.gem5.org/release/current/index.html>

## 其他通用 gem5 文档

请查看页面左侧的导航！
