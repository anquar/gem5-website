---
layout: documentation
title: CS 752 作业 4
doc: Learning gem5
parent: gem5_101
permalink: /documentation/learning_gem5/gem5_101/homework-4
authors:
---

# CS 752: 高级计算机体系结构 I 作业 4 (2015 年秋季 1 组)


**截止日期：10/7 星期一**

**您应该独自完成此作业。不接受逾期作业。**

此作业的联系人：**Nilay Vaish** <nilay@cs.wisc.edu>。


本作业本质上是实验性的，因为我昨天（2015 年 9 月 28 日）才想到这个。它涉及利用指令级并行的两种不同方法：“分支预测”和“推断 (predication)”。

考虑以下代码段：
```cpp
  if (x < y)
     x = y;
```

我们至少有两种方法可以为此生成汇编代码。

1. 使用分支：

```
    compare x, y
    jump if not less L
    move x, y
  L:
```

2. 使用条件移动：

```
  compare x, y
  conditionally move x to y.
```

应该首选哪个版本？我们将在这个作业中尝试对这个问题有一些了解。


1. 这里有一些来自 Linux 操作系统创建者和维护者 Linus Torvalds 关于 cmov 的 [帖子](http://yarchive.net/comp/linux/cmov.html)。
Linus 提供了一小段 C 代码来测量分支和条件移动的性能。在您最喜欢的 x86 处理器上运行代码，并报告两个版本的 `choose()` 函数的计时数字。您应该运行每个版本至少 10 次。报告平均执行时间和运行时间的标准差。
如果您看到运行时间变化太大，请运行更多迭代。这通常应该能稳定性能。


2. 现在使用 gem5 模拟相同的两个版本，使用乱序（默认配置）处理器。将迭代次数降低到 1,000,000，因为 100,000,000 对于 gem5 来说是很多迭代。再次报告哪个选项表现最好。还要报告预测的分支总数和预测错误的分支数。

----

3. SPAA 2015 发表了一篇关于 [避免分支算法](http://dl.acm.org/citation.cfm?id=2755580) 的论文。作者建议避免分支的图算法可能比使用分支的算法性能更好。让我们尝试验证这一说法。

该论文提供了两种版本的计算无向图中连通分量的算法。第一个版本使用分支，第二个版本使用条件移动。我实现了这两个版本，但是有一个小问题。第一个版本可以直接在 C++ 中实现，但是第二个版本需要使用 CMOV 指令。我无法使用内联汇编使该指令工作，但是使用原始汇编可以工作。因此，除了 [C++11 源代码](http://pages.cs.wisc.edu/~david/courses/cs752/Fall2015/html/hw4/connected-components.cpp) 之外，我还为您提供了 GCC 生成的 [汇编代码](http://pages.cs.wisc.edu/~david/courses/cs752/Fall2015/html/hw4/connected-components.s) 和 [静态编译的可执行文件](http://pages.cs.wisc.edu/~david/courses/cs752/Fall2015/html/hw4/connected-components)。注意
您将无法通过编译 C++11 源代码生成完全相同的汇编代码和可执行文件。这是因为我修改了生成的汇编代码以使 cmov 工作。我还提供了三个图 [small](http://pages.cs.wisc.edu/~david/courses/cs752/Fall2015/html/hw4/small.graph)、[medium](http://pages.cs.wisc.edu/~david/courses/cs752/Fall2015/html/hw4/medium.graph) 和 [large](http://pages.cs.wisc.edu/~david/courses/cs752/Fall2015/html/hw4/large.graph.gz)，您将用于实验。阅读 C++ 源代码以了解如何向可执行文件提供选项。

a. 在 x86 处理器上运行这两个版本（带分支和带 cmov），并报告提供的输入文件的运行时间性能。仅对大型图进行此练习。
提供第 1 部分中要求的数据。

b. 使用 gem5 运行这两个版本，报告代码注释部分的两个版本的性能、预测的分支数、预测错误的分支百分比。您只需要对小型和中型图执行此操作，不需要对大型图执行此操作。
再次提供第 2 部分中要求的数据。

## 提交内容
通过发送电子邮件给 Nilay Vaish <nilay@cs.wisc.edu> 和 David Wood 教授 <david@cs.wisc.edu> 提交您的作业，主题行：
"[CS752 Homework4]"

**请以 PDF 文件形式提交您的作业。**

* 第 1 步问题的答案
* 第 2 步问题的答案
* 第 3 步问题的答案
