---
layout: documentation
title: Trace CPU 模型
parent: cpu_models
doc: gem5 documentation
permalink: /documentation/general_docs/cpu_models/TraceCPU
---
# **TraceCPU**
 目录


1. [概述](##Overveiw)


 1. [Elastic Trace 生成](##Elastic-Trace-Generation)
       1. [脚本和选项](##Scripts-and-options)
       2. [Trace 文件格式](###Trace-file-formats)





 2. [使用 Trace CPU 回放](#replay-with-trace-cpu)
       1. [脚本和选项](##Scripts-and-options)




## **概述**
Trace CPU 模型回放弹性 trace (elastic traces)，这是由附加到 O3 CPU 模型的 Elastic Trace Probe 生成的带有依赖关系和时序注释的 trace。Trace CPU 模型的重点是以快速且相当准确的方式实现内存系统（缓存层次结构、互连和主存）性能探索，而不是使用详细但缓慢的 O3 CPU 模型。这些 trace 是为在 SE 和 FS 模式下模拟的单线程基准测试开发的。通过将 Trace CPU 与经典内存系统接口并改变缓存设计参数和 DRAM 内存类型，它们已针对 15 个内存敏感的 SPEC 2006 基准测试和少数 HPC 代理应用程序进行了关联。一般来说，弹性 trace 可以移植到其他模拟环境。

 **出版物**:

[Exploring System Performance using Elastic Traces: Fast, Accurate and Portable"](https://ieeexplore.ieee.org/document/7818336) Radhika Jagtap, Stephan Diestelhorst, Andreas Hansson, Matthias Jung and Norbert Wehn SAMOS 2016

**Trace 生成和回放方法**

![显示使用 O3 CPU 生成弹性 trace 和使用 Trace CPU 回放的方法框图
](/assets/img/Etrace_methodology.jpg)

## **Elastic Trace 生成**
Elastic Trace Probe Listener 监听插入在 O3 CPU 流水线阶段的 Probe Points。它监视每条指令并通过记录数据读后写依赖关系以及加载和存储之间的顺序依赖关系来创建依赖关系图。它将指令获取请求 trace 和弹性数据内存请求 trace 写入两个单独的文件，如下所示。

![Elastic trace 文件生成](/assets/img/Etraces_output.jpg)

### **Trace 文件格式**

弹性数据内存 trace 和获取请求 trace 都使用 google protobuf 编码。

##### **protobuf 格式的 Elastic Trace 字段**

字段    | 描述
-------------- | -------------
required uint64 seq_num &nbsp;   | 用作跟踪依赖关系的 id 的指令编号
required RecordType type &nbsp;    | RecordType 枚举具有值：INVALID, LOAD, STORE, COMP
optional uint64 p_addr &nbsp; 	| 如果指令是加载/存储，则为物理内存地址
optional uint32 size &nbsp; 	| 如果指令是加载/存储，则为数据的大小（以字节为单位）
optional uint32 flags &nbsp; 	| 	访问的标志或属性，例如 Uncacheable
required uint64 rob_dep &nbsp;  |   存在顺序 (ROB) 依赖关系的过去指令编号
required uint64 comp_delay &nbsp;       |	最后一个依赖项完成与指令执行之间的执行延迟 &nbsp;
repeated uint64 reg_dep &nbsp;              | 存在 RAW 数据依赖关系的过去指令编号
optional uint32 weight &nbsp; | 	用于计算被过滤掉的已提交指令
optional uint64 pc &nbsp; | 指令地址，即程序计数器
optional uint64 v_addr &nbsp; | 	如果指令是加载/存储，则为虚拟内存地址
optional uint32 asid &nbsp; | 地址空间 ID

Python 中的解码脚本可在 `util/decode_inst_dep_trace.py` 获得，该脚本以 ASCII 格式输出 trace。

**ASCII trace 示例**

    1,356521,COMP,8500::

    2,35656,1,COMP,0:,1:

    3,35660,1,LOAD,1748752,4,74,500:,2:

    4,35660,1,COMP,0:,3:

    5,35664,1,COMP,3000::,4

    6,35666,1,STORE,1748752,4,74,1000:,3:,4,5

    7,35666,1,COMP,3000::,4

    8,35670,1,STORE,1748748,4,74,0:,6,3:,7

    9,35670,1,COMP,500::,7

指令获取 trace 中的每条记录都具有以下字段。

字段    | 描述
-------------- | -------------
required uint64 tick &nbsp;   |	访问的时间戳
required uint32 cmd	&nbsp;    | 读取或写入（在这种情况下始终为读取）
required uint64 addr &nbsp;	| 物理内存地址
required uint32 size &nbsp;	| 数据的大小（以字节为单位）
optional uint32 flags &nbsp;	| 访问的标志或属性
optional uint64 pkt_id &nbsp;  |   访问的 Id
optional uint64 pc  &nbsp;     |	指令地址，即程序计数器



Python 中的解码脚本 `util/decode_packet_trace.py` 可用于以 ASCII 格式输出 trace。


**编译依赖项**:

您需要安装 google protocol buffer，因为 trace 是使用它记录的。

```sh

sudo apt-get install protobuf-compiler
sudo apt-get install libprotobuf-dev

```

### **脚本和选项**
#### SE 模式
```
build/ARM/gem5.opt configs/example/arm/etrace_se.py \
    --inst-trace-file fetchtrace.proto.gz \
    --data-trace-file deptrace.proto.gz \
    [WORKLOAD]
```
#### FS 模式
为您感兴趣的区域创建检查点，并从检查点恢复，但启用 O3 CPU 模型和 trace。
```
# 检查点生成
# 注意：fs.py 已被弃用并将被删除。不要太依赖它
build/ARM/gem5.opt --outdir=m5out/bbench \
    ./configs/deprecated/example/fs.py [fs.py options] \
    --benchmark bbench-ics
```
```
# 检查点恢复
# 注意：fs.py 已被弃用并将被删除。不要太依赖它
build/ARM/gem5.opt --outdir=m5out/bbench/capture_10M \
    ./configs/deprecated/example/fs.py [fs.py options] \
    --cpu-type=arm_detailed --caches \
    --elastic-trace-en --data-trace-file=deptrace.proto.gz --inst-trace-file=fetchtrace.proto.gz \
    --mem-type=SimpleMemory \
    --checkpoint-dir=m5out/bbench -r 0 --benchmark bbench-ics -I 10000000
```

## **使用 Trace CPU 回放**

上面生成的执行 trace 然后由 Trace CPU 消耗，如下图所示。

![Trace_cpu_top_level](/assets/img/Trace_cpu_top_level.jpg)

Trace CPU 模型继承自 Base CPU，并与数据和指令 L1 缓存接口。解释主要逻辑和控制块的 Trace CPU 图如下所示。

![Trace_CPU_details](/assets/img/Trace_cpu_detail.jpg)

### **脚本和选项**

* 示例文件夹中的 trace 回放脚本可用于回放 SE 和 FS 生成的 trace
    * `build/ARM/gem5.opt [gem5.opt options] -d bzip_10Minsts_replay configs/example/etrace_replay.py [options] --caches --data-trace-file=bzip_10Minsts/deptrace.proto.gz --inst-trace-file=bzip_10Minsts/fetchtrace.proto.gz --mem-size=4GB`






字段    | 描述
-------------- | -------------
required uint64 seq_num    |	访问的时间戳
required RecordType type    | 读取或写入（在这种情况下始终为读取）
optional uint64 p_addr	| 如果指令是加载/存储，则为物理内存地址
optional uint32 size	| 如果指令是加载/存储，则为数据的大小（以字节为单位）
optional uint32 flags	| 访问的标志或属性，例如 Uncacheable
required uint64 rob_dep | 存在顺序 (ROB) 依赖关系的过去指令编号
required uint64 comp_delay | 最后一个依赖项完成与指令执行之间的执行延迟
repeated uint64 reg_dep | 存在 RAW 数据依赖关系的过去指令编号
optional uint32 weight | 用于计算被过滤掉的已提交指令
optional uint64 pc	| 指令地址，即程序计数器
optional uint64 v_addr | 如果指令是加载/存储，则为虚拟内存地址
optional uint32 asid |	地址空间 ID
