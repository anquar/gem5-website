---
layout: bootcamp
title: 在 gem5 中开发 SimObjects
permalink: /bootcamp/developing-gem5/sim-objects-intro
section: developing-gem5
author: Mahyar Samani, M. Mysore
---
<!-- _class: title -->

## 在 gem5 中开发 SimObjects

<!-- Add a topic sentence here.-->

---

<!--
Speaker Notes
- How to build gem5
 -->

## 让我们开始构建 gem5

让我们在基础 **gem5** 目录中构建 gem5，同时我们学习一些基础知识。通过运行以下命令来完成。

```sh
cd gem5
scons build/NULL/gem5.opt -j$(nproc)
```

---

## gem5 构建系统的基础知识

gem5 的构建系统是*复杂的*。

正如我们将在接下来的章节中看到的，gem5 有许多领域特定语言和源到源编译器。

这意味着两件事：

1. 最终代码的样子并不总是显而易见的。
2. 设置 gem5 构建有很多很多选项。

---

## 配置 gem5 构建

正如我们所看到的，有多种方式可以配置 gem5 构建，这会产生不同的二进制文件。

有两类选项：

1. 构建时配置（例如，在二进制文件中包含哪些模型）
2. 编译器配置（例如，优化、调试标志等）

如果你忘记了这些，

> `scons --help` 将解释目标和 Kconfig 工具。

---

## 编译器配置

这由你构建的 gem5 二进制文件的*后缀*指定。例如，`gem5.opt` 是用 "opt" 配置构建的。选项有：

- `fast`：所有优化，无调试符号，大多数断言被禁用。
  - 只有在完全调试好模型后才使用此选项。
  - 比 `opt` 显著加速，因为二进制文件更小（约 50 MiB）。
- `opt`：优化的构建，带有调试符号和所有 panic、断言等启用。
  - 这是最常见的构建目标，但它非常大（约 500 MiB）。
  - 可以与 `gdb` 一起使用，但有时它会说"该变量已被优化掉"。
- `debug`：最小优化（`-O1`）和所有调试符号。
  - 当你需要调试 gem5 代码本身且 `opt` 不适合时使用此选项。
  - 比 `opt` *慢得多*（大约慢 5-10 倍）。

> 记住，这些选项是针对 *gem5* 二进制文件的，而不是模拟系统。选择 *fast* 或 *debug* 不会影响模拟器的输出（当然，除非有 bug）。

---

## 构建时配置

配置 gem5 构建有很多选项。

有两种方法：

1. 使用 `gem5/build_opts` 中找到的默认值
2. 使用 `Kconfig` 配置（与 Linux 内核使用的相同工具）

---

## Build_opts

```text
ALL                       GCN3_X86                  NULL_MOESI_hammer  X86_MESI_Two_Level
ARM                       MIPS                      POWER              X86_MI_example
ARM_MESI_Three_Level      NULL                      RISCV              X86_MOESI_AMD_Base
ARM_MESI_Three_Level_HTM  NULL_MESI_Two_Level       SPARC
ARM_MOESI_hammer          NULL_MOESI_CMP_directory  VEGA_X86
Garnet_standalone         NULL_MOESI_CMP_token      X86
```

在 `build_opts` 中，你会找到许多默认选项。大多数选项命名为 `<ISA>_<PROTOCOL>`。

例如，`X86_MESI_Two_Level` 是 X86 ISA 和 MESI_Two_Level 协议的构建选项。

你也可以将多个 ISA 构建到一个二进制文件中（例如，`ALL`），但你**不能**将多个 Ruby 一致性协议构建到一个二进制文件中。

---

## 使用 Kconfig

Kconfig 是一个允许你交互式配置 gem5 构建的工具。

使用 Kconfig 时，首先必须创建一个构建目录。
注意：此目录可以有任何名称，并且可以位于系统上的*任何位置*。

常见做法是在 gem5 源代码目录中创建一个名为 `build` 的目录，并使用 `build_opts` 中的默认值。

```sh
scons defconfig build/my_gem5/ build_opts/ALL
```

在这种情况下，我们使用 `build/my_gem5` 作为构建目录，使用 `build_opts/ALL` 作为默认配置。

---

## 使用 Kconfig（续）

创建构建目录后，你可以使用 `menuconfig` 目标运行 `scons` 来获得交互式配置工具。

```sh
scons menuconfig build/my_gem5/
```

<script src="https://asciinema.org/a/nMSV0wVOKNavHSJEt3I77jxyu.js" id="asciicast-nMSV0wVOKNavHSJEt3I77jxyu" async="true"></script>

---

## 整合所有内容

要构建 gem5，一旦你设置并配置了构建目录，就可以运行以下命令。

```sh
scons build/my_gem5/gem5.opt -j$(nproc)
```

这将使用你设置的配置构建 gem5 二进制文件。
它将构建 "opt" 二进制文件。

注意：gem5 需要很长时间来构建，因此使用多核很重要。
我不知道你有多少个核心，所以我使用了 `-j$(nproc)` 来使用所有核心。
如果你在系统上做其他事情，你可能想使用更少的核心。

---

## gem5 的 Scons 构建系统

用于设置 gem5 构建的文件主要有两种类型：

- `SConstruct`：包含构建目标类型的定义。
  - 所有 `SConstruct` 文件首先执行。
  - 一些代码也在 `gem5/build_tools` 中
  - 说实话，这段代码很混乱，不容易追踪。
- `SConscript`：包含文件的构建指令。
  - 定义*要构建什么*（例如，要编译哪些 C++ 文件）。
  - 你将主要与这些文件交互。

我们支持*大多数*常见操作系统和*大多数*现代编译器。修复 SCons 构建中的编译器错误并不简单。

> 我们强烈建议你使用**支持的**编译器/操作系统或使用 docker 来构建 gem5。
>
> 你*不会*发现 SCons 文档有帮助。gem5 对它进行了*太多*定制。

---

<!-- _class: start -->

## SimObjects

---

<!--
Speaker Notes
- SimObject
    - Definition
    - Role of SimObjects
 -->

## 什么是 SimObject？

`SimObject` 是 gem5 对模拟模型的命名。我们使用 `SimObject` 及其子类（例如 `ClockedObject`）来模拟计算机硬件组件。`SimObject` 在 gem5 中促进以下功能：

- 定义模型：例如缓存
- 参数化模型：例如缓存大小、关联度
- 收集统计信息：例如命中次数、访问次数

---

<!--
Speaker Notes
- 4 SimObject files
    - Definition file
    - Header file
    - Source file
    - Params header file (auto-generated)
 -->

## 代码中的 SimObject

在 gem5 构建中，每个基于 `SimObject` 的类都有 4 个相关文件。

- `SimObject` 声明文件：Python（类似）脚本（.py 扩展名）：
  - 在最高级别表示模型。允许实例化模型并与 C++ 后端接口。它定义了模型的参数集。
  - **注意**：如果你想重新配置 `SimObject`，你不应该在此文件中更改参数值（我们将在以后学习）。
- `SimObject` 头文件：C++ 头文件（.hh 扩展名）：
  - 在 C++ 中声明 `SimObject` 类。
  与 `SimObject` 定义文件紧密相关。
- `SimObject` 源文件：C++ 源文件（.cc 扩展名）：
  - 实现 `SimObject` 的功能。
- `SimObjectParams` 头文件：从 `SimObject` 定义**自动生成**的 C++ 头文件（.hh）：
  - 声明一个存储 `SimObject` 所有参数的 C++ 结构体。

---

<!--
Speaker Notes
- Steps to making HelloSimObject
    - First HelloSimObject
    - Adding `num_hellos`
 -->

<!-- _class: two-col -->

## HelloSimObject

我们将开始构建我们的第一个 `SimObject`，称为 `HelloSimObject`，我们将查看 `SimObject` 文件之一。

我们将从以下步骤开始。

1. 编写定义文件。
2. 编写头文件。
3. 编写源文件。
4. 编写 `SConscript`。
5. 编译。
6. 编写配置脚本并运行它。

###

稍后，我们将执行以下步骤。

7. 向定义文件添加参数。
8. 更新源文件。
9. 编译。
10. 编写第二个配置脚本并运行它。

---
<!-- _class: start -->

## 步骤 1：简单的 SimObject

---

<!-- _class: border-image -->

<!--
Speaker Notes
- Commands to run for:
    - Creating a directory
    - Creating a new file
 -->

## SimObject 定义文件：创建文件

让我们在以下位置为我们的 `SimObject` 创建一个 python 文件：
[src/bootcamp/hello-sim-object/HelloSimObject.py](../../gem5/src/bootcamp/hello-sim-object/HelloSimObject.py)

由于 gem5 仍在编译，首先打开一个新终端。

![width:1140px 点击哪里打开新终端](/bootcamp/03-Developing-gem5-models/01-sim-objects-intro-imgs/terminal.drawio.svg)

然后，在基础 **gem5** 目录中运行以下命令：

```sh
cd gem5
mkdir src/bootcamp
mkdir src/bootcamp/hello-sim-object
touch src/bootcamp/hello-sim-object/HelloSimObject.py
```

---

<!--
Speaker Notes
- What to put in SimObject definition file
 -->

## SimObject 定义文件：导入和定义

在你选择的编辑器中打开 [src/bootcamp/hello-sim-object/HelloSimObject.py](../../gem5/src/bootcamp/hello-sim-object/HelloSimObject.py)。

在 `HelloSimObject.py` 中，我们将定义一个表示我们 `HelloSimObject` 的新类。
我们需要从 `m5.objects.SimObject` 导入 `SimObject` 的定义。
将以下行添加到 `HelloSimObject.py` 以导入 `SimObject` 的定义。

```python
from m5.objects.SimObject import SimObject
```

让我们为新 `SimObject` 添加定义。

```python
class HelloSimObject(SimObject):
    type = "HelloSimObject"
    cxx_header = "bootcamp/hello-sim-object/hello_sim_object.hh"
    cxx_class = "gem5::HelloSimObject"
```

---

<!--
Speaker Notes
- Understanding SimObject definition file
    - What is
        - type
        - cxx_header
        - cxx_class
    - MetaSimObject metaclass
 -->

## SimObject 定义文件：深入了解我们所做的工作

让我们更深入地了解我们拥有的几行代码。

```python
class HelloSimObject(SimObject):
    type = "HelloSimObject"
    cxx_header = "bootcamp/hello-sim-object/hello_sim_object.hh"
    cxx_class = "gem5::HelloSimObject"
```

- `type` 是 `SimObject` 在 Python 中的类型名称。
- `cxx_header` 表示在 C++ 中声明 `SimObject` 的 C++ 头文件路径。**重要**：此路径应相对于 `gem5/src` 指定。
- `cxx_class` 是你的 `SimObject` 类在 C++ 中的名称。

`type`、`cxx_header` 和 `cxx_class` 是由 `MetaSimObject` 元类定义的关键字。有关这些关键字的完整列表，请查看 [src/python/m5/SimObject::MetaSimObject](../../gem5/src/python/m5/SimObject.py)。可以跳过这些关键字变量中的一些（如果不是全部）。但是，我强烈建议你至少定义 `type`、`cxx_header`、`cxx_class`。

---

<!--
Speaker Notes
- Important Notes
    - Naming consistency
    - autogenerated params header file
 -->

## 给明智者的建议和对未来的小小展望

- 我强烈建议将 `type` 设置为 Python 中 `SimObject` 类的名称。我还建议确保 C++ 类名与 Python 类名相同。你会在整个 gem5 代码库中看到这*并不*总是如此。但是，我强烈建议遵循此规则以避免任何编译问题。

- 我们稍后会看到，当构建 gem5 时，将有一个**自动生成**的结构体定义来存储该类的参数。结构体的名称将由 `SimObject` 本身的名称决定。例如，如果 `SimObject` 的名称是 `HelloSimObject`，存储其参数的结构体将是 `HelloSimObjectParams`。此定义将在构建目录中的 [params/HelloSimObject.hh](../../gem5/build/NULL/params/HelloSimObject.hh) 文件下。此结构体在 C++ 中实例化 `SimObject` 对象时使用。

<!-- An object of a SimObject class? -->

---

<!--
Speaker Notes
- Creating header file
- Parallelizing inheritance for
    - Classes
    - Params
 -->

## SimObject 头文件：创建文件

现在，让我们开始在 C++ 中构建我们的 `SimObject`。首先，通过在基础 **gem5** 目录中运行以下命令为我们的 `SimObject` 创建一个文件。**记住**：我们将 `cxx_header` 设置为 `bootcamp/hello-sim-object/hello_sim_object.hh`。因此，我们需要在具有相同路径的文件中添加 `HelloSimObject` 的定义。

<!-- need to add the declaration? -->

```sh
touch src/bootcamp/hello-sim-object/hello_sim_object.hh
```

**非常重要**：如果 `SimObject` 类在 Python 中继承自另一个 `SimObject` 类，它在 C++ 中也应该这样做。例如，`HelloSimObject` 在 Python 中继承自 `SimObject`，所以在 C++ 中，`HelloSimObject` 应该继承自 `SimObject`。
**非常重要**：`SimObject` 参数结构体以与 `SimObject` 本身相同的方式继承。例如，如果 `HelloSimObject` 继承自 `SimObject`，则 `HelloSimObjectParams` 继承自 `SimObjectParams`。

---

<!--
Speaker Notes
- Finalizing header file
 -->

<!-- _class: code-60-percent -->

## SimObject 头文件：前几行

在你选择的编辑器中打开 [src/bootcamp/hello-sim-object/hello_sim_object.hh](../../gem5/src/bootcamp/hello-sim-object/hello_sim_object.hh) 并向其中添加以下代码。

```cpp
#ifndef __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__
#define __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__

#include "params/HelloSimObject.hh"
#include "sim/sim_object.hh"

namespace gem5
{

class HelloSimObject: public SimObject
{
  public:
    HelloSimObject(const HelloSimObjectParams& params);
};

} // namespace gem5

#endif // __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__
```

---

<!--
Speaker Notes
- __BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__
    - double includes/cyclic includes
- sim/sim_object.hh
- namespace gem5
    - specific namespaces
- HelloSimObject inherits from SimObject
- SimObject constructor

 -->

## SimObject 头文件：深入了解前几行

需要注意的事项：

<!-- - `sim/sim_object.hh` holds the definition for class `SimObject` in C++.
Should this be declaration? -->

- `__BOOTCAMP_HELLO_SIM_OBJECT_HELLO_SIM_OBJECT_HH__` 是一个包含保护，用于防止重复包含和循环包含。gem5 的约定是名称应反映头文件相对于 `gem5/src` 目录的位置，使用 `_` 作为分隔符。
- `sim/sim_object.hh` 包含 C++ 中 `SimObject` 类的定义。
- 如前所述，`params/HelloSimObject.hh` 是自动生成的，并声明了一个名为 `HelloSimObjectParams` 的结构体。
- 每个 `SimObject` 都应该在 `namespace gem5` 内声明/定义。不同类别的 `SimObjects` 可能有自己的特定命名空间，例如 `gem5::memory`。
- 类 `HelloSimObject`（Python 中 `HelloSimObject` 的 C++ 对应物）应该继承自类 `SimObject`（Python 中 `SimObject` 的 C++ 对应物）。
- 每个 `SimObject` 类都需要定义一个只接受一个参数的构造函数。此参数必须是其参数结构体的常量引用对象。稍后，我们将查看 gem5 从 `SimObject` 类实例化对象的内部过程。

---

<!--
Speaker Notes
- Creating and writing source file
 -->

<!-- _class: code-50-percent -->

## SimObject 源文件：所有代码

让我们在以下位置为 `HelloSimObject` 创建一个源文件：
[src/bootcamp/hello-sim-object/hello_sim_object.cc](../../gem5/src/bootcamp/hello-sim-object/hello_sim_object.cc)。

```sh
touch src/bootcamp/hello-sim-object/hello_sim_object.cc
```

在你选择的编辑器中打开 [src/bootcamp/hello-sim-object/hello_sim_object.cc](../../gem5/src/bootcamp/hello-sim-object/hello_sim_object.cc) 并向其中添加以下代码。

```cpp
#include "bootcamp/hello-sim-object/hello_sim_object.hh"

#include <iostream>

namespace gem5
{

HelloSimObject::HelloSimObject(const HelloSimObjectParams& params):
    SimObject(params)
{
    std::cout << "Hello from HelloSimObject's constructor!" << std::endl;
}

} // namespace gem5
```

---

<!--
Speaker Notes
- Include statement convention
- Constructors we defined
- Explain params object in the context of HelloSimObject
-->

<!-- In the last bullet point: I don't fully understand this line: This means params can be passed to the `SimObject::SimObject`
It can be passed to SimObject::SimObject because it inherits from SimObjectParams? It needs to be passed to SimObjectParams because of the nature of inheritance? Why do we need to pass to SimObject? -->

## SimObject 源文件：深入了解

需要注意的事项：

- gem5 的包含语句顺序约定如下。
  - `SimObject` 的头文件。
  - 按字母顺序排列的 C++ 库。
  - 按字母顺序排列的其他 gem5 头文件。
- 我们只定义 `HelloSimObject` 的构造函数，因为这是它目前唯一的函数。
- 传递给 `HelloSimObject::HelloSimObject` 构造函数的 `params` 对象是一个 `HelloSimObjectParams` 对象，它继承自 `SimObjectParams`。这意味着 `params` 可以传递给 `SimObject::SimObject` 构造函数。

---

<!--
Speaker Notes
- Why we need a SConscript
- Creating and writing a Sconscript
-->

## 开始构建：SConscript

我们需要将 `SimObject` 注册到 gem5，以便将其构建到 gem5 可执行文件中。在构建时，`scons`（gem5 的构建系统）将搜索 gem5 目录中名为 `SConscript` 的文件。`SConscript` 文件包含需要构建的内容的指令。我们只需通过在基础 **gem5** 目录中运行以下命令来创建一个名为 `SConscript` 的文件（在我们的 `SimObject` 目录内）。

```sh
touch src/bootcamp/hello-sim-object/SConscript
```

将以下内容添加到 [SConscript](../../gem5/src/bootcamp/hello-sim-object/SConscript)。

```python
Import("*")

SimObject("HelloSimObject.py", sim_objects=["HelloSimObject"])

Source("hello_sim_object.cc")
```

---

<!--
Speaker Notes
- Go through each line of SConscript
    - Import("*")
    - SimObject("HelloSimObject.py", sim_objects=["HelloSimObject"])
    - Source("hello_sim_object.cc")
-->

## 开始构建：深入了解 SConscript

需要注意的事项：

- `SimObject("HelloSimObject.py", sim_objects=["HelloSimObject"])` 将 `HelloSimObject` 注册为 `SimObject`。第一个参数表示将在 `m5.objects` 下创建的子模块的名称。列在 `sim_objects` 下的所有 `SimObjects` 都将添加到该子模块中。在此示例中，我们将能够将 `HelloSimObject` 导入为 `m5.objects.HelloSimObject.HelloSimObject`。可以在一个 Python 脚本中定义多个 `SimObject`。只有列在 `sim_objects` 下的 `SimObjects` 才会被构建。
- `Source("hello_sim_object.cc")` 将 `hello_sim_object.cc` 添加为要编译的源文件。

---

<!--
Speaker Notes
- Recompile gem5
- Creating directories and configuration script file path
 -->

## 让我们编译

现在，在我们可以在配置脚本中使用 `HelloSimObject` 之前，剩下的唯一事情就是重新编译 gem5。在基础 **gem5** 目录中运行以下命令以重新编译 gem5。

```sh
scons build/NULL/gem5.opt -j$(nproc)
```

在等待 gem5 构建时，我们将创建一个使用 `HelloSimObject` 的配置脚本。在单独的终端中，让我们在 [gem5/configs](../../gem5/configs/) 内创建该脚本。首先，让我们为脚本创建目录结构。在基础 **gem5** 目录中运行以下命令集以创建清晰的结构。

```sh
mkdir configs/bootcamp
mkdir configs/bootcamp/hello-sim-object
touch configs/bootcamp/hello-sim-object/first-hello-example.py
```

---

<!--
Speaker Notes
- Explaining import statements
    - Interfacing with backend
        - m5
    - Device tree (Explain in depth) (Consider visual)
        - Root
 -->

<!-- Might be worth mentioning the device tree earlier or dedicating a slide to it -->

## 配置脚本：第一个 Hello 示例：m5 和 Root

在你选择的编辑器中打开 [configs/bootcamp/first-hello-example.py](../../gem5/configs/bootcamp/hello-sim-object/first-hello-example.py)。

要运行模拟，我们需要与 gem5 的后端接口。`m5` 将允许我们调用 C++ 后端来在 C++ 中实例化 `SimObjects` 并模拟它们。要将 `m5` 导入到配置脚本中，请将以下内容添加到代码中。

```python
import m5
```

gem5 中的每个配置脚本都必须实例化 `Root` 类的对象。此对象表示 gem5 正在模拟的计算机系统中的设备树根。要将 `Root` 导入到配置中，请将以下行添加到脚本中。

```python
from m5.objects.Root import Root
```

---

<!--
Speaker Notes
- Importing HelloSimObject
- Creating device tree in code
 -->

## 配置脚本：第一个 Hello 示例：在 Python 中创建实例

我们还需要将 `HelloSimObject` 导入到配置脚本中。为此，请将以下行添加到配置脚本中。

```python
from m5.objects.HelloSimObject import HelloSimObject
```

接下来我们需要做的是创建一个 `Root` 对象和一个 `HelloSimObject` 对象。我们可以使用 `.` 运算符将 `HelloSimObject` 对象添加为 `root` 对象的子对象。将以下行添加到配置中以执行此操作。

```python
root = Root(full_system=False)
root.hello = HelloSimObject()
```

**注意**：我们将 `full_system=False` 传递给 `Root`，因为我们将在 `SE` 模式下进行模拟。

---

<!--
Speaker Notes
- m5.instantiate()
- m5.simulate()
- getCause()
 -->

## 配置脚本：第一个 Hello 示例：在 C++ 中实例化和模拟

接下来，让我们通过从 `m5` 调用 `instantiate` 来告诉 gem5 在 C++ 中实例化我们的 `SimObjects`。将以下行添加到代码中以执行此操作。

```python
m5.instantiate()
```

现在我们已经实例化了 `SimObjects`，我们可以告诉 gem5 开始模拟。我们通过从 `m5` 调用 `simulate` 来做到这一点。将以下行添加到代码中以执行此操作。

```python
exit_event = m5.simulate()
```

此时，模拟将开始。它将返回一个保存模拟状态的对象。我们可以通过从 `exit_event` 调用 `getCause` 来查看模拟退出的原因。将以下行添加到代码中以执行此操作。

```python
print(f"Exited simulation because: {exit_event.getCause()}.")
```

---

<!--
Speaker Notes
- Complete configuration script
 -->

## 一切都在这里

这是我们配置脚本的完整版本。

```python
import m5
from m5.objects.Root import Root
from m5.objects.HelloSimObject import HelloSimObject

root = Root(full_system=False)
root.hello = HelloSimObject()

m5.instantiate()
exit_event = m5.simulate()

print(f"Exited simulation because: {exit_event.getCause()}.")
```

---

<!--
Speaker Notes
- Command to run
 -->

## 模拟：第一个 Hello 示例

在基础 **gem5** 目录中使用以下命令运行。

```sh
./build/NULL/gem5.opt ./configs/bootcamp/hello-sim-object/first-hello-example.py
```

<script src="https://asciinema.org/a/ffjsHBq6mPCR1DPxT15WCkm58.js" id="asciicast-ffjsHBq6mPCR1DPxT15WCkm58" async="true"></script>

---
<!-- _class: start -->

## 步骤 1 结束

---

<!-- _class: start -->

## 一点绕路：m5.instantiate

---

<!--
Speaker Notes
- What happens when m5.instantiate() is called
    - SimObjects created
    - Ports
 -->

## 绕路：m5.instantiate：SimObject 构造函数和连接端口

以下是 `m5.instantiate` 定义中的代码片段：

```python
# Create the C++ sim objects and connect ports
    for obj in root.descendants():
        obj.createCCObject()
    for obj in root.descendants():
        obj.connectPorts()
```

当你调用 `m5.instantiate` 时，首先，所有 `SimObjects` 都被创建（即调用它们的 C++ 构造函数）。然后，创建所有 `port` 连接。如果你不知道 `Port` 是什么，别担心。我们将在后面的幻灯片中介绍。现在，将 `ports` 视为 `SimObjects` 相互发送数据的一种方式。

---

<!--
Speaker Notes
- What happens when m5.instantiate() is called
    - init (for all SimObjects)
 -->


<!-- _class: code-50-percent -->

## 绕路：m5.instantiate：SimObject::init

以下是 `instantiate` 中稍后的代码片段。

```python
    # Do a second pass to finish initializing the sim objects
    for obj in root.descendants():
        obj.init()
```

在此步骤中，gem5 将从每个 `SimObject` 调用 `init` 函数。`init` 是由 `SimObject` 类定义的虚函数。每个基于 `SimObject` 的类都可以重写此函数。`init` 函数的目的是类似于构造函数。但是，保证当从任何 `SimObject` 调用 `init` 函数时，所有 `SimObjects` 都已创建（即已调用它们的构造函数）。

Below is the declaration for `init` in `src/sim/sim_object.hh`.

```cpp
    /* init() is called after all C++ SimObjects have been created and
    *  all ports are connected.  Initializations that are independent
    *  of unserialization but rely on a fully instantiated and
    *  connected SimObject graph should be done here. */
    virtual void init();
```

---

<!--
Speaker Notes
- What happens when m5.instantiate() is called
    - checkpoints (explain in depth)
    - initState and loadState
 -->

<!-- _class: code-80-percent -->

## 绕路：m5.instantiate：SimObject::initState、SimObject::loadState

下面显示了来自 instantiate 的另一个代码片段：

```python
# Restore checkpoint (if any)
    if ckpt_dir:
        _drain_manager.preCheckpointRestore()
        ckpt = _m5.core.getCheckpoint(ckpt_dir)
        for obj in root.descendants():
            obj.loadState(ckpt)
    else:
        for obj in root.descendants():
            obj.initState()
```

`initState` 和 `loadState` 是初始化 `SimObjects` 的最后一步。但是，每次模拟只调用其中一个。`loadState` 被调用来从检查点反序列化 `SimObject` 的状态，而 `initState` 仅在启动新模拟时调用（即不从检查点）。

继续下一页。

---

<!--
Speaker Notes
- loadState code
    - Words to explain
        - unserialize()
        - hook
        - cold start
-->

## Detour: m5.instantiate: SimObject::initState, SimObject::loadState: C++

Below is the declaration for `initState` and `loadState` in `src/sim/sim_object.hh`.

```cpp
    /* loadState() is called on each SimObject when restoring from a
    *  checkpoint.  The default implementation simply calls
    *  unserialize() if there is a corresponding section in the
    *  checkpoint.  However, objects can override loadState() to get
    *  other behaviors, e.g., doing other programmed initializations
    *  after unserialize(), or complaining if no checkpoint section is
    *  found. */
    virtual void loadState(CheckpointIn &cp);
    /* initState() is called on each SimObject when *not* restoring
    *  from a checkpoint.  This provides a hook for state
    *  initializations that are only required for a "cold start". */
    virtual void initState();
```

---

<!--
Speaker Notes
- HelloSimObject relation to m5.simulate
-->

## 我们稍后会看到

你可能已经注意到，我们也在配置脚本中调用了 `m5.simulate`。目前，`HelloSimObject` 在模拟期间不做任何有趣的事情。我们稍后将查看 simulate 的详细信息。

---
<!-- _class: start -->

## 参数

---
<!-- _class: start -->

## 步骤 2：SimObject 参数

---

<!--
Speaker Notes
- Updating definition file
    - m5.params
    - New parameter (num_hellos)
- parameter classes/how to add a parameter
-->

<!-- _class: code-60-percent -->

## 让我们谈谈参数：模型 vs 参数

<!-- ask Jason for good example analogy for Model vs Params (cache is a model and cache size is a param) -->

正如我们之前提到的，gem5 允许我们参数化模型。gem5 中的整个参数类集在 `m5.params` 下定义，因此让我们继续从 `m5.params` 将所有内容导入到 `SimObject` 定义文件中。在你选择的编辑器中打开 [src/bootcamp/hello-sim-object/HelloSimObject.py](../../gem5/src/bootcamp/hello-sim-object/HelloSimObject.py) 并向其中添加以下行。

```python
from m5.params import *
```

现在，我们只需要为 `HelloSimObject` 定义一个参数。将以下行添加到同一文件（`HelloSimObject` 定义）中。你应该在 `class HelloSimObject` 的定义下添加此行。

```python
num_hellos = Param.Int("Number of times to say Hello.")
```

请务必查看 [src/python/m5/params.py](../../gem5/src/python/m5/params.py) 以获取有关不同参数类以及如何添加参数的更多信息。
**注意**：`Params` 允许你为它们定义默认值。我强烈建议除非真的需要，否则不要定义默认值。

---

<!--
Speaker Notes
- Final definition file
-->

## HelloSimObject 定义文件现在

这是你的 `HelloSimObject` 定义文件在更改后应该看起来的样子。

```python
from m5.objects.SimObject import SimObject
from m5.params import *

class HelloSimObject(SimObject):
    type = "HelloSimObject"
    cxx_header = "bootcamp/hello-sim-object/hello_sim_object.hh"
    cxx_class = "gem5::HelloSimObject"

    num_hellos = Param.Int("Number times to say Hello.")
```

**注意**：对 `HelloSimObject.py` 的此更改将在下次编译 gem5 时向 `HelloSimObjectParams` 添加一个属性。这意味着我们现在可以在 C++ 代码中访问此参数。

---

<!--
Speaker Notes
- Updating source file to use num_hellos
    - Explain that you are NOT replacing the ENTIRE file with this code (only updating the class)
- Recompile
-->

<!-- _class: code-50-percent -->

## 使用 num_hellos

现在，我们将使用 `num_hellos` 在 `HelloSimObject` 的构造函数中多次打印 `Hello from ...`。在你选择的编辑器中打开 [src/bootcamp/hello-sim-object/hello_sim_object.cc](../../gem5/src/bootcamp/hello-sim-object/hello_sim_object.cc)。

如下更改 `HelloSimObject::HelloSimObject`：

```cpp
HelloSimObject::HelloSimObject(const HelloSimObjectParams& params):
    SimObject(params)
{
    for (int i = 0; i < params.num_hellos; i++) {
        std::cout << "i: " << i << ", Hello from HelloSimObject's constructor!" << std::endl;
    }
}
```

确保不要删除 `include` 语句和任何包含 `namespace gem5` 的行

***重新编译***：我们现在需要做的就是重新编译 gem5。只需在基础 **gem5** 目录中运行以下命令即可。

```sh
scons build/NULL/gem5.opt -j$(nproc)
```

---

<!--
Speaker Notes
- Auto-generated param header file
-->

<!-- _class: two-col code-60-percent -->

## params/HelloSimObject.hh

正如我们之前提到的，`SimObject` 的参数在自动生成的头文件中定义，文件名与 `SimObject` 的名称相同。

现在我们已经向 `HelloSimObject` 添加了一个参数，它现在应该在 [build/NULL/params/HelloSimObject.hh](../../gem5/build/NULL/params/HelloSimObject.hh) 中的 `HelloSimObjectParams` 下定义。

如果你查看头文件，你应该看到类似这样的内容。

###

```cpp
#ifndef __PARAMS__HelloSimObject__
#define __PARAMS__HelloSimObject__

namespace gem5 {
class HelloSimObject;
} // namespace gem5
#include <cstddef>
#include "base/types.hh"

#include "params/SimObject.hh"

namespace gem5
{
struct HelloSimObjectParams
    : public SimObjectParams
{
    gem5::HelloSimObject * create() const;
    int num_hellos;
};

} // namespace gem5

#endif // __PARAMS__HelloSimObject__
```

---

<!--
Speaker Notes
- Creating a new configuration script
- Adding param num_hellos
-->

<!-- _class: code-60-percent -->

## 配置脚本：第二个 Hello 示例

让我们创建 [first-hello-example.py](../../gem5/configs/bootcamp/hello-sim-object/first-hello-example.py) 的副本，命名为 [second-hello-example.py](../../gem5/configs/bootcamp/hello-sim-object/second-hello-example.py)。只需在基础 **gem5** 目录中运行以下命令即可。

```sh
cp configs/bootcamp/hello-sim-object/first-hello-example.py configs/bootcamp/hello-sim-object/second-hello-example.py
```

现在，在你选择的编辑器中打开 [second-hello-example.py](../../gem5/configs/bootcamp/hello-sim-object/second-hello-example.py) 并更改代码，以便在实例化 `HelloSimObject` 时为 `num_hellos` 传递一个值。下面是一个完整的示例。

```python
import m5
from m5.objects.Root import Root
from m5.objects.HelloSimObject import HelloSimObject

root = Root(full_system=False)
root.hello = HelloSimObject(num_hellos=5)

m5.instantiate()
exit_event = m5.simulate()

print(f"Exited simulation because: {exit_event.getCause()}.")
```

---

<!--
Speaker Notes
- Command to run with
-->

## 模拟：第二个 Hello 示例

在基础 **gem5** 目录中使用以下命令运行。

```sh
./build/NULL/gem5.opt ./configs/bootcamp/hello-sim-object/second-hello-example.py
```

<script src="https://asciinema.org/a/P1nULfk7VRZGvQURZJryl7mAK.js" id="asciicast-P1nULfk7VRZGvQURZJryl7mAK" async="true"></script>

---
<!-- _class: start -->

## 步骤 2 结束

---

<!-- _class: two-col -->

## 步骤总结

- 创建基本的 `SimObject`
    - [`SimObject` 定义文件](../../gem5/src/bootcamp/hello-sim-object/HelloSimObject.py) (.py)
        - 定义模型的参数集。
    - [`SimObject` 头文件](../../gem5/src/bootcamp/hello-sim-object/hello_sim_object.hh) (.hh)
        - 在 C++ 中声明 `SimObject` 类。
    - [`SimObject` 源文件](../../gem5/src/bootcamp/hello-sim-object/hello_sim_object.cc) (.cc 扩展名)：
        - 实现 `SimObject` 的功能。
    - [`SConscript`](../../gem5/src/bootcamp/hello-sim-object/SConscript)
        - 将我们的 `SimObject` 注册到 gem5。
    - 自动生成的 [`SimObjectParams` 头文件](../../gem5/build/NULL/params/HelloSimObject.hh) (.hh)
        - 声明一个存储 `SimObject` 所有参数的 C++ 结构体。
    - [配置文件](../../gem5/configs/bootcamp/hello-sim-object/first-hello-example.py) (.py)
        - 实例化 `SimObject` 并运行模拟。
- 添加参数（`num_hellos`）
    - 更新[定义文件](../../gem5/src/bootcamp/hello-sim-object/HelloSimObject.py)和[源文件](../../gem5/src/bootcamp/hello-sim-object/hello_sim_object.cc)。
    - 编写新的[配置文件](../../gem5/configs/bootcamp/hello-sim-object/second-hello-example.py)。
    - 重新编译并重新运行。
