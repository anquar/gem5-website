---
layout: documentation
title: 调试 SLICC 协议
doc: Learning gem5
parent: part3
permalink: /documentation/learning_gem5/part3/MSIdebugging/
author: Jason Lowe-Power
---



在本节中，我将介绍我在调试本章前面实现的 MSI 协议时采取的步骤。学习调试一致性协议是一项挑战。最好的方法是与过去编写过 SLICC 协议的其他人一起工作。但是，由于您（读者）无法在我调试协议时看着我，所以我试图展示第二好的东西。

在这里，我首先提出一些解决协议错误的高级建议。接下来，我讨论有关死锁的一些细节，以及如何理解可用于修复它们的协议跟踪。然后，我以意识流的风格介绍我在本章中调试 MSI 协议的经历。我将显示生成的错误，然后是错误的解决方案，有时还会附带一些对此尝试解决错误的各种策略的评论。

## 一般调试技巧

Ruby 有许多有用的调试标志。但是，到目前为止最有用的一个是 `ProtocolTrace`。下面，您将看到几个使用协议跟踪来调试协议的示例。协议跟踪打印所有控制器的每个转换。因此，您可以简单地跟踪缓存系统的整个执行过程。

其他有用的调试标志包括：

RubyGenerated
:   打印一堆来自 ruby 生成代码的东西。

RubyPort/RubySequencer
:   查看向 ruby 发送/接收消息的详细信息。

RubyNetwork
:   打印整个网络消息，包括所有消息的发送者/接收者和消息内的数据。当出现数据不匹配时，此标志很有用。

调试 Ruby 协议的第一步是使用 Ruby 随机测试器运行它。随机测试器向 Ruby 系统发出半随机请求，并检查返回的数据是否正确。为了加快调试速度，随机测试器从一个控制器发出对一个块的读取请求，并从另一个控制器发出对同一缓存块（但不同字节）的写入请求。因此，Ruby 随机测试器很好地运用了协议中的瞬态和竞争条件。

不幸的是，随机测试器的配置与使用普通 CPU 时略有不同。因此，我们需要使用与以前不同的 `MyCacheSystem`。您可以下载此不同的缓存系统文件
[这里](/_pages/static/scripts/part3/configs/test_caches.py)，您可以下载修改后的运行脚本
[这里](/_pages/static/scripts/part3/configs/ruby_test.py)。测试运行脚本与简单的运行脚本大致相同，但创建的是 `RubyRandomTester` 而不是 CPU。

通常最好先使用单个“CPU”运行随机测试器。然后，将加载数从默认的 100 增加到在您的主机系统上执行几分钟的数量。接下来，如果没有错误，则将“CPU”的数量增加到两个，并再次将加载数减少到 100。然后，开始增加加载数。最后，您可以将 CPU 数量增加到对于您尝试模拟的系统来说合理的数量。如果您可以运行随机测试器 10-15 分钟，您可以稍微确信随机测试器不会发现任何其他错误。

一旦您的协议与随机测试器一起工作，您就可以继续使用实际应用程序。实际应用程序可能会暴露协议中更多的错误。如果可能的话，使用随机测试器调试协议比使用实际应用程序容易得多！

## 理解协议跟踪

不幸的是，尽管为了捕获其中的错误付出了巨大的努力，一致性协议（甚至是经过严格测试的协议）也会有错误。有时这些错误是相对简单的修复，而有时这些错误会非常隐蔽且难以追踪。在最坏的情况下，错误将表现为死锁：从字面上阻止应用程序取得进展的错误。另一个类似的问题是活锁：由于系统某处的循环，程序永远运行。每当发生活锁或死锁时，接下来要做的是生成协议跟踪。跟踪打印内存系统中发生的每个转换的运行列表：内存请求开始和完成，L1 和目录转换等。然后，您可以使用这些跟踪来识别发生死锁的原因。但是，正如我们将在下面更详细地讨论的那样，调试协议跟踪中的死锁通常极具挑战性。

在这里，我们讨论协议跟踪中出现的内容，以帮助解释正在发生的事情。首先，让我们看一小段协议跟踪（我们将在下面进一步讨论此跟踪的细节）：

```protocoltrace
    ...
    4541   0    L1Cache         Replacement   MI_A>MI_A   [0x4ac0, line 0x4ac0]
    4542   0    L1Cache              PutAck   MI_A>I      [0x4ac0, line 0x4ac0]
    4549   0  Directory              MemAck   MI_M>I      [0x4ac0, line 0x4ac0]
    4641   0        Seq               Begin       >       [0x4aec, line 0x4ac0] LD
    4652   0    L1Cache                Load      I>IS_D   [0x4ac0, line 0x4ac0]
    4657   0  Directory                GetS      I>S_M    [0x4ac0, line 0x4ac0]
    4669   0  Directory             MemData    S_M>S      [0x4ac0, line 0x4ac0]
    4674   0        Seq                Done       >       [0x4aec, line 0x4ac0] 33 cycles
    4674   0    L1Cache       DataDirNoAcks   IS_D>S      [0x4ac0, line 0x4ac0]
    5321   0        Seq               Begin       >       [0x4aec, line 0x4ac0] ST
    5322   0    L1Cache               Store      S>SM_AD  [0x4ac0, line 0x4ac0]
    5327   0  Directory                GetM      S>M_M    [0x4ac0, line 0x4ac0]
```

此跟踪中的每一行都有关于该行显示什么信息的固定模式。具体来说，字段是：

1. 当前 Tick：打印发生的 tick
2. 机器版本：此请求来自的机器编号。例如，如果有 4 个 L1 缓存，则数字将是 0-3。假设每个核心有 1 个 L1 缓存，您可以将其视为代表请求来自的核心。
3. 组件：系统的哪个部分正在进行打印。通常，`Seq` 是 Sequencer 的简写，`L1Cache` 代表 L1 缓存，“Directory”代表目录，依此类推。对于 L1 缓存和目录，这代表机器类型的名称（即 `machine()` 定义中“MachineType:”之后的内容）。
4. 动作：组件正在做什么。例如，“Begin”表示 Sequencer 收到了新请求，“Done”表示 Sequencer 正在完成之前的请求，“DataDirNoAcks”表示我们的 DataDirNoAcks 事件正在被触发。
5. 转换（例如，MI\_A\>MI\_A）：此动作正在进行什么状态转换（格式："currentState\>nextState"）。如果没有发生转换，则用 "\>" 表示。
6. 地址（例如，[0x4ac0, line 0x4ac0]）：请求的物理地址（格式：[wordAddress, lineAddress]）。此地址将始终与缓存块对齐，来自 `Sequencer` 和 `mandatoryQueue` 的请求除外。
7. （可选）注释：可选地，还有一个额外的字段用于传递注释。例如，“LD”、“ST”和“33 cycles”行使用此额外字段向跟踪传递附加信息——例如将请求标识为加载或存储。对于 SLICC 转换，`APPEND_TRANSITION_COMMENT` 通常使用此字段，正如我们 [之前讨论的](../cache-actions/)。

通常，使用空格分隔每个字段（字段之间的空格是隐式添加的，您不需要添加它们）。但是，有时如果字段很长，可能会没有空格，或者该行可能与其他行相比发生偏移。

利用这些信息，让我们分析上面的片段。第一个（tick）字段告诉我们，此跟踪片段显示了在 tick 4541 和 5327 之间内存系统中发生的事情。在这个片段中，所有的请求都来自 L1Cache-0（核心 0）并去往 Directory-0（目录的第一个 bank）。在此期间，我们看到针对缓存行 0x4ac0 的几个内存请求和状态转换，都在 L1 缓存和目录处。例如，在 tick 5322，核心对 0x4ac0 执行存储。但是，目前它的缓存中没有处于 Modified 状态的该行（在核心从 tick 4641-4674 加载它之后，它处于 Shared 状态），因此它需要向目录请求该行的所有权（目录在 tick 5327 收到此请求）。在等待所有权期间，L1Cache-0 从 S (Shared) 转换到 SM\_AD（瞬态——曾处于 S，去往 M，等待 Ack 和 Data）。

要向协议跟踪添加打印，您需要使用 ProtocolTrace 标志添加带有这些字段的打印。例如，如果您查看 `src/mem/ruby/system/Sequencer.cc`，您可以看到 `Seq               Begin` 和 `Seq                Done` 跟踪打印来自何处（搜索 ProtocolTrace）。

## 我在调试 MSI 时遇到的错误

```termout
    gem5.opt: build/MSI/mem/ruby/system/Sequencer.cc:423: void Sequencer::readCallback(Addr, DataBlock&, bool, MachineType, Cycles, Cycles, Cycles): Assertion `m_readRequestTable.count(makeLineAddress(address))' failed.
```

我犯了一个愚蠢的错误。那就是我在 externalStoreHit 中调用了 readCallback 而不是 writeCallback。从简单的开始很好！

```termout
    gem5.opt: build/MSI/mem/ruby/network/MessageBuffer.cc:220: Tick MessageBuffer::dequeue(Tick, bool): Assertion `isReady(current_time)' failed.
```

我在 GDB 中运行 gem5 以获取更多信息。查看
L1Cache\_Controller::doTransitionWorker。当前转换为：
event=L1Cache\_Event\_PutAck, state=L1Cache\_State\_MI\_A,
<next_state=@0x7fffffffd0a0>: L1Cache\_State\_FIRST 简而言之就是 PutAck 上的 MI\_A-\>I。看到它在 popResponseQueue 中。

问题是 PutAck 在转发网络上，而不是响应网络上。

```termout
    panic: Invalid transition
    system.caches.controllers0 time: 3594 addr: 3264 event: DataDirAcks state: IS_D
```

嗯。我认为这不应该发生。所需的 acks 应该始终为 0，或者您从所有者那里获取数据。啊。所以我实现了 sendDataToReq 在目录处始终发送共享者数量。如果我们在 IS\_D 中收到此响应，我们不在乎是否有共享者。因此，为了使事情更简单，我将在 DataDirAcks 上转换到 S。这与 Sorin 等人的原始实现略有不同。

嗯，实际上，我认为这是我们在将自己添加到共享者列表之后发送请求。上面的说法是 *不正确* 的。Sorin 等人没有错！让我们试着不要那样做！

所以，我通过在目录处向请求者发送数据之前检查请求者是否为 *所有者* 来解决了这个问题。只有当请求者是所有者时，我们才包括共享者的数量。否则，这根本无关紧要，我们只需将共享者设置为 0。

```termout
    panic: Invalid transition system.caches.controllers0 time: 5332
    addr: 0x4ac0 event: Inv state: SM\_AD
```

首先，让我们看看在哪里触发 Inv。如果您收到一个 invalidate... 只有那样。也许我们在共享者列表中而不应该在？

我们可以使用协议跟踪和 grep 来查找发生了什么。

```sh
build/MSI/gem5.opt --debug-flags=ProtocolTrace configs/learning_gem5/part6/ruby_test.py | grep 0x4ac0
```

```termout
    ...
    4541   0    L1Cache         Replacement   MI_A>MI_A   [0x4ac0, line 0x4ac0]
    4542   0    L1Cache              PutAck   MI_A>I      [0x4ac0, line 0x4ac0]
    4549   0  Directory              MemAck   MI_M>I      [0x4ac0, line 0x4ac0]
    4641   0        Seq               Begin       >       [0x4aec, line 0x4ac0] LD
    4652   0    L1Cache                Load      I>IS_D   [0x4ac0, line 0x4ac0]
    4657   0  Directory                GetS      I>S_M    [0x4ac0, line 0x4ac0]
    4669   0  Directory             MemData    S_M>S      [0x4ac0, line 0x4ac0]
    4674   0        Seq                Done       >       [0x4aec, line 0x4ac0] 33 cycles
    4674   0    L1Cache       DataDirNoAcks   IS_D>S      [0x4ac0, line 0x4ac0]
    5321   0        Seq               Begin       >       [0x4aec, line 0x4ac0] ST
    5322   0    L1Cache               Store      S>SM_AD  [0x4ac0, line 0x4ac0]
    5327   0  Directory                GetM      S>M_M    [0x4ac0, line 0x4ac0]
```

也许当不应该有共享者时，共享者列表中有一个共享者？我们可以在 clearOwner 和 setOwner 中添加防御性 assert。

```cpp
action(setOwner, "sO", desc="Set the owner") {
    assert(getDirectoryEntry(address).Sharers.count() == 0);
    peek(request_in, RequestMsg) {
        getDirectoryEntry(address).Owner.add(in_msg.Requestor);
    }
}

action(clearOwner, "cO", desc="Clear the owner") {
    assert(getDirectoryEntry(address).Sharers.count() == 0);
    getDirectoryEntry(address).Owner.clear();
}
```

现在，我得到以下错误：

```termout
    panic: Runtime Error at MSI-dir.sm:301: assert failure.
```

这是在 setOwner 中。嗯，实际上这没问题，因为我们需要仍然设置共享者，直到我们计算它们以向请求者发送 ack 计数。让我们删除该 assert 看看会发生什么。什么也没有。那并没有帮助。

目录何时发送 invalidations？仅在 S-\>M\_M 上。所以，在这里，我们需要将自己从 invalidation 列表中删除。我想我们需要将自己保留在共享者列表中，因为我们在发送 ack 数量时减去了一个。

注意：我稍后再回来讨论这个问题。事实证明，这两个 assert 都是错误的。我在下面使用多个 CPU 运行时发现了这一点。在 M-\>S\_D 上进行 GetS 时，在清除 Owner 之前设置了共享者。

所以，到下一个问题！

```termout
    panic: Deadlock detected: current_time: 56091 last_progress_time: 6090 difference:  50001 processor: 0
```

死锁是最糟糕的错误类型。导致死锁的任何原因都是古代历史（即可能发生在许多周期之前），通常很难追踪。

查看协议跟踪的尾部（注意：有时您必须将协议跟踪放入文件中，因为它增长得 *非常* 大），我看到有一个地址正试图被替换。让我们从这里开始。

```protocoltrace
    56091   0    L1Cache         Replacement   SM_A>SM_A   [0x5ac0, line 0x5ac0]
    56091   0    L1Cache         Replacement   SM_A>SM_A   [0x5ac0, line 0x5ac0]
    56091   0    L1Cache         Replacement   SM_A>SM_A   [0x5ac0, line 0x5ac0]
    56091   0    L1Cache         Replacement   SM_A>SM_A   [0x5ac0, line 0x5ac0]
    56091   0    L1Cache         Replacement   SM_A>SM_A   [0x5ac0, line 0x5ac0]
    56091   0    L1Cache         Replacement   SM_A>SM_A   [0x5ac0, line 0x5ac0]
    56091   0    L1Cache         Replacement   SM_A>SM_A   [0x5ac0, line 0x5ac0]
    56091   0    L1Cache         Replacement   SM_A>SM_A   [0x5ac0, line 0x5ac0]
    56091   0    L1Cache         Replacement   SM_A>SM_A   [0x5ac0, line 0x5ac0]
    56091   0    L1Cache         Replacement   SM_A>SM_A   [0x5ac0, line 0x5ac0]
```

在这个替换卡住之前，我在协议跟踪中看到以下内容。注意：这是在 50000 个周期以前！

```protocoltrace
    ...
    5592   0    L1Cache               Store      S>SM_AD  [0x5ac0, line 0x5ac0]
    5597   0  Directory                GetM      S>M_M    [0x5ac0, line 0x5ac0]
    ...
    5641   0  Directory             MemData    M_M>M      [0x5ac0, line 0x5ac0]
    ...
    5646   0    L1Cache         DataDirAcks  SM_AD>SM_A   [0x5ac0, line 0x5ac0]
```

啊！这显然不应该是 DataDirAcks，因为我们只有一个 CPU！所以，我们似乎没有正确减法。回到上一个错误，关于需要将自己保留在列表中，我错了。我忘了我们不再有 -1 的东西了。所以，让我们在最初获得 S-\>M 请求时发送 invalidations 之前将自己从共享列表中删除。

所以！通过这些更改，Ruby 测试器可以用单个核心完成。现在，为了增加难度，我们需要增加加载数，然后增加核心数。

当然，当我将其增加到 10,000 个加载时，出现了死锁。有趣！

我在协议跟踪的末尾看到以下内容。

```protocoltrace
    144684   0    L1Cache         Replacement   MI_A>MI_A   [0x5bc0, line 0x5bc0]
    ...
    144685   0  Directory                GetM   MI_M>MI_M   [0x54c0, line 0x54c0]
    ...
    144685   0    L1Cache         Replacement   MI_A>MI_A   [0x5bc0, line 0x5bc0]
    ...
    144686   0  Directory                GetM   MI_M>MI_M   [0x54c0, line 0x54c0]
    ...
    144686   0    L1Cache         Replacement   MI_A>MI_A   [0x5bc0, line 0x5bc0]
    ...
    144687   0  Directory                GetM   MI_M>MI_M   [0x54c0, line 0x54c0]
    ...
```

这重复了很长时间。

似乎存在循环依赖或类似的东西导致此死锁。

嗯，看来我是对的。in\_ports 的顺序真的很重要！在目录中，我之前的顺序是：request, response, memory。但是，有一个内存数据包被阻塞，因为请求队列被阻塞，这导致了循环依赖和死锁。顺序 *应该* 是 memory, response 和 request。我相信 memory/response 的顺序无关紧要，因为没有响应依赖于内存，反之亦然。

现在，让我们尝试两个 CPU。我遇到的第一件事是 assert 失败。我看到 setState 中的第一个 assert 失败了。

```cpp
void setState(Addr addr, State state) {
    if (directory.isPresent(addr)) {
        if (state == State:M) {
            assert(getDirectoryEntry(addr).Owner.count() == 1);
            assert(getDirectoryEntry(addr).Sharers.count() == 0);
        }
        getDirectoryEntry(addr).DirState := state;
        if (state == State:I)  {
            assert(getDirectoryEntry(addr).Owner.count() == 0);
            assert(getDirectoryEntry(addr).Sharers.count() == 0);
        }
    }
}
```

为了追踪此问题，让我们添加一个调试语句 (DPRINTF) 并使用协议跟踪运行。首先，我在 assert 之前添加了以下行。请注意，您必须使用 RubySlicc 调试标志。这是生成的 SLICC 文件中包含的唯一调试标志。

```cpp
DPRINTF(RubySlicc, "Owner %s\n", getDirectoryEntry(addr).Owner);
```

然后，在使用 ProtocolTrace 和 RubySlicc 运行时，我看到以下输出。

```gem5trace
    118   0  Directory             MemData    M_M>M      [0x400, line 0x400]
    118: system.caches.controllers2: MSI-dir.sm:160: Owner [NetDest (16) 1 0  -  -  - 0  -  -  -  -  -  -  -  -  -  -  -  -  - ]
    118   0  Directory                GetM      M>M      [0x400, line 0x400]
    118: system.caches.controllers2: MSI-dir.sm:160: Owner [NetDest (16) 1 1  -  -  - 0  -  -  -  -  -  -  -  -  -  -  -  -  - ]
```

看起来当我们在状态 M 处理 GetM 时，我们需要先清除所有者，然后再添加新所有者。另一个选项是在 setOwner 中我们可以专门设置 Owner 而不是将其添加到 NetDest。

噢！这是一个新错误！

```termout
    panic: Runtime Error at MSI-dir.sm:229: Unexpected message type..
```

这个失败的消息是什么？让我们使用 RubyNetwork 调试标志来试图追踪导致此错误的消息。在错误上方的几行，我看到以下消息，其目的地是目录。

目的地是一个 NetDest，它是 MachineID 的位向量。这些被分成多个部分。我知道我是用两个 CPU 运行的，所以前两个 0 是给 CPU 的，另一个 1 必须是给目录的。

```gem5trace
    2285: PerfectSwitch-2: Message: [ResponseMsg: addr = [0x8c0, line 0x8c0] Type = InvAck Sender = L1Cache-1 Destination = [NetDest (16) 0 0  -  -  - 1  -  -  -  -  -  -  -  -  -  -  -  -  - ] DataBlk = [ 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0xb1 0xb2 0xb3 0xb4 0xca 0xcb 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 ] MessageSize = Control Acks = 0 ]
```

此消息的类型是 InvAck，这显然是错误的！看起来当我们从目录向 L1 缓存发送 invalidate (Inv) 消息时，我们设置请求者错误了。

是的。这就是问题所在。我们需要将请求者设为原始请求者。对于 FwdGetS/M 这已经是正确的，但我不知何故错过了 invalidate。下一个错误！

```termout
    panic: Invalid transition
    system.caches.controllers0 time: 2287 addr: 0x8c0 event: LastInvAck state: SM_AD
```

这似乎是我没有正确计算 acks。这也可能是因为目录响应比其他缓存慢得多，因为它必须从内存中获取数据。

如果是后者（我应该确信验证这一点），我们可以做的是为目录也包括一个 ack 要求。然后，当目录发送数据（以及所有者）时，减少所需的 acks 并根据新的 ack 计数触发事件。

实际上，第一个假设并不完全正确。我在收到 InvAck 时打印出了 acks 的数量，发生的事情是，在目录告诉它预期多少个 acks 之前，另一个缓存就用 InvAck 响应了。

所以，我们需要做一些类似于我在上面谈论的事情。首先，我们需要让 acks 降至 0 以下，并从中添加来自目录消息的总 acks。然后，我们将不得不使触发最后一个 ack 等的逻辑复杂化。

好的。所以现在我们让 tbe.Acks 降至 0 以下，然后在目录 acks 出现时添加它们。

下一个错误：这是一个棘手的问题。现在的错误是数据不匹配。有点像死锁，数据可能在古代就被破坏了。我相信地址是协议跟踪中的最后一个。

```termout
    panic: Action/check failure: proc: 0 address: 19688 data: 0x779e6d0
    byte\_number: 0 m\_value+byte\_number: 53 byte: 0 [19688, value: 53,
    status: Check\_Pending, initiating node: 0, store\_count: 4]Time:
    5843
```

所以，这可能与 ack 计数有关，虽然我不认为是这个问题。无论哪种方式，用 ack 信息注释协议跟踪是一个好主意。为此，我们可以使用 APPEND\_TRANSITION\_COMMENT 向转换添加注释。

```cpp
action(decrAcks, "da", desc="Decrement the number of acks") {
    assert(is_valid(tbe));
    tbe.Acks := tbe.Acks - 1;
    APPEND_TRANSITION_COMMENT("Acks: ");
    APPEND_TRANSITION_COMMENT(tbe.Acks);
}
```

```protocoltrace
    5737   1    L1Cache              InvAck  SM_AD>SM_AD  [0x400, line 0x400] Acks: -1
```

对于这些数据问题，调试标志 RubyNetwork 很有用，因为它打印数据块在网络中每个点的值。例如，对于上面有问题的地址，看起来从主内存加载后数据块全为 0。我相信这应该有有效数据。事实上，如果我们回溯一段时间，我们会看到有一些非零元素。

```protocoltrace
    5382   1    L1Cache                 Inv      S>I      [0x4cc0, line 0x4cc0]
```

```gem5trace
    5383: PerfectSwitch-1: Message: [ResponseMsg: addr = [0x4cc0, line
    0x4cc0] Type = InvAck Sender = L1Cache-1 Destination = [NetDest (16) 1
    0 - - - 0 - - - - - - - - - - - - - ] DataBlk = [ 0x0 0x0 0x0 0x0 0x0
    0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
    0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
    0x0 0x35 0x36 0x37 0x61 0x6d 0x6e 0x6f 0x70 0x0 0x0 0x0 0x0 0x0 0x0
    0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 ] MessageSize = Control Acks =
    0 ] ... ... ... 5389 0 Directory MemData M\_M\    >M [0x4cc0, line 0x4cc0]
    5390: PerfectSwitch-2: incoming: 0 5390: PerfectSwitch-2: Message:
    [ResponseMsg: addr = [0x4cc0, line 0x4cc0] Type = Data Sender =
    Directory-0 Destination = [NetDest (16) 1 0 - - - 0 - - - - - - - - -
    - - - - ] DataBlk = [ 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
    0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
    0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
    0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
    0x0 ] MessageSize = Data Acks = 1 ]
```

看来内存在 M-\>S 转换时没有正确更新。经过大量挖掘并使用 MemoryAccess 调试标志查看主内存的确切读写内容，我发现在 sendDataToMem 中我使用的是 request\_in。这对于 PutM 是正确的，但对于 Data 不正确。我们需要另一个动作来从响应队列发送数据！

```termout
    panic: Invalid transition
    system.caches.controllers0 time: 44381 addr: 0x7c0 event: Inv state: SM_AD
```

无效转换是我个人最喜欢的 SLICC 错误类型。对于此错误，您确切知道导致该错误的地址，并且很容易通过协议跟踪来查找出了什么问题。但是，在这种情况下，没有任何问题，我只是忘了把这个转换放进去！简单的修复！
