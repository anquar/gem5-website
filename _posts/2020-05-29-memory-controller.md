---
layout: post
title:  "面向新 DRAM 技术、NVM 接口和灵活内存拓扑的内存控制器更新"
author: Wendy Elsasser and Nikos Nikoleris
date:   2020-05-27
---

## 为 DRAMCtrl 添加 LPDDR5 支持

LPDDR5 目前正在批量生产，用于包括移动、汽车、AI 和 5G 在内的多个市场。由于提议的速度等级扩展，该技术预计将在 2021 年成为主流旗舰低功耗 DRAM，并具有预期的长期性。该规范定义了灵活的架构和多种选项，以在不同用例之间进行优化，权衡功耗、性能、可靠性和复杂性。为了评估这些权衡，gem5 模型已更新为包含 LPDDR5 配置和架构支持。

LPDDR5 主要是 LPDDR4 的演进升级，有三个关键动机：灵活性、性能和功耗。该规范提供了多种选项，以支持各种用例，具有用户可编程的存储体架构和新的低功耗功能，以平衡功耗和性能权衡。与之前的几代类似，LPDDR5 提高了数据速率，当前版本的规范支持高达 6.4Gbps（每秒千兆位）的数据速率，16 位通道的最大 I/O 带宽为 12.8GB/s（每秒千兆字节）。定义了一个新的时钟架构，利用来自其他技术（如 GDDR）的概念，但具有低功耗的转变。使用新的时钟架构，命令以较低频率传输，某些命令需要多个时钟周期。新的时钟架构还包括数据时钟同步的额外要求，可能在突发发出时动态完成。由于这些更改，需要额外的考虑来确保某些高速场景中的足够命令带宽。这些新的 LPDDR5 功能需要在 gem5 中进行新的检查和优化，以确保在与真实硬件比较时模型的完整性。

对多周期命令和较低频率命令传输的支持促使在 gem5 中进行新的检查以验证命令带宽。DRAM 控制器历史上不验证命令总线上的争用，并假设无限命令带宽。随着新技术的演进，这种假设并不总是有效。一个潜在的解决方案是将所有命令对齐到时钟边界，并确保不同时发出两个命令。鉴于 gem5 模型不是周期精确模型，此解决方案被认为过于复杂。或者，定义了一个滚动窗口，模型计算在该窗口内可以发出的最大命令数。在发出命令之前，模型将验证命令将发出的窗口是否仍有可用插槽。如果插槽已满，命令将转移到下一个窗口。这将持续进行，直到找到具有空闲命令插槽的窗口。窗口目前由传输突发所需的时间定义，通常由 tBURST 参数定义。

在更高的数据速率下，无缝传输突发的能力取决于 LPDDR5 中的存储体架构。当使用存储体组架构配置时，该架构定义了总共 16 个存储体，分布在 4 个存储体组中，32 的突发无法无缝传输。相反，数据将在突发中间有间隙的情况下传输。基本上，突发的一半将在 2 个周期内传输，然后是 2 个周期的间隙，突发的后半部分在间隙之后传输。为了减轻对数据总线利用率和 IO 带宽的影响，LPDDR5 支持交错突发。gem5 模型也已更新以支持突发交错，通过这些更改，模型能够达到预期的高数据总线利用率（在许多情况下是必需的）。

所有这些更改将在 gem5 研讨会中讨论。在研讨会中，我们将回顾 LPDDR5 要求并详细介绍在 gem5 中进行的更改。虽然这些更改是专门为 LPDDR5 合并的，但其中一些也适用于其他内存技术。我期待在研讨会中的讨论！

### Workshop Presentation

<iframe width="960" height="540"
src="https://www.youtube.com/embed/ttJ9_I_Avyc" frameborder="0"
allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
allowfullscreen style="max-width: 960px"></iframe>

## 重构 DRAMCtrl 并创建初始 NVM 接口

gem5 DRAM 控制器提供与外部、用户可寻址内存的接口，传统上是 DRAM。控制器由 2 个主要组件组成：内存控制器和 DRAM 接口。内存控制器包括连接到片上结构的端口。它从结构接收命令包，将它们排入读写队列，并管理读写请求的命令调度算法。DRAM 接口包含定义 DRAM 架构和时序参数的媒体特定信息，并管理媒体特定操作，如激活、预充电、刷新和低功耗模式。

随着 SCM（存储类内存）的出现，新兴的 NVM 也可能存在于内存接口上，可能与 DRAM 一起存在。NVM 支持可以简单地分层在现有 DRAM 控制器之上，并将更改集成到当前 DRAM 接口中。然而，通过更系统的方法，可以修改模型以提供一种机制，使新接口更容易集成以支持未来的内存技术。为此，内存控制器已被重构。不是单个 DRAM 控制器 (DRAMCtrl) 对象，而是定义了两个对象：DRAMCtrl 和 DRAMInterface。内存配置现在定义为 DRAM 接口，DRAM 特定参数和函数已从控制器移动到接口。这包括 DRAM 架构、时序和 IDD 参数。为了连接这两个对象，在 DRAM 控制器 Python 对象中定义了一个新参数。此参数 'dram' 是指向 DRAM 接口的指针。

```
    # Interface to volatile, DRAM media
    dram = Param.DRAMInterface(NULL, "DRAM interface")
```

特定于 DRAM 操作码的函数也已从控制器中提取并移动到接口。例如，Rank 类和关联函数现在在接口内定义。DRAM 接口定义为 AbstractMemory，允许为实际媒体接口而不是控制器定义地址范围。通过此更改，控制器已修改为 ClockedObject。

现在，DRAM 控制器是通用内存控制器，可以定义并轻松连接非 DRAM 接口。在这方面，已定义了一个初始 NVM 接口 NVMInterface，它模拟 NVDIMM-P 的行为。与 DRAM 接口类似，NVM 接口定义为 AbstractMemory，为接口定义了地址范围。在 Python 中定义了一个新参数 'nvm'，在配置时将控制器连接到 NVM 接口。

```
    # Interface to non-volatile media
    nvm = Param.NVMInterface(NULL, "NVM interface")
```

NVM 接口是媒体无关的，仅定义读写操作。该接口的意图是支持多种媒体类型，其中许多性能不如 DRAM。虽然 DRAM 以确定性时序访问，但 NVM 内的内部操作可能创建更长的尾部延迟分布，需要非确定性延迟。为了管理非确定性，读取已分为 2 个阶段：读取请求和数据突发。第一阶段，读取请求简单地发出读取命令并调度 ReadReady 事件。当读取完成且数据可用时，将触发该事件。那时，NVM 接口将触发控制器事件以发出数据突发。

虽然新兴 NVM 的写入延迟和写入带宽通常比 FLASH 快几个数量级，但对于许多技术来说，它尚未与 DRAM 相当。为了减轻更长的写入延迟和较低的带宽，gem5 中的 NVM 接口建模了一个近 NVM 写入缓冲区。此缓冲区从内存控制器卸载写入命令和数据，并在满时提供回推，抑制进一步写入命令的发出，直到弹出条目。当写入完成时，使用 NVM 接口中定义的参数弹出条目。

在重构控制器并创建唯一的 DRAM 和 NVM 接口后，gem5 中可能出现各种潜在的内存子系统拓扑。系统可以在单个通道上合并 NVM 和 DRAM，或为每个媒体定义专用通道。可以定义配置以提供多种场景用于 NVM+DRAM 模拟，以分析新内存技术的权衡和优化未来内存子系统的方法。

### Workshop Presentation

<iframe width="960" height="540"
src="https://www.youtube.com/embed/t2PRoZPwwpk" frameborder="0"
allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
allowfullscreen style="max-width: 960px"></iframe>
