---
layout: documentation
title: ARM 功耗建模
doc: Learning gem5
parent: part2
permalink: /documentation/learning_gem5/part2/arm_power_modelling/
author: Thomas E. Hansen
---


ARM 功耗建模
===================

可以对 gem5 模拟的能量和功率使用情况进行建模和监控。这是通过使用 gem5 已经记录的各种统计数据在 `MathExprPowerModel` 中完成的；这是一种通过数学方程建模功率使用的方法。本教程的这一章详细介绍了功耗建模所需的各种组件是什么，并解释了如何将它们添加到现有的 ARM 模拟中。

本章借鉴了 `configs/example/arm` 目录中提供的 `fs_power.py` 配置脚本，还提供了有关如何扩展此脚本或其他脚本的说明。

请注意，只有在使用更详细的 "timing" CPU 时才能应用功率模型。

有关如何在 gem5 中构建功耗建模以及它们与模拟器的哪些其他部分交互的概述，可以在 2017 年 ARM 研究峰会的 [Sascha Bischoff 的演示](https://youtu.be/3gWyUWHxVj4) 中找到。

动态电源状态
--------------------

功率模型由两个函数组成，它们描述了如何计算不同电源状态下的功耗。电源状态如下（来自 `src/sim/PowerState.py`）：

- `UNDEFINED`: 无效状态，没有电源状态派生信息可用。
   这是默认状态。
- `ON`: 逻辑块正在积极运行并消耗动态和泄漏能量，具体取决于所需的处理量。
- `CLK_GATED`: 块内的时钟电路被选通以节省动态能量，块的电源仍然打开，块正在消耗泄漏能量。
- `SRAM_RETENTION`: 逻辑块内的 SRAM 被拉入保持状态以进一步减少泄漏能量。
- `OFF`: 逻辑块被电源选通，不消耗任何能量。

使用 `PowerModel` 类的 `pm` 字段为除 `UNDEFINED` 之外的每个状态分配一个功率模型。它是一个包含 4 个功率模型的列表，每个状态一个，顺序如下：

0. `ON`
1. `CLK_GATED`
2. `SRAM_RETENTION`
3. `OFF`

请注意，虽然有 4 个不同的条目，但这些不必是不同的功率模型。提供的 `fs_power.py` 文件对 `ON` 状态使用一个功率模型，然后对剩余状态使用相同的功率模型。

功耗类型
-----------------

gem5 模拟器模拟 2 种类型的功耗：

- **static**:无论活动如何，模拟系统使用的功率。
- **dynamic**: 由于各种类型的活动，系统使用的功率。

功率模型必须包含用于模拟这两者的方程（尽管该方程可以像 `st = "0"` 一样简单，例如，如果静态功率在该功率模型中不需要或不相关）。

MathExprPowerModels
-------------------

`fs_power.py` 中提供的功率模型扩展了 `MathExprPowerModel` 类。`MathExprPowerModels` 指定为包含有关如何计算系统使用的功率的数学表达式的字符串。它们通常包含统计数据和自动变量（例如温度）的混合，例如：

```python
class CpuPowerOn(MathExprPowerModel):
    def __init__(self, cpu_path, **kwargs):
        super(CpuPowerOn, self).__init__(**kwargs)
        # 每 IPC 2A，每缓存未命中 3pA
        # 然后转换为瓦特
        self.dyn = "voltage * (2 * {}.ipc + 3 * 0.000000001 * " \
                   "{}.dcache.overall_misses / sim_seconds)".format(cpu_path,
                                                                    cpu_path)
        self.st = "4 * temp"
```

（上面的功率模型取自提供的 `fs_power.py` 文件。）

我们可以看到自动变量（`voltage` 和 `temp`）不需要路径，而特定于组件的统计数据（CPU 的每周期指令数 `ipc`）需要。在文件的更下方，在 `main` 函数中，我们可以看到 CPU 对象有一个 `path()` 函数，它返回组件在系统中的“路径”，例如 `system.bigCluster.cpus0`。`path` 函数由 `SimObject` 提供，因此可以由系统中扩展此对象的任何对象使用，例如 l2 缓存对象在 CPU 对象使用它的几行之后使用了它。

（注意 `dcache.overall_misses` 除以 `sim_seconds` 以转换为瓦特。这是 _功率_ 模型，即能量随时间的变化，而不是能量模型。使用这些术语时要小心，因为它们经常互换使用，但在涉及功率和能量模拟/建模时意味着非常具体的事情。）

扩展现有模拟
--------------------------------

提供的 `fs_power.py` 脚本通过导入它然后修改值来扩展现有的 `fs_bigLITTLE.py` 脚本。作为其中的一部分，使用了几个循环来遍历 SimObject 的后代以应用功率模型。因此，为了扩展现有模拟以支持功率模型，定义一个执行此操作的辅助函数会很有帮助：

```python
def _apply_pm(simobj, power_model, so_class=None):
    for desc in simobj.descendants():
        if so_class is not None and not isinstance(desc, so_class):
            continue

        desc.power_state.default_state = "ON"
        desc.power_model = power_model(desc.path())
```

上面的函数接受一个 SimObject、一个功率模型和一个可选的类，SimObject 的后代必须实例化该类才能应用 PM。如果未指定类，则 PM 应用于所有后代。

无论您是否决定使用辅助函数，您现在都需要定义一些功率模型。这可以通过遵循 `fs_power.py` 中看到的模式来完成：

0. 为您感兴趣的每个电源状态定义一个类。这些类应扩展 `MathExprPowerModel`，并包含 `dyn` 和 `st` 字段。这些字段中的每一个都应包含一个字符串，描述如何计算此状态下各自类型的功率。它们的构造函数应该接受一个通过 `format` 在描述功率计算方程的字符串中使用的路径，以及许多要传递给超类构造函数的 kwargs。
1. 定义一个类来保存上一步中定义的所有功率模型。此类应扩展 `PowerModel` 并包含单个字段 `pm`，该字段包含 4 个元素的列表：`pm[0]` 应该是 "ON" 电源状态的功率模型的实例；`pm[1]` 应该是 "CLK_GATED" 电源状态的功率模型的实例；等等。此类的构造函数应接受传递给各个功率模型的路径，以及传递给超类构造函数的许多 kwargs。
2. 定义了辅助函数和上述类后，您可以扩展 `build` 函数以考虑这些因素，如果您希望能够切换模型的使用，还可以选择在 `addOptions` 函数中添加命令行标志。

> **示例实现：**
>
> ```python
> class CpuPowerOn(MathExprPowerModel):
>     def __init__(self, cpu_path, **kwargs):
>         super(CpuPowerOn, self).__init__(**kwargs)
>         self.dyn = "voltage * 2 * {}.ipc".format(cpu_path)
>         self.st = "4 * temp"
>
>
> class CpuPowerClkGated(MathExprPowerModel):
>     def __init__(self, cpu_path, **kwargs):
>         super(CpuPowerOn, self).__init__(**kwargs)
>         self.dyn = "voltage / sim_seconds"
>         self.st = "4 * temp"
>
>
> class CpuPowerOff(MathExprPowerModel):
>     dyn = "0"
>     st = "0"
>
>
> class CpuPowerModel(PowerModel):
>     def __init__(self, cpu_path, **kwargs):
>         super(CpuPowerModel, self).__init__(**kwargs)
>         self.pm = [
>             CpuPowerOn(cpu_path),       # ON
>             CpuPowerClkGated(cpu_path), # CLK_GATED
>             CpuPowerOff(),              # SRAM_RETENTION
>             CpuPowerOff(),              # OFF
>         ]
>
> [...]
>
> def addOptions(parser):
>     [...]
>     parser.add_argument("--power-models", action="store_true",
>                         help="Add power models to the simulated system. "
>                              "Requires using the 'timing' CPU."
>     return parser
>
>
> def build(options):
>     root = Root(full_system=True)
>     [...]
>     if options.power_models:
>         if options.cpu_type != "timing":
>             m5.fatal("The power models require the 'timing' CPUs.")
>
>         _apply_pm(root.system.bigCluster.cpus, CpuPowerModel
>                   so_class=m5.objects.BaseCpu)
>         _apply_pm(root.system.littleCluster.cpus, CpuPowerModel)
>
>     return root
>
> [...]
> ```

统计名称
----------

统计名称通常与模拟后在 `m5out` 目录中生成的 `stats.txt` 文件中看到的名称相同。但是，也有一些例外：

- CPU 时钟在 `stats.txt` 中被称为 `clk_domain.clock`，但在功率模型中使用 `clock_period` 而 *不是* `clock` 进行访问。

统计转储频率
-------------------

默认情况下，gem5 每模拟秒将模拟统计信息转储到 `stats.txt` 文件中。这可以通过 `m5.stats.periodicStatDump` 函数进行控制，该函数采用以模拟 tick（而不是秒）为单位测量的所需统计转储频率。幸运的是，`m5.ticks` 提供了一个 `fromSeconds` 函数以方便使用。

下面是一个统计转储频率如何影响结果分辨率的示例，取自 [Sascha Bischoff 的演示](https://youtu.be/3gWyUWHxVj4) 幻灯片 16：

![比较不太详细的功率图和更详细的功率图的图片；1 秒采样间隔与 1 毫秒采样间隔。](/pages/static/figures/empowering_the_masses_slide16.png)

统计数据转储的频率直接影响基于 `stats.txt` 文件生成的图形的分辨率。但是，它也会影响输出文件的大小。每模拟秒转储统计数据与每模拟毫秒转储统计数据相比，文件大小增加了数百倍。因此，想要控制统计转储频率是有意义的。

使用提供的 `fs_power.py` 脚本，可以按如下方式完成：

```python
[...]

def addOptions(parser):
    [...]
    parser.add_argument("--stat-freq", type=float, default=1.0,
                        help="Frequency (in seconds) to dump stats to the "
                             "'stats.txt' file. Supports scientific notation, "
                             "e.g. '1.0E-3' for milliseconds.")
    return parser

[...]

def main():
    [...]
    m5.stats.periodicStatDump(m5.ticks.fromSeconds(options.stat_freq))
    bL.run()

[...]
```

然后可以使用
```
--stat-freq <val>
```
在调用模拟时指定统计转储频率。

常见问题
---------------

- gem5 在使用提供的 `fs_power.py` 时崩溃，并显示消息 `fatal: statistic '' (160) was not properly initialized by a regStats() function`
- gem5 在使用提供的 `fs_power.py` 时崩溃，并显示消息 `fatal: Failed to evaluate power expressions: [...]`

这是由于 gem5 的统计框架最近已被重构。
获取最新版本的 gem5 源代码并重新构建应该可以解决问题。如果这不是理想的，则需要以下两组补丁：

1. [https://gem5-review.googlesource.com/c/public/gem5/+/26643](https://gem5-review.googlesource.com/c/public/gem5/+/26643)
2. [https://gem5-review.googlesource.com/c/public/gem5/+/26785](https://gem5-review.googlesource.com/c/public/gem5/+/26785)

可以按照各自链接中的下载说明检出并应用这些补丁。
