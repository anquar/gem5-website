---
layout: documentation
title: 设备
parent: fullsystem
doc: gem5 documentation
permalink: documentation/general_docs/fullsystem/devices
---

# 全系统模式下的设备

## I/O 设备基类

src/dev/\*_device.\* 中的基类允许相对轻松地创建设备。
下面列出了必须实现的类和虚拟函数。
在阅读以下内容之前，熟悉[内存系统](../memory_system)会有所帮助。

### PioPort

PioPort 类是一个可编程 I/O 端口，所有对地址范围敏感的设备都使用它。
该端口接受所有内存访问类型，并将它们整合到一个 `read()` 和 `write()` 调用中，设备必须响应这些调用。
设备还必须提供 `addressRanges()` 函数，该函数返回它感兴趣的地址范围。
如果需要，设备可以拥有多个 PIO 端口。
但在正常情况下，它只有一个端口，并在调用 `addressRange()` 函数时返回多个范围。只有在设备希望与两个内存对象有单独连接时，才需要多个 PIO 端口。

### PioDevice

这是所有对地址范围敏感的设备继承的基类。
所有设备必须实现三个纯虚拟函数：`addressRanges()`、`read()` 和 `write()`。
选择我们处于哪种模式等的逻辑由 PioPort 处理，因此设备不必担心。

每个设备的参数应该在从 `PioDevice::Params` 派生的 Params 结构体中。

### BasicPioDevice

由于大多数 PioDevice 只响应一个地址范围，`BasicPioDevice` 提供了一个 `addressRanges()` 以及正常 pio 延迟和设备响应的地址的参数。
由于设备的大小通常不可配置，因此不使用参数，从此类继承的任何内容都应在构造函数中将其大小写入 pioSize。

### DmaPort

DmaPort（在 dma_device.hh 中）仅用于设备主控访问。
`recvTimingResp()` 方法必须可用于响应（无论是否被否定）它发出的请求。
该端口有两个公共方法 `dmaPending()`，它返回 dma 端口是否繁忙（例如，它仍在尝试发送最后一个请求的所有部分）。
所有将请求分解为适当大小的块、收集可能多个响应并响应设备的代码都通过 `dmaAction()` 访问。
命令、起始地址、大小、完成事件以及可能的数据被传递给该函数，该函数将在请求完成时执行完成事件的 `process()` 方法。
在内部，代码使用 `DmaReqState` 来管理它已接收的块，并知道何时执行完成事件。

### DmaDevice

这是 DMA 非 PCI 设备将继承的基类，但目前 M5 中不存在这些设备。该类确实有一些方法 `dmaWrite()`、`dmaRead()`，它们从 DMA 读或写操作中选择适当的命令。

### NIC 设备

gem5 模拟器有两个不同的网络接口卡 (NIC) 设备，可用于通过模拟以太网链路连接两个模拟实例。

#### 获取以太网链路上的数据包列表

您可以通过创建 Etherdump 对象、设置其文件参数，并在 EtherLink 上设置 dump 参数来获取以太网链路上的数据包列表。
这可以通过在我们的 fs.py 示例配置中添加命令行选项 \-\-etherdump=\<filename\> 轻松完成。生成的文件将命名为 \<file\> 并采用标准 pcap 格式。
可以使用 [wireshark](https://www.wireshark.org/) 或任何其他理解 pcap 格式的工具读取此文件。


### PCI 设备
```
待办事项：解释平台和系统，它们如何相关，以及它们各自的用途
```
