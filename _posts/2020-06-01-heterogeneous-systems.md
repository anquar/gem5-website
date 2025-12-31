---
layout: post
title:  "自适应流量配置文件：在 gem5 中建模异构系统的工具"
author: Matteo Andreozzi, Frances Conboy, Giovanni Stea, and Raffaele Zippo
date:   2020-06-01
---

由各种设备组成的异构系统特别难以为目标用例设计和确定规模。迫切需要能够促进其设计空间探索的工具，以便设计人员和测试人员能够预测或测量其目标用例的性能。另一方面，新一代应用程序，如自动驾驶或工业 4.0 应用程序，对异构系统提出了具有挑战性的要求。这些应用程序是时间关键的，意味着必须事先保证其执行时间的严格上界，否则它们将危及人类的安全和财产。

为了满足上述两个要求，Arm 最近发布了 AMBA 自适应流量配置文件 (ATP) 框架作为开源参考实现。ATP 是一种可移植的方式，用于为异构系统的验证和/或设计空间探索生成输入。ATP 通过简单的基于规则的语法模拟异构系统中主设备的流量注入模式，例如，GPU 访问一系列连续的 RAM 地址。ATP 应用程序可以在独立模式下运行，ATP 主设备与 ATP 从设备通信，或者在混合模式下运行，主机平台（如 gem5 模拟器）充当流量转发器。我们介绍 ATP 语法和功能的基础知识，然后展示我们如何使用后者，与 gem5 一起，为 First-Ready、First-Come-First-Served (FR-FCFS) DRAM 控制器设计准最坏情况场景。这使我们能够对分析技术的结果进行基准测试，以计算同一系统的最坏情况延迟 (WCD) 的上界：通过将（可能悲观的）分析上界与使用由 ATP 配置文件提供的 gem5 模拟获得的结果进行比较，我们可以限制分析技术的悲观性。

ATP 是一个合成流量建模框架，表示执行工作负载的设备。主 ATP 模拟主设备（例如，GPU）将做什么，即根据可配置的时序属性（例如，每 100 ns 一个新请求）和目标地址发送内存请求并接收响应。其对应物是从 ATP，它模拟从设备（例如，内存）将做什么，即根据固定延迟和带宽响应请求。两者都可以有未完成事务的限制，之后它们被锁定，即无法根据配置的时序继续执行。当未完成的事务再次低于限制时（例如，因为从设备已响应主设备的请求），ATP 恢复到其活动状态。

<img src="/assets/img/blog/heterogeneous-systems/fig0.png" alt="Figure 1" width="10">
<br>
<em>Figure 1.</em>


ATP 的基本构建块是 ATP FIFO。这些可以组合形成复杂的行为，就像基本谐波可以组合成复杂波形一样。ATP FIFO 是一个具有自己大小和速率的队列。写 FIFO 模拟生产者，读 FIFO 模拟消费者。在写 FIFO 中，内存请求操作将缓冲区填充到其大小，而内存响应则将其排空。如果发生缓冲区溢出，事件被记录，相应的配置文件被锁定。读 FIFO 是写 FIFO 的对偶，行为非常相似：其速率是消耗速率，即信息被消耗的速率。可以设置附加参数 TxnLimit 以限制在任何给定时间的未完成事务数。ATP FIFO 与模式关联，描述如何填充事务的地址和数据大小字段。ATP FIFO Profile 元素将 FIFO 和模式对象组合成一个自包含的描述符，并将其分配给系统设备主设备，如示例所示。在此示例中，FIFO 将以 1GB/s 的速率生成最多 1000 个读取请求，请求长度为 64B，地址每次递增 64。延迟容差约为 (FIFO 大小 - 包大小)/速率 = 1.85 us。

AMBA ATP 框架附带自己的平台无关引擎，可以插入到事件或时间驱动的建模、模拟和测试平台中。ATP 已经包括一个 gem5 适配器层，因此它可以与 gem5 集成，用户无需任何努力。gem5 适配器 ProfileGen 实现为 MemObject 派生类，允许 gem5 从 ATP 引擎发送和接收内存请求和响应包。ProfileGen 通过实例化专用于各个 ATP 主设备的可配置数量的主端口连接到其他 gem5 对象，通过这些端口它发送和接收来自/发往这些主设备的包。

正如预期的那样，我们使用 ATP 和 gem5 尝试最大化 FR-FCFS DRAM 控制器的访问延迟，如下图所示。特别是，我们希望获得读取请求可能遭受的最大延迟的估计，作为其在控制器读取队列中位置的函数。读取请求可以是命中或未命中。后者需要在访问 DRAM 单元之前"打开行"，因此会产生额外的延迟。前者不需要，因此被赋予优先级以最大化效率 - 因此称为"First-ready"。未命中的读取请求改为按 FCFS 调度。写入请求单独排队，写入队列在其水位 W 以上时被服务。在写入模式下，控制器在切换回服务读取之前连续服务一批 N_wd 写入。最后，发生周期性 DRAM 刷新以避免数据丢失。假设：a) 读取命中超越的数量由已知限制上界，称为 N_cap（没有它，读取未命中的 WCD 将是无界的），以及 b) 写入队列的到达速率有上界，我们可以通过将控制器描述为有限状态机来计算 WCD 的上界，其中状态是操作，转换是它们的调度时间成本，并从上方限制导致第 N 个读取未命中的任何路径的时间成本。此技术在以下论文中有更详细的描述：M. Andreozzi, F. Conboy, G. Stea, R. Zippo, "Heterogeneous systems modelling with Adaptive Traffic Profiles and its application to worst-case analysis of a DRAM controller", Proc. of IEEE COMPSAC 2020, July 2020。

<figure>
    <img src="/assets/img/blog/heterogeneous-systems/fig1.png" alt="Figure 2" width="500"/>
    <br>
    <em>Figure 2.</em>
</figure>


The above upper bound could in principle be pessimistic, due to several assumptions that are required to make it computable in practice. To benchmark it, we simulate the above system using gem5. In the simulative approach, ATP FIFOs are used as input to a modified gem5 model of a DRAM memory device and controller to setup a quasi-worst-case scenario, shown in Fig. 2. The gem5 model includes a locking mechanism, that halts the service of requests until there are the N-1 enqueued, and a refresh which is activated at least once in the scenario. The ATP FIFOs that we used are shown at the right of the same figure. The setup profiles (in blue) produce the packets that fill up the read and write queues to create suitable initial conditions, i.e., N-1 read-misses in the read queue and W-1 write-misses in the write queue. Run profiles (in green) are used to produce the N-th memory request (upon receiving which the controller will start to serve requests), the N_cap read-hits that will overtake it, and the writes that keep arriving during the simulation at the configured rate. The simulation stops after the N-th read has been served.

<figure>
    <img src="/assets/img/blog/heterogeneous-systems/fig2.png" alt="Figure 3" width="500"/>
    <br>
    <em>Figure 3.</em>
</figure>

 We simulate three memory configurations: a DDR3-1600, a DDR4-2400, and an LPDDR-3200 based on a 4Gbit per channel datasheet. All use an open-adaptive page management policy and Row-Rank-Bank-Column-Channel address mapping. Experiments were run using values of N between 2 and 55, and the write request rate was varied from 1 to 8 Gbps. The figure reports the lower and upper bounds on the WCD for the three above-mentioned technologies (DDR3 left, DDR4 center, LPDDR right). All show that gem5 simulations are very close to the upper bounds until the write request rate gets high (i.e., 6 Gbps for DDR3/4, 2.5 Gbps for LPDDR). The increased distance at high write rates may be due to both pessimism in the upper bound, or the fact that the simulation model loses accuracy in these cases.

## Workshop Presentation

<iframe width="960" height="540" src="https://www.youtube.com/embed/UhWAozvZ9mU" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen style="max-width: 960px;"></iframe>
