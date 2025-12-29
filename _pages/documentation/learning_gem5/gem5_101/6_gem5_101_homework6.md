---
layout: documentation
title: 作业 6 - 多核编程
doc: Learning gem5
parent: gem5_101
permalink: /documentation/learning_gem5/gem5_101/homework-6
authors:
---


# CS 758: 多核处理器编程 (2013 年秋季 1 组)


**GPU: 10/30**

**您应该独自完成此作业。不接受逾期作业。**

作业文件列表：
* [模板文件]({$urlbase}/handouts/homeworks/hw6-dist.tgz)
* [Euler 集群使用简介](http://wacc.wisc.edu/documentation/EulerWalkthrough.pdf)

本作业的目的是让您熟悉 GPGPU 计算平台 (CUDA) 并获得 GPGPU 特定优化的经验。对于此作业，您将获得在 GPU 上运行的算法的基本实现，并且您将通过应用 GPGPU 优化原则程序性地改进它。

**重要提示**:
CUDA 可能很棘手，特别是如果您犯了错误。错误消息通常很隐晦且信息量不大。尽早开始这项作业！如果您遇到任何问题，请在电子邮件列表上发帖。

## 问题
对于此作业，您将再次实现 Ocean 算法。您将比较您的 GPU 优化算法的性能与您在作业 1 中的解决方案。模板文件中也包含作业 1 的简单解决方案，如果您愿意，可以随意使用它。

## 硬件
您将使用 Euler 集群。您应该拥有或即将收到一封包含用户名和临时密码的电子邮件。（确保您重置密码！）阅读上面描述硬件配置的教程。

## 作业提交
此作业最初设置为将作业提交到 Torque 队列。
对于此作业，请直接在 `euler01` 上运行作业。

开始：

```sh
local $ ssh user@euler.wacc.wisc.edu
euler $ ssh euler01
euler01 $ scp <username>@ale-01.cs.wisc.edu:/p/course/cs758-david/public/html/Fall2013/handouts/homeworks/hw6-dist.tgz .
euler01 $ tar -x -f hw6-dist.tgz
euler01 $ mv hw4-dist hw6
euler01 $ cd hw6
euler01 $ make
euler01 $ ./serial_ocean.sh
```

只要您的代码快速完成并且您不长时间打开 cuda-gdb，您就不会遇到任何问题（他们遇到过一些 cuda-gdb 有时会阻止访问所有其他 GPU 的错误）。

Euler 集群中提供的硬件信息可在 [此处](http://wacc.wisc.edu/documentation/EulerWalkthrough.pdf) 获得。您将使用 Fermi 卡之一（Tesla 2070/2050 或 GTX 480）。每一个都有 448 个 CUDA 核心（14 个 SM）。

随 CUDA 5.5 一起分发的是一个名为 `computeprof` 的应用程序，它可以很好地简洁地表示 NVidia GPU 上可用的性能计数器。要使用此程序，您需要使用 `@@ssh -X@@` 登录 Euler 集群以转发 X 服务器。然后您可以使用 `@@/usr/local/cuda/5.5.22/cuda/bin/computeprof@@` 运行它。我建议在校园里这样做，因为那里的带宽要高得多。您可以使用 `computeprof` 来诊断算法的每个实现的瓶颈。

## 附加信息
Dan Negrut 目前正在教授 GPU 计算课程 (ME964)。如果您需要作业的其他信息，您可以在他的课程网页上找到您需要的内容：<http://sbel.wisc.edu/Courses/ME964/2013/>
还有一个论坛，班上的学生可以在那里发布问题/答案。它在这里：
<http://sbel.wisc.edu/Forum/viewforum.php?f=15>

## 步骤 1：移植 CPU 算法
我已在 [模板文件]({$urlbase}/handouts/homeworks/hw4-dist.tgz) 中包含了 `@@ocean_kernel@@` 的此实现。您可以在 `cuda_ocean_kernels.cu` 中的 `@@#ifdef VERSION1@@` 之后找到它。虽然更加冗长，但这主要是 `omp_ocean.c` 中算法的字面翻译，采用 OpenMP 静态分区。每个线程获取红/黑海洋网格内的一块位置并更新这些位置。研究此代码并确保了解其工作原理。

* 问题 a) 描述 `memory` 分歧以及为什么会导致 SIMT 模型中代码性能不佳。
* 问题 b) 描述 `@@ocean_kernel@@` 的 `@@VERSION1@@` 的 `memory` 分歧行为。
* 问题 c) 改变块大小/网格大小。此 ocean 实现的最佳块/网格大小是多少？相对于 1 个块和 1 个线程（“单线程”）的加速比是多少？使用输入 `@@4098 4098 100@@` 运行。
* 问题 d) 相对于单线程 CPU 版本的加速比是多少？使用输入 `@@4098 4098 100@@` 运行。

## 步骤 2：减少内存分歧（将算法转换为 "SIMD"）
实现 `@@ocean_kernel@@` 的 `@@VERSION2@@`。此版本的内核将朝着减少内存分歧迈出一步。与其给每个线程一大块数组来处理，不如重写算法，使每个块中的线程处理相邻的元素。（即对于红色迭代，线程 0 将处理元素 0，线程 1 将处理元素 2，线程 3 将处理元素 6，等等）。

* 问题 a) 描述此 ocean 实现中仍然存在“内存”分歧的地方。
* 问题 b) 改变块大小/网格大小。此 ocean 实现的最佳块/网格大小是多少？
* 问题 c) 此版本与 VERSION1 相比如何？分别使用最佳块大小和输入 `@@4098 4098 100@@` 运行。

## 步骤 3：进一步减少内存分歧（修改数据结构以使其以 GPU 为中心）。
实现 `@@ocean_kernel@@` 的 `@@VERSION3@@`。与其使用一个平面数组来表示海洋网格，不如将其拆分为两个数组，一个用于红色单元格，一个用于黑色单元格。您应该首先编写另外两个内核，将网格对象拆分为 red_grid 和 black_grid，并将 red/black_grid 放回网格对象中。

如果您想冒险，请随时为此实现添加任何其他优化。只需在您的报告中描述它们即可。

* 问题 a) 此版本的性能与 VERSION2 相比如何？这是你所期望的吗？
* 问题 b) 分别对每个内核和内存复制进行计时（ocean_kernel 和 (un)split_array_kernel）。哪些动作花费最多的执行时间？这如何影响算法的整体执行时间？（`computeprof` 很好地总结了这些数据）
* 问题 c) 改变块大小/网格大小。此 ocean 实现的最佳块/网格大小是多少？当您更改问题大小时它会改变吗？
* 问题 d) 描述“分支”分歧以及为什么会导致 SIMT 模型中代码性能不佳。您的代码是否表现出任何分支分歧？如果是，在哪里？
* 问题 e) 鉴于 Euler 集群中的每个节点都有 2 个 Intel Xeon E5520 处理器，并且 GPU 具有 448 个 CUDA 核心 (GTX480/C2050/C2070)，您认为您的 GPU 版本与 CPU 版本相比性能如何？
* 问题 f) 运行您的 OpenMP 版本的 ocean 或模板文件中的版本。Ocean 的 CPU 版本与 GPU 版本相比性能如何，更好还是更差？您认为这是为什么？使用 omp_ocean.sh 提交 OpenMP 版本。使用问题大小 1026、2050、4098 和 8194 以及 100 个时间步长运行。
* 问题 g) 您对 CUDA 有什么看法？总体而言对 SIMT 编程有什么看法？



## 提示与技巧
* 尽早开始。
* 请注意，Dan Negrut 教授很友善地允许我们将他的计算资源用于此作业。

## 提交内容
请在讲座开始时以 **纸质** 形式提交此作业。您必须包括：
* 您的 GPU 内核的打印输出
* 所有问题的答案和支持图表。
**重要提示：** 在每一页上写上您的名字。
