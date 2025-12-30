---
layout: documentation
title: "经典缓存"
doc: gem5 documentation
parent: memory_system
permalink: /documentation/general_docs/memory_system/classic_caches/
author: Jason Lowe-Power
---

# 经典缓存

默认缓存是一个非阻塞缓存，带有 MSHR（未命中状态保持寄存器）和 WB（写缓冲区）用于读写未命中。缓存还可以启用预取（通常在最后一级缓存中）。

gem5 中实现了多种可能的 [替换策略](/documentation/general_docs/memory_system/replacement_policies) 和 [索引策略](/documentation/general_docs/memory_system/indexing_policies)。它们分别定义了给定地址可以用于块替换的可能块，以及如何使用地址信息查找块的位置。
默认情况下，使用 [LRU (最近最少使用)](/documentation/general_docs/memory_system/replacement_policies) 替换缓存行，并使用 [组相联 (Set Associative)](/documentation/general_docs/memory_system/indexing_policies) 策略进行索引。

# 互连

### 交叉开关 (Crossbars)

交叉开关中的两种流量是内存映射数据包和 snoop 数据包。内存映射请求沿内存层次结构向下传输，响应沿内存层次结构向上传输（相同路线返回）。
snoop 请求水平传输并沿缓存层次结构向上传输，snoop 响应水平传输并沿层次结构向下传输（相同路线返回）。普通 snoop 水平传输，express snoop 沿缓存层次结构向上传输。

![总线连接](/assets/img/Bus.png)

### 桥接器 (Bridges)

### 其他...

# 调试

经典内存系统中有一个功能，用于在调试器（例如 gdb）中显示特定块的一致性状态。此功能建立在经典内存系统对功能访问的支持之上。（请注意，此功能目前很少使用，并且可能有错误。）

如果您注入一个命令设置为 PrintReq 的功能请求，该数据包将遍历内存系统（就像常规功能请求一样），但在任何匹配的对象（其他排队的数据包、缓存块等）上，它只是打印出有关该对象的一些信息。

Port 上有一个名为 printAddr() 的辅助方法，它接受一个地址并构建适当的 PrintReq 数据包并注入它。由于它使用与普通功能请求相同的机制传播，因此需要从传播到整个内存系统的端口注入，例如在 CPU 处。MemTest、AtomicSimpleCPU 和 TimingSimpleCPU 对象上有辅助 printAddr() 方法，它们只是在其各自的缓存端口上调用 printAddr()。（警告：后两者未经测试。）

把所有这些放在一起，您可以这样做：

```
(gdb) set print object
(gdb) call SimObject::find(" system.physmem.cache0.cache0.cpu")
$4 = (MemTest *) 0xf1ac60
(gdb) p (MemTest*)$4
$5 = (MemTest *) 0xf1ac60
(gdb) call $5->printAddr(0x107f40)

system.physmem.cache0.cache0
  MSHRs
    [107f40:107f7f] Fill   state:
      Targets:
        cpu: [107f40:107f40] ReadReq
system.physmem.cache1.cache1
  blk VEM
system.physmem
  0xd0
```

...这表示 cache0.cache0 为该地址分配了一个 MSHR 来服务来自 CPU 的目标 ReadReq，但它尚未在服务中（否则会被标记为服务中）；该块在 cache1.cache1 中是有效、独占和已修改的，并且该字节在物理内存中的值为 0xd0。

显然，这不一定是您想要的所有信息，但它非常有用。随意扩展。还有一个目前未使用的详细程度参数，可以利用它来获得不同级别的输出。

注意，额外的 "p (MemTest*)$4" 是必需的，因为虽然 "set print object" 显示派生类型，但在内部 gdb 仍然认为指针是基类型，所以如果您尝试直接在 $4 指针上调用 printAddr，您会得到这个：

```
(gdb) call $4->printAddr(0x400000)
Couldn't find method SimObject::printAddr
```
