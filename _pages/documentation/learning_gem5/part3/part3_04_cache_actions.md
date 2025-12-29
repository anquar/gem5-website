---
layout: documentation
title: 动作代码块
doc: Learning gem5
parent: part3
permalink: /documentation/learning_gem5/part3/cache-actions/
author: Jason Lowe-Power
---

## 动作代码块

状态机文件的下一部分是动作块。
动作块在从一种状态转换到另一种状态期间执行，并由转换代码块调用（我们将在下一节 \<MSI-transitions-section\> 中讨论）。动作是 *单一动作* 块。一些示例是“向目录发送消息”和“弹出缓冲区的头部”。每个动作都应该很小，并且只执行一个动作。

我们将实现的第一个动作是向目录发送 GetS 请求的动作。
每当我们想要读取缓存中未处于 Modified 或 Shared 状态的某些数据时，我们都需要向目录发送 GetS 请求。如前所述，在动作块内会自动填充三个变量（如 `peek` 块中的 `in_msg`）。`address` 是传入 `trigger` 函数的地址，`cache_entry` 是传入 `trigger` 函数的缓存条目，`tbe` 是传入 `trigger` 函数的 TBE。

```cpp
action(sendGetS, 'gS', desc="Send GetS to the directory") {
    enqueue(request_out, RequestMsg, 1) {
        out_msg.addr := address;
        out_msg.Type := CoherenceRequestType:GetS;
        out_msg.Destination.add(mapAddressToMachine(address,
                                MachineType:Directory));
        // See mem/protocol/RubySlicc_Exports.sm for possible sizes.
        out_msg.MessageSize := MessageSizeType:Control;
        // Set that the requestor is this machine so we get the response.
        out_msg.Requestor := machineID;
    }
}
```

在指定动作块时，有两个参数：描述和“简写”。这两个参数用于 HTML 表格生成。简写出现在转换单元格中，因此应尽可能短。SLICC 提供了一种特殊语法，允许在简写中使用粗体 ('')、上标 ('\^') 和空格 ('\_')，以帮助保持简短。其次，当您单击特定动作时，描述也会显示在 HTML 表格中。描述可以更长，有助于解释动作的作用。

接下来，在此动作中，我们将向目录发送一条消息，通过我们在 `in_port` 块上方声明的 `request_out` 端口。
`enqueue` 函数类似于 `peek` 函数，因为它需要一个代码块。但是，`enqueue` 具有特殊变量 `out_msg`。在 `enqueue` 块中，您可以使用当前数据修改 `out_msg`。

`enqueue` 块接受三个参数，发送消息的消息缓冲区、消息类型和延迟。此延迟（在上面的示例中和整个缓存控制器中均为 1 个周期）是 *缓存延迟*。这是您指定访问缓存延迟的地方，在本例中为未命中。下面我们将看到指定命中延迟也是类似的。

在 `enqueue` 块内部是填充消息数据的地方。对于请求的地址，我们可以使用自动填充的 `address` 变量。我们正在发送 GetS 消息，因此我们使用该消息类型。接下来，我们需要指定消息的目的地。
为此，我们使用 `mapAddressToMachine` 函数，该函数接受地址和我们要发送到的机器类型。这将根据地址查找正确的 `MachineID`。我们调用 `Destination.add` 因为 `Destination` 是一个 `NetDest` 对象，或者说是所有 `MachineID` 的位图。

最后，我们需要指定消息大小（来自 `mem/protocol/RubySlicc_Exports.sm`）并将我们自己设置为请求者。
通过将此 `machineID` 设置为请求者，它将允许目录响应该缓存或将其转发到另一个缓存以响应该请求。

同样，我们可以创建用于发送其他 get 和 put 请求的动作。
请注意，get 请求表示对数据的请求，而 put 请求表示我们在降级或驱逐数据副本的请求。

```cpp
action(sendGetM, "gM", desc="Send GetM to the directory") {
    enqueue(request_out, RequestMsg, 1) {
        out_msg.addr := address;
        out_msg.Type := CoherenceRequestType:GetM;
        out_msg.Destination.add(mapAddressToMachine(address,
                                MachineType:Directory));
        out_msg.MessageSize := MessageSizeType:Control;
        out_msg.Requestor := machineID;
    }
}

action(sendPutS, "pS", desc="Send PutS to the directory") {
    enqueue(request_out, RequestMsg, 1) {
        out_msg.addr := address;
        out_msg.Type := CoherenceRequestType:PutS;
        out_msg.Destination.add(mapAddressToMachine(address,
                                MachineType:Directory));
        out_msg.MessageSize := MessageSizeType:Control;
        out_msg.Requestor := machineID;
    }
}

action(sendPutM, "pM", desc="Send putM+data to the directory") {
    enqueue(request_out, RequestMsg, 1) {
        out_msg.addr := address;
        out_msg.Type := CoherenceRequestType:PutM;
        out_msg.Destination.add(mapAddressToMachine(address,
                                MachineType:Directory));
        out_msg.DataBlk := cache_entry.DataBlk;
        out_msg.MessageSize := MessageSizeType:Data;
        out_msg.Requestor := machineID;
    }
}
```

接下来，我们需要指定一个动作，以便在我们从目录收到另一个缓存的转发请求的情况下向另一个缓存发送数据。在这种情况下，我们必须查看请求队列以从请求消息中获取其他数据。此 peek 代码块与 `in_port` 中的代码块完全相同。当您在 `peek` 块中嵌套 `enqueue` 块时，`in_msg` 和 `out_msg` 变量都可用。
这是必需的，以便我们知道要将数据发送到哪个其他缓存。
此外，在此动作中，我们使用 `cache_entry` 变量来获取要发送到另一个缓存的数据。

```cpp
action(sendCacheDataToReq, "cdR", desc="Send cache data to requestor") {
    assert(is_valid(cache_entry));
    peek(forward_in, RequestMsg) {
        enqueue(response_out, ResponseMsg, 1) {
            out_msg.addr := address;
            out_msg.Type := CoherenceResponseType:Data;
            out_msg.Destination.add(in_msg.Requestor);
            out_msg.DataBlk := cache_entry.DataBlk;
            out_msg.MessageSize := MessageSizeType:Data;
            out_msg.Sender := machineID;
        }
    }
}
```

接下来，我们指定用于向目录发送数据以及在转发请求时向原始请求者发送无效确认的动作，当此缓存没有数据时。

```cpp
action(sendCacheDataToDir, "cdD", desc="Send the cache data to the dir") {
    enqueue(response_out, ResponseMsg, 1) {
        out_msg.addr := address;
        out_msg.Type := CoherenceResponseType:Data;
        out_msg.Destination.add(mapAddressToMachine(address,
                                MachineType:Directory));
        out_msg.DataBlk := cache_entry.DataBlk;
        out_msg.MessageSize := MessageSizeType:Data;
        out_msg.Sender := machineID;
    }
}

action(sendInvAcktoReq, "iaR", desc="Send inv-ack to requestor") {
    peek(forward_in, RequestMsg) {
        enqueue(response_out, ResponseMsg, 1) {
            out_msg.addr := address;
            out_msg.Type := CoherenceResponseType:InvAck;
            out_msg.Destination.add(in_msg.Requestor);
            out_msg.DataBlk := cache_entry.DataBlk;
            out_msg.MessageSize := MessageSizeType:Control;
            out_msg.Sender := machineID;
        }
    }
}
```

另一个必需的动作是减少我们正在等待的 acks 数量。当我们从另一个缓存获得无效确认以跟踪总 acks 数时，将使用此方法。对于此动作，我们假设有一个有效的 TBE 并修改动作块中的隐式 `tbe` 变量。

此外，我们还有另一个使协议调试更容易的示例：`APPEND_TRANSITION_COMMENT`。此函数接受字符串或可以轻松转换为字符串的内容（例如 `int`）作为参数。它修改 *协议跟踪* 输出，我们将在 [调试部分](../MSIdebugging) 中讨论。在执行此动作的每个协议跟踪行上，它将打印此缓存仍在等待的总 ack 数。这很有用，因为剩余 acks 的数量是缓存块状态的一部分。

```cpp
action(decrAcks, "da", desc="Decrement the number of acks") {
    assert(is_valid(tbe));
    tbe.AcksOutstanding := tbe.AcksOutstanding - 1;
    APPEND_TRANSITION_COMMENT("Acks: ");
    APPEND_TRANSITION_COMMENT(tbe.AcksOutstanding);
}
```

我们还需要一个动作来存储当我们从带有 ack 计数的目录收到消息时的 acks。对于此动作，我们查看目录的响应消息以获取 acks 数并将其存储在（必须有效）TBE 中。

```cpp
action(storeAcks, "sa", desc="Store the needed acks to the TBE") {
    assert(is_valid(tbe));
    peek(response_in, ResponseMsg) {
        tbe.AcksOutstanding := in_msg.Acks + tbe.AcksOutstanding;
    }
    assert(tbe.AcksOutstanding > 0);
}
```

下一组动作是响应命中和未命中时的 CPU 请求。对于这些动作，我们需要通知定序器（Ruby 与 gem5 其余部分之间的接口）新数据。在存储的情况下，我们给定序器一个指向数据块的指针，定序器就地更新数据。

```cpp
action(loadHit, "Lh", desc="Load hit") {
    assert(is_valid(cache_entry));
    cacheMemory.setMRU(cache_entry);
    sequencer.readCallback(address, cache_entry.DataBlk, false);
}

action(externalLoadHit, "xLh", desc="External load hit (was a miss)") {
    assert(is_valid(cache_entry));
    peek(response_in, ResponseMsg) {
        cacheMemory.setMRU(cache_entry);
        // 转发响应该请求的机器类型
        // 例如，另一个缓存或目录。这用于跟踪统计信息。
        sequencer.readCallback(address, cache_entry.DataBlk, true,
                               machineIDToMachineType(in_msg.Sender));
    }
}

action(storeHit, "Sh", desc="Store hit") {
    assert(is_valid(cache_entry));
    cacheMemory.setMRU(cache_entry);
    // 与上面的读回调相同。
    sequencer.writeCallback(address, cache_entry.DataBlk, false);
}

action(externalStoreHit, "xSh", desc="External store hit (was a miss)") {
    assert(is_valid(cache_entry));
    peek(response_in, ResponseMsg) {
        cacheMemory.setMRU(cache_entry);
        sequencer.writeCallback(address, cache_entry.DataBlk, true,
                               // 注意：这可能是最后一个 ack。
                               machineIDToMachineType(in_msg.Sender));
    }
}

action(forwardEviction, "e", desc="sends eviction notification to CPU") {
    if (send_evictions) {
        sequencer.evictionCallback(address);
    }
}
```

在这些动作中的每一个中，我们对缓存条目调用 `setMRU` 至关重要。`setMRU` 函数允许替换策略知道哪些块是最近访问的。如果您省略 `setMRU` 调用，替换策略将无法正常运行！

在加载和存储时，我们在 `sequencer` 上调用 `read/writeCallback` 函数。这会通知定序器新数据或允许其将数据写入数据块。这些函数采用四个参数（最后一个参数是可选的）：地址、数据块、原始请求是否未命中的布尔值，最后是可选的 `MachineType`。最后一个可选参数用于跟踪有关请求数据所在位置的统计信息。它允许您跟踪数据是来自缓存到缓存传输还是来自内存。

最后，我们还有一个向 CPU 转发驱逐的动作。对于 gem5 的乱序模型，如果在加载提交之前缓存块被驱逐，则需要挤压推测性加载。我们使用在状态机文件顶部指定的参数来检查这是否需要。

接下来，我们有一组分配和释放缓存条目和 TBE 的缓存管理动作。要创建新的缓存条目，我们必须在 `CacheMemory` 对象中有空间。然后，我们可以调用 `allocate` 函数。此分配函数实际上并不分配缓存条目的主机内存，因为此控制器专门化了 `Entry` 类型，这就是为什么我们需要将 `new Entry` 传递给 `allocate` 函数的原因。

此外，在这些动作中，我们调用 `set_cache_entry`、`unset_cache_entry` 以及针对 TBE 的类似函数。这些设置和取消设置通过 `trigger` 函数传入的隐式变量。例如，当分配新的缓存块时，我们调用 `set_cache_entry`，在 `allocateCacheBlock` 之后的所有动作中，`cache_entry` 变量将有效。

还有一个动作将数据从缓存数据块复制到 TBE。这允许我们即使在删除缓存块之后也保留数据，直到我们确定此缓存不再负责该数据。

```cpp
action(allocateCacheBlock, "a", desc="Allocate a cache block") {
    assert(is_invalid(cache_entry));
    assert(cacheMemory.cacheAvail(address));
    set_cache_entry(cacheMemory.allocate(address, new Entry));
}

action(deallocateCacheBlock, "d", desc="Deallocate a cache block") {
    assert(is_valid(cache_entry));
    cacheMemory.deallocate(address);
    // 清除 cache_entry 变量（现在无效）
    unset_cache_entry();
}

action(writeDataToCache, "wd", desc="Write data to the cache") {
    peek(response_in, ResponseMsg) {
        assert(is_valid(cache_entry));
        cache_entry.DataBlk := in_msg.DataBlk;
    }
}

action(allocateTBE, "aT", desc="Allocate TBE") {
    assert(is_invalid(tbe));
    TBEs.allocate(address);
    // 这会为其他动作更新 tbe 变量
    set_tbe(TBEs[address]);
}

action(deallocateTBE, "dT", desc="Deallocate TBE") {
    assert(is_valid(tbe));
    TBEs.deallocate(address);
    // 这使得 tbe 变量无效
    unset_tbe();
}

action(copyDataFromCacheToTBE, "Dct", desc="Copy data from cache to TBE") {
    assert(is_valid(cache_entry));
    assert(is_valid(tbe));
    tbe.DataBlk := cache_entry.DataBlk;
}
```

下一组动作是管理消息缓冲区的。我们需要添加动作以在消息得到满足后从缓冲区中弹出头消息。`dequeue` 函数采用单个参数，即发生出队的时间。将出队延迟一个周期可以防止 `in_port` 逻辑在单个周期内从同一消息缓冲区中消耗另一条消息。

```cpp
action(popMandatoryQueue, "pQ", desc="Pop the mandatory queue") {
    mandatory_in.dequeue(clockEdge());
}

action(popResponseQueue, "pR", desc="Pop the response queue") {
    response_in.dequeue(clockEdge());
}

action(popForwardQueue, "pF", desc="Pop the forward queue") {
    forward_in.dequeue(clockEdge());
}
```

最后，最后一个动作是停顿。在下面，我们使用的是 "z\_stall"，这是 SLICC 中最简单的一种停顿。通过将动作留空，它会在 `in_port` 逻辑中生成一个“协议停顿”，阻止当前消息缓冲区和所有较低优先级消息缓冲区中的所有消息被处理。使用 "z\_stall" 的协议通常更简单，但性能较低，因为高优先级缓冲区的停顿可能会阻止许多可能不需要停顿的请求。

```cpp
action(stall, "z", desc="Stall the incoming request") {
    // z_stall
}
```

还有另外两种方法可以处理当前无法处理的消息，从而提高协议的性能。（注意：我们将不会在这个简单的示例协议中使用这些更复杂的技术。）第一种是 `recycle`。消息缓冲区有一个 `recycle` 函数，可以将队列头部的请求移动到尾部。这允许立即处理缓冲区中的其他请求或其他缓冲区中的请求。`recycle` 动作通常会显着提高协议的性能。

但是，与缓存一致性的实际实现相比，`recycle` 并不十分现实。对于更现实的高性能消息停顿解决方案，Ruby 在消息缓冲区上提供了 `stall_and_wait` 函数。此函数获取头请求并将其移动到由地址标记的单独结构中。地址是用户指定的，但通常是请求的地址。稍后，当可以处理被阻止的请求时，还有另一个函数 `wakeUpBuffers(address)` 将唤醒在 `address` 上停顿的所有请求，以及 `wakeUpAllBuffers()` 唤醒所有停顿的请求。当请求被“唤醒”时，它被放回消息缓冲区以便随后处理。
