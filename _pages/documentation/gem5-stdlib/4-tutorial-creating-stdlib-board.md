---
layout: documentation
title: 如何使用 gem5 标准库创建您自己的开发板
parent: gem5-standard-library
doc: gem5 documentation
permalink: /documentation/gem5-stdlib/develop-stdlib-board
author: Jasjeet Rangi, Kunal Pai
---

## 如何使用 gem5 标准库创建您自己的开发板

在本教程中，我们将介绍如何使用 gem5 标准库创建自定义开发板。

本教程基于制作 _RiscvMatched_ 的过程，这是一个继承自 `MinorCPU` 的 RISC-V 预构建开发板。此开发板可以在 `src/python/gem5/prebuilt/riscvmatched` 找到。

本教程将创建一个大小为 2 GiB 的单通道 DDR4 内存，一个使用 MinorCPU 和 RISC-V ISA 的核心，尽管相同的过程可以用于其他类型或大小的内存、ISA 和核心。

同样，本教程将利用在[开发您自己的组件教程](https://www.gem5.org/documentation/gem5-stdlib/develop-own-components-tutorial)中制作的 UniqueCacheHierarchy，尽管可以使用任何其他缓存层次结构。

首先，我们开始导入所需的组件和标准库功能。

``` python
from typing import List

from m5.objects import (
    AddrRange,
    BaseCPU,
    BaseMMU,
    IOXBar,
    Port,
    Process,
)
from m5.objects.RiscvCPU import RiscvMinorCPU

from gem5.components.boards.abstract_system_board import AbstractSystemBoard
from gem5.components.boards.se_binary_workload import SEBinaryWorkload
from gem5.components.cachehierarchies.classic.unique_cache_hierarchy import (
    UniqueCacheHierarchy,
)
from gem5.components.memory import SingleChannelDDR4_2400
from gem5.components.processors.base_cpu_core import BaseCPUCore
from gem5.components.processors.base_cpu_processor import BaseCPUProcessor
from gem5.isas import ISA
from gem5.utils.override import overrides
```

我们将通过为我们的开发板创建一个专门的 CPU 核心来开始开发，该核心继承自所选 CPU 的 ISA 特定版本。
由于我们的 ISA 是 RISC-V，我们想要的 CPU 类型是 MinorCPU，我们将从 `RiscvMinorCPU` 继承。
这样做是为了我们可以设置自己的参数以根据我们的要求定制 CPU。
在我们的示例中，我们将覆盖单个参数：`decodeToExecuteForwardDelay`（默认值为 1）。
我们将这个新的 CPU 核心类型称为 `UniqueCPU`。

``` python
class UniqueCPU(RiscvMinorCPU):
    decodeToExecuteForwardDelay = 2
```

由于 `RiscvMinorCPU` 继承自 `BaseCPU`，我们可以使用 `BaseCPUCore`（`BaseCPU` 对象的标准库包装器，其源代码可以在 `src/python/gem5/components/processors/base_cpu_core.py` 找到）将其整合到标准库中。
`BaseCPUCore` 在构造时将 `BaseCPU` 作为参数。
因此，我们可以执行以下操作：

```python
core = BaseCPUCore(core=UniqueCPU(), isa=ISA.RISCV)
```

<!-- **Note**: `BaseCPU` objects require a unique `core_id` to be specified upon construction. -->

接下来我们必须定义我们的处理器。
在 gem5 标准库中，处理器是核心的集合。
在这种情况下，例如我们的情况，我们可以利用库的 `BaseCPUProcessor`，一个包含 `BaseCPUCore` 对象的处理器（源代码可以在 `src/python/gem5/components/processors/base_cpu_processor.py` 找到）。
`BaseCPUProcessor` 需要一个 `BaseCPUCore` 列表。
因此：

```python
processor = BaseCPUProcessor(cores=[core])
```

接下来我们专注于构建开发板以承载我们的组件。
所有开发板都必须继承自 `AbstractBoard`，在大多数情况下，还要继承 gem5 的 `System` simobject。
因此，在这种情况下，我们的开发板将从 `AbstractSystemBoard` 继承；这是一个继承自两者的抽象类。

为了在 SE 模式下运行模拟，我们还必须继承自 `SEBinaryWorkload`。

所有 `AbstractBoard` 都必须指定 `clk_freq`（时钟频率）、`processor`、`memory` 和 `cache_hierarchy`。
我们已经有了处理器，并将使用 `UniqueCacheHierarchy` 作为 `cache_hierarchy`，使用大小为 2GiB 的 `SingleChannelDDR4_2400` 作为内存。

我们将此称为 `UniqueBoard`，它应该如下所示：

``` python
class UniqueBoard(AbstractSystemBoard, SEBinaryWorkload):
    def __init__(
        self,
        clk_freq: str,
    ) -> None:
        core = BaseCPUCore(core=UniqueCPU(), isa=ISA.RISCV)
        processor = BaseCPUProcessor(cores=[core])
        memory = SingleChannelDDR4_2400("2GiB")
        cache_hierarchy = UniqueCacheHierarchy()
        super().__init__(
            clk_freq=clk_freq,
            processor=processor,
            memory=memory,
            cache_hierarchy=cache_hierarchy,
        )
```

构造函数完成后，我们必须实现 `AbstractSystemBoard` 中的抽象方法。
在这里查看 `/src/python/gem5/components/boards/abstract_system_board.py` 中 `AbstractBoard` 的源代码很有用。

您选择实现或不实现的抽象方法将取决于您创建的系统类型。
在我们的示例中，诸如 `_setup_board` 之类的函数是不需要的，因此我们将使用 `pass` 实现它们。
在其他情况下，我们将使用 `NotImplementedError` 来处理此开发板上不可用的特定组件/功能的情况，如果尝试访问它，应该返回错误。
例如，我们的开发板将没有 IO 总线。
因此，我们将实现 `has_io_bus` 返回 `False`，并让 `get_io_bus` 在调用时引发 `NotImplementedError`。

除了 `_setup_memory_ranges` 之外，我们不实现 `AbstractSystemBoard` 所需的许多功能。开发板应该如下所示：

``` python
class UniqueBoard(AbstractSystemBoard, SEBinaryWorkload):
    def __init__(
        self,
        clk_freq: str,
    ) -> None:
        core = BaseCPUCore(core=UniqueCPU(), isa=ISA.RISCV)
        processor = BaseCPUProcessor(cores=[core])
        memory = SingleChannelDDR4_2400("2GiB")
        cache_hierarchy = UniqueCacheHierarchy()
        super().__init__(
            clk_freq=clk_freq,
            processor=processor,
            memory=memory,
            cache_hierarchy=cache_hierarchy,
        )

    @overrides(AbstractSystemBoard)
    def _setup_board(self) -> None:
        pass

    @overrides(AbstractSystemBoard)
    def has_io_bus(self) -> bool:
        return False

    @overrides(AbstractSystemBoard)
    def get_io_bus(self) -> IOXBar:
        raise NotImplementedError(
            "UniqueBoard does not have an IO Bus. "
            "Use `has_io_bus()` to check this."
        )

    @overrides(AbstractSystemBoard)
    def has_dma_ports(self) -> bool:
        return False

    @overrides(AbstractSystemBoard)
    def get_dma_ports(self) -> List[Port]:
        raise NotImplementedError(
            "UniqueBoard does not have DMA Ports. "
            "Use `has_dma_ports()` to check this."
        )

    @overrides(AbstractSystemBoard)
    def has_coherent_io(self) -> bool:
        return False

    @overrides(AbstractSystemBoard)
    def get_mem_side_coherent_io_port(self) -> Port:
        raise NotImplementedError(
            "UniqueBoard does not have any I/O ports. Use has_coherent_io to "
            "check this."
        )

    @overrides(AbstractSystemBoard)
    def _setup_memory_ranges(self) -> None:
        memory = self.get_memory()
        self.mem_ranges = [AddrRange(memory.get_size())]
        memory.set_memory_range(self.mem_ranges)
```

这完成了为 gem5 标准库创建自定义开发板的工作。
完成的开发板如下：

```python
from typing import List

from m5.objects import (
    AddrRange,
    BaseCPU,
    BaseMMU,
    IOXBar,
    Port,
    Process,
)
from m5.objects.RiscvCPU import RiscvMinorCPU

from gem5.components.boards.abstract_system_board import AbstractSystemBoard
from gem5.components.boards.se_binary_workload import SEBinaryWorkload
from gem5.components.cachehierarchies.classic.unique_cache_hierarchy import (
    UniqueCacheHierarchy,
)
from gem5.components.memory import SingleChannelDDR4_2400
from gem5.components.processors.base_cpu_core import BaseCPUCore
from gem5.components.processors.base_cpu_processor import BaseCPUProcessor
from gem5.isas import ISA
from gem5.utils.override import overrides


class UniqueCPU(RiscvMinorCPU):
    decodeToExecuteForwardDelay = 2


class UniqueBoard(AbstractSystemBoard, SEBinaryWorkload):
    def __init__(
        self,
        clk_freq: str,
    ) -> None:
        core = BaseCPUCore(core=UniqueCPU(), isa=ISA.RISCV)
        processor = BaseCPUProcessor(cores=[core])
        memory = SingleChannelDDR4_2400("2GiB")
        cache_hierarchy = UniqueCacheHierarchy()
        super().__init__(
            clk_freq=clk_freq,
            processor=processor,
            memory=memory,
            cache_hierarchy=cache_hierarchy,
        )

    @overrides(AbstractSystemBoard)
    def _setup_board(self) -> None:
        pass

    @overrides(AbstractSystemBoard)
    def has_io_bus(self) -> bool:
        return False

    @overrides(AbstractSystemBoard)
    def get_io_bus(self) -> IOXBar:
        raise NotImplementedError(
            "UniqueBoard does not have an IO Bus. "
            "Use `has_io_bus()` to check this."
        )

    @overrides(AbstractSystemBoard)
    def has_dma_ports(self) -> bool:
        return False

    @overrides(AbstractSystemBoard)
    def get_dma_ports(self) -> List[Port]:
        raise NotImplementedError(
            "UniqueBoard does not have DMA Ports. "
            "Use `has_dma_ports()` to check this."
        )

    @overrides(AbstractSystemBoard)
    def has_coherent_io(self) -> bool:
        return False

    @overrides(AbstractSystemBoard)
    def get_mem_side_coherent_io_port(self) -> Port:
        raise NotImplementedError(
            "UniqueBoard does not have any I/O ports. Use has_coherent_io to "
            "check this."
        )

    @overrides(AbstractSystemBoard)
    def _setup_memory_ranges(self) -> None:
        memory = self.get_memory()
        self.mem_ranges = [AddrRange(memory.get_size())]
        memory.set_memory_range(self.mem_ranges)

```

由此，您可以创建一个运行脚本并测试您的开发板：

``` python
from unique_board import UniqueBoard

from gem5.resources.resource import obtain_resource
from gem5.simulate.simulator import Simulator

board = UniqueBoard(clk_freq="1.2GHz")

# As we are using the RISCV ISA, "riscv-hello" should work.
board.set_se_binary_workload(obtain_resource("riscv-hello"))

simulator = Simulator(board=board)
simulator.run()
```
