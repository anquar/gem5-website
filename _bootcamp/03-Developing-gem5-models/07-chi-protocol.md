---
layout: bootcamp
title: 使用 gem5 的 CHI 协议实现
permalink: /bootcamp/developing-gem5/chi-protocol
section: developing-gem5
---
<!-- _class: title -->

## 使用 gem5 的 CHI 协议实现

---

## 示例

- 让我们构建一个简单的两级缓存层次结构
  - 私有 L1 缓存
  - 共享 L2/目录（主节点）
<!-- - Extend this to allow for multiple L2s (banked by address) -->
<!-- - Multiple memory controllers as well -->

代码位于 [`materials/03-Developing-gem5-models/07-chi-protocol`](../../materials/03-Developing-gem5-models/07-chi-protocol/)。

---

## 使用一些组件

- CHI 已经有一些可用的组件
  - 目前只有一个 `private_l1_moesi_cache`
  - 点对点网络

参见 [`gem5/src/python/gem5/components/cachehierarchies/chi/nodes/private_l1_moesi_cache.py`](../../gem5/src/python/gem5/components/cachehierarchies/chi/nodes/private_l1_moesi_cache.py)。

---

## 创建 L2 主节点对象

在 CHI 中，您必须指定许多参数来配置缓存。
我们将使用 `AbstractNode` 作为缓存的基础类，它隐藏了一些样板代码。

对于我们的 L2，我们只想参数化大小和关联度。其他参数是 `AbstractNode` 类所必需的。

```python
class SharedL2(AbstractNode):
    """一个带有共享缓存的主节点（HNF）"""

    def __init__(
        self,
        size: str,
        assoc: int,
        network: RubyNetwork,
        cache_line_size: int,
    ):
        super().__init__(network, cache_line_size)
```

---

## 创建缓存对象

```python
self.cache = RubyCache(
    size=size,
    assoc=assoc,
    # 可以选择任何替换策略
    replacement_policy=RRIPRP(),
)
```

您可以从 [`gem5/src/mem/cache/replacement_policies/ReplacementPolicies.py`](../../gem5/src/mem/cache/replacement_policies/ReplacementPolicies.py) 中选择任何替换策略。

---

## 设置 CHI 参数

设置允许三跳协议的主节点并启用"owned"状态。

```python
self.is_HN = True
self.enable_DMT = True
self.enable_DCT = True
self.allow_SD = True
```

---

## 设置更多 CHI 参数

MOESI / 共享时主要包含 / 唯一时独占

```python
self.alloc_on_seq_acc = False
self.alloc_on_seq_line_write = False
self.alloc_on_readshared = True
self.alloc_on_readunique = False
self.alloc_on_readonce = True
self.alloc_on_writeback = True
self.alloc_on_atomic = True
self.dealloc_on_unique = True
self.dealloc_on_shared = False
self.dealloc_backinv_unique = False
self.dealloc_backinv_shared = False
```

---

## 现在，让我们创建层次结构

设置我们关心的参数（忽略其他参数）

```python
class PrivateL1SharedL2CacheHierarchy(AbstractRubyCacheHierarchy):
    """基于 CHI 的两级缓存
    """

    def __init__(self, l1_size: str, l1_assoc: int, l2_size: str, l2_assoc: int):
        self._l1_size = l1_size
        self._l1_assoc = l1_assoc
        self._l2_size = l2_size
        self._l2_assoc = l2_assoc
```

---

## 设置层次结构

记住，`incorporate_cache` 是我们需要实现的主要方法。大部分样板代码已经为您准备好了。

您应该添加代码来创建共享的 L2 缓存。

```python
def incorporate_cache(self, board):
    ...
    self.l2cache = SharedL2(
        size=self._l2_size,
        assoc=self._l2_assoc,
        network=self.ruby_system.network,
        cache_line_size=board.get_cache_line_size()
    )
    self.l2cache.ruby_system = self.ruby_system
    ...
```

---

## 接下来，让我们创建运行脚本

首先，让我们使用流量生成器。将以下代码放入 `run_test.py`

```python
from hierarchy import PrivateL1SharedL2CacheHierarchy

board = TestBoard(
    generator=LinearGenerator(num_cores=4, max_addr=2**22, rd_perc=75),
    cache_hierarchy=PrivateL1SharedL2CacheHierarchy(
        l1_size="32KiB", l1_assoc=8, l2_size="2MiB", l2_assoc=16,
    ),
    memory=SingleChannelDDR4_2400(size="2GB"),
    clk_freq="3GHz",
)
sim = Simulator(board)
sim.run()
```

---

## 测试新的层次结构并查看统计信息

```sh
> gem5-chi run_test.py
```

stats.txt

```text
simSeconds                               0.001000
...
board.processor.cores0.generator.readBW  2811101367.231156
board.processor.cores0.generator.writeBW 986163850.461362
board.processor.cores1.generator.readBW  2679838984.383712
board.processor.cores1.generator.writeBW 935348476.506769
board.processor.cores2.generator.readBW  2805533435.828071
board.processor.cores2.generator.writeBW 974899989.232133
board.processor.cores3.generator.readBW  2729054378.050062
board.processor.cores3.generator.writeBW 948724311.716480
```

---

## 现在，让我们运行全系统仿真

让我们创建一个脚本来运行 NPB 中的 IS。
只需将以下内容添加到 [`materials/03-Developing-gem5-models/07-chi-protocol/run-is.py`](../../materials/03-Developing-gem5-models/07-chi-protocol/run-is.py/) 中的模板。

```python
from hierarchy import PrivateL1SharedL2CacheHierarchy
cache_hierarchy = PrivateL1SharedL2CacheHierarchy(
    l1_size="32KiB",
    l1_assoc=8,
    l2_size="2MiB",
    l2_assoc=16,
)
```

---

## 运行脚本

```sh
gem5 run-is.py
```

您应该很快看到以下输出

```text
...
Work begin. Switching to detailed CPU
switching cpus
...
```

这大约需要 5 分钟完成，但您可以在运行时使用以下命令检查输出
`tail -f m5out/board.pc.com_1.terminal`。

---

## 获取一些统计信息

最后，让我们获取一些看起来有趣的统计信息（我们将在下一节中更多地使用这些信息）。

```text
board.cache_hierarchy.ruby_system.m_missLatencyHistSeqr::mean   185.561335
board.processor.switch0.core.commitStats0.ipc     0.149605
```

我们的平均缺失延迟为 185 个周期（很多 L2 缺失！），IPC 为 0.15。

### 注意：此示例尚未调试，可能存在 FS 问题

---

## 总结

- 我们使用 CHI 协议创建了一个简单的两级缓存层次结构
- 我们运行了一个简单的流量生成器和全系统仿真
- 我们了解了如何使用标准库在 gem5 中设置 CHI 协议
