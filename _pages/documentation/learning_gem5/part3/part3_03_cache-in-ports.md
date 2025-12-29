---
layout: documentation
title: 输入端口代码块
doc: Learning gem5
parent: part3
permalink: documentation/learning_gem5/part3/cache-in-ports/
author: Jason Lowe-Power
---


在状态机文件中声明了我们需要的所有结构之后，文件的第一个“功能”部分是“输入端口 (in ports)”。本节指定对不同传入消息 *触发* 什么 *事件*。

但是，在我们到达输入端口之前，我们必须声明我们的输出端口。

```cpp
out_port(request_out, RequestMsg, requestToDir);
out_port(response_out, ResponseMsg, responseToDirOrSibling);
```

这段代码基本上只是将 `requestToDir` 和 `responseToDirOrSibling` 重命名为 `request_out` 和 `response_out`。在文件的后面，当我们想要将消息 *入队 (enqueue)* 到这些消息缓冲区时，我们将使用新名称 `request_out` 和 `response_out`。这还指定了我们将通过这些端口发送的消息的确切实现。我们将在下面的 `MSI-msg.sm` 文件中查看这些类型的确切定义。

接下来，我们创建一个 *输入端口代码块*。在 SLICC 中，有很多情况下的代码块看起来类似于 `if` 块，但它们编码特定信息。例如，`in_port()` 块内的代码被放入一个特殊的生成文件中：`L1Cache_Wakeup.cc`。

所有 `in_port` 代码块都按顺序执行（如果指定了优先级，则基于优先级）。在控制器的每个活动周期中，执行第一个 `in_port` 代码。如果成功，则重新执行它以查看端口上是否有其他可以使用的消息。如果没有消息或没有触发事件，则执行下一个 `in_port` 代码块。

在执行 `in_port` 代码块时，可能会生成三种不同类型的 *停顿 (stalls)*。首先，每个控制器的每个周期的转换次数有一个参数化限制。如果达到此限制（即，消息缓冲区上的消息多于每周期转换限制），则所有 `in_port` 将停止处理并等待直到下一个周期继续。其次，可能会出现 *资源停顿 (resource stall)*。如果某些所需资源不可用，就会发生这种情况。例如，如果使用 `BankedArray` 带宽模型，则所需的缓存库可能当前被占用。第三，可能会出现 *协议停顿 (protocol stall)*。这是一种特殊的动作，导致状态机停顿直到下一个周期。

重要的是要注意，协议停顿和资源停顿会阻止 **所有** `in_port` 块执行。例如，如果第一个 `in_port` 块生成协议停顿，则其他端口都不会执行，从而阻止所有消息。这就是为什么使用正确数量和顺序的虚拟网络很重要的原因。

下面是针对我们的 L1 缓存控制器的最高优先级消息（来自目录或其他缓存的响应）的 `in_port` 块的完整代码。接下来我们将分解代码块来解释每个部分。

```cpp
in_port(response_in, ResponseMsg, responseFromDirOrSibling) {
    if (response_in.isReady(clockEdge())) {
        peek(response_in, ResponseMsg) {
            Entry cache_entry := getCacheEntry(in_msg.addr);
            TBE tbe := TBEs[in_msg.addr];
            assert(is_valid(tbe));

            if (machineIDToMachineType(in_msg.Sender) ==
                        MachineType:Directory) {
                if (in_msg.Type != CoherenceResponseType:Data) {
                    error("Directory should only reply with data");
                }
                assert(in_msg.Acks + tbe.AcksOutstanding >= 0);
                if (in_msg.Acks + tbe.AcksOutstanding == 0) {
                    trigger(Event:DataDirNoAcks, in_msg.addr, cache_entry,
                            tbe);
                } else {
                    trigger(Event:DataDirAcks, in_msg.addr, cache_entry,
                            tbe);
                }
            } else {
                if (in_msg.Type == CoherenceResponseType:Data) {
                    trigger(Event:DataOwner, in_msg.addr, cache_entry,
                            tbe);
                } else if (in_msg.Type == CoherenceResponseType:InvAck) {
                    DPRINTF(RubySlicc, "Got inv ack. %d left\n",
                            tbe.AcksOutstanding);
                    if (tbe.AcksOutstanding == 1) {
                        trigger(Event:LastInvAck, in_msg.addr, cache_entry,
                                tbe);
                    } else {
                        trigger(Event:InvAck, in_msg.addr, cache_entry,
                                tbe);
                    }
                } else {
                    error("Unexpected response from other cache");
                }
            }
        }
    }
}
```

首先，就像上面的 out\_port 一样，"response\_in" 是我们稍后引用此端口时将使用的名称，"ResponseMsg" 是我们期望在此端口上的消息类型（因为此端口处理对我们请求的响应）。所有 `in_port` 代码块的第一步是检查消息缓冲区以查看是否有任何消息需要处理。如果没有，则跳过此 `in_port` 代码块并执行下一个。

```cpp
in_port(response_in, ResponseMsg, responseFromDirOrSibling) {
    if (response_in.isReady(clockEdge())) {
        . . .
    }
}
```

假设消息缓冲区中有一条有效消息，接下来，我们通过使用特殊代码块 `peek` 来获取该消息。Peek 是一个特殊函数。peek 语句中的任何代码都会声明并填充一个特殊变量：`in_msg`。这包含端口头部的消息（在本例中为 ResponseMsg 类型，由 `peek` 调用的第二个参数指定）。在这里，`response_in` 是我们要查看的端口。

然后，我们需要获取传入地址的缓存条目和 TBE。（我们将查看下面的响应消息中的其他参数。）在上面，我们实现了 getCacheEntry。它将返回地址的有效匹配条目，如果没有匹配的缓存块，则返回无效条目。

对于 TBE，由于这是对该缓存控制器发起的请求的响应，因此 TBE 表中 *必须* 有一个有效的 TBE。因此，我们看到了我们的第一个调试语句，一个 *assert*。这是简化缓存一致性协议调试的方法之一。鼓励大量使用断言以使调试更容易。

```cpp
peek(response_in, ResponseMsg) {
    Entry cache_entry := getCacheEntry(in_msg.addr);
    TBE tbe := TBEs[in_msg.addr];
    assert(is_valid(tbe));

    . . .
}
```

接下来，我们需要根据消息决定触发什么事件。为此，我们需要首先讨论数据响应消息携带的内容。

要声明新的消息类型，首先为所有消息类型创建一个新文件：`MSI-msg.sm`。在此文件中，您可以声明将在协议的所有 SLICC 文件中 *全局* 使用的任何结构。稍后我们将通过 `MSI.slicc` 文件将此文件包含在所有状态机定义中。这类似于在 C/C++ 的头文件中包含全局定义。

在 `MSI-msg.sm` 文件中，添加以下代码块：

```cpp
structure(ResponseMsg, desc="Used for Dir->Cache and Fwd message responses",
          interface="Message") {
    Addr addr,                   desc="Physical address for this response";
    CoherenceResponseType Type,  desc="Type of response";
    MachineID Sender,            desc="Node who is responding to the request";
    NetDest Destination,         desc="Multicast destination mask";
    DataBlock DataBlk,           desc="data for the cache line";
    MessageSizeType MessageSize, desc="size category of the message";
    int Acks,                    desc="Number of acks required from others";

    // This must be overridden here to support functional accesses
    bool functionalRead(Packet *pkt) {
        if (Type == CoherenceResponseType:Data) {
            return testAndRead(addr, DataBlk, pkt);
        }
        return false;
    }

    bool functionalWrite(Packet *pkt) {
        // No check on message type required since the protocol should read
        // data block from only those messages that contain valid data
        return testAndWrite(addr, DataBlk, pkt);
    }
}
```

该消息只是另一个 SLICC 结构，类似于我们之前定义的结构。但是，这一次，我们有一个它正在实现的特定接口：`Message`。在此消息中，我们可以添加协议所需的任何成员。在这种情况下，我们首先有地址。注意，一个常见的“陷阱”是您 *不能* 使用带有大写 "A" 的 "Addr" 作为成员名称，因为它与类型名称相同！

接下来，我们有响应的类型。在我们的例子中，有两种类型的响应数据和来自其他缓存的无效确认（在它们使副本无效之后）。因此，我们需要定义一个 *枚举*，`CoherenceResponseType`，以便在此消息中使用它。在同一文件中 `ResponseMsg` 声明 *之前* 添加以下代码。

```cpp
enumeration(CoherenceResponseType, desc="Types of response messages") {
    Data,       desc="Contains the most up-to-date data";
    InvAck,     desc="Message from another cache that they have inv. the blk";
}
```

接下来，在响应消息类型中，我们有发送响应的 `MachineID`。`MachineID` 是发送响应的 *特定机器*。例如，它可能是目录 0 或缓存 12。`MachineID` 既包含 `MachineType`（例如，我们在第一个 `machine()` 中声明的 `L1Cache`）也包含该机器类型的特定 *版本*。在配置系统时，我们将回到机器版本号。

接下来，所有消息都需要一个 *目的地* 和一个 *大小*。目的地指定为 `NetDest`，它是系统中所有 `MachineID` 的位图。这允许将消息广播到灵活的一组接收器。消息也有大小。您可以在 `src/mem/ruby/protocol/RubySlicc_Exports.sm` 中找到可能的消息大小。

此消息还可以包含数据块和预期的 ack 数。因此，我们也可以在消息定义中包含这些内容。

最后，我们还必须定义功能读写函数。Ruby 使用这些来在功能读写时检查正在传输的消息。注意：此功能目前非常脆弱，如果对于功能读取或写入的地址有正在传输的消息，则功能访问可能会失败。

您可以下载完整的 `MSI-msg.sm` 文件
[这里](https://gem5.googlesource.com/public/gem5/+/refs/heads/stable/src/learning_gem5/part3/MSI-msg.sm)。

现在我们已经定义了响应消息中的数据，我们可以看看我们如何选择在 `in_port` 中为缓存响应触发哪个动作。

```cpp
// 如果是来自目录...
if (machineIDToMachineType(in_msg.Sender) ==
            MachineType:Directory) {
    if (in_msg.Type != CoherenceResponseType:Data) {
        error("Directory should only reply with data");
    }
    assert(in_msg.Acks + tbe.AcksOutstanding >= 0);
    if (in_msg.Acks + tbe.AcksOutstanding == 0) {
        trigger(Event:DataDirNoAcks, in_msg.addr, cache_entry,
                tbe);
    } else {
        trigger(Event:DataDirAcks, in_msg.addr, cache_entry,
                tbe);
    }
} else {
    // 这是来自另一个缓存。
    if (in_msg.Type == CoherenceResponseType:Data) {
        trigger(Event:DataOwner, in_msg.addr, cache_entry,
                tbe);
    } else if (in_msg.Type == CoherenceResponseType:InvAck) {
        DPRINTF(RubySlicc, "Got inv ack. %d left\n",
                tbe.AcksOutstanding);
        if (tbe.AcksOutstanding == 1) {
            // 如果恰好剩下一个 ack，那么我们知道它是最后一个 ack。
            trigger(Event:LastInvAck, in_msg.addr, cache_entry,
                    tbe);
        } else {
            trigger(Event:InvAck, in_msg.addr, cache_entry,
                    tbe);
        }
    } else {
        error("Unexpected response from other cache");
    }
}
```

首先，我们检查消息是来自目录还是另一个缓存。如果它来自目录，我们知道它 *必须* 是数据响应（目录永远不会用 ack 响应）。

在这里，我们遇到了向协议添加调试信息的第二种方法：`error` 函数。此函数会中断模拟并打印出字符串参数，类似于 `panic`。

接下来，当我们从目录接收数据时，我们期望我们正在等待的 ack 数永远不会小于 0。我们正在等待的 ack 数是我们当前已收到的 acks (tbe.AcksOutstanding) 和目录告诉我们要等待的 acks 数。我们需要这样检查，因为我们可能在收到目录的消息告诉我们需要等待 acks 之前就已经收到了来自其他缓存的 acks。

对于 acks 有两种可能性，要么我们已经收到了所有的 acks，现在我们正在获取数据（表 8.3 中的 data from dir acks==0），或者我们需要等待更多的 acks。因此，我们检查此条件并触发两个不同的事件，每种可能性一个。

触发转换时，您需要传递四个参数。第一个参数是要触发的事件。这些事件早先在 `Event` 声明中指定。下一个参数是要操作的缓存块的（物理内存）地址。通常这与 `in_msg` 的地址相同，但也可能不同，例如，在替换时，地址是被替换块的地址。接下来是该块的缓存条目和 TBE。如果缓存中该地址没有有效条目或 TBE 表中没有有效 TBE，这些可能是无效的。

当我们下面实现动作时，我们将看到如何使用这最后三个参数。它们作为隐式变量传递给动作：`address`、`cache_entry` 和 `tbe`。

如果执行了 `trigger` 函数，在转换完成后，`in_port` 逻辑将再次执行，假设每个周期的转换次数少于最大转换次数。如果消息缓冲区中有其他消息，则可以触发更多转换。

如果响应来自另一个缓存而不是目录，则会触发其他事件，如上面的代码所示。这些事件直接来自 Sorin 等人的表 8.3。

重要的是，您应该使用 `in_port` 逻辑来检查所有条件。触发事件后，它应该只有 *单个代码路径*。即，任何动作块中都不应有 `if` 语句。如果您想有条件地执行动作，您应该在 `in_port` 逻辑中使用不同的状态或不同的事件。

此约束的原因是 Ruby 在执行转换之前检查资源的方式。在 `in_port` 块生成的代码中，在实际执行转换之前，会检查所有资源。换句话说，转换是原子的，要么执行所有动作，要么都不执行。动作内的条件语句会阻止 SLICC 编译器正确跟踪资源使用情况，并可能导致奇怪的性能、死锁和其他错误。

在为最高优先级网络（响应网络）指定 `in_port` 逻辑之后，我们需要为转发请求网络添加 `in_port` 逻辑。但是，在指定此逻辑之前，我们需要定义 `RequestMsg` 类型和包含请求类型的 `CoherenceRequestType`。这两个定义位于 `MSI-msg.sm` 文件中，*不在 MSI-cache.sm 中*，因为它们是全局定义。

可以将其实现为两个不同的消息和请求类型枚举，一个用于转发，一个用于正常请求，但使用单个消息和类型可以简化代码。

```cpp
enumeration(CoherenceRequestType, desc="Types of request messages") {
    GetS,       desc="Request from cache for a block with read permission";
    GetM,       desc="Request from cache for a block with write permission";
    PutS,       desc="Sent to directory when evicting a block in S (clean WB)";
    PutM,       desc="Sent to directory when evicting a block in M";

    // "Requests" from the directory to the caches on the fwd network
    Inv,        desc="Probe the cache and invalidate any matching blocks";
    PutAck,     desc="The put request has been processed.";
}
```

```cpp
structure(RequestMsg, desc="Used for Cache->Dir and Fwd messages",  interface="Message") {
    Addr addr,                   desc="Physical address for this request";
    CoherenceRequestType Type,   desc="Type of request";
    MachineID Requestor,         desc="Node who initiated the request";
    NetDest Destination,         desc="Multicast destination mask";
    DataBlock DataBlk,           desc="data for the cache line";
    MessageSizeType MessageSize, desc="size category of the message";

    bool functionalRead(Packet *pkt) {
        // Requests should never have the only copy of the most up-to-date data
        return false;
    }

    bool functionalWrite(Packet *pkt) {
        // No check on message type required since the protocol should read
        // data block from only those messages that contain valid data
        return testAndWrite(addr, DataBlk, pkt);
    }
}
```

现在，我们可以指定转发网络 `in_port` 的逻辑。此逻辑很简单，并且为每种请求类型触发不同的事件。

```cpp
in_port(forward_in, RequestMsg, forwardFromDir) {
    if (forward_in.isReady(clockEdge())) {
        peek(forward_in, RequestMsg) {
            // Grab the entry and tbe if they exist.
            Entry cache_entry := getCacheEntry(in_msg.addr);
            TBE tbe := TBEs[in_msg.addr];

            if (in_msg.Type == CoherenceRequestType:GetS) {
                trigger(Event:FwdGetS, in_msg.addr, cache_entry, tbe);
            } else if (in_msg.Type == CoherenceRequestType:GetM) {
                trigger(Event:FwdGetM, in_msg.addr, cache_entry, tbe);
            } else if (in_msg.Type == CoherenceRequestType:Inv) {
                trigger(Event:Inv, in_msg.addr, cache_entry, tbe);
            } else if (in_msg.Type == CoherenceRequestType:PutAck) {
                trigger(Event:PutAck, in_msg.addr, cache_entry, tbe);
            } else {
                error("Unexpected forward message!");
            }
        }
    }
}
```

最后一个 `in_port` 用于强制队列。这是最低优先级的队列，因此它必须在状态机文件的最低位置。强制队列具有特殊的消息类型：`RubyRequest`。此类型在 `src/mem/protocol/RubySlicc_Types.sm` 中指定。它包含两个不同的地址，`LineAddress` 是缓存块对齐的，而 `PhysicalAddress` 保存原始请求的地址，可能未对齐缓存块。它还有其他可能在某些协议中有用的成员。但是，对于这个简单的协议，我们只需要 `LineAddress`。

```cpp
in_port(mandatory_in, RubyRequest, mandatoryQueue) {
    if (mandatory_in.isReady(clockEdge())) {
        peek(mandatory_in, RubyRequest, block_on="LineAddress") {
            Entry cache_entry := getCacheEntry(in_msg.LineAddress);
            TBE tbe := TBEs[in_msg.LineAddress];

            if (is_invalid(cache_entry) &&
                    cacheMemory.cacheAvail(in_msg.LineAddress) == false ) {
                Addr addr := cacheMemory.cacheProbe(in_msg.LineAddress);
                Entry victim_entry := getCacheEntry(addr);
                TBE victim_tbe := TBEs[addr];
                trigger(Event:Replacement, addr, victim_entry, victim_tbe);
            } else {
                if (in_msg.Type == RubyRequestType:LD ||
                        in_msg.Type == RubyRequestType:IFETCH) {
                    trigger(Event:Load, in_msg.LineAddress, cache_entry,
                            tbe);
                } else if (in_msg.Type == RubyRequestType:ST) {
                    trigger(Event:Store, in_msg.LineAddress, cache_entry,
                            tbe);
                } else {
                    error("Unexpected type from processor");
                }
            }
        }
    }
}
```

这段代码中显示了一些新概念。首先，我们在 peek 函数中使用 `block_on="LineAddress"`。这做的就是确保对同一缓存行的任何其他请求都将被阻止，直到当前请求完成。

接下来，我们检查该行的缓存条目是否有效。如果无效，并且集合中没有更多可用条目，那么我们需要驱逐另一个条目。要获取受害者地址，我们可以在 `CacheMemory` 对象上使用 `cacheProbe` 函数。此函数使用参数化的替换策略并返回受害者的物理（行）地址。

重要的是，当我们触发 `Replacement` 事件时，*我们使用受害者块的地址* 以及受害者缓存条目和 tbe。因此，当我们在替换转换中采取动作时，我们将对受害者块进行操作，而不是请求块。此外，我们需要记住 *不要* 从强制队列中删除请求消息 (pop)，直到它得到满足。更换完成后不应弹出消息。

如果发现缓存块有效，那么我们只需触发 `Load` 或 `Store` 事件。
