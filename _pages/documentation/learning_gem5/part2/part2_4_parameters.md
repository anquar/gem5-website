---
layout: documentation
title: 向 SimObjects 添加参数和更多事件
doc: Learning gem5
parent: part2
permalink: /documentation/learning_gem5/part2/parameters/
author: Jason Lowe-Power
---


向 SimObjects 添加参数和更多事件
===============================================

gem5 的 Python 接口最强大的部分之一是能够将参数从 Python 传递到 gem5 中的 C++ 对象。在本章中，我们将探索 SimObject 的一些参数类型，以及如何基于 [前几章](http://www.gem5.org/documentation/learning_gem5/part2/helloobject/) 中的简单 `HelloObject` 使用它们。

简单参数
-----------------

首先，我们将在 `HelloObject` 中添加延迟和触发事件次数的参数。要添加参数，请修改 SimObject Python 文件 (`src/learning_gem5/part2/HelloObject.py`) 中的 `HelloObject` 类。通过向包含 `Param` 类型的 Python 类添加新语句来设置参数。

例如，以下代码有一个 `time_to_wait` 参数，它是 "Latency" 参数，还有一个 `number_of_fires`，它是整数参数。

```python
class HelloObject(SimObject):
    type = 'HelloObject'
    cxx_header = "learning_gem5/part2/hello_object.hh"

    time_to_wait = Param.Latency("Time before firing the event")
    number_of_fires = Param.Int(1, "Number of times to fire the event before "
                                   "goodbye")
```

`Param.<TypeName>` 声明一个类型为 `TypeName` 的参数。常见类型有用于整数的 `Int`、用于浮点数的 `Float` 等。这些类型的行为类似于常规 Python 类。

每个参数声明接受一个或两个参数。当给出两个参数时（如上面的 `number_of_fires`），第一个参数是参数的 *默认值*。在这种情况下，如果您在 Python 配置文件中实例化 `HelloObject` 而没有为 number\_of\_fires 指定任何值，它将采用默认值 1。

参数声明的第二个参数是参数的简短描述。这必须是 Python 字符串。如果您只为参数声明指定一个参数，那就是描述（如 `time_to_wait`）。

gem5 还支持许多不仅仅是内置类型的复杂参数类型。例如，`time_to_wait` 是一个 `Latency`。`Latency` 将时间值作为字符串并将其转换为模拟器 **ticks**。例如，默认 tick 速率为 1 皮秒（10\^12 ticks 每秒或 1 THz），`"1ns"` 会自动转换为 1000。还有其他方便的参数，如 `Percent`、`Cycles`、`MemorySize` 等等。

一旦在 SimObject 文件中声明了这些参数，您需要在 C++ 类的构造函数中复制它们的值。以下代码显示了对 `HelloObject` 构造函数的更改。

```cpp
HelloObject::HelloObject(const HelloObjectParams &params) :
    SimObject(params),
    event(*this),
    myName(params.name),
    latency(params.time_to_wait),
    timesLeft(params.number_of_fires)
{
    DPRINTF(Hello, "Created the hello object with the name %s\n", myName);
}
```

在这里，我们将参数的值用于 latency 和 timesLeft 的默认值。此外，我们存储来自参数对象的 `name` 以供稍后在成员变量 `myName` 中使用。每个 `params` 实例化都有一个名称，该名称在实例化时来自 Python 配置文件。

但是，在这里分配名称只是使用 params 对象的一个示例。对于所有 SimObject，都有一个 `name()` 函数始终返回名称。因此，永远不需要像上面那样存储名称。

在 HelloObject 类声明中，为名称添加一个成员变量。

```cpp
class HelloObject : public SimObject
{
  private:
    void processEvent();

    EventWrapper event;

    const std::string myName;

    const Tick latency;

    int timesLeft;

  public:
    HelloObject(HelloObjectParams *p);

    void startup() override;
};
```

当我们用上面的代码运行 gem5 时，我们会得到以下错误：

    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 compiled Jan  4 2017 14:46:36
    gem5 started Jan  4 2017 14:46:52
    gem5 executing on chinook, pid 3422
    command line: build/X86/gem5.opt --debug-flags=Hello configs/learning_gem5/part2/run_hello.py

    Global frequency set at 1000000000000 ticks per second
    fatal: hello.time_to_wait without default or user set value

这是因为 `time_to_wait` 参数没有默认值。因此，我们需要更新 Python 配置文件 (`run_hello.py`) 来指定此值。

```python
root.hello = HelloObject(time_to_wait = '2us')
```

或者，我们可以将 `time_to_wait` 指定为成员变量。任一选项完全相同，因为直到调用 `m5.instantiate()` 才会创建 C++ 对象。

```python
root.hello = HelloObject()
root.hello.time_to_wait = '2us'
```

运行 `Hello` 调试标志时，此简单脚本的输出如下。

    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 compiled Jan  4 2017 14:46:36
    gem5 started Jan  4 2017 14:50:08
    gem5 executing on chinook, pid 3455
    command line: build/X86/gem5.opt --debug-flags=Hello configs/learning_gem5/part2/run_hello.py

    Global frequency set at 1000000000000 ticks per second
          0: hello: Created the hello object with the name hello
    Beginning simulation!
    info: Entering event queue @ 0.  Starting simulation...
    2000000: hello: Hello world! Processing the event! 0 left
    2000000: hello: Done firing!
    Exiting @ tick 18446744073709551615 because simulate() limit reached

您也可以修改配置脚本以多次触发事件。

其他 SimObjects 作为参数
------------------------------

您也可以指定其他 SimObjects 作为参数。为了演示这一点，我们将创建一个名为 `GoodbyeObject` 的新 SimObject。此对象将具有一个简单的函数，对另一个 SimObject 说 "Goodbye"。为了让它更有趣一点，`GoodbyeObject` 将有一个缓冲区来写入消息，以及有限的带宽来写入消息。

首先，在 SConscript 文件中声明 SimObject：

```python
Import('*')

SimObject('HelloObject.py', sim_objects=['HelloObject', 'GoodbyeObject'])
Source('hello_object.cc')
Source('goodbye_object.cc')

DebugFlag('Hello')
```

新的 SConscript 文件可以下载
[这里](/_pages/static/scripts/part2/parameters/SConscript)。

接下来，您需要在 SimObject Python 文件中声明新的 SimObject。由于 `GoodbyeObject` 与 `HelloObject` 高度相关，我们将使用同一个文件。您可以将以下代码添加到 `HelloObject.py`。

此对象有两个参数，都有默认值。第一个参数是缓冲区的大小，是一个 `MemorySize` 参数。第二个是 `write_bandwidth`，它指定填充缓冲区的速度。一旦缓冲区已满，模拟将退出。

```python
class GoodbyeObject(SimObject):
    type = 'GoodbyeObject'
    cxx_header = "learning_gem5/part2/goodbye_object.hh"
    cxx_class = "gem5::GoodbyeObject"

    buffer_size = Param.MemorySize('1kB',
                                   "Size of buffer to fill with goodbye")
    write_bandwidth = Param.MemoryBandwidth('100MB/s', "Bandwidth to fill "
                                            "the buffer")
```

更新后的 `HelloObject.py` 文件可以下载
[这里](/_pages/static/scripts/part2/parameters/HelloObject.py)。

现在，我们需要实现 `GoodbyeObject`。

```cpp
#ifndef __LEARNING_GEM5_GOODBYE_OBJECT_HH__
#define __LEARNING_GEM5_GOODBYE_OBJECT_HH__

#include <string>

#include "params/GoodbyeObject.hh"
#include "sim/sim_object.hh"

class GoodbyeObject : public SimObject
{
  private:
    void processEvent();

    /**
     * Fills the buffer for one iteration. If the buffer isn't full, this
     * function will enqueue another event to continue filling.
     */
    void fillBuffer();

    EventWrapper<GoodbyeObject, &GoodbyeObject::processEvent> event;

    /// The bytes processed per tick.
    float bandwidth;

    /// The size of the buffer we are going to fill.
    int bufferSize;

    /// The buffer we are putting our message in.
    char *buffer;

    /// The message to put into the buffer.
    std::string message;

    /// The amount of the buffer we've used so far.
    int bufferUsed;

  public:
    GoodbyeObject(GoodbyeObjectParams *p);
    ~GoodbyeObject();

    /**
     * Called by an outside object. Starts off the events to fill the buffer
     * with a goodbye message.
     *
     * @param name the name of the object we are saying goodbye to.
     */
    void sayGoodbye(std::string name);
};

#endif // __LEARNING_GEM5_GOODBYE_OBJECT_HH__
```

```cpp
#include "learning_gem5/part2/goodbye_object.hh"

#include "base/trace.hh"
#include "debug/Hello.hh"
#include "sim/sim_exit.hh"

GoodbyeObject::GoodbyeObject(const GoodbyeObjectParams &params) :
    SimObject(params), event(*this), bandwidth(params.write_bandwidth),
    bufferSize(params.buffer_size), buffer(nullptr), bufferUsed(0)
{
    buffer = new char[bufferSize];
    DPRINTF(Hello, "Created the goodbye object\n");
}

GoodbyeObject::~GoodbyeObject()
{
    delete[] buffer;
}

void
GoodbyeObject::processEvent()
{
    DPRINTF(Hello, "Processing the event!\n");
    fillBuffer();
}

void
GoodbyeObject::sayGoodbye(std::string other_name)
{
    DPRINTF(Hello, "Saying goodbye to %s\n", other_name);

    message = "Goodbye " + other_name + "!! ";

    fillBuffer();
}

void
GoodbyeObject::fillBuffer()
{
    // 最好有一条消息
    assert(message.length() > 0);

    // Copy from the message to the buffer per byte.
    int bytes_copied = 0;
    for (auto it = message.begin();
         it < message.end() && bufferUsed < bufferSize - 1;
         it++, bufferUsed++, bytes_copied++) {
        // Copy the character into the buffer
        buffer[bufferUsed] = *it;
    }

    if (bufferUsed < bufferSize - 1) {
        // Wait for the next copy for as long as it would have taken
        DPRINTF(Hello, "Scheduling another fillBuffer in %d ticks\n",
                bandwidth * bytes_copied);
        schedule(event, curTick() + bandwidth * bytes_copied);
    } else {
        DPRINTF(Hello, "Goodbye done copying!\n");
        // Be sure to take into account the time for the last bytes
        exitSimLoop(buffer, 0, curTick() + bandwidth * bytes_copied);
    }
}
```

头文件可以下载
[这里](/_pages/static/scripts/part2/parameters/goodbye_object.hh) 且实现可以下载
[这里](/_pages/static/scripts/part2/parameters/goodbye_object.cc)。

这个 `GoodbyeObject` 的接口是一个简单的函数 `sayGoodbye`，它接受一个字符串作为参数。调用此函数时，模拟器构建消息并将其保存在成员变量中。然后，我们开始填充缓冲区。

为了模拟有限的带宽，每次我们将消息写入缓冲区时，我们会暂停写入消息所需的延迟。我们使用一个简单的事件来模拟此暂停。

由于我们在 SimObject 声明中使用了 `MemoryBandwidth` 参数，`bandwidth` 变量会自动转换为每字节的 ticks，因此计算延迟只是带宽乘以我们要写入缓冲区的字节数。

最后，当缓冲区已满时，我们调用函数 `exitSimLoop`，它将退出模拟。此函数接受三个参数，第一个是返回给 Python 配置脚本的消息 (`exit_event.getCause()`)，第二个是退出代码，第三个是何时退出。

### 将 GoodbyeObject 作为参数添加到 HelloObject

首先，我们还将添加一个 `GoodbyeObject` 作为 `HelloObject` 的参数。为此，您只需将 SimObject 类名指定为 `Param` 的 `TypeName`。您可以有默认值，或者没有，就像普通参数一样。

```python
class HelloObject(SimObject):
    type = 'HelloObject'
    cxx_header = "learning_gem5/part2/hello_object.hh"

    time_to_wait = Param.Latency("Time before firing the event")
    number_of_fires = Param.Int(1, "Number of times to fire the event before "
                                   "goodbye")

    goodbye_object = Param.GoodbyeObject("A goodbye object")
```

更新后的 `HelloObject.py` 文件可以下载
[这里](/_pages/static/scripts/part2/parameters/HelloObject.py)。

其次，我们将向 `HelloObject` 类添加对 `GoodbyeObject` 的引用。
别忘了在 `hello_object.hh` 文件顶部包含 `goodbye_object.hh`！

```cpp
#include <string>

#include "learning_gem5/part2/goodbye_object.hh"
#include "params/HelloObject.hh"
#include "sim/sim_object.hh"

class HelloObject : public SimObject
{
  private:
    void processEvent();

    EventWrapper event;

    /// Pointer to the corresponding GoodbyeObject. Set via Python
    GoodbyeObject* goodbye;

    /// The name of this object in the Python config file
    const std::string myName;

    /// Latency between calling the event (in ticks)
    const Tick latency;

    /// Number of times left to fire the event before goodbye
    int timesLeft;

  public:
    HelloObject(const HelloObjectParams &p);

    void startup() override;
};
```

然后，我们需要更新 `HelloObject` 的构造函数和处理事件函数。我们还在构造函数中添加了一个检查，以确保 `goodbye` 指针有效。可以通过使用 `NULL` 特殊 Python SimObject 通过参数传递空指针作为 SimObject。当这种情况发生时，我们应该 *panic*，因为这不是该对象已被编码为接受的情况。

```cpp
#include "learning_gem5/part2/hello_object.hh"

#include "debug/Hello.hh"

HelloObject::HelloObject(HelloObjectParams &params) :
    SimObject(params),
    event(*this),
    goodbye(params.goodbye_object),
    myName(params.name),
    latency(params.time_to_wait),
    timesLeft(params.number_of_fires)
{
    DPRINTF(Hello, "Created the hello object with the name %s\n", myName);
    panic_if(!goodbye, "HelloObject must have a non-null GoodbyeObject");
}
```

一旦我们处理了参数指定的事件数量，我们就应该调用 `GoodbyeObject` 中的 `sayGoodbye` 函数。

```cpp
void
HelloObject::processEvent()
{
    timesLeft--;
    DPRINTF(Hello, "Hello world! Processing the event! %d left\n", timesLeft);

    if (timesLeft <= 0) {
        DPRINTF(Hello, "Done firing!\n");
        goodbye->sayGoodbye(myName);
    } else {
        schedule(event, curTick() + latency);
    }
}
```

您可以找到更新后的头文件
[这里](/_pages/static/scripts/part2/parameters/hello_object.hh) 和实现文件
[这里](/_pages/static/scripts/part2/parameters/hello_object.cc)。

### 更新配置脚本

最后，我们需要将 `GoodbyeObject` 添加到配置脚本中。创建一个新的配置脚本 `hello_goodbye.py` 并实例化 hello 和 goodbye 对象。例如，一种可能的脚本如下。

```python
import m5
from m5.objects import *

root = Root(full_system = False)

root.hello = HelloObject(time_to_wait = '2us', number_of_fires = 5)
root.hello.goodbye_object = GoodbyeObject(buffer_size='100B')

m5.instantiate()

print("Beginning simulation!")
exit_event = m5.simulate()
print('Exiting @ tick %i because %s' % (m5.curTick(), exit_event.getCause()))
```

您可以下载此脚本
[这里](/_pages/static/scripts/part2/parameters/hello_goodbye.py)。

运行此脚本会生成以下输出。

    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 compiled Jan  4 2017 15:17:14
    gem5 started Jan  4 2017 15:18:41
    gem5 executing on chinook, pid 3838
    command line: build/X86/gem5.opt --debug-flags=Hello configs/learning_gem5/part2/hello_goodbye.py

    Global frequency set at 1000000000000 ticks per second
          0: hello.goodbye_object: Created the goodbye object
          0: hello: Created the hello object
    Beginning simulation!
    info: Entering event queue @ 0.  Starting simulation...
    2000000: hello: Hello world! Processing the event! 4 left
    4000000: hello: Hello world! Processing the event! 3 left
    6000000: hello: Hello world! Processing the event! 2 left
    8000000: hello: Hello world! Processing the event! 1 left
    10000000: hello: Hello world! Processing the event! 0 left
    10000000: hello: Done firing!
    10000000: hello.goodbye_object: Saying goodbye to hello
    10000000: hello.goodbye_object: Scheduling another fillBuffer in 152592 ticks
    10152592: hello.goodbye_object: Processing the event!
    10152592: hello.goodbye_object: Scheduling another fillBuffer in 152592 ticks
    10305184: hello.goodbye_object: Processing the event!
    10305184: hello.goodbye_object: Scheduling another fillBuffer in 152592 ticks
    10457776: hello.goodbye_object: Processing the event!
    10457776: hello.goodbye_object: Scheduling another fillBuffer in 152592 ticks
    10610368: hello.goodbye_object: Processing the event!
    10610368: hello.goodbye_object: Scheduling another fillBuffer in 152592 ticks
    10762960: hello.goodbye_object: Processing the event!
    10762960: hello.goodbye_object: Scheduling another fillBuffer in 152592 ticks
    10915552: hello.goodbye_object: Processing the event!
    10915552: hello.goodbye_object: Goodbye done copying!
    Exiting @ tick 10944163 because Goodbye hello!! Goodbye hello!! Goodbye hello!! Goodbye hello!! Goodbye hello!! Goodbye hello!! Goo

您可以修改这两个 SimObject 的参数，看看总执行时间（Exiting @ tick **10944163**）是如何变化的。要运行这些测试，您可能希望删除调试标志，以便终端输出更少。

在接下来的章节中，我们将创建一个更复杂、更有用的 SimObject，最终实现一个简单的阻塞式单处理器缓存。
