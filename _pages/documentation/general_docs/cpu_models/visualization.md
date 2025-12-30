---
layout: documentation
title: "可视化"
doc: gem5 documentation
parent: cpu_models
permalink: /documentation/general_docs/cpu_models/visualization/
---

# 可视化
本页面包含有关集成的或可与 gem5 一起使用的不同类型信息可视化的信息。

## O3 流水线查看器
o3 流水线查看器是乱序 CPU 流水线的基于文本的查看器。它显示指令何时被取指 (f)、解码 (d)、重命名 (n)、分派 (p)、发出 (i)、完成 (c) 和退休 (r)。这对于理解流水线在合理的代码小序列中在哪里停顿或挤压非常有用。在环绕的彩色查看器旁边是当前指令退休的 tick、该指令的 pc、它的反汇编以及该指令的 o3 序列号。

![o3pipeviewer](/assets/img/O3pipeview.png)

要生成您在上面看到的输出行，您首先需要使用 o3 cpu 运行实验：

```./build/ARM/gem5.opt --debug-flags=O3PipeView --debug-start=<first tick of interest> --debug-file=trace.out configs/example/se.py --cpu-type=detailed --caches -c <path to binary> -m <last cycle of interest>```

然后您可以运行脚本以生成类似于上面的 trace（在本例中 500 是每个时钟 (2GHz) 的 tick 数）：

```./util/o3-pipeview.py -c 500 -o pipeview.out --color m5out/trace.out```

您可以通过将文件通过 less 管道传输来查看彩色输出：

```less -r pipeview.out```

当 CYCLE_TIME (-c) 错误时，输出中的右方括号可能无法对齐到同一列。CYCLE_TIME 的默认值为 1000。请小心。

该脚本有一些额外的集成帮助：（键入 ‘./util/o3-pipeview.py --help’ 获取帮助）。

## Minor 查看器
关于 minor 查看器的 [新页面](minor_view) 尚未制作，请参阅 [旧页面](http://pages.cs.wisc.edu/~swilson/gem5-docs/minor.html#trace) 以获取文档。
