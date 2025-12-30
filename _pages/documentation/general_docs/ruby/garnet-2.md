---
layout: documentation
title: "Garnet 2.0"
doc: gem5 documentation
parent: ruby
permalink: /documentation/general_docs/ruby/garnet-2/
author: Jason Lowe-Power
---

**gem5 Ruby 互连网络的更多详细信息在 [这里](/documentation/general_docs/ruby/interconnection-network/)。**

### Garnet2.0: 用于异构 SoC 的片上网络模型

Garnet2.0 是 gem5 内部的一个详细互连网络模型。它正在积极开发中，更多功能的补丁将定期推送到 gem5。**正在开发的（不属于 repo 的）其他 garnet 相关补丁和工具支持可以在 [佐治亚理工学院的 Garnet 页面](http://synergy.ece.gatech.edu/tools/garnet) 找到**。

Garnet2.0 建立在最初的 Garnet 模型之上，该模型发布于 [2009 年](http://ieeexplore.ieee.org/xpls/abs_all.jsp?arnumber=4919636%7CISPASS)。

如果您对 Garnet 的使用有助于发表论文，请引用以下论文：

```
    @inproceedings{garnet,
      title={GARNET: A detailed on-chip network model inside a full-system simulator},
      author={Agarwal, Niket and Krishna, Tushar and Peh, Li-Shiuan and Jha, Niraj K},
      booktitle={Performance Analysis of Systems and Software, 2009. ISPASS 2009. IEEE International Symposium on},
      pages={33--42},
      year={2009},
      organization={IEEE}
    }
```

Garnet2.0 提供了一个片上网络路由器的周期精确微架构实现。它利用了 gem5 的 ruby 内存系统模型提供的 [拓扑](/documentation/general_docs/ruby/interconnection-network#Topology) 和 [路由](/documentation/general_docs/ruby/interconnection-network#Routing) 基础设施。默认路由器是最先进的 1 周期流水线。支持通过在拓扑中指定，在任何路由器中添加任意周期数的额外延迟。

Garnet2.0 也可以通过在路由器和链路中设置适当的延迟来模拟片外互连网络。

- **相关文件**:
  - **src/mem/ruby/network/Network.py**
  - **src/mem/ruby/network/garnet2.0/GarnetNetwork.py**
  - **src/mem/ruby/network/Topology.cc**

## 调用

可以通过添加 **--network=garnet2.0** 来启用 garnet 网络。

## 配置

Garnet2.0 使用 Network.py 中的通用网络参数：

- **number_of_virtual_networks**: 这是最大虚拟网络数。实际活动的虚拟网络数由协议决定。
- **control_msg_size**: 控制消息的大小（以字节为单位）。默认为 8。Network.cc 中的 **m_data_msg_size** 设置为块大小（以字节为单位）+ control_msg_size。

其他参数在 garnet2.0/GarnetNetwork.py 中指定：

- **ni_flit_size**: flit 大小（以字节为单位）。Flits 是信息从一个路由器发送到另一个路由器的粒度。默认为 16 (=\> 128 位)。\[此默认值 16 导致控制消息适合 1 个 flit，数据消息适合 5 个 flit\]。Garnet 要求 ni_flit_size 与 bandwidth_factor (在 network/BasicLink.py 中) 相同，因为它不模拟网络内的可变带宽。这也可以通过 **--link-width-bits** 从命令行设置。
- **vcs_per_vnet**: 每个虚拟网络的虚拟通道 (VC) 数。默认为 4。这也可以通过 **--vcs-per-vnet** 从命令行设置。
- **buffers_per_data_vc**: 数据消息类中每个 VC 的 flit 缓冲区数。由于数据消息占用 5 个 flit，此值可以在 1-5 之间。默认为 4。
- **buffers_per_ctrl_vc**: 控制消息类中每个 VC 的 flit 缓冲区数。由于控制消息占用 1 个 flit，并且 VC 一次只能保存一条消息，因此此值必须为 1。默认为 1。
- **routing_algorithm**: 0: 基于权重的表（默认），1: XY，2: 自定义。更多详情如下。

## 拓扑

Garnet2.0 利用 gem5 的 ruby 内存系统模型提供的 [拓扑](/documentation/general_docs/ruby/interconnection-network#Topology) 基础设施。可以模拟任何异构拓扑。拓扑文件中的每个路由器都可以给定一个独立的延迟，覆盖默认值。此外，每个链路有 2 个可选参数：src_outport 和 dst_inport，它们是包含每个链路的源路由器和目标路由器的输出和输入端口名称的字符串。这些可以在 garnet2.0 内部用于实现自定义路由算法，如下所述。例如，在 Mesh 中，西向东的链路将 src_outport 设置为 "west"，将 dst_inport 设置为 "east"。

- **网络组件**:
    - **GarnetNetwork**: 这是实例化所有网络接口、路由器和链路的顶层对象。Topology.cc 调用方法在 NI 和路由器之间添加“外部链路”，在路由器之间添加“内部链路”。
    - **NetworkInterface**: 每个 NI 一端通过 MsgBuffer 接口连接到一个一致性控制器。另一端有一个连接到路由器的链路。每个协议消息都被放入一个一 flit 控制或多（默认=5）flit 数据（取决于其 vnet），并注入到路由器中。多个 NI 可以连接到同一个路由器（例如，在 Mesh 拓扑中，缓存和目录控制器通过单独的 NI 连接到同一个路由器）。
    - **Router**: 路由器管理输出链路的仲裁，以及路由器之间的流控制。
    - **NetworkLink**: 网络链路携带 flits。它们可以是 3 种类型之一：EXT_OUT_ (路由器到 NI)，EXT_IN_ (NI 到路由器)，和 INT_ (内部路由器到路由器)
    - **CreditLink**: 信用链路在路由器之间携带 VC/缓冲区信用以进行流控制。

## 路由

Garnet2.0 利用 gem5 的 ruby 内存系统模型提供的 [路由](/documentation/general_docs/ruby/interconnection-network#Routing) 基础设施。默认路由算法是具有最短路径的确定性基于表的路由算法。链路权重可用于优先选择某些链路而不是其他链路。有关路由表如何填充的详细信息，请参见 src/mem/ruby/network/Topology.cc。

**自定义路由**: 为了模拟自定义路由算法（比如自适应算法），我们提供了一个框架，用 src_outport 和 dst_inport 方向命名每个链路，并在 garnet 内部使用这些来实现路由算法。例如，在 Mesh 中，West-first 可以通过沿着“西”输出端口链路发送 flit 来实现，直到 flit 不再有任何 X- 跳数剩余，然后随机（或基于下一个路由器 VC 可用性）选择剩余链路之一。参见 src/mem/ruby/network/garnet2.0/RoutingUnit.cc 中 outportComputeXY() 是如何实现的。类似地，可以实现 outportComputeCustom()，并通过在命令行中添加 --routing-algorithm=2 来调用。

**组播消息**: 模拟的网络在网络内部没有硬件多播支持。多播消息在网络接口处被分解为多个单播消息。

## 流控制

设计中使用了虚拟通道流控制。每个 VC 可以容纳一个数据包。设计中有两种 VC - 控制和数据。每个中的缓冲区深度可以从 GarnetNetwork.py 独立控制。默认值是 1-flit 深的控制 VC，和 4-flit 深的数据 VC。控制数据包的默认大小是 1-flit，数据数据包是 5-flit。

## 路由器微架构

garnet2.0 路由器执行以下操作：

1.  **缓冲区写入 (BW)**: 传入的 flit 被缓冲在其 VC 中。
2.  **路由计算 (RC)** 缓冲的 flit 计算其输出端口，此信息存储在其 VC 中。
3.  **交换机分配 (SA)**: 所有缓冲的 flit 尝试为下一个周期预留交换机端口。\[分配以 *可分离* 的方式发生：首先，每个输入使用输入仲裁器选择一个放置交换机请求的输入 VC。然后，每个输出端口通过输出仲裁器解决冲突\]。有序虚拟网络中的所有仲裁器都是 *排队* 的，以维持点对点排序。所有其他仲裁器都是 *轮询* 的。
4.  **VC 选择 (VS)**: SA 的获胜者从其输出端口选择一个空闲 VC（如果是 HEAD/HEAD_TAIL flit）。
5.  **交换机遍历 (ST)**: 赢得 SA 的 flit 遍历交叉开关交换机。
6.  **链路遍历 (LT)**: 来自交叉开关的 flit 遍历链路以到达下一个路由器。

在默认设计中，BW、RC、SA、VS 和 ST 都发生在 1 个周期内。LT 发生在下一个周期。

**多周期路由器**: 可以通过在拓扑文件中指定每个路由器的延迟，或更改 src/mem/ruby/network/BasicRouter.py 中的默认路由器延迟来模拟多周期路由器。这是通过使缓冲的 flit 在路由器中等待 (latency-1) 个周期才有资格进行 SA 来实现的。

## 缓冲区管理

每个路由器输入端口有 number_of_virtual_networks 个 Vnet，每个 Vnet 有 vcs_per_vnet 个 VC。控制 Vnet 中的 VC 深度为 buffers_per_ctrl_vc (默认 = 1)，数据 Vnet 中的 VC 深度为 buffers_per_data_vc (默认 = 4)。**信用用于传递有关空闲 VC 和每个 VC 内缓冲区数量的信息。**

## 网络遍历的生命周期

  - NetworkInterface.cc::wakeup()
      - 每个 NI 一端连接到一个一致性协议控制器，另一端连接到一个路由器。
      - 接收来自一致性协议缓冲区的消息（在适当的 vnet 中），将其转换为网络数据包并发送到网络中。
          - garnet2.0 添加了此时捕获网络跟踪的能力 \[开发中\]。
      - 从网络接收 flit，提取协议消息并将其发送到适当 vnet 中的一致性协议缓冲区。
      - 管理与其连接的路由器的流控制（即信用）。
      - NI 的消费 flit/信用输出链路被放入全局事件队列，时间戳设置为下一个周期。事件队列调用消费者中的 wakeup 函数。

<!-- end list -->

  - NetworkLink.cc::wakeup()
      - 从 NI/路由器接收 flit 并在 m_latency 周期延迟后将其发送到 NI/路由器
      - 每个链路的默认延迟值可以从命令行设置（参见 configs/network/Network.py）
      - 每个链路的延迟可以在拓扑文件中覆盖
      - 链路的消费者（NI/路由器）被放入全局事件队列，时间戳设置为 m_latency 周期后。事件队列调用消费者中的 wakeup 函数。

<!-- end list -->

  - Router.cc::wakeup()
      - 循环遍历所有 InputUnits 并调用其 wakeup()
      - 循环遍历所有 OutputUnits 并调用其 wakeup()
      - 调用 SwitchAllocator 的 wakeup()
      - 调用 CrossbarSwitch 的 wakeup()
      - 只要路由器的任何模块（InputUnit、OutputUnit、SwitchAllocator、CrossbarSwitch）在此周期有准备好的 flit/信用可操作，就会调用路由器的 wakeup 函数。

<!-- end list -->

  - InputUnit.cc::wakeup()
      - 如果在本周期准备就绪，则从上游路由器读取输入 flit
      - 对于 HEAD/HEAD_TAIL flit，执行路由计算，并更新 VC 中的路由。
      - 缓冲 flit (m_latency - 1) 个周期，并标记为从该周期开始对 SwitchAllocation 有效。
          - 每个路由器的默认延迟可以从命令行设置（参见 configs/network/Network.py）
          - 每个路由器的延迟（即流水线级数）可以在拓扑文件中设置。

<!-- end list -->

  - OutputUnit.cc::wakeup()
      - 如果在本周期准备就绪，则从下游路由器读取输入信用
      - 增加适当输出 VC 状态的信用。
      - 如果信用携带 is_free_signal 为 true，则将输出 VC 标记为空闲

<!-- end list -->

  - SwitchAllocator.cc::wakeup()
      - 注意：SwitchAllocator 在其内部执行 VC 仲裁和选择。
      - SA-I (或 SA-i): 循环遍历每个输入端口的所有输入 VC，并以轮询方式选择一个。
          - 对于 HEAD/HEAD_TAIL flit，仅选择其输出端口具有至少一个空闲输出 VC 的输入 VC。
          - 对于 BODY/TAIL flit，仅选择在其输出 VC 中有信用的输入 VC。
      - 从此 VC 发出输出端口请求。
      - SA-II (或 SA-o): 循环遍历所有输出端口，并以轮询方式选择一个输入 VC（在 SA-I 期间发出请求的）作为此输出端口的获胜者。
          - 对于 HEAD/HEAD_TAIL flit，执行 outvc 分配（即，从输出端口选择一个空闲 VC。
          - 对于 BODY/TAIL flit，减少输出 vc 中的信用。
      - 从输入 VC 读出 flit，并将其发送到 CrossbarSwitch
      - 为此输入 VC 向由上游路由器发送 increment_credit 信号。
          - 对于 HEAD_TAIL/TAIL flit，在信用中将 is_free_signal 标记为 true。
          - 输入单元通过信用链路将信用发送到上游路由器。
      - 重新调度 Router 在下一个周期唤醒，以处理下一个周期准备好进行 SA 的任何 flit。

<!-- end list -->

  - CrossbarSwitch.cc::wakeup()
      - 循环遍历所有输入端口，并将获胜的 flit 从其输出端口发送到输出链路上。
      - 路由器的消费 flit 输出链路被放入全局事件队列，时间戳设置为下一个周期。事件队列调用消费者中的 wakeup 函数。

<!-- end list -->

  - NetworkLink.cc::wakeup()
      - 从 NI/路由器接收 flit 并在 m_latency 周期延迟后将其发送到 NI/路由器
      - 每个链路的默认延迟值可以从命令行设置（参见 configs/network/Network.py）
      - 每个链路的延迟可以在拓扑文件中覆盖
      - 链路的消费者（NI/路由器）被放入全局事件队列，时间戳设置为 m_latency 周期后。事件队列调用消费者中的 wakeup 函数。

## 使用合成流量运行 Garnet2.0

Garnet2.0 可以以独立方式运行并馈送合成流量。详细信息在此处描述：**[Garnet 合成流量](/documentation/general_docs/ruby/garnet_synthetic_traffic)**
