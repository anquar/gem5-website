---
layout: post
title:  "gem5 O3CPU 后端文档更新"
author: Zhengrong Wang
date:   2020-07-18
categories: project
---

关于 gem5 O3CPU 的文档有点抽象，与代码没有密切关联。因此，本文提取关键函数链以显示指令如何由后端处理，并提供一些基本描述以降低 O3CPU 后端（IEW 和 Commit 阶段）的学习曲线。

希望这能帮助更多人。读者应该已经熟悉 gem5。本文也已添加到[文档]({{site.url}}/documentation/general_docs/cpu_models/O3CPU#backend-pipeline)中。

### 计算指令
计算指令更简单，因为它们不访问内存，也不与 LSQ 交互。下面包含一个高级调用链（仅重要函数）以及每个函数功能的描述。

```cpp
Rename::tick()->Rename::RenameInsts()
IEW::tick()->IEW::dispatchInsts()
IEW::tick()->InstructionQueue::scheduleReadyInsts()
IEW::tick()->IEW::executeInsts()
IEW::tick()->IEW::writebackInsts()
Commit::tick()->Commit::commitInsts()->Commit::commitHead()
```

- Rename (`Rename::renameInsts()`)。
顾名思义，寄存器被重命名，指令被推送到 IEW 阶段。它检查 IQ/LSQ 是否可以容纳新指令。
- Dispatch (`IEW::dispatchInsts()`)。
此函数将重命名的指令插入到 IQ 和 LSQ 中。
- Schedule (`InstructionQueue::scheduleReadyInsts()`)
IQ 在就绪列表中管理就绪指令（操作数就绪），并将它们调度到可用的 FU。FU 的延迟在这里设置，当 FU 完成时，指令被发送到执行。
- Execute (`IEW::executeInsts()`)。
这里调用计算指令的 `execute()` 函数并发送到提交。请注意 `execute()` 会将结果写入目标寄存器。
- Writeback (`IEW::writebackInsts()`)。
这里调用 `InstructionQueue::wakeDependents()`。依赖指令将被添加到就绪列表中进行调度。
- Commit (`Commit::commitInsts()`)。
一旦指令到达 ROB 的头部，它将被提交并从 ROB 中释放。

### 加载指令
加载指令与计算指令共享相同的路径，直到执行。

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
- `LSQUnit::read()` 将检查加载是否与任何先前的存储别名。
  - 如果可以转发，它将在下一个周期调度 `WritebackEvent`。
  - 如果它是别名但无法转发，它调用 `InstructionQueue::rescheduleMemInst()` 和 `LSQRequest::discard()`。
  - 否则，它将包发送到缓存。
- `LSQUnit::writeback()` 将调用 `StaticInst::completeAcc()`，这将把加载的值写入目标寄存器。然后指令被推送到提交队列。`IEW::writebackInsts()` 然后将标记它完成并唤醒其依赖项。从这里开始，它与计算指令共享相同的路径。

### 存储指令
存储指令类似于加载指令，但仅在提交后写回到缓存。

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

- 与 `LSQUnit::read()` 不同，`LSQUnit::write()` 只会复制存储数据，但不会将包发送到缓存，因为存储尚未提交。
- 存储提交后，`LSQUnit::commitStores()` 将 SQ 条目标记为 `canWB`，以便 `LSQUnit::writebackStores()` 将存储请求发送到缓存。
- 最后，当响应返回时，`LSQUnit::completeStore()` 将释放 SQ 条目。

### 分支错误预测

分支错误预测在 `IEW::executeInsts()` 中处理。它将通知提交阶段开始压缩错误预测分支上 ROB 中的所有指令。

```cpp
IEW::tick()->IEW::executeInsts()->IEW::squashDueToBranch()
```

### 内存顺序错误预测

`InstructionQueue` 有一个 `MemDepUnit` 来跟踪内存顺序依赖性。
如果 MemDepUnit 声明存在依赖性，IQ 将不会调度指令。

在 `LSQUnit::read()` 中，LSQ 将搜索可能的别名存储并在可能时转发。否则，加载被阻塞，并通过通知 MemDepUnit 在阻塞存储完成时重新调度。

`LSQUnit::executeLoad/Store()` 都将调用 `LSQUnit::checkViolation()` 来搜索 LQ 中可能的错误预测。如果找到，它将设置 `LSQUnit::memDepViolator`，`IEW::executeInsts()` 将稍后开始压缩错误预测的指令。

```cpp
IEW::tick()->IEW::executeInsts()
  ->LSQUnit::executeLoad()
    ->StaticInst::initiateAcc()
    ->LSQUnit::checkViolation()
  ->IEW::squashDueToMemOrder()
```
