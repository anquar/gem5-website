---
layout: documentation
title: MSI 目录实现
doc: Learning gem5
parent: part3
permalink: /documentation/learning_gem5/part3/directory/
author: Jason Lowe-Power
---


实现目录控制器与 L1 缓存控制器非常相似，只是使用不同的状态机表。目录的状态机可以在 Sorin 等人的表 8.2 中找到。由于事情与 L1 缓存大多相似，因此本节主要讨论一些更多的 SLICC 细节以及目录控制器和缓存控制器之间的一些差异。让我们直接深入并开始修改新文件 `MSI-dir.sm`。

```cpp
machine(MachineType:Directory, "Directory protocol")
:
  DirectoryMemory * directory;
  Cycles toMemLatency := 1;

MessageBuffer *forwardToCache, network="To", virtual_network="1",
      vnet_type="forward";
MessageBuffer *responseToCache, network="To", virtual_network="2",
      vnet_type="response";

MessageBuffer *requestFromCache, network="From", virtual_network="0",
      vnet_type="request";

MessageBuffer *responseFromCache, network="From", virtual_network="2",
      vnet_type="response";

MessageBuffer *requestToMemory;

MessageBuffer *responseFromMemory;

{
. . .
}
```

首先，此目录控制器有两个参数，`DirectoryMemory` 和 `toMemLatency`。`DirectoryMemory` 有点奇怪。它在初始化时分配，以便它可以覆盖 *所有* 物理内存，就像一个完整的目录 *而不是目录缓存*。即，`DirectoryMemory` 对象中有指向物理内存中每个 64 字节块的指针。但是，实际条目（如下定义）是通过 `getDirEntry()` 延迟创建的。我们将在下面看到有关 `DirectoryMemory` 的更多详细信息。

接下来是 `toMemLatency` 参数。这将在排队请求时用于 `enqueue` 函数中，以模拟目录延迟。我们在 L1 缓存中没有为此使用参数，但使控制器延迟参数化很简单。此参数默认为 1 个周期。不需要在此处设置默认值。默认值传播到生成的 SimObject 描述文件，作为 SimObject 参数的默认值。

接下来，我们有目录的消息缓冲区。重要的是，*这些必须具有与 L1 缓存中的消息缓冲区相同的虚拟网络号*。这些虚拟网络号是 Ruby 网络在控制器之间引导消息的方式。

还有两个特殊的消息缓冲区：`requestToMemory` 和 `responseFromMemory`。这类似于 `mandatoryQueue`，只是它是像请求者端口，而不像 CPU 的响应者端口。`responseFromMemory` 和 `requestToMemory` 缓冲区将传递通过内存端口发送的响应，并通过内存端口发送请求，正如我们将在下面的动作部分看到的那样。

在参数和消息缓冲区之后，我们需要声明所有状态、事件和其他本地结构。

```cpp
state_declaration(State, desc="Directory states",
                  default="Directory_State_I") {
    // 稳定状态。
    // 注意：这些是像 Sorin 等人那样的“以缓存为中心”的状态。
    // 但是，访问权限是以内存为中心的。
    I, AccessPermission:Read_Write,  desc="Invalid in the caches.";
    S, AccessPermission:Read_Only,   desc="At least one cache has the blk";
    M, AccessPermission:Invalid,     desc="A cache has the block in M";

    // 瞬态
    S_D, AccessPermission:Busy,      desc="Moving to S, but need data";

    // 等待来自内存的数据
    S_m, AccessPermission:Read_Write, desc="In S waiting for mem";
    M_m, AccessPermission:Read_Write, desc="Moving to M waiting for mem";

    // 等待来自内存的写确认
    MI_m, AccessPermission:Busy,       desc="Moving to I waiting for ack";
    SS_m, AccessPermission:Busy,       desc="Moving to I waiting for ack";
}

enumeration(Event, desc="Directory events") {
    // 来自缓存的数据请求
    GetS,         desc="Request for read-only data from cache";
    GetM,         desc="Request for read-write data from cache";

    // 来自缓存的写回请求
    PutSNotLast,  desc="PutS and the block has other sharers";
    PutSLast,     desc="PutS and the block has no other sharers";
    PutMOwner,    desc="Dirty data writeback from the owner";
    PutMNonOwner, desc="Dirty data writeback from non-owner";

    // 缓存响应
    Data,         desc="Response to fwd request with data";

    // 来自内存
    MemData,      desc="Data from memory";
    MemAck,       desc="Ack from memory that write is complete";
}

structure(Entry, desc="...", interface="AbstractCacheEntry", main="false") {
    State DirState,         desc="Directory state";
    NetDest Sharers,        desc="Sharers for this block";
    NetDest Owner,          desc="Owner of this block";
}
```

在 `state_declaration` 中，我们定义了一个默认值。对于 SLICC 中的许多事物，您可以指定默认值。但是，此默认值必须使用 C++ 名称（修饰后的 SLICC 名称）。对于下面的状态，您必须使用控制器名称和我们用于状态的名称。在这种情况下，由于机器的名称是 "Directory"，因此 "I" 的名称是 "Directory"+"State"（对于结构的名称）+"I"。

请注意，目录中的权限是“以内存为中心的”。鉴于，所有状态都是以缓存为中心的，如 Sorin 等人所述。

在目录的 `Entry` 定义中，我们对共享者和所有者都使用 NetDest。这对共享者有意义，因为我们想要一个用于所有可能共享块的 L1 缓存的完整位向量。我们也对所有者使用 `NetDest` 的原因是简单地将结构复制到我们作为响应发送的消息中，如下所示。
请注意，我们向 `Entry` 声明添加了一个额外的参数：`main="false"`。
此额外参数告诉替换策略此 `Entry` 是特殊的，应被忽略。
在 `DirectoryMemory` 中，我们正在跟踪 *所有* 后备内存位置，因此不需要替换策略。

在此实现中，我们使用的瞬态比 Sorin 等人的表 8.2 多一些，以处理内存延迟未知的事实。在 Sorin 等人中，作者假设目录状态和内存数据一起存储在主内存中以简化协议。同样，我们还包括新的动作：来自内存的响应。

接下来，我们有需要覆盖和声明的函数。函数 `getDirectoryEntry` 要么返回有效的目录条目，要么如果尚未分配，则分配该条目。以这种方式实现可能会节省一些主机内存，因为这是延迟填充的。

```cpp
Tick clockEdge();

Entry getDirectoryEntry(Addr addr), return_by_pointer = "yes" {
    Entry dir_entry := static_cast(Entry, "pointer", directory[addr]);
    if (is_invalid(dir_entry)) {
        // 我们第一次看到这个地址时为其分配一个条目。
        dir_entry := static_cast(Entry, "pointer",
                                 directory.allocate(addr, new Entry));
    }
    return dir_entry;
}

State getState(Addr addr) {
    if (directory.isPresent(addr)) {
        return getDirectoryEntry(addr).DirState;
    } else {
        return State:I;
    }
}

void setState(Addr addr, State state) {
    if (directory.isPresent(addr)) {
        if (state == State:M) {
            DPRINTF(RubySlicc, "Owner %s\n", getDirectoryEntry(addr).Owner);
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

AccessPermission getAccessPermission(Addr addr) {
    if (directory.isPresent(addr)) {
        Entry e := getDirectoryEntry(addr);
        return Directory_State_to_permission(e.DirState);
    } else  {
        return AccessPermission:NotPresent;
    }
}
void setAccessPermission(Addr addr, State state) {
    if (directory.isPresent(addr)) {
        Entry e := getDirectoryEntry(addr);
        e.changePermission(Directory_State_to_permission(state));
    }
}

void functionalRead(Addr addr, Packet *pkt) {
    functionalMemoryRead(pkt);
}

int functionalWrite(Addr addr, Packet *pkt) {
    if (functionalMemoryWrite(pkt)) {
        return 1;
    } else {
        return 0;
    }
```

接下来，我们需要实现缓存的端口。首先我们指定 `out_port`，然后是 `in_port` 代码块。目录中的 `in_port` 与 L1 缓存中的唯一区别在于目录没有 TBE 或缓存条目。因此，我们不将这两者传递给 `trigger` 函数。

```cpp
out_port(forward_out, RequestMsg, forwardToCache);
out_port(response_out, ResponseMsg, responseToCache);

in_port(memQueue_in, MemoryMsg, responseFromMemory) {
    if (memQueue_in.isReady(clockEdge())) {
        peek(memQueue_in, MemoryMsg) {
            if (in_msg.Type == MemoryRequestType:MEMORY_READ) {
                trigger(Event:MemData, in_msg.addr);
            } else if (in_msg.Type == MemoryRequestType:MEMORY_WB) {
                trigger(Event:MemAck, in_msg.addr);
            } else {
                error("Invalid message");
            }
        }
    }
}

in_port(response_in, ResponseMsg, responseFromCache) {
    if (response_in.isReady(clockEdge())) {
        peek(response_in, ResponseMsg) {
            if (in_msg.Type == CoherenceResponseType:Data) {
                trigger(Event:Data, in_msg.addr);
            } else {
                error("Unexpected message type.");
            }
        }
    }
}

in_port(request_in, RequestMsg, requestFromCache) {
    if (request_in.isReady(clockEdge())) {
        peek(request_in, RequestMsg) {
            Entry e := getDirectoryEntry(in_msg.addr);
            if (in_msg.Type == CoherenceRequestType:GetS) {

                trigger(Event:GetS, in_msg.addr);
            } else if (in_msg.Type == CoherenceRequestType:GetM) {
                trigger(Event:GetM, in_msg.addr);
            } else if (in_msg.Type == CoherenceRequestType:PutS) {
                assert(is_valid(e));
                // 如果只有一个共享者（即请求者）
                if (e.Sharers.count() == 1) {
                    assert(e.Sharers.isElement(in_msg.Requestor));
                    trigger(Event:PutSLast, in_msg.addr);
                } else {
                    trigger(Event:PutSNotLast, in_msg.addr);
                }
            } else if (in_msg.Type == CoherenceRequestType:PutM) {
                assert(is_valid(e));
                if (e.Owner.isElement(in_msg.Requestor)) {
                    trigger(Event:PutMOwner, in_msg.addr);
                } else {
                    trigger(Event:PutMNonOwner, in_msg.addr);
                }
            } else {
                error("Unexpected message type.");
            }
        }
    }
}
```

状态机文件的下一部分是动作。
首先，我们定义发送内存读取和写入的动作。
为此，我们将使用上面定义的特殊 `memQueue_out` 端口。
如果我们在该端口上 `enqueue` 消息，它们将被转换为“正常”的 gem5 `PacketPtr` 并通过配置中定义的内存端口发送。
我们将在配置部分 \<MSI-config-section\> 中看到如何连接此端口。请注意，我们需要两个不同的动作来向内存发送数据以进行请求和响应，因为数据可能到达两个不同的消息缓冲区（虚拟网络）。

```cpp
action(sendMemRead, "r", desc="Send a memory read request") {
    peek(request_in, RequestMsg) {
        enqueue(memQueue_out, MemoryMsg, toMemLatency) {
            out_msg.addr := address;
            out_msg.Type := MemoryRequestType:MEMORY_READ;
            out_msg.Sender := in_msg.Requestor;
            out_msg.MessageSize := MessageSizeType:Request_Control;
            out_msg.Len := 0;
        }
    }
}

action(sendDataToMem, "w", desc="Write data to memory") {
    peek(request_in, RequestMsg) {
        DPRINTF(RubySlicc, "Writing memory for %#x\n", address);
        DPRINTF(RubySlicc, "Writing %s\n", in_msg.DataBlk);
        enqueue(memQueue_out, MemoryMsg, toMemLatency) {
            out_msg.addr := address;
            out_msg.Type := MemoryRequestType:MEMORY_WB;
            out_msg.Sender := in_msg.Requestor;
            out_msg.MessageSize := MessageSizeType:Writeback_Data;
            out_msg.DataBlk := in_msg.DataBlk;
            out_msg.Len := 0;
        }
    }
}

action(sendRespDataToMem, "rw", desc="Write data to memory from resp") {
    peek(response_in, ResponseMsg) {
        DPRINTF(RubySlicc, "Writing memory for %#x\n", address);
        DPRINTF(RubySlicc, "Writing %s\n", in_msg.DataBlk);
        enqueue(memQueue_out, MemoryMsg, toMemLatency) {
            out_msg.addr := address;
            out_msg.Type := MemoryRequestType:MEMORY_WB;
            out_msg.Sender := in_msg.Sender;
            out_msg.MessageSize := MessageSizeType:Writeback_Data;
            out_msg.DataBlk := in_msg.DataBlk;
            out_msg.Len := 0;
        }
}
```

在这段代码中，我们还看到了向 SLICC 协议添加调试信息的最后一种方式：`DPRINTF`。这与 gem5 中的 `DPRINTF` 完全相同，只是在 SLICC 中只有 `RubySlicc` 调试标志可用。

接下来，我们指定更新特定块的共享者和所有者的动作。

```cpp
action(addReqToSharers, "aS", desc="Add requestor to sharer list") {
    peek(request_in, RequestMsg) {
        getDirectoryEntry(address).Sharers.add(in_msg.Requestor);
    }
}

action(setOwner, "sO", desc="Set the owner") {
    peek(request_in, RequestMsg) {
        getDirectoryEntry(address).Owner.add(in_msg.Requestor);
    }
}

action(addOwnerToSharers, "oS", desc="Add the owner to sharers") {
    Entry e := getDirectoryEntry(address);
    assert(e.Owner.count() == 1);
    e.Sharers.addNetDest(e.Owner);
}

action(removeReqFromSharers, "rS", desc="Remove requestor from sharers") {
    peek(request_in, RequestMsg) {
        getDirectoryEntry(address).Sharers.remove(in_msg.Requestor);
    }
}

action(clearSharers, "cS", desc="Clear the sharer list") {
    getDirectoryEntry(address).Sharers.clear();
}

action(clearOwner, "cO", desc="Clear the owner") {
    getDirectoryEntry(address).Owner.clear();
}
```

下一组动作将无效和转发请求发送到目录无法单独处理的缓存。

```cpp
action(sendInvToSharers, "i", desc="Send invalidate to all sharers") {
    peek(request_in, RequestMsg) {
        enqueue(forward_out, RequestMsg, 1) {
            out_msg.addr := address;
            out_msg.Type := CoherenceRequestType:Inv;
            out_msg.Requestor := in_msg.Requestor;
            out_msg.Destination := getDirectoryEntry(address).Sharers;
            out_msg.MessageSize := MessageSizeType:Control;
        }
    }
}

action(sendFwdGetS, "fS", desc="Send forward getS to owner") {
    assert(getDirectoryEntry(address).Owner.count() == 1);
    peek(request_in, RequestMsg) {
        enqueue(forward_out, RequestMsg, 1) {
            out_msg.addr := address;
            out_msg.Type := CoherenceRequestType:GetS;
            out_msg.Requestor := in_msg.Requestor;
            out_msg.Destination := getDirectoryEntry(address).Owner;
            out_msg.MessageSize := MessageSizeType:Control;
        }
    }
}

action(sendFwdGetM, "fM", desc="Send forward getM to owner") {
    assert(getDirectoryEntry(address).Owner.count() == 1);
    peek(request_in, RequestMsg) {
        enqueue(forward_out, RequestMsg, 1) {
            out_msg.addr := address;
            out_msg.Type := CoherenceRequestType:GetM;
            out_msg.Requestor := in_msg.Requestor;
            out_msg.Destination := getDirectoryEntry(address).Owner;
            out_msg.MessageSize := MessageSizeType:Control;
        }
    }
}
```

现在我们有来自目录的响应。在这里，我们正在查看特殊的缓冲区 `responseFromMemory`。您可以在 `src/mem/protocol/RubySlicc_MemControl.sm` 中找到 `MemoryMsg` 的定义。

```cpp
action(sendDataToReq, "d", desc="Send data from memory to requestor. May need to send sharer number, too") {
    peek(memQueue_in, MemoryMsg) {
        enqueue(response_out, ResponseMsg, 1) {
            out_msg.addr := address;
            out_msg.Type := CoherenceResponseType:Data;
            out_msg.Sender := machineID;
            out_msg.Destination.add(in_msg.OriginalRequestorMachId);
            out_msg.DataBlk := in_msg.DataBlk;
            out_msg.MessageSize := MessageSizeType:Data;
            Entry e := getDirectoryEntry(address);
            // 只有当我们是所有者时才需要包括 acks。
            if (e.Owner.isElement(in_msg.OriginalRequestorMachId)) {
                out_msg.Acks := e.Sharers.count();
            } else {
                out_msg.Acks := 0;
            }
            assert(out_msg.Acks >= 0);
        }
    }
}

action(sendPutAck, "a", desc="Send the put ack") {
    peek(request_in, RequestMsg) {
        enqueue(forward_out, RequestMsg, 1) {
            out_msg.addr := address;
            out_msg.Type := CoherenceRequestType:PutAck;
            out_msg.Requestor := machineID;
            out_msg.Destination.add(in_msg.Requestor);
            out_msg.MessageSize := MessageSizeType:Control;
        }
    }
}
```

然后，我们有队列管理和停顿动作。

```cpp
action(popResponseQueue, "pR", desc="Pop the response queue") {
    response_in.dequeue(clockEdge());
}

action(popRequestQueue, "pQ", desc="Pop the request queue") {
    request_in.dequeue(clockEdge());
}

action(popMemQueue, "pM", desc="Pop the memory queue") {
    memQueue_in.dequeue(clockEdge());
}

action(stall, "z", desc="Stall the incoming request") {
    // 没做啥
}
```

最后，我们有状态机文件的转换部分。这些主要来自 Sorin 等人的表 8.2，但也有一些额外的转换来处理未知的内存延迟。

```cpp
transition({I, S}, GetS, S_m) {
    sendMemRead;
    addReqToSharers;
    popRequestQueue;
}

transition(I, {PutSNotLast, PutSLast, PutMNonOwner}) {
    sendPutAck;
    popRequestQueue;
}

transition(S_m, MemData, S) {
    sendDataToReq;
    popMemQueue;
}

transition(I, GetM, M_m) {
    sendMemRead;
    setOwner;
    popRequestQueue;
}

transition(M_m, MemData, M) {
    sendDataToReq;
    clearSharers; // 注意：这在某些情况下并不 *需要*。
    popMemQueue;
}

transition(S, GetM, M_m) {
    sendMemRead;
    removeReqFromSharers;
    sendInvToSharers;
    setOwner;
    popRequestQueue;
}

transition({S, S_D, SS_m, S_m}, {PutSNotLast, PutMNonOwner}) {
    removeReqFromSharers;
    sendPutAck;
    popRequestQueue;
}

transition(S, PutSLast, I) {
    removeReqFromSharers;
    sendPutAck;
    popRequestQueue;
}

transition(M, GetS, S_D) {
    sendFwdGetS;
    addReqToSharers;
    addOwnerToSharers;
    clearOwner;
    popRequestQueue;
}

transition(M, GetM) {
    sendFwdGetM;
    clearOwner;
    setOwner;
    popRequestQueue;
}

transition({M, M_m, MI_m}, {PutSNotLast, PutSLast, PutMNonOwner}) {
    sendPutAck;
    popRequestQueue;
}

transition(M, PutMOwner, MI_m) {
    sendDataToMem;
    clearOwner;
    sendPutAck;
    popRequestQueue;
}

transition(MI_m, MemAck, I) {
    popMemQueue;
}

transition(S_D, {GetS, GetM}) {
    stall;
}

transition(S_D, PutSLast) {
    removeReqFromSharers;
    sendPutAck;
    popRequestQueue;
}

transition(S_D, Data, SS_m) {
    sendRespDataToMem;
    popResponseQueue;
}

transition(SS_m, MemAck, S) {
    popMemQueue;
}

// 如果我们收到对正在等待内存的块的另一个请求，
// 停顿该请求。
transition({MI_m, SS_m, S_m, M_m}, {GetS, GetM}) {
    stall;
}
```

您可以下载完整的 `MSI-dir.sm` 文件
[这里](https://gem5.googlesource.com/public/gem5/+/refs/heads/stable/src/learning_gem5/part3/MSI-dir.sm)。
