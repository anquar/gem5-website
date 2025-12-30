---
layout: documentation
title: "MOESI hammer"
doc: gem5 documentation
parent: ruby
permalink: /documentation/general_docs/ruby/MOESI_hammer/
author: Jason Lowe-Power
---

# MOESI Hammer

这是 AMD 的 Hammer 协议的实现，用于 AMD 的 Hammer 芯片（也称为 Opteron 或 Athlon 64）。该协议实现了原始的 HyperTransport 协议以及更新的 ProbeFilter 协议。该协议还包括全位目录模式。

### 相关文件

  - **src/mem/protocols**
      - **MOESI_hammer-cache.sm**: 缓存控制器规范
      - **MOESI_hammer-dir.sm**: 目录控制器规范
      - **MOESI_hammer-dma.sm**: DMA 控制器规范
      - **MOESI_hammer-msg.sm**: 消息类型规范
      - **MOESI_hammer.slicc**: 容器文件

### 缓存层次结构

该协议实现了 2 级私有缓存层次结构。它为每个核心分配独立的指令和数据 L1 缓存，以及统一的 L2 缓存。这些缓存对每个核心都是私有的，并由一个共享缓存控制器控制。该协议强制 L1 和 L2 缓存之间的排他性。

### 稳定状态和不变式

| 状态 | 不变式                                                                                                                                                                                                          |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **MM** | 缓存块由该节点独占持有，并且可能已被本地修改（类似于传统的 "M" 状态）。                                                                                           |
| **O**  | 缓存块由该节点拥有。它尚未被该节点修改。没有其他节点以独占模式持有此块，但可能存在共享者。                                                      |
| **M**  | 缓存块以独占模式持有，但尚未写入（类似于传统的 "E" 状态）。没有其他节点持有此块的副本。在此状态下不允许存储。                                  |
| **S**  | 缓存行保存数据的最新、正确副本。系统中的其他处理器也可能在共享状态下保存数据的副本。在此状态下可以读取缓存行，但不能写入。 |
| **I**  | 缓存行无效，不保存数据的有效副本。                                                                                                                                               |

### 缓存控制器

**控制器 FSM 图中使用的符号在[此处](#Coherence_controller_FSM_Diagrams "wikilink")描述。**

MOESI_hammer 支持缓存刷新。要刷新缓存行，缓存控制器首先向目录发出 GETF 请求以阻塞该行，直到刷新完成。然后它发出 PUTF 并写回缓存行。

![MOESI_hammer_cache_FSM.jpg](/assets/img/MOESI_hammer_cache_FSM.jpg
"MOESI_hammer_cache_FSM.jpg")

### 目录控制器

MOESI_hammer 内存模块与典型的目录协议不同，不包含任何目录状态，而是向系统中的所有处理器广播请求。同时，它从 DRAM 获取数据并将响应转发给请求者。

probe filter: TODO

#### **稳定状态和不变式**

| 状态 | 不变式                                                           |
| ------ | -------------------------------------------------------------------- |
| **NX** | 非所有者，probe filter 条目存在，块在所有者处为 O。           |
| **NO** | 非所有者，probe filter 条目存在，块在所有者处为 E/M。         |
| **S**  | 数据干净，probe filter 条目存在，指向当前所有者。 |
| **O**  | 数据干净，probe filter 条目存在。                               |
| **E**  | 独占所有者，无 probe filter 条目。                              |

#### **控制器**

**控制器 FSM 图中使用的符号在[此处](#Coherence_controller_FSM_Diagrams "wikilink")描述。**

![MOESI_hammer_dir_FSM.jpg](/assets/img/MOESI_hammer_dir_FSM.jpg
"MOESI_hammer_dir_FSM.jpg")
