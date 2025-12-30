---
layout: documentation
title: 概述
doc: gem5art
parent: main
permalink: /documentation/gem5art/main/summary
Authors:
  - Ayaz Akram
  - Jason Lowe-Power
---

# 概述

gem5art 的主要动机是提供基础设施，使用结构化方法来运行 gem5 实验。gem5art 的具体目标包括：

- 结构化的 gem5 实验
- 易于使用
- 资源共享
- 可重现性
- 易于扩展
- 记录已执行的实验

gem5art 主要由以下组件组成：

- 用于存储组件的数据库（`gem5art-artifacts`）
- 用于包装 gem5 实验的 Python 对象（`gem5art-run`）
- 用于管理 gem5 作业的 celery 工作进程（`gem5art-tasks`）

由于涉及多个组件，使用 gem5 执行实验的过程可能很快变得复杂。
这对新用户来说可能令人生畏，即使对于有经验的研究人员来说也很难管理。
例如，下图显示了在使用 gem5 运行全系统实验时不同组件（组件）之间发生的交互。


![](/assets/img/gem5art/art.png)
<br>
*图：gem5 全系统模式用例流程图*

图中的每个气泡代表一个不同的[组件](artifacts)，这是 gem5 实验的一小部分，最终产生 gem5 执行的结果。
所有线条都显示组件之间的依赖关系（例如，磁盘镜像依赖于 m5 二进制文件）。

您可以想象此示例中的所有内容都包含在一个基础 git 仓库（base repo）组件中，该组件可以跟踪其他仓库未跟踪的文件更改。
[Packer](https://packer.io) 是生成磁盘镜像的工具，并作为磁盘镜像组件的输入。
gem5 源代码仓库组件作为另外两个组件（gem5 二进制文件和 m5 实用程序）的输入。
Linux 源代码仓库和基础仓库（特别是内核配置文件）用于构建磁盘镜像，多个组件然后生成最终的结果组件。

gem5art 作为工具/基础设施来简化整个过程，并在事物发生变化时跟踪它们，从而实现可重现的运行。
此外，它允许多个用户共享上述示例中使用的组件。
此外，gem5art 像所有其他组件一样跟踪结果，因此可以稍后归档和查询它们以聚合许多不同的 gem5 实验。


## 安装 gem5art

gem5art 可作为 PyPI 包使用，可以使用 pip 安装。
由于 gem5art 需要 Python 3，我们建议在使用 gem5art 之前创建一个 Python 3 虚拟环境。
运行以下命令创建虚拟环境并安装 gem5art：

```sh
virtualenv -p python3 venv
source venv/bin/activate
pip install gem5art-artifact gem5art-run gem5art-tasks
```
