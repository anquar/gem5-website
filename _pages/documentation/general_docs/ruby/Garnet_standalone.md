---
layout: documentation
title: "Garnet 独立运行"
doc: gem5 documentation
parent: ruby
permalink: /documentation/general_docs/ruby/Garnet_standalone/
author: Jason Lowe-Power
---

# Garnet 独立运行

这是一个虚拟缓存一致性协议，用于以独立方式运行 Garnet。该协议与 [Garnet 合成流量 (Garnet Synthetic Traffic)](/documentation/general_docs/ruby/garnet_synthetic_traffic) 注入器一起工作。

### 相关文件

  - **src/mem/protocols**
      - **Garnet_standalone-cache.sm**: 缓存控制器规范
      - **Garnet_standalone-dir.sm**: 目录控制器规范
      - **Garnet_standalone-msg.sm**: 消息类型规范
      - **Garnet_standalone.slicc**: 容器文件

### 缓存层次结构

此协议假设 1 级缓存层次结构。缓存的作用只是简单地将消息从 cpu 发送到适当的目录（基于地址），在适当的虚拟网络中（基于消息类型）。它不跟踪任何状态。事实上，与其他协议不同，没有创建 CacheMemory。目录接收来自缓存的消息，但不发回任何消息。此协议的目标是仅启用互连网络的模拟/测试。

### 稳定状态和不变量

| 状态 | 不变量                        |
| ------ | --------------------------------- |
| **I**  | 所有缓存块的默认状态 |

### 缓存控制器

  - 请求、响应、触发器：
      - 来自核心的加载、指令提取、存储。

网络测试器 (在 src/cpu/testers/networktest/networktest.cc 中) 生成 **ReadReq**、**INST_FETCH** 和 **WriteReq** 类型的数据包，它们分别由 RubyPort (在 src/mem/ruby/system/RubyPort.hh/cc 中) 转换为 **RubyRequestType:LD**、**RubyRequestType:IFETCH** 和 **RubyRequestType:ST**。这些消息通过 Sequencer 到达缓存控制器。这些消息的目的地由流量类型确定，并嵌入在地址中。更多详细信息可以在 [这里](/documentation/general_docs/debugging_and_testing/directed_testers/ruby_random_tester) 找到。

  - 主要操作：
      - 缓存的目标仅仅是充当底层互连网络中的源节点。它不跟踪任何状态。
      - 在来自核心的 **LD** 上：
          - 它返回命中，并且
          - 将地址映射到目录，并在请求 vnet (0) 中为其发出类型为 **MSG**、大小为 **Control** (8 字节) 的消息。
          - 注意：通过取消注释 Network_test-cache.sm 中 *a_issueRequest* 动作中的相应行，也可以使 vnet 0 广播，而不是向特定目录发送定向消息
      - 在来自核心的 **IFETCH** 上：
          - 它返回命中，并且
          - 将地址映射到目录，并在转发 vnet (1) 中为其发出类型为 **MSG**、大小为 **Control** (8 字节) 的消息。
      - 在来自核心的 **ST** 上：
          - 它返回命中，并且
          - 将地址映射到目录，并在响应 vnet (2) 中为其发出类型为 **MSG**、大小为 **Data** (72 字节) 的消息。
      - 注意：请求、转发和响应仅用于区分 vnet，但在此协议中没有任何物理意义。

### 目录控制器

  - 请求、响应、触发器：
      - 来自核心的 **MSG**

  - 主要操作：
      - 目录的目标仅仅是充当底层互连网络中的目标节点。它不跟踪任何状态。
      - 目录在收到消息时只是弹出其传入队列。

### 其他功能

   此协议假设只有 3 个 vnet。
  - 它仅应在运行 [Garnet 合成流量](/documentation/general_docs/ruby/garnet_synthetic_traffic) 时使用。
