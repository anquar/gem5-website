---
layout: documentation
title: 配置一个简单的 Ruby 系统
doc: Learning gem5
parent: part3
permalink: /documentation/learning_gem5/part3/configuration/
author: Jason Lowe-Power
---


## MSI 协议的配置脚本

首先，在 `configs/` 中创建一个新的配置目录。就像所有 gem5 配置文件一样，我们将有一个配置运行脚本。对于运行脚本，我们可以从 simple-config-chapter 中的 `simple.py` 开始。将此文件复制到新目录中的 `simple_ruby.py`。

我们将对此文件进行一些小更改，以使用 Ruby 而不是直接将 CPU 连接到内存控制器。

首先，为了我们可以测试我们的 *一致性* 协议，让我们使用两个 CPU。

```python
system.cpu = [X86TimingSimpleCPU(), X86TimingSimpleCPU()]
```

接下来，在实例化内存控制器之后，我们将创建缓存系统并设置所有缓存。在 *创建 CPU 中断之后，但在实例化系统之前* 添加以下行。

```python
system.caches = MyCacheSystem()
system.caches.setup(system, system.cpu, [system.mem_ctrl])
```

像 cache-config-chapter 中的经典缓存示例一样，我们将创建包含缓存配置代码的第二个文件。在此文件中，我们将有一个名为 `MyCacheSystem` 的类，并且我们将创建一个 `setup` 函数，该函数将系统中的 CPU 和内存控制器作为参数。

您可以下载完整的运行脚本
[这里](https://github.com/gem5/gem5/blob/stable/configs/learning_gem5/part3/simple_ruby.py)。

### 缓存系统配置

现在，让我们创建一个文件 `msi_caches.py`。在这个文件中，我们将创建四个类：`MyCacheSystem` 将继承自 `RubySystem`，`L1Cache` 和 `Directory` 将继承自 SLICC 从我们的两个状态机创建的 SimObject，以及 `MyNetwork` 将继承自 `SimpleNetwork`。

#### L1 缓存

让我们从 `L1Cache` 开始。首先，我们将继承自 `L1Cache_Controller`，因为我们在状态机文件中将我们的 L1 缓存命名为 "L1Cache"。我们还包括一个特殊的类变量和类方法来跟踪“版本号”。对于每个 SLICC 状态机，您必须按从 0 开始的升序对它们进行编号。同一类型的每台机器都应该有一个唯一的版本号。这用于区分各个机器。（希望将来这个要求会被取消。）

```python
class L1Cache(L1Cache_Controller):

    _version = 0
    @classmethod
    def versionCount(cls):
        cls._version += 1 # 使用此特定类型的计数
        return cls._version - 1
```

接下来，我们实现该类的构造函数。

```python
def __init__(self, system, ruby_system, cpu):
    super(L1Cache, self).__init__()

    self.version = self.versionCount()
    self.cacheMemory = RubyCache(size = '16kB',
                           assoc = 8,
                           start_index_bit = self.getBlockSizeBits(system))
    self.clk_domain = cpu.clk_domain
    self.send_evictions = self.sendEvicts(cpu)
    self.ruby_system = ruby_system
    self.connectQueues(ruby_system)
```

我们需要此函数中的 CPU 来获取时钟域，并且需要系统来获取缓存块大小。在这里，我们设置我们在状态机文件中命名的所有参数（例如，`cacheMemory`）。我们将稍后设置 `sequencer`。我们还硬编码了缓存的大小和关联性。如果要在运行时更改它们，您可以为这些选项添加命令行参数。

接下来，我们实现几个辅助函数。首先，我们需要弄清楚使用地址的多少位来索引缓存，这是一个简单的对数运算。我们还需要决定是否向 CPU 发送驱逐通知。仅当我们使用乱序 CPU 并使用 x86 或 ARM ISA 时，我们才应该转发驱逐。

```python
def getBlockSizeBits(self, system):
    bits = int(math.log(system.cache_line_size, 2))
    if 2**bits != system.cache_line_size.value:
        panic("Cache line size not a power of 2!")
    return bits

def sendEvicts(self, cpu):
    """True if the CPU model or ISA requires sending evictions from caches
       to the CPU. Three scenarios warrant forwarding evictions to the CPU:
       1. The O3 model must keep the LSQ coherent with the caches
       2. The x86 mwait instruction is built on top of coherence
       3. The local exclusive monitor in ARM systems
    """
    return True
```

最后，我们需要实现 `connectQueues` 以将所有消息缓冲区连接到 Ruby 网络。首先，我们为强制队列创建一个消息缓冲区。由于这是一个 L1 缓存并且它将有一个定序器，我们需要实例化这个特殊的消息缓冲区。接下来，我们为控制器中的每个缓冲区实例化一个消息缓冲区。对于所有的 "to" 缓冲区，我们必须将 "master" 设置为网络（即，缓冲区将向网络发送消息），并且对于所有的 "from" 缓冲区，我们必须将 "slave" 设置为网络。这些 *名称* 与 gem5 端口相同，但 *消息缓冲区目前并未实现为 gem5 端口*。在这个协议中，为了简单起见，我们假设消息缓冲区是有序的。

```python
def connectQueues(self, ruby_system):
    self.mandatoryQueue = MessageBuffer()

    self.requestToDir = MessageBuffer(ordered = True)
    self.requestToDir.master = ruby_system.network.slave
    self.responseToDirOrSibling = MessageBuffer(ordered = True)
    self.responseToDirOrSibling.master = ruby_system.network.slave
    self.forwardFromDir = MessageBuffer(ordered = True)
    self.forwardFromDir.slave = ruby_system.network.master
    self.responseFromDirOrSibling = MessageBuffer(ordered = True)
    self.responseFromDirOrSibling.slave = ruby_system.network.master
```

#### 目录

现在，我们可以类似地实现目录。与 L1 缓存有三个不同之处。首先，我们需要为目录设置地址范围。由于每个目录对应于特定内存控制器的一部分地址范围（可能），我们需要确保范围匹配。Ruby 控制器的默认地址范围是 `AllMemory`。

接下来，我们需要设置主端口 `memory`。这是在 SLICC 代码中调用 `queueMemoryRead/Write` 时发送消息的端口。我们将其设置为内存控制器端口。同样，在 `connectQueues` 中，我们需要实例化特殊的消息缓冲区 `responseFromMemory`，就像 L1 缓存中的 `mandatoryQueue` 一样。

```python
class DirController(Directory_Controller):

    _version = 0
    @classmethod
    def versionCount(cls):
        cls._version += 1 # 使用此特定类型的计数
        return cls._version - 1

    def __init__(self, ruby_system, ranges, mem_ctrls):
        """ranges are the memory ranges assigned to this controller.
        """
        if len(mem_ctrls) > 1:
            panic("This cache system can only be connected to one mem ctrl")
        super(DirController, self).__init__()
        self.version = self.versionCount()
        self.addr_ranges = ranges
        self.ruby_system = ruby_system
        self.directory = RubyDirectoryMemory()
        # Connect this directory to the memory side.
        self.memory = mem_ctrls[0].port
        self.connectQueues(ruby_system)

    def connectQueues(self, ruby_system):
        self.requestFromCache = MessageBuffer(ordered = True)
        self.requestFromCache.slave = ruby_system.network.master
        self.responseFromCache = MessageBuffer(ordered = True)
        self.responseFromCache.slave = ruby_system.network.master

        self.responseToCache = MessageBuffer(ordered = True)
        self.responseToCache.master = ruby_system.network.slave
        self.forwardToCache = MessageBuffer(ordered = True)
        self.forwardToCache.master = ruby_system.network.slave

        self.responseFromMemory = MessageBuffer()
```

#### Ruby 系统

现在，我们可以实现 Ruby 系统对象。对于此对象，构造函数很简单。它只是检查 SCons 变量 `PROTOCOL` 以确保我们使用了为编译的协议的正确配置文件。我们不能在构造函数中创建控制器，因为它们需要指向此对象的指针。如果我们要在构造函数中创建它们，SimObject 层次结构中将存在循环依赖，这将在使用 `m5.instantiate` 实例化系统时导致无限递归。

```python
class MyCacheSystem(RubySystem):

    def __init__(self):
        if buildEnv['PROTOCOL'] != 'MSI':
            fatal("This system assumes MSI from learning gem5!")

        super(MyCacheSystem, self).__init__()
```

我们不构造函数中创建控制器，而是创建一个新函数来创建所有需要的对象：`setup`。首先，我们创建网络。我们要看的是这对象。对于网络，我们需要设置系统中的虚拟网络数量。

接下来，我们实例化所有的控制器。在这里，我们使用控制器的单个全局列表，以便以后更容易将它们连接到网络。但是，对于更复杂的缓存拓扑，使用多个控制器列表可能是有意义的。我们为每个 CPU 创建一个 L1 缓存，并为系统创建一个目录。

然后，我们实例化所有的定序器，每个 CPU 一个。每个定序器都需要一个指向指令和数据缓存的指针，以模拟最初访问缓存时的正确延迟。在更复杂的系统中，您还必须为其他对象（如 DMA 控制器）创建定序器。

创建定序器后，我们在每个 L1 缓存控制器上设置定序器变量。

然后，我们将所有控制器连接到网络，并在网络上调用 `setup_buffers` 函数。

然后我们必须为 Ruby 系统和 `system` 设置“端口代理”，以便进行 functional 访问（例如，在 SE 模式下加载二进制文件）。

最后，我们将所有 CPU 连接到 ruby 系统。在此示例中，我们假设只有 CPU 定序器，因此第一个 CPU 连接到第一个定序器，依此类推。我们还必须连接 TLB 和中断端口（如果我们使用的是 x86）。

```python
def setup(self, system, cpus, mem_ctrls):
    self.network = MyNetwork(self)

    self.number_of_virtual_networks = 3
    self.network.number_of_virtual_networks = 3

    self.controllers = \
        [L1Cache(system, self, cpu) for cpu in cpus] + \
        [DirController(self, system.mem_ranges, mem_ctrls)]

    self.sequencers = [RubySequencer(version = i,
                            # I/D 缓存合并并从 ctrl 获取
                            icache = self.controllers[i].cacheMemory,
                            dcache = self.controllers[i].cacheMemory,
                            clk_domain = self.controllers[i].clk_domain,
                            ) for i in range(len(cpus))]

    for i,c in enumerate(self.controllers[0:len(self.sequencers)]):
        c.sequencer = self.sequencers[i]

    self.num_of_sequencers = len(self.sequencers)

    self.network.connectControllers(self.controllers)
    self.network.setup_buffers()

    self.sys_port_proxy = RubyPortProxy()
    system.system_port = self.sys_port_proxy.slave

    for i,cpu in enumerate(cpus):
        cpu.icache_port = self.sequencers[i].slave
        cpu.dcache_port = self.sequencers[i].slave
        isa = buildEnv['TARGET_ISA']
        if isa == 'x86':
            cpu.interrupts[0].pio = self.sequencers[i].master
            cpu.interrupts[0].int_master = self.sequencers[i].slave
            cpu.interrupts[0].int_slave = self.sequencers[i].master
        if isa == 'x86' or isa == 'arm':
            cpu.itb.walker.port = self.sequencers[i].slave
            cpu.dtb.walker.port = self.sequencers[i].slave
```

#### 网络

最后，我们要实现的最后一个对象是网络。构造函数很简单，但我们需要为网络接口列表 (`netifs`) 声明一个空列表。

大部分代码都在 `connectControllers` 中。此函数实现了一个 *非常简单、不切实际* 的点对点网络。换句话说，每个控制器都与每个其他控制器有直接链接。

Ruby 网络由三部分组成：将数据从一个路由器路由到另一个路由器或外部控制器的路由器，将控制器链接到路由器的外部链接，以及将两个路由器链接在一起的内部链接。首先，我们为每个控制器创建一个路由器。然后，我们创建一个从该路由器到控制器的外部链接。最后，我们添加所有的“内部”链接。每个路由器都连接到所有其他路由器，以构成点对点网络。

```python
class MyNetwork(SimpleNetwork):

    def __init__(self, ruby_system):
        super(MyNetwork, self).__init__()
        self.netifs = []
        self.ruby_system = ruby_system

    def connectControllers(self, controllers):
        self.routers = [Switch(router_id = i) for i in range(len(controllers))]

        self.ext_links = [SimpleExtLink(link_id=i, ext_node=c,
                                        int_node=self.routers[i])
                          for i, c in enumerate(controllers)]

        link_count = 0
        self.int_links = []
        for ri in self.routers:
            for rj in self.routers:
                if ri == rj: continue # 不要将路由器连接到其自身！
                link_count += 1
                self.int_links.append(SimpleIntLink(link_id = link_count,
                                                    src_node = ri,
                                                    dst_node = rj))
```

您可以下载完整的 `msi_caches.py` 文件
[这里](https://github.com/gem5/gem5/blob/stable/configs/learning_gem5/part3/msi_caches.py)。
