---
layout: documentation
title: CS 752 作业 5
doc: Learning gem5
parent: gem5_101
permalink: /documentation/learning_gem5/gem5_101/homework-5
authors:
---

# CS 752: 高级计算机体系结构 I 作业 5 (2015 年秋季 1 组)

**截止日期：10/28 星期三**

**您应该独自完成此作业。不接受逾期作业。**

此作业的联系人："Nilay Vaish'" <nilay@cs.wisc.edu>

此作业的目标是双重的。首先，让您体验在 gem5 中创建新的 SimObject，其次让您考虑缓存设计中的权衡。

更新的 cache.py 配置可以在这里下载 <{$urlbase}html/hw5/caches.py>。您可以替换上一个作业中的 cache.py，这里：<{$urlbase}html/hw4-configs.tar.gz>。

## 步骤 1：实现 NMRU 替换策略

您可以按照这里的教程进行操作：<http://pages.cs.wisc.edu/~david/courses/cs752/Spring2015/gem5-tutorial/index.html>
教程的第 2 部分将指导您如何创建 NMRU 策略。

## 步骤 2：实现 PLRU 替换策略

按照实现 NRU 的类似步骤进行操作，但实现伪 LRU (pseudo-LRU)。
伪 LRU 使用二叉树来编码哪些块比集合中的其他块更少使用。Mikko Lipasti 的这些幻灯片很好地解释了 PLRU 算法：<https://ece752.ece.wisc.edu/lect11-cache-replacement.pdf>。

## 步骤 3：架构探索

这一次，Entil 首席执行官已委托您设计基于乱序 O3CPU 的新处理器的 L1 数据缓存。对于这项任务，Entil 的营销总监声称他们的大多数客户的工作负载都在矩阵乘法内核中。由于其内存密集型，Entil 相信更好的缓存设计可以使其处理器的性能优于竞争对手（AMM，Advanced Micro Machines，如果您一直在跟踪）。

分块矩阵乘法实现可以在这里下载：<{$urlbase}html/hw5/mm.cpp>。使用 128x128 矩阵的输入 (./mm 128)。

您可以从三种 L1D 缓存替换策略中进行选择：'Random', 'NMRU', 'PLRU'。随着关联性的增加，NMRU 和 PLRU 的成本上升，而 Random 的成本保持不变。因此，Random 可以使用比其他替换策略更高的关联性。此外，由于 NMRU 和 PLRU 必须更新它们访问的标记中的最近使用位，因此这些策略限制了 CPU 的时钟速率。注意，这代 O3 CPU 的最大时钟为 2.3 GHz。

这些策略的约束总结如下。

|            |Random |NMRU   |PLRU    |
|------------|-------|-------|--------|
|最大关联性  |16     |8      |8       |
|查找时间 |100 ps |500 ps | 666 ps |

在给 Entil 首席执行官的一页备忘录中清楚地描述您模拟的所有配置、模拟结果以及关于如何构建 L1 数据缓存的总体结论。
此外，回答以下具体问题：
* 为什么 16 路组相联缓存的性能比 8 路组相联缓存更好/更差/相似？
* 为什么 Random/NMRU/PLRU/None 比其他替换策略表现更好？
* 缓存替换/关联性对此工作负载重要吗，还是您只从时钟周期中获得好处？解释为什么缓存架构重要/不重要。


## 提交内容

通过发送电子邮件给 Nilay Vaish <nilay@cs.wisc.edu> 和 David Wood 教授 <david@cs.wisc.edu> 提交您的作业，主题行：
"[CS752 Homework5]"

1. 电子邮件应包含提交作业的学生的姓名和 ID 号。以下文件应作为 zip 文件附加到电子邮件中。
2. 一个包含您对 gem5 所做所有更改的补丁文件。
3. 所有模拟的 stats.txt 和 config.ini 文件。
4. 关于所提问题的简短报告。报告应为 PDF 格式。
