---
layout: documentation
title: 在内存系统中创建 SimObject
doc: Learning gem5
parent: part2
permalink: /documentation/learning_gem5/part2/memoryobject/
author: Jason Lowe-Power
---


在内存系统中创建 SimObject
========================================

在本章中，我们将创建一个简单的内存对象，它位于 CPU 和内存总线之间。在 [下一章](../simplecache) 中，我们将采用这个简单的内存对象并向其添加一些逻辑，使其成为一个非常简单的阻塞式单处理器缓存。

gem5 请求和响应端口
---------------------------

在深入研究内存对象的实现之前，我们应该首先了解 gem5 的请求和响应端口接口。如 [simple-config-chapter](../../part1/simple_config) 中先前讨论的那样，所有内存对象都通过端口连接在一起。这些端口在这些内存对象之间提供了严格的接口。

这些端口实现了三种不同的内存系统 *模式*：timing、atomic 和 functional。最重要的模式是 *timing 模式*。Timing 模式是唯一产生正确模拟结果的模式。其他模式仅在特殊情况下使用。

*Atomic 模式* 对于将模拟快进到感兴趣的区域和预热模拟器非常有用。此模式假设在内存系统中不会生成任何事件。相反，所有内存请求都通过单个长调用链执行。除非内存对象将在快进期间或模拟器预热期间使用，否则不需要实现原子访问。

*Functional 模式* 最好描述为 *调试模式*。Functional 模式用于诸如将数据从主机读取到模拟器内存中之类的事情。它在系统调用仿真模式中被大量使用。例如，functional 模式用于将 `process.cmd` 中的二进制文件从主机加载到模拟系统的内存中，以便模拟系统可以访问它。Functional 访问应在读取时返回最新数据，无论数据在哪里，并且应在写入时更新所有可能的有效数据（例如，在具有缓存的系统中，可能存在多个具有相同地址的有效缓存块）。

### 包 (Packets)

在 gem5 中，`Packets` 通过端口发送。`Packet` 由 `MemReq`（内存请求对象）组成。`MemReq` 保存有关发起数据包的原始请求的信息，例如请求者、地址和请求类型（读取、写入等）。

Packets 还有一个 `MemCmd`，它是数据包的 *当前* 命令。此命令可以在数据包的生命周期内更改（例如，一旦满足内存命令，请求就会变成响应）。最常见的 `MemCmd` 是 `ReadReq`（读请求）、`ReadResp`（读响应）、`WriteReq`（写请求）、`WriteResp`（写响应）。还有用于缓存的写回请求 (`WritebackDirty`, `WritebackClean`) 和许多其他命令类型。

Packets 也可以保存请求的数据，或指向数据的指针。在创建数据包时有选项决定数据是动态的（显式分配和释放），还是静态的（由数据包对象分配和释放）。

最后，packets 在经典缓存中用作跟踪一致性的单位。因此，大部分 packet 代码特定于经典缓存一致性协议。但是，packets 用于 gem5 中内存对象之间的所有通信，即使它们不直接参与一致性（例如，DRAM 控制器和 CPU 模型）。

所有端口接口函数都接受一个 `Packet` 指针作为参数。由于此指针非常常见，gem5 包含了一个 typedef：`PacketPtr`。

### 端口接口

gem5 中有两种类型的端口：请求端口 (request ports) 和响应端口 (response ports)。
每当您实现一个内存对象时，您将实现至少一种类型的端口。为此，您创建一个新类，分别继承自 `RequestPort` 或 `ResponsePort`。请求端口发送请求（并接收响应），响应端口接收请求（并发送响应）。

下图概述了请求端口和响应端口之间最简单的交互。此图显示了 timing 模式下的交互。其他模式要简单得多，并且在请求者和响应者之间使用简单的调用链。

![请求者和响应者都可以接受请求和响应时的简单请求-响应交互。](/_pages/static/figures/requestor_responder_1.png)

如上所述，所有端口接口都需要一个 `PacketPtr` 作为参数。每个这些函数 (`sendTimingReq`, `recvTimingReq` 等) 接受单个参数，即 `PacketPtr`。此数据包是要发送或接收的请求或响应。

要发送请求数据包，请求者调用 `sendTimingReq`。反过来（并且在同一个调用链中），响应者上会调用 `recvTimingReq` 函数，并将相同的 `PacketPtr` 作为其唯一参数。

`recvTimingReq` 的返回类型为 `bool`。此布尔返回值直接返回给调用的请求者。返回值 `true` 表示数据包已被响应者接受。另一方面，返回值 `false` 意味着响应者无法接受，并且必须在将来的某个时间重试请求。

在上图中，首先，请求者通过调用 `sendTimingReq` 发送时序请求，该函数反过来调用 `recvTimingReq`。响应者从 `recvTimingReq` 返回 true，该值从 `sendTimingReq` 调用中返回。请求者继续执行，响应者执行完成请求所需的任何操作（例如，如果是缓存，它会查找标签以查看是否与请求中的地址匹配）。

一旦响应者完成了请求，它可以向请求者发送响应。响应者调用带有响应数据包的 `sendTimingResp`（这应该与请求是同一个 `PacketPtr`，但它现在应该是一个响应数据包）。反过来，调用请求函数 `recvTimingResp`。请求者的 `recvTimingResp` 函数返回 `true`，这是响应者中 `sendTimingResp` 的返回值。因此，该请求的交互完成。

稍后，在示例部分，我们将展示这些函数的示例代码。

当请求者或响应者收到请求或响应时，它们可能正忙。下图显示了发送原始请求时响应者正忙的情况。

![当响应者忙碌时的简单请求者-响应者交互](/_pages/static/figures/requestor_responder_2.png)

在这种情况下，响应者从 `recvTimingReq` 函数返回 `false`。当请求者在调用 `sendTimingReq` 后收到 false 时，它必须等待直到其函数 `recvReqRetry` 被执行。只有当此函数被调用时，请求者才允许重试调用 `sendTimingRequest`。上图显示了时序请求失败一次，但它可能会失败任意次。注意：由请求者负责跟踪失败的数据包，而不是响应者。响应者 *不* 保留指向失败数据包的指针。

同样，下图显示了当响应者尝试发送响应时请求者正忙的情况。在这种情况下，响应者在收到 `recvRespRetry` 之前无法调用 `sendTimingResp`。

![当请求者忙碌时的简单请求者-响应者交互](/_pages/static/figures/requestor_responder_3.png)

重要的是，在这两种情况下，重试代码路径可以是单个调用堆栈。例如，当请求者调用 `sendRespRetry` 时，`recvTimingReq`也可以在同一个调用堆栈中被调用。因此，很容易错误地创建无限递归错误或其他错误。重要的是，在内存对象发送重试之前，它 *在那一瞬间* 准备好接受另一个数据包。

简单的内存对象示例
----------------------------

在本节中，我们将构建一个简单的内存对象。最初，它将简单地将请求从 CPU 侧（一个简单的 CPU）传递到内存侧（一个简单的内存总线）。见下图。
它将有一个内存侧请求者端口，用于向内存总线发送请求，以及两个 CPU 侧端口，用于 CPU 的指令和数据缓存端口。在下一章 [simplecache-chapter](../simplecache) 中，我们将添加逻辑使此对象成为缓存。

![具有位于 CPU 和内存总线之间的简单内存对象的系统。](/pages/static/figures/simple_memobj.png)

### 声明 SimObject

就像我们在 [hello-simobject-chapter](../helloobject) 中创建简单的 SimObject 一样，第一步是创建 SimObject Python 文件。我们将这个简单的内存对象称为 `SimpleMemobj`，并在 `src/learning_gem5/simple_memobj` 中创建 SimObject Python 文件。

```python
from m5.params import *
from m5.proxy import *
from m5.SimObject import SimObject

class SimpleMemobj(SimObject):
    type = 'SimpleMemobj'
    cxx_header = "learning_gem5/part2/simple_memobj.hh"

    inst_port = ResponsePort("CPU side port, receives requests")
    data_port = ResponsePort("CPU side port, receives requests")
    mem_side = RequestPort("Memory side port, sends requests")
```

对于此对象，我们继承自 `SimObject`。`SimObject` 类有一个纯虚函数，我们必须在 C++ 实现中定义它，即 `getPort`。

此对象的参数是三个端口。两个端口供 CPU 连接指令和数据端口，一个端口连接到内存总线。这些端口没有默认值，并且它们有一个简单的描述。

记住这些端口的名称很重要。在实现 `SimpleMemobj` 和定义 `getPort` 函数时，我们将显式使用这些名称。

您可以下载 SimObject 文件
[这里](/_pages/static/scripts/part2/memoryobject/SimpleMemobj.py)。

当然，您还需要在新目录中创建一个 SConscript 文件，该文件声明 SimObject Python 文件。您可以下载 SConscript 文件
[这里](/_pages/static/scripts/part2/memoryobject/SConscript)。

### 定义 SimpleMemobj 类

现在，我们为 `SimpleMemobj` 创建一个头文件。

```cpp
#include "mem/port.hh"
#include "params/SimpleMemobj.hh"
#include "sim/sim_object.hh"

class SimpleMemobj : public SimObject
{
  private:

  public:

    /** constructor
     */
    SimpleMemobj(SimpleMemobjParams *params);
};
```

### 定义响应端口类型

现在，我们需要为我们的两种端口定义类：CPU 侧和内存侧端口。为此，我们将在 `SimpleMemobj` 类内部声明这些类，因为没有其他对象会使用这些类。

让我们从响应端口（即 CPU 侧端口）开始。我们将继承 `ResponsePort` 类。以下是覆盖 `ResponsePort` 类中所有纯虚函数所需的代码。

```cpp
class CPUSidePort : public ResponsePort
{
  private:
    SimpleMemobj *owner;

  public:
    CPUSidePort(const std::string& name, SimpleMemobj *owner) :
        ResponsePort(name, owner), owner(owner)
    { }

    AddrRangeList getAddrRanges() const override;

  protected:
    Tick recvAtomic(PacketPtr pkt) override { panic("recvAtomic unimpl."); }
    void recvFunctional(PacketPtr pkt) override;
    bool recvTimingReq(PacketPtr pkt) override;
    void recvRespRetry() override;
};
```

此对象需要定义五个函数。

此对象还有一个成员变量，即其所有者，因此它可以调用该对象上的函数。

### 定义请求端口类型

接下来，我们需要定义一个请求端口类型。这将是内存侧端口，它将请求从 CPU 侧转发到内存系统的其余部分。

```cpp
class MemSidePort : public RequestPort
{
  private:
    SimpleMemobj *owner;

  public:
    MemSidePort(const std::string& name, SimpleMemobj *owner) :
        RequestPort(name, owner), owner(owner)
    { }

  protected:
    bool recvTimingResp(PacketPtr pkt) override;
    void recvReqRetry() override;
    void recvRangeChange() override;
};
```

此类只有三个我们必须覆盖的纯虚函数。

### 定义 SimObject 接口

现在我们已经定义了这两个新类型 `CPUSidePort` 和 `MemSidePort`，我们可以将我们的三个端口声明为 `SimpleMemobj` 的一部分。我们还需要在 `SimObject` 类中声明纯虚函数 `getPort`。该函数在初始化阶段由 gem5 使用，通过端口将内存对象连接在一起。

```cpp
class SimpleMemobj : public SimObject
{
  private:

    <CPUSidePort declaration>
    <MemSidePort declaration>

    CPUSidePort instPort;
    CPUSidePort dataPort;

    MemSidePort memPort;

  public:
    SimpleMemobj(SimpleMemobjParams *params);

    Port &getPort(const std::string &if_name,
                  PortID idx=InvalidPortID) override;
};
```

您可以下载 `SimpleMemobj` 的头文件
[这里](/_pages/static/scripts/part2/memoryobject/simple_memobj.hh)。

### 实现基本 SimObject 函数

对于 `SimpleMemobj` 的构造函数，我们将简单地调用 `SimObject` 构造函数。我们还需要初始化所有端口。每个端口的构造函数接受两个参数：名称和指向其所有者的指针，正如我们在头文件中定义的那样。名称可以是任何字符串，但按照惯例，它是 Python SimObject 文件中的相同名称。我们还将 blocked 初始化为 false。

```cpp
#include "learning_gem5/part2/simple_memobj.hh"
#include "debug/SimpleMemobj.hh"

SimpleMemobj::SimpleMemobj(SimpleMemobjParams *params) :
    SimObject(params),
    instPort(params->name + ".inst_port", this),
    dataPort(params->name + ".data_port", this),
    memPort(params->name + ".mem_side", this), blocked(false)
{
}
```

接下来，我们需要实现获取端口的接口。该接口由函数 `getPort` 组成。
该函数接受两个参数。`if_name` 是 *此* 对象接口的 Python 变量名。

为了实现 `getPort`，我们比较 `if_name` 并检查它是否如我们的 Python SimObject 文件中所指定的那样为 `mem_side`。如果是，则返回 `memPort` 对象。如果名称是 `"inst_port"`，则返回 instPort，如果名称是 `data_port`，则返回 data port。如果不是，则将请求名称传递给我们的父级。

```cpp
Port &
SimpleMemobj::getPort(const std::string &if_name, PortID idx)
{
    panic_if(idx != InvalidPortID, "This object doesn't support vector ports");

    // 这是来自 Python SimObject 声明 (SimpleMemobj.py) 的名称
    if (if_name == "mem_side") {
        return memPort;
    } else if (if_name == "inst_port") {
        return instPort;
    } else if (if_name == "data_port") {
        return dataPort;
    } else {
        // 把它传递给我们的超类
        return SimObject::getPort(if_name, idx);
    }
}
```


### 实现请求和响应端口函数

请求和响应端口的实现都相对简单。在大多数情况下，每个端口函数只是将信息转发到主内存对象 (`SimpleMemobj`)。

从两个简单的函数开始，`getAddrRanges` 和 `recvFunctional` 只是调用 `SimpleMemobj`。

```cpp
AddrRangeList
SimpleMemobj::CPUSidePort::getAddrRanges() const
{
    return owner->getAddrRanges();
}

void
SimpleMemobj::CPUSidePort::recvFunctional(PacketPtr pkt)
{
    return owner->handleFunctional(pkt);
}
```

这些函数在 `SimpleMemobj` 中的实现同样简单。这些实现只是将请求传递给内存侧。我们也可以在这里使用 `DPRINTF` 调用来跟踪发生的事情以进行调试。

```cpp
void
SimpleMemobj::handleFunctional(PacketPtr pkt)
{
    memPort.sendFunctional(pkt);
}

AddrRangeList
SimpleMemobj::getAddrRanges() const
{
    DPRINTF(SimpleMemobj, "Sending new ranges\n");
    return memPort.getAddrRanges();
}
```

同样对于 `MemSidePort`，我们需要实现 `recvRangeChange` 并通过 `SimpleMemobj` 将请求转发到响应端口。

```cpp
void
SimpleMemobj::MemSidePort::recvRangeChange()
{
    owner->sendRangeChange();
}
```

```cpp
void
SimpleMemobj::sendRangeChange()
{
    instPort.sendRangeChange();
    dataPort.sendRangeChange();
}
```

### 实现接收请求

`recvTimingReq` 的实现稍微复杂一些。我们需要检查 `SimpleMemobj` 是否可以接受请求。`SimpleMemobj` 是一个非常简单的阻塞结构；我们一次只允许一个未完成的请求。因此，如果在另一个请求未完成时收到请求，`SimpleMemobj` 将阻止第二个请求。

为了简化实现，`CPUSidePort` 存储端口接口的所有流控制信息。因此，我们需要向 `CPUSidePort` 添加一个额外的成员变量 `needRetry`，这是一个布尔值，用于存储每当 `SimpleMemobj` 变为空闲时我们是否需要发送重试。然后，如果 `SimpleMemobj` 在请求上被阻止，我们设置我们需要在将来的某个时间发送重试。

```cpp
bool
SimpleMemobj::CPUSidePort::recvTimingReq(PacketPtr pkt)
{
    if (!owner->handleRequest(pkt)) {
        needRetry = true;
        return false;
    } else {
        return true;
    }
}
```

为了处理 `SimpleMemobj` 的请求，我们首先检查 `SimpleMemobj` 是否已经被阻止等待对另一个请求的响应。如果它被阻止，那么我们返回 `false` 以向调用请求端口发出信号，表明我们现在无法接受请求。否则，我们将端口标记为已阻止并从内存端口发送数据包。为此，我们可以在 `MemSidePort` 对象中定义一个辅助函数，以向 `SimpleMemobj` 实现隐藏流控制。我们将假设 `memPort` 处理所有流控制，并且始终从 `handleRequest` 返回 `true`，因为我们成功地使用了请求。

```cpp
bool
SimpleMemobj::handleRequest(PacketPtr pkt)
{
    if (blocked) {
        return false;
    }
    DPRINTF(SimpleMemobj, "Got request for addr %#x\n", pkt->getAddr());
    blocked = true;
    memPort.sendPacket(pkt);
    return true;
}
```

接下来，我们需要在 `MemSidePort` 中实现 `sendPacket` 函数。此函数将处理流控制，以防其对等响应端口无法接受请求。为此，我们需要向 `MemSidePort` 添加一个成员来存储数据包，以防它被阻止。如果接收者无法接收请求（或响应），发送者有责任存储数据包。

此函数只需调用函数 `sendTimingReq` 即可发送数据包。如果发送失败，则此对象将数据包存储在 `blockedPacket` 成员函数中，以便以后（当它收到 `recvReqRetry` 时）发送数据包。此函数还包含一些防御性代码，以确保没有错误，并且我们永远不会尝试错误地覆盖 `blockedPacket` 变量。

```cpp
void
SimpleMemobj::MemSidePort::sendPacket(PacketPtr pkt)
{
    panic_if(blockedPacket != nullptr, "Should never try to send if blocked!");
    if (!sendTimingReq(pkt)) {
        blockedPacket = pkt;
    }
}
```

接下来，我们需要实现重新发送数据包的代码。在这个函数中，我们尝试通过调用我们在上面编写的 `sendPacket` 函数来重新发送数据包。

```cpp
void
SimpleMemobj::MemSidePort::recvReqRetry()
{
    assert(blockedPacket != nullptr);

    PacketPtr pkt = blockedPacket;
    blockedPacket = nullptr;

    sendPacket(pkt);
}
```

### 实现接收响应

响应代码路径类似于接收代码路径。当 `MemSidePort` 收到响应时，我们通过 `SimpleMemobj` 将响应转发到相应的 `CPUSidePort`。

```cpp
bool
SimpleMemobj::MemSidePort::recvTimingResp(PacketPtr pkt)
{
    return owner->handleResponse(pkt);
}
```

在 `SimpleMemobj` 中，首先，当我们收到响应时它应该总是被阻止，因为对象应该正在等待响应。在将数据包发送回 CPU 侧之前，我们需要标记对象不再被阻止。这必须在 *调用 `sendTimingResp` 之前* 完成。否则，可能会陷入无限循环，因为请求端口可能在接收响应和发送另一个请求之间具有单个调用链。

在解锁 `SimpleMemobj` 之后，我们检查数据包是指令数据包还是数据数据包，并通过相应的端口将其发回。最后，由于对象现在已解除阻止，我们可能需要通知 CPU 侧端口它们现在可以重试失败的请求。

```cpp
bool
SimpleMemobj::handleResponse(PacketPtr pkt)
{
    assert(blocked);
    DPRINTF(SimpleMemobj, "Got response for addr %#x\n", pkt->getAddr());

    blocked = false;

    // Simply forward to the memory port
    if (pkt->req->isInstFetch()) {
        instPort.sendPacket(pkt);
    } else {
        dataPort.sendPacket(pkt);
    }

    instPort.trySendRetry();
    dataPort.trySendRetry();

    return true;
}
```

类似于我们在 `MemSidePort` 中实现发送数据包的便利函数，我们可以在 `CPUSidePort` 中实现 `sendPacket` 函数以将响应发送到 CPU 侧。此函数调用 `sendTimingResp`，这将反过来调用对等请求端口上的 `recvTimingResp`。如果此调用失败并且对等端口当前被阻止，那么我们将存储数据包以便稍后发送。

```cpp
void
SimpleMemobj::CPUSidePort::sendPacket(PacketPtr pkt)
{
    panic_if(blockedPacket != nullptr, "Should never try to send if blocked!");

    if (!sendTimingResp(pkt)) {
        blockedPacket = pkt;
    }
}
```

当我们收到 `recvRespRetry` 时，我们将稍后发送此被阻止的数据包。此函数与上面的 `recvReqRetry` 完全相同，只是尝试重新发送数据包，该数据包可能会再次被阻止。

```cpp
void
SimpleMemobj::CPUSidePort::recvRespRetry()
{
    assert(blockedPacket != nullptr);

    PacketPtr pkt = blockedPacket;
    blockedPacket = nullptr;

    sendPacket(pkt);
}
```

最后，我们需要为 `CPUSidePort` 实现额外的函数 `trySendRetry`。每当 `SimpleMemobj` 可能被解锁时，`SimpleMemobj` 都会调用此函数。`trySendRetry` 检查是否需要重试，我们在 `recvTimingReq` 中每当 `SimpleMemobj` 在新请求上被阻止时就标记它。然后，如果需要重试，此函数调用 `sendRetryReq`，这反过来调用对等请求端口（在本例中为 CPU）上的 `recvReqRetry`。

```cpp
void
SimpleMemobj::CPUSidePort::trySendRetry()
{
    if (needRetry && blockedPacket == nullptr) {
        needRetry = false;
        DPRINTF(SimpleMemobj, "Sending retry req for %d\n", id);
        sendRetryReq();
    }
}
```
除了此函数之外，要完成该文件，请为 SimpleMemobj 添加 create 函数。
```cpp
SimpleMemobj*
SimpleMemobjParams::create()
{
    return new SimpleMemobj(this);
}
```
您可以下载 `SimpleMemobj` 的实现
[这里](/_pages/static/scripts/part2/memoryobject/simple_memobj.cc)。

下图显示了 `CPUSidePort`、`MemSidePort` 和 `SimpleMemobj` 之间的关系。此图显示了对等端口如何与 `SimpleMemobj` 的实现进行交互。每个粗体函数都是我们必须实现的函数，非粗体函数是对等端口的端口接口。颜色突出了通过对象的一条 API 路径（例如，接收请求或更新内存范围）。

![SimpleMemobj 及其端口之间的交互](/_pages/static/figures/memobj_api.png)

对于这个简单的内存对象，数据包只是从 CPU 侧转发到内存侧。但是，通过修改 `handleRequest` 和 `handleResponse`，我们可以创建功能丰富的对象，例如在 [下一章](../simplecache) 中的缓存。

### 创建配置文件

这是实现简单内存对象所需的全部代码！在 [下一章](../simplecache) 中，我们将采用此框架并添加一些缓存逻辑，使此内存对象成为一个简单的缓存。但是，在此之前，让我们看一下将 SimpleMemobj 添加到您的系统的配置文件。

此配置文件基于 [simple-config-chapter](../../part1/simple_config) 中的简单配置文件。但是，我们不是将 CPU 直接连接到内存总线，而是要实例化一个 `SimpleMemobj` 并将其放置在 CPU 和内存总线之间。

```python
import m5
from m5.objects import *

system = System()
system.clk_domain = SrcClockDomain()
system.clk_domain.clock = '1GHz'
system.clk_domain.voltage_domain = VoltageDomain()
system.mem_mode = 'timing'
system.mem_ranges = [AddrRange('512MB')]

system.cpu = X86TimingSimpleCPU()

system.memobj = SimpleMemobj()

system.cpu.icache_port = system.memobj.inst_port
system.cpu.dcache_port = system.memobj.data_port

system.membus = SystemXBar()

system.memobj.mem_side = system.membus.cpu_side_ports

system.cpu.createInterruptController()
system.cpu.interrupts[0].pio = system.membus.mem_side_ports
system.cpu.interrupts[0].int_requestor = system.membus.cpu_side_ports
system.cpu.interrupts[0].int_responder = system.membus.mem_side_ports

system.mem_ctrl = DDR3_1600_8x8()
system.mem_ctrl.range = system.mem_ranges[0]
system.mem_ctrl.port = system.membus.mem_side_ports

system.system_port = system.membus.cpu_side_ports

process = Process()
process.cmd = ['tests/test-progs/hello/bin/x86/linux/hello']
system.cpu.workload = process
system.cpu.createThreads()

root = Root(full_system = False, system = system)
m5.instantiate()

print ("Beginning simulation!")
exit_event = m5.simulate()
print('Exiting @ tick %i because %s' % (m5.curTick(), exit_event.getCause()))
```

您可以下载此配置脚本
[这里](/_pages/static/scripts/part2/memoryobject/simple_memobj.py)。

现在，当您运行此配置文件时，您会得到以下输出。

    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 compiled Jan  5 2017 13:40:18
    gem5 started Jan  9 2017 10:17:17
    gem5 executing on chinook, pid 5138
    command line: build/X86/gem5.opt configs/learning_gem5/part2/simple_memobj.py

    Global frequency set at 1000000000000 ticks per second
    warn: DRAM device capacity (8192 Mbytes) does not match the address range assigned (512 Mbytes)
    0: system.remote_gdb.listener: listening for remote gdb #0 on port 7000
    warn: CoherentXBar system.membus has no snooping ports attached!
    warn: ClockedObject: More than one power state change request encountered within the same simulation tick
    Beginning simulation!
    info: Entering event queue @ 0.  Starting simulation...
    Hello world!
    Exiting @ tick 507841000 because target called exit()

如果您使用 `SimpleMemobj` 调试标志运行，您可以看到所有来自和发往 CPU 的内存请求和响应。

    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 compiled Jan  5 2017 13:40:18
    gem5 started Jan  9 2017 10:18:51
    gem5 executing on chinook, pid 5157
    command line: build/X86/gem5.opt --debug-flags=SimpleMemobj configs/learning_gem5/part2/simple_memobj.py

    Global frequency set at 1000000000000 ticks per second
    Beginning simulation!
    info: Entering event queue @ 0.  Starting simulation...
          0: system.memobj: Got request for addr 0x190
      77000: system.memobj: Got response for addr 0x190
      77000: system.memobj: Got request for addr 0x190
     132000: system.memobj: Got response for addr 0x190
     132000: system.memobj: Got request for addr 0x190
     187000: system.memobj: Got response for addr 0x190
     187000: system.memobj: Got request for addr 0x94e30
     250000: system.memobj: Got response for addr 0x94e30
     250000: system.memobj: Got request for addr 0x190
     ...

您还可以将 CPU 模型更改为乱序模型 (`X86O3CPU`)。当使用乱序 CPU 时，您可能会看到不同的地址流，因为它允许一次有多个未完成的内存请求。当使用乱序 CPU 时，现在会有许多停顿，因为 `SimpleMemobj` 是阻塞的。
