---
layout: post
title: "ISCA 2025：迈向全系统异构模拟：将 gem5-SALAM 合并到 gem5 主线"
author: Akanksha Chaudhari, Matt Sinclair(UW-Madison).
date:   2025-07-30
---

# 迈向 gem5 中的全系统异构模拟

随着 SoC 架构变得越来越异构，它们现在不仅集成了 CPU 和 GPU，还集成了为特定工作负载量身定制的紧密耦合的可编程加速器。这些加速器对于移动推理、AR/VR、实时视觉和边缘分析等新兴领域至关重要。与传统的 CPU-GPU 系统不同，现代异构平台需要不同计算引擎、共享内存子系统和软件管理的执行模型之间的细粒度协调。捕获这些交互需要周期级、全系统模拟器。

虽然 gem5 长期以来支持详细的 CPU 模拟，并且最近支持全系统 GPU 建模，但对可编程加速器的支持仍然通过 gem5-SALAM 等工具在外部——基于 gem5 v21.1 构建。尽管 SALAM 添加了加速器特定的功能，如周期级数据路径建模、内存映射暂存器和硬件综合集成，但它与主线隔离。因此，它无法利用最近的 ISA、内存系统或配置基础设施更新，也无法从上游验证中受益。

为了缩小这一差距，我们将 SALAM 的加速器基础设施集成到 gem5 主线（develop 分支 v25）中。这种统一将加速器提升为与 CPU 和 GPU 并列的一流组件，在单个软件堆栈下实现全系统异构模拟。结果是用于建模异构 SoC 的统一框架，具有真实的 OS 支持、共享资源争用和软件控制的任务编排。

## 集成概览

我们通过一系列架构、接口和验证更新将 SALAM 的加速器建模基础设施集成到 gem5-develop 中。

我们首先将 SALAM 的关键加速器建模组件集成到 gem5 中。这些包括 `LLVMInterface`，它使用周期精确的数据路径执行 LLVM IR 内核；`CommInterface`，它提供软件可见的控制和中断信号；以及一套可配置的内存组件，如暂存器、DMA 引擎和流缓冲区。这些元素共同实现了对各种加速器微架构和内存层次结构的详细和灵活建模。为了支持真实的 SoC 集成，加速器和本地内存可以分组到 `AccCluster` 中，反映了商业 SoC 中常见的加速器子系统的模块化结构。为了快速原型设计，我们还集成并自动化了 SALAM 的硬件配置文件生成器，它将用户定义的时序规范转换为可执行的数据路径模型——消除了手动微架构实现的需要。最后，我们重构了 CACTI-SALAM 以与 gem5 的基础设施兼容，使用 CACTI 的基于文件的配置方法实现暂存器的时序和能量估计。这些更改将周期级加速器建模、全系统内存交互和可扩展的设计空间探索带入 gem5 主线。

然后，我们更新了 SALAM 的加速器基础设施以匹配 gem5 的最新设计约定。这包括重构类以使用现代 SimObject 模式，用类型安全的 32 位变量替换 LLVM 指令处理中的不安全指针转换，以及切换到 gem5 的标准化随机数生成器进行延迟建模。我们修复了地址范围定义中的差一错误以遵循 gem5 的包含-排除语义，将环境和 ISA 配置与 gem5 的当前设置对齐，并添加了使用 `llvm-config` 的动态 LLVM 检测以简化基于 SCons 的数据路径模拟编译。

最后，我们通过确保它通过 gem5 的预提交检查和完整回归测试套件来验证集成框架。此外，我们调整了 SALAM 的原始系统验证测试以在统一环境中运行，并将输出与原始 SALAM 基线进行交叉验证以确认功能等价性。我们计划将这些加速器测试上游到 gem5-resources 仓库，以支持在 gem5 内对集成的 SALAM 组件进行更广泛的验证。

## 这使什么成为可能

### 更广泛的异构研究

随着加速器现在完全集成到 gem5 主线中，研究人员可以模拟完整的异构系统，包括 CPU、GPU 和自定义加速器——在单个 OS 内核下共存并共享互连和内存。这允许对不同计算引擎之间的性能干扰、资源仲裁和同步机制进行详细研究，基于全系统行为而不是简化模型。

### 系统级探索

该框架支持在系统级别对架构权衡进行丰富的探索。用户可以评估不同的内存组织——如私有暂存器、共享 LLC 或 DMA 管理的 SPM——并比较卸载、同步和内核放置的策略。静态与动态调度、位置感知内存分区和软件管理的 DMA 方案都可以在真实的 OS 驱动设置中进行研究。

### 领域特定工作负载支持

此基础设施还支持针对新兴领域的架构研究，如实时视觉、移动推理、AR/VR 和边缘计算。这些应用程序需要可预测的延迟、软件-加速器协调和仔细的内存管理。集成框架允许研究人员使用真实的软件堆栈和可启动的 Linux 镜像对这些工作负载进行建模和研究，加速器行为以周期级保真度模拟。

### 非传统机制的探索性研究

最后，该工具链支持在新兴机制下探索加速器操作，如瞬态超频和先进冷却。在我们的研讨会论文中，我们使用此框架研究了一个这样的非传统操作机制案例：加速器中的多 GHz 频率缩放，由先进冷却技术（如浸没和低温系统）实现。我们对此范围内的性能和功率上限进行了初步分析。结果显示系统瓶颈如何随着频率增加而转移，突出了在主机延迟和内存交互的背景下评估加速器行为的重要性。实验设置和发现的完整详细信息包含在我们的 ISCA '25 研讨会论文中。

用户可以使用内置的加速器模型和基准测试将此框架应用于上述用例，或通过建模自己的自定义加速器进一步扩展它。

## 建模您自己的加速器

在集成的 gem5 框架中创建新的加速器模型很简单。您首先用 C/C++ 编写所需的加速器算法并编译为 LLVM IR。基于 YAML 的硬件配置文件指定指令时序、功能单元延迟和内存端口。此配置文件由硬件配置文件生成器处理以生成周期级时序模型。

然后，用户将加速器放置在 `AccCluster` 内，根据需要附加暂存器或 DMA，并使用 gem5 的 Python 接口配置系统拓扑。在模拟 OS 中运行的主机端程序通过内存映射控制寄存器和中断与加速器协调。使用 `run_system.sh` 模拟完整系统，生成统计信息、可选的功率报告和主机端控制台输出。

## 开始使用

要开始使用，请将以下环境变量设置为您 gem5 和基准测试的根目录：

```bash
export M5_PATH=/path/to/gem5
export ACC_BENCH_PATH=/path/to/benchmarks
```

克隆并构建 gem5：

```bash
git clone https://github.com/akanksha-sc/gem5
cd gem5
scons build/ARM/gem5.opt -j$(nproc)
```

生成自定义硬件配置文件（可选）：

```bash
$M5_PATH/tools/hw_generator/HWProfileGenerator.py -b <benchmark_name>
```

运行 CACTI-SALAM（可选的能量/面积估计）：

```bash
cd $M5_PATH/tools/cacti-SALAM
./run_cacti_salam.py --bench-list $ACC_BENCH_PATH/benchmarks.list
```

运行基准测试（自定义或内置的，如 `bfs`）：

```bash
$M5_PATH/tools/run_system.sh --bench <benchmark_name> --bench-path <benchmark_path>
```

这会启动 Linux，启动用户空间驱动程序，并模拟加速器。输出包括 `stats.txt`（性能计数器）、`system.terminal`（主机控制台输出）、`SALAM_power.csv`（功率/面积估计，如果使用 CACTI-SALAM）。其他示例和文档包含在 `src/hwacc/docs` 中。

## 结论

此集成将 gem5 定位为异构 SoC 的统一全系统模拟器——在一个框架下结合 CPU、GPU 和可编程加速器，具有真实的时序、软件和架构细节。它为从协同调度和内存系统调整到高频加速器和先进冷却分析的研究打开了大门。下一步包括将支持合并到 gem5 主线，使用领域特定工作负载扩展基准测试套件，并将全系统加速器支持扩展到其他 ISA。我们希望这个基础能够加速整个社区的异构系统研究。

## 致谢

这项工作部分得到了半导体研究公司和 DOE 科学办公室、先进科学计算研究办公室通过 EXPRESS：2023 极端规模科学探索研究的支持。

## 参考文献

* A. Chaudhari and M. D. Sinclair. "Toward Full-System Heterogeneous Simulation: Merging gem5-SALAM with Mainline gem5." 6th gem5 Users' Workshop, June 2025.
* S. Rogers, J. Slycord, M. Baharani and H. Tabkhi, "gem5-SALAM: A System Architecture for LLVM-based Accelerator Modeling," 2020 53rd Annual IEEE/ACM International Symposium on Microarchitecture (MICRO), Athens, Greece, 2020, pp. 471-482, doi: 10.1109/MICRO50266.2020.00047.
