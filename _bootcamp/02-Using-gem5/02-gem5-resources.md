---
layout: bootcamp
title: gem5 资源
permalink: /bootcamp/using-gem5/gem5-resources
section: using-gem5
---
<!-- _class: title -->

## gem5 资源

---

## 什么是资源？（磁盘、内核、二进制文件等）

- gem5 资源是可用于运行 gem5 模拟的预构建工件。
- 每个 gem5 资源属于 13 个类别之一（如二进制文件或内核），并支持 6 个 ISA 之一（包括 ARM、x86 和 RISC-V）。
- 有关类别的更多信息，请访问 [resources.gem5.org/category](https://resources.gem5.org/category)
- [gem5 资源网站](https://resources.gem5.org) 是搜索你想要使用的资源的便捷方式。
  - 有基于类别、ISA 和 gem5 版本的过滤器，可帮助你根据需求缩小资源范围。

---

## 重要类别及其描述

**内核 (Kernel)**：通过管理系统资源来充当操作系统核心的计算机程序。
**磁盘镜像 (disk-image)**：包含存储在存储设备上的数据精确副本的文件。
**二进制文件 (binary)**：用于测试计算机系统性能的程序。
**引导加载程序 (bootloader)**：在计算机启动时负责将操作系统加载到内存中的小程序。
**检查点 (checkpoint)**：模拟的快照。
**simpoint**：此资源存储创建和恢复 Simpoint 所需的所有信息。
**文件 (file)**：由单个文件组成的资源。
**工作负载 (workload)**：可以在 gem5 中直接运行的资源包和任何输入参数。
**套件 (suite)**：工作负载的集合。

---

## 资源版本控制

- 在 gem5 中，所有资源都有一个 `id`，对资源的任何更新都会更新 `resource_version`。
- 每个唯一资源由其 `id` 和 `resource_version` 表示。
- 当更新现有资源时，`id` 保持不变，但 `resource_version` 会更新。
- 每个资源还有一个名为 `gem5_versions` 的字段，显示资源与哪些 gem5 版本兼容。

![resource version fit bg right](/bootcamp/02-Using-gem5/02-gem5-resouces-imgs/resource_website_version.png)

---

## 在 gem5 模拟中使用资源

要在 gem5 中使用资源，我们可以使用 `obtain_resource` 函数。

让我们做一个示例，在示例中使用 `x86-hello64-static` 二进制文件。

转到 [materials/02-Using-gem5/02-gem5-resources/01-hello-example.py](../../materials/02-Using-gem5/02-gem5-resources/01-hello-example.py)

此文件构建一个基本板子，我们将使用 `x86-hello64-static` 资源并运行模拟。

---

## 运行 hello 二进制文件

要获取二进制文件，我们编写以下行：

```python
board.set_se_binary_workload(obtain_resource("x86-hello64-static"))
```

让我们分解这段代码

- `obtain_resource("x86-hello64-static")` 部分从 gem5 资源获取二进制文件 <!-- go into detail about the parameters -->
- `board.set_se_binary_workload` 部分告诉板子运行给定的二进制文件。

Then we run the simulation

```bash
cd materials/02-Using-gem5/02-gem5-resources
gem5 01-hello-example.py
```

---

## 工作负载

工作负载是一个或多个资源的包，可以具有预定义的参数。

让我们看看 `x86-npb-is-size-s-run` 工作负载。

此工作负载在 SE 模式下运行 NPB IS 基准测试。

你可以在资源网站的 [raw](https://resources.gem5.org/resources/x86-npb-is-size-s-run/raw?database=gem5-resources&version=1.0.0) 选项卡中查看工作负载的 JSON。

![workload se fit bg right](/bootcamp/02-Using-gem5/../02-Using-gem5/02-gem5-resouces-imgs/se_workload_ss.drawio.png)

---

## 工作负载（续）

让我们看看 `x86-ubuntu-24.04-boot-with-systemd` 工作负载，你可以查看 [raw](https://resources.gem5.org/resources/x86-ubuntu-24.04-boot-with-systemd/raw?database=gem5-resources&version=1.0.0) 选项卡以了解资源的制作方式。

- `function` 字段具有工作负载调用的函数名称。
- `resources` 字段包含工作负载使用的资源。
  - `resources` 字段的键（如 `kernel`、`disk_image` 等）与工作负载调用的 `function` 中的参数名称相同。
- `additional_params` 字段包含我们希望工作负载具有的非资源参数值。
  - 我们在上面的工作负载中使用 `kernel_args` 参数。

---

## 套件

套件是工作负载的集合，可以使用多处理并行运行（稍后将显示）。

套件中的所有工作负载都有一个名为 `input_groups` 的内容，可用于过滤套件。

Let's do an example where we will:

- Print all the workloads in the suite
- Filter the suite with `input_groups`
- Run a workload from the suite

---

<!-- _class: code-80-percent -->

## Printing all the workloads in a suite

The `SuiteResource` class acts as a generator so we can iterate through the workloads.

Let's print some workload information from  the `x86-getting-started-benchmark-suite` suite.

Let's modify [02-suite-workload-example.py](../../materials/02-Using-gem5/02-gem5-resources/02-suite-workload-example.py). Below, we get the resource and iterate through the suite, printing the `id` and `version` of each workload. Add this to the bottom of the script:

```python
getting_started_suite = obtain_resource("x86-getting-started-benchmark-suite")
for workload in getting_started_suite:
    print(f"Workload ID: {workload.get_id()}")
    print(f"workload version: {workload.get_resource_version()}")
    print("=========================================")
```

Now run:

```bash
gem5 02-suite-workload-example.py
```

---

## Filtering suites by `input_groups`

Each workload in a suite has one or more `input_groups` that we can filter by.

Let's print all the unique input groups in the suite.

We can do this by using the `get_input_groups()` function:

```python
print("Input groups in the suite")
print(getting_started_suite.get_input_groups())
```

---

<!-- _class: code-80-percent -->

## Running a workload from the suite (single code block)

Let's run the NPB IS benchmark in this suite.

First, we need to filter the suite to get this workload. We can do this by filtering to get all workloads that have the input tag `"is"`.

We convert the returned object to a list and get the first workload in it. This works because `"is"` is a unique tag that only one workload has, the NPB IS workload we're looking for.

Let's print the `id` of our workload and then run it with the board we have:

```python
npb_is_workload = list(getting_started_suite.with_input_group("is"))[0]
print(f"Workload ID: {npb_is_workload.get_id()}")
board.set_workload(npb_is_workload)

simulator = Simulator(board=board)
simulator.run()
```

---

## 本地资源

你也可以在 gem5 中使用本地创建的资源。

你可以创建一个本地 JSON 文件作为数据源，然后设置：

- `GEM5_RESOURCE_JSON` 环境变量指向 JSON，如果你只想使用 JSON 中的资源。
- `GEM5_RESOURCE_JSON_APPEND` 环境变量指向 JSON，如果你想将本地资源与 gem5 资源一起使用。

有关如何使用本地资源的更多详细信息，请阅读[本地资源文档](https://www.gem5.org/documentation/gem5-stdlib/using-local-resources)

---

## 为什么使用本地资源

gem5 有两种主要方式使用本地资源。

- 通过传递资源的本地路径直接创建资源对象。
  - `BinaryResource(local_path=/path/to/binary)`
  - 当我们在制作新资源并想快速测试资源时，可以使用此方法。
- 如果我们要使用或共享我们创建的资源，最好创建一个 JSON 文件并更新数据源，如上面的幻灯片中所述。
  - 使用此方法，我们可以使用 `obtain_resource`。
  - 此方法使模拟更具可重现性和一致性。

Let's do an example that creates a local binary and runs that binary in gem5.

---

## Let's create a binary

Let's use [this C program that prints a simple triangle pattern](../../materials/02-Using-gem5/02-gem5-resources/03-local-resources/pattern.c).

Compile this program. This will be the binary that we will run in gem5.

```bash
gcc -o pattern pattern.c
```

Now, let's use the local path method.

In [03-run-local-resource-local-path.py](../../materials/02-Using-gem5/02-gem5-resources/03-run-local-resource-local-path.py), create the binary resource object as follows:

```python
binary = BinaryResource(local_path="./pattern")
```

Let's run the simulation and see the output

```bash
gem5 03-run-local-resource-local-path.py
```

---

<!-- _class: code-50-percent -->

## Let's create a JSON file for the binary resource

The [JSON resource](../../materials/02-Using-gem5/02-gem5-resources/03-local-resources/local_resources.json) for the binary would look like this:

```json
{
  "category": "binary",
  "id": "x86-pattern-print",
  "description": "A simple X86 binary that prints a pattern",
  "architecture": "X86",
  "size": 1,
  "tags": [],
  "is_zipped": false,
  "md5sum": "2a0689d8a0168b3d5613b01dac22b9ec",
  "source": "",
  "url": "file://./pattern",
  "code_examples": [],
  "license": "",
  "author": [
      "Harshil Patel"
  ],
  "source_url": "",
  "resource_version": "1.0.0",
  "gem5_versions": [
      "23.0",
      "23.1",
      "24.0"
  ],
  "example_usage": "obtain_resource(resource_id=\"x86-pattern-print\")"
}
```

---

## Let's get the resource and run the simulation

In [04-run-local-resource-json.py](../../materials/02-Using-gem5/02-gem5-resources/04-run-local-resource-json.py), we can get the binary by using obtain resource:

```python
board.set_se_binary_workload(obtain_resource("x86-pattern-print"))
```

Let's run the simulation.

We do this by defining `GEM5_RESOURCE_JSON_APPEND` with our JSON resource before the usual `gem5` command:

```bash
GEM5_RESOURCE_JSON_APPEND=local_resources.json gem5 04-run-local-resource-json.py
```
