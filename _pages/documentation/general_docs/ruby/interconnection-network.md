---
layout: documentation
title: "互连网络"
doc: gem5 documentation
parent: ruby
permalink: /documentation/general_docs/ruby/interconnection-network/
author: Jason Lowe-Power
---

# 互连网络

此处描述了 gem5 ruby 内存系统内部互连网络模型的各个组件。

## 如何调用网络

**简单网络 (Simple Network)**:

```
./build/<ISA>/gem5.debug \
                      configs/example/ruby_random_test.py \
                      --num-cpus=16  \
                      --num-dirs=16  \
                      --network=simple
                      --topology=Mesh_XY  \
                      --mesh-rows=4
```

默认网络是 simple，默认拓扑是 crossbar。

**Garnet 网络**:

```
./build/<ISA>/gem5.debug \
                      configs/example/ruby_random_test.py  \
                      --num-cpus=16 \
                      --num-dirs=16  \
                      --network=garnet2.0 \
                      --topology=Mesh_XY \
                      --mesh-rows=4
```

## 拓扑

各种控制器之间的连接通过 python 文件指定。所有外部链路（控制器和路由器之间）都是双向的。所有内部链路（路由器之间）都是单向的——这允许每个链路上的每个方向权重来偏置路由决策。

- **相关文件**:
    - **src/mem/ruby/network/topologies/Crossbar.py**
    - **src/mem/ruby/network/topologies/CrossbarGarnet.py**
    - **src/mem/ruby/network/topologies/Mesh_XY.py**
    - **src/mem/ruby/network/topologies/Mesh_westfirst.py**
    - **src/mem/ruby/network/topologies/MeshDirCorners_XY.py**
    - **src/mem/ruby/network/topologies/Pt2Pt.py**
    - **src/mem/ruby/network/Network.py**
    - **src/mem/ruby/network/BasicLink.py**
    - **src/mem/ruby/network/BasicRouter.py**



- **拓扑描述**:
  - **Crossbar**: 每个控制器 (L1/L2/Directory) 连接到一个简单的交换机。每个交换机连接到一个中央交换机（模拟交叉开关）。这可以通过 **--topology=Crossbar** 从命令行调用。
  - **CrossbarGarnet**: 每个控制器 (L1/L2/Directory) 通过一个 garnet 路由器（内部模拟交叉开关和分配器）连接到每个其他控制器。这可以通过 **--topology=CrossbarGarnet** 从命令行调用。
  - **Mesh_\***: 此拓扑要求目录数等于 cpu 数。路由器/交换机的数量等于系统中的 cpu 数。每个路由器/交换机连接到一个 L1、一个 L2（如果存在）和一个 Directory。网格中的行数 **必须由 --mesh-rows 指定**。此参数也允许创建非对称网格。
      - **Mesh_XY**: 具有 XY 路由的网格。所有 x 方向链路的权重为 1，而所有 y 方向链路的权重为 2。这强制所有消息在使用 Y 链路之前先使用 X 链路。它可以由 **--topology=Mesh_XY** 从命令行调用
      - **Mesh_westfirst**: 具有西优先路由的网格。所有西向链路的权重为 1，所有其他链路的权重为 2。这强制所有消息在使用其他链路之前先使用西向链路。它可以由 **--topology=Mesh_westfirst** 从命令行调用
  - **MeshDirCorners_XY**: 此拓扑要求目录数等于 4。路由器/交换机数等于系统中的 cpu 数。每个路由器/交换机连接到一个 L1、一个 L2（如果存在）。每个角落路由器/交换机连接到一个 Directory。它可以由 **--topology=MeshDirCorners_XY** 从命令行调用。网格中的行数 **必须由 --mesh-rows 指定**。使用 XY 路由算法。
  - **Pt2Pt**: 每个控制器 (L1/L2/Directory) 通过直接链路连接到每个其他控制器。这可以通过命令行调用
  - **Pt2Pt**: 全对全点对点连接

![](http://pwp.gatech.edu/ece-synergy/wp-content/uploads/sites/332/2016/10/topologies.jpg)

**在每个拓扑中，每个链路和每个路由器都可以独立传递一个覆盖默认值的参数（在 BasicLink.py 和 BasicRouter.py 中）**:

  - **链路参数:**
      - **latency**: 链路内的传输延迟。
      - **weight**: 与此链路关联的权重。此参数由路由表在决定路由时使用，如下文 [路由](Interconnection_Network#Routing "wikilink") 中所述。
      - **bandwidth_factor**: 仅由简单网络使用，以指定链路的宽度（以字节为单位）。这转换为带宽乘数 (simple/SimpleLink.cc)，单个链路带宽变为带宽乘数 x endpoint_bandwidth (在 SimpleNetwork.py 中指定)。在 garnet 中，带宽由 GarnetNetwork.py 中的 ni_flit_size 指定)


  - **内部链路参数:**
      - **src_outport**: 带有源路由器输出端口名称的字符串。
      - **dst_inport**: 带有目标路由器输入端口名称的字符串。

这两个参数可由路由器用于在 garnet2.0 中实现自定义路由算法

  - **路由器参数:**
      - **latency**: 每个路由器的延迟。仅由 garnet2.0 支持。

## 路由

**基于表的路由 (默认):** 基于拓扑，使用最短路径图遍历来填充每个路由器/交换机的 *路由表*。这是在 src/mem/ruby/network/Topology.cc 中完成的。默认路由算法是基于表的，并尝试选择链路遍历次数最少的路径。可以在拓扑文件中给链路赋予权重以模拟不同的路由算法。例如，在 Mesh_XY.py 和 MeshDirCorners_XY.py 中，Y 方向链路的权重为 2，而 X 方向链路的权重为 1，从而导致 XY 遍历。在 Mesh_westfirst.py 中，西向链路的权重为 1，所有其他链路的权重为 2。在 garnet2.0 中，路由算法在权重相等的链路之间随机选择。在简单网络中，它在权重相等的链路之间静态选择。

**自定义路由算法:** 在 garnet2.0 中，我们提供了额外的支持来实现自定义（包括自适应）路由算法（参见 src/mem/ruby/network/garnet2.0/RoutingUnit.cc 中的 outportComputeXY()）。链路的 src_outport 和 dst_inport 字段可用于为每个链路赋予自定义名称（例如，如果是网格，则为方向），这些可以在 garnet 内部用于实现任何路由算法。可以通过设置 --routing-algorithm=2 从命令行选择自定义路由算法。参见 configs/network/Network.py 和 src/mem/ruby/network/garnet2.0/GarnetNetwork.py

## 流控制和路由器微架构

Ruby 支持两种网络模型，Simple 和 Garnet，它们分别权衡详细建模与模拟速度。

### 简单网络

Ruby 中的默认网络模型是简单网络。

- **相关文件**:
    - **src/mem/ruby/network/Network.py**
    - **src/mem/ruby/network/simple**
    - **src/mem/ruby/network/simple/SimpleNetwork.py**

## 配置

简单网络使用 Network.py 中的通用网络参数：

- **number_of_virtual_networks**: 这是最大虚拟网络数。实际活动的虚拟网络数由协议决定。
- **control_msg_size**: 控制消息的大小（以字节为单位）。默认为 8。Network.cc 中的 **m_data_msg_size** 设置为块大小（以字节为单位）+ control_msg_size。

其他参数在 simple/SimpleNetwork.py 中指定：

- **buffer_size**: 每个交换机输入和输出端口的缓冲区大小。值 0 意味着无限缓冲。
- **endpoint_bandwidth**: 网络端点的带宽，以 1/1000 字节为单位。
- **adaptive_routing**: 这启用了基于输出缓冲区占用率的自适应路由。

## 交换机模型

简单网络模拟逐跳网络遍历，但抽象出交换机内的详细建模。交换机在 simple/PerfectSwitch.cc 中建模，而链路在 simple/Throttle.cc 中建模。流控制是通过在发送之前监视输出链路中的可用缓冲区和可用带宽来实现的。

![Simple_network.jpg](/assets/img/Simple_network.jpg "Simple_network.jpg")


### Garnet2.0

新 (2016) Garnet2.0 网络的详细信息在 **[这里](garnet-2)**。

## 使用合成流量运行网络

互连网络可以以独立方式运行并馈送合成流量。我们建议使用 garnet2.0 执行此操作。

**[使用合成流量运行 Garnet Standalone](/documentation/general_docs/ruby/garnet_synthetic_traffic)**
