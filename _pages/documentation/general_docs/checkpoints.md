---
layout: documentation
title: 检查点
doc: gem5 documentation
parent: checkpoints
permalink: /documentation/general_docs/checkpoints/
---

# 检查点

检查点本质上是模拟的快照。当您的模拟需要极长时间（几乎总是如此）时，您会想要使用检查点，这样您可以在稍后使用 DerivO3CPU 从该检查点恢复。

## 创建

首先，您需要创建一个检查点。每个检查点保存在名为 'cpt.TICKNUMBER' 的新目录中，其中 TICKNUMBER 指创建此检查点时的 tick 值。有几种创建检查点的方法：

* 启动 gem5 模拟器后，执行命令 m5 checkpoint。可以使用 m5term 手动执行该命令，或将其包含在运行脚本中，以便在 Linux 内核启动后自动执行。
* 有一个伪指令可用于创建检查点。例如，可以在应用程序中包含此伪指令，以便在应用程序达到某个状态时创建检查点。
* 可以向 Python 脚本（fs.py、ruby_fs.py）提供 **--take-checkpoints** 选项，以便定期转储检查点。选项 **--checkpoint-at-end** 可用于在模拟结束时创建检查点。请查看文件 **configs/common/Options.py** 以了解这些选项。

在使用 Ruby 内存模型创建检查点时，必须使用 MOESI hammer 协议。这是因为检查点需要正确的内存状态，要求将缓存刷新到内存。此刷新操作目前仅在使用 MOESI hammer 协议时支持。

## 恢复

从检查点恢复通常可以很容易地从命令行完成，例如：

```console
  build/ALL/gem5.debug configs/example/fs.py -r N
  OR
  build/ALL/gem5.debug configs/example/fs.py --checkpoint-restore=N
```

数字 N 是表示检查点编号的整数，通常从 1 开始，然后递增到 2、3、4...

默认情况下，gem5 假设使用 Atomic CPU 恢复检查点。如果检查点是使用 Timing / Detailed / Inorder CPU 记录的，这可能不起作用。可以在命令行中提及选项 <br /> **--restore-with-cpu \<CPU Type\>**。使用此选项提供的 CPU 类型随后用于从检查点恢复。

## 详细示例：Parsec

在以下部分中，我们将描述如何为工作负载 PARSEC 基准测试套件创建检查点。但是，可以遵循类似的过程为 PARSEC 套件之外的其他工作负载创建检查点。以下是创建检查点的高级步骤：

1. 用关注区域（Region of Interest）的开始和结束以及程序中工作单元的开始和结束来注释每个工作负载。
2. 在关注区域开始时创建一个检查点。
3. 在关注区域中模拟整个程序，并定期创建检查点。
4. 分析对应于定期检查点的统计信息，并选择程序执行中最有趣的部分。
5. 在到达程序最有趣的部分之前，为 Ruby 获取预热缓存跟踪，并创建最终检查点。
在以下各节中，我们将更详细地解释上述每个步骤。

### 注释工作负载

注释有两个目的：定义程序初始化部分之外的程序区域，以及定义每个工作负载中的逻辑工作单元。

PARSEC 基准测试套件中的工作负载已经具有注释，用于标记没有程序初始化部分和程序完成部分的程序部分的开始和结束。我们只需使用 gem5 特定的注释来标记关注区域的开始。关注区域（ROI）的开始由 **m5_roi_begin()** 标记，ROI 的结束由 **m5_roi_end()** 标记。

由于模拟时间很长，并不总是可以模拟整个程序。此外，与单线程程序不同，在多线程工作负载中模拟给定数量的指令并不是模拟程序部分的正确方法，因为可能存在在同步变量上自旋的指令。因此，在每个工作负载中定义语义上有意义的逻辑工作单元很重要。在多线程工作负载中模拟给定数量的工作单元提供了一种合理的方法来模拟工作负载的一部分，从而解决在同步变量上自旋的指令问题。

# 切换/快进

## 采样

采样（在功能模型和详细模型之间切换）可以通过您的 Python 脚本实现。在脚本中，您可以指示模拟器在两组 CPU 之间切换。为此，在脚本中设置一个元组列表 (oldCPU, newCPU)。如果您希望同时切换多个 CPU，可以将它们全部添加到该列表中。例如：

```python
run_cpu1 = SimpleCPU()
switch_cpu1 = DetailedCPU(switched_out=True)
run_cpu2 = SimpleCPU()
switch_cpu2 = FooCPU(switched_out=True)
switch_cpu_list = [(run_cpu1,switch_cpu1),(run_cpu2,switch_cpu2)]
```

请注意，不立即运行的 CPU 应具有参数 "switched_out=True"。这可以防止这些 CPU 将自己添加到要运行的 CPU 列表中；它们将在您切换它们时被添加。

为了让 gem5 实例化您的所有 CPU，您必须将要切换的 CPU 设置为配置层次结构中某个对象的子对象。不幸的是，目前一些配置限制强制将切换 CPU 放置在 System 对象之外。Root 对象是放置 CPU 的下一个最方便的位置，如下所示：

```python
m5.simulate(500)  # simulate for 500 cycles
m5.switchCpus(switch_cpu_list)
m5.simulate(500)  # simulate another 500 cycles after switching
```

请注意，由于被切换出的 CPU 中可能存在任何未完成的状态，gem5 可能必须在切换 CPU 之前模拟几个周期。
