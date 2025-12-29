---
layout: documentation
title: 声明状态机
doc: Learning gem5
parent: part3
permalink: /documentation/learning_gem5/part3/cache-declarations/
author: Jason Lowe-Power
---


让我们开始编写第一个状态机文件！首先，我们将为我们的 MSI 协议创建 L1 缓存控制器。

创建一个名为 `MSI-cache.sm` 的文件，以下代码声明了状态机。

```cpp
machine(MachineType:L1Cache, "MSI cache")
    : <parameters>
{
    <All state machine code>
}
```

关于状态机代码，您会注意到的第一件事是它看起来非常像 C++。状态机文件就像在头文件中创建 C++ 对象一样，如果你在那里也包含所有代码的话。
如果有疑问，C++ 语法 *可能* 在 SLICC 中有效。但是，在许多情况下 C++ 语法对于 SLICC 是不正确的语法，以及 SLICC 扩展语法的情况。

通过 `MachineType:L1Cache`，我们将此状态机命名为 `L1Cache`。
SLICC 将使用该名称为我们从状态机生成许多不同的对象。例如，一旦编译此文件，将有一个新的 SimObject：`L1Cache_Controller`，它是缓存控制器。此声明中还包括此状态机的描述："MSI cache"。

SLICC 中有许多情况，您必须包含描述以配合变量。这样做的原因是 SLICC 最初设计用于仅描述，而不是实现一致性协议。今天，这些额外的描述有两个目的。首先，它们充当关于作者意图将每个变量、状态或事件用于什么的注释。其次，在为 SLICC 协议构建 HTML 表时，其中许多仍导出为 HTML。因此，在浏览 HTML 表格时，您可以查看协议作者的更详细评论。清楚地描述这些很重要，因为一致性协议可能会变得非常复杂。

## 状态机参数

在 `machine()` 声明之后是一个冒号，之后声明了状态机的所有参数。这些参数直接导出到由状态机生成的 SimObject。

对于我们的 MSI L1 缓存，我们有以下参数：

```cpp
machine(MachineType:L1Cache, "MSI cache")
: Sequencer *sequencer;
  CacheMemory *cacheMemory;
  bool send_evictions;

  <Message buffer declarations>

  {

  }
```

首先，我们有一个 `Sequencer`。这是一个在 Ruby 中实现的特殊类，用于与 gem5 的其余部分接口。Sequencer 是一个 gem5 `MemObject`，带有一个从属端口，因此它可以接受来自其他对象的内存请求。定序器接受来自 CPU（或其他主端口）的请求并将 gem5 数据包转换为 `RubyRequest`。最后，`RubyRequest` 被推送到状态机的 `mandatoryQueue` 上。我们将在 [输入端口部分](../cache-in-ports) 重新访问 `mandatoryQueue`。

接下来，有一个 `CacheMemory` 对象。这是保存缓存数据（即缓存条目）的内容。确切的实现、大小等可在运行时配置。

最后，我们可以指定我们想要的任何其他参数，类似于通用的 `SimObject`。在这种情况下，我们有一个布尔变量 `send_evictions`。这用于乱序核心模型，如果加载后地址被驱逐，则通知加载存储队列，以便在推测性加载时压缩加载。

接下来，同样在参数块中（即，在第一个左括号之前），我们需要声明此状态机将使用的所有消息缓冲区。消息缓冲区是状态机和 Ruby 网络之间的接口。消息通过消息缓冲区发送和接收。因此，对于我们协议中的每个虚拟通道，我们需要一个单独的消息缓冲区。

MSI 协议需要三个不同的虚拟网络。需要虚拟网络来防止死锁（例如，如果响应卡在停止的请求后面是很糟糕的）。在此协议中，最高优先级是响应（虚拟网络 2），其次是转发请求（虚拟网络 1），然后请求具有最低优先级（虚拟网络 0）。有关为什么需要这三个虚拟网络的详细信息，请参见 Sorin 等人。

以下代码声明了所有需要的消息缓冲区。

```cpp
machine(MachineType:L1Cache, "MSI cache")
: Sequencer *sequencer;
  CacheMemory *cacheMemory;
  bool send_evictions;

  MessageBuffer * requestToDir, network="To", virtual_network="0", vnet_type="request";
  MessageBuffer * responseToDirOrSibling, network="To", virtual_network="2", vnet_type="response";

  MessageBuffer * forwardFromDir, network="From", virtual_network="1", vnet_type="forward";
  MessageBuffer * responseFromDirOrSibling, network="From", virtual_network="2", vnet_type="response";

  MessageBuffer * mandatoryQueue;

{

}
```

我们要五个不同的消息缓冲区：两个 "To"，两个 "From" 和一个特殊消息缓冲区。"To" 消息缓冲区类似于 gem5 中的主端口。这些是此控制器用于向系统中其他控制器发送消息的消息缓冲区。"From" 消息缓冲区就像从端口。此控制器从系统中的其他控制器接收 "From" 缓冲区上的消息。

我们要两个不同的 "To" 缓冲区，一个用于低优先级请求，一个用于高优先级响应。网络的优先级不是固有的。优先级基于其他控制器查看消息缓冲区的顺序。对虚拟网络进行编号以便较高的数字意味着较高的优先级是一个好主意，但 Ruby 忽略虚拟网络编号，除了网络 2 上的消息只能去往网络 2 上的其他消息缓冲区（即，消息不能从一个网络跳到另一个网络）。

同样，此缓存有两种不同的接收消息方式，或者是来自目录的转发请求（例如，另一个缓存请求可写块而我们有可读副本），或者是对该控制器发出的请求的响应。响应的优先级高于转发请求。

最后，有一个特殊的消息缓冲区，`mandatoryQueue`。此消息缓冲区由 `Sequencer` 用于将 gem5 数据包转换为 Ruby 请求。与其他消息缓冲区不同，`mandatoryQueue` 不连接到 Ruby 网络。注意：此消息缓冲区的名称是硬编码的，必须正好是 "mandatoryQueue"。

如前所述，此参数块将转换为 SimObject 描述文件。您在此块中放入的任何参数都将是可从 Python 配置文件访问的 SimObject 参数。如果您查看生成的 L1Cache\_Controller.py，它看起来会非常熟悉。注意：这是一个生成的文件，您绝不应该直接修改生成的文件！

```python
from m5.params import *
from m5.SimObject import SimObject
from Controller import RubyController

class L1Cache_Controller(RubyController):
    type = 'L1Cache_Controller'
    cxx_header = 'mem/protocol/L1Cache_Controller.hh'
    sequencer = Param.RubySequencer("")
    cacheMemory = Param.RubyCache("")
    send_evictions = Param.Bool("")
    requestToDir = Param.MessageBuffer("")
    responseToDirOrSibling = Param.MessageBuffer("")
    forwardFromDir = Param.MessageBuffer("")
    responseFromDirOrSibling = Param.MessageBuffer("")
    mandatoryQueue = Param.MessageBuffer("")
```

## 状态声明

状态机的下一部分是状态声明。在这里，我们将声明状态机的所有稳定状态和瞬态。我们将遵循 Sorin 等人的命名约定。例如，瞬态 "IM\_AD" 对应于从无效移动到修改，等待 acks 和数据。这些状态直接来自 Sorin 等人表 8.3 的左列。

```cpp
state_declaration(State, desc="Cache states") {
    I,      AccessPermission:Invalid,
                desc="Not present/Invalid";

    // States moving out of I
    IS_D,   AccessPermission:Invalid,
                desc="Invalid, moving to S, waiting for data";
    IM_AD,  AccessPermission:Invalid,
                desc="Invalid, moving to M, waiting for acks and data";
    IM_A,   AccessPermission:Busy,
                desc="Invalid, moving to M, waiting for acks";

    S,      AccessPermission:Read_Only,
                desc="Shared. Read-only, other caches may have the block";

    // States moving out of S
    SM_AD,  AccessPermission:Read_Only,
                desc="Shared, moving to M, waiting for acks and 'data'";
    SM_A,   AccessPermission:Read_Only,
                desc="Shared, moving to M, waiting for acks";

    M,      AccessPermission:Read_Write,
                desc="Modified. Read & write permissions. Owner of block";

    // States moving to Invalid
    MI_A,   AccessPermission:Busy,
                desc="Was modified, moving to I, waiting for put ack";
    SI_A,   AccessPermission:Busy,
                desc="Was shared, moving to I, waiting for put ack";
    II_A,   AccessPermission:Invalid,
                desc="Sent valid data before receiving put ack. "Waiting for put ack.";
}
```

每个状态都有一个关联的访问权限："Invalid", "NotPresent", "Busy", "Read\_Only", 或 "Read\_Write"。访问权限用于对缓存的 *functional* 访问。Functional 访问是类似调试的访问，当模拟器想要立即读取或更新数据时。这方面的一个例子是在 SE 模式下读取文件，这些文件直接加载到内存中。

对于 functional 访问，检查所有缓存以查看它们是否具有匹配地址的相应块。对于 functional 读取，访问 *所有* 具有匹配地址且具有只读或读写权限的块（它们应该都具有相同的数据）。对于 functional 写入，如果所有具有繁忙、只读或读写权限的块，都会用新数据更新。

## 事件声明

接下来，我们需要声明此缓存控制器由传入消息触发的所有事件。这些事件直接来自 Sorin 等人表 8.3 的第一行。

```cpp
enumeration(Event, desc="Cache events") {
    // From the processor/sequencer/mandatory queue
    Load,           desc="Load from processor";
    Store,          desc="Store from processor";

    // Internal event (only triggered from processor requests)
    Replacement,    desc="Triggered when block is chosen as victim";

    // Forwarded request from other cache via dir on the forward network
    FwdGetS,        desc="Directory sent us a request to satisfy GetS. We must have the block in M to respond to this.";
    FwdGetM,        desc="Directory sent us a request to satisfy GetM. We must have the block in M to respond to this.";
    Inv,            desc="Invalidate from the directory.";
    PutAck,         desc="Response from directory after we issue a put. This must be on the fwd network to avoid deadlock.";

    // Responses from directory
    DataDirNoAcks,  desc="Data from directory (acks = 0)";
    DataDirAcks,    desc="Data from directory (acks > 0)";

    // Responses from other caches
    DataOwner,      desc="Data from owner";
    InvAck,         desc="Invalidation ack from other cache after Inv";

    // Special event to simplify implementation
    LastInvAck,     desc="Triggered after the last ack is received";
}
```

## 用户定义的结构

接下来，我们需要定义一些我们将在该控制器的其他地方使用的结构。我们要定义的第一个是 `Entry`。这是存储在 `CacheMemory` 中的结构。它只需要包含数据和状态，但也可以包含您想要的任何其他数据。注意：此结构存储的状态是上面定义的 `State` 类型，而不是硬编码的状态类型。

您可以在 `src/mem/ruby/slicc_interface/AbstractCacheEntry.hh` 中找到此类的抽象版本 (`AbstractCacheEntry`)。如果你想使用 `AbstractCacheEntry` 的任何成员函数，你需要在这里声明它们（此协议中未使用）。

```cpp
structure(Entry, desc="Cache entry", interface="AbstractCacheEntry") {
    State CacheState,        desc="cache state";
    DataBlock DataBlk,       desc="Data in the block";
}
```

我们需要另一个结构是 TBE。TBE 是“事务缓冲区条目 (transaction buffer entry)”。这存储瞬态期间所需的信息。这 *就像* 一个 MSHR。在此协议中，它充当 MSHR，但也为其他用途分配条目。在此协议中，它将存储状态（通常需要）、数据（通常也需要）以及此块当前正在等待的 ack 数。`AcksOutstanding` 用于其他控制器发送 ack 而不是数据时的转换。

```cpp
structure(TBE, desc="Entry for transient requests") {
    State TBEState,         desc="State of block";
    DataBlock DataBlk,      desc="Data for the block. Needed for MI_A";
    int AcksOutstanding, default=0, desc="Number of acks left to receive.";
}
```

接下来，我们需要一个地方来存储所有的 TBE。这是一个外部定义的类；它是在 SLICC 之外的 C++ 中定义的。因此，我们需要声明我们将使用它，并且还需要声明我们将调用的任何函数。您可以在 src/mem/ruby/structures/TBETable.hh 中找到 `TBETable` 的代码。它是在上面定义的 TBE 结构上模板化的，这会让人有点困惑，正如我们将看到的那样。

```cpp
structure(TBETable, external="yes") {
  TBE lookup(Addr);
  void allocate(Addr);
  void deallocate(Addr);
  bool isPresent(Addr);
}
```

`external="yes"` 告诉 SLICC 不要查找此结构的定义。这类似于在 C/C++ 中声明变量 `extern`。

## 其他所需的声明和定义

最后，我们将通过一些样板代码来声明变量，声明我们将在该控制器中使用的 `AbstractController` 中的函数，并在 `AbstractController` 中定义抽象函数。

首先，我们需要有一个存储 TBE 表的变量。我们必须在 SLICC 中这样做，因为直到这个时候我们才知道 TBE 表的真实类型，因为 TBE 类型是在上面定义的。这是让 SLICC 生成正确的 C++ 代码的一些特别棘手（或讨厌）的代码。困难在于我们要基于上面的 `TBE` 类型模板化 `TBETable`。关键是 SLICC 用机器名称破坏机器中声明的所有类型的名称。例如，`TBE` 实际上是 C++ 中的 L1Cache\_TBE。

我们还要将参数传递给 `TBETable` 的构造函数。这是一个实际上属于 `AbstractController` 的参数，因此我们需要使用变量的 C++ 名称，因为它没有 SLICC 名称。

```cpp
TBETable TBEs, template="<L1Cache_TBE>", constructor="m_number_of_TBEs";
```

如果您能理解上面的代码，那么您就是官方的 SLICC 忍者！

接下来，如果我们在文件的其余部分使用 `AbstractController` 中的任何函数，则需要声明这些函数。在这种情况下，我们只使用 `clockEdge()`：

```cpp
Tick clockEdge();
```

我们在动作中还要使用一些其他函数。这些函数用于在动作中设置和取消设置动作代码块中可用的隐式变量。动作代码块将在动作部分 \<MSI-actions-section\> 中详细解释。当转换有许多动作时，可能需要这些。

```cpp
void set_cache_entry(AbstractCacheEntry a);
void unset_cache_entry();
void set_tbe(TBE b);
void unset_tbe();
```

另一个有用的函数是 `mapAddressToMachine`。这允许我们在运行时更改存储目录或缓存的地址映射，这样我们就不必在 SLICC 文件中对其进行硬编码。

```cpp
MachineID mapAddressToMachine(Addr addr, MachineType mtype);
```

最后，您还可以添加您可能想要在文件中使用的任何函数并在此处实现它们。例如，使用单个函数通过地址访问缓存块很方便。同样，在这个函数中有一些 SLICC 技巧。我们需要“通过指针”访问，因为缓存块是我们稍后需要可变的东西（“通过引用”会是一个更好的名称）。强制转换也是必要的，因为我们在文件中定义了特定的 `Entry` 类型，但 `CacheMemory` 保存的是抽象类型。

```cpp
// 查找缓存条目的便利函数。
// 需要指针，以便它是引用并且可以在动作中更新
Entry getCacheEntry(Addr address), return_by_pointer="yes" {
    return static_cast(Entry, "pointer", cacheMemory.lookup(address));
}
```

下一组样板代码很少在不同的协议之间改变。我们必须实现 `AbstractController` 中有一组纯虚函数。

`getState`
:   给定 TBE、缓存条目和地址返回块的状态。这在块上调用以决定当触发事件时执行哪个转换。通常，您返回 TBE 或缓存条目中的状态，无论哪个有效。

`setState`
:   给定 TBE、缓存条目和地址确保在块上正确设置状态。这在转换结束时调用以在块上设置最终状态。

`getAccessPermission`
:   获取块的访问权限。这在 functional 访问期间用于决定是否在功能上访问该块。它类似于 `getState`，如果有效则从 TBE 获取信息，如果有效则从缓存条目获取，或者该块不存在。

`setAccessPermission`
:   像 `getAccessPermission`，但设置权限。

`functionalRead`
:   功能性地读取数据。TBE 可能有更最新的信息，所以先检查一下。注意：testAndRead/Write 定义在 src/mem/ruby/slicc\_interface/Util.hh

`functionalWrite`
:   功能性地写入数据。同样，您可能需要更新 TBE 和缓存条目中的数据。

```cpp
State getState(TBE tbe, Entry cache_entry, Addr addr) {
    // TBE 状态将覆盖缓存内存中的状态，如果有效
    if (is_valid(tbe)) { return tbe.TBEState; }
    // 接下来，如果缓存条目有效，它保存状态
    else if (is_valid(cache_entry)) { return cache_entry.CacheState; }
    // 如果块不存在，则其状态必须为 I。
    else { return State:I; }
}

void setState(TBE tbe, Entry cache_entry, Addr addr, State state) {
  if (is_valid(tbe)) { tbe.TBEState := state; }
  if (is_valid(cache_entry)) { cache_entry.CacheState := state; }
}

AccessPermission getAccessPermission(Addr addr) {
    TBE tbe := TBEs[addr];
    if(is_valid(tbe)) {
        return L1Cache_State_to_permission(tbe.TBEState);
    }

    Entry cache_entry := getCacheEntry(addr);
    if(is_valid(cache_entry)) {
        return L1Cache_State_to_permission(cache_entry.CacheState);
    }

    return AccessPermission:NotPresent;
}

void setAccessPermission(Entry cache_entry, Addr addr, State state) {
    if (is_valid(cache_entry)) {
        cache_entry.changePermission(L1Cache_State_to_permission(state));
    }
}

void functionalRead(Addr addr, Packet *pkt) {
    TBE tbe := TBEs[addr];
    if(is_valid(tbe)) {
        testAndRead(addr, tbe.DataBlk, pkt);
    } else {
        testAndRead(addr, getCacheEntry(addr).DataBlk, pkt);
    }
}

int functionalWrite(Addr addr, Packet *pkt) {
    int num_functional_writes := 0;

    TBE tbe := TBEs[addr];
    if(is_valid(tbe)) {
        num_functional_writes := num_functional_writes +
            testAndWrite(addr, tbe.DataBlk, pkt);
        return num_functional_writes;
    }

    num_functional_writes := num_functional_writes +
            testAndWrite(addr, getCacheEntry(addr).DataBlk, pkt);
    return num_functional_writes;
}
```
