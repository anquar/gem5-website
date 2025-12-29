---
layout: documentation
title: 创建一个非常简单的 SimObject
doc: Learning gem5
parent: part2
permalink: /documentation/learning_gem5/part2/helloobject/
author: Jason Lowe-Power
---


创建一个 *非常* 简单的 SimObject
==================================

**注意**：gem5 有一个名为 `SimpleObject` 的 SimObject。实现另一个 `SimpleObject` SimObject 会导致令人困惑的编译器问题。

gem5 中几乎所有对象都继承自基本 SimObject 类型。SimObject 导出了 gem5 中所有对象的主要接口。SimObject 是封装的 `C++` 对象，可从 `Python` 配置脚本访问。

SimObject 可以有许多参数，这些参数通过 `Python` 配置文件设置。除了整数和浮点数等简单参数外，它们还可以将其他 SimObject 作为参数。这允许您创建复杂的系统层次结构，如真实机器。

在本章中，我们将逐步创建一个简单的 "HelloWorld" SimObject。目的是向您介绍如何创建 SimObject 以及所有 SimObject 所需的样板代码。我们还将创建一个简单的 `Python` 配置脚本来实例化我们的 SimObject。

在接下来的几章中，我们将采用这个简单的 SimObject 并对其进行扩展，以包括 [调试支持](../debugging)、[动态事件](../events) 和 [参数](../parameters)。

> **使用 git 分支**
>
> 为您添加到 gem5 的每个新功能使用新的 git 分支是很常见的。
>
> 添加新功能或修改 gem5 中的某些内容时的第一步是创建一个新分支来存储您的更改。有关 git 分支的详细信息可以在 Git book 中找到。
>
> ```
> git checkout -b hello-simobject
> ```

第一步：为您的新 SimObject 创建一个 Python 类
----------------------------------------------------

每个 SimObject 都有一个与之关联的 Python 类。此 Python 类描述了您的 SimObject 的参数，这些参数可以从 Python 配置文件进行控制。对于我们简单的 SimObject，我们将从没有参数开始。因此，我们只需要为我们的 SimObject 声明一个新类，并设置它的名称和将定义 SimObject 的 C++ 类的 C++ 头文件。

我们可以在 `src/learning_gem5/part2` 中创建一个文件 `HelloObject.py`。
如果您已经克隆了 gem5 仓库，您将在 `src/learning_gem5/part2` 和 `configs/learning_gem5/part2` 下完成本教程中提到的文件。您可以删除这些文件或将它们移动到其他位置以按照本教程进行操作。

```python
from m5.params import *
from m5.SimObject import SimObject

class HelloObject(SimObject):
    type = 'HelloObject'
    cxx_header = "learning_gem5/part2/hello_object.hh"
    cxx_class = "gem5::HelloObject"
```

[//]: # 您可以找到完整的文件
[//]: # [这里](/_static/scripts/part2/helloobject/HelloObject.py)

`type` 不一定非要与类名相同，但这是一种惯例。`type` 是您用此 Python SimObject 包装的 C++ 类。只有在特殊情况下，`type` 和类名才应该不同。

`cxx_header` 是包含用作 `type` 参数的类声明的文件。同样，惯例是使用全部小写和下划线的 SimObject 名称，但这只是惯例。您可以在此处指定任何头文件。

`cxx_class` 是一个属性，指定新创建的 SimObject 在 gem5 命名空间内声明。gem5 代码库中的大多数 SimObject 都在 gem5 命名空间内声明！

第二步：在 C++ 中实现您的 SimObject
---------------------------------------

接下来，我们需要在 `src/learning_gem5/part2/` 目录中创建 `hello_object.hh` 和 `hello_object.cc`，这将实现 `HelloObject`。

我们将从 `C++` 对象的头文件开始。按照惯例，gem5 将所有头文件包装在带有文件名及其所在目录的 `#ifndef/#endif` 中，以避免循环包含。

SimObject 应在 gem5 命名空间内声明。因此，我们在 `namespace gem5` 范围内声明我们的类。

我们在文件中唯一需要做的就是声明我们的类。由于 `HelloObject` 是一个 SimObject，它必须继承自 C++ SimObject 类。大多数时候，您的 SimObject 的父类将是 SimObject 的子类，而不是 SimObject 本身。

SimObject 类指定了许多虚函数。但是，这些函数都不是纯虚函数，因此在最简单的情况下，除了构造函数之外，不需要实现任何函数。

所有 SimObject 的构造函数都假设它将接受一个参数对象。此参数对象由构建系统自动创建，并且基于 SimObject 的 `Python` 类，就像我们在上面创建的那样。此参数类型的名称是根据对象名称自动生成的。对于我们的 "HelloObject"，参数类型的名称是 "HelloObjectParams"。

我们的简单头文件所需的代码如下所列。

```cpp
#ifndef __LEARNING_GEM5_HELLO_OBJECT_HH__
#define __LEARNING_GEM5_HELLO_OBJECT_HH__

#include "params/HelloObject.hh"
#include "sim/sim_object.hh"

namespace gem5
{

class HelloObject : public SimObject
{
  public:
    HelloObject(const HelloObjectParams &p);
};

} // namespace gem5

#endif // __LEARNING_GEM5_HELLO_OBJECT_HH__
```

[//]: # 您可以找到完整的文件
[//]: # [这里](/_pages/static/scripts/part2/helloobject/hello_object.hh).

接下来，我们需要在 `.cc` 文件中实现 *两个* 函数，而不仅仅是一个。第一个函数是 `HelloObject` 的构造函数。在这里，我们只是将参数对象传递给 SimObject 父类并打印 "Hello world!"

通常，您 **永远不会** 在 gem5 中使用 `std::cout`。相反，您应该使用调试标志。在 [下一章](../debugging) 中，我们将修改此代码以改用调试标志。但是，目前，我们将简单地使用 `std::cout`，因为它很简单。

```cpp
#include "learning_gem5/part2/hello_object.hh"

#include <iostream>

namespace gem5
{

HelloObject::HelloObject(const HelloObjectParams &params) :
    SimObject(params)
{
    std::cout << "Hello World! From a SimObject!" << std::endl;
}

} // namespace gem5
```

**注意**：如果您的 SimObject 的构造函数遵循以下签名，

```cpp
Foo(const FooParams &)
```

那么将自动定义 `FooParams::create()` 方法。`create()` 方法的目的是调用 SimObject 构造函数并返回 SimObject 的实例。大多数 SimObject 将遵循此模式；但是，如果您的 SimObject 不遵循此模式，
[gem5 SimObject 文档](http://doxygen.gem5.org/release/current/classSimObject.html#details) 提供了有关手动实现 `create()` 方法的更多信息。


[//]: # 您可以找到完整的文件
[//]: # [这里](/_pages/static/scripts/part2/helloobject/hello_object.cc).


第三步：注册 SimObject 和 C++ 文件
-------------------------------------------

为了编译 `C++` 文件并解析 `Python` 文件，我们需要告诉构建系统有关这些文件的信息。gem5 使用 SCons 作为构建系统，因此您只需在包含 SimObject 代码的目录中创建一个 SConscript 文件。如果该目录已有 SConscript 文件，只需将以下声明添加到该文件中。

此文件只是一个普通的 `Python` 文件，因此您可以在此文件中编写任何您想要的 `Python` 代码。有些脚本可能会变得相当复杂。gem5 利用这一点自动为 SimObject 创建代码，并编译领域特定语言，如 SLICC 和 ISA 语言。

在 SConscript 文件中，导入后会自动定义许多函数。请参阅有关那部分的内容...

要让您的新 SimObject 编译，您只需在 `src/learning_gem5/part2` 目录下创建一个名为 "SConscript" 的新文件。在此文件中，您必须声明 SimObject 和 `.cc` 文件。下面是所需的代码。

```python
Import('*')

SimObject('HelloObject.py', sim_objects=['HelloObject'])
Source('hello_object.cc')
```

[//]: # 您可以找到完整的文件
[//]: # [这里](/_pages/static/scripts/part2/helloobject/SConscript).

第四步：(重新)构建 gem5
-----------------------

要编译并链接您的新文件，您只需重新编译 gem5。
下面的示例假设您使用的是 x86 ISA，但我们的对象中没有任何内容需要 ISA，因此这适用于任何 gem5 的 ISA。

```
scons build/ALL/gem5.opt
```

第五步：创建配置脚本以使用您的新 SimObject
-----------------------------------------------------------

既然您已经实现了一个 SimObject，并且它已被编译到 gem5 中，您需要在 `configs/learning_gem5/part2` 中创建或修改一个 `Python` 配置文件 `run_hello.py` 来实例化您的对象。由于您的对象非常简单，因此不需要系统对象！不需要 CPU，或缓存，或任何东西，除了一个 `Root` 对象。所有 gem5 实例都需要一个 `Root` 对象。

逐步创建一个 *非常* 简单的配置脚本，首先，导入 m5 和所有您已编译的对象。

```python
import m5
from m5.objects import *
```

接下来，您必须实例化 `Root` 对象，这是所有 gem5 实例所必需的。

```python
root = Root(full_system = False)
```

现在，您可以实例化您创建的 `HelloObject`。您所要做的就是调用 `Python` "构造函数"。稍后，我们将看看如何通过 `Python` 构造函数指定参数。除了创建对象的实例化之外，还需要确保它是根对象的子对象。只有作为 `Root` 对象的子对象的 SimObject 才会用 `C++` 实例化。

```python
root.hello = HelloObject()
```

最后，您需要调用 `m5` 模块上的 `instantiate` 并实际运行模拟！

```python
m5.instantiate()

print("Beginning simulation!")
exit_event = m5.simulate()
print('Exiting @ tick {} because {}'
      .format(m5.curTick(), exit_event.getCause()))
```

[//]: # 您可以找到完整的文件
[//]: # [这里](/_pages/static/scripts/part2/helloobject/run_hello.py).

请记住在修改 src/ 目录中的文件后重新构建 gem5。运行配置文件的命令行在下面的输出中，在 'command line:' 之后。输出应该如下所示：

注意：如果未来部分“向 SimObjects 添加参数和更多事件”的代码 (goodbye_object) 在您的 `src/learning_gem5/part2` 目录中，run_hello.py 将导致错误。如果您删除这些文件或将它们移出 gem5 目录，`run_hello.py` 应该会给出下面的输出。

```
    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 compiled May  4 2016 11:37:41
    gem5 started May  4 2016 11:44:28
    gem5 executing on mustardseed.cs.wisc.edu, pid 22480
    command line: build/X86/gem5.opt configs/learning_gem5/part2/run_hello.py

    Global frequency set at 1000000000000 ticks per second
    Hello World! From a SimObject!
    Beginning simulation!
    info: Entering event queue @ 0.  Starting simulation...
    Exiting @ tick 18446744073709551615 because simulate() limit reached
```
恭喜！您已经编写了您的第一个 SimObject。在接下来的章节中，我们将扩展这个 SimObject 并探索您可以用 SimObject 做什么。
