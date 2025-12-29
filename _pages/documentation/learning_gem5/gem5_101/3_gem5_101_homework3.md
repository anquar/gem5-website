---
layout: documentation
title: CS 752 作业 3
doc: Learning gem5
parent: gem5_101
permalink: /documentation/learning_gem5/gem5_101/homework-3
authors:
---

# CS 752: 高级计算机体系结构 I 作业 3 (2015 年秋季 1 组)

**截止日期：9/29 星期二 下午 1 点**

**您应该独自完成此作业。不接受逾期作业。**

本作业的目的是让您体验流水线 CPU。您将使用简单的时序 CPU 模拟给定的程序，以了解程序的指令组合。然后，您将使用流水线按序 CPU 模拟相同的程序，以了解流水线不同部分的延迟和带宽如何影响性能。您还将接触到用于执行底层实验所需功能的伪指令。此作业基于 CA:AQA 第三版练习 3.6。

----

1. DAXPY 循环 (双精度 aX + Y) 是处理矩阵和向量的程序中常用的操作。以下代码在 C++11 中实现了 DAXPY。

```cpp
  #include <cstdio>
  #include <random>

  int main()
  {
    const int N = 1000;
    double X[N], Y[N], alpha = 0.5;
    std::random_device rd; std::mt19937 gen(rd());
    std::uniform_real_distribution<> dis(1, 2);
    for (int i = 0; i < N; ++i)
    {
      X[i] = dis(gen);
      Y[i] = dis(gen);
    }

    // DAXPY 循环开始
    for (int i = 0; i < N; ++i)
    {
      Y[i] = alpha * X[i] + Y[i];
    }
    // DAXPY 循环结束

    double sum = 0;
    for (int i = 0; i < N; ++i)
    {
      sum += Y[i];
    }
    printf("%lf\n", sum);
    return 0;
  }
```

您的第一个任务是静态编译此代码，并使用时序简单 CPU 在 gem5 中模拟它。使用 `-O2` 标志编译程序，以避免在 gem5 中模拟时遇到未实现的 x87 指令。报告不同操作类的指令分解。为此，在文件 stats.txt 中 grep op_class。


2. 通过在编译 GCC 时使用 `-S` 和 `-O2` 选项，为上面的 daxpy 程序生成汇编代码。正如您从汇编代码中看到的那样，对程序实际任务（计算 `aX + Y`）不重要的指令也将被模拟。这包括用于生成向量 `X` 和 `Y`、求和 `Y` 中的元素以及打印总和的指令。当我用 `-S` 编译代码时，我得到了大约 350 行汇编代码，只有大约 10-15 行用于实际的 daxpy 循环。

通常，在进行评估设计的实验时，人们只想查看最重要的代码部分的统计信息。为此，通常会对程序进行注释，以便模拟器在到达代码的带注释部分时执行诸如创建检查点、输出和重置统计变量之类的功能。

您将编辑第一部分的 C++ 代码，在 DAXPY 循环开始之前和之后输出并重置统计信息。为此，在程序中包含文件 `util/m5/m5op.h`。您将在 gem5 仓库的 `util/m5` 目录中找到此文件。在您的程序中使用此文件中的函数 `m5_dump_reset_stats()`。此函数输出统计变量然后重置它们。您可以为延迟和周期参数提供 0 值。

要提供 `m5_dump_reset_stats()` 的定义，请转到目录 `util/m5` 并按以下方式编辑 Makefile.x86：

```
  diff --git a/util/m5/Makefile.x86 b/util/m5/Makefile.x86
  --- a/util/m5/Makefile.x86
  +++ b/util/m5/Makefile.x86
  [=@@=] -31,7 +31,7 @@
   AS=as
   LD=ld

  -CFLAGS=-O2 -DM5OP_ADDR=0xFFFF0000
  +CFLAGS=-O2
   OBJS=m5.o m5op_x86.o

   all: m5
```

在目录 `util/m5` 中执行命令 `make -f Makefile.x86`。这将创建一个名为 `m5op_x86.o` 的对象文件。将此文件与 DAXPY 程序链接。现在再次使用时序简单 CPU 模拟程序。这次您应该在文件 stats.txt 中看到三组统计信息。报告程序三个部分中不同操作类之间的指令分解。提供生成的汇编代码片段，该片段以调用 `m5_dump_reset_stats()` 开始，以 `m5_dump_reset_stats()` 结束，并在中间包含主 daxpy 循环。


3. gem5 支持几种不同类型的 CPU：atomic、timing、out-of-order、inorder 和 kvm。让我们谈谈 timing 和 inorder cpu。timing CPU（也称为 SimpleTimingCPU）在单个周期内执行每个算术指令，但内存访问需要多个周期。此外，它不是流水线的。所以任何时候都只有一个指令在被处理。inorder cpu（也称为 Minor）以流水线方式执行指令。据我了解，它具有以下流水线阶段：fetch1、fetch2、decode 和 execute。

查看文件 `src/cpu/minor/MinorCPU.py`。在 `MinorFU`（功能单元类）的定义中，我们定义了两个量 `opLat` 和 `issueLat`。从文件中提供的注释中，了解这两个参数是如何使用的。还要注意 `MinorDefaultFUPool` 类中定义的实例化的不同功能单元。


假设 FloatSimdFU 的 issueLat 和 opLat 可以从 1 到 6 个周期变化，并且它们的总和总是为 7 个周期。对于 opLat 的每一次减少，我们需要付出 issueLat 增加一个单位的代价。您更喜欢哪种 FloatSimd 功能单元设计？提供通过模拟代码的注释部分获得的统计证据。

您可以在此处找到扩展 minor CPU 的骨架文件 <$urlbase}html/cpu.py>。如果您使用此文件，您将不得不修改您的配置脚本以使其工作。此外，您必须修改此文件以支持下一部分。

4. 默认情况下，Minor CPU 具有两个整数功能单元，如文件 MinorCPU.py 中定义的那样（忽略乘法和除法单元）。假设我们最初的 Minor CPU 设计需要 2 个周期用于整数函数，4 个周期用于浮点函数。在我们即将推出的 Minor CPU 中，我们可以将这些延迟中的任何一个减半。我们应该选哪一个？提供通过模拟获得的统计证据。


## 提交内容
通过发送电子邮件给 David Wood 教授 <david@cs.wisc.edu> 和 Nilay Vaish <nilay@cs.wisc.edu> 提交您的作业，主题行："CS752 Homework3"。

1. 电子邮件应包含提交作业的学生的姓名和 ID 号。以下文件应作为 zip 文件附加到电子邮件中。

2. 一个名为 daxpy.cpp 的文件，用于测试。此文件还应包括第 2 部分要求的伪指令 (`m5_dump_reset_stats()`)。还要提供一个文件 daxpy.s，其中包含第 2 部分要求的生成的汇编代码片段。

3. 所有模拟的 stats.txt 和 config.ini 文件。

4. 一份关于所提问题的简短报告（200 字）。
