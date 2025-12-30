---
layout: documentation
title: "HeteroGarnet (Garnet 3.0)"
doc: gem5 documentation
parent: ruby
permalink: /documentation/general_docs/ruby/heterogarnet/
author: Srikant Bharadwaj
---

**gem5 Ruby 互连网络的更多详细信息在 [这里](/documentation/general_docs/ruby/interconnection-network "wikilink")。**
**有关早期 Garnet 版本的详细信息可以在 [这里](/documentation/general_docs/ruby/garnet-2 "wikilink") 找到。**

### HeteroGarnet: 用于多样化互连系统的详细模拟器
[HeteroGarnet](https://doi.org/10.1109/DAC18072.2020.9218539) 通过启用对新兴互连系统的精确模拟，改进了广受欢迎的 Garnet 2.0 网络模型。具体来说，HeteroGarnet 增加了对时钟域岛、支持多个频率域的网络交叉以及能够连接到多个物理链路的网络接口控制器的支持。它还通过引入新的可配置串行器-解串器 (Serializer-Deserializer) 组件来支持可变带宽链路和路由器。HeteroGarnet 作为 Garnet 3.0 集成到 gem5 仓库中。

HeteroGarnet 建立在最初的 Garnet 模型之上，该模型发布于 [2009 年](https://doi.org/10.1109/ISPASS.2009.4919636)。

如果您对 HeteroGarnet 的使用有助于发表论文，请引用以下论文：

```
    @inproceedings{heterogarnet,
        author={Bharadwaj, Srikant and Yin, Jieming and Beckmann, Bradford and Krishna, Tushar},
        booktitle={2020 57th ACM/IEEE Design Automation Conference (DAC)},
        title={Kite: A Family of Heterogeneous Interposer Topologies Enabled via Accurate Interconnect Modeling},
        year={2020},
        volume={},
        number={},
        pages={1-6},
        doi={10.1109/DAC18072.2020.9218539}
	}
```

## 拓扑构建
HeteroGarnet 允许用户使用 python 配置文件作为拓扑来配置复杂的拓扑。
整体拓扑配置可以包括系统的完整互连定义，包括任何异构组件。定义拓扑的一般流程涉及以下步骤：

1. 确定系统中的路由器总数并实例化它们。
    1. 使用 **Router** 类实例化单个路由器。
    2. 根据要求配置每个路由器的属性，例如时钟域、支持的 flit 宽度。
```
routers = Router(id, latency, clock_domain,
                flit_width, supported_vnets,
                vcs_per_vnet)
```

2. 使用外部物理互连连接连接到端点（例如，核心、缓存、目录）的路由器。
    1. 使用 **ExternalLink** 类实例化连接端点的链路。
    2. 根据要求配置每个外部链路的属性，例如时钟域、链路宽度。
    3. 根据互连拓扑，在任一端启用时钟域交叉 (CDC) 和串行器-解串器 (SerDes) 单元。
```
external_link = ExternalLink(id, latency, clock_domain,
                             flit_width, supported_vnets,
                             serdes_enable, cdc_enable)
````

3. 根据拓扑连接网络内的各个路由器。
    1. 使用 **InternalLink** 类实例化连接端点的链路。
    2. 根据要求配置每个内部链路的属性，例如时钟域、链路宽度。
    3. 根据互连拓扑，在任一端启用时钟域交叉和串行器-解串器单元。
```
internal_link = InternalLink(id, latency, clock_domain,
                             flit_width, supported_vnets,
                             serdes_enable, cdc_enable)
```

Garnet 3.0 还提供了几个预配置脚本 (./configs/Network/Network.py)，它们会自动执行其他一些步骤，例如实例化网络接口、域交叉和 SerDes 单元。下面讨论用于配置拓扑的几种类型的单元。


## 物理链路
Garnet 中的物理链路模型代表互连线本身。链路是具有自己的延迟、宽度和它可以传输的 flit 类型的单一实体。链路还支持基于信用的背压机制。类似于升级后的 Garnet 3.0 路由器，每个 Garnet 3.0 链路都可以使用适当的参数配置为操作频率和宽度。这允许连接以不同频率运行的链路和路由器。

## 网络接口
网络接口控制器 (NIC) 是位于网络端点（例如，缓存、DMA 节点）和互连系统之间的对象。NIC 接收来自控制器的消息并将它们转换为固定长度的 flits，即流控制单元的简称。这些 flits 根据传出的物理链路适当调整大小。网络接口还管理传出和传入 flits 的流控制和缓冲区管理。Garnet 3.0 允许将多个端口连接到单个端点。因此，NIC 决定必须在哪里调度某个消息/flit。

## 时钟域交叉单元
为了支持多个时钟域，Garnet 3.0 引入了时钟域交叉 (CDC) 单元，如下图（左）所示，它由先进先出 (FIFO) 缓冲区组成，可以在网络模型的任何位置实例化。CDC 单元支持整个系统具有不同时钟域的架构。每个 CDC 单元的延迟是可配置的。延迟也可以根据连接到它的时钟域动态计算。这实现了 DVFS 技术的精确建模，因为 CDC 延迟通常是生产者和消费者工作频率的函数。

## 串行器-解串器单元
建模 SoC 和异构架构所需的另一个关键功能是支持整个系统的各种互连宽度。考虑 GPU 内两个路由器之间的链路和内存控制器与片上存储器之间的链路。这两条链路的宽度可能不同。为了启用这种配置，Garnet 3.0 引入了如下图所示的串行器-解串器单元，它在位宽边界处将 flit 转换为适当的宽度。这些 SerDes 单元可以在 Garnet 3.0 拓扑中的任何位置实例化，类似于上一小节中描述的 CDC 单元。

![SerDes_CDC.png](/assets/img/SerDes_CDC.png)

## 路由
路由算法决定 flits 如何通过拓扑传播。路由策略的目标是在最大化互连提供的带宽的同时最小化争用。Garnet 3.0 提供了几种标准路由策略供用户选择。

### 路由策略。
已经提出了几种通用的路由策略，用于通过互连网络进行无死锁的 flit 路由。

### 基于表的路由
Garnet 还具有基于表的路由策略，用户可以选择该策略以使用基于权重的系统设置自定义路由策略。权重较低的链路优于配置为具有较高权重的链路。



## 流控制和缓冲区管理

流控制机制决定互连系统中的缓冲区分配。良好的流控制系统的目标是最小化缓冲区分配对系统中消息整体延迟的影响。这些机制的实施通常涉及互连系统内物理数据包的微观管理。

缓存控制器生成的一致性消息通常分解为固定长度的 flit（流控制单元）。一组携带消息的 flit 通常被称为数据包。数据包可以具有头 flit、体 flit 和尾 flit 来携带消息的内容以及数据包本身的任何其他元数据。已经提出了几种流控制技术，并在各种资源分配粒度上实施。

Garnet 3.0 实现了一种基于信用的 flit 级流控制机制，支持虚拟通道。

### 虚拟通道
网络中的虚拟通道 (VC) 充当单独的队列，可以共享两个路由器或仲裁器之间的物理线（物理链路）。虚拟通道主要用于缓解队头阻塞。但是，它们也被用作避免死锁的手段。

### 缓冲区背压
大多数互连网络的实现不容忍在传输过程中丢弃数据包或 flit。因此，需要使用背压机制严格管理 flit。

### 基于信用的背压
基于信用的背压机制通常用于 flit 停顿的低延迟实现。信用通过在每次发送 flit 时递减总缓冲区来跟踪下一个中间目的地可用的缓冲区数量。当目的地被腾空时，信用会被发送回来。

互连系统中的路由器执行网络内的仲裁、缓冲区分配和流控制。路由器微架构的目标是最小化路由器内的争用，同时为 flit 提供最小的每跳延迟。路由器微架构的复杂性也影响互连系统的整体能量和面积消耗。


## Garnet 3.0 中消息的生命周期
在本节中，我们描述消息在由缓存控制器单元生成后在 NoC 中的生命周期。我们以 Garnet 3.0 为例来描述该过程，但一般的建模原则也可以扩展到其他软件模拟/建模工具。

![HeteroGarnet_Life.png](/assets/img/HeteroGarnet_Life.png)

系统的总体流程在上图中详细显示。它显示了一个简单的示例场景，其中缓存控制器生成一条消息，该消息注定要发送到另一个缓存控制器，该缓存控制器通过路由器经由物理链路、串行器-解串器单元和时钟域交叉连接。

### 消息注入
源缓存控制器创建一条消息并将一个或多个缓存控制器指定为目的地。然后将此消息注入消息队列。缓存控制器通常有几个用于不同类型消息的传出和传入消息缓冲区。

### 转换为 Flit。
网络接口控制器单元 (NIC) 连接到每个缓存控制器。此 NIC 唤醒并使用消息队列中的消息。然后将每条消息转换为单播消息，然后根据传出物理链路支持的大小分解为固定长度的 flit。然后根据下一跳缓冲区的可用性通过输出链路之一调度这些 flit 进行传输。根据目的地、路由策略和消息类型选择传出链路。

### 传输到本地路由器。
每个网络接口都连接到一个或多个“本地”路由器，这些路由器可以通过“外部”链路连接。一旦安排了 flit，它就会通过这些外部链路传输，这些链路在定义的延迟期后将 flit 传递给路由器。

### 路由器仲裁。
flit 唤醒路由器，路由器是一个多级单元。路由器包含输入缓冲区、VC 分配、交换机仲裁和交叉开关单元。到达时，flit 首先放入输入缓冲区队列。路由器中有几个输入缓冲区队列争夺下一跳的输出链路和 VC。这是使用 VC 分配和交换机仲裁阶段完成的。一旦选择 flit 进行传输，交叉开关阶段就会将 flit 定向到输出链路。随着输入缓冲区空间腾出供下一个 flit 到达，信用随后被发送回 NIC。

### 序列化-反序列化。
序列化-反序列化 (SerDes) 是一个可选单元，可以根据设计要求启用。SerDes 单元消耗 flit 并将其适当地转换为传出 flit 大小。除了处理数据包外，SerDes 还通过序列化或反序列化信用单元来处理信用系统。


## 面积、功率和能量模型
Orion2.0 和 DSENT 等框架为 NoC 路由器和链路的各种构建块提供了面积和功率模型。HeteroGarnet 集成 DSENT 作为外部工具，以在模拟结束时报告面积、功率和能量（取决于活动）。
