---
layout: documentation
title: MSI 示例缓存协议
doc: Learning gem5
parent: part3
permalink: /documentation/learning_gem5/part3/cache-intro/
author: Jason Lowe-Power
---


## MSI 示例缓存协议

在实现缓存一致性协议之前，对缓存一致性有深刻的了解非常重要。本节主要依靠 Daniel J. Sorin、Mark D. Hill 和 David A. Wood 撰写的伟大著作 *A Primer on Memory Consistency and Cache Coherence*，该书于 2011 年作为 Synthesis Lectures on Computer Architecture 的一部分出版
([DOI:10.2200/S00346ED1V01Y201104CAC016](https://doi.org/10.2200/S00346ED1V01Y201104CAC016))。
如果您不熟悉缓存一致性，我强烈建议您在继续之前阅读该书。

在本章中，我们将实现一个 MSI 协议。
（MSI 协议具有三个稳定状态：modified 具有读写权限，shared 具有只读权限，invalid 没有权限。）
我们将这实现为一个三跳目录协议（即，缓存可以将数据直接发送到其他缓存，而无需经过目录）。
协议的详细信息可以在 *A Primer on Memory Consistency and Cache Coherence* 的第 8.2 节（第 141-149 页）中找到。
打印出第 8.2 节以便在实施协议时参考会很有帮助。

您可以通过 [此链接](https://link.springer.com/content/pdf/10.1007/978-3-031-01764-3.pdf) 下载第二版。

## 编写协议的第一步

让我们首先在 src/learning\_gem5/MSI\_protocol 为我们的协议创建一个新目录。
在此目录中，就像在所有 gem5 源代码目录中一样，我们需要为 SCons 创建一个文件以了解要编译的内容。
但是，这一次，我们要创建一个 `SConsopts` 文件，而不是创建 `SConscript` 文件。（`SConsopts` 文件在 `SConscript` 文件之前处理，我们需要在 SCons 执行之前运行 SLICC 编译器。）

我们需要创建一个包含以下内容的 `SConsopts` 文件：

```python
Import('*')

main.Append(ALL_PROTOCOLS=['MSI'])

main.Append(PROTOCOL_DIRS=[Dir('.')])
```

我们在这个文件中做了两件事。首先，我们注册协议的名称（`'MSI'`）。由于我们将协议命名为 MSI，SCons 将假定存在一个名为 `MSI.slicc` 的文件，该文件指定所有状态机文件和辅助文件。我们将在编写所有状态机文件后创建该文件。其次，`SConsopts` 文件告诉 SCons 在当前目录中查找要传递给 SLICC 编译器的文件。

您可以下载 `SConsopts` 文件
[这里](https://gem5.googlesource.com/public/gem5/+/refs/heads/stable/src/learning_gem5/part3/SConsopts)。

### 编写状态机文件

编写协议的下一步也是大部分工作是创建状态机文件。状态机文件通常遵循以下大纲：

Parameters (参数)
:   这些是将从 SLICC 代码生成的 SimObject 的参数。

Declaring required structures and functions (声明所需的结构和函数)
:   本节声明状态、事件以及状态机所需的许多其他结构。

In port code blocks (输入端口代码块)
:   包含查看来自 (`in_port`) 消息缓冲区的传入消息并确定触发哪些事件的代码。

Actions (动作)
:   这些是在转换过程中执行的简单的单效果代码块（例如，发送消息）。

Transitions (转换)
:   指定给定开始状态和事件以及最终状态时要执行的操作。这是状态机定义的核心。

在接下来的几节中，我们将介绍如何编写协议的每个组件。
