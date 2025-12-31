---
layout: bootcamp
title: 计算机体系结构模拟
permalink: /bootcamp/introduction/simulation-background
section: introduction
author: Jason Lowe-Power
---
<!-- _class: title -->

## 计算机体系结构模拟

---

## 大纲

### gem5 是什么以及一些历史

### 我对体系结构模拟的看法

### gem5 的软件架构

---

## 首先是 M5

![M5 Logo](/bootcamp/01-Introduction/01-simulation-background-imgs/m5.drawio.svg)

---

<!-- _class: center-image -->

## ISCA 2005 上的 M5

![M5 slide from ISCA tutorial height:500px](/bootcamp/01-Introduction/01-simulation-background-imgs/m5-isca-2005.png)

---

## 然后是 GEMS

![M5 和 GEMS 的 Logo](/bootcamp/01-Introduction/01-simulation-background-imgs/m5-gems.drawio.svg)

---

<!-- _class: center-image -->

## ISCA 2005 上的 GEMS

![GEMS slide from ISCA tutorial height:500px](/bootcamp/01-Introduction/01-simulation-background-imgs/gems-isca-2005.png)

---

## 现在，我们有两个模拟器...

![M5 和 GEMS 的 Logo](/bootcamp/01-Introduction/01-simulation-background-imgs/m5-gems.drawio.svg)

---

## gem5 是什么？

### 密歇根 m5 + 威斯康星 GEMS = gem5

> "gem5 模拟器是一个用于计算机系统体系结构研究的模块化平台，涵盖系统级体系结构以及处理器微体系结构。"

### gem5 的引用

Lowe-Power et al. The gem5 Simulator: Version 20.0+. ArXiv Preprint ArXiv:2007.03152, 2021. <https://doi.org/10.48550/arXiv.2007.03152>

Nathan Binkert, Bradford Beckmann, Gabriel Black, Steven K. Reinhardt, Ali Saidi, Arkaprava Basu, Joel Hestness, Derek R. Hower, Tushar Krishna, Somayeh Sardashti, Rathijit Sen, Korey Sewell, Muhammad Shoaib, Nilay Vaish, Mark D. Hill, and David A. Wood. 2011. The gem5 simulator. SIGARCH Comput. Archit. News 39, 2 (August 2011), 1-7. DOI=<http://dx.doi.org/10.1145/2024716.2024718>

---

<!-- _class: no-logo -->

## gem5-20+：计算机体系结构模拟的新时代

![gem5-20+](/bootcamp/01-Introduction/01-simulation-background-imgs/gem5-20plus.drawio.png)

---

## gem5 的目标

![计算机体系结构栈 height:500px](/bootcamp/01-Introduction/01-simulation-background-imgs/arch-stack.png)

![bg right agile hardware methodology fit](/bootcamp/01-Introduction/01-simulation-background-imgs/agile-hardware.png)

---

## gem5 的目标

### 任何人（包括非体系结构专家）都可以下载并使用 gem5

### 用于跨栈研究：

- 同时更改内核、运行时和硬件
- 运行完整的 ML 栈、完整的 AR/VR 栈……其他新兴应用

### 我们很接近了……只是还有很多粗糙的边缘！您可以提供帮助！

---

<!-- _class: logo-left -->

## gem5 社区

数百名贡献者和数千名（？）用户

### 旨在满足以下需求

- 学术研究（你们中的大多数人！）
- 工业研发
- 课堂教学

行为准则（参见仓库）

### _我们希望看到社区成长！_

![一群工蜂改进底层计算机硬件的社区 bg right](/bootcamp/01-Introduction/01-simulation-background-imgs/gem5-community.jpg)

---

<!-- _class: start -->

## 我对模拟的看法

---

![计算机系统研究和科学方法 bg left:60% fit](/bootcamp/01-Introduction/01-simulation-background-imgs/systems-research.png)

来自 Lieven Eeckhout 的 [Computer Architecture Performance Evaluation Methods](https://link.springer.com/book/10.1007/978-3-031-01727-8)

高亮块是计算机体系结构模拟的适用位置

---

## 为什么需要模拟？

---

## 为什么需要模拟？（答案）

- 需要工具来评估尚不存在的系统
  - 性能、功耗、能耗等
- 实际制造硬件成本非常高
- 计算机系统很复杂，有许多相互依赖的部分
  - 没有完整系统很难做到准确
- 模拟可以参数化
  - 设计空间探索
  - 敏感性分析

---

## 周期级模拟的替代方案：分析建模

### 阿姆达尔定律

$$ S_{latency}(s) = \frac{1}{(1-p) + \frac{p}{s}} $$

### 排队论

![排队论 bg auto](/bootcamp/01-Introduction/01-simulation-background-imgs/queuing.png)

<br><br> <!-- needed for image above -->

$$ L = \lambda W $$

---

## 模拟的类型

- 功能模拟
- 基于插桩的模拟
- 基于跟踪的模拟
- 执行驱动模拟
- 全系统模拟

---

## 模拟的类型：详细信息

- 功能模拟
  - 正确执行程序。通常没有时序信息
  - 用于验证编译器等的正确性
  - RISC-V Spike、QEMU、gem5 "atomic" 模式
- 基于插桩的模拟
  - 通常是二进制翻译。在实际硬件上运行并带有回调
  - 类似于基于跟踪的模拟。对新 ISA 不灵活。某些内容不透明
  - PIN、NVBit
- 基于跟踪的模拟
  - 生成地址/事件并重新执行
  - 可以很快（不需要进行功能模拟）。重用跟踪
  - 如果执行依赖于时序，这将不起作用！
  - 针对单个方面的"专用"模拟器（例如，仅缓存命中/未命中）

---

## 模拟的类型：执行驱动和全系统

### 执行驱动

- 功能模拟和时序模拟相结合
- gem5 和许多其他模拟器
- gem5 是"执行中的执行"或"时序导向"

### 全系统

- 组件建模具有足够的保真度，可以运行大部分未修改的应用程序
- 通常是"裸机"模拟
- 程序的所有部分都由模拟器进行功能仿真
- 通常意味着在模拟器中运行操作系统，而不是伪造它

"全系统"模拟器通常结合了功能模拟和执行驱动模拟

---

## 术语（虚拟机）

- **宿主机 (Host)：** 您正在使用的实际硬件
- 直接在硬件上运行：
  - **原生执行 (Native execution)**
- **客户机 (Guest)：** 在"虚拟"硬件上运行的代码
  - 虚拟机中的操作系统是客户操作系统
  - 运行在"虚拟机监控程序之上"
  - 虚拟机监控程序正在模拟硬件

![您的系统和虚拟化系统的层次 bg right:45% 90%](/bootcamp/01-Introduction/01-simulation-background-imgs/vm-nomenclature.drawio.svg)

---

## 术语（gem5）

- **宿主机 (Host)：** 您正在使用的实际硬件
- **模拟器 (Simulator)：** 在宿主机上运行
  - 向客户机暴露硬件
- **客户机 (Guest)：** 在模拟硬件上运行的代码
  - 在 gem5 上运行的操作系统是客户操作系统
  - gem5 正在模拟硬件
- **模拟器的代码：** 原生运行
  - 执行/仿真客户代码
- **客户机的代码：**（或基准测试、工作负载等）
  - 在 gem5 上运行，而不是在宿主机上

![您的系统和虚拟化系统的层次 bg right:45% 90%](/bootcamp/01-Introduction/01-simulation-background-imgs/gem5-nomenclature.drawio.svg)

---

## 术语（更多 gem5）

- **宿主机 (Host)：** 您正在使用的实际硬件
- **模拟器 (Simulator)：** 在宿主机上运行
  - 向客户机暴露硬件
- **模拟器的性能：**
  - 在宿主机上运行模拟所需的时间
  - 您感知到的挂钟时间
- **模拟性能：**
  - 模拟器预测的时间
  - 客户代码在模拟器上运行的时间

![您的系统和虚拟化系统的层次 bg right:45% 90%](/bootcamp/01-Introduction/01-simulation-background-imgs/gem5-nomenclature.drawio.svg)

---

## 模拟类型的权衡

- 开发时间：制作模拟器/模型所需的时间
- 评估时间：运行模拟器的挂钟时间
- 准确性：模拟器与真实硬件的接近程度
- 覆盖范围：模拟器可以广泛使用的程度？

![来自《计算机体系结构性能评估方法》的表格](/bootcamp/01-Introduction/01-simulation-background-imgs/tradeoffs.png)

---

## 我们应该在什么级别进行模拟？

- 问自己：这个问题需要什么保真度？
  - 示例：新的寄存器文件设计
  - 通常，答案是混合的。
- gem5 非常适合这种混合
  - 具有不同保真度的模型
  - 可以相互替换

### "周期级"与"周期精确"

---

## RTL 模拟

- RTL：寄存器传输级/逻辑
  - "模型"就是硬件设计
  - 您指定每根线和每个寄存器
  - 接近实际的 ASIC
- 这是"周期精确"的，因为它在模型和 ASIC 中应该是相同的
- 保真度非常高，但以可配置性为代价
  - 需要完整的设计
  - 更难结合功能和时序

---

## 周期级模拟

- 逐周期建模系统
- 通常是"事件驱动"（我们很快就会看到）
- 可以高度准确
  - 与 ASIC 的逐周期不完全相同，但时序相似
- 易于参数化
  - 不需要完整的硬件设计
- 比周期精确更快
  - 可以"作弊"并在功能上模拟某些内容

---

<!-- _class: start -->

## gem5 的软件架构

---

## 软件架构

![模型、标准库和模拟控制的图表](/bootcamp/01-Introduction/01-simulation-background-imgs/gem5-software-arch.drawio.svg)

---

## gem5 架构：SimObject

### 模型

这是 **`src/`** 中的 `C++` 代码

### 参数

**`src/`** 中的 Python 代码
在 SimObject 声明文件中

### 实例或配置

参数的具体选择
在标准库、您的扩展或 Python 运行脚本中

---

## 模型与参数

- **模型：** 执行时序模拟的 `C++` 代码
  - 通用
- 向 Python 暴露**参数**
- 在 Python 中设置**参数**和连接

![来自 wikichip 的 Sunny Cove 架构图片 bg right fit](/bootcamp/01-Introduction/01-simulation-background-imgs/Sunny_cove_block_diagram.png)

---

## 一些术语

### 您可以**_扩展_**模型以建模新事物

在这种情况下，您应该在 C++ 中从对象_继承_

```cpp
class O3CPU : public BaseCPU
{
```

### 您可以**_特化_**模型以使用特定参数进行建模

在这种情况下，您应该在 Python 中从对象_继承_

```python
class i7CPU(O3CPU):
    issue_width = 10
```

---

## gem5 架构：模拟

gem5 是一个**_离散事件模拟器_**

在每个时间步，gem5：

1. 队首的事件被出队
2. 执行该事件
3. 调度新事件

![离散事件模拟示例 bg right:55% fit](/bootcamp/01-Introduction/01-simulation-background-imgs/des-1.drawio.svg)

---

<!-- _paginate: hold -->

## gem5 架构：模拟

gem5 是一个**_离散事件模拟器_**

在每个时间步，gem5：

1. 队首的事件被出队
2. 执行该事件
3. 调度新事件

![离散事件模拟示例 bg right:55% fit](/bootcamp/01-Introduction/01-simulation-background-imgs/des-2.drawio.svg)

---

<!-- _paginate: hold -->

## gem5 架构：模拟

gem5 是一个**_离散事件模拟器_**

在每个时间步，gem5：

1. 队首的事件被出队
2. 执行该事件
3. 调度新事件

> **所有 SimObject 都可以将事件入队到事件队列中**

![离散事件模拟示例 bg right:55% fit](/bootcamp/01-Introduction/01-simulation-background-imgs/des-3.drawio.svg)

---

## 离散事件模拟示例

![离散事件模拟示例 fit](/bootcamp/01-Introduction/01-simulation-background-imgs/des-example-1.drawio.svg)

---

<!-- _paginate: hold -->

## 离散事件模拟示例

![离散事件模拟示例 fit](/bootcamp/01-Introduction/01-simulation-background-imgs/des-example-2.drawio.svg)

---

<!-- _paginate: hold -->

## 离散事件模拟示例

![离散事件模拟示例 fit](/bootcamp/01-Introduction/01-simulation-background-imgs/des-example-3.drawio.svg)

要建模需要时间的事物，请在将来调度_下一个_事件（当前事件的延迟）。
可以调用函数而不是调度事件，但它们发生在_同一个 tick_中。

---

## 离散事件模拟

"时间"需要一个单位。
在 gem5 中，我们使用一个称为 "Tick" 的单位。

需要将模拟 "tick" 转换为用户可理解的时间
例如，秒。

这是全局模拟 tick 速率。
通常是每个 tick 1 ps 或每秒 $10^{12}$ 个 tick

---

<!-- _class: center-image -->

## gem5 的主要抽象：内存

### 内存请求

- **端口 (Ports)** 允许您发送请求并接收响应。
- 端口是单向的（两种类型，请求/响应）。
- 任何带有请求端口的对象*都可以连接到任何响应端口。
- 更多内容请参见[端口和基于内存的 SimObject](../03-Developing-gem5-models/04-ports.md)。

![CPU 通过端口与缓存通信](/bootcamp/01-Introduction/01-simulation-background-imgs/abstractions-1.drawio.svg)

---

<!-- _class: center-image -->

## gem5 的主要抽象：CPU

### ISA 与 CPU 模型

- ISA 和 CPU 模型是正交的。
- 任何 ISA 都应该与任何 CPU 模型一起工作。
- "执行上下文 (Execution Context)" 是接口。
- 更多内容请参见[建模核心](../03-Developing-gem5-models/05-modeling-cores.md)。

![ISA-CPU 交互以及 CPU 通过端口与缓存通信](/bootcamp/01-Introduction/01-simulation-background-imgs/abstractions-2.drawio.svg)
