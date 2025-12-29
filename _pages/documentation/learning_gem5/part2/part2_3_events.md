---
layout: documentation
title: 事件驱动编程
doc: Learning gem5
parent: part2
permalink: /documentation/learning_gem5/part2/events/
author: Jason Lowe-Power
---


事件驱动编程
========================

gem5 是一个事件驱动的模拟器。在本章中，我们将探索如何创建和调度事件。我们将以 [hello-simobject-chapter](../helloobject) 中的简单 `HelloObject` 为基础。

创建一个简单的事件回调
--------------------------------

在 gem5 的事件驱动模型中，每个事件都有一个回调函数，在该函数中 *处理* 事件。通常，这是一个继承自 :cppEvent 的类。但是，gem5 提供了一个包装函数来创建简单事件。

在我们的 `HelloObject` 的头文件中，我们只需声明一个要在每次事件触发时执行的新函数 (`processEvent()`)。此函数必须不带参数且不返回任何内容。

接下来，我们添加一个 `Event` 实例。在这种情况下，我们将使用 `EventFunctionWrapper`，它允许我们执行任何函数。

我们还添加了一个 `startup()` 函数，将在下面进行解释。

```cpp
class HelloObject : public SimObject
{
  private:
    void processEvent();

    EventFunctionWrapper event;

  public:
    HelloObject(const HelloObjectParams &p);

    void startup() override;
};
```

接下来，我们必须在 `HelloObject` 的构造函数中构造此事件。`EventFuntionWrapper` 接受两个参数，一个要执行的函数和一个名称。名称通常是拥有事件的 SimObject 的名称。打印名称时，会在名称末尾自动附加 ".wrapped\_function\_event"。

第一个参数只是一个不带参数且没有返回值 (`std::function<void(void)>`) 的函数。通常，这是一个调用成员函数的简单 lambda 函数。但是，它可以是您想要的任何函数。在下面，我们在 lambda (`[this]`) 中捕获 `this`，以便我们可以调用类的实例的成员函数。

```cpp
HelloObject::HelloObject(const HelloObjectParams &params) :
    SimObject(params), event([this]{processEvent();}, name())
{
    DPRINTF(HelloExample, "Created the hello object\n");
}
```

我们还必须定义处理函数的实现。在这种情况下，如果我们正在调试，我们将简单地打印一些内容。

```cpp
void
HelloObject::processEvent()
{
    DPRINTF(HelloExample, "Hello world! Processing the event!\n");
}
```

调度事件
-----------------

最后，为了处理事件，我们首先必须 *调度* 事件。为此，我们使用 :cppschedule 函数。此函数将 `Event` 的某个实例调度到未来的某个时间（事件驱动模拟不允许事件在过去执行）。

我们最初将在我们添加到 `HelloObject` 类的 `startup()` 函数中调度事件。`startup()` 函数是允许 SimObject 调度内部事件的地方。直到第一次开始模拟（即从 Python 配置文件调用 `simulate()` 函数）时，它才会执行。

```cpp
void
HelloObject::startup()
{
    schedule(event, 100);
}
```

在这里，我们只是将事件调度为在 tick 100 执行。通常，您会使用相对于 `curTick()` 的偏移量，但由于我们知道调用 startup() 函数时当前时间为 0，因此我们可以使用显式的 tick 值。

当您使用 "HelloExample" 调试标志运行 gem5 时，现在的输出是

    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 compiled Jan  4 2017 11:01:46
    gem5 started Jan  4 2017 13:41:38
    gem5 executing on chinook, pid 1834
    command line: build/X86/gem5.opt --debug-flags=Hello configs/learning_gem5/part2/run_hello.py

    Global frequency set at 1000000000000 ticks per second
          0: hello: Created the hello object
    Beginning simulation!
    info: Entering event queue @ 0.  Starting simulation...
        100: hello: Hello world! Processing the event!
    Exiting @ tick 18446744073709551615 because simulate() limit reached

更多事件调度
---------------------

我们还可以在事件处理动作中调度新事件。例如，我们将向 `HelloObject` 添加一个延迟参数和一个关于触发事件次数的参数。在 [下一章](parameters-chapter) 中，我们将使这些参数可从 Python 配置文件访问。

在 HelloObject 类声明中，添加延迟和触发次数的成员变量。

```cpp
class HelloObject : public SimObject
{
  private:
    void processEvent();

    EventFunctionWrapper event;

    const Tick latency;

    int timesLeft;

  public:
    HelloObject(const HelloObjectParams &p);

    void startup() override;
};
```

然后，在构造函数中添加 `latency` 和 `timesLeft` 的默认值。

```cpp
HelloObject::HelloObject(const HelloObjectParams &params) :
    SimObject(params), event([this]{processEvent();}, name()),
    latency(100), timesLeft(10)
{
    DPRINTF(HelloExample, "Created the hello object\n");
}
```

最后，更新 `startup()` 和 `processEvent()`。

```cpp
void
HelloObject::startup()
{
    schedule(event, latency);
}

void
HelloObject::processEvent()
{
    timesLeft--;
    DPRINTF(HelloExample, "Hello world! Processing the event! %d left\n", timesLeft);

    if (timesLeft <= 0) {
        DPRINTF(HelloExample, "Done firing!\n");
    } else {
        schedule(event, curTick() + latency);
    }
}
```

现在，当我们运行 gem5 时，事件应该触发 10 次，并且模拟将在 1000 个 tick 后结束。输出现在应该如下所示。

    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 compiled Jan  4 2017 13:53:35
    gem5 started Jan  4 2017 13:54:11
    gem5 executing on chinook, pid 2326
    command line: build/X86/gem5.opt --debug-flags=Hello configs/learning_gem5/part2/run_hello.py

    Global frequency set at 1000000000000 ticks per second
          0: hello: Created the hello object
    Beginning simulation!
    info: Entering event queue @ 0.  Starting simulation...
        100: hello: Hello world! Processing the event! 9 left
        200: hello: Hello world! Processing the event! 8 left
        300: hello: Hello world! Processing the event! 7 left
        400: hello: Hello world! Processing the event! 6 left
        500: hello: Hello world! Processing the event! 5 left
        600: hello: Hello world! Processing the event! 4 left
        700: hello: Hello world! Processing the event! 3 left
        800: hello: Hello world! Processing the event! 2 left
        900: hello: Hello world! Processing the event! 1 left
       1000: hello: Hello world! Processing the event! 0 left
       1000: hello: Done firing!
    Exiting @ tick 18446744073709551615 because simulate() limit reached

您可以找到更新后的头文件
[这里](/_pages/static/scripts/part2/events/hello_object.hh) 和实现文件
[这里](/_pages/static/scripts/part2/events/hello_object.cc)。
