---
layout: bootcamp
title: 使用 DRAMSim 和 DRAMSys 扩展 gem5
permalink: /bootcamp/other-simulators/dram
section: other-simulators
---
<!-- _class: title -->

## 使用 DRAMSim 和 DRAMSys 扩展 gem5


---

## 端口是与其他模拟器交互的有用接口

---

## 为什么使用外部模拟器？

> 注意：我不建议使用外部 DRAM 模拟器。
> gem5 的 DRAM 模型对于大多数研究来说已经足够准确

使用外部 DRAM 模拟器的主要原因有：

- 用于比较 gem5 的 DRAM 模型与其他模拟器（例如，在为 gem5 开发新的 DRAM 模型时）
- 当您已经修改了其他模拟器并需要使用真实的流量来驱动它时

---

## 获取 DRAMSys

详情请参见 [`gem5/ext/dramsys/README`](https://github.com/gem5/gem5/blob/stable/ext/dramsys/README)。

运行

```sh
cd ext/dramsys
git clone https://github.com/tukl-msd/DRAMSys --branch v5.0 --depth 1 DRAMSys
```

---

## 构建 DRAMSys

将 DRAMSys 仓库添加到 `ext/dramsys` 后，它将自动构建到 gem5 中。

```sh
scons build/NULL/gem5.opt -j$(nproc)
```

---

## 使用 DRAMSys

关于 DRAMSys 的文档，请参见 <https://github.com/tukl-msd/DRAMSys>

要配置 gem5 使用 DRAMSys，您可以使用标准库。
DRAMSys 可以作为 `MemorySystem` 使用，就像 `SingleChannel` 或 `MultiChannel` 内存一样。

打开 [`materials/05-Other-simulators/02-dram/dramsys-example.py`](https://github.com/gem5bootcamp/2024/blob/main/materials/05-Other-simulators/02-dram/dramsys-example.py)。

添加以下行以使用 DRAMSys 创建带有 DDR4 的内存系统

```python
memory = DRAMSysMem(
    configuration="/workspaces/2024/gem5/ext/dramsys/DRAMSys/configs/ddr4-example.json",
    recordable=True,
    resource_directory="/workspaces/2024/gem5/ext/dramsys/DRAMSys/configs",
    size="4GB",
)
```

---

## 配置 DRAMSys

DRAMSys 的选项：

- `configuration`：请参见 [`gem5/ext/dramsys/DRAMSys/configs/`](https://github.com/gem5/gem5/blob/stable/ext/dramsys/DRAMSys/configs/) 以查看提供的配置。
  - 必须是绝对路径或相对于运行路径的路径。
- `resource_directory`：指向配置目录的指针。
  - 必须是绝对路径或相对于运行路径的路径。
- `recordable`：DRAMSys 是否应记录跟踪文件

### 实现说明

- DRAMSys 使用 TLM 2.0
- 这是如何让 gem5 与 TLM 对象通信的一个很好的示例。

---

## DRAMSys 输出

```sh
../https://github.com/gem5/gem5/blob/stable/build/NULL/gem5.opt dramsys-example.py
```

```test
board.memory.dramsys.DRAMSys.controller0  Total Time:     250027920 ps
board.memory.dramsys.DRAMSys.controller0  AVG BW:          87.97 Gb/s |  11.00 GB/s |  73.67 %
board.memory.dramsys.DRAMSys.controller0  AVG BW\IDLE:     87.97 Gb/s |  11.00 GB/s |  73.67 %
board.memory.dramsys.DRAMSys.controller0  MAX BW:         119.40 Gb/s |  14.93 GB/s | 100.00 %
```

输出一个文件 `board.memory.dramsys.DRAMSys_ddr4-example_example_ch0.tdb`，这是一个数据库跟踪文件。

> 不使用 gem5 的统计输出！

---

## DRAMSim

在获取和使用方式上与 DRAMSys 类似

> 注意：DRAMSim3 没有定期测试

详情请参见 [`gem5/ext/dramsim3/README`](https://github.com/gem5/gem5/blob/stable/ext/dramsim3/README)。

要获取 DRAMsim，请运行以下代码并重新编译 gem5。

```sh
cd ext/dramsim3
git clone clone git@github.com:umd-memsys/DRAMsim3
cd DRAMsim3
mkdir build
cd build
cmake ..
make -j$(nproc)
```

---

## 使用 DRAMSim3

在 `gem5.components.memory.dramsim_3` 中有可用的单通道配置。

```python
from gem5.components.memory.dramsim_3 import SingleChannelHBM
```

```python
memory = SingleChannelHBM(size="1GiB")
```

您可以使用该模块中的 `SingleChannel` 扩展其他内存类型。

查找 DRAMSim 配置列表：[`gem5/ext/dramsim3/DRAMsim3/configs`](https://github.com/gem5/gem5/blob/stable/ext/dramsim3/DRAMsim3/configs)

```python
SingleChannel(<memory type from configs>, <size>)
```

---

## 注意：DRAMSim3 不适用于 v24.0.0.0！
