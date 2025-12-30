---
layout: documentation
title: Ruby 随机测试器
doc: gem5 documentation
parent: directed_testers
permalink: /documentation/general_docs/debugging_and_testing/directed_testers/ruby_random_tester/
author: Bobby R. Bruce
---

# Ruby 随机测试器

缓存一致性协议通常有几种不同类型的状态
机，状态机有几种不同的状态。例如，
`MESI CMP` 目录协议有四种不同的状态机（`L1`、`L2`、
`directory`、`dma`）。测试这样的协议的功能正确性是一个
具有挑战性的任务。gem5 提供了一个随机测试器来测试一致性
协议。它被称为 Ruby 随机测试器。与测试器相关的源文件
位于目录 `src/cpu/testers/rubytest` 中。文件
`configs/examples/ruby_random_test.py` 用于配置和执行
测试。例如，以下命令可用于测试
协议：

```bash
./build/NULL/gem5.fast ./configs/example/ruby_random_test.py
```

Note: As of gem5 v24.1, the above command will not work if the ALL build is used.

Though one can specify many different options to the random tester, some of
them are note worthy.

|Parameter         |Description                                                       |
|:-----------------|:-----------------------------------------------------------------|
|`-n`, `--num-cpus`|Number of cpus injecting load/store requests to the memory system.|
|`--num-dirs`      |Number of directory controllers in the system.                    |
|`-m`, `--maxtick` |Number of cycles to simulate.                                     |
|`-l`, `--checks`  |Number of loads to be performed.                                  |
|`--random_seed`   |Seed for initialization of the random number generator.           |

Testing a coherence protocol with the random tester is a tedious task and
requires patience. First, build gem5 with the protocol to be tested. Then, run
the ruby random tester as mentioned above. Initially one should run the tester
with a single processor, and few loads. It is likely that one would encounter
problems. Use the debug flags to get a trace of the events ocurring in the
system. You may find the flag `ProtocolTrace` particularly useful. As these are
rectified, keep on increasing the number of loads, say by a factor of 10 each
time till one can execute one to ten million loads. Once it starts working for
a single processor, a similar process now needs to be followed for a two
processor system, followed by larger systems.

Theoretical approaches exist for [verifying coherence protocols](
https://doi.org/10.1145/248621.248624), but gem5 currently does not include any
testers based on those.
