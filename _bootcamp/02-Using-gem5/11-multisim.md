---
layout: bootcamp
title: MultiSim
permalink: /bootcamp/using-gem5/multisim
section: using-gem5
---
<!-- _class: title -->

## MultiSim

gem5 模拟的多处理支持。

---

## 问题

gem5 模拟器是单线程的。

这是核心设计的一部分，由于转换整个代码库的高成本，不太可能改变。

**因此，我们无法通过更多的核心和线程来"加速"您的工作**。

---

## 洞察

gem5 模拟器用于实验。

实验涉及探索当所有其他变量保持不变时，感兴趣的变量如何改变系统的行为。因此，使用 gem5 模拟器进行实验需要多次运行模拟器。
**可以并行运行多个 gem5 实例**。

_如果不是使用多线程的单一 gem5 进程，为什么不使用多个 gem5 进程，每个都是单线程的呢？_

（（这对我们来说非常方便，因为我们不需要担心多线程的复杂性：内存一致性等。））

---

## 人们已经在这样做...某种程度上...

前往 [`materials/02-Using-gem5/11-multisim/01-multiprocessing-via-script`](../../materials/02-Using-gem5/11-multisim/01-multiprocessing-via-script/) 目录查看一个完整的示例，展示如何**不**运行多个 gem5 进程。

这是典型的做法，但不推荐。

编写脚本来运行多个 gem5 进程：

1. 需要用户编写脚本。
    1. 增加了入门门槛。
    2. 增加了出错的可能性。
    3. 需要用户管理输出文件。
2. 非标准化（每个人的做法都不同）。
    1. 难以与他人分享。
    2. 难以重现。
    3. 现在或将来都没有内置支持。

---

## 更好的方法

**MultiSim** 是 gem5 的一个功能，允许用户从单个 gem5 配置脚本运行多个 gem5 进程。

该脚本概述了要运行的模拟。
父 gem5 进程（用户直接启动的进程）会生成 gem5 子进程，每个子进程都能够运行这些模拟。

通过 Python `multiprocessing` 模块，父 gem5 进程将模拟（"作业"）排队，供子 gem5 进程（"工作线程"）执行。

---

与简单地编写脚本来运行多个 gem5 进程相比，Multisim 有几个优势：

1. 我们（gem5 开发者）为您处理这些。
    1. 降低入门门槛。
    2. 降低出错的可能性。
    3. Multisim 会自动处理输出文件。
2. 标准化。
    1. 易于与他人分享（只需发送脚本）。
    2. 易于重现（只需运行脚本）。
    3. 允许未来的支持（编排等）。

---

### 一些注意事项（这是新功能：请耐心等待）

此功能自版本 24.0 起是新的。

它还不完全成熟，仍然缺乏工具和库支持，这些支持将允许更大的灵活性和易用性。
然而，这个简短的教程应该能让您对如何继续使用它有一个很好的了解。

---

## 让我们看一个例子

首先打开 [`materials/02-Using-gem5/11-multisim/02-multiprocessing-via-multisim/multisim-experiment.py`](../../materials/02-Using-gem5/11-multisim/02-multiprocessing-via-multisim/multisim-experiment.py)。

此配置脚本与上一个示例中的脚本几乎相同，但移除了 argparse 代码并添加了 multisim 导入：

### 开始：声明最大处理器数量

```python
# Sets the maximum number of concurrent processes to be 2.
multisim.set_num_processes(2)
```

如果未设置，gem5 将默认消耗所有可用线程。
我们**强烈**建议设置此值以避免过度消耗系统资源。
将此行放在配置脚本的顶部附近。

---

## 使用简单的 Python 结构定义多个模拟

```python
for data_cache_size in ["8kB","16kB"]:
    for instruction_cache_size in ["8kB","16kB"]:
        cache_hierarchy = PrivateL1CacheHierarchy(
            l1d_size=data_cache_size,
            l1i_size=instruction_cache_size,
        )
```

用此代码替换 [`multisim-experiment.py`](../../materials/02-Using-gem5/11-multisim/02-multiprocessing-via-multisim/multisim-experiment.py) 中的缓存层次结构，并缩进缓存层次结构之后的代码，使其全部位于内部 for 循环（`for instruction_cache_size ...`）内。

---

## 创建模拟并将其添加到 MultiSim 对象

关键区别：模拟器对象通过 `add_simulator` 函数传递给 MultiSim 模块。

这里不调用 `run` 函数。相反，它参与 MultiSim 模块的执行。

```python
multisim.add_simulator(
    Simulator(
        board=board,
        id=f"process_{data_cache_size}_{instruction_cache_size}"
    )
)
```

`id` 参数用于标识模拟。强烈建议设置此参数。每个输出目录将根据 `id` 参数命名。

---

## 执行多个模拟

可以在 [`materials/02-Using-gem5/11-multisim/completed/02-multiprocessing-via-multisim/multisim-experiment.py`](../../materials/02-Using-gem5/11-multisim/completed/02-multiprocessing-via-multisim/multisim-experiment.py) 找到完整的示例。

```shell
cd /workspaces/2024/materials/02-Using-gem5/11-multisim/completed/02-multiprocessing-via-multisim
gem5 -m gem5.utils.multisim multisim-experiment.py
```

检查 "m5out" 目录以查看每个模拟的分离输出文件。

---

## 从 MultiSim 配置执行单个模拟

您也可以从 MultiSim 配置脚本执行单个模拟。
为此，只需将配置脚本直接传递给 gem5（即，不要使用 `-m gem5.multisim multisim-experiment.py`）。

要列出 MultiSim 配置脚本中模拟的 ID：

```shell
gem5 {config} --list
```

要执行单个模拟，传递 ID：

```shell
gem5 {config} {id}
```
