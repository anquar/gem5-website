---
layout: bootcamp
title: gem5/SST 集成
permalink: /bootcamp/other-simulators/sst
section: other-simulators
---
<!-- _class: title -->

## gem5/SST 集成

---

## 第一步：安装 SST

我们今天不会做这个。

相反，我们将使用一个安装了 sst 的 docker 容器。

运行以下命令进入 docker 容器。
注意：你不应该像这样交互式地使用容器，但我很懒。

```sh
cd /workspaces/2024
docker run --rm --volume
/workspaces/:/workspaces -w `pwd` ghcr.io/gem5/sst-env
```

---

## gem5 作为库：Hello, World!

要在 SST 中将 gem5 用作"组件"，你需要将其构建为库。
这是另一个独特的构建目标...
注意：如果你在 Mac 上构建，它不是 ".so" 而是 ".dynlib"

将 gem5 编译为库

```bash
cd gem5/
scons defconfig build/for_sst build_opts/RISCV
scons build/for_sst/libgem5_opt.so -j8 --without-tcmalloc --duplicate-sources
```

---

## 在 gem5 中构建 gem5 组件

编译 gem5 组件

```bash
cd ext/sst
cp Makefile.linux Makefile
```

将包含 `ARCH=RISCV` 的行改为 `ARCH=for_sst`

```sh
make -j8
```

运行模拟，

```bash
sst --add-lib-path=. sst/example.py
```

---

## gem5 作为库：实例化

![Diagram showing how gem5 interacts with other simulators w:900px](/bootcamp/05-Other-simulators/01-sst/instantiation-1.drawio.svg)

---

## gem5 作为库：实例化

![Diagram showing how gem5 interacts with other simulators w:900px](/bootcamp/05-Other-simulators/01-sst/instantiation-2.drawio.svg)

---

## gem5 作为库：实例化

![Diagram showing how gem5 interacts with other simulators w:900px](/bootcamp/05-Other-simulators/01-sst/instantiation-3.drawio.svg)

---

## gem5 作为库：实例化

![Diagram showing how gem5 interacts with other simulators w:900px](/bootcamp/05-Other-simulators/01-sst/instantiation-4.drawio.svg)

---


## gem5 作为库

如何在另一个模拟器中设置 gem5？

* 步骤 1：设置 gem5 Python 环境。
    * 需要手动导入 m5 模块
* 步骤 2：读取 gem5 Python 系统配置文件。
    * 这包括为 gem5 和其他模拟器设置通信数据路径


* 注意事项：
    * `m5.instantiate()` 必须在任何模拟之前调用。
    * `m5.simulate(K)` 运行 gem5 模拟 `K` 个时钟周期。

---

## gem5 作为库：模拟

![Diagram showing how gem5 interacts with other simulators w:900px](/bootcamp/05-Other-simulators/01-sst/simulation.drawio.svg)

---

## gem5 作为库：模拟

对于每个外部模拟器时钟周期：

```python
external_simulator.advance_to_next_event()
gem5_system.advance(n_ticks)
```

其中 `n_ticks` = 此事件与外部模拟器上一个事件之间的时间差

---

## 案例研究：gem5/SST 集成

SST：结构模拟工具包
http://sst-simulator.org/

* 一个高度并行化的离散事件模拟器。
* 由以下部分组成：
    * SST-Core（模拟器）
    * SST-Elements（组件）
    * SST-Macro

---

## SST：简要概述

* 模拟对象：
    * SST::Component（类似于 gem5::SimObject）
    * SST::Link（允许两个组件相互发送 SST::Event）
        * 双向
    * SST::Event（类似于 gem5::Event）
        * 通过 SST::Link 发送

* 并行化：
    * SST 将组件分区到多个分区。
    * 分区之间的通信通过 MPI 完成。
    * 分区过程可以自动或手动完成

---

## gem5/SST 集成

![Diagram showing how gem5 interacts with other simulators w:800px](/bootcamp/05-Other-simulators/01-sst/integration-1.drawio.svg)

---

## gem5/SST 集成

![Diagram showing how gem5 interacts with other simulators w:800px](/bootcamp/05-Other-simulators/01-sst/integration-2.drawio.svg)

---

## gem5/SST 集成

* gem5 提供：
    * OutgoingRequestBridge：一个向外部组件发送请求的 Request 端口。
    * SSTResponderInterface：用于外部组件的 Response 端口的接口。
* gem5 Component 是一个 SST::Component，它有多个实现 SSTReponderInterface 的 SSTResponder。
* 数据包转换发生在 gem5 Component 内部。

---

## gem5/SST 集成

![Snoop protocol](/bootcamp/05-Other-simulators/01-sst/sst.drawio.svg)

---

## gem5/SST 集成

* 示例（arm 和 RISC-V）：
    * gem5 作为 SST 组件：gem5/ext/sst/
    * SST 系统配置：gem5/ext/sst/sst/example.py
    * gem5 系统配置：gem5/configs/example/sst/riscv_fs.py
* 系统设置：
    * SST 驱动模拟。
    * 一个 gem5 组件，包含 4 个详细核心。
    * 缓存和内存是来自 SST-Elements 的 SST::Components。

---

## gem5/SST 集成

* 系统设置：
    * SST 驱动全系统模拟。
    * 一个 gem5 组件，包含 4 个详细核心。
    * 缓存和内存是来自 SST-Elements 的 SST::Components。
* 限制：
    * gem5 核心在每个 CPU 时钟周期频繁唤醒。
    * 由于缓存一致性协议，核心频繁同步。
    * 块设备需要额外的工作才能运行。

---

## gem5/SST 集成

* 但是，我们可以设置多节点模拟。
* 如何实现？
    * 拥有多个 gem5 组件，每个代表一个节点。
    * 每个 gem5 组件位于不同的分区中。
    * gem5 实例之间的通信可以通过 gem5 PIO 设备完成。
* 为什么？
    * 在节点粒度上有更多的并行性。

---

## 其他注意事项

* SST 有自己的 Python 环境，因此 SST 中的 gem5 不应再次初始化 Python 环境。
* 但是，应该手动导入 m5 和 gem5 库。
* m5 库有一个函数可以根据 SimObject 名称查找 SimObject。
    * 对于在外部模拟器中查找端口的拥有者很有用。

---

## 文档

* 设置
    * gem5/ext/sst/README.md
* gem5 与外部模拟器通信的接口，
    * gem5/src/sst
* gem5 作为外部库中的组件，
    * gem5/ext/sst
* 将引导加载程序 + 内核 + 自定义工作负载编译为二进制文件，
    * https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/stable/src/riscv-boot-exit-nodisk/README.md
