---
layout: documentation
title: "MOESI CMP directory"
doc: gem5 documentation
parent: ruby
permalink: /documentation/general_docs/ruby/MOESI_CMP_directory/
author: Jason Lowe-Power
---

# MOESI CMP Directory

### 协议概述

  - TODO: 缓存层次结构

<!-- end list -->

  - 与 MESI 协议相比，MOESI 协议引入了额外的**Owned**状态。
  - MOESI 协议还包括 MESI 协议中不可用的许多合并优化。

### 相关文件

  - **src/mem/protocols**
      - **MOESI_CMP_directory-L1cache.sm**: L1 缓存控制器规范
      - **MOESI_CMP_directory-L2cache.sm**: L2 缓存控制器规范
      - **MOESI_CMP_directory-dir.sm**: 目录控制器规范
      - **MOESI_CMP_directory-dma.sm**: DMA 控制器规范
      - **MOESI_CMP_directory-msg.sm**: 消息类型规范
      - **MOESI_CMP_directory.slicc**: 容器文件

### L1 缓存控制器

#### **稳定状态和不变式**

| 状态    | 不变式                                                                                                                                                                                                                                                                                                                                                   |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **MM**    | 缓存块由该节点独占持有，并且可能已被修改（类似于传统的 "M" 状态）。                                                                                                                                                                                                                                            |
| **MM_W** | 缓存块由该节点独占持有，并且可能已被修改（类似于传统的 "M" 状态）。在此状态下不允许替换和 DMA 访问。块在超时后自动转换到 MM 状态。                                                                                                              |
| **O**     | 缓存块由该节点拥有。它尚未被该节点修改。没有其他节点以独占模式持有此块，但可能存在共享者。                                                                                                                                                                                               |
| **M**     | 缓存块以独占模式持有，但尚未写入（类似于传统的 "E" 状态）。没有其他节点持有此块的副本。在此状态下不允许存储。                                                                                                                                                                           |
| **M_W**  | 缓存块以独占模式持有，但尚未写入（类似于传统的 "E" 状态）。没有其他节点持有此块的副本。仅允许加载和存储。在存储时静默升级到 MM_W 状态。在此状态下不允许替换和 DMA 访问。块在超时后自动转换到 M 状态。 |
| **S**     | 缓存块由 1 个或多个节点在共享状态下持有。在此状态下不允许存储。                                                                                                                                                                                                                                                            |
| **I**     | 缓存块无效。                                                                                                                                                                                                                                                                                                                                  |

#### **FSM 抽象**

**控制器 FSM 图中使用的符号在[此处](#Coherence_controller_FSM_Diagrams "wikilink")描述。**

![MOESI_CMP_directory_L1cache_FSM.jpg](/assets/img/MOESI_CMP_directory_L1cache_FSM.jpg
"MOESI_CMP_directory_L1cache_FSM.jpg")

#### **优化**

| 状态 | 描述                                                                                                                                                                                                                              |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **SM** | 已发出 GETX 以获取即将对缓存块进行存储的独占权限，但块的旧副本仍然存在。在此状态下不允许存储和替换。                                     |
| **OM** | 已发出 GETX 以获取即将对缓存块进行存储的独占权限，数据已收到，但所有预期的确认尚未到达。在此状态下不允许存储和替换。 |

**The notation used in the controller FSM diagrams is described
[here](#Coherence_controller_FSM_Diagrams "wikilink").**

![MOESI_CMP_directory_L1cache_optim_FSM.jpg](/assets/img/MOESI_CMP_directory_L1cache_optim_FSM.jpg
"MOESI_CMP_directory_L1cache_optim_FSM.jpg")

### L2 缓存控制器

#### **稳定状态和不变式**

<table>
<thead>
<tr>
<th> 片内包含 </th>
<th> 片间排他 </th>
<th> 状态 </th>
<th> 描述
</th>
</tr>
</thead>
<tbody>
<tr>
<td> <b><span style="color:#808080">不在此芯片的任何 L1 或 L2 中</span></b> </td>
<td> <b>可能存在于其他芯片</b> </td>
<td> <b>NP/I</b> </td>
<td> 此芯片上的缓存块无效。
</td></tr>
<tr>
<td rowspan="6"> <b><span style="color:#00CC99">不在 L2 中，但在此芯片的 1 个或多个 L1 中</span></b> </td>
<td rowspan="3"><b>可能存在于其他芯片</b> </td>
<td> <b>ILS</b> </td>
<td> 缓存块不在此芯片的 L2 中。它由此芯片中的 L1 节点本地共享。
</td></tr>
<tr>
<td> <b>ILO</b> </td>
<td> 缓存块不在此芯片的 L2 中。此芯片中的某个 L1 节点是此缓存块的所有者。
</td></tr>
<tr>
<td> <b>ILOS</b> </td>
<td> 缓存块不在此芯片的 L2 中。此芯片中的某个 L1 节点是此缓存块的所有者。此芯片中还有此缓存块的 L1 共享者。
</td></tr>
<tr>
<td rowspan="3"><b>不存在于任何其他芯片</b> </td>
<td> <b>ILX</b> </td>
<td> 缓存块不在此芯片的 L2 中。它由此芯片中的某个 L1 节点以独占模式持有。
</td></tr>
<tr>
<td> <b>ILOX</b> </td>
<td> 缓存块不在此芯片的 L2 中。它由此芯片独占持有，此芯片中的某个 L1 节点是该块的所有者。
</td></tr>
<tr>
<td> <b>ILOSX</b> </td>
<td> 缓存块不在此芯片的 L2 中。它由此芯片独占持有。此芯片中的某个 L1 节点是该块的所有者。此芯片中还有此缓存块的 L1 共享者。
</td></tr>
<tr>
<td rowspan="3"> <b><span style="color:#99CCFF">在 L2 中，但不在该芯片的任何 L1 中</span></b> </td>
<td rowspan="2"><b>可能存在于其他芯片</b> </td>
<td> <b>S</b> </td>
<td> 缓存块不在此芯片的 L1 中。它在此芯片的 L2 中以共享模式持有，也可能在芯片间共享。
</td></tr>
<tr>
<td> <b>O</b> </td>
<td> 缓存块不在此芯片的 L1 中。它在此芯片的 L2 中以拥有模式持有。它也可能在芯片间共享。
</td></tr>
<tr>
<td> <b>不存在于任何其他芯片</b> </td>
<td> <b>M</b> </td>
<td> 缓存块不在此芯片的 L1 中。它在此芯片的 L2 中存在，并且可能已被修改。
</td></tr>
<tr>
<td rowspan="3"> <b><span style="color:#CC99FF">同时在此芯片的 L2 和 1 个或多个 L1 中</span></b> </td>
<td rowspan="2"><b>可能存在于其他芯片</b> </td>
<td> <b>SLS</b> </td>
<td> 缓存块在此芯片的 L2 中以共享模式存在。此芯片上存在该块的本地 L1 共享者。它也可能在芯片间共享。
</td></tr>
<tr>
<td> <b>OLS</b> </td>
<td> 缓存块在此芯片的 L2 中以拥有模式存在。此芯片上存在该块的本地 L1 共享者。它也可能在芯片间共享。
</td></tr>
<tr>
<td> <b>不存在于任何其他芯片</b> </td>
<td> <b>OLSX</b> </td>
<td> 缓存块在此芯片的 L2 中以拥有模式存在。此芯片上存在该块的本地 L1 共享者。它由此芯片独占持有。
</td></tr>
</tbody>
</table>

#### **FSM 抽象**

控制器分为 2 部分描述。第一张图显示所有"片内包含"类别之间以及类别 1、3、4 内的转换。类别 2（不在 L2 中，但在此芯片的 1 个或多个 L1 中）内的转换在第二张图中显示。

**控制器 FSM 图中使用的符号在[此处](#Coherence_controller_FSM_Diagrams "wikilink")描述。涉及其他芯片的转换用<span style="color:#CC3300">棕色</span>标注。**

![MOESI_CMP_directory_L2cache_FSM_part_1.jpg](/assets/img/MOESI_CMP_directory_L2cache_FSM_part_1.jpg
"MOESI_CMP_directory_L2cache_FSM_part_1.jpg")

下面的第二张图扩展了上面图片的中心六边形部分，以显示类别 2（不在 L2 中，但在此芯片的 1 个或多个 L1 中）内的转换。

**控制器 FSM 图中使用的符号在[此处](#Coherence_controller_FSM_Diagrams "wikilink")描述。涉及其他芯片的转换用<span style="color:#CC3300">棕色</span>标注。**

![MOESI_CMP_directory_L2cache_FSM_part_2.jpg](/assets/img/MOESI_CMP_directory_L2cache_FSM_part_2.jpg
"MOESI_CMP_directory_L2cache_FSM_part_2.jpg")

### 目录控制器

#### **稳定状态和不变式**

| 状态 | 不变式                                                                                                                                                                      |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **M**  | 缓存块仅由 1 个节点以独占状态持有（该节点也是所有者）。此块没有共享者。数据可能与内存中的数据不同。 |
| **O**  | 缓存块恰好由 1 个节点拥有。此块可能有共享者。数据可能与内存中的数据不同。                                          |
| **S**  | 缓存块由 1 个或多个节点在共享状态下持有。没有节点拥有该块的所有权。数据与内存中的数据一致（检查）。                             |
| **I**  | 缓存块无效。                                                                                                                                                     |

#### **FSM 抽象**

**控制器 FSM 图中使用的符号在[此处](#Coherence_controller_FSM_Diagrams "wikilink")描述。**

![MOESI_CMP_directory_dir_FSM.jpg](/assets/img/MOESI_CMP_directory_dir_FSM.jpg
"MOESI_CMP_directory_dir_FSM.jpg")

### 其他功能

#### **超时**：
