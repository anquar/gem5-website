---
layout: documentation
title: Minor CPU 模型
doc: gem5 documentation
parent: cpu_models
permalink: /documentation/general_docs/cpu_models/minor_cpu
author: Andrew Bardsley
---

Minor CPU 模型

本文档包含对 [Minor](http://doxygen.gem5.org/release/current/namespaceMinor.html) gem5 按序处理器模型的结构和功能的描述。

建议任何想了解 [Minor](http://doxygen.gem5.org/release/current/namespaceMinor.html) 的内部组织、设计决策、C++ 实现和 Python 配置的人阅读。假设读者熟悉 gem5 及其一些内部结构。本文档旨在与 [Minor](http://doxygen.gem5.org/release/current/namespaceMinor.html) 源代码一起阅读，并解释其总体结构，而不必过于拘泥于命名每个函数和数据类型。

## 什么是 Minor？

[Minor](http://doxygen.gem5.org/release/current/namespaceMinor.html) 是一个具有固定流水线但可配置数据结构和执行行为的按序处理器模型。它旨在用于模拟具有严格按序执行行为的处理器，并允许通过 MinorTrace/minorview.py 格式/工具可视化指令在流水线中的位置。其目的是提供一个框架，以便在微架构上将该模型与具有类似功能的特定、选定的处理器相关联。

## 设计理念

### 多线程

该模型目前不支持多线程，但在需要数组化阶段数据以支持多线程的关键位置有 THREAD 注释。

### 数据结构

避免用大量的生命周期信息装饰数据结构。只有指令 ([MinorDynInst](
http://doxygen.gem5.org/release/current/classMinor_1_1MinorDynInst.html)) 包含其值未在构造时设置的大部分数据内容。

所有内部结构在构造时都有固定的大小。队列和 FIFO 中保存的数据 ([MinorBuffer](
http://doxygen.gem5.org/release/current/classMinor_1_1MinorBuffer.html),
[FUPipeline](
http://doxygen.gem5.org/release/current/classMinor_1_1FUPipeline.html)) 应该有一个 [BubbleIF](http://doxygen.gem5.org/release/current/classMinor_1_1BubbleIF.html) 接口，以便为每种类型允许一个独特的“气泡”/无数据值选项。

阶段间 'struct' 数据打包在按值传递的结构中。只有 [MinorDynInst](
http://doxygen.gem5.org/release/current/classMinor_1_1MinorDynInst.html)、[ForwardLineData](
http://doxygen.gem5.org/release/current/classMinorCPU.html#a36a7ec6a8c5a6d27fd013d8b0238029d) 中的行数据以及内存接口对象 [Fetch1::FetchRequest](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1_1_1FetchRequest.html) 和 [LSQ::LSQRequest](
http://doxygen.gem5.org/release/current/classMinor_1_1LSQ_1_1LSQRequest.html) 是在运行模型时 `::new` 分配的。

## 模型结构

[MinorCPU](
http://doxygen.gem5.org/release/current/classMinorCPU.html) 类的对象由模型提供给 gem5。[MinorCPU](
http://doxygen.gem5.org/release/current/classMinorCPU.html) 实现 (cpu.hh) 的接口，并可以提供数据和指令接口以连接到缓存系统。该模型通过 Python 以与其他 gem5 模型类似的方式进行配置。该配置传递给 [MinorCPU::pipeline](
http://doxygen.gem5.org/release/current/classMinorCPU.html#a36a7ec6a8c5a6d27fd013d8b0238029d)（[Pipeline](
http://doxygen.gem5.org/release/current/classMinor_1_1Pipeline.html) 类），后者实际实现处理器流水线。

从 [MinorCPU](
http://doxygen.gem5.org/release/current/classMinorCPU.html) 向下的主要单元所有权层次结构如下所示：

```
MinorCPU
--- Pipeline - 流水线的容器，拥有循环 'tick' 事件机制和空闲（周期跳过）机制。
--- --- Fetch1 - 指令获取单元，负责获取缓存行（或来自 I-cache 接口的部分行）。
--- --- --- Fetch1::IcachePort - 从 Fetch1 到 I-cache 的接口。
--- --- Fetch2 - 行到指令的分解。
--- --- Decode - 指令到微操作的分解。
--- --- Execute - 指令执行和数据内存接口。
--- --- --- LSQ - 内存引用指令的加载存储队列。
--- --- --- LSQ::DcachePort - 从 Execute 到 D-cache 的接口。
```

## 关键数据结构

### 指令和行标识：Instld (`dyn_inst.hh`)

```
- T/S.P/L - 用于获取的缓存行
- T/S.P/L/F - 用于 Decode 之前的指令
- T/S.P/L/F.E - 用于 Decode 之后的指令
```

例如：

```
- 0/10.12/5/6.7
```

[InstId](http://doxygen.gem5.org/release/current/classMinor_1_1InstId.html) 字段是：

|字段|符号|生成者|检查者|功能|
|:----|:-----|:-----------|:---------|:-------|
|InstId::threadId|T|[Fetch1](http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html) | 需要线程号的所有地方| 线程号（目前总是 0）。
|InstId::streamSeqNum|S|[Execute](http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html) | Fetch1, Fetch2, Execute (用于丢弃行/指令) | Execute 选择的流序列号。流序列号在 Execute 中 PC 更改（分支、异常）后更改，用于分隔分支前后的指令流。|
|InstId::predictionSeqNum|P|[Fetch2](http://doxygen.gem5.org/release/current/classMinor_1_1Fetch2.html)| Fetch2 (预测后丢弃行时)| 预测序列号代表分支预测决策。Fetch2 使用它根据 Fetch2 做出的最后一次跟随分支预测来标记行/指令。Fetch2 可以向 Fetch1 发出信号，要求其更改获取地址并用新的预测序列号标记行（仅当 Fetch1 期望的流序列号与请求匹配时才会这样做）。
|InstId::lineSeqNum|L|[Fetch1](http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html)| (仅用于调试) | 此缓存行或提取此指令的行的行获取序列号。|
|InstId::fetchSeqNum|F|[Fetch2](http://doxygen.gem5.org/release/current/classMinor_1_1Fetch2.html) | Fetch2 (作为分支的指令序列号) | 当行分解为指令时由 Fetch2 分配的指令获取顺序。|
|InstId::execSeqNum|E|[Decode](http://doxygen.gem5.org/release/current/classMinor_1_1Decode.html)|Execute (用于检查队列/FU/LSQ 中的指令标识)| 微操作分解后的指令顺序|

序列号字段彼此独立，虽然例如指令的 [InstId::execSeqNum](
http://doxygen.gem5.org/release/current/classMinor_1_1InstId.html#a064b0e4480268559e68510311be2a9b0) 总是 >= [InstId::fetchSeqNum](
http://doxygen.gem5.org/release/current/classMinor_1_1InstId.html#a06677e68051a2a52f384e55e9368e33d)，但比较没有用处。

每个序列号字段的发起阶段保留该字段的计数器，可以递增以生成新的唯一编号。


### 指令：MinorDynInst (`dyn_inst.hh`)

[MinorDynInst](
http://doxygen.gem5.org/release/current/classMinor_1_1MinorDynInst.html) 代表指令在流水线中的进程。一条指令可以是三件事：

|事物|谓词|解释|
|:---------------------|:---------------------------------------------------------------------------------------------------------------------------------|:----------|
|气泡 (Bubble)|[MinorDynInst::isBubble()](http://doxygen.gem5.org/release/current/classMinor_1_1MinorDynInst.html#a24e835fa495026ca63ffec43ee9cc07e) | 根本没有指令，只是一个空间填充符|
|故障 (Fault)|[MinorDynInst::isFault()](http://doxygen.gem5.org/release/current/classMinor_1_1MinorDynInst.html#a24029f3cd1835928d572737a548a824e)  | 披着指令外衣传递到流水线的故障|
|解码指令 (Decoded instruction)|[MinorDynInst::isInst()](http://doxygen.gem5.org/release/current/classMinor_1_1MinorDynInst.html#adc55cdcf9f7c6588bb27eddb4c7fe38e)   | 指令实际上在 Fetch2 中传递给 gem5 解码器，因此创建时已完全解码。MinorDynInst::staticInst 是解码后的指令形式。 |

指令使用 gem5 [RefCountingPtr](
http://doxygen.gem5.org/release/current/classRefCountingPtr.html)
([base/refcnt.hh](http://doxygen.gem5.org/release/current/refcnt_8hh.html))
包装器进行引用计数。因此，它们通常在代码中显示为 MinorDynInstPtr。请注意，由于 [RefCountingPtr](http://doxygen.gem5.org/release/current/classRefCountingPtr.html) 初始化为 nullptr 而不是支持 [BubbleIF::isBubble](
http://doxygen.gem5.org/release/current/classMinor_1_1BubbleIF.html#a7ce121301dba2e89b94235d96bf339ae) 的对象，因此从 stage.hh 将原始 MinorDynInstPtrs 传递给 [Queues](
http://doxygen.gem5.org/release/current/classMinor_1_1Queue.html) 和其他类似结构而不进行装箱是危险的。

### ForwardLineData (`pipe_data.hh`)

ForwardLineData 用于将缓存行从 Fetch1 传递到 Fetch2。像 MinorDynInsts 一样，它们可以是气泡 ([ForwardLineData::isBubble()](
http://doxygen.gem5.org/release/current/classMinor_1_1ForwardLineData.html#a46789690719acf167be0a57c9d7d4f8f))、携带故障或包含由 Fetch1 获取的行（部分行）。ForwardLineData 携带的数据归从内存返回的 Packet 对象所有，并且是显式内存管理的，一旦处理完毕必须删除（通过 Fetch2 删除 Packet）。

### ForwardInstData (`pipe_data.hh`)

ForwardInstData 可以在其 [ForwardInstData::insts](
http://doxygen.gem5.org/release/current/classMinor_1_1ForwardInstData.html#ab54a61c683376aaf5a12ea19ab758340) 向量中包含多达 [ForwardInstData::width()](
http://doxygen.gem5.org/release/current/classMinor_1_1ForwardInstData.html#ad5db21f655f2f1dfff69e6f6d5cc606e) 条指令。此结构用于在 Fetch2、Decode 和 Execute 之间携带指令，并在 Decode 和 Execute 中存储输入缓冲向量。

### Fetch1::FetchRequest (`fetch1.hh`)

FetchRequests 代表 I-cache 行获取请求。它们在 Fetch1 的内存队列中使用，并在遍历内存系统时被推入/弹出 [Packet::senderState](
http://doxygen.gem5.org/release/current/classPacket.html#ad1dd4fa4370e508806fe4a8253a0ad12)。

FetchRequests 包含该获取访问的内存系统 Request ([mem/request.hh](
http://doxygen.gem5.org/release/current/request_8hh.html))，一个 packet (Packet, [mem/packet.hh](
http://doxygen.gem5.org/release/current/packet_8hh.html))，如果请求到达内存，以及一个 fault 字段，可以用 TLB 来源的预取故障（如果有）填充。

### LSQ::LSQRequest (`execute.hh`)

LSQRequests 类似于 FetchRequests，但用于 D-cache 访问。它们携带与内存访问关联的指令。

## 流水线

```
------------------------------------------------------------------------------
    图例:

    [] : 阶段间 BufferBuffer
    ,--.
    |  | : 流水线阶段
    `--'
    ---> : 前向通信
    <--- : 后向通信

    rv : 输入缓冲区的预留信息

                ,------.     ,------.     ,------.     ,-------.
 (来自  --[]-v->|Fetch1|-[]->|Fetch2|-[]->|Decode|-[]->|Execute|--> (到 Fetch1
 Execute)    |  |      |<-[]-|      |<-rv-|      |<-rv-|       |     & Fetch2)
             |  `------'<-rv-|      |     |      |     |       |
             `-------------->|      |     |      |     |       |
                             `------'     `------'     `-------'
------------------------------------------------------------------------------
```

四个流水线阶段通过 [MinorBuffer](
http://doxygen.gem5.org/release/current/classMinor_1_1MinorBuffer.html) FIFO (stage.hh, 最终派生自 [TimeBuffer](
http://doxygen.gem5.org/release/current/classTimeBuffer.html)) 结构连接在一起，允许模拟阶段间延迟。在相邻阶段之间的前向方向（例如：将行从 Fetch1 传递到 Fetch2）有一个 [MinorBuffers](
http://doxygen.gem5.org/release/current/classMinor_1_1MinorBuffer.html)，在 Fetch2 和 Fetch1 之间有一个后向方向的缓冲区，携带分支预测。

Fetch2、Decode 和 Execute 阶段具有输入缓冲区，每个周期可以接受来自上一阶段的输入数据，如果该阶段未准备好处理它，则可以保留该数据。输入缓冲区以与接收时相同的形式存储数据，因此 Decode 和 Execute 的输入缓冲区包含来自其前一阶段的输出指令向量 ([ForwardInstData](
http://doxygen.gem5.org/release/current/classMinor_1_1ForwardInstData.html)
([pipe_data.hh](http://doxygen.gem5.org/release/current/pipe__data_8hh.html)))，指令和气泡位于作为单个缓冲区条目的相同位置。

阶段输入缓冲区为其前一阶段提供 [Reservable](
http://doxygen.gem5.org/release/current/classMinor_1_1Reservable.html) (stage.hh) 接口，以允许在其输入缓冲区中预留插槽，并向后传达其输入缓冲区占用率，以允许前一阶段计划是否应在给定周期内进行输出。

### 事件处理：MinorActivityRecorder (`activity.hh`, `pipeline.hh`)

Minor 本质上是一个周期可调用的模型，具有基于流水线活动跳过周期的能力。外部事件主要由回调接收（例如 [Fetch1::IcachePort::recvTimingResp](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1_1_1IcachePort.html#aec62b3d89dfe61e8528cdcdf3729eeab)），并导致流水线被唤醒以服务推进请求队列。

[Ticked](http://doxygen.gem5.org/release/current/classgem5_1_1Ticked.html) (sim/ticked.hh)
是一个基类，汇集了 evaluate 成员函数和提供的 [SimObject](http://doxygen.gem5.org/release/current/classgem5_1_1SimObject.html)。它提供 [Ticked::start](
http://doxygen.gem5.org/release/current/classTicked.html#a798d1e248c27161de6eb2bc6fef5e425)/stop 接口来启动和暂停定期发布的时钟事件。[Pipeline](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Pipeline.html) 是 Ticked 的派生类。

在 evaluate 调用期间，阶段可以通过调用 [MinorCPU::activityRecorder](
http://doxygen.gem5.org/release/current/classgem5_1_1MinorCPU.html#ae3b03c96ee234e2c5c6c68f4567245a7)->activity()（对于非回调相关活动）或 MinorCPU::wakeupOnEvent(<stageId>)（对于阶段回调相关“唤醒”活动）来发出信号，表明它们在下一个周期仍有工作要做。

[Pipeline::evaluate](
http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Pipeline.html#af07fdce00c8937e9de5b6450a1cd62bf) 包含对每个单元的 evaluate 调用和流水线空闲测试，如果没有任何单元发出可能在下一个周期变为活动的信号，则可以关闭时钟 tick。

在 Pipeline ([pipeline.hh](
http://doxygen.gem5.org/release/current/pipeline_8hh.html)) 中，阶段按相反顺序评估（因此将按相反顺序 ::evaluate），并且它们的后向数据可以在每个周期写入后立即读取，从而允许输出决策是“完美的”（允许整个流水线同步停顿）。从 Fetch2 到 Fetch1 的分支预测也可以在 0 个周期内传输，使得 fetch1ToFetch2BackwardDelay 成为唯一可以设置为低至 0 个周期的可配置延迟。

可以调用 [MinorCPU::activateContext](
http://doxygen.gem5.org/release/current/classgem5_1_1MinorCPU.html#a854596342bfb9dd889437e494c4ddb27) 和 [MinorCPU::suspendContext](
http://doxygen.gem5.org/release/current/classgem5_1_1MinorCPU.html#ae6aa9b1bb798d8938f0b35e11d9e68b8) 接口来启动和暂停线程（MT 意义上的线程）以及启动和暂停流水线。执行指令可以调用此接口（间接通过 ThreadContext）来空闲 CPU/它们的线程。

### 每个流水线阶段

一般来说，阶段的行为（每个周期）是：

```
    evaluate:
        将输入推送到 inputBuffer
        设置对输入/输出数据插槽的引用

        做“每个周期”的“步进”任务

        如果有输入并且下一阶段有空间：
            处理并生成新输出
            可能重新激活阶段

        发送后向数据

        如果阶段向后续 FIFO 生成了输出：
            发出管道活动信号

        如果阶段有更多可处理的输入并且下一阶段有空间：
            为下一个周期重新激活阶段

        如果该数据未全部使用，则提交对 inputBuffer 的推送
```

Execute 阶段与此模型不同，因为其前向输出（分支）数据无条件地发送到 Fetch1 和 Fetch2。为了允许这种行为，Fetch1 和 Fetch2 必须无条件地接收该数据。

### Fetch1 阶段

[Fetch1](http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html) 负责从 I-cache 获取缓存行或部分缓存行，并将它们传递给 [Fetch2](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch2.html) 以分解为指令。它可以从 [Execute](http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html) 和 [Fetch2](http://doxygen.gem5.org/release/current/classMinor_1_1Fetch2.html) 接收“流更改”指示，以发出信号表明它应该更改其内部获取地址并用新的流或预测序列号标记新获取的行。当 Execute 和 [Fetch2](http://doxygen.gem5.org/release/current/classMinor_1_1Fetch2.html) 同时发出流更改信号时，[Fetch1](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html) 采用 [Execute](http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html) 的更改。

[Fetch1](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html) 发出的每一行都将带有唯一的行序列号，可用于调试流更改。

从 I-cache 获取时，[Fetch1](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html) 将请求从当前获取地址 (Fetch1::pc) 到参数 fetch1LineSnapWidth 中设置的“数据快照”大小结束的数据。随后的自主行获取将在快照边界获取大小为 fetch1LineWidth 的整行。

只有当 [Fetch1](http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html) 可以在 [Fetch2](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch2.html) 输入缓冲区中预留空间时，它才会启动内存获取。该输入缓冲区充当系统的获取队列/LFL。

[Fetch1](http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html) 包含两个队列：requests 和 transfers，用于处理转换行获取地址（通过 TLB）和适应向/从内存获取的请求/响应的阶段。

来自 [Fetch1](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html) 的获取请求在通过调用 itb->translateTiming 发送到 ITLB 后，作为新分配的 FetchRequest 对象被推送到 requests 队列中。

来自 TLB 的响应将请求从 requests 队列移动到 transfers 队列。如果每个队列中有多个条目，则可能会获得不在 requests 队列头部的请求的 TLB 响应。在这种情况下，TLB 响应在请求对象中标记为 Translated 状态更改，并且将请求推进到 transfers（和内存系统）留给对 [Fetch1::stepQueues](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html#ac143710b93ec9f55bfc3e2882ef2fe4c) 的调用，该调用在收到任何事件后的周期中调用。

[Fetch1::tryToSendToTransfers](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html#a9ace21e8131caf360190ea876cfa2934)
负责在两个队列之间移动请求并向内存发出请求。失败的 TLB 查找（预取中止）继续占用队列中的空间，直到它们在 transfers 头部被恢复。

来自内存的响应将请求对象状态更改为 Complete，并且 [Fetch1::evaluate](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html#a68a0a88ce6ee3dd170c977318cfb4ca9) 可以提取响应数据，将其打包在 [ForwardLineData](
http://doxygen.gem5.org/release/current/classMinor_1_1ForwardLineData.html) 对象中，并将其转发到 [Fetch2](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch2.html) 的输入缓冲区。

由于空间总是保留在 [Fetch2::inputBuffer](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch2.html#afdaa27275e2f605d9aaa637e8c39f96d) 中，将输入缓冲区的大小设置为 1 会导致非预取行为。

当流发生变化时，可以无条件丢弃已翻译的 requests 队列成员和已完成的 transfers 队列成员，以便为新的传输腾出空间。

### Fetch2 阶段

Fetch2 将一行从 Fetch1 接收到其输入缓冲区中。该缓冲区头行中的数据被迭代并分离成单独的指令，这些指令被打包成可以传递给 [Decode](http://doxygen.gem5.org/release/current/classMinor_1_1Decode.html) 的指令向量。如果在整个输入行或分解的指令中发现故障，则可以提前中止打包指令。

#### 分支预测

Fetch2 包含分支预测机制。这是围绕 gem5 提供的分支预测器接口 (cpu/pred/...) 的包装器。

对发现的任何控制指令预测分支。如果对指令尝试预测，则在该指令上设置 [MinorDynInst::triedToPredict](
http://doxygen.gem5.org/release/current/classMinor_1_1MinorDynInst.html#a905b0516019ae7f47b5795ceda33f5cd) 标志。

当预测分支发生时，设置 [MinorDynInst::predictedTaken](http://doxygen.gem5.org/release/current/classMinor_1_1MinorDynInst.html#aa57659ef9d30162ddcf10fcb0f3963ac) 标志，并将 [MinorDynInst::predictedTarget](http://doxygen.gem5.org/release/current/classMinor_1_1MinorDynInst.html#a5eaf9547bcaefa2c0fd37f32c828691b) 设置为预测的目标 PC 值。然后将预测的分支指令打包到 Fetch2 的输出向量中，预测序列号递增，并将分支传达给 Fetch1。

发出预测信号后，Fetch2 将丢弃其输入缓冲区内容，并将拒绝具有与该分支相同的流序列号但具有不同预测序列号的任何新行。这允许拒绝随后的顺序获取行，而不会忽略由 Execute 的“真实”分支指示的流更改生成的新行（这将具有新的流序列号）。

Fetch1 数据包提供给 Fetch2 的程序计数器值仅在流发生变化时更新。Fetch2::havePC 指示是否将从下一个处理的输入行获取 PC。Fetch2::havePC 对于允许通过解码跟踪换行指令是必要的。

Execute 处理的分支（和预测要分支的指令）将生成 BranchData ([pipe_data.hh](
http://doxygen.gem5.org/release/current/pipe__data_8hh.html)) 数据，解释分支的结果，并将其转发给 Fetch1 和 Fetch2。Fetch1 使用此数据更改流（并更新其流序列号和新行的地址）。Fetch2 使用它来更新分支预测器。对于在提交途中被丢弃的指令，Minor 不会将分支数据传达给分支预测器。

BranchData::BranchReason ([pipe_data.hh](
http://doxygen.gem5.org/release/current/pipe__data_8hh.html)) 编码可能的分支场景：


|分支枚举值| 在 Execute 中| Fetch1 反应| Fetch2 反应|
|:-------------------------|:-------------------------------------------------------------|:-----------------------------------------------------------------------|:----------------------------|
|No Branch                 |(输出气泡数据)|-                                                                       |-                            |
|CorrectlyPredictedBranch  |已预测，已发生|-                                                                       |作为已发生分支更新 BP    |
|UnpredictedBranch         |未预测，已发生且已发生|新流|作为已发生分支更新 BP    |
|BadlyPredictedBranch      |已预测，未发生|新流以恢复到旧的 Inst. 源|作为未发生分支更新 BP|
|BadlyPredictedBranchTarget|已预测，已发生，但目标与预测不同|新流|更新 BTB 到新目标     |
|SuspendThread             |暂停获取的提示|暂停此线程的获取（分支到下一条指令作为唤醒获取地址|-                            |
|Interrupt                 |检测到中断|新流|-                            |


### Decode 阶段

[Decode](http://doxygen.gem5.org/release/current/classMinor_1_1Decode.html) 从 [Fetch2](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch2.html)（通过其输入缓冲区）获取指令向量，并将这些指令分解为微操作（如果需要），并将它们打包到其输出指令向量中。

参数 executeInputWidth 设置每个周期可以打包到输出中的指令数。如果参数 decodeCycleInput 为 true，[Decode](http://doxygen.gem5.org/release/current/classMinor_1_1Decode.html) 可以尝试每个周期从其输入缓冲区中的多个条目获取指令。

### Execute 阶段

Execute 提供所有指令执行和内存访问机制。指令通过 Execute 的通道可能需要多个周期，其精确时序由功能单元流水线 FIFO 建模。

指令向量（可能包括故障“指令”）由 Decode 提供给 Execute，并且可以在发出之前在 Execute 输入缓冲区中排队。设置参数 executeCycleInput 允许 execute 检查多个输入缓冲区条目（多个指令向量）。可以使用 executeInputWidth 设置输入向量中的指令数，可以使用参数 executeInputBufferSize 设置输入缓冲区的深度。

#### 功能单元

Execute 阶段包含构成 CPU 计算核心的每个功能单元的流水线。功能单元通过 executeFuncUnits 参数进行配置。每个功能单元都有许多它支持的指令类、指令发出之间的规定延迟、从指令发出到（可能）提交的延迟以及能够进行更复杂时序的可选时序注释。

每个活动周期，[Execute::evaluate](
http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html#a2d6ca9a694bf99ef82da7759cba8c3da) 执行此操作：

```
    Execute::evaluate:
        将输入推送到 inputBuffer
        设置对输入/输出数据插槽和分支输出插槽的引用

        步进 D-cache 接口队列（类似于 Fetch1）

        如果发布了中断：
            接受中断（向 Fetch1/Fetch2 发出分支信号）
        否则
            提交指令
            发出新指令

        推进功能单元流水线

        如果单元仍处于活动状态，则重新激活 Execute

        如果该数据未全部使用，则提交对 inputBuffer 的推送
```

#### 功能单元 FIFO

功能单元实现为 SelfStallingPipelines (stage.hh)。这些是具有两条不同“推”和“弹”线的 [TimeBuffer](http://doxygen.gem5.org/release/current/classTimeBuffer.html) FIFO。除非 FIFO 的远端“弹”端有数据，否则它们对 [SelfStallingPipeline::advance](
http://doxygen.gem5.org/release/current/classMinor_1_1SelfStallingPipeline.html#ad933640bc6aab559c009302e478c3768) 的响应与 TimeBuffers 相同。提供了一个 'stalled' 标志用于发出停顿信号并允许清除停顿。目的是为每个功能单元提供一个流水线，在指令被处理并且流水线显式取消停顿之前，该流水线永远不会推进指令。

动作 'issue', 'commit', 和 'advance' 作用于功能单元。

#### 发出 (Issue)

发出指令涉及迭代输入缓冲区指令和功能单元的头部，以尝试按顺序发出指令。每个周期可以发出的指令数受参数 executeIssueLimit、executeCycleInput 的设置方式、流水线空间的可用性以及用于选择可以发出指令的流水线的策略的限制。

目前，唯一的发布策略是严格的循环访问每个流水线，按顺序给出指令。为了获得更大的灵活性，需要更好的（和更具体的策略）。

内存操作指令遍历其功能单元以执行其 EA 计算。在“提交”时，执行 [ExecContext](
http://doxygen.gem5.org/release/current/classMinor_1_1ExecContext.html)::initiateAcc 执行阶段，并将任何内存访问（通过 ExecContext::{read,write}Mem 调用 [LSQ::pushRequest](
http://doxygen.gem5.org/release/current/classMinor_1_1LSQ.html#a18594a4baa4eef7bfc3be45c03f4d544)）发出到 [LSQ](http://doxygen.gem5.org/release/current/classMinor_1_1LSQ.html)。

请注意，故障就像指令一样发出，并且（当前）可以发出到任何功能单元。

每个发出的指令也被推入 Execute::inFlightInsts 队列。内存引用指令被推入 Execute::inFUMemInsts 队列。

#### 提交 (Commit)

通过检查 Execute::inFlightInsts 队列的头部（用指令发出的功能单元编号装饰）来提交指令。然后可以在其功能单元中找到的指令被执行并从 Execute::inFlightInsts 中弹出。

内存操作指令提交到内存队列（如上所述）并退出其功能单元流水线，但不从 Execute::inFlightInsts 队列中弹出。Execute::inFUMemInsts 队列为通过功能单元的内存操作提供排序（保持发出顺序）。进入 LSQ 时，指令从 Execute::inFUMemInsts 中弹出。

如果设置了参数 executeAllowEarlyMemoryIssue，则内存操作可以在到达 Execute::inFlightInsts 头部之前但在其依赖关系得到满足之后从其 FU 发送到 LSQ。[MinorDynInst::instToWaitFor](
http://doxygen.gem5.org/release/current/classMinor_1_1MinorDynInst.html#ac72a9dcff570bbaf24da9ee74392e6d0) 标记有内存操作进展到 LSQ 所需提交的最新依赖指令 execSeqNum。

一旦内存响应可用（通过测试 Execute::inFlightInsts 的头部与 [LSQ::findResponse](
http://doxygen.gem5.org/release/current/classMinor_1_1LSQ.html#a458abe5d220a0f66600bf339bceb2100)），提交将处理该响应 (ExecContext::completeAcc) 并从 Execute::inFlightInsts 中弹出指令。

任何分支、故障或中断都会导致流序列号更改并向 Fetch1/Fetch2 发出分支信号。只有具有当前流序列号的指令才会被发出和/或提交。

#### 推进 (Advance)

所有未停顿的流水线都会推进，此后可能会停顿。如果任何流水线中还有任何指令，则发出下一个周期中潜在活动的信号。

#### 记分板 (Scoreboard)

记分板 ([Scoreboard](
http://doxygen.gem5.org/release/current/classMinor_1_1Scoreboard.html)) 用于控制指令发出。它包含将写入每个通用 CPU 整数或浮点寄存器的在飞指令数量的计数。只有当记分板包含将写入指令源寄存器之一的 0 条指令的计数时，才会发出指令。

一旦发出指令，该指令的每个目标寄存器的记分板计数将递增。

通过将发出的 FU 的长度添加到当前时间，在记分板中标记指令结果的估计传递时间。每个 FU 上的 timings 参数提供了一组用于计算传递时间的附加规则。这些记录在 MinorCPU.py 中的参数注释中。

在提交时（对于内存操作，内存响应提交），指令源寄存器的记分板计数器递减。

#### Execute::inFlightInsts

Execute::inFlightInsts 队列将始终按正确的发出顺序包含 [Execute](http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html) 中的所有在飞指令。[Execute::issue](
http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html#af0b90170a273f1a0d41f4164ba3fe456) 是唯一将指令推入队列的过程。[Execute::commit](
http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html#ac2da0ae4202602ce4ad976f33a004237) 是唯一可以弹出指令的过程。

#### LSQ

[LSQ](http://doxygen.gem5.org/release/current/classMinor_1_1LSQ.html) 在许多保守情况下可以支持对内存的多个未完成事务。

有三个队列包含请求：requests、transfers 和 store buffer。requests 和 transfers 队列的操作方式与 Fetch1 中的队列类似。store buffer 用于解耦完成存储操作与后续加载的延迟。

请求在其指令离开其功能单元时发给 DTLB。在 requests 头部，可缓存加载请求可以发送到内存并继续到 transfers 队列。可缓存存储将未经处理地传递给 transfers 并推进该队列，保持与其他事务的顺序。

[LSQ::tryToSendToTransfers](
http://doxygen.gem5.org/release/current/classMinor_1_1LSQ.html#a7d7b8ddc7c69fd9eb3b8594fe261d8e8) 中的条件规定何时可以将请求发送到内存。

所有不可缓存事务、拆分事务和锁定事务都在 requests 头部按顺序处理。此外，驻留在 store buffer 中的存储结果可以将其数据转发给可缓存加载（无需从内存执行读取），但在该队列的存储已排入 store buffer 之前，不能向 transfers 队列发出可缓存加载。

在 transfers 结束时，[LSQ::LSQRequest::Complete](
http://doxygen.gem5.org/release/current/classMinor_1_1LSQ_1_1LSQRequest.html#a429d50f5dd6be4217d5dba93f8c289d3a81b9dbf6670e396d0266949d59b57428)（正在故障、是可缓存存储或已发送到内存并收到响应）的请求可以由 Execute 选取并提交 (ExecContext::completeAcc)，对于存储，发送到 store buffer。

屏障指令不会阻止可缓存加载向内存推进，但会导致流更改，从而丢弃该加载。如果存储处于屏障的阴影中但在新指令流到达 Execute 之前，则不会提交到 store buffer。由于所有其他内存事务都在 requests 队列末尾延迟，直到它们位于 Execute::inFlightInsts 的头部，因此它们将被任何屏障流更改丢弃。

提交后，[LSQ::BarrierDataRequest](
http://doxygen.gem5.org/release/current/classMinor_1_1LSQ_1_1BarrierDataRequest.html) 请求插入 store buffer 以跟踪每个屏障，直到所有前面的内存事务已从 store buffer 排出。在屏障排出之前，不会从 FU 的末端发出进一步的内存事务。

#### 排空 (Draining)

排空主要由 [Execute](
http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html) 阶段处理。当通过调用 [MinorCPU::drain](
http://doxygen.gem5.org/release/current/classMinorCPU.html#a3191c9247cd80dfc603bfcd154cf09a0) 启动时，[Pipeline::evaluate](
http://doxygen.gem5.org/release/current/classMinor_1_1Pipeline.html#af07fdce00c8937e9de5b6450a1cd62bf) 每个周期检查每个单元的排空状态，并保持流水线活动直到排空完成。Pipeline 发出排空完成的信号。Execute 由 [MinorCPU::drain](
http://doxygen.gem5.org/release/current/classMinorCPU.html#a3191c9247cd80dfc603bfcd154cf09a0) 触发，并开始逐步通过其 [Execute::DrainState](
http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html#aeb21dbbbbde40d8cdc68e9b17ddd3d40) 状态机，从状态 Execute::NotDraining 开始，顺序如下：

|状态|含义|
|[Execute::NotDraining](http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html#aeb21dbbbbde40d8cdc68e9b17ddd3d40aeecf47987ef0d4aa0a6a59403d085ec9)|不尝试排空，正常执行|
|[Execute::DrainCurrentInst](http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html#aeb21dbbbbde40d8cdc68e9b17ddd3d40aec53785380b6256e2baa889739311570)|排空微操作以完成指令|
|[Execute::DrainHaltFetch](http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html#aeb21dbbbbde40d8cdc68e9b17ddd3d40a516d421a79c458d376bedeb067fc207f)|停止获取指令|
|[Execute::DrainAllInsts](http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html#aeb21dbbbbde40d8cdc68e9b17ddd3d40ade3ca2567fed8d893896d71bb95f13ca)|丢弃所有呈现的指令|

完成后，已排空的 Execute 单元将处于 [Execute::DrainAllInsts](
http://doxygen.gem5.org/release/current/classMinor_1_1Execute.html#aeb21dbbbbde40d8cdc68e9b17ddd3d40ade3ca2567fed8d893896d71bb95f13ca) 状态，在此状态下它将继续丢弃指令，但不知道模型其余部分的排空状态。

## 调试选项

该模型提供了许多调试标志，可以通过 `–debug-flags` 选项传递给 gem5。

可用的标志有：

|调试标志| 将生成调试输出的单元 |
|:---------------|:------------------------------------------|
|Activity        | [Debug](http://doxygen.gem5.org/release/current/namespaceDebug.html) ActivityMonitor 动作 |
|Branch          | [Fetch2](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Fetch2.html) 和 [Execute](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Execute.html) 分支预测决策 |
|[MinorCPU](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1MinorCPU.html)      | CPU 全局动作，例如唤醒/线程挂起 |
|[Decode](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Decode.html) | [Decode](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Decode.html) |
|MinorExec       | [Execute](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Execute.html) 行为 |
|Fetch           |[Fetch1](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Fetch1.html) 和 [Fetch2](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Fetch2.html) |
|MinorInterrupt  | [Execute](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Execute.html) 中断处理  |
|MinorMem        | [Execute](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Execute.html) 内存交互 |
|MinorScoreboard | [Execute](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Execute.html) 记分板活动 |
|MinorTrace      | 生成 MinorTrace 循环状态跟踪输出（见下文） |
|MinorTiming     | MinorTiming 指令时序修改操作    |

组标志 [Minor](http://doxygen.gem5.org/release/current/namespaceminor.html) 启用所有以 [Minor](
http://doxygen.gem5.org/release/current/namespaceMinor.html) 开头的标志。

## MinorTrace 和 minorview.py

调试标志 MinorTrace 导致打印逐周期的状态数据，然后可以通过 minorview.py 工具进行处理和查看。此输出非常详细，因此建议仅将其用于小示例。

### MinorTrace 格式

MinorTrace 输出三种类型的行：

#### MinorTrace - Ticked 单元周期状态

例如：

```
 110000: system.cpu.dcachePort: MinorTrace: state=MemoryRunning in_tlb_mem=0/0
```

对于每个时间步长，MinorTrace 标志将导致为模型中的每个命名元素打印一行 MinorTrace。

#### MinorInst - Decode 发出的指令摘要

[Decode](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Decode.html)

例如：

```
 140000: system.cpu.execute: MinorInst: id=0/1.1/1/1.1 addr=0x5c \
                             inst="  mov r0, #0" class=IntAlu
```

MinorInst 行目前仅针对已提交的指令生成。

#### MinorLine - Fetch1 发出的行获取摘要

[Fetch1](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Fetch1.html)

例如：

```
  92000: system.cpu.icachePort: MinorLine: id=0/1.1/1 size=36 \
                                vaddr=0x5c paddr=0x5c
```

### minorview.py

Minorview (util/minorview.py) 可用于可视化 MinorTrace 创建的数据。

```
usage: minorview.py [-h] [--picture picture-file] [--prefix name]
                   [--start-time time] [--end-time time] [--mini-views]
                   event-file

Minor visualiser

positional arguments:
  event-file

optional arguments:
  -h, --help            show this help message and exit
  --picture picture-file
                        markup file containing blob information (default:
                        <minorview-path>/minor.pic)
  --prefix name         name prefix in trace for CPU to be visualised
                        (default: system.cpu)
  --start-time time     time of first event to load from file
  --end-time time       time of last event to load from file
  --mini-views          show tiny views of the next 10 time steps
```

原始调试输出可以作为 event-file 传递给 minorview.py。它将挑选出 MinorTrace 行，并使用模拟中命名单元的其他行（如上例中的 system.cpu.dcachePort）在可视化器上单击单元时显示为“注释”。

单击包含指令或行的单元将弹出一个气泡，提供源自 MinorInst/MinorLine 行的额外信息。

`–start-time` 和 `–end-time` 允许仅加载调试文件的部分。

`–prefix` 允许提供要检查的 CPU 的名称前缀。默认为 `system.cpu`。

在可视化器中，按钮 Start, End, Back, Forward, Play 和 Stop 可用于控制显示的模拟时间。

对角线条纹彩色块显示它们代表的指令或行的 [InstId](
http://doxygen.gem5.org/release/current/classMinor_1_1InstId.html)。请注意，[Fetch1](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch1.html) 和 f1ToF2.F 中的行仅显示行的 id 字段，并且 [Fetch2](
http://doxygen.gem5.org/release/current/classMinor_1_1Fetch2.html), f2ToD, 和 decode.inputBuffer 中的指令还没有执行序列号。T/S.P/L/F.E 按钮可用于打开和关闭 [InstId](
http://doxygen.gem5.org/release/current/classMinor_1_1InstId.html) 的部分，以便于理解显示。有用的组合是：

|组合|原因|
|:----------|:---------------------------------------------------------------------------------------------------------------------------|
|E          |仅显示最终执行序列号                                                                                 |
|F/E        |显示指令相关的数字                                                                                        |
|S/P        |仅显示流相关的数字（观察流序列随分支变化而不随预测分支变化）|
|S/E        |显示指令及其流                                                                                          |

右侧的图例显示了所有可显示的颜色（有些颜色选择很糟糕！）：

|符号 |含义                                                      |
|:------|:------------------------------------------------------------|
|U      |未知数据                                                  |
|B      |阻塞阶段                                                |
|-      |气泡                                                       |
|E      |空队列槽                                             |
|R      |保留队列槽                                          |
|F      |故障                                                        |
|r      |读取（用作 dcachePort 中数据的最左侧条纹） |
|w      |写入 " "                                                    |
|0 to 9 |对应数据的最后一位十进制数字                 |

```
    ,---------------.         .--------------.  *U
    | |=|->|=|->|=| |         ||=|||->||->|| |  *-  <- Fetch queues/LSQ
    `---------------'         `--------------'  *R
    === ======                                  *w  <- Activity/Stage activity
                              ,--------------.  *1
    ,--.      ,.      ,.      | ============ |  *3  <- Scoreboard
    |  |-\[]-\||-\[]-\||-\[]-\| ============ |  *5  <- Execute::inFlightInsts
    |  | :[] :||-/[]-/||-/[]-/| -. --------  |  *7
    |  |-/[]-/||  ^   ||      |  | --------- |  *9
    |  |      ||  |   ||      |  | ------    |
[]->|  |    ->||  |   ||      |  | ----      |
    |  |<-[]<-||<-+-<-||<-[]<-|  | ------    |->[] <- Execute to Fetch1,
    '--`      `'  ^   `'      | -' ------    |        Fetch2 branch data
             ---. |  ---.     `--------------'
             ---' |  ---'       ^       ^
                  |   ^         |       `------------ Execute
  MinorBuffer ----' input       `-------------------- Execute input buffer
                    buffer
```

阶段显示当前正在生成/处理的指令的颜色。

阶段之间的前向 FIFO 显示当前 tick 推入它们的数据（向左），传输中的数据，以及在其输出端可用的数据（向右）。

[Fetch2](
http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Fetch2.html) 和 [Fetch1](
http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Fetch1.html) 之间的后向 FIFO 显示分支预测数据。

通常，所有显示的数据在指示时间周期活动结束时是正确的，但在阶段间 FIFO 被 tick 之前。因此，每个 FIFO 都有一个额外的槽来显示断言的新输入数据，以及当前在 FIFO 内的所有数据。

每个阶段的输入缓冲区显示在相应阶段下方，并将这些缓冲区的内容显示为水平条。标记为保留（默认为青色）的条保留供上一阶段填充。因此，具有所有保留或占用槽的输入缓冲区将阻止上一阶段生成输出。

Fetch 队列和 [LSQ](
http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1LSQ.html) 显示每个接口队列中的行/指令，并在其框架顶部的两种条纹颜色中显示 TLB 和内存中的行/指令数。

在 [Execute](
http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Execute.html) 内部，水平条代表各个 FU 流水线。左侧的垂直条是输入缓冲区，右侧的条是本周期提交的指令。[Execute](
http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Execute.html) 的背景显示本周期在其原始 FU 流水线位置提交的指令。

[Execute](
http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Execute.html) 块顶部的条带显示 [Execute](
http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Execute.html) 正在提交的当前 streamSeqNum。
[Fetch1](
http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Fetch1.html) 顶部的类似条纹显示该阶段预期的 streamSeqNum，[Fetch2](
http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Fetch2.html) 顶部的条纹显示其发布的 predictionSeqNum。

记分板显示在飞指令的数量，这些指令将提交结果到所示位置的寄存器。记分板包含每个整数和浮点寄存器的插槽。

Execute::inFlightInsts 队列显示 [Execute](http://doxygen.gem5.org/release/current/classgem5_1_1minor_1_1Execute.html) 中所有在飞的指令，最旧的指令（下一条要提交的指令）在右侧。

`Stage activity` 显示每个阶段的信号活动（如 E/1）（左侧为 CPU 杂项活动）

`Activity` 显示阶段和管道活动的计数。

### minor.pic 格式

minor.pic 文件 (src/minor/minor.pic) 描述了可视化器上模型块的布局。其格式在提供的 minor.pic 文件中描述。
