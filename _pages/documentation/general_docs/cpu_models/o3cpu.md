---
layout: documentation
title: 乱序 CPU 模型
doc: gem5 documentation
parent: cpu_models
permalink: /documentation//general_docs/cpu_models/O3CPU
---

# **O3CPU**

目录

 1. [流水线阶段](##Pipeline-stages)
 2. [Execute-in-execute 模型](##Execute-in-execute-model)
 3. [模板策略](##Template-Policies)
 4. [ISA 独立性](##ISA-independence)
 5. [与 ThreadContext 交互](##Interaction-with-ThreadContext**)

O3CPU 是我们在 v2.0 版本中的新详细模型。它是一个乱序 CPU 模型，大致基于 Alpha 21264。此页面将为您提供 O3CPU 模型、流水线阶段和流水线资源的概述。我们已努力保持代码有良好的文档，因此请浏览代码以了解 O3CPU 各部分如何工作的确切细节。


## **流水线阶段**
* 取指 (Fetch)

     每个周期提取指令，根据所选策略选择从哪个线程提取。这是首次创建 DynInst 的阶段。还处理分支预测。

* 解码 (Decode)

  每个周期解码指令。还处理 PC 相对无条件分支的早期解析。

* 重命名 (Rename)

  使用带有空闲列表的物理寄存器文件重命名指令。如果没有足够的寄存器重命名，或者后端资源已满，将停顿。此时还处理任何序列化指令，通过在重命名阶段停顿它们直到后端排空。

* 发出/执行/写回 (Issue/Execute/Writeback)

  我们的模拟器模型在指令调用 execute() 函数时处理执行和写回，因此我们将这三个阶段合并为一个阶段。此阶段 (IEW) 处理将指令分派到指令队列，告诉指令队列发出指令，以及执行和写回指令。

* 提交 (Commit)

   每个周期提交指令，处理指令可能引起的任何故障。还处理在分支预测错误的情况下重定向前端。


## **Execute-in-execute 模型**

对于 O3CPU，我们努力使其具有高度的时序准确性。为此，我们使用了一个在流水线执行阶段实际执行指令的模型。大多数模拟器模型会在流水线的开头或结尾执行指令；SimpleScalar 和我们的旧详细 CPU 模型都在流水线开头执行指令，然后将其传递给时序后端。这带来了两个潜在问题：首先，时序后端中可能存在错误，这些错误不会显示在程序结果中。其次，通过在流水线开头执行，指令都是按顺序执行的，乱序加载交互丢失。我们的模型能够避免这些缺陷并提供准确的时序模型。

## **模板策略**

O3CPU 大量使用模板策略来获得一定程度的多态性，而无需使用虚函数。它使用模板策略将 "Impl" 传递给 O3CPU 中使用的几乎所有类。此 Impl 在其中定义了流水线的所有重要类，例如特定的 Fetch 类、Decode 类、特定的 DynInst 类型、CPU 类等。它允许任何将其用作模板参数的类能够获取 Impl 中定义的任何类的完整类型信息。通过获取完整的类型信息，不需要通常用于提供多态性的传统虚函数/基类。主要缺点是 CPU 必须在编译时完全定义，并且模板化类需要手动实例化。有关示例 Impl 类，请参见 `src/cpu/o3/impl.hh ` 和 `src/cpu/o3/cpu_policy.hh`。

## **ISA 独立性**

O3CPU 的设计旨在尝试分离依赖于 ISA 的代码和独立于 ISA 的代码。流水线阶段和资源主要是 ISA 独立的，以及低级 CPU 代码。ISA 依赖代码实现特定于 ISA 的函数。例如，AlphaO3CPU 实现特定于 Alpha 的函数，例如从错误中断硬件返回 (hwrei()) 或读取中断标志。低级 CPU，FullO3CPU，负责协调所有流水线阶段并处理其他独立于 ISA 的操作。我们希望这种分离使得实现未来的 ISA 变得更容易，因为希望只需重新定义高级类。

## **与 ThreadContext 交互**

[ThreadContext](/documentation/general_docs/cpu_models/execution_basics) 为外部对象提供了访问 CPU 内线程状态的接口。但是，由于 O3CPU 是乱序 CPU，这稍微复杂一些。虽然在任何给定周期定义架构状态是明确的，但如果更改该架构状态会发生什么并没有明确定义。因此，可以毫不费力地对 ThreadContext 进行读取，但是对 ThreadContext 进行写入和更改寄存器状态需要 CPU 刷新整个流水线。这是因为可能有在飞指令依赖于已更改的寄存器，并且不清楚它们是否应该查看寄存器更新。因此，访问 ThreadContext 可能会导致 CPU 模拟变慢。

## **后端流水线**
### 计算指令
计算指令更简单，因为它们不访问内存并且不与 LSQ 交互。下面包含一个高级调用链（仅重要函数）以及对每个函数功能的描述。

```cpp
Rename::tick()->Rename::RenameInsts()
IEW::tick()->IEW::dispatchInsts()
IEW::tick()->InstructionQueue::scheduleReadyInsts()
IEW::tick()->IEW::executeInsts()
IEW::tick()->IEW::writebackInsts()
Commit::tick()->Commit::commitInsts()->Commit::commitHead()
```

- 重命名 (`Rename::renameInsts()`)。
顾名思义，寄存器被重命名，指令被推送到 IEW 阶段。它检查 IQ/LSQ 是否可以容纳新指令。
- 分派 (`IEW::dispatchInsts()`)。
此函数将重命名的指令插入到 IQ 和 LSQ 中。
- 调度 (`InstructionQueue::scheduleReadyInsts()`)
IQ 在就绪列表中管理就绪指令（操作数就绪），并将它们调度到可用的 FU。FU 的延迟在此处设置，当 FU 完成时指令被发送去执行。
- 执行 (`IEW::executeInsts()`)。
这里调用计算指令的 `execute()` 函数并发送到提交。请注意，`execute()` 将结果写入目标寄存器。
- 写回 (`IEW::writebackInsts()`)。
这里调用 `InstructionQueue::wakeDependents()`。依赖指令将被添加到就绪列表以进行调度。
- 提交 (`Commit::commitInsts()`)。
一旦指令到达 ROB 的头部，它将被提交并从 ROB 中释放。

### 加载指令
加载指令在执行之前与计算指令共享相同的路径。

```cpp
IEW::tick()->IEW::executeInsts()
  ->LSQUnit::executeLoad()
    ->StaticInst::initiateAcc()
      ->LSQ::pushRequest()
        ->LSQUnit::read()
          ->LSQRequest::buildPackets()
          ->LSQRequest::sendPacketToCache()
    ->LSQUnit::checkViolation()
DcachePort::recvTimingResp()->LSQRequest::recvTimingResp()
  ->LSQUnit::completeDataAccess()
    ->LSQUnit::writeback()
      ->StaticInst::completeAcc()
      ->IEW::instToCommit()
IEW::tick()->IEW::writebackInsts()
```

- `LSQUnit::executeLoad()` 将通过调用指令的 `initiateAcc()` 函数来启动访问。通过执行上下文接口，`initiateAcc()` 将调用 `initiateMemRead()` 并最终被定向到 `LSQ::pushRequest()`。
- `LSQ::pushRequest()` 将分配一个 `LSQRequest` 来跟踪所有状态，并开始转换。当转换完成时，它将记录虚拟地址并调用 `LSQUnit::read()`。
- `LSQUnit::read()` 将检查加载是否与之前的任何存储有别名。
  - 如果可以转发，则它将为下一个周期调度 `WritebackEvent`。
  - 如果它有别名但无法转发，它会调用 `InstructionQueue::rescheduleMemInst()` 和 `LSQReuqest::discard()`。
  - 否则，它将数据包发送到缓存。
- `LSQUnit::writeback()` 将调用 `StaticInst::completeAcc()`，它将加载的值写入目标寄存器。然后指令被推送到提交队列。`IEW::writebackInsts()` 然后将其标记为完成并唤醒其依赖项。从这里开始，它与计算指令共享相同的路径。

### 存储指令
存储指令类似于加载指令，但只有在提交后才写回到缓存。

```cpp
IEW::tick()->IEW::executeInsts()
  ->LSQUnit::executeStore()
    ->StaticInst::initiateAcc()
      ->LSQ::pushRequest()
        ->LSQUnit::write()
    ->LSQUnit::checkViolation()
Commit::tick()->Commit::commitInsts()->Commit::commitHead()
IEW::tick()->LSQUnit::commitStores()
IEW::tick()->LSQUnit::writebackStores()
  ->LSQRequest::buildPackets()
  ->LSQRequest::sendPacketToCache()
  ->LSQUnit::storePostSend()
DcachePort::recvTimingResp()->LSQRequest::recvTimingResp()
  ->LSQUnit::completeDataAccess()
    ->LSQUnit::completeStore()
```

- 与 `LSQUnit::read()` 不同，`LSQUnit::write()` 只复制存储数据，但不将数据包发送到缓存，因为存储尚未提交。
- 存储提交后，`LSQUnit::commitStores()` 将把 SQ 条目标记为 `canWB`，以便 `LSQUnit::writebackStores()` 将存储请求发送到缓存。
- 最后，当响应返回时，`LSQUnit::completeStore()` 将释放 SQ 条目。

### 分支预测错误

分支预测错误在 `IEW::executeInsts()` 中处理。它将通知提交阶段开始挤压 ROB 中预测错误分支上的所有指令。

```cpp
IEW::tick()->IEW::executeInsts()->IEW::squashDueToBranch()
```

### 内存顺序预测错误

`InstructionQueue` 有一个 `MemDepUnit` 来跟踪内存顺序依赖性。如果 MemDepUnit 声明存在依赖性，IQ 将不会调度指令。

在 `LSQUnit::read()` 中，LSQ 将搜索可能的别名存储并在可能的情况下转发。否则，加载被阻止，并在阻止存储完成时通过通知 MemDepUnit 重新调度。

`LSQUnit::executeLoad/Store()` 都会调用 `LSQUnit::checkViolation()` 来搜索 LQ 以寻找可能的预测错误。如果找到，它将设置 `LSQUnit::memDepViolator`，稍后 `IEW::executeInsts()` 将启动以挤压预测错误的指令。

```cpp
IEW::tick()->IEW::executeInsts()
  ->LSQUnit::executeLoad()
    ->StaticInst::initiateAcc()
    ->LSQUnit::checkViolation()
  ->IEW::squashDueToMemOrder()
```
