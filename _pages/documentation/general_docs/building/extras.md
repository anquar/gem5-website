---
layout: documentation
title: 构建 EXTRAS
doc: gem5 documentation
parent: building_extras
permalink: /documentation/general_docs/building/EXTRAS
authors: Jason Lowe-Power
---

# 构建 EXTRAS

`EXTRAS` SCons 选项是一种无需将文件添加到 gem5 源代码树即可在 gem5 中添加功能的方法。具体来说，它允许您识别一个或多个目录，这些目录将与 gem5 一起编译，就像它们出现在 gem5 树的 'src' 部分下一样，而不需要代码实际上位于 'src' 下。它的存在是为了允许用户编译未随 gem5 分发的或无法随 gem5 分发的附加功能（通常是附加的 SimObject 类）。这对于维护不适合合并到 gem5 源代码树中的本地代码，或由于不兼容的许可证而无法合并的第三方代码非常有用。由于 EXTRAS 位置完全独立于 gem5 仓库，因此您也可以将其代码保留在不同的版本控制系统下。

EXTRAS 功能的主要缺点是，就其本身而言，它只支持向 gem5 添加代码，不支持修改任何基本的 gem5 代码。

EXTRAS 功能的一个用途是支持 EIO trace。EIO 的 trace 读取器是在 SimpleScalar 许可下授权的，由于该许可与 gem5 的 BSD 许可不兼容，读取这些 trace 的代码不包含在 gem5 发行版中。相反，EIO 代码通过单独的“受限”[仓库](https://github.com/gem5/gem5) 分发。

以下示例显示如何编译 EIO 代码。通过添加或修改 extras 路径，可以编译任何其他合适的 extra。要使用 EXTRAS 编译代码，只需执行以下操作：

```js
 scons EXTRAS=/path/to/encumbered build/<ISA>/gem5.opt
```

在此目录的根目录中，您应该有一个 SConscript，它使用 M5 其余部分中使用的 ```Source()``` 和 ```SimObject()``` scons 函数来编译适当的源并添加任何感兴趣的 SimObject。如果要添加多个目录，可以将 EXTRAS 设置为以冒号分隔的路径列表。

请注意，EXTRAS 是一个“粘性”参数，因此一旦向 scons 提供一次值，该值将在针对同一构建目录（本例中为 ```build/<ISA>```）的未来 scons 调用中重复使用，只要它没有被覆盖。因此，您只需在第一次构建特定配置时或想要覆盖先前指定的值时指定 EXTRAS。
要使用 EXTRAS 运行回归测试，请使用类似以下的命令行：
```js
 ./util/regress --scons-opts = "EXTRAS=/path/to/encumbered" -j 2 quick
```
