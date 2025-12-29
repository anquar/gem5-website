---
layout: documentation
title: 配置标准协议
doc: Learning gem5
parent: part3
permalink: /documentation/learning_gem5/part3/simple-MI_example/
author: Jason Lowe-Power
---


您可以轻松地将本部分中的简单示例配置调整为 gem5 中的其他 SLICC 协议。在本章中，我们将简要介绍一个带有 `MI_example` 的示例，但这可以很容易地扩展到其他协议。

但是，这些简单的配置文件仅在系统调用仿真模式下工作。全系统模式增加了一些复杂性，例如 DMA 控制器。这些脚本可以扩展到全系统。

对于 `MI_example`，我们可以使用与以前完全相同的运行脚本 (`simple_ruby.py`)，我们只需要实现不同的 `MyCacheSystem`（并在 `simple_ruby.py` 中导入该文件）。下面是 `MI_example` 所需的类。与 `MSI` 只有几处更改，主要是由于命名方案不同。您可以下载文件
[这里](https://github.com/gem5/gem5/blob/stable/configs/learning_gem5/part3/ruby_caches_MI_example.py)。

```python
class MyCacheSystem(RubySystem):

    def __init__(self):
        if buildEnv['PROTOCOL'] != 'MI_example':
            fatal("This system assumes MI_example!")

        super(MyCacheSystem, self).__init__()

    def setup(self, system, cpus, mem_ctrls):
        """Set up the Ruby cache subsystem. Note: This can't be done in the
           constructor because many of these items require a pointer to the
           ruby system (self). This causes infinite recursion in initialize()
           if we do this in the __init__.
        """
        # Ruby 的全局网络。
        self.network = MyNetwork(self)

        # MI example 使用 5 个虚拟网络
        self.number_of_virtual_networks = 5
        self.network.number_of_virtual_networks = 5

        # 有一个包含所有控制器的全局列表，以便更容易将所有东西连接到全局网络。
        # 这可以根据拓扑/网络要求进行定制。
        # 为每个 L1 缓存（和缓存内存对象）创建一个控制器
        # 创建一个目录控制器（实际上是内存控制器）
        self.controllers = \
            [L1Cache(system, self, cpu) for cpu in cpus] + \
            [DirController(self, system.mem_ranges, mem_ctrls)]

        # 为每个 CPU 创建一个定序器。在许多系统中，这更复杂
        # 因为您还必须为 DMA 控制器和其他控制器创建定序器。
        self.sequencers = [RubySequencer(version = i,
                                # I/D 缓存合并并从 ctrl 获取
                                icache = self.controllers[i].cacheMemory,
                                dcache = self.controllers[i].cacheMemory,
                                clk_domain = self.controllers[i].clk_domain,
                                ) for i in range(len(cpus))]

        for i,c in enumerate(self.controllers[0:len(cpus)]):
            c.sequencer = self.sequencers[i]

        self.num_of_sequencers = len(self.sequencers)

        # 创建网络并连接控制器。
        # 注意：如果使用 Garnet，这会有很大不同！
        self.network.connectControllers(self.controllers)
        self.network.setup_buffers()

        # 为 system_port 设置代理端口。用于加载二进制文件和其他仅功能性的东西。
        self.sys_port_proxy = RubyPortProxy()
        system.system_port = self.sys_port_proxy.slave

        # 将 cpu 的缓存、中断和 TLB 端口连接到 Ruby
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

class L1Cache(L1Cache_Controller):

    _version = 0
    @classmethod
    def versionCount(cls):
        cls._version += 1 # 使用此特定类型的计数
        return cls._version - 1

    def __init__(self, system, ruby_system, cpu):
        """CPUs needed to grab the clock domain and system is needed for
           the cache block size.
        """
        super(L1Cache, self).__init__()

        self.version = self.versionCount()
        # 这是存储缓存数据和标签的缓存内存对象
        self.cacheMemory = RubyCache(size = '16kB',
                               assoc = 8,
                               start_index_bit = self.getBlockSizeBits(system))
        self.clk_domain = cpu.clk_domain
        self.send_evictions = self.sendEvicts(cpu)
        self.ruby_system = ruby_system
        self.connectQueues(ruby_system)

    def getBlockSizeBits(self, system):
        bits = int(math.log(system.cache_line_size, 2))
        if 2**bits != system.cache_line_size.value:
            panic("Cache line size not a power of 2!")
        return bits

    def sendEvicts(self, cpu):
        """True if the CPU model or ISA requires sending evictions from caches
           to the CPU. Two scenarios warrant forwarding evictions to the CPU:
           1. The O3 model must keep the LSQ coherent with the caches
           2. The x86 mwait instruction is built on top of coherence
           3. The local exclusive monitor in ARM systems
        """
        return True

    def connectQueues(self, ruby_system):
        """Connect all of the queues for this controller.
        """
        self.mandatoryQueue = MessageBuffer()
        self.requestFromCache = MessageBuffer(ordered = True)
        self.requestFromCache.master = ruby_system.network.slave
        self.responseFromCache = MessageBuffer(ordered = True)
        self.responseFromCache.master = ruby_system.network.slave
        self.forwardToCache = MessageBuffer(ordered = True)
        self.forwardToCache.slave = ruby_system.network.master
        self.responseToCache = MessageBuffer(ordered = True)
        self.responseToCache.slave = ruby_system.network.master

class DirController(Directory_Controller):

    _version = 0
    @classmethod
    def versionCount(cls):
        cls._version += 1 # Use count for this particular type
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
        self.requestToDir = MessageBuffer(ordered = True)
        self.requestToDir.slave = ruby_system.network.master
        self.dmaRequestToDir = MessageBuffer(ordered = True)
        self.dmaRequestToDir.slave = ruby_system.network.master

        self.responseFromDir = MessageBuffer()
        self.responseFromDir.master = ruby_system.network.slave
        self.dmaResponseFromDir = MessageBuffer(ordered = True)
        self.dmaResponseFromDir.master = ruby_system.network.slave
        self.forwardFromDir = MessageBuffer()
        self.forwardFromDir.master = ruby_system.network.slave
        self.responseFromMemory = MessageBuffer()

class MyNetwork(SimpleNetwork):
    """A simple point-to-point network. This doesn't not use garnet.
    """

    def __init__(self, ruby_system):
        super(MyNetwork, self).__init__()
        self.netifs = []
        self.ruby_system = ruby_system

    def connectControllers(self, controllers):
        """Connect all of the controllers to routers and connect the routers
           together in a point-to-point network.
        """
        # Create one router/switch per controller in the system
        self.routers = [Switch(router_id = i) for i in range(len(controllers))]

        # Make a link from each controller to the router. The link goes
        # externally to the network.
        self.ext_links = [SimpleExtLink(link_id=i, ext_node=c,
                                        int_node=self.routers[i])
                          for i, c in enumerate(controllers)]

        # Make an "internal" link (internal to the network) between every pair
        # of routers.
        link_count = 0
        self.int_links = []
        for ri in self.routers:
            for rj in self.routers:
                if ri == rj: continue # Don't connect a router to itself!
                link_count += 1
                self.int_links.append(SimpleIntLink(link_id = link_count,
                                                    src_node = ri,
                                                    dst_node = rj))
```
