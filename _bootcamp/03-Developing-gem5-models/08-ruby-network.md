---
layout: bootcamp
title: 使用 Garnet 建模片上网络
permalink: /bootcamp/developing-gem5/ruby-network
section: developing-gem5
---
<!-- _class: title -->

## 使用 Garnet 建模片上网络

---

## Ruby 回顾

- **控制器模型** *(例如，缓存)*: 管理一致性状态并发出请求
- **控制器拓扑** *(缓存如何连接)*: 决定消息如何路由
- **互连模型** *(例如，片上路由器)*: 决定路由性能
- **接口** *(如何将消息传入/传出 Ruby)*

![Inside Ruby: controllers around an interconnect model cloud bg right fit](/bootcamp/03-Developing-gem5-models/06-modeling-cache-coherence-imgs/ruby-inside.drawio.svg)

---

## 片上网络

由**拓扑**和**互连**模型组成

### 拓扑

在 Python 配置中指定路由器/交换机如何连接

### 互连

- Simple: 快速，只能更改链路带宽/延迟
- Garnet: 详细的路由器、流控制和链路架构模型

首先我们将创建一个新的拓扑（环形），然后扩展它以使用 Garnet。

---

## 创建新拓扑

来自[缓存一致性建模](06-modeling-cache-coherence.md)
每个控制器和路由器之间需要一个*外部链路*。

```python
self.routers = [
    Switch(router_id = i)
    for i in range(len(controllers))
]
self.ext_links = [
    SimpleExtLink(
        link_id=i, ext_node=c,
        int_node=self.routers[i])
    for i, c in enumerate(controllers)
]
```

![diagram showing cache/directory controllers connected to routers  bg right fit](/bootcamp/03-Developing-gem5-models/08-ruby-network-imgs/router-links-1.drawio.svg)

---

## 创建新拓扑

来自[缓存一致性建模](06-modeling-cache-coherence.md)
在路由器之间创建内部链路。

```python
for ri in self.routers:
    for rj in self.routers:
        # 不要将路由器连接到自身！
        if ri == rj: continue
        link_count += 1
        self.int_links.append(
            SimpleIntLink(
                link_id = link_count,
                src_node=ri, dst_node=rj
            )
        )
```

![diagram showing cache/directory controllers connected to routers and routers connected with links bg right fit](/bootcamp/03-Developing-gem5-models/08-ruby-network-imgs/router-links-2.drawio.svg)

---

## 让我们为 CHI 协议创建一个环形拓扑

基于[CHI 协议](07-chi-protocol.md)构建

![diagram showing a ring topology with four cores, two memory controllers and two L2s](/bootcamp/03-Developing-gem5-models/08-ruby-network-imgs/ring.drawio.svg)

---

## 创建拓扑文件

打开 [https://github.com/gem5bootcamp/2024/blob/main/materials/03-Developing-gem5-models/08-ruby-network/ring.py](https://github.com/gem5bootcamp/2024/blob/main/materials/03-Developing-gem5-models/08-ruby-network/ring.py)

注意：这段代码中有很多奇怪的地方。大部分内容，你只需要相信我的话...

---

## 扩展 `SimpleNetwork` 类

```python
class Ring(SimpleNetwork):
    def __init__(self, ruby_system):
        super().__init__()
        self.netifs = []
        self.ruby_system = ruby_system
```

注意 netifs 仅用于 Garnet。此外，必须手动设置 `ruby_system`。

---

## `connectControllers` 方法

这是创建拓扑核心内容的地方。
在我们的例子中，我们将使这个拓扑非常具体。

重要提示：拓扑的布局与核心数量、L2 缓存组、内存控制器等密切相关。

例如，考虑一下如何布局网格拓扑。

```python
def connectControllers(
    self, l1i_ctrls, l1d_ctrls, l2_ctrls, mem_ctrls, dma_ctrls
):
    assert len(l1i_ctrls) == 4
    assert len(l1d_ctrls) == 4
    assert len(l2_ctrls) == 2
    assert len(mem_ctrls) == 2
```

---

## 为 L1D 和 L1I 缓存创建路由器

L1I 和 L1D 可以共享同一个路由器。L2 缓存有自己独立的路由器。

```python
self.l1_routers = [Switch(router_id=i) for i in range(4)]
self.l1i_ext_links = [
    SimpleExtLink(link_id=i, ext_node=c, int_node=self.l1_routers[i])
    for i, c in enumerate(l1i_ctrls)
]
self.l1d_ext_links = [
    SimpleExtLink(link_id=4+i, ext_node=c, int_node=self.l1_routers[i])
    for i, c in enumerate(l1d_ctrls)
]
```

注意：`link_id` 很重要。你必须手动递增它，并确保每种类型的 id 都是唯一的。
就像很多事情一样，可能有更好的方法，但这就是它的实现方式...

---

## 为 L2 缓存和内存创建路由器

```python
self.l2_routers = [Switch(router_id=4+i) for i in range(2)]
self.l2_ext_links = [
    SimpleExtLink(link_id=8+i, ext_node=c, int_node=self.l2_routers[i])
    for i, c in enumerate(l2_ctrls)
]

self.mem_routers = [Switch(router_id=6+i) for i in range(2)]
self.mem_ext_links = [
    SimpleExtLink(link_id=10+i, ext_node=c, int_node=self.mem_routers[i])
    for i, c in enumerate(mem_ctrls)
]
```

不要忘记链路 id！

---

## 最后，如果我们在 FS 模式下运行，需要 DMA

```python
if dma_ctrls:
    self.dma_ext_links = [
        SimpleExtLink(
            link_id=12+i, ext_node=c, int_node=self.mem_routers[0]
        )
        for i, c in enumerate(dma_ctrls)
    ]
```

---

## 创建内部链路

这是我们创建环形拓扑的地方。
为了有所不同，让我们做一个单向环形。

```python
self.int_links = [
    SimpleIntLink(
        link_id=0,
        src_node=self.l1_routers[0],
        dst_node=self.l1_routers[1],
    ),
    SimpleIntLink(
        link_id=1,
        src_node=self.l1_routers[1],
        dst_node=self.mem_routers[0],
    ),
...
```

![diagram showing a ring topology with four cores, two memory controllers and two L2s bg right fit](/bootcamp/03-Developing-gem5-models/08-ruby-network-imgs/ring.drawio.svg)

---

## 更多样板代码

我们必须告诉父网络类我们的链路和路由器。它需要成员变量 `routers`、`ext_links` 和 `int_links`。

```python
self.ext_links = (
    self.l1i_ext_links
    + self.l1d_ext_links
    + self.l2_ext_links
    + self.mem_ext_links
    + getattr(self, "dma_ext_links", [])
)
self.routers = (
    self.l1_routers
    + self.l2_routers
    + self.mem_routers
)
```

---

## 测试结果

```sh
gem5 run-test.py
```

```text
board.processor.cores0.generator.readBW  2095164513.646249
board.processor.cores1.generator.readBW  2219964305.979394
board.processor.cores2.generator.readBW  2057532576.265793
board.processor.cores3.generator.readBW  2124156465.403641
```

注意：这比我们看到的点对点连接低近 10%！

---

<!-- _class: two-col -->

## 想法！交换 L2 和内存的位置

```python
    dst_node=self.l2_routers[0],
),
SimpleIntLink(
    link_id=2,
    src_node=self.l2_routers[0],
    dst_node=self.mem_routers[0],
),
SimpleIntLink(
    link_id=3,
    src_node=self.mem_routers[0],
    dst_node=self.l1_routers[2],
```

```python
SimpleIntLink(
    link_id=5,
    src_node=self.l1_routers[3],
    dst_node=self.l2_routers[1],
),
SimpleIntLink(
    link_id=6,
    src_node=self.l2_routers[1],
    dst_node=self.mem_routers[1],
),
SimpleIntLink(
    link_id=7,
    src_node=self.mem_routers[1],
```

---

## 再次运行

```sh
gem5 run-test.py
```

```text
board.processor.cores0.generator.readBW  2370664319.434113
board.processor.cores1.generator.readBW  2472807299.127889
board.processor.cores2.generator.readBW  2414887877.684990
board.processor.cores3.generator.readBW  2504614981.400951
```

---

<!-- _class: start -->

## Garnet

---

<!-- _class: two-col -->

## Simple vs Garnet

### 路由器微架构

- Switch: Simple 网络
  - 路由器延迟
  - 虚拟通道数量
- Garnet Router: Garnet 网络
  - 虚拟通道数量
  - 虚拟网络数量
  - 数据片（流控制单元）大小

### 链路微架构

- Simple 网络:
  - 仅指定"带宽因子"
- Garnet 网络:
  - 数据链路和流控制链路分开：网络链路和信用链路
  - 支持时钟域交叉
  - 串行化和反串行化
  - 链路宽度

---

## 路由

- 基于表的路由
  - 最短路径
  - 选择链路遍历次数最少的路径
  - 链路权重影响路由
- 自定义路由算法

---

## Garnet 扩展

- 时钟域交叉
  - 如果外部和内部链路以不同频率运行，应为 `GarnetExtLink` 启用此功能
  - 如果两个内部链路具有不同频率，应为 `GarnetIntLink` 启用此功能
- 串行化和反串行化
  - 如果外部链路的数据片大小与 `GarnetExtLink` 的内部链路不同，则需要此功能
  - 如果两个内部链路的数据片大小不同，则 `GarnetIntLink` 需要此功能
- 时钟域的信用链路和桥接器会自动创建

---

## 示例？

... 不幸的是，这不起作用。但我有一个变通方法...

肯定有某个地方的缓冲区正在填满，导致死锁。

问题是我不能确定是在网络、协议还是其他地方。

使用 Ruby 和 Garnet 时就是这样！

---

## Garnet 的更改

1. 复制 `ring.py`

```sh
cp ring.py ring_garnet.py
```

2. 更改 `hierarchy.py` 以使用 `ring_garnet`，并删除以下行

```diff
-     self.ruby_system.network.setup_buffers()
```

3. 在 `ring_garnet.py` 中进行以下替换

- `SimpleNetwork` -> `GarnetNetwork`
- `SimpleExtLink` -> `GarnetExtLink`
- `SimpleIntLink` -> `GarnetIntLink`

---

## 还有一个更改（以及一个变通方法）

还要在 `Ring.connectControllers` 中添加以下内容

```python
self.netifs = [GarnetNetworkInterface(id=i) \
            for (i,n) in enumerate(self.ext_links)]
```

在构造函数中添加以下内容以绕过死锁。

```python
# 如果我必须这样做才能让它工作，肯定有什么地方出了问题。
self.ni_flit_size = 64
self.vcs_per_vnet = 16
```

---

## 现在，再次运行测试！

```sh
gem5 run-test.py
```

```text
board.processor.cores0.generator.readBW  3248115023.780479
board.processor.cores1.generator.readBW  3149747416.759070
board.processor.cores2.generator.readBW  3317362747.135825
board.processor.cores3.generator.readBW  3113523561.473372
```

注意：使用 Garnet 进行模拟比使用 `SimpleNetwork` 需要更长的时间。
更高的保真度意味着更长的模拟时间！
