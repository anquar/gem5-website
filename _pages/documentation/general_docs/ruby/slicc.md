---
layout: documentation
title: "SLICC"
doc: gem5 documentation
parent: ruby
permalink: /documentation/general_docs/ruby/slicc/
author: Jason Lowe-Power
---

# SLICC

SLICC 是一种用于指定缓存一致性协议的领域特定语言。SLICC 编译器为不同的控制器生成 C++ 代码，这些代码可以与 Ruby 的其他部分协同工作。
编译器还会生成协议的 HTML 规范。HTML 生成默认关闭。要启用 HTML 输出，请在编译时向 scons 传递选项 "SLICC_HTML=True"。

### 编译器输入

SLICC 编译器将指定协议中涉及的控制器的文件作为输入。.slicc 文件指定所考虑的特定协议使用的不同文件。例如，如果尝试使用 SLICC 指定 MI 协议，则可以使用 MI.slicc 作为指定协议所需的所有文件的文件。指定协议所需的文件包括不同控制器的状态机定义，以及在这些控制器之间传递的网络消息定义。

这些文件的语法类似于 C++。编译器使用 [PLY (Python Lex-Yacc)](http://www.dabeaz.com/ply/) 编写，解析这些文件以创建抽象语法树 (AST)。然后遍历 AST 以构建一些内部数据结构。最后，编译器通过再次遍历树来输出 C++ 代码。AST 表示状态机中存在的不同结构的层次结构。接下来我们描述这些结构。

### 协议状态机

在本节中，我们更仔细地了解包含状态机规范的文件中的内容。

#### 指定数据成员

每个状态机都使用 SLICC 的 **machine** 数据类型来描述。每个机器都有几种不同类型的成员。缓存和目录控制器的机器分别包括缓存内存和目录内存数据成员。我们将使用 src/mem/protocol 中可用的 MI 协议作为运行示例。因此，以下是如何开始编写状态机的方法

```
machine(MachineType:L1Cache, "MI Example L1 Cache")
  : Sequencer * sequencer,
    CacheMemory * cacheMemory,
    int cache_response_latency = 12,
    int issue_latency = 2 {
      // Add rest of the stuff
    }
```
为了让控制器从系统中的不同实体接收消息，机器有多个**消息缓冲区**。这些充当机器的输入和输出端口。以下是指定输出端口的示例。

```
 MessageBuffer requestFromCache, network="To", virtual_network="2", ordered="true";
 MessageBuffer responseFromCache, network="To", virtual_network="4", ordered="true";
```

请注意，消息缓冲区有一些需要正确指定的属性。另一个示例，这次是指定输入端口。

```
 MessageBuffer forwardToCache, network="From", virtual_network="3", ordered="true";
 MessageBuffer responseToCache, network="From", virtual_network="4", ordered="true";
```

接下来，机器包括机器可能达到的**状态**声明。在缓存一致性协议中，状态可以是两种类型——稳定状态和瞬态。如果在没有任何活动的情况下（例如，来自另一个控制器的块请求），缓存块将永远保持在该状态，则称缓存块处于稳定状态。瞬态是在稳定状态之间转换所需的。当两个稳定状态之间的转换不能以原子方式完成时，就需要它们。接下来是一个显示如何声明状态的示例。SLICC 有一个关键字 **state_declaration**，必须用于声明状态。

```
state_declaration(State, desc="Cache states") {
   I, AccessPermission:Invalid, desc="Not Present/Invalid";
   II, AccessPermission:Busy, desc="Not Present/Invalid, issued PUT";
   M, AccessPermission:Read_Write, desc="Modified";
   MI, AccessPermission:Busy, desc="Modified, issued PUT";
   MII, AccessPermission:Busy, desc="Modified, issued PUTX, received nack";
   IS, AccessPermission:Busy, desc="Issued request for LOAD/IFETCH";
   IM, AccessPermission:Busy, desc="Issued request for STORE/ATOMIC";
}
```

状态 I 和 M 是此示例中唯一的稳定状态。再次注意，必须为状态指定某些属性。

状态机需要指定它可以处理的**事件**，从而从一个状态转换到另一个状态。SLICC 提供了关键字 **enumeration**，可用于指定可能的事件集。一个示例以进一步说明这一点 -

```
enumeration(Event, desc="Cache events") {
   // From processor
   Load,       desc="Load request from processor";
   Ifetch,     desc="Ifetch request from processor";
   Store,      desc="Store request from processor";
   Data,       desc="Data from network";
   Fwd_GETX,        desc="Forward from network";
   Inv,        desc="Invalidate request from dir";
   Replacement,  desc="Replace a block";
   Writeback_Ack,   desc="Ack from the directory for a writeback";
   Writeback_Nack,   desc="Nack from the directory for a writeback";
}
```

在开发协议机器时，我们可能需要定义表示内存系统中不同实体的结构。
SLICC 为此目的提供了关键字 **structure**。以下是一个示例

```
structure(Entry, desc="...", interface="AbstractCacheEntry") {
   State CacheState,        desc="cache state";
   bool Dirty,              desc="Is the data dirty (different than memory)?";
   DataBlock DataBlk,       desc="Data in the block";
}
```

使用 SLICC 结构的一个好处是，它会自动为您生成不同字段的 get 和 set 函数。它还会编写一个很好的 print 函数并重载 \<\< 运算符。但是，如果您希望自己完成所有工作，可以在结构声明中使用关键字 **external**。这将阻止 SLICC 为此结构生成 C++ 代码。

```
structure(TBETable, external="yes") {
   TBE lookup(Address);
   void allocate(Address);
   void deallocate(Address);
   bool isPresent(Address);
}
```

实际上，src/mem/protocol/RubySlicc_\*.sm 文件中存在许多预定义类型。您可以使用它们，或者如果需要新类型，也可以定义新类型。您还可以使用关键字 **interface** 来利用 C++ 中可用的继承功能。请注意，目前 SLICC 仅支持公共继承。

我们也可以像在 C++ 中一样声明和定义函数。编译器期望控制器始终定义某些函数。这些包括
- getState()
- setState()

#### 机器的输入

由于协议是状态机，我们需要指定机器在接收输入时如何从一个状态转换到另一个状态。如前所述，每个机器都有多个输入和输出端口。对于每个输入端口，使用 **in_port** 关键字来指定机器在该输入端口上接收到消息时的行为。以下是一个显示声明输入端口语法的示例。

```
in_port(mandatoryQueue_in, RubyRequest, mandatoryQueue, desc="...") {
  if (mandatoryQueue_in.isReady()) {
    peek(mandatoryQueue_in, RubyRequest, block_on="LineAddress") {
      Entry cache_entry := getCacheEntry(in_msg.LineAddress);
      if (is_invalid(cache_entry) &&
          cacheMemory.cacheAvail(in_msg.LineAddress) == false ) {
        // make room for the block
        trigger(Event:Replacement, cacheMemory.cacheProbe(in_msg.LineAddress),
                getCacheEntry(cacheMemory.cacheProbe(in_msg.LineAddress)),
                TBEs[cacheMemory.cacheProbe(in_msg.LineAddress)]);
      }
      else {
        trigger(mandatory_request_type_to_event(in_msg.Type), in_msg.LineAddress,
                cache_entry, TBEs[in_msg.LineAddress]);
      }
    }
  }
}
```

如您所见，in_port 接受多个参数。第一个参数 mandatoryQueue_in 是文件中使用的 in_port 的标识符。下一个参数 RubyRequest 是此输入端口接收的消息类型。每个输入端口使用队列来存储消息，队列的名称是第三个参数。

关键字 **peek** 用于从输入端口的队列中提取消息。使用此关键字会隐式声明一个变量 **in_msg**，其类型与输入端口声明中指定的类型相同。此变量指向队列头部的消息。它可以用于访问消息的字段，如上面的代码所示。

一旦分析了传入消息，就该使用此消息采取适当的操作并更改机器的状态。这是使用关键字 **trigger** 完成的。trigger 函数实际上仅在 SLICC 代码中使用，在生成的代码中不存在。相反，此调用被转换为对生成的代码中出现的 **doTransition()** 函数的调用。doTransition() 函数由 SLICC 为每个状态机自动生成。trigger 的参数数量取决于机器本身。通常，trigger 的输入参数是需要处理的消息类型、此消息针对的地址、该地址的缓存和事务缓冲区条目。

**trigger** 还会增加一个计数器，在转换之前检查该计数器。在一个 ruby 周期中，可以执行的转换数量有限制。这样做是为了更接近基于硬件的状态机。**@TODO：如果没有更多转换了会发生什么？唤醒会中止吗？**

#### 动作

在本节中，我们将介绍如何定义状态机可以执行的动作。当状态机接收到某个输入消息（然后用于进行转换）时，将调用这些动作。让我们看一个如何使用关键字 **action** 的示例。

```
action(a_issueRequest, "a", desc="Issue a request") {
   enqueue(requestNetwork_out, RequestMsg, latency=issue_latency) {
   out_msg.Address := address;
     out_msg.Type := CoherenceRequestType:GETX;
     out_msg.Requestor := machineID;
     out_msg.Destination.add(map_Address_to_Directory(address));
     out_msg.MessageSize := MessageSizeType:Control;
   }
}
```

第一个输入参数是动作的名称，下一个参数是用于生成文档的缩写，最后一个是动作的描述，用于 HTML 文档和 C++ 代码中的注释。

每个动作都被转换为具有该名称的 C++ 函数。生成的 C++ 代码在函数头中隐式包含最多三个输入参数，这再次取决于机器。这些参数是正在执行动作的内存地址、与此地址相关的缓存和事务缓冲区条目。

接下来要看的有用内容是 **enqueue** 关键字。此关键字用于将作为动作结果生成的消息排队到输出端口。关键字接受三个输入参数，即输出端口的名称、要排队的消息类型以及可以出队此消息的延迟。请注意，如果启用了随机化，则忽略指定的延迟。使用关键字会隐式声明一个变量 out_msg，该变量由后续语句填充。

#### 转换

转换函数是从状态集和事件集的叉积到状态集的映射。SLICC 提供了关键字 **transition** 来指定状态机的转换函数。以下是一个示例 --

```
transition(IM, Data, M) {
   u_writeDataToCache;
   sx_store_hit;
   w_deallocateTBE;
   n_popResponseQueue;
}
```

在此示例中，初始状态是 *IM*。如果在该状态下发生类型为 *Data* 的事件，则最终状态将是 *M*。在进行转换之前，状态机可以对其维护的结构执行某些动作。在给定的示例中，*u_writeDataToCache* 是一个动作。所有这些操作都以原子方式执行，即在与转换指定的动作集完成之前，不能发生其他事件。

为便于使用，可以将事件集和状态集作为输入提供给转换。这些集的叉积将映射到相同的最终状态。请注意，最终状态不能是集合。如果对于特定事件，最终状态与初始状态相同，则可以省略最终状态。

```
transition({IS, IM, MI, II}, {Load, Ifetch, Store, Replacement}) {
   z_stall;
}
```

### 特殊函数

#### 阻塞/回收/等待输入端口

SLICC 和生成的状态机的一个更复杂的内部特性是如何处理由于缓存块处于瞬态而无法处理事件的情况。有几种可能的方法来处理这种情况，每种解决方案都有不同的权衡。本小节试图解释这些差异。如需进一步跟进，请发送电子邮件至 gem5-user 列表。

##### 阻塞输入端口

处理无法处理的事件的最简单方法是简单地阻塞输入端口。正确的方法是在转换语句中包含 "z_stall" 动作：

```
transition({IS, IM, MI, II}, {Load, Ifetch, Store, Replacement}) {
   z_stall;
}
```

在内部，SLICC 将为此转换返回 ProtocolStall，并且在处理被阻塞的消息之前，不会处理来自关联输入端口的后续消息。但是，将分析其他输入端口以查找就绪消息并并行处理。虽然这是一个相对简单的解决方案，但可能会注意到，在同一输入端口上阻塞不相关的消息将导致过度和不必要的阻塞。

需要注意的一件事是**不要**将转换语句留空，如下所示：

```
transition({IS, IM, MI, II}, {Load, Ifetch, Store, Replacement}) {
   // 通过简单地不弹出消息来阻塞输入端口
}
```

这将导致 SLICC 为此转换返回成功，并且 SLICC 将继续重复分析同一输入端口。结果是最终死锁。

##### 回收输入端口

性能更好但更不现实的解决方案是回收输入端口上被阻塞的消息。这样做的方法是使用 "zz_recycleMandatoryQueue" 动作：

```
action(zz_recycleMandatoryQueue, "\z", desc="Send the head of the mandatory queue to the back of the queue.") {
   mandatoryQueue_in.recycle();
}
```
```
transition({IS, IM, MI, II}, {Load, Ifetch, Store, Replacement}) {
   zz_recycleMandatoryQueue;
}
```

此动作的结果是转换返回 Protocol Stall，并且违规消息移动到 FIFO 输入端口的后面。因此，可以处理同一输入端口上的其他不相关消息。此解决方案的问题是，回收的消息可能会在每个周期中被分析和重新分析，直到地址改变状态。

##### 阻塞并等待输入端口

更好但更复杂的解决方案是"阻塞并等待"违规的输入消息。这样做的方法是使用 "z_stallAndWaitMandatoryQueue" 动作：

```
action(z_stallAndWaitMandatoryQueue, "\z", desc="recycle L1 request queue") {
   stall_and_wait(mandatoryQueue_in, address);
}
```
```
transition({IS, IM, IS_I, M_I, SM, SINK_WB_ACK}, {Load, Ifetch, Store, L1_Replacement}) {
   z_stallAndWaitMandatoryQueue;
}
```

此动作的结果是转换返回成功，这是可以的，因为 stall_and_wait 将违规消息移出输入端口并移到与输入端口关联的侧表中。消息在被唤醒之前不会再次被分析。同时，将处理其他不相关的消息。

阻塞和等待的复杂部分是，被阻塞的消息必须由其他消息/转换显式唤醒。特别是，将地址移动到基本状态的转换应该唤醒可能正在等待该地址的被阻塞消息：

```
action(kd_wakeUpDependents, "kd", desc="wake-up dependents") {
   wakeUpBuffers(address);
}
```

```
transition(M_I, WB_Ack, I) {
   s_deallocateTBE;
   o_popIncomingResponseQueue;
   kd_wakeUpDependents;
}
```

替换特别复杂，因为被阻塞的地址与它们实际等待更改的地址不关联。在这些情况下，必须唤醒所有等待的消息：

```
action(ka_wakeUpAllDependents, "ka", desc="wake-up all dependents") {
   wakeUpAllBuffers();
}
```

```
transition(I, L2_Replacement) {
   rr_deallocateL2CacheBlock;
   ka_wakeUpAllDependents;
}
```

### 其他编译器功能

- SLICC 支持 **if** 和 **else** 形式的条件语句。请注意，SLICC 不支持 **else if**。

- 每个函数都有一个返回类型，也可以是 void。不能忽略返回值。

- SLICC 对指针变量的支持有限。支持 is_valid() 和 is_invalid() 操作来测试给定指针是否"不是 NULL"和"是 NULL"。关键字 **OOD**（代表 Out of Domain）扮演 C++ 中使用的关键字 NULL 的角色。

- SLICC 不支持 **\!**（非运算符）。

- SLICC 支持静态类型转换。为此目的提供了关键字 **static_cast**。例如，在以下代码片段中，类型为 AbstractCacheEntry 的变量被转换为类型为 Entry 的变量。

```
   Entry L1Dcache_entry := static_cast(Entry, "pointer", L1DcacheMemory[addr]);
```

### SLICC 内部

**C++ 到 Slicc 接口 - @note：这些文件各自做什么/定义什么？？？**

- src/mem/protocol/RubySlicc_interaces.sm
    - RubySlicc_Exports.sm
    - RubySlicc_Defines.sm
    - RubySlicc_Profiler.sm
    - RubySlicc_Types.sm
    - RubySlicc_MemControl.sm
    - RubySlicc_ComponentMapping.sm

**变量赋值**

- 使用 `:=` 运算符在类中分配成员（例如，在 RubySlicc_Types.sm 中定义的成员）：
    - 在 SLICC 文件中提到的名称会自动添加 `m_`。
