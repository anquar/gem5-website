---
layout: documentation
title: 统计信息
parent: statistics
doc: gem5 documentation
permalink: /documentation/general_docs/statistics/
---

# 统计信息包
目前统计信息包的理念是拥有一个名为 Stat 的单一基类，它只是统计信息可能重要的其他方面的钩子。因此，此 Stat 基类具有虚拟函数，用于命名、设置精度、设置标志以及初始化所有统计信息的大小。对于所有基于 Vector 的统计信息，在使用统计信息之前进行初始化非常重要，以便可以进行适当的存储分配。对于所有其他统计信息，命名和标志设置也很重要，但对于二进制文件的实际正确执行来说并不那么重要。在代码中设置此功能的方式是有一个 regStats() 过程，在该过程中，所有统计信息都可以在统计信息数据库中注册和初始化。

因此，要添加您自己的统计信息，只需将它们添加到相应类的数据成员列表中，并确保在该类的 regStats 函数中初始化/注册它们。

以下是各种初始化函数的列表。请注意，所有这些都返回 Stat& 引用，从而能够以简洁的方式调用它们。

* init(various args) // 这因不同类型的统计信息而异。
   * Average: 没有 init()
   * Vector: init(size_t) // 表示向量的大小
   * AverageVector: init(size_t) // 表示向量的大小
   * Vector2d: init(size_t x, size_t y) // 行、列
   * Distribution: init(min, max, bkt) // min 指最小值，max 指最大值，bkt 指桶的大小。换句话说，如果您有 min=0、max=15 和 bkt=8，那么 0-7 将进入桶 0，8-15 将进入桶 1。
   * StandardDeviation: 没有 init()
   * AverageDeviation: 没有 init()
   * VectorDistribution: init(size, min, max, bkt) // size 指向量的大小，其余与 Distribution 相同。
   * VectorStandardDeviation: init(size) // size 指向量的大小
   * VectorAverageDeviation: init(size) // size 指向量的大小
   * Formula: 没有 init()
* name(const std::string name) // 统计信息的名称
* desc(const std::string desc) // 统计信息的简要描述
* precision(int p) // p 指小数点后保留多少位。p=0 将强制舍入为整数。
* prereq(const Stat &prereq) // 这表示除非 prereq 具有非零值，否则不应打印此统计信息。（例如，如果有 0 次缓存访问，则不要打印缓存未命中、命中等。）
* subname(int index, const std::string subname) // 这用于基于 Vector 的统计信息，为向量的每个索引提供一个子名称。
* subdesc(int index, const std::string subname) // 也用于基于 Vector 的统计信息，为每个索引提供一个子描述。对于 2d 向量，subname 应用于每一行（x 的）。y 的可以使用 Vector2d 成员函数 ysubname 命名，有关详细信息，请参阅代码。

flags(FormatFlags f) // 这些是您可以传递给统计信息的各种标志，我将在下面描述。

* none -- 无特殊格式
* total -- 这用于基于 Vector 的统计信息，如果设置了此标志，将在末尾打印整个向量的总和（对于支持此功能的统计信息）。
* pdf -- 这将打印统计信息的概率分布
* nozero -- 如果统计信息的值为零，则不会打印它
* nonan -- 如果统计信息不是数字 (nan)，则不会打印它。
* cdf -- 这将打印统计信息的累积分布

下面是如何初始化 VectorDistribution 的示例：

```
    vector_dist.init(4,0,5,2)
        .name("Dummy Vector Dist")
        .desc("there are 4 distributions with buckets 0-1, 2-3, 4-5")
        .flags(nonan | pdf)
        ;
```
# 统计信息类型 #
## Scalar（标量） ##
最基本的统计信息是 Scalar。这体现了基本的计数统计信息。它是一个模板化的统计信息，接受两个参数：类型和 bin。默认类型是 Counter，默认 bin 是 NoBin（即此统计信息上没有分箱）。它的用法很简单：要为其赋值，只需说 foo = 10;，或者要递增它，只需像任何其他类型一样使用 ++ 或 +=。
## Average（平均值） ##
这是一个"特殊用途"的统计信息，旨在计算模拟周期数中某物的平均值。最好通过示例来解释此统计信息。如果您想知道模拟过程中加载-存储队列的平均占用率，您需要每个周期累积 LSQ 中的指令数，最后将其除以周期数。对于此统计信息，可能有许多周期 LSQ 占用率没有变化。因此，您可以使用此统计信息，只需在 LSQ 占用率发生变化时显式更新统计信息。统计信息本身将处理没有变化的周期。此统计信息可以分箱，并且也以与 Stat 相同的方式进行模板化。
## Vector（向量） ##
Vector 就是它听起来的样子，模板参数中类型 T 的向量。它也可以分箱。Vector 最自然的用途是跟踪某些统计信息（例如 SMT 线程数）。大小为 n 的向量可以通过说 Vector<> foo; 来声明，然后稍后将大小初始化为 n。此时，foo 可以像常规向量或数组一样访问，例如 foo[7]++。
## AverageVector（平均值向量） ##
AverageVector 只是 Average 的向量。
## Vector2d（二维向量） ##
Vector2d 是一个二维向量。它可以在 x 和 y 方向上命名，尽管主要名称是在 x 维度上给出的。要在 y 维度上命名，请使用仅 Vector2d 可用的特殊 ysubname 函数。
## Distribution（分布） ##
这本质上是一个向量，但有一些细微差别。在向量中，索引映射到该桶的关注项，而在分布中，您可以将不同的关注范围映射到桶。基本上，如果您将 Distribution 的 init 的 bkt 参数设置为 1，您也可以使用 Vector。
## StandardDeviation（标准差） ##
此统计信息计算模拟周期数的标准差。它与 Average 类似，因为它内置了行为，但需要每个周期更新。
## AverageDeviation（平均偏差） ##
此统计信息也计算标准差，但不需要每个周期更新，就像 Average 一样。它将处理没有变化的周期。
## VectorDistribution（向量分布） ##
这只是分布的向量。
## VectorStandardDeviation（向量标准差） ##
这只是标准差的向量。
## VectorAverageDeviation（向量平均偏差） ##
这只是 AverageDeviation 的向量。
## Histogram（直方图） ##
此统计信息将每个采样值放入可配置数量的桶中的一个桶中。所有桶形成一个连续区间且长度相等。如果存在不适合现有桶之一的采样值，则桶的长度会动态扩展。
## SparseHistogram（稀疏直方图） ##
此统计信息类似于直方图，但它只能采样自然数。SparseHistogram 例如适用于计算对内存地址的访问次数。
## Formula（公式） ##
这是一个 Formula 统计信息。这适用于任何需要在模拟结束时进行计算的内容，例如速率。因此，定义 Formula 的示例将是：

```
    Formula foo = bar + 10 / num;
```

Formula 有一些细微之处。如果 bar 和 num 都是统计信息（包括 Formula 类型），那么没有问题。如果 bar 或 num 是常规变量，则必须使用 constant(bar) 限定它们。这本质上是类型转换。如果您想在定义时使用 bar 或 num 的值，请使用 constant()。如果您想在计算公式时（即结束时）使用 bar 或 num 的值，请将 num 定义为 Scalar。如果 num 是 Vector，请使用 sum(num) 计算其总和以用于公式。将常规变量转换为 Scalar 的操作 "scalar(num)" 不再存在。
