---
layout: post
title:  "迈向全系统独立 GPU 模拟"
author: Mattew Poremba, Alexandru Dutu, Gaurav Jain, Pouya Fotouhi, Michael Boyer, and Bradford M. Beckmann.
date:   2020-06-01
---

AMD Research 正在开发一个全系统 GPU（图形处理单元）模型，能够使用 amdgpu Linux 内核驱动程序和最新的软件堆栈。此前，AMD 更新了 gem5 [1] GPU 计算时序模型以执行 GCN（Graphics Core Next）第三代机器 ISA [2,3]，但它仍然依赖于系统调用仿真。通过全系统支持，该模型可以在不修改的情况下运行最新的开源 Radeon Open Compute 平台 (ROCm) 堆栈。这允许用户运行用多种高级语言编写的各种应用程序，包括 C++、HIP、OpenMP 和 OpenCL。这为研究人员提供了评估多种不同类型工作负载的能力，从传统的计算应用程序到新兴的现代 GPU 工作负载，如任务并行和机器学习应用程序。由此产生的 AMD gem5 GPU 模拟器是一个周期级、灵活的研究模型，能够表示许多不同的 GPU 配置、片上缓存层次结构和系统设计。该模型在过去几年中被用于多篇顶级计算机体系结构出版物中。

在本演示中，我们将描述 AMD gem5 GPU 模拟器的功能，该模拟器将以 BSD 许可证公开发布。我们将详细介绍模拟更改并描述新的执行流程。演示还将重点介绍全系统支持提供的新功能。特别是，模拟将更加确定性，并允许用户使用 KVM 快速转发运行主机端 CPU 代码。我们将详细介绍正在添加的额外支持，包括多上下文虚拟内存支持、系统 DMA 引擎以及它们之间软件接口的支持。

[1] Binkert, Nate L., et al. “The gem5 Simulator,” In SIGARCH Computer Arch. News, vol. 39, no. 2, pp. 1-7, Aug. 2011.

[2] AMD. “AMD GCN3 ISA Architecture Manual”, https://gpuopen.com/compute-product/amd-gcn3-isa-architecture-manual/

[3] Gutierrez, Anthony et al. “The Updated AMD gem5 APU Simulator: Modeling GPUs Using the Machine ISA” ISCA tutorial 2018.

## Workshop Presentation
<iframe width="560" height="315" src="https://www.youtube.com/embed/cpnoUgcGjuI" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
