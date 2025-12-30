---
layout: documentation
title: gem5 实验的艺术
doc: gem5art
parent: gem5art
permalink: /documentation/gem5art/introduction
---

# gem5 实验的艺术

<img src="/assets/img/gem5art/gem5art.svg" alt="gem5art-logo" width="100%" style="max-width:300px;"/>
<br/>

gem5art 项目是一组 Python 模块，旨在帮助更轻松地运行 gem5 模拟器实验。
gem5art 包含用于*组件、可重现性和测试*的库。
您可以将 gem5art 视为运行 gem5 实验的结构化[协议](https://en.wikipedia.org/wiki/Protocol_(science))。

运行实验时，有输入、运行实验的步骤和输出。
gem5art 通过[组件](main/artifacts)跟踪所有这些内容。
组件是一个对象，通常是一个文件，用作实验的一部分。

gem5art 项目包含一个接口，用于将所有组件存储在[数据库](main/artifacts.html#artifactdb)中。
该数据库主要用于帮助可重现性，例如，当您想要返回并重新运行实验时。
但是，它也可以用于与其他进行类似实验的人共享组件（例如，包含共享工作负载的磁盘镜像）。

数据库还用于存储 [gem5 运行](main/run)的结果。
给定所有输入组件，这些运行具有足够的信息来重现完全相同的实验输出。
此外，每个 gem5 运行都有相关的元数据（例如，实验名称、脚本名称、脚本参数、gem5 二进制文件名等），这对于聚合多个实验的结果很有用。

这些实验聚合对于测试 gem5 以及进行研究都很有用。
我们将通过聚合来自数百或数千个 gem5 实验的数据来确定 gem5 代码库在任何特定时间点的状态。
例如，如[Linux 启动教程](tutorials/boot-tutorial)中所述，我们可以使用这些数据来确定哪些 Linux 内核、Ubuntu 版本和启动类型目前在 gem5 中可用。

----

gem5art 的一个基本主题是，您应该充分理解正在运行的实验的每个部分。
为此，gem5art 要求为特定实验的每个组件都*明确*定义。
此外，我们鼓励在从工作负载和磁盘镜像创建到运行 gem5 的每个实验级别使用 Python 脚本。
通过使用 Python 脚本，您可以自动化和记录运行实验的过程。

开发 gem5art 的许多想法来自我们使用 gem5 的经验以及运行复杂实验的痛点。
Jason Lowe-Power 在威斯康星大学麦迪逊分校攻读博士学位期间广泛使用了 gem5。
通过这段经历，他犯了很多错误，并花费了无数天的时间试图重现实验或重新创建意外删除或移动的组件。
gem5art 旨在减少这种情况发生在其他研究人员身上的可能性。
