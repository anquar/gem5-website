---
layout: documentation
title: 开发自定义组件教程
parent: gem5-standard-library
doc: gem5 documentation
permalink: /documentation/gem5-stdlib/develop-own-components-tutorial
author: Bobby R. Bruce
---

## 开发您自己的 gem5 标准库组件

![gem5 组件库设计](/assets/img/stdlib/gem5-components-design.png)

上图显示了 gem5 库组件的基本设计。
有四个重要的抽象类：`AbstractBoard`、`AbstractProcessor`、`AbstractMemorySystem` 和 `AbstractCacheHierarchy`。
每个 gem5 组件都继承自其中之一，以成为可在设计中使用的 gem5 组件。
`AbstractBoard` 必须通过指定 `AbstractProcessor`、`AbstractMemorySystem` 和 `AbstractCacheHierarchy` 来构造。
通过这种设计，任何开发板都可以使用继承自 `AbstractProcessor`、`AbstractMemorySystem` 和 `AbstractCacheHierarchy` 的组件的任何组合。
例如，使用图像作为指南，我们可以将 `SimpleProcessor`、`SingleChannelDDR3_1600` 和 `PrivateL1PrivateL2CacheHierarchy` 添加到 `X86Board`。
如果我们愿意，可以将 `PrivateL1PrivateL2CacheHierarchy` 替换为继承自 `AbstractCacheHierarchy` 的另一个类。

在本教程中，我们将想象用户希望创建一个新的缓存层次结构。
从图中可以看出，有两个继承自 `AbstractCacheHierarchy` 的子类：`AbstractRubyCacheHierarchy` 和 `AbstractClassicCacheHierarchy`。
虽然您 _可以_ 直接从 `AbstractCacheHierarchy` 继承，但我们建议从子类继承（取决于您希望开发 ruby 还是经典缓存层次结构设置）。
我们将从 `AbstractClassicCacheHierarchy` 类继承以创建经典缓存设置。

首先，我们应该创建一个继承自 `AbstractClassicCacheHierarchy` 的新 Python 类。
在本示例中，我们将其称为 `UniqueCacheHierarchy`，包含在文件 `unique_cache_hierarchy.py` 中：

```python
from m5.objects import (
    Port,
)

from gem5.components.boards.abstract_board import AbstractBoard
from gem5.components.cachehierarchies.classic.abstract_classic_cache_hierarchy import (
    AbstractClassicCacheHierarchy,
)


class UniqueCacheHierarchy(AbstractClassicCacheHierarchy):


    def __init__() -> None:
        AbstractClassicCacheHierarchy.__init__(self=self)

    def get_mem_side_port(self) -> Port:
        pass

    def get_cpu_side_port(self) -> Port:
        pass

    def incorporate_cache(self, board: AbstractBoard) -> None:
        pass
```

与每个抽象基类一样，有一些必须实现的虚函数。
一旦实现，`UniqueCacheHierarchy` 就可以在模拟中使用。
`get_mem_side_port` 和 `get_cpu_side_port` 在 [AbstractClassicCacheHierarchy](https://github.com/gem5/gem5/blob/stable/src/python/gem5/components/cachehierarchies/classic/abstract_classic_cache_hierarchy.py) 中声明，而 `incorporate_cache` 在 [AbstractCacheHierarchy](https://github.com/gem5/gem5/blob/stable/src/python/gem5/components/cachehierarchies/abstract_cache_hierarchy.py) 中声明。

`get_mem_side_port` 和 `get_cpu_side_port` 函数各自返回一个 `Port`。
顾名思义，这些是开发板用于从内存端和 CPU 端访问缓存层次结构的端口。
这些必须为所有经典缓存层次结构设置指定。

`incorporate_cache` 函数是用于将缓存整合到开发板中的函数。
此函数的内容会因缓存层次结构设置而异，但通常会检查它连接到的开发板，并使用开发板的 API 连接缓存层次结构。

在本示例中，我们假设用户希望实现一个私有 L1 缓存层次结构，由每个 CPU 核心的数据缓存和指令缓存组成。
这实际上已经在 gem5 标准库中实现为 [PrivateL1CacheHierarchy](https://github.com/gem5/gem5/blob/stable/src/python/gem5/components/cachehierarchies/classic/private_l1_cache_hierarchy.py)，但为了本示例，我们将重复这项工作。

首先，我们通过实现 `get_mem_side_port` 和 `get_cpu_side_port` 函数开始：

```python
from m5.objects import (
    BadAddr,
    Port,
    SystemXBar,
)

from gem5.components.boards.abstract_board import AbstractBoard
from gem5.components.cachehierarchies.classic.abstract_classic_cache_hierarchy import (
    AbstractClassicCacheHierarchy,
)


class UniqueCacheHierarchy(AbstractClassicCacheHierarchy):

    def __init__(self) -> None:
        AbstractClassicCacheHierarchy.__init__(self=self)
        self.membus = SystemXBar(width=64)
        self.membus.badaddr_responder = BadAddr()
        self.membus.default = self.membus.badaddr_responder.pio

    def get_mem_side_port(self) -> Port:
        return self.membus.mem_side_ports

    def get_cpu_side_port(self) -> Port:
        return self.membus.cpu_side_ports

    def incorporate_cache(self, board: AbstractBoard) -> None:
        pass
```

这里我们使用了一个简单的内存总线。

接下来，我们实现 `incorporate_cache` 函数：

```python
from m5.objects import (
    BadAddr,
    Cache,
    Port,
    SystemXBar,
)

from gem5.components.boards.abstract_board import AbstractBoard
from gem5.components.cachehierarchies.classic.abstract_classic_cache_hierarchy import (
    AbstractClassicCacheHierarchy,
)
from gem5.components.cachehierarchies.classic.caches.l1dcache import L1DCache
from gem5.components.cachehierarchies.classic.caches.l1icache import L1ICache
from gem5.components.cachehierarchies.classic.caches.mmu_cache import MMUCache


class UniqueCacheHierarchy(AbstractClassicCacheHierarchy):

    def __init__(self) -> None:
        AbstractClassicCacheHierarchy.__init__(self=self)
        self.membus = SystemXBar(width=64)
        self.membus.badaddr_responder = BadAddr()
        self.membus.default = self.membus.badaddr_responder.pio

    def get_mem_side_port(self) -> Port:
        return self.membus.mem_side_ports

    def get_cpu_side_port(self) -> Port:
        return self.membus.cpu_side_ports

    def incorporate_cache(self, board: AbstractBoard) -> None:
        # Set up the system port for functional access from the simulator.
        board.connect_system_port(self.membus.cpu_side_ports)

        for cntr in board.get_memory().get_memory_controllers():
            cntr.port = self.membus.mem_side_ports

        self.l1icaches = [
            L1ICache(size="32KiB")
            for i in range(board.get_processor().get_num_cores())
        ]

        self.l1dcaches = [
            L1DCache(size="32KiB")
            for i in range(board.get_processor().get_num_cores())
        ]
        # ITLB Page walk caches
        self.iptw_caches = [
            MMUCache(size="8KiB")
            for _ in range(board.get_processor().get_num_cores())
        ]
        # DTLB Page walk caches
        self.dptw_caches = [
            MMUCache(size="8KiB")
            for _ in range(board.get_processor().get_num_cores())
        ]

        if board.has_coherent_io():
            self._setup_io_cache(board)

        for i, cpu in enumerate(board.get_processor().get_cores()):

            cpu.connect_icache(self.l1icaches[i].cpu_side)
            cpu.connect_dcache(self.l1dcaches[i].cpu_side)

            self.l1icaches[i].mem_side = self.membus.cpu_side_ports
            self.l1dcaches[i].mem_side = self.membus.cpu_side_ports

            self.iptw_caches[i].mem_side = self.membus.cpu_side_ports
            self.dptw_caches[i].mem_side = self.membus.cpu_side_ports

            cpu.connect_walker_ports(
                self.iptw_caches[i].cpu_side, self.dptw_caches[i].cpu_side
            )

            int_req_port = self.membus.mem_side_ports
            int_resp_port = self.membus.cpu_side_ports
            cpu.connect_interrupt(int_req_port, int_resp_port)

    def _setup_io_cache(self, board: AbstractBoard) -> None:
        """Create a cache for coherent I/O connections"""
        self.iocache = Cache(
            assoc=8,
            tag_latency=50,
            data_latency=50,
            response_latency=50,
            mshrs=20,
            size="1kB",
            tgts_per_mshr=12,
            addr_ranges=board.mem_ranges,
        )
        self.iocache.mem_side = self.membus.cpu_side_ports
        self.iocache.cpu_side = board.get_mem_side_coherent_io_port()
```

这完成了我们创建自己的缓存层次结构所需的代码。

要使用此代码，用户可以像导入任何其他 Python 模块一样导入它。
只要此代码在 gem5 的 python 搜索路径中，您就可以导入它。
您还可以在 gem5 运行脚本的开头添加 `import sys; sys.path.append(<path to new component>)`，以将此新组件的路径添加到 python 搜索路径。

## 将您的组件贡献给 gem5 标准库

在贡献您的组件之前，您需要将其移动到 `src/` 目录中，以便将其编译到 gem5 二进制文件中。

### 将您的组件编译到 gem5 标准库中

gem5 标准库代码位于 `src/python/gem5`。
基本目录结构如下：

```txt
gem5/
    components/                 # All the components to build the system to simulate.
        boards/                 # The boards, typically broken down by ISA target.
            experimental/       # Experimental boards.
        cachehierarchies/       # The Cache Hierarchy components.
            chi/                # CHI protocol cache hierarchies.
            classic/            # Classic cache hierarchies.
            ruby/               # Ruby cache hierarchies.
        memory/                 # Memory systems.
        processors/             # Processors.
    prebuilt/                   # Prebuilt systems, ready to use.
        demo/                   # Prebuilt System for demonstrations. (not be representative of real-world targets).
    resources/                  # Utilities used for referencing and obtaining gem5-resources.
    simulate/                   # A package for the automated running of gem5 simulations.
    utils/                      # General utilities.
```

我们建议将 `unique_cache_hierarchy.py` 放在 `src/python/gem5/components/cachehierarchies/classic/` 中。

然后，您需要在 `src/python/SConscript` 中添加以下行：

```scons
PySource('gem5.components.cachehierarchies.classic',
    'gem5/components/cachehierarchies/classic/unique_cache_hierarchy.py')
```

然后，当您重新编译 gem5 二进制文件时，`UniqueCacheHierarchy` 类将被包含在内。
要在您自己的脚本中使用它，您只需要包含它：

```python
from gem5.components.cachehierarchies.classic.unique_cache_hierarchy import UniqueCacheHierarchy

...

cache_hierarchy = UniqueCacheHierarchy()

...

```

### gem5 代码贡献和审查

如果您认为您对 gem5 标准库的添加对 gem5 社区有益，您可以将其作为补丁提交。
如果您之前没有为 gem5 做出贡献或需要提醒我们的程序，请遵循我们的[贡献指南](/contributing)。

除了我们的常规贡献指南外，我们强烈建议您对标准库贡献执行以下操作：

* **添加文档**：应使用 [reStructured text](https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html) 记录类和方法。
请查看标准库中的其他源代码，了解通常是如何完成的。
* **使用 Python 类型**：利用 [Python typing 模块](https://docs.python.org/3/library/typing.html) 指定参数和方法返回类型。
* **使用相对导入**：在 gem5 标准库中，应使用相对导入来引用标准库中的其他模块/包（即，包含在 `src/python/gem5` 中的内容）。
* **使用 black 格式化**：请使用 [Python black](https://pypi.org/project/black/) 格式化您的 Python 代码，最大行宽为 79：`black --line-length=79 <file/directory>`。
**注意**：Python black 并不总是强制执行行长度。
例如，它不会减少字符串长度。
您可能需要手动减少某些行的长度。

代码将通过 [GitHub](https://github.com/gem5/gem5) 进行审查，就像所有其他贡献一样。
但是，我们要强调的是，我们不会仅仅因为功能性和经过测试就接受对库的补丁；
我们需要一些说服力，证明贡献改进了库并有益于社区。
例如，如果小众组件被认为效用较低，同时增加了库的维护开销，则可能不会被纳入。
