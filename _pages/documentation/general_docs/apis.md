---
layout: documentation
title: gem5 API
doc: gem5 documentation
parent: gem5-apis
permalink: /documentation/general_docs/gem5-apis/
authors: Bobby R. Bruce
---

有关标记为 API 的所有方法和变量的完整文档，请参阅我们的 [Doxygen 模块页面](
http://doxygen.gem5.org/release/v20-1-0-0/modules.html)。

# gem5 API

为了提高产品稳定性，gem5 开发团队正逐渐将 gem5 中的方法和变量标记为 API，开发人员需要经过特定程序才能更改这些 API。我们的 gem5 API 目标是为用户提供一个稳定的接口来构建 gem5 模型并扩展 gem5 代码库，并保证这些 API 不会在 gem5 版本之间发生剧烈、突然的变化。

## gem5 API 是如何记录的？

我们使用 [Doxygen 文档生成工具](
https://www.doxygen.nl/index.html) 记录 gem5 API。这意味着您可能会在源代码级别和通过我们的 [基于 Web 的文档](
http://doxygen.gem5.org) 看到标记的 API。我们使用 Doxygen 的 `@ingroup` 标签来指定方法/变量作为 gem5 API 的一部分。我们将 API 分解为子域，如 `api_simobject` 或 `api_ports`，尽管所有 gem5 API 都带有前缀 `api_`。例如，我们将 SimObject 的 `params()` 函数标记如下：

```cpp
/**
* @return This function returns the cached copy of the object parameters.
*
* @ingroup api_simobject
*/
const Params *params() const { return _params; }
```

通过 Doxygen 自动生成，gem5 API 列表可以在 [Doxygen 模块页面](http://doxygen.gem5.org/release/current/modules.html) 上找到。在此示例中，整个 SimObject API 列表都在 [SimObject API 页面](
http://doxygen.gem5.org/release/current/group__api__simobject.html) 中注明。
不同 API 组的定义可以在 [`src/doxygen/group_definitions.hh`](
https://github.com/gem5/gem5/blob/stable/src/doxygen/group_definitions.hh) 中找到。

### 开发人员注意事项

如果开发人员希望将新方法/变量标记为 gem5 API 的一部分，应咨询 gem5 社区。API 旨在保持一段时间不变。为了避免 gem5 项目受到“太多 API”的阻碍，我们强烈建议那些希望扩展 API 的人向 gem5 开发团队传达 API 为何具有价值。
[gem5 Discussion 页面](https://github.com/orgs/gem5/discussions/categories/gem5-dev) 是一个很好的沟通渠道。

## API 如何更改？

我们不保证 gem5 API 永远不会随着时间的推移而改变。gem5 是一个不断开发的产品，必须适应计算机体系结构研究社区的需求。但是，我们要保证 API 更改将遵循下文概述的严格准则。

1. 当 API 方法或变量被更改时，将以新 API 与旧 API 共存的方式进行，旧 API 标记为已弃用但仍可使用。

2. 旧的、已弃用的 API 将存在两个 gem5 主要周期，然后从代码库中完全删除，尽管 gem5 开发人员可能会选择将已弃用的 API 在代码库中保留更长时间。例如，如果 API 在 gem5 21.0 中标记为已弃用，它仍将存在于 gem5 21.1 中（仍标记为已弃用）。它可能会在 gem5 21.2 中完全删除，但这将留给 gem5 开发人员自行决定。

3. gem5 已弃用的 C++ API 将使用 C++ deprecated 属性 (`[[deprecated(<msg>)]]`) 进行标记。当使用已弃用的 C++ API 时，将在编译时给出警告，指定要转换到哪个 API。gem5 已弃用的 Python 参数 API 包含在我们 [定制的 `DeprecatedParam` 类](
https://github.com/gem5/gem5/blob/bd13e8e206e6c86581cf9afa904ef1060351a4b0/src/python/m5/params.py#L2166) 中。包含在此类中的 Python 参数在使用时会发出警告，并指定要转换到哪个 API。

### 开发人员注意事项

在对 gem5 API 进行任何更改之前，应咨询 [gem5-dev 邮件列表](
/ask-a-question/)。出于任何原因更改 API **都将** 受到比其他更改更严格的审查。开发人员应准备好提供令人信服的论据，说明为什么要更改 API。我们强烈建议讨论 API 更改，否则它们可能会在代码审查期间被拒绝。

创建新 API 时，必须将旧 API 标记为已弃用，并且创建的新 API 需与旧 API 共存。**维护且不删除旧的、已弃用的 API 至关重要**。

作为一个例子，请看下面的代码：

```cpp
/**
 * @ingroup api_bitfield
 */
inline uint64_t
mask(int first, int last)
{
    return mbits((uint64_t)-1LL, first, last);
}
```

此函数是 gem5 位段 (bitfield) API 的一部分。这是一个基本的掩码函数，它采用 MSB (first) 和 LSB (last) 来生成 64 位。
让我们假设有一个很好的论据，即这个函数应该替换为一个采用 MSB (first) 和掩码长度的函数。

首先，旧 API 需要维护（即不更改）并使用 `[[deprecated(<msg>)]]` 标记进行标记。提供的消息 (`<msg>`) 应说明要使用的新 API，并且应删除 API 标记。然后应创建并标记新 API。因此，使用我们的示例：

```cpp
[[deprecated("Use mask_length instead.")]]
inline uint64_t
mask(int first, int last)
{
    return mbits((uint64_t)-1LL, first, last);
}
```

```cpp
/**
 * @ingroup api_bitfield
 */
inline uint64_t
mask_length(int first, int length)
{
    return mbits((uint64_t)-1LL, first, first + length);
}
```

在这里，创建了一个新函数 `mask_length`。它已通过 Doxygen 正确标记。旧 API `mask` 存在，但添加了 `[[deprecated]]` 注释。提供的消息说明了哪个 API 替换它。

然后开发人员需要将代码库中所有 `mask` 的使用替换为 `mask_length`。如果使用 `mask`，编译时将会给出警告，说明它已被弃用并“使用 mask\_length 代替”。

偶尔可能需要更改 python API 接口，这与标记的 API 有关。例如，让我们看下面的代码：

```python
class TLBCoalescer(ClockedObject):
    type = 'TLBCoalescer'
    cxx_class = 'TLBCoalescer'
    cxx_header = 'gpu-compute/tlb_coalescer.hh'

    ...

    slave    = VectorResponsePort("Port on side closer to CPU/CU")
    master   = VectorRequestPort("Port on side closer to memory")

   ...
```

[在最近的修订中](
https://github.com/gem5/gem5/tree/392c1ced53827198652f5eda58e1874246b024f4)
术语 `master` 和 `slave` 已被替换。但是，`slave` 和 `master` 术语被广泛使用，以至于我们认为它们是旧 API 的一部分。因此，我们希望以安全的方式弃用此 API，同时将 `master` 和 `slave` 更改为 `cpu_side_ports` 和 `mem_side_ports`。为此，我们将维护 `master` 和 `slave` 变量，但利用我们的 [`DeprecatedParam` 类](
https://github.com/gem5/gem5/blob/bd13e8e206e6c86581cf9afa904ef1060351a4b0/src/python/m5/params.py#L2166)
在这些已弃用的变量被使用时产生警告。针对我们的示例，我们将产生以下内容：

```python
class TLBCoalescer(ClockedObject):
    type = 'TLBCoalescer'
    cxx_class = 'TLBCoalescer'
    cxx_header = 'gpu-compute/tlb_coalescer.hh'

    ...

    cpu_side_ports = VectorResponsePort("Port on side closer to CPU/CU")
    slave    = DeprecatedParam(cpu_side_ports,
                        '`slave` is now called `cpu_side_ports`')
    mem_side_ports = VectorRequestPort("Port on side closer to memory")
    master   = DeprecatedParam(mem_side_ports,
                        '`master` is now called `mem_side_ports`')

   ...
```

请注意使用 `DeprecatedParam`，既确保 `master` 和 `slave` 仍通过分别重定向到 `mem_side_ports` 和 `cpu_side_ports` 来发挥作用，又提供了解释为什么此 API 已被弃用的注释。如果曾经使用 `master` 或 `slave`，这将显示为警告给用户。

与 gem5 源代码的所有更改一样，这些更改必须通过我们的 Gerrit 代码审查系统，然后才能合并到 `develop` 分支，并最终作为 gem5 发布的一部分进入我们的 `stable` 分支。
根据我们的 API 政策，这些已弃用的 API 必须以标记为已弃用的状态存在两个 gem5 主要发布周期。在此之后，它们可能会被删除，尽管开发人员没有被要求这样做。
