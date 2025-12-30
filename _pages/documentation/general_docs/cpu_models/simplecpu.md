---
layout: documentation
title: Simple CPU 模型
doc: gem5 documentation
parent: cpu_models
permalink: /documentation/general_docs/cpu_models/SimpleCPU
---
# **SimpleCPU**
SimpleCPU 是一个纯粹的功能性、按序模型，适用于不需要详细模型的场景。这可能包括预热期、驱动主机的客户端系统，或者只是测试程序是否正常工作。

它最近经过重写以支持新的内存系统，现在分为三个类：

**目录**

  1. [**BaseSimpleCPU**](#basesimplecpu)
  2. [**AtomicSimpleCPU**](#atomicsimplecpu)
  3. [**TimingSimpleCPU**](#timingsimplecpu)

## **BaseSimpleCPU**
BaseSimpleCPU 有几个用途：
  * 保存架构状态，以及 SimpleCPU 模型之间通用的统计信息。
  * 定义用于检查中断、设置取指请求、处理执行前设置、处理执行后操作以及将 PC 推进到下一条指令的函数。这些函数在 SimpleCPU 模型之间也是通用的。
  * 实现 ExecContext 接口。

BaseSimpleCPU 不能单独运行。您必须使用继承自 BaseSimpleCPU 的类之一，即 AtomicSimpleCPU 或 TimingSimpleCPU。

## **AtomicSimpleCPU**
AtomicSimpleCPU 是使用原子内存访问的 SimpleCPU 版本（有关详细信息，请参阅 [内存系统](../memory_system/index.html#access-types)）。它使用原子访问的延迟估计来估计整体缓存访问时间。AtomicSimpleCPU 派生自 BaseSimpleCPU，并实现了读写内存的函数，以及 tick 函数，它定义了每个 CPU 周期发生的事情。它定义了用于连接到内存的端口，并将 CPU 连接到缓存。

![AtomicSimpleCPU](/assets/img/AtomicSimpleCPU.jpg)

## **TimingSimpleCPU**
TimingSimpleCPU 是使用时序内存访问的 SimpleCPU 版本（有关详细信息，请参阅 [内存系统](../memory_system/index.html#access-types)）。它在缓存访问时停顿，并在继续之前等待内存系统响应。像 AtomicSimpleCPU 一样，TimingSimpleCPU 也派生自 BaseSimpleCPU，并实现了相同的一组函数。它定义了用于连接到内存的端口，并将 CPU 连接到缓存。它还定义了处理从内存发出的访问响应的必要函数。

![TimingSimpleCPU](/assets/img/TimingSimpleCPU.jpg)
