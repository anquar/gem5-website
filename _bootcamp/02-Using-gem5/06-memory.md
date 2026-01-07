---
layout: bootcamp
title: 在 gem5 中建模内存
permalink: /bootcamp/using-gem5/memory
section: using-gem5
---
<!-- _class: title -->

## 在 gem5 中建模内存

DRAM 和其他内存设备！

---

<!-- _class: center-image -->

## 内存系统

### gem5 的内存系统由两个主要组件组成

1. 内存控制器
2. 内存接口

![Diagram of the gem5 memory system](/bootcamp/02-Using-gem5/06-memory-imgs/memory-system.drawio.svg)

---

<!-- _class: center-image -->

## 内存控制器

### 当 `MemCtrl` 接收到数据包时...

1. 数据包被排入读队列和/或写队列
2. 应用**调度算法**（FCFS、FR-FCFS 等）来发出读写请求

![Diagram of the gem5 memory controller queues](/bootcamp/02-Using-gem5/06-memory-imgs/memory-controller-queues.drawio.svg)

---

<!-- _class: center-image -->

## 内存接口

- 内存接口实现了所选内存类型的**架构**和**时序参数**。
- 它管理**介质特定的操作**，如激活、预充电、刷新和低功耗模式等。

![Diagram of the gem5 memory interface](/bootcamp/02-Using-gem5/06-memory-imgs/memory-interface.drawio.svg)

---

<!-- _class: center-image -->

## gem5 的内存控制器

![Hierarchy of gem5 memory controller classes](/bootcamp/02-Using-gem5/06-memory-imgs/memory-controller-classes.drawio.svg)

---

<!-- _class: center-image -->

## gem5 的内存接口

![Hierarchy of gem5 memory interface classes](/bootcamp/02-Using-gem5/06-memory-imgs/memory-interface-classes.drawio.svg)

---

## 内存模型的工作原理

- 内存控制器负责调度和发出读写请求
- 它遵循内存接口的时序参数
  - `tCAS`、`tRAS` 等在内存接口中按*每个 bank* 进行跟踪
  - 使用 gem5 的*事件*（[稍后详述](../03-Developing-gem5-models/03-event-driven-sim.md)）来调度 bank 何时空闲

该模型不是"周期精确的"，但它是*周期级别*的，与 DRAMSim 和 DRAMSys 等其他 DRAM 模拟器相比相当准确。

你可以为新型内存设备（例如 DDR6）扩展接口，但通常你会使用已经实现的接口。

gem5 内存通常配置的主要方式是通道数和通道/rank/bank/行/列位数，因为系统很少使用定制内存设备。

---

## 标准库中的内存

标准库将 DRAM/内存模型封装到 `MemorySystem` 中。

标准库中已经为你实现了很多示例。

请参阅 [`gem5/src/python/gem5/components/memory/multi_channel.py`](https://github.com/gem5/gem5/blob/stable/src/python/gem5/components/memory/multi_channel.py) 和 [`gem5/src/python/gem5/components/memory/single_channel.py`](https://github.com/gem5/gem5/blob/stable/src/python/gem5/components/memory/single_channel.py) 作为示例。

此外，

- `SimpleMemory()` 允许用户不必担心时序参数，只需提供所需的延迟、带宽和延迟变化。
- `ChanneledMemory()` 包含整个内存系统（控制器和接口）。
- ChanneledMemory 提供了一种使用多个内存通道的简单方法。
- ChanneledMemory 为你处理调度策略和交错等事务。

---

## 使用标准库运行示例

打开 [`materials/02-Using-gem5/06-memory/run-mem.py`](https://github.com/gem5bootcamp/2024/blob/main/materials/02-Using-gem5/06-memory/run-mem.py)

该文件使用流量生成器（在[之前](03-running-in-gem5.md)见过）在 64GiB 处生成内存流量。

让我们看看使用简单内存时会发生什么。为内存系统添加以下行。

```python
memory = SingleChannelSimpleMemory(latency="50ns", bandwidth="32GiB/s", size="8GiB", latency_var="10ns")
```

使用以下命令运行。使用 `-c <LinearGenerator,RandomGenerator>` 指定流量生成器，使用 `-r <read percentage>` 指定读取百分比。

```sh
gem5 run-mem.py
```

---

## 改变延迟和带宽

使用 16 GiB/s、32 GiB/s、64 GiB/s，以及 100% 读取和 50% 读取的运行结果。

| 带宽 | 读取百分比 | 线性速度 (GB/s) | 随机速度 (GB/s) |
|-----------|-----------------|---------------------|---------------------|
| 16 GiB/s  | 100%            | 17.180288           | 17.180288           |
|           | 50%             | 17.180288           | 17.180288           |
| 32 GiB/s  | 100%            | 34.351296           | 34.351296           |
|           | 50%             | 34.351296           | 34.351296           |
| 64 GiB/s  | 100%            | 34.351296           | 34.351296           |
|           | 50%             | 34.351296           | 34.351296           |

使用 `SimpleMemory` 时，你不会看到内存模型中的任何复杂行为（但它**确实**很快）。

---

## 运行通道化内存

- 打开 [`gem5/src/python/gem5/components/memory/single_channel.py`](https://github.com/gem5/gem5/blob/stable/src/python/gem5/components/memory/single_channel.py)
- 我们看到 `SingleChannel` 内存，例如：

```python
def SingleChannelDDR4_2400(
    size: Optional[str] = None,
) -> AbstractMemorySystem:
    """
    A single channel memory system using DDR4_2400_8x8 based DIMM.
    """
    return ChanneledMemory(DDR4_2400_8x8, 1, 64, size=size)
```

- 我们看到 `DRAMInterface=DDR4_2400_8x8`，通道数=1，交错大小=64，以及大小。

---

## 运行通道化内存

- 让我们回到脚本，用这个替换 SingleChannelSimpleMemory！

替换

```python
SingleChannelSimpleMemory(latency="50ns", bandwidth="32GiB/s", size="8GiB", latency_var="10ns")
```

为

```python
SingleChannelDDR4_2400()
```

### 让我们看看运行测试时会发生什么

---

## 改变延迟和带宽

使用 16 GiB/s、32 GiB/s，以及 100% 读取和 50% 读取的运行结果。

| 带宽 | 读取百分比 | 线性速度 (GB/s) | 随机速度 (GB/s) |
|-----------|-----------------|---------------------|---------------------|
| 16 GiB/s  | 100%            | 13.85856            | 14.557056           |
|           | 50%             | 13.003904           | 13.811776           |
| 32 GiB/s  | 100%            | 13.85856            | 14.541312           |
|           | 50%             | 13.058112           | 13.919488           |

正如预期的那样，由于读转写的转换，100% 读取比 50% 读取更高效。
同样如预期，带宽低于 SimpleMemory（仅约 75% 利用率）。

有点令人惊讶的是，建模的内存有足够的 bank 来高效处理随机流量。

---

## 添加新的通道化内存

- 打开 [`materials/02-Using-gem5/06-memory/lpddr2.py`](https://github.com/gem5bootcamp/2024/blob/main/materials/02-Using-gem5/06-memory/lpddr2.py)
- 如果我们想在标准库中添加 LPDDR2 作为新内存，我们首先确保在 [`dram_interfaces` 目录](https://github.com/gem5/gem5/blob/stable/src/python/gem5/components/memory/dram_interfaces/lpddr2.py)中有它的 DRAM 接口
- 然后我们需要通过在 `lpddr2.py` 的顶部添加以下内容来确保导入它：
```python
from gem5.components.memory.abstract_memory_system import AbstractMemorySystem
from gem5.components.memory.dram_interfaces.lpddr2 import LPDDR2_S4_1066_1x32
from gem5.components.memory.memory import ChanneledMemory
from typing import Optional
```

---

## 添加新的通道化内存

然后在 `lpddr2.py` 的主体中添加以下内容：

```python
def SingleChannelLPDDR2(
    size: Optional[str] = None,
) -> AbstractMemorySystem:
    return ChanneledMemory(LPDDR2_S4_1066_1x32, 1, 64, size=size)
```

然后我们通过以下方式将此类导入到脚本中：

```python
from lpddr2 import SingleChannelLPDDR2
```

### 让我们再次测试这个！

---

## 改变延迟和带宽

使用 16 GiB/s，以及 100% 读取和 50% 读取的运行结果。

| 带宽 | 读取百分比 | 线性速度 (GB/s) | 随机速度 (GB/s) |
|-----------|-----------------|---------------------|---------------------|
| 16 GiB/s  | 100%            | 4.089408            | 4.079552            |
|           | 50%             | 3.65664             | 3.58816             |

LPDDR2 的性能不如 DDR4。

---

## CommMonitor

- 监控两个端口之间通信的 SimObject
- 对时序没有任何影响
- [`gem5/src/mem/CommMonitor.py`](https://github.com/gem5/gem5/blob/stable/src/mem/CommMonitor.py)

---

<!-- _class: center-image -->

## CommMonitor

### 要修改的简单系统

![Simple system diagram](/bootcamp/02-Using-gem5/06-memory-imgs/comm-monitor-0.drawio.svg)

### 让我们进行模拟：

<!-- >    > gem5-x86 –outdir=results/simple materials/extra-topics/02-monitor-and-trace/simple.py -->
运行

```sh
gem5 comm_monitor.py
```

---

<!-- _class: center-image -->

## CommMonitor

### 让我们添加 CommMonitor

![Simple system with CommMonitor diagram](/bootcamp/02-Using-gem5/06-memory-imgs/comm-monitor-1.drawio.svg)

<!-- ### Let's simulate: -->

<!--  gem5-x86 –outdir=results/simple_comm materials/extra-topics/02-monitor-and-trace/simple_comm.py
     diff results/simple/stats.txt results/simple_comm/stats.txt -->

---

## CommMonitor

- 删除以下行：
```python
system.l1cache.mem_side = system.membus.cpu_side_ports
```

- 在注释 `# Insert CommMonitor here` 下添加以下代码块：
```python
system.comm_monitor = CommMonitor()
system.comm_monitor.cpu_side_port = system.l1cache.mem_side
system.comm_monitor.mem_side_port = system.membus.cpu_side_ports
```

- 运行：
```sh
gem5 comm_monitor.py
```

---

## 地址交错

### 想法：我们可以并行化内存访问

- 例如，我们可以同时访问多个 bank/通道等
- 使用地址的一部分作为选择器来选择要访问的 bank/通道
- 允许连续地址范围在 bank/通道之间交错

---

<!-- _class: center-image -->

## 地址交错

### 例如...

![Diagram showing an example of address interleaving](/bootcamp/02-Using-gem5/06-memory-imgs/address-interleaving.drawio.svg)

---

## 地址交错

### 在 gem5 中使用地址交错

- 我们可以使用 AddrRange 构造函数来定义选择器函数
  - [`src/base/addr_range.hh`](https://github.com/gem5/gem5/blob/stable/src/base/addr_range.hh)

- 示例：标准库的多通道内存
  - [`gem5/src/python/gem5/components/memory/multi_channel.py`](https://github.com/gem5/gem5/blob/stable/src/python/gem5/components/memory/multi_channel.py)

---

## 地址交错

### 有两个构造函数

构造函数 1：

```cpp
AddrRange(Addr _start,
          Addr _end,
          const std::vector<Addr> &_masks,
          uint8_t _intlv_match)
```

`_masks`：掩码数组，其中选择器的第 `k` 位是由 `masks[k]` 指定的所有位的异或

---

## 地址交错

### 有两个构造函数

构造函数 2（旧版）：

```cpp
AddrRange(Addr _start,
          Addr _end,
          uint8_t _intlv_high_bit,
          uint8_t _xor_high_bit,
          uint8_t _intlv_bits,
          uint8_t _intlv_match)
```

选择器定义为两个范围：

```code
addr[_intlv_high_bit:_intlv_low_bit] XOR addr[_xor_high_bit:_xor_low_bit]
```
