---
layout: documentation
title: 统计信息 API
parent: statistics
doc: gem5 documentation
permalink: /documentation/general_docs/statistics/api
---

# 统计信息 API

## 目录
1. [通用统计信息函数](#general-statistics-functions)
2. [Stats::Group - 统计信息容器](#stats_group-statistics-container)
3. [统计信息标志](#stats-flags)
4. [统计信息类](#statistics-classes)
5. [附录：迁移到新的统计信息跟踪样式](#appendix_migrating-to-the-new-style-of-tracking-statistics)

---

## 通用统计信息函数

| 函数签名                                 | 描述                                                           |
|-----------------------------------------------------|------------------------------------------------------------------------|
|`void Stats::dump()`                                 | 将所有统计信息转储到注册的输出，例如 stats.txt。                  |
|`void Stats::reset()`                                | 重置统计信息。                                                           |

---

## Stats::Group - 统计信息容器
通常，统计信息对象可以作为类变量放置在任何 `SimObject` 中。
但是，[最近的更新](https://gem5-review.googlesource.com/c/public/gem5/+/19368)
解决了 gem5 中 `SimObject` 的层次结构性质，
这反过来使对象的统计信息具有层次结构。
该更新引入了 `Stats::Group` 类，它是一个统计信息容器
并且了解 `SimObject` 的层次结构。
理想情况下，此容器应包含 `SimObject` 中的所有统计信息。

**注意**：如果您决定在 `SimObject` 内使用 `Stats::Group` 结构体，
通常有两种方法：
- 使用 `Stats::Group(Stats::Group &parent, const std::string &name)` 构造函数创建子组。当需要同一统计信息结构的多个实例时，这很有用。
- 使用 `Stats::Group(Stats::Group &parent)` 构造函数，它将当前组的统计信息合并（即添加）到父组。因此，添加到当前组的统计信息的行为就像它们被直接添加到父组一样。

### Stats::Group 宏
##### `#define ADD_STAT(n, ...) n(this, # n, __VA_ARGS__)`
用于向统计信息组添加统计信息的便捷宏。

此宏用于在 Group 构造函数的初始化列表中将统计信息添加到 Stats::Group。该宏
自动将统计信息分配给当前组并为其提供
与类中相同的名称。例如：
```
struct MyStats : public Stats::Group
{
    Stats::Scalar scalar0;
    Stats::Scalar scalar1;

    MyStats(Stats::Group *parent)
        : Stats::Group(parent),
          ADD_STAT(scalar0, "Description of scalar0"),       // 等价于 scalar0(this, "scalar0", "Description of scalar0")，其中 scalar0 具有以下构造函数
                                                             // Stats::Scalar(Group *parent = nullptr, const char *name = nullptr, const char *desc = nullptr)
          scalar1(this, "scalar1", "Description of scalar1")
     {
     }
};
```


### Stats::Group 函数
##### `Group(Group *parent, const char *name = nullptr)`
构造一个新的统计信息组。

构造函数接受两个参数：父组和名称。
通常应指定父组。但是，有一些
特殊情况，父组可能为 null。一个这样的
特殊情况是 SimObjects，其中 Python 代码执行
组父级的后期绑定。

如果 name 参数为 NULL，组将合并到
父组而不是创建子组。属于
合并组的统计信息的行为就像它们被直接添加到
父组一样。

##### `virtual void regStats()`
用于设置统计信息参数的回调。

此回调通常用于复杂的统计信息（例如，
分布），除了名称和
描述之外还需要参数。在统计信息对象无法在
构造函数中初始化的情况下（例如跟踪
总线主控器的统计信息，只有在整个
系统实例化后才能发现）。统计信息名称和描述应该
通常使用 `ADD_STAT` 宏从构造函数中设置。

##### `virtual void resetStats()`
用于重置统计信息的回调。

##### `virtual void preDumpStats()`
在转储统计信息之前的回调。这可以被
需要在统计信息框架实现的功能之外执行计算的对象覆盖。

##### `void addStat(Stats::Info *info)`
向此组注册统计信息。此方法通常在
实例化统计信息时自动调用。

##### `const std::map<std::string, Group *> &getStatGroups() const`
获取与此对象关联的所有子组。

##### `const std::vector<Info *> &getStats() const`
获取与此对象关联的所有统计信息。

##### `void addStatGroup(const char *name, Group *block)`
将统计信息块添加为此块的子项。

此方法只能从 Group 构造函数或从
regStats 调用。它通常只在从 Python
设置 SimObject 层次结构时显式调用。

##### `const Info * resolveStat(std::string name) const`
在此组中按名称解析统计信息。

此方法遍历此组和子组中的统计信息
并返回与提供的
名称匹配的统计信息的指针。输入名称必须相对于此
组的名称。

例如，如果此组是 `SimObject
system.bigCluster.cpus` 并且我们想要统计信息
`system.bigCluster.cpus.ipc`，输入参数应该是
字符串 "ipc"。

---

## 统计信息标志

| 标志            | 描述                                                   |
|------------------|----------------------------------------------------------------|
| `Stats::none`    | 不打印额外内容。                                        |
| `Stats::total`   | 打印总和。                                               |
| `Stats::pdf`     | 打印此条目占总数的百分比。     |
| `Stats::cdf`     | 打印到此条目为止的累积百分比。      |
| `Stats::dist`    | 打印分布。                                        |
| `Stats::nozero`  | 如果为零则不打印。                                   |
| `Stats::nonan`   | 如果为 NAN 则不打印                                     |
| `Stats::oneline` | 在单行上打印所有值。仅对直方图有用。 |

注意：尽管标志 `Stats::init` 和 `Stats::display` 可用，但这些标志
不允许由用户设置。

---

## 统计信息类

| 类名                                         | 描述                                                            |
|-----------------------------------------------------|-------------------------------------------------------------------------|
| [`Stats::Scalar`](#statsscalar)                     | 简单标量统计信息。                                                |
| [`Stats::Average`](#statsaverage)                   | 计算值的每 TICK 平均值的统计信息。             |
| [`Stats::Value`](#statsvalue)                       | 类似于 Stats::Scalar。                                               |
| [`Stats::Vector`](#statsvector)                     | 标量统计信息的向量。                                          |
| [`Stats::AverageVector`](#statsaveragevector)       | 平均值统计信息的向量。                                         |
| [`Stats::Vector2d`](#statsvector2d)                 | 标量统计信息的二维向量。                                       |
| [`Stats::Distribution`](#statsdistribution)         | 简单分布统计信息（具有方便的 min、max、sum 等）。 |
| [`Stats::Histogram`](#statshistogram)               | 简单直方图统计信息（保持等分连续范围的频率）。 |
| [`Stats::SparseHistogram`](#statssparsehistogram)   | 保持离散值集合的频率/直方图。     |
| [`Stats::StandardDeviation`](#statsstandarddeviation)| 计算所有样本的均值和方差。                       |
| [`Stats::AverageDeviation`](#statsaveragedeviation) | 计算每 tick 的样本均值和方差。                       |
| [`Stats::VectorDistribution`](#statsvectordistribution)| 分布的向量。                                           |
| [`Stats::VectorStandardDeviation`](#statsvectorstandarddeviation)| 标准差统计信息的向量。                 |
| [`Stats::VectorAverageDeviation`](#statsvectoraveragedeviation)| 平均偏差统计信息的向量。                    |
| [`Stats::Formula`](#statsformula)                   | 保持涉及多个统计信息对象的算术运算的统计信息。    |

**注意**：`Stats::Average` 仅计算标量在模拟 tick 数上的平均值。
为了获得数量 A 相对于数量 B 的平均值，可以使用 `Stats::Formula`。
例如，
```C++
Stats::Scalar totalReadLatency;
Stats::Scalar numReads;
Stats::Formula averageReadLatency = totalReadLatency/numReads;
```

### 通用统计信息函数

| 函数签名                                 | 描述                                                           |
|-----------------------------------------------------|------------------------------------------------------------------------|
|`StatClass name(const std::string &name)`            | 设置统计信息名称，标记要打印的统计信息                 |
|`StatClass desc(const std::string &_desc)`           | 设置统计信息的描述                                 |
|`StatClass precision(int _precision)`                | 设置统计信息的精度                                    |
|`StatClass flags(Flags _flags)`                      | 设置标志                                                         |
|`StatClass prereq(const Stat &prereq)`               | 设置先决条件统计信息                                             |

### `Stats::Scalar`
Storing a signed integer statistic.

| Function signatures                                 | Descriptions                                                           |
|-----------------------------------------------------|------------------------------------------------------------------------|
|`void operator++()`                                  | increments the stat by 1 // prefix ++, e.g. `++scalar`                 |
|`void operator--()`                                  | decrements the stat by 1 // prefix --                                  |
|`void operator++(int)`                               | increments the stat by 1 // postfix ++, e.g. `scalar++`                |
|`void operator--(int)`                               | decrements the stat by 1 // postfix --                                 |
|`template <typename U> void operator=(const U &v)`   | sets the scalar to the given value                                     |
|`template <typename U> void operator+=(const U &v)`  | increments the stat by the given value                                 |
|`template <typename U> void operator-=(const U &v)`  | decrements the stat by the given value                                 |
|`size_type size()`                                   | returns 1                                                              |
|`Counter value()`                                    | returns the current value of the stat as an integer                    |
|`Counter value() const`                              | returns the current value of the stat as an integer                    |
|`Result result()`                                    | returns the current value of the stat as a `double`                    |
|`Result total()`                                     | returns the current value of the stat as a `double`                    |
|`bool zero()`                                        | returns `true` if the stat equals to zero, returns `false` otherwise   |
|`void reset()`                                       | resets the stat to 0                                                   |

### `Stats::Average`
Storing an average of an integer quantity, supposely A, over the number of simulated ticks.
The quantity A keeps the same value across all ticks after its latest update and before the next update.
**Note:** the number of simulated ticks is reset when the user calls `Stats::reset()`.

| Function signatures                                 | Descriptions                                                           |
|-----------------------------------------------------|------------------------------------------------------------------------|
|`void set(Counter val)`                              | sets the quantity A to the given value                                 |
|`void inc(Counter val)`                              | increments the quantity A by the given value                           |
|`void dec(Counter val)`                              | decrements the quantity A by the given value                           |
|`Counter value()`                                    | returns the current value of A as an integer                           |
|`Result result()`                                    | returns the current average as a `double`                              |
|`bool zero()`                                        | returns `true` if the average equals to zero, returns `false` otherwise|
|`void reset(Info \*info)`                            | keeps the current value of A, does not count the value of A before the current tick|

### `Stats::Value`
Storing a signed integer statistic that is either an integer or an integer that is a result from calling a function or an object's method.

| Function signatures                                 | Descriptions                                                           |
|-----------------------------------------------------|------------------------------------------------------------------------|
|`Counter value()`                                    | returns the value as an integer                                        |
|`Result result() const`                              | returns the value as a double                                          |
|`Result total() const`                               | returns the value as a double                                          |
|`size_type size() const`                             | returns 1                                                              |
|`bool zero() const`                                  | returns `true` if the value is zero, returns `false` otherwise         |


### `Stats::Vector`
Storing an array of scalar statistics where each element of the vector has function signatures similar to those of `Stats::Scalar`.

| Function signatures                                 | Descriptions                                                           |
|-----------------------------------------------------|------------------------------------------------------------------------|
|`Derived & init(size_type size)`                     | initializes the vector to the given size (throws an error if attempting to resize an initilized vector)|
|`Derived & subname(off_type index, const std::string &name)`| adds a name to the statistic at the given index                 |
|`Derived & subdesc(off_type index, const std::string &desc)`| adds a description to the statistic at the given index          |
|`void value(VCounter &vec) const`                    | copies the vector of statistics to the given vector of integers        |
|`void result(VResult &vec) const`                    | copies the vector of statistics to the given vector of doubles         |
|`Result total() const`                               | returns the sum of all statistics in the vector as a double            |
|`size_type size() const`                             | returns the size of the vector                                         |
|`bool zero() const`                                  | returns `true` if each statistic in the vector is 0, returns `false` otherwise|
|`operator[](off_type index)`                         | gets the reference to the statistic at the given index, e.g. `vecStats[1]+=9`|

### `Stats::AverageVector`
Storing an array of average statistics where each element of the vector has function signatures similar to those of `Stats::Average`.

| Function signatures                                 | Descriptions                                                           |
|-----------------------------------------------------|------------------------------------------------------------------------|
|`Derived & init(size_type size)`                     | initializes the vector to the given size (throws an error if attempting to resize an initilized vector)|
|`Derived & subname(off_type index, const std::string &name)`| adds a name to the statistic at the given index                 |
|`Derived & subdesc(off_type index, const std::string &desc)`| adds a description to the statistic at the given index          |
|`void value(VCounter &vec) const`                    | copies the vector of statistics to the given vector of integers        |
|`void result(VResult &vec) const`                    | copies the vector of statistics to the given vector of doubles         |
|`Result total() const`                               | returns the sum of all statistics in the vector as a double            |
|`size_type size() const`                             | returns the size of the vector                                         |
|`bool zero() const`                                  | returns `true` if each statistic in the vector is 0, returns `false` otherwise|
|`operator[](off_type index)`                         | gets the reference to the statistic at the given index, e.g. `avgStats[1].set(9)`|

### `Stats::Vector2d`
Storing a 2-dimensional array of scalar statistics, where each element of the array has function signatures similar to those of `Stats::Scalar`.
This data structure assumes all elements whose the same second dimension index has the same name.

| Function signatures                                 | Descriptions                                                           |
|-----------------------------------------------------|------------------------------------------------------------------------|
|`Derived & init(size_type _x, size_type _y)`         | initializes the vector to the given size (throws an error if attempting to resize an initilized vector)|
|`Derived & ysubname(off_type index, const std::string &subname)` | sets `subname` as the name of the statistics of elements whose the second dimension of `index`|
|`Derived & ysubnames(const char **names)`            | similar to `ysubname()` above, but sets name for all indices of the second dimension|
|`std::string ysubname(off_type i) const`             | returns the name of the statistics of elements whose the second dimension of `i`|
|`size_type size() const`                             | returns the number of elements in the array                            |
|`bool zero()`                                        | returns `true` if the element at row 0 column 0 equals to 0, returns `false` otherwise |
|`Result total()`                                     | returns the sum of all elements as a double
|`void reset()`                                       | sets each element in the array to 0                                    |
|`operator[](off_type index)`                         | gets the reference to the statistic at the given index, e.g. `vecStats[1][2]+=9`|

### `Stats::Distribution`
Storing a distribution of a quantity.
The statistics of the distribution include,
  - the smallest/largest value being sampled
  - the number of values that are smaller/larger than the specified minimum and maximum
  - the sum of all samples
  - the mean, the geometric mean and the standard deviation of the samples
  - histogram within the range of [`min`, `max`] splitted into `(max-min)/bucket_size` equally sized buckets,  where the `min`/`max`/`bucket_size` are inputs to the init() function.

| Function signatures                                         | Descriptions                                                           |
|-------------------------------------------------------------|------------------------------------------------------------------------|
|`Distribution & init(Counter min, Counter max, Counter bkt)` | initializes the distribution where `min` is the minimum value being tracked by the distribution's histogram, `max` is the minimum value being tracked by the distribution's histogram, and `bkt` is the number of values in each bucket |
|`void sample(Counter val, int number)`                       | adds `val` to the distribution `number` times                          |
|`size_type size() const`                                     | returns the number of bucket in the distribution                       |
|`bool zero() const`                                          | returns `true` if the number of samples is zero, returns `false` otherwise |
|`void reset(Info *info)`                                     | discards all samples                                                   |
|`add(DistBase &)`                                            | merges the samples from another `Stats` class with `DistBase` (e.g. `Stats::Histogram`)|

### `Stats::Histogram`
Storing a histogram of a quantity given the number of buckets.
All buckets are equally sized.
Different from the histogram of `Stats::Distribution` which keeps track of the samples in a specific range, `Stats::Histogram` keeps track of all samples in its histogram.
Also, while `Stats::Distribution` is parameterized by the number of values in a bucket, `Stats::Histogram`'s sole parameter is the number of buckets.
When a new sample is outside of the current range of all all buckets, the buckets will be resized.
Roughly, two consecutive buckets will be merged until the new sample is inside one of the buckets.

Other than the histogram itself, the statistics of the distribution include,
  - the smallest/largest value being sampled
  - the sum of all samples
  - the mean, the geometric mean and the standard deviation of the samples

| Function signatures                                         | Descriptions                                                           |
|-------------------------------------------------------------|------------------------------------------------------------------------|
|`Histogram & init(size_type size)`                           | initializes the histogram, sets the number of buckets to `size`        |
|`void sample(Counter val, int number)`                       | adds `val` to the histogram `number` times                             |
|`void add(HistStor *)`                                       | merges another histogram to this histogram                             |
|`size_type size() const `                                    | returns the number of buckets                                          |
|`bool zero() const`                                          | returns `true` if the number of samples is zero, returns `false` otherwise |
|`void reset(Info *info)`                                     | discards all samples                                                   |

### `Stats::SparseHistogram`
Storing a histogram of a quantity given a set of integral values.

| Function signatures                                         | Descriptions                                                           |
|-------------------------------------------------------------|------------------------------------------------------------------------|
|`template <typename U> void sample(const U &v, int n = 1)`   | adds `v` to the histogram `n` times                                    |
|`size_type size() const `                                    | returns the number of entries                                          |
|`bool zero() const`                                          | returns `true` if the number of samples is zero, returns `false` otherwise |
|`void reset()`                                               | discards all samples                                                   |

### `Stats::StandardDeviation`
Keeps track of the standard deviation of a sample.

| Function signatures                                         | Descriptions                                                           |
|-------------------------------------------------------------|------------------------------------------------------------------------|
|`void sample(Counter val, int number)`                       | adds `val` to the distribution `number` times                          |
|`size_type size() const`                                     | returns 1                                                              |
|`bool zeros() const`                                         | discards all samples                                                   |
|`add(DistBase &)`                                            | merges the samples from another `Stats` class with `DistBase` (e.g. `Stats::Distribution`|

### `Stats::AverageDeviation`
Keeps track of the average deviation of a sample.

| Function signatures                                         | Descriptions                                                           |
|-------------------------------------------------------------|------------------------------------------------------------------------|
|`void sample(Counter val, int number)`                       | adds `val` to the distribution `number` times                          |
|`size_type size() const`                                     | returns 1                                                              |
|`bool zeros() const`                                         | discards all samples                                                   |
|`add(DistBase &)`                                            | merges the samples from another `Stats` class with `DistBase` (e.g. `Stats::Distribution`|

### `Stats::VectorDistribution`
Storing a vector of distributions where each element of the vector has function signatures similar to those of `Stats::Distribution`.

| Function signatures                                         | Descriptions                                                           |
|-------------------------------------------------------------|------------------------------------------------------------------------|
|`VectorDistribution & init(size_type size, Counter min, Counter max, Counter bkt)` | initializes a vector of `size` distributions where `min` is the minimum value being tracked by each distribution's histogram, `max` is the minimum value being tracked by each distribution's histogram, and `bkt` is each distribution's the number of values in each bucket |
|`Derived & subname(off_type index, const std::string &name)` | adds a name to the statistic at the given index                        |
|`Derived & subdesc(off_type index, const std::string &desc)` | adds a description to the statistic at the given index                 |
|`size_type size() const`                                     | returns the number of elements in the vector                           |
|`bool zero() const`                                          | returns `true` if each of distributions has 0 samples, return `false` otherwise |
|`operator[](off_type index)`                                 | gets the reference to the distribution at the given index, e.g. `dists[1].sample(2,3)`|

### `Stats::VectorStandardDeviation`
Storing a vector of standard deviations where each element of the vector has function signatures similar to those of `Stats::StandardDeviation`.

| Function signatures                                         | Descriptions                                                           |
|-------------------------------------------------------------|------------------------------------------------------------------------|
|`VectorStandardDeviation & init(size_type size)`             | initializes a vector of `size` standard deviations                     |
|`Derived & subname(off_type index, const std::string &name)`| adds a name to the statistic at the given index                         |
|`Derived & subdesc(off_type index, const std::string &desc)`| adds a description to the statistic at the given index                  |
|`size_type size() const`                                     | returns the number of elements in the vector                           |
|`bool zero() const`                                          | returns `true` if each of distributions has 0 samples, return `false` otherwise |
|`operator[](off_type index)`                                 | gets the reference to the standard deviation at the given index, e.g. `dists[1].sample(2,3)`|

### `Stats::VectorAverageDeviation`
Storing a vector of average deviations where each element of the vector has function signatures similar to those of `Stats::AverageDeviation`.

| Function signatures                                         | Descriptions                                                           |
|-------------------------------------------------------------|------------------------------------------------------------------------|
|`VectorAverageDeviation & init(size_type size)`              | initializes a vector of `size` average deviations                      |
|`Derived & subname(off_type index, const std::string &name)`| adds a name to the statistic at the given index                         |
|`Derived & subdesc(off_type index, const std::string &desc)`| adds a description to the statistic at the given index                  |
|`size_type size() const`                                     | returns the number of elements in the vector                           |
|`bool zero() const`                                          | returns `true` if each of distributions has 0 samples, return `false` otherwise |
|`operator[](off_type index)`                                 | gets the reference to the average deviation at the given index, e.g. `dists[1].sample(2,3)`|

### `Stats::Formula`
Storing a statistic that is a result of a series of arithmetic operations on `Stats` objects.
Note that, in the following function, `Temp` could be any of `Stats` class holding statistics (including vector statistics), a formula, or a number (e.g.`int`, `double`, `1.2`).

| Function signatures                                         | Descriptions                                                           |
|-------------------------------------------------------------|------------------------------------------------------------------------|
|`const Formula &operator=(const Temp &r)`                    | assigns an uninitialized `Stats::Formula` to the given root            |
|`const Formula &operator=(const T &v)`                       | assigns the formula to a statistic or another formula or a number      |
|`const Formula &operator+=(Temp r)`                          | adds to the current formula a statistic or another formula or a number  |
|`const Formula &operator/=(Temp r)`                          | divides the current formula by a statistic or another formula or a number |
|`void result(VResult &vec) const`                            | assigns the evaluation of the formula to the given vector; if the formula does *not* have a vector component (none of the variables in the formula is a vector), then the vector size is 1 |
|`Result total() const`                                       | returns the evaluation of the `Stats::Formula` as a double; if the formula does have a vector component (one of the variables in the formula is a vector), then the vector is turned in to a scalar by setting it to the sum all elements in the vector |
|`size_type size() const`                                     | returns 1 if the root element is not a vector, returns the size of the vector otherwise |
|`bool zero()`                                                | returns `true` if all elements in `result()` are 0's, returns `false` otherwise|

An example of using `Stats::Formula`,
```C++
Stats::Scalar totalReadLatency;
Stats::Scalar numReads;
Stats::Formula averageReadLatency = totalReadLatency/numReads;
```

---

## 附录：迁移到新的统计信息跟踪样式

### 新的统计信息跟踪样式
gem5 统计信息具有扁平结构，不了解 `SimObject` 的层次结构，而 `SimObject` 通常包含统计信息对象。
这导致不同统计信息具有相同名称的问题，更重要的是，操作 gem5 统计信息的结构并不简单。
此外，gem5 没有提供将统计信息对象集合分组到不同组的方法，这对于维护大量统计信息对象很重要。

[最近的提交](https://gem5-review.googlesource.com/c/public/gem5/+/19368)引入了 `Stats::Group`，这是一个旨在保存属于对象的所有统计信息的结构。
新结构提供了一种明确的方式来反映 `SimObject` 的层次结构性质
`Stats::Group` 还使维护大量应分组到不同集合的 `Stats` 对象更加明确和容易，因为可以在 `SimObject` 中创建多个 `Stats::Group` 并将它们合并到 `SimObject`，`SimObject` 也是一个了解其子 `Stats::Group` 的 `Stats::Group`。

总的来说，这是朝着更结构化的 `Stats` 格式迈出的一步，这将有助于操作 gem5 中统计信息的整体结构，例如过滤统计信息并将 `Stats` 生成更标准化的格式，如 JSON 和 XML，这些格式反过来在各种编程语言中都有大量支持的库。

### 迁移到新的统计信息跟踪样式

*注意*：强烈建议迁移到新样式；但是，旧样式的统计信息（即具有扁平结构的样式）仍然受支持。

本指南提供了如何迁移到 gem5 统计信息跟踪新样式的广泛概述，并指出了一些显示如何完成此操作的具体示例。

#### `ADD_STAT`
`ADD_STAT` 是一个定义为以下内容的宏，
```C++
#define ADD_STAT(n, ...) n(this, # n, __VA_ARGS__)
```
此宏旨在在 `Stats::Group` 构造函数中使用以初始化 `Stats` 对象。
换句话说，`ADD_STAT` 是调用 `Stats` 对象构造函数的别名。
例如，`ADD_STAT(stat_name, stat_desc)` 等同于，
```
  stat_name.parent = 定义 stat_name 的 `Stats::Group`
  stat_name.name = "stat_name"
  stat_name.desc = "stat_desc"
```
这适用于大多数 `Stats` 数据类型，但 `Stats::Formula` 例外，宏 `ADD_STAT` 可以处理指定公式的可选参数。
例如，`ADD_STAT(ips, "Instructions per Second", n_instructions/sim_seconds)`。


`ADD_STAT` 的示例用例（我们在本节中将此示例称为"**示例 1**"）。
此示例还用作构造 `Stats::Group` 结构体的模板。
```C++
    protected:
        // 定义统计信息组
        struct StatGroup : public Stats::Group
        {
            StatGroup(Stats::Group *parent); // 构造函数
            Stats::Histogram histogram;
            Stats::Scalar scalar;
            Stats::Formula formula;
        } stats;

    // 定义声明的构造函数
    StatGroup::StatGroup(Stats::Group *parent)
      : Stats::Group(parent),                           // 初始化基类
        ADD_STAT(histogram, "A useful histogram"),
        scalar(this, "scalar", "A number"),             // 这与 ADD_STAT(scalar, "A number") 相同
        ADD_STAT(formula, "A formula", scalar1/scalar2)
    {
        histogram
          .init(num_bins);
        scalar
          .init(0)
          .flags(condition ? 1 : 0);
    }
```

#### 迁移到新样式
这些是将统计信息转换为新样式的具体示例：[here](https://gem5-review.googlesource.com/c/public/gem5/+/19370)、[here](https://gem5-review.googlesource.com/c/public/gem5/+/19371) 和 [here](https://gem5-review.googlesource.com/c/public/gem5/+/32794)。

将统计信息迁移到新样式涉及：
  - 创建一个 `Stats::Group` 结构体，并将所有统计信息变量移到那里。此结构体的作用域应为 `protected`。统计信息变量的声明通常在头文件中。
  - 摆脱 `regStats()`，并将统计信息变量的初始化移到 `Stats::Group` 构造函数，如**示例 1** 所示。
  - 在头文件和 cpp 文件中，所有统计信息变量都应该以新创建的 `Stats::Group` 名称作为前缀，因为统计信息现在位于 `Stats::Group` 结构体下。
  - 更新类构造函数以初始化 `Stats::Group` 变量。通常，这是将 `stats(this)` 添加到构造函数，假设变量名是 `stats`。

一些示例，
  - `Stats::Group` 声明的示例在[此处](https://github.com/gem5/gem5/blob/v20.0.0.3/src/cpu/testers/traffic_gen/base.hh#L194)。
注意，所有以 `Stats::` 开头的类型变量都已移到结构体中。
  - 使用 `ADD_STAT` 的 `Stats::Group` 构造函数的示例在[此处](https://github.com/gem5/gem5/blob/v20.0.0.3/src/cpu/testers/traffic_gen/base.cc#L332)。
  - 在统计信息变量需要除 `name` 和 `description` 之外的额外初始化的情况下，您可以遵循[此示例](https://github.com/gem5/gem5/blob/v20.0.0.3/src/mem/comm_monitor.cc#L105)。
