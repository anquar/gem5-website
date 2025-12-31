---
layout: post
title:  "在 gem5 中对链接器进行基准测试"
author: Melissa Jost
date:   2023-02-16
categories: project
---
**tl;dr**：构建 gem5 时使用 [mold 链接器](<https://github.com/rui314/mold>) 以获得最快的链接时间

熟悉 gem5 的人都知道它的编译时间很长，尤其是在链接阶段。
当即使是微小的编辑也需要重新链接先前编译的文件时，这可能会变得令人沮丧。
这可能会增加几分钟的过程。
考虑到这一点，我们评估了一系列 gem5 当前支持的链接器，以确定哪一个最有效。

为了进行这些测试，我们仔细检查了 gem5 当前支持的每个链接器，包括当前默认链接器 "ld"。
评估的四个额外支持的链接器是 "lld"、"bfd"、"gold" 和 "mold"。

我们比较这些链接器的方法如下：我们首先通过执行 `scons build/ALL/gem5.opt` 正常构建 gem5。
一旦 `gem5.opt` 二进制文件被编译，我们删除它。
因此我们留下了编译的目标文件但没有链接的二进制文件。
然后，我们使用 `/usr/bin/time scons build/ALL/gem5.opt -j12 --linker=[linker-option]` 比较使用每个链接器重建/链接 gem5 的运行，其中 `/usr/bin/time` 测量持续时间。
我们在使用 AMD EPYC 7402P 24 核处理器（频率为 3.35 GHz）的系统上运行这些测试。

在这些测试期间，我们观察到在我们的实验设置中使用除默认 "ld" 之外的链接器强制重新编译所有 m5 文件。
但是，如果我们在之后删除 `gem5.opt` 二进制文件并再次运行编译，只有 `gem5.opt` 被重建/链接，导致两个不同的时间。
为了比较时间，我们需要考虑第一次运行构建所有 m5 文件所需的时间，以及第二次运行重新链接 gem5.opt 所需的时间。
这些在下面标记为 "all m5" 与 "last few"。
除了这两次运行之外，我们还在网络文件系统 (NFS) 和本地 SSD 上比较了每次运行，以查看文件的存储类型是否对运行时间有任何影响。
最后，我们在本地 SSD 上使用系统上的 48 个可用核心执行了最后一次运行，以评估是否有所不同。
下面，我们展示了每次运行的经过时间。

我们发现，在我们测试的四个链接器中，"bfd" 最慢，"mold" 最快。
此外，使用 `-j12` 和 `-j48` 之间的差异似乎微不足道。

根据我们的结果，我们建议在使用 gem5 时使用 "mold" 作为链接器。
值得注意的是，使用特定链接器对所用时间的影响比存储位置更显著。

|           | NFS + all m5  | NFS + last few    | Local SSD + all m5 | Local SSD + last few   | Local SSD + -j48 + last few    |
| :---:     | :---:         | :---:             | :---:              | :---:                  | :---:                          |
| ld        | ---           | 3:29.19           | ---                | 3:08.31                | 3:00.15                        |
| bfd       | 4:15.82       | 3:32.13           | 3:39.70            | 3:02.15                | 3:02.35                        |
| lld       | 2:16.22       | 1:54.25           | 1:52.94            | 1:13.12                | 1:13.16                        |
| gold      | 2:30.98       | 1:43.59           | 1:59.41            | 1:19.86                | 1:19.48                        |
| mold      | 1:48.62       | 1:07.08           | 1:08.18            | 0:28.23                | 0:27.89                        |

除了仅比较构建时间之外，我们还为每个链接的编译执行了 100000000 个 tick，以确保使用这些链接器在实际使用 gem5 时不会引起任何问题，例如增加执行时间或功能问题。

我们通过使用 O3 CPU 和 Ruby 缓存执行 x86 linux 启动来实现这一点。执行此操作的命令如下所示。

命令：

```sh
/usr/bin/time build/ALL/gem5.opt -re tests/gem5/configs/x86_boot_exit_run.py --cpu o3 --num-cpus 2 --mem-system mesi_two_level --dram-class DualChannelDDR4_2400 --boot-type init --resource-directory tests/gem5/resources --tick-exit 100000000
```

我们发现没有任何链接器对任何测试的运行时间有显著影响，所有测试都成功完成。
这表明使用链接器不应该对在 gem5 内进行的实验产生任何不利影响。

根据我们的发现，我们可以自信地推荐使用 [mold 链接器](<https://github.com/rui314/mold>) 来加速构建 gem5 时的链接时间。
如果您有兴趣使用 mold，可以按照[这里](<https://github.com/rui314/mold#how-to-build>)的说明进行编译。
一旦正确安装，您可以在构建 gem5 时通过传递 `--linker=mold` 来使用它。

这是一个示例命令：`scons build/ALL/gem5.opt -j12 --linker=mold`。
