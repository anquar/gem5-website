---
layout: documentation
title: ARM DVFS 支持
doc: Learning gem5
parent: part2
permalink: /documentation/learning_gem5/part2/arm_dvfs_support/
author: Thomas E. Hansen
---


ARM DVFS 建模
==================

像大多数现代 CPU 一样，ARM CPU 支持 DVFS。可以对此进行建模，例如，在 gem5 中监控由此产生的功耗。DVFS 建模是通过使用 Clocked Objects 的两个组件来完成的：电压域 (Voltage Domains) 和时钟域 (Clock Domains)。本章详细介绍了不同的组件，并展示了将它们添加到现有模拟中的不同方法。

电压域
---------------

电压域规定了 CPU 可以使用的电压值。如果在 gem5 中运行全系统模拟时未指定 VD，则使用默认值 1.0 伏特。这是为了避免在用户对模拟电压不感兴趣时强制他们考虑电压。

电压域可以从单个值或值列表构造，使用 `voltage` kwarg 传递给 `VoltageDomain` 构造函数。如果指定了单个值和多个频率，则该电压用于时钟域中的所有频率。如果指定了电压值列表，其条目数必须与相应时钟域中的条目数匹配，并且条目必须按 _降序_ 排列。与真实硬件一样，电压域适用于整个处理器插槽。这意味着如果您想为不同的处理器拥有不同的 VD（例如，对于 big.LITTLE 设置），您需要确保 big 和 LITTLE 集群位于不同的插槽上（检查与集群关联的 `socket_id` 值）。

有 2 种方法可以将 VD 添加到现有的 CPU/模拟中，一种更灵活，另一种更直接。第一种方法向提供的 `configs/example/arm/fs_bigLITTLE.py` 文件添加命令行标志，而第二种方法添加自定义类。

1. 向模拟添加电压域的最灵活方法是使用命令行标志。要添加命令行标志，请在文件中找到 `addOptions` 函数并在那里添加标志，还可以选择添加一些帮助文本。
   支持单个和多个电压的示例：

   ```python
   def addOptions(parser):
       [...]
       parser.add_argument("--big-cpu-voltage", nargs="+", default="1.0V",
                           help="Big CPU voltage(s).")
       return parser
   ```

   然后可以使用以下命令指定电压域值：

   ```
   --big-cpu-voltage <val1>V [<val2>V [<val3>V [...]]]
   ```

   然后将在 `build` 函数中使用 `options.big_cpu_voltage` 访问此值。`nargs="+"` 确保至少需要一个参数。
   `build` 中的用法示例：

   ```python
   def build(options):
       [...]
       # big cluster
       if options.big_cpus > 0:
           system.bigCluster = big_model(system, options.big_cpus,
                                         options.big_cpu_clock,
                                         options.big_cpu_voltage)
       [...]
   ```

   可以添加类似的标志和对 `build` 函数的添加，以支持指定 LITTLE CPU 的电压值。这种方法允许非常容易地指定和修改电压。这种方法的唯一缺点是，多个命令行参数（有些是列表形式）可能会使调用模拟器的命令变得混乱。

2. 指定电压域的不太灵活的方法是创建 `CpuCluster` 的子类。类似于现有的 `BigCluster` 和 `LittleCluster` 子类，这些将扩展 `CpuCluster` 类。
   在子类的构造函数中，除了指定 CPU 类型外，我们还定义了电压域的值列表，并使用 kwarg `cpu_voltage`将其传递给对 `super` 构造函数的调用。
   这是一个向 `BigCluster` 添加电压的示例：

   ```python
   class VDBigCluster(devices.CpuCluster):
       def __init__(self, system, num_cpus, cpu_clock=None, cpu_voltage=None):
           # 使用与库存 BigCluster 相同的 CPU
           abstract_cpu = ObjectList.cpu_list.get("O3_ARM_v7a_3")
           # 电压值
           my_voltages = [ '1.0V', '0.75V', '0.51V']

           super(VDBigCluster, self).__init__(
               cpu_voltage=my_voltages,
               system=system,
               num_cpus=num_cpus,
               cpu_type=abstract_cpu,
               l1i_type=devices.L1I,
               l1d_type=devices.L1D,
               wcache_type=devices.WalkCache,
               l2_type=devices.L2
           )
   ```

   然后可以通过定义类似的 `VDLittleCluster` 类来向 `LittleCluster` 添加电压。

   定义了子类后，我们仍然需要在文件中的 `cpu_types` 字典中添加一个条目，指定字符串名称作为键，类对作为值，例如：

   ```python
   cpu_types = {
       [...]
       "vd-timing" : (VDBigCluster, VDLittleCluster)
   }
   ```

   然后可以通过传递以下内容来使用带有 VD 的 CPU

   ```
   --cpu-type vd-timing
   ```

   到调用模拟的命令。

   由于对电压值的任何修改都必须通过找到正确的子类并修改其代码，或添加更多子类和 `cpu_types` 条目来完成，因此这种方法的灵活性远不如基于标志的方法。

时钟域
-------------

电压域与时钟域结合使用。如前所述，如果未指定自定义电压值，则时钟域中的所有值均使用默认值 1.0V。

时钟域的类型
与电压域相比，有 3 种类型的时钟域（来自 `src/sim/clock_domain.hh`）：

- `ClockDomain` -- 为捆绑在同一时钟域下的一组 Clocked Objects 提供时钟。CD 又被分组到电压域中。CD 提供对具有“源”和“派生”时钟域的层次结构的支持。
- `SrcClockDomain` -- 提供连接到可调时钟源的 CD 的概念。它维护时钟周期并提供设置/获取时钟的方法，以及处理程序将管理的 CD 的配置参数。这包括各种性能级别的频率值、域 ID 和当前性能级别。
  请注意，软件请求的性能级别对应于 CD 可以运行的频率操作点之一。
- `DerivedClockDomain` -- 提供连接到父 CD 的 CD 的概念，该父 CD 可以是 `SrcClockDomain` 或 `DerivedClockDomain`。它维护时钟分频器并提供获取时钟的方法。

向现有模拟添加时钟域
----------------------------------------------

此示例将使用与 VD 示例相同的提供的文件，即 `configs/example/arm/fs_bigLITTLE.py` 和 `configs/example/arm/devices.py`。

像 VD 一样，CD 可以是单个值或值列表。如果给出了时钟速度列表，则适用与给 VD 的电压列表相同的规则，即 CD 中的值数必须与 VD 中的值数匹配；并且时钟速度必须按 _降序_ 给定。提供的文件支持将时钟指定为单个值（通过 `--{big,little}-cpu-clock` 标志），但不支持作为值列表。
扩展/修改提供的标志的行为是添加对多值 CD 支持的最简单和最灵活的方法，但也可以通过添加子类来实现。

1. 要向现有的 `--{big,little}-cpu-clock` 标志添加多值支持，请在 `configs/example/arm/fs_bigLITTLE.py` 文件中找到 `addOptions` 函数。在各种 `parser.add_argument` 调用中，找到添加 CPU-clock 标志的调用，并将 kwarg `type=str` 替换为 `nargs="+"`：
   ```python
   def addOptions(parser):
       [...]
       parser.add_argument("--big-cpu-clock", nargs="+", default="2GHz",
                           help="Big CPU clock frequency.")
       parser.add_argument("--little-cpu-clock", nargs="+", default="1GHz",
                           help="Little CPU clock frequency.")
       [...]
   ```
   有了这个，可以类似于用于 VD 的标志指定多个频率：
   ```
   --{big,little}-cpu-clock <val1>GHz [<val2>MHz [<val3>MHz [...]]]
   ```

   由于这修改了现有标志，因此标志的值已经在 `build` 函数中连接到了相关的构造函数和 kwargs，因此无需修改任何内容。

2. 要在子类中添加 CD，该过程与作为子类添加 VD 的过程非常相似。区别在于，我们指定时钟值并在 `super` 调用中使用 `cpu_clock` kwarg，而不是指定电压并使用 `cpu_voltage` kwarg：
   ```python
   class CDBigCluster(devices.CpuCluster):
       def __init__(self, system, num_cpus, cpu_clock=None, cpu_voltage=None):
           # 使用与库存 BigCluster 相同的 CPU
           abstract_cpu = ObjectList.cpu_list.get("O3_ARM_v7a_3")
           # 时钟值
           my_freqs = [ '1510MHz', '1000MHz', '667MHz']

           super(VDBigCluster, self).__init__(
               cpu_clock=my_freqs,
               system=system,
               num_cpus=num_cpus,
               cpu_type=abstract_cpu,
               l1i_type=devices.L1I,
               l1d_type=devices.L1D,
               wcache_type=devices.WalkCache,
               l2_type=devices.L2
           )
   ```
   这可以与 VD 示例结合使用，以便为集群指定 VD 和 CD。

   与使用此方法添加 VD 一样，您需要为您想要使用的每种 CPU 类型定义一个类，并在 `cpu_types` 字典中指定它们的名称-cpu对值。此方法也具有相同的限制，并且不如基于标志的方法灵活。

确保 CD 具有有效的 DomainID
-------------------------------------

无论使用哪种先前的方法，都需要进行一些额外的修改。这些涉及提供的 `configs/example/arm/devices.py` 文件。

在文件中，找到 `CpuClusters` 类并找到将 `self.clk_domain` 初始化为 `SrcClockDomain` 的位置。如上面关于 `SrcClockDomain` 的注释中所述，这些具有域 ID。如果未设置此项（如提供的设置中的情况），则将使用默认 ID `-1`。
取而代之的是，更改代码以确保设置了域 ID：

```python
[...]
self.clk_domain = SrcClockDomain(clock=cpu_clock,
                                 voltage_domain=self.voltage_domain,
                                 domain_id=system.numCpuClusters())
[...]
```

这里使用 `system.numCpuClusters()`，因为 CD 适用于整个集群，即第一个集群为 0，第二个集群为 1，依此类推。

如果您不设置域 ID，当尝试运行支持 DVFS 的模拟时，您将收到以下错误，因为某些内部检查捕获了默认域 ID：

```
fatal: fatal condition domain_id == SrcClockDomain::emptyDomainID occurred:
DVFS: Controlled domain system.bigCluster.clk_domain needs to have a properly
assigned ID.
```

DVFS 处理程序
----------------

如果您指定 VD 和 CD 然后尝试运行模拟，它很可能会运行，但您可能会在输出中注意到以下警告：

```
warn: Existing EnergyCtrl, but no enabled DVFSHandler found.
```

VD 和 CD 已添加，但没有系统可以用来调整值的 `DVFSHandler`。解决此问题的最简单方法是在 `configs/example/arm/fs_bigLITTLE.py` 文件中添加另一个命令行标志。

就像在 VD 和 CD 示例中一样，找到 `addOptions` 函数并将以下代码附加到它：

```python
def addOptions(parser):
    [...]
    parser.add_argument("--dvfs", action="store_true",
                        help="Enable the DVFS Handler.")
    return parser
```

然后，找到 `build` 函数并将此代码附加到它：

```python
def build(options):
    [...]
    if options.dvfs:
        system.dvfs_handler.domains = [system.bigCluster.clk_domain,
                                       system.littleCluster.clk_domain]
        system.dvfs_handler.enable = options.dvfs

    return root
```

有了这个，您现在应该能够通过在调用模拟时使用 `--dvfs` 标志来运行支持 DVFS 的模拟，并可以根据需要指定 big 和 LITTLE 集群的电压和频率操作点。
