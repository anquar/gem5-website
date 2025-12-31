---
layout: bootcamp
title: gem5 入门
permalink: /bootcamp/introduction/introduction-to-bootcamp
section: introduction
author: Jason Lowe-Power
---
<!-- _class: title -->

## 欢迎参加 gem5 训练营！

---

## 关于训练营的整体结构

这些幻灯片可在 <https://bootcamp.gem5.org/> 获取，供您跟随学习。

（注意：它们将被归档到 <https://gem5bootcamp.github.io/2024>）

幻灯片的源代码以及您在整个训练营中将使用的内容可以在 GitHub 上找到：<https://github.com/gem5bootcamp/2024>

> 注意：暂时不要克隆该仓库。我们稍后会进行。

---

<!-- _class: two-col -->

## 关于我

我是 **Jason Lowe-Power 教授**（他/他）。
我是计算机科学系的副教授，也是 gem5 项目的*项目管理委员会主席*。

我领导戴维斯计算机体系结构研究 (DArchR) 小组。

<https://arch.cs.ucdavis.edu>

![UC Davis logo width:500px](/bootcamp/01-Introduction/00-introduction-to-bootcamp-imgs/expanded_logo_gold-blue.png)

![DArchR logo width:550px](/bootcamp/01-Introduction/00-introduction-to-bootcamp-imgs/darchr.png)

---

## 训练营团队

![所有为训练营做出贡献的人员 width:1200px](/bootcamp/01-Introduction/00-introduction-to-bootcamp-imgs/devs.drawio.svg)

---

<!-- _class: outline -->

## 本周计划

### 第 1 天

- 介绍
  - [模拟背景](01-simulation-background.md) <!-- 1 hour (Jason) -->
    - 什么是模拟以及为什么它很重要
    - gem5 历史
  - [gem5 入门](02-getting-started.md) <!-- 30 minutes (Jason) -->
    - 进入 codespace 环境
    - 运行您的第一次模拟
  - [Python 和 gem5 背景](03-python-background.md) <!--  1.5 hours (Bobby) -->
    - Python 基础
    - gem5 中的 Python
    - Python 中的面向对象编程
- 使用 gem5
  - [gem5 标准库](../02-Using-gem5/01-stdlib.md) <!--  2 hours (Bobby) -->
  - [gem5 资源](../02-Using-gem5/02-gem5-resources.md) <!--  1 hour (Harshil) -->
    - 什么是资源？（磁盘、内核、二进制文件等）
    - 如何获取资源
    - 如何使用资源
    - 工作负载和套件
    - 本地资源

### 第 2 天

- 使用 gem5
  - [在 gem5 中运行程序](../02-Using-gem5/03-running-in-gem5.md) <!--  2 hours (Erin / Zhantong) -->
    - 系统调用仿真模式介绍
    - gem5-bridge 工具和库
    - 交叉编译
    - 流量生成器（测试板）
    - SE 模式下的 Process.map 和驱动程序（可能删除）
  - [在 gem5 中建模核心](../02-Using-gem5/04-cores.md) <!--  1 hour (Mysore / Jason) -->
    - gem5 中的 CPU 模型
    - 使用 CPU 模型
    - 分支预测器
    - 查看 gem5 生成的统计信息
    - ISA 概述和权衡
  - [在 gem5 中建模缓存](../02-Using-gem5/05-cache-hierarchies.md) <!--  1.5 hour (Leo / Mahyar) -->
    - gem5 中的缓存模型（Ruby 和经典）
    - 使用缓存模型
    - 替换策略
    - 标签策略
    - 经典和 Ruby 之间的权衡
    - 查看 gem5 生成的统计信息
  - [在 gem5 中建模内存](../02-Using-gem5/06-memory.md) <!-- 1 hours (Noah / William (Maryam)) -->
    - gem5 中的内存模型
    - 使用内存模型
    - 使用流量生成器测试内存
    - Comm Monitor
  - [全系统模拟](../02-Using-gem5/07-full-system.md) <!--(Harshil) 1 hour -->
    - 什么是全系统模拟？
    - 在 gem5 中启动真实系统的基础知识
    - 使用 packer 和 qemu 创建磁盘镜像
    - 扩展/修改 gem5 磁盘镜像
    - 使用 m5term 与运行中的系统交互

### 第 3 天

- 使用 gem5
  - [加速模拟](../02-Using-gem5/08-accelerating-simulation.md) <!--  (Zhantong) 0.5 hours -->
    - KVM 快速转发
    - 检查点
  - [使用 gem5 进行采样模拟](../02-Using-gem5/09-sampling.md) <!--  (Zhantong) 1.5 hours -->
    - Simpoint 和 Looppoint 概念
    - Simpoint 和 Loopoint 分析
    - Simpoint 和 Loopoint 检查点
    - 如何分析采样模拟数据
    - 统计模拟概念
    - 统计模拟运行和分析
  - [功耗建模](../02-Using-gem5/10-modeling-power.md) <!--  (Jason?) -->
  - [Multisim](../02-Using-gem5/11-multisim.md) <!-- (Bobby) (10 minutes) -->
    - 使用 multisim 的示例
- 开发 gem5 模型
  - [SimObject 介绍](../03-Developing-gem5-models/01-sim-objects-intro.md) <!-- (Mahyar) 0.5 hours -->
    - 开发环境、代码风格、git 分支
    - 最简单的 `SimObject`
    - 简单的运行脚本
    - 如何向 `SimObject` 添加参数
  - [调试和调试标志](../03-Developing-gem5-models/02-debugging-gem5.md) <!-- (Mahyar) 0.5 hours -->
    - 如何启用调试标志（DRAM 和 Exec 的示例）
    - `--debug-help`
    - 添加新的调试标志
    - DPRINTF 之外的其他函数
    - Panic/fatal/assert
    - gdb？
  - [事件驱动模拟](../03-Developing-gem5-models/03-event-driven-sim.md) <!-- (Mahyar) 1 hours -->
    - 创建简单的回调事件
    - 调度事件
    - 使用事件建模带宽和延迟
    - 其他 SimObject 作为参数
    - 带缓冲区的 Hello/Goodbye 示例
    - 时钟域？

### 第 4 天

- 开发 gem5 模型
  - [建模核心](../03-Developing-gem5-models/05-modeling-cores.md) <!-- (Bobby) 1.5 hours -->
    - 新指令
    - 执行模型的工作原理
    - 调试
  - [使用 Ruby 和 SLICC 建模缓存一致性](../03-Developing-gem5-models/06-modeling-cache-coherence.md) <!--  (Jason) 1.5 hours -->
    - Ruby 介绍
    - SLICC 的结构
    - 构建/运行/配置协议
    - 调试
    - Ruby 网络
    - （给 Jason 的注释：如果像以前那样拆分，可以在这里做一整天。）
  - [扩展 gem5](../03-Developing-gem5-models/09-extending-gem5-models.md) <!-- (Zhantong) 1 hours -->
    - 探测点
    - 通用缓存对象
    - 基础工具（例如，bitset）
    - 随机数
    - 信号端口？
- [GPU 建模](../04-GPU-model/01-intro.md) <!-- (Matt S.) -->

### 第 5 天

- 开发 gem5 模型
  - [端口和基于内存的 SimObject](../03-Developing-gem5-models/04-ports.md) <!-- (Mahyar) 1 hours -->
    - 端口的概念（请求/响应）、数据包、接口
    - 转发数据的简单内存对象
    - 连接端口和编写配置文件
    - 向 SimObject 添加统计信息
    - 添加延迟以及建模缓冲区/计算时间
  - [使用 CHI 协议](../03-Developing-gem5-models/07-chi-protocol.md) <!-- (Jason) 0.5 hours -->
    - CHI 与其他协议有何不同？
    - 配置 CHI 层次结构
  - [使用 Garnet 建模片上网络](../03-Developing-gem5-models/08-ruby-network.md) <!-- (Jason) 1 hours -->
    - Garnet 介绍
    - 构建/运行/配置网络
    - 调试
- 其他模拟器 <!-- (Jason?) -->
  - [SST](../05-Other-simulators/01-sst.md)
  - [DRAMSim/DRAMSys](../05-Other-simulators/02-dram.md)
  - [SystemC](../05-Other-simulators/03-systemc.md)
- 为 gem5 做贡献 <!-- (Bobby) -->
  - [gem5 贡献流程](../06-Contributing-to-gem5/01-contributing.md)
  - [gem5 测试](../06-Contributing-to-gem5/02-testing.md)

---

## gem5 训练营的目标

- 让 gem5 使用起来不那么困难，并降低学习曲线
- 为您提供提问的词汇表
- 为未来提供参考
- 为您提供可以带回并教授给同事的材料

### 其他可能的结果

- 您会被大量的信息和 gem5 的庞大所震撼
  - 没关系！您可以随身携带这些材料并随时查阅
- 您不会理解所有内容
  - 没关系！我们可以在进行过程中提问

---

## 这将如何运作

- 我们将主要采用自上而下的方式
  1. 如何使用 gem5
  2. 如何使用每个模型
  3. 如何开发您自己的模型并修改现有模型
- 高度迭代：
  - 您会反复看到相同的内容
  - 每次都会深入一个层次
- 大量编码示例
  - 包括现场编码和实践问题

---

## 编码示例

您可以编写以下代码

```python
print("Hello, world!")
print("You'll be seeing a lot of Python code")
print("The slides will be a reference, but we'll be doing a lot of live coding!")
```

您将看到以下输出。

```console
Hello, world!
You'll be seeing a lot of Python code
The slides will be a reference, but we'll be doing a lot of live coding!
```

---

## 训练营后勤安排

我们每天将从上午 9 点到下午 4 点在这里。

午餐时间约为中午 12 点到下午 1 点。

我们将在上午和下午有休息时间。

下午休息时间将提供咖啡/零食。

今晚：在 [Dunloe Brewing](https://dunloebrewing.com/)（Olive Drive Brewery）举行招待会
下午 5:30 - 8:00。下午 5 点从这里步行前往。

周三：在 UC Davis ["Games Area"](https://memorialunion.ucdavis.edu/games-area) 举行社交活动（保龄球、台球、电子游戏等）
晚上 6:30 - 9:30。

---

## 其他管理事项

---

## 重要资源

### 训练营链接

- [训练营网站](https://gem5bootcamp.gem5.org/)（也许您现在就在这里）
  - [训练营归档](https://gem5bootcamp.github.io/2024)（如果您稍后访问）
- [训练营材料源代码](https://github.com/gem5bootcamp/2024)（您将在这里工作）
- [GitHub Classroom](https://classroom.github.com/a/gCcXlgBs)（使用 codespaces 所需）

### gem5 链接

- [gem5 代码](https://github.com/gem5/gem5)
- [gem5 网站](https://www.gem5.org/)
- [gem5 YouTube](https://youtube.com/@gem5)
- [gem5 Slack](https://gem5-workspace.slack.com/join/shared_invite/zt-2e2nfln38-xsIkN1aRmofRlAHOIkZaEA)（用于离线提问）
