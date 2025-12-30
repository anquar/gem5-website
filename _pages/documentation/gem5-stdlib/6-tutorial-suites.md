---
layout: documentation
title: gem5 中的套件
parent: gem5-standard-library
doc: gem5 documentation
permalink: /documentation/gem5-stdlib/suites
author: Kunal Pai, Harshil Patel
---

## 简介

Suite 是 gem5 版本 23.1 中引入的新资源类别，允许用户对工作负载进行分组。
SuiteResource 类已添加到资源专门化中。
gem5 资源上的预构建套件可以使用 `obtain_resource()` 获取，就像所有其他资源一样。

SuiteResource 类具有 `__iter__` 和 `__len__` 函数。
SuiteResource 将表现为一个迭代器，返回工作负载对象的生成器。

### 如何获取套件

要获取 gem5 资源中已有的套件，我们可以使用 `[resource.py](http://resource.py)` 中的 `obtain_resource` 函数。

要获取 ID 为 "riscv-vertical-microbenchmarks" 和版本为 "1.0.0" 的套件

```python
suite_obj = obtain_resource(id = "riscv-vertical-microbenchmarks", resource_version="1.0.0")
```

不指定 resource_version 将返回资源的最新兼容版本。

**注意**：本教程其余部分使用的套件是 "riscv-vertical-microbenchmarks"，它存在于 gem5 资源中，但仅与 gem5 版本 23.1 及更高版本以及 RISC-V ISA 兼容。

### 如何按输入组过滤套件中的工作负载

每个套件都有一个 workloads 字段，它是一个包含套件中所有工作负载的 ID、版本和输入组的数组。

The workload field would look like the following:

```python
[
	{
		'id': 'riscv-cca-run',
		'resource_version': '1.0.0',
		'input_group': ['cca']
	},
	{
		'id': 'riscv-cce-run',
		'resource_version': '1.0.0',
		'input_group': ['cce']
	},
	{
		'id': 'riscv-ccm-run',
		'resource_version': '1.0.0',
		'input_group': ['ccm']
	},
	...
]
```

SuiteResource 类具有允许用户按输入组过滤工作负载的函数。
函数 `get_input_groups()` 返回套件中存在的所有输入组的集合。
函数 `with_input_group(str)` 返回一个 SuiteResource 对象，该对象仅包含具有作为参数传入的输入组的工作负载。
例如，我们的套件具有如上定义的 workloads 字段，那么 `get_input_groups()` 将返回以下内容：

```python
set(['cca','cce','ccm',...])
```

我们可以像这样使用 `with_input_group()`：

```python
suite_obj = obtain_resource('riscv-vertical-microbenchmarks')
filtered_suite = suite_obj.with_input_group('cca')
```

这将返回一个 `SuiteResource`，其中包含所有满足具有输入组 "cca" 条件的工作负载，在这种情况下是 ID 为 "riscv-cca-run" 的 `WorkloadResource`。

我们还可以将 `with_input_group()` 函数与 for 循环和生成器一起使用。

```python
for workload in suite_obj.with_input_group('cca')
	board.set_workload(workload)
	simulator = Simulator(board=board)
	simulator.run()
```

### 创建自定义套件

也可以通过直接使用 `[resource.py](http://resource.py)` 中的 `SuiteResource` 类来创建自定义套件。
要创建自定义套件，我们还需要 `WorkloadResource` 对象。

```python
workload1= obtain_resource('workload-1', resource_version='1.0.0')
workload2= obtain_resource('workload-2', resource_version='1.0.0')

suite_obj = SuiteResource(workloads=[workload1, workload2])
```

上面的代码片段将创建一个包含两个工作负载的套件对象。
我们在上面的套件中没有定义 `workloads` 字段，因此 `get_input_group()` 和 `with_input_group()` 函数将抛出警告，并分别返回空集和没有工作负载的套件对象。

如果添加了 `workloads` 字段，则自定义套件将与使用 `obtain_resource` 创建的套件功能相同。

```python
workload1= obtain_resource('workload-1', resource_version='1.0.0')
workload2= obtain_resource('workload-2', resource_version='1.0.0')
workloads = [
	{
		'id': 'workload-1',
		'resource_version': '1.0.0',
		'input_group': ['input_group_1', 'input_group_2']
	},
	{
		'id': 'workload-2',
		'resource_version': '1.0.0',
		'input_group': ['input_group_1', 'input_group_3']
	}]
suite_obj = SuiteResource(workloads=[workload1, workload2], worklaods= workloads)
```
