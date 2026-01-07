---
layout: bootcamp
title: 在 gem5 中建模功耗
permalink: /bootcamp/using-gem5/modeling-power
section: using-gem5
---
<!-- _class: title -->

## 在 gem5 中建模功耗

---

## 我们将介绍的内容

- 功耗建模背后的思想
- `MathExprPowerModel`
- 一个示例

---

## 功耗建模

- gem5 支持基于"激活计数"的功耗模型
- 这类似于 McPAT/Wattch 等工具，但可以在 gem5 中完成
- 正确的常数很难找到
  - CACTI 是一种可能，但是...

例如

$$P = \frac{N_{cache\_accesses} * 18 \mu J + N_{cache\_misses} * 1 \mu J}{s}$$

> 我们构建的是*功耗*模型，而不是能量模型。因此，不要忘记转换为*瓦特*而不是*焦耳*。

---

## gem5 中的功耗模型

gem5 有一个通用的功耗模型，向 Python 暴露 `getDynamicPower` 和 `getStaticPower` 接口

每个 SimObject 可以为不同的功耗状态（例如，开启、关闭、时钟门控和 SRAM 保持）设置不同的功耗模型

还有一个使用 RC 电路模型的热模型。
今天我们不会讨论热模型。

参见 [`gem5/src/sim/power/`](../../gem5/src/sim/power/)

我们将使用 `MathExprPowerModel`，但你也可以创建自己的模型。
应该很快会有一个新的 `PythonFunction` 功耗模型。

---

## MathExprPowerModel

我们将使用 `MathExprPowerModel`
参见 [`gem5/src/sim/power/MathExprPowerModel.py`](../../gem5/src/sim/power/MathExprPowerModel.py)

这允许你为功耗模型指定一个数学表达式，就像我们之前看到的那样。

你可以使用统计信息、电压以及来自热模型的信息。

电压来自对象的电压域（在 `ClockedObject` 中指定）。

### 在进入示例之前的一些注意事项

我们（目前）不提供任何常数。

我们将看到一些变通方法，因为标准库不支持功耗模型。

### 这一点再怎么强调都不为过：使用功耗模型时要小心！

---

## L3 缓存功耗模型

让我们从之前使用经典缓存创建的 L3 缓存开始。

以下是我们提供的一些代码

```python
from m5.objects import PowerModel, MathExprPowerModel

class L3PowerModel(PowerModel):
    def __init__(self, l3_path, **kwargs):
        super().__init__(**kwargs)
        # Choose a power model for every power state
        self.pm = [
            L3PowerOn(l3_path),  # ON
            L3PowerOff(),  # CLK_GATED
            L3PowerOff(),  # SRAM_RETENTION
            L3PowerOff(),  # OFF
        ]
```

---

## 为"开启"状态添加功耗模型

```python
class L3PowerOn(MathExprPowerModel):
    def __init__(self, l3_path, **kwargs):
        super().__init__(**kwargs)
        self.dyn = f"({l3_path}.overallAccesses * 0.000_018_000 \
                 + {l3_path}.overallMisses * 0.000_001_000)/simSeconds"
        self.st = "(voltage * 3)/10"
```

这个功耗模型使用了前面幻灯片中的方程。

我们从缓存中获取 "overallAccesses" 统计信息和 "overallMisses" 统计信息。

你可以查看 stats.txt 文件以了解所有可以使用的统计信息。

我们还除以模拟的秒数来计算*瓦特*而不是*焦耳*。（如果你想获得增量时间...祝你好运）

---

## 添加功耗模型

将以下代码添加到你的 `cache_hierarchy` 中。

```python
    def add_power_model(self):
        self.l3_cache.power_state.default_state = "ON"
        self.l3_cache.power_model = L3PowerModel(self.l3_cache.path())
```

> 这需要在 `board._pre_instantiate` 之后但在 `m5.instantiate` 之前调用。标准库目前不支持此功能。

你需要获取 L3 缓存的"路径"，以便获取统计信息。
路径是对象的"完整名称"。
`SimObject` 有一个获取路径的函数，但它只在创建 `Root` 对象后有效。

---

## 运行代码

```sh
gem5 test-cache.py
```

查看 `stats.txt` 的输出

```sh
grep power_model m5out/stats.txt
```

```text
board.cache_hierarchy.l3_cache.power_model.dynamicPower  2011.504302
board.cache_hierarchy.l3_cache.power_model.staticPower     0.300000
board.cache_hierarchy.l3_cache.power_model.pm0.dynamicPower  2011.504302
board.cache_hierarchy.l3_cache.power_model.pm0.staticPower     0.300000
board.cache_hierarchy.l3_cache.power_model.pm1.dynamicPower            0
board.cache_hierarchy.l3_cache.power_model.pm1.staticPower            0
```

> **缓存 2 千瓦？？？？？** 这似乎不对...
