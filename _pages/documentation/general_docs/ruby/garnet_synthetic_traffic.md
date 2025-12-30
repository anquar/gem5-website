---
layout: documentation
title: "Garnet 合成流量"
doc: gem5 documentation
parent: ruby
permalink: /documentation/general_docs/ruby/garnet_synthetic_traffic/
author: Jason Lowe-Power
---

# Garnet 合成流量

Garnet 合成流量提供了一个框架，用于模拟带有受控输入的 [Garnet 网络](/documentation/general_docs/ruby/garnet-2)。这对网络测试/调试，或带有合成流量的仅网络模拟非常有用。

**注意：garnet 合成流量注入器仅适用于 [Garnet_standalone](/documentation/general_docs/ruby/Garnet_standalone.md) 一致性协议。**

## 相关文件

* configs/example/garnet_synth_traffic.py: 调用网络测试器的文件
* src/cpu/testers/garnet_synthetic_traffic: 实现测试器的文件。
  * GarnetSyntheticTraffic.py
  * GarnetSyntheticTraffic.hh
  * GarnetSyntheticTraffic.cc

## 如何运行

首先使用 [Garnet_standalone](/documentation/general_docs/ruby/Garnet_standalone.md) 一致性协议构建 gem5。Garnet_standalone 协议与 ISA 无关，因此我们使用 NULL ISA 构建它。

对于 gem5 <= 23.0:

```
scons build/NULL/gem5.debug PROTOCOL=Garnet_standalone
```

对于 gem5 >= 23.1

```
scons defconfig build/NULL build_opts/NULL
scons setconfig build/NULL RUBY_PROTOCOL_GARNET_STANDALONE=y
scons build/NULL/gem5.debug
```

示例命令：

```
./build/NULL/gem5.debug configs/example/garnet_synth_traffic.py  \
        --num-cpus=16 \
        --num-dirs=16 \
        --network=garnet \
        --topology=Mesh_XY \
        --mesh-rows=4  \
        --sim-cycles=1000 \
        --synthetic=uniform_random \
        --injectionrate=0.01
```

## 参数化选项

| **系统配置** |  **描述**  |
|------------|-----------|
| **--num-cpus** | cpu 数量。这是网络中源（注入）节点的数量。 |
| **--num-dirs** | 目录数量。这是网络中目的地（弹出）节点的数量。 |
| **--network** | 网络模型：simple 或 garnet。使用 garnet 运行合成流量。 |
| **--topology** | 用于将 cpu 和 dirs 连接到网络路由器/交换机的拓扑。有关不同拓扑的更多详细信息可以在 (这里)[Interconnection_Network#Topology] 找到。 |
| **--mesh-rows** | 网格中的行数。仅当 ''--topology'' 为 ''Mesh_*'' 或 ''MeshDirCorners_*'' 时有效。 |



| **网络配置** | **描述** |
|------------|-----------|
| **--router-latency** | garnet 路由器中流水线级的默认数量。必须 >= 1。可以在拓扑文件中逐个路由器覆盖。 |
| **--link-latency** | 网络中每个链接的默认延迟。必须 >= 1。可以在拓扑文件中逐个链接覆盖。 |
| **--vcs-per-vnet** | 每个虚拟网络的 VC 数量。 |
| **--link-width-bits** | garnet 网络内所有链接的位宽。默认 = 128。 |



| **流量注入** | **描述** |
|------------|-----------|
| **--sim-cycles** | 模拟应运行的总周期数。 |
| **--synthetic** | 要注入的合成流量类型。目前支持以下合成流量模式：'uniform_random', 'tornado', 'bit_complement', 'bit_reverse', 'bit_rotation', 'neighbor', 'shuffle', 和 'transpose'。 |
| **--injectionrate** | 流量注入率，以 包/节点/周期 为单位。它可以取 0 到 1 之间的任何十进制值。小数点后的精度位数可以通过 ''--precision'' 控制，该参数在 ''garnet_synth_traffic.py'' 中默认为 3。 |
| **--single-sender-id** | 仅从此发送者注入。要从所有节点发送，请设置为 -1。 |
| **--single-dest-id** | 仅发送到此目的地。要发送到合成流量模式指定的所有目的地，请设置为 -1。 |
| **--num-packets-max** | 每个 cpu 节点要注入的最大数据包数。默认值为 -1（保持注入直到 sim-cycles）。 |
| **--inj-vnet** | 仅在此 vnet（0, 1 或 2）中注入。0 和 1 是 1-flit，2 是 5-flit。设置为 -1 以在所有 vnet 中随机注入。 |


## Garnet 合成流量的实现
合成流量注入器在 GarnetSyntheticTraffic.cc 中实现。生成和发送数据包所涉及的步骤序列如下。

* 每个周期，每个 cpu 执行一个概率等于 --injectionrate 的伯努利试验，以确定是否生成数据包。
* 如果 --num-packets-max 为非负数，每个 cpu 在生成 --num-packets-max 个数据包后停止生成新数据包。注入器在 --sim-cycles 后终止。
* 如果 cpu 必须生成新数据包，它会根据合成流量类型 (--synthetic) 计算新数据包的目的地。
* 此目的地嵌入到数据包地址中块偏移量之后的位中。
* 生成的数据包随机标记为 ReadReq、INST_FETCH 或 WriteReq，并发送到 Ruby 端口 (src/mem/ruby/system/RubyPort.hh/cc)。
* Ruby 端口将数据包分别转换为 RubyRequestType:LD、RubyRequestType:IFETCH 和 RubyRequestType:ST，并将其发送到 Sequencer，Sequencer 依次将其发送到 Garnet_standalone 缓存控制器。
* 缓存控制器从数据包地址中提取目的地目录。
* 缓存控制器分别将 LD、IFETCH 和 ST 注入虚拟网络 0、1 和 2。
  * LD 和 IFETCH 作为控制数据包（8 字节）注入，而 ST 作为数据数据包（72 字节）注入。
* 数据包遍历网络并到达目录。
* 目录控制器只是将其丢弃。
