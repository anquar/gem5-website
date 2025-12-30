---
layout: documentation
title: "简介"
doc: gem5 documentation
parent: ruby
permalink: /documentation/general_docs/ruby/
author: Jason Lowe-Power
---

# Ruby

Ruby 实现了内存子系统的详细模拟模型。它模拟包含/排斥缓存层次结构，具有各种替换策略、一致性协议实现、互连网络、DMA 和内存控制器、发起内存请求和处理响应的各种定序器。这些模型是模块化、灵活且高度可配置的。这些模型的三个关键方面是：

1.  关注点分离——例如，一致性协议规范与替换策略和缓存索引映射分离，网络拓扑与实现分离。
2.  丰富的可配置性——几乎可以控制影响内存层次结构功能和时序的任何方面。
3.  快速原型设计——使用高级规范语言 SLICC 来指定各种控制器的功能。

下图取自 ISCA 2005 的 GEMS 教程，显示了 Ruby 中主要组件的高级视图。
![ruby_overview.jpg](/assets/img/Ruby_overview.jpg)

有关基于教程的 Ruby 方法，请参阅 [Learning gem5 的第三部分](/documentation/learning_gem5/part3/)

### SLICC + 一致性协议：

***[SLICC](slicc)*** 代表 *Specification Language for Implementing Cache Coherence (用于实现缓存一致性的规范语言)*。它是一种用于指定缓存一致性协议的领域特定语言。本质上，缓存一致性协议的行为类似于状态机。SLICC 用于指定状态机的行为。由于目标是尽可能接近地模拟硬件，SLICC 对可以指定的状态机施加了约束。例如，SLICC 可以对单个周期内发生的转换数量施加限制。除了协议规范之外，SLICC 还将内存模型中的一些组件组合在一起。如下图所示，状态机从互连网络的输入端口获取输入，并在网络的输出端口对输出进行排队，从而将缓存/内存控制器与互连网络本身联系起来。

![slicc_overview.jpg](/assets/img/Slicc_overview.jpg)

支持以下缓存一致性协议：

1.  **[MI_example](MI_example)**: 示例协议，1 级缓存。
2.  **[MESI_Two_Level](MESI_Two_Level)**: 单芯片，2 级缓存，严格包含层次结构。
3.  **[MOESI_CMP_directory](MOESI_CMP_directory)**:
    多芯片，2 级缓存，非包含（既非严格包含也非排斥）层次结构。
4.  **[MOESI_CMP_token](MOESI_CMP_token)**: 2 级缓存。
    TODO.
5.  **[MOESI_hammer](MOESI_hammer)**: 单芯片，2 级私有缓存，严格排斥层次结构。
6.  **[Garnet_standalone](Garnet_standalone)**: 以独立方式运行 Garnet 网络的协议。
7.  **MESI Three Level**: 3 级缓存，严格包含层次结构。基于 MESI Two Level，带有额外的 L0 缓存。
8.  **[CHI](CHI)**: 实现 Arm AMBA5 CHI 事务的灵活协议。支持具有 MESI 或 MOESI 一致性的可配置缓存层次结构。

协议中常用的符号和数据结构已在 [这里](cache-coherence-protocols) 详细描述。

### 协议无关的内存组件

1.  **Sequencer (定序器)**
2.  **Cache Memory (缓存内存)**
3.  **Replacement Policies (替换策略)**
4.  **Memory Controller (内存控制器)**

通常，缓存一致性协议无关组件包括定序器、缓存内存结构、缓存替换策略和内存控制器。Sequencer 类负责向内存子系统（包括缓存和片外内存）提供来自处理器的加载/存储/原子内存请求。每个内存请求在内存子系统完成时也会通过 Sequencer 向处理器发回响应。系统中模拟的每个硬件线程（或核心）都有一个 Sequencer。Cache Memory 模拟具有可参数化大小、关联性、替换策略的组相联缓存结构。系统中的 L1、L2、L3 缓存（如果存在）是 Cache Memory 的实例。Cache Replacement 策略与 Cache Memory 保持模块化，以便 Cache Memory 的不同实例可以使用它们选择的不同替换策略。目前随版本分发了两种替换策略——LRU 和 Pseudo-LRU。Memory Controller 负责模拟和处理任何在模拟系统的所有片上缓存上未命中的请求。Memory Controller 目前很简单，但忠实地模拟了 DRAM bank 争用、DRAM 刷新。它还模拟了 DRAM 缓冲区的 close-page 策略。

### 互连网络

互连网络将内存层次结构的各种组件（缓存、内存、dma 控制器）连接在一起。

![Interconnection_network.jpg](/assets/img/Interconnection_network.jpg
"Interconnection_network.jpg")

互连网络的关键组件是：

1.  **Topology (拓扑)**
2.  **Routing (路由)**
3.  **Flow Control (流控制)**
4.  **Router Microarchitecture (路由器微架构)**

***有关网络模型实现的更多详细信息，请参见 [这里](Interconnection_Network)。***

或者，互连网络可以用外部模拟器 [TOPAZ](https://github.com/ceunican/tpzsimul) 替换。该模拟器已准备好在 gem5 中运行，并增加了大量功能
超过原始的 ruby 网络模拟器。它包括新的高级路由器微架构、新拓扑、精度-性能可调的路由器模型、加速网络模拟的机制等。

## Ruby 中内存请求的生命周期

在本节中，我们将提供一个关于内存请求如何由 Ruby 作为一个整体提供服务以及它经过 Ruby 中的哪些组件的高级概述。有关每个组件内的详细操作，请参阅描述每个单独组件的先前部分。

1.  来自 gem5 核心或硬件上下文的内存请求通过 ***RubyPort::recvTiming*** 接口（在 src/mem/ruby/system/RubyPort.hh/cc 中）进入 Ruby 的管辖范围。模拟系统中 Rubyport 实例化的数量等于硬件线程上下文或核心的数量（在 *非多线程* 核心的情况下）。每个核心侧面的端口都绑定到相应的 RubyPort。
2.  内存请求作为 gem5 数据包到达，RubyPort 负责将其转换为 Ruby 的各种组件可以理解的 RubyRequest 对象。它还会查明请求是否针对某个 PIO，并将数据包操纵到正确的 PIO。最后，一旦它生成了相应的 RubyRequest 对象并确定该请求是 *正常* 内存请求（不是 PIO 访问），它就会将请求传递给附加的 Sequencer 对象的 ***Sequencer::makeRequest*** 接口（变量 *ruby_port* 持有指向它的指针）。请注意，Sequencer 类本身是 RubyPort 类的派生类。
3.  如描述 Ruby 的 Sequencer 类部分所述，模拟系统中的 Sequencer 对象数量与硬件线程上下文的数量一样多（这也等于系统中 RubyPort 对象的数量），并且 Sequencer 对象与硬件线程上下文之间存在一一对应关系。一旦内存请求到达 ***Sequencer::makeRequest***，它就会对请求进行各种记账和资源分配，最后将请求推送到 Ruby 的一致性缓存层次结构以满足请求，同时考虑服务该请求的延迟。请求通过在考虑 L1 缓存访问延迟后将请求入队到 *mandatory queue* 来推送到 Cache 层次结构。*mandatory queue*（变量名 *m_mandatory_q_ptr*）实际上充当 Sequencer 和 SLICC 生成的缓存一致性文件之间的接口。
4.  L1 缓存控制器（由 SLICC 根据一致性协议规范生成）从 *mandatory queue* 中出队请求并查找缓存，进行必要的一致性状态转换和/或根据要求将请求推送到下一级缓存层次结构。SLICC 生成的 Ruby 代码的不同控制器和组件通过 Ruby 的 *MessageBuffer* 类（src/mem/ruby/buffers/MessageBuffer.cc/hh）的实例化相互通信，该类可以充当有序或无序缓冲区或队列。此外，服务满足内存请求的不同步骤的延迟也会被考虑在内，以便相应地调度入队和出队操作。如果请求的缓存块可以在具有所需一致性权限的 L1 缓存中找到，则满足请求并立即返回。否则，请求通过 *MessageBuffer* 推送到下一级缓存层次结构。请求可以一直到达 Ruby 的内存控制器（在许多协议中也称为目录）。一旦请求得到满足，它就会通过 *MessageBuffer* 向上推送到层次结构中。
5.  *MessageBuffers* 也充当一致性消息进入建模的片上互连的入口点。MesageBuffers 根据指定的互连拓扑连接。因此，一致性消息相应地通过此片上互连传输。
6.  一旦请求的缓存块在 L1 缓存中具有所需的一致性权限可用，L1 缓存控制器就会通过调用其 ***readCallback*** 或 **'writeCallback**'' 方法（取决于请求的类型）来通知相应的 Sequencer 对象。请注意，在 Sequencer 上调用这些方法时，服务请求的延迟已被隐式考虑在内。
7.  然后，Sequencer 清除相应请求的记账信息，然后调用 ***RubyPort::ruby_hit_callback*** 方法。这最终将请求的结果返回给前端 (gem5) 的核心/硬件上下文的相应端口。

## 目录结构

  - **src/mem/**
      - **protocols**: 一致性协议的 SLICC 规范
      - **slicc**: SLICC 解析器和代码生成器的实现
      - **ruby**
          - **common**: 常用数据结构，例如 Address（带位操作方法）、直方图、数据块
          - **filters**: 各种 Bloom 过滤器（来自 GEMS 的陈旧代码）
          - **network**: 互连实现、示例拓扑规范、网络功耗计算、用于连接控制器的消息缓冲区
          - **profiler**: 缓存事件、内存控制器事件的分析
          - **recorder**: 缓存预热和访问跟踪记录
          - **slicc_interface**: 消息数据结构、各种映射（例如地址到目录节点）、实用函数（例如地址与 int 之间的转换、将地址转换为缓存行地址）
          - **structures**: 协议无关的内存组件 – CacheMemory, DirectoryMemory
          - **system**: 胶水组件 – Sequencer, RubyPort, RubySystem
