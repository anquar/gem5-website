---
layout: documentation
title: "C/C++ 编码风格"
doc: gem5 documentation
parent: development
permalink: /documentation/general_docs/development/coding_style/
---
# C/C++ 编码风格

我们努力在 gem5 C/C++ 源代码中保持一致的编码风格，以使源代码更具可读性和可维护性。这必然涉及处理此代码的多个开发人员之间的妥协。我们觉得我们已经成功地找到了这样的妥协，因为每个主要的 M5 开发人员都对下面的至少一条规则感到恼火。如果您开发想要贡献回 M5 的代码，我们要求您也遵守这些准则。在源代码树中的 util/emacs/m5-c-style.el 处提供了体现缩进规则的 Emacs c++-mode 样式。

## 缩进和换行

缩进将为每级 4 个空格，但命名空间不应增加缩进。

* 例外：后跟冒号的标签（case 和 goto 标签以及 public/private/protected 修饰符）从包含上下文缩进两个空格。

缩进应仅使用空格（不使用制表符），因为制表符宽度并不总是一致设置，并且制表符在使用 diff 等工具时使输出更难阅读。

行长度最多为 79 个字符。

## 大括号

对于控制块（if、while 等），左大括号必须与控制关键字在同一行，右括号和左大括号之间有一个空格。

* 例外：对于多行表达式，左大括号可以放在单独的行上，以区分控制块和块内的语句。

```c++
if (...) {
    ...
}

// 例外情况
for (...;
     ...;
     ...) // 大括号可以在这里
{ // 但这仅在 'for' 跨越多行时可选地允许
    ...
}
```

'Else' 关键字应跟在右 'if' 大括号的同一行，如下所示：

```c++
if (...) {
    ...
} else if (...) {
    ...
} else {
    ...
}
```

由适合单行的单个语句组成的块可以选择省略大括号。如果单个语句跨越多行，或者如果块是 else/if 链的一部分，其中其他块有大括号，则仍需要大括号。

```c++
// 有或没有大括号都可以
if (a > 0)
    --a;

// 在以下情况下，仍需要大括号
if (a > 0) {
    obnoxiously_named_function_with_lots_of_args(verbose_arg1,
                                                 verbose_arg2,
                                                 verbose_arg3);
}

if (a > 0) {
    --a;
} else {
    underflow = true;
    warn("underflow on a");
}
```

对于函数定义或类声明，左大括号必须在下一行的第一列。

在函数定义中，返回类型应在一行上，函数名在下一行左对齐。如上所述，左大括号也应在函数名之后的单独行上。

请参见下面的示例：

```c++
int
exampleFunc(...)
{
    ...
}

class ExampleClass
{
  public:
    ...
};
```

函数前面应该有一个描述函数的块注释。

超过一行的内联函数声明不应放在类声明内。大多数超过一行的函数无论如何都不应该是内联的。

## 间距

应该有：

* 关键字（if、for、while 等）和左括号之间有一个空格
* 二元运算符（+、-、<、> 等）周围有一个空格，包括赋值运算符（=、+= 等）
* 在参数/参数列表中使用 '=' 时周围没有空格，无论是绑定默认参数值（在 Python 或 C++ 中）还是绑定关键字参数（在 Python 中）
* 函数名和参数的左括号之间没有空格
* 括号内紧邻没有空格，除非是非常复杂的表达式。复杂表达式优先使用临时变量分解为多个更简单的表达式。


对于指针和引用参数声明，以下两种方式都可以接受：

```c++
FooType *fooPtr;
FooType &fooRef;
```

或

```c++
FooType* fooPtr;
FooType& fooRef;
```
但是，样式应在文件内保持一致。如果您正在编辑现有文件，请与现有代码保持一致。如果您在新文件中编写新代码，可以自由选择您喜欢的样式。

## 命名

类和类型名称是混合大小写，以大写字母开头，不包含下划线（例如，ClassName）。例外：缩写名称应全部大写（例如，CPU）。类成员名称（方法和变量，包括 const 变量）是混合大小写，以小写字母开头，不包含下划线（例如，aMemberVariable）。具有访问器方法的类成员应具有前导下划线，以指示用户应使用访问器。访问器函数本身应与变量同名，但没有前导下划线。

局部变量是小写，用下划线分隔单词（例如，local_variable）。函数参数应使用下划线且为小写。

C 预处理器符号（常量和宏）应全部大写并带下划线。但是，这些已弃用，应尽可能分别替换为 const 变量和内联函数。

```c++
class FooBarCPU
{
  private:
    static const int minLegalFoo = 100;  // consts are formatted just like other vars
    int _fooVariable;   // starts with '_' because it has public accessor functions
    int barVariable;    // no '_' since it's internal use only

  public:
    // short inline methods can go all on one line
    int fooVariable() const { return _fooVariable; }

    // longer inline methods should be formatted like regular functions,
    // but indented
    void
    fooVariable(int new_value)
    {
        assert(new_value >= minLegalFoo);
        _fooVariable = new_value;
    }
};
```

## #includes

尽可能优先使用 C++ 包含而不是 C 包含。例如，选择 cstdio，而不是 stdio.h。

文件顶部的 #includes 块应该组织好。我们保持几个排序的组。这使得查找 #include 和避免重复的 #includes 变得容易。

如果需要该头文件，请始终首先包含 Python.h。这是集成指南要求的。下一个头文件应该是您的主头文件（例如，对于 foo.cc，您应该首先包含 foo.hh）。首先包含此头文件可确保它是独立的，并且可以在其他地方包含而不会缺少依赖项。

```c++
// Include Python.h first if you need it.
#include <Python.h>

// Include your main header file before any other non-Python headers (i.e., the one with the same name as your cc source file)
#include "main_header.hh"

// C includes in sorted order
#include <fcntl.h>
#include <sys/time.h>

// C++ includes
#include <cerrno>
#include <cstdio>
#include <string>
#include <vector>

// Shared headers living in include/. These are used both in the simulator and utilities such as the m5 tool.
#include <gem5/asm/generic/m5ops.h>

// M5 includes
#include "base/misc.hh"
#include "cpu/base.hh"
#include "params/BaseCPU.hh"
#include "sim/system.hh"
```

## 文件结构和模块化

源文件（.cc 文件）不应包含 extern 声明；相反，应包含定义对象的 .cc 文件关联的头文件。此头文件应包含从该 .cc 文件导出的所有对象的 extern 声明。此头文件也应包含在定义它的 .cc 文件中。这里的关键是我们在 .hh 文件中有一个单一的外部声明，编译器将自动检查其与 .cc 文件的一致性。（这在 C++ 中不如在 C 中重要，因为链接器名称修饰现在会捕获这些错误，但这仍然是一个好主意。）

当足够时（即，仅声明指向类的指针或引用时），头文件应使用前向类声明而不是包含完整的头文件。

头文件不应在顶层包含 using namespace 声明。这会将该命名空间中的所有名称强制到包含该头文件的任何源文件的全局命名空间中，这基本上完全违背了使用命名空间的初衷。在源（.cc）文件的顶层使用 using namespace 声明是可以的，因为效果完全局限于该 .cc 文件。在 _impl.hh 文件中使用它们也是可以的，因为尽管它们的扩展名，但出于实际目的，这些是源（不是头）文件。

## 代码文档

每个文件/类/成员都应使用 doxygen 样式的注释进行文档化。Doxygen 允许用户通过从代码和注释中提取相关信息来快速为我们的代码创建文档。它能够文档化所有代码结构，包括类、命名空间、文件、成员、定义等。其中大多数都很简单，您只需要在声明之前放置一个特殊的文档块。gem5 中的 Doxygen 文档每晚都会处理，并生成以下网页：[Doxygen](http://doxygen.gem5.org/release/current/index.html)

### 使用 Doxygen

特殊文档块采用 javadoc 样式的注释形式。javadoc 注释是一个 C 样式的注释，开头有 2 个 *，如下所示：

```c++
/**
 * ...文档...
 */
```

中间的星号是可选的，但请使用它们来清楚地划分文档注释。

这些块中的文档至少包含对所文档化结构的简要描述，后面可以跟更详细的描述和其他文档。简要描述是注释的第一句话。它以句号后跟空格或换行符结束。例如：

```c++
/**
 * 这是简要描述。这是详细
 * 描述的开始。详细描述继续。
 */
```

如果您需要在简要描述中使用句号，请在它后面跟一个反斜杠和一个空格。

```c++
/**
 * 例如。\ 这是一个带有内部句号的简要描述。
 */
```
这些注释中的空行被解释为段落分隔符，以帮助您使文档更具可读性。

### 特殊命令

在大多数情况下，将这些注释放在声明之前是有效的。但是，对于文件，您需要指定您正在文档化该文件。为此，您使用 @file 特殊命令。要文档化您当前所在的文件，您只需要使用该命令后跟您的注释。要注释单独的文件（我们不应该这样做），您可以在 file 命令后直接提供名称。还有一些其他特殊命令我们将经常使用。要文档化函数，我们将使用 @param 和 @return 或 @retval 来文档化参数和返回值。@param 接受参数名称及其描述。@return 只描述返回值，而 @retval 为其添加名称。要指定前置和后置条件，您可以使用 @pre 和 @post。

其他一些有用的命令是 @todo 和 @sa。@todo 允许您放置要修复/实现的事项提醒，并将它们与特定的类或成员/函数关联。@sa 允许您放置对另一段文档（类、成员等）的引用。这对于提供有助于理解正在文档化的代码的链接很有用。

### Example of Simple Documentation

Here is a simple header file with doxygen comments added.

```c++
/**
 * @file
 * Contains an example of documentation style.
 */

#include <vector>

/**
 * Adds two numbers together.
 */
#define DUMMY(a,b) (a+b)

/**
 * A simple class description. This class does really great things in detail.
 *
 * @todo Update to new statistics model.
 */
class foo
{
  /** This variable stores blah, which does foo and has invariants x,y,z
         @warning never set this to 0
         @invariant foo
    */
   int myVar;

 /**
  * This function does something.
  * @param a The number of times to do it.
  * @param b The thing to do it to.
  * @return The number of times it was done.
  *
  * @sa DUMMY
  */
 int bar(int a, long b);


 /**
  * A function that does bar.
  * @retval true if there is a problem, false otherwise.
  */
 bool manchu();

};
```

### 分组

Doxygen 还允许声明类和成员（或其他组）的组。我们可以使用这些来创建所有统计信息/全局变量的列表。或者只是对整个内存层次结构进行注释。您使用 @defgroup 定义一个组，然后使用 @ingroup 或 @addgroup 添加到其中。例如：

```c++
/**
 * @defgroup statistics Statistics group
 */

/**
  * @defgroup substat1 Statistitics subgroup
  * @ingroup statistics
  */

/**
 *  A simple class.
 */
class foo
{
  /**
   * Collects data about blah.
   * @ingroup statistics
   */
  Stat stat1;

  /**
   * Collects data about the rate of blah.
   * @ingroup statistics
   */
  Stat stat2;

  /**
   * Collects data about flotsam.
   * @ingroup statistics
   */
  Stat stat3;

  /**
   * Collects data about jetsam.
   * @ingroup substat1
   */
  Stat stat4;

};
```

这会将 stat1-3 放在 statistics 组中，将 stat4 放在子组中。有一种将对象放入组的简写方法。您可以使用 @{ 和 @} 来标记组包含的开始和结束。上面的示例可以重写为：

```c++
/**
 * @defgroup statistics Statistics group
 */

/**
  * @defgroup substat1 Statistitics subgroup
  * @ingroup statistics
  */

/**
 *  A simple class.
 */
class foo
{
  /**
   * @ingroup statistics
   * @{
   */

  /** Collects data about blah.*/
  Stat stat1;
  /** Collects data about the rate of blah. */
  Stat stat2;
  /** Collects data about flotsam.*/
  Stat stat3;

  /** @} */

  /**
   * Collects data about jetsam.
   * @ingroup substat1
   */
  Stat stat4;

};
```

我们还能想出什么组还有待观察。

### 其他功能

不确定我们还想使用哪些其他 doxygen 功能。

## M5 状态消息
### Fatal 与 Panic

在 `src/base/logging.hh:` 中定义了两个错误函数：`panic()` 和 `fatal()`。虽然这两个函数具有大致相似的效果（打印错误消息并终止模拟过程），但它们有不同的目的和用例。区别在头文件的注释中有记录，但为了方便起见，这里重复说明，因为人们经常混淆并使用错误的函数。

* `panic()` 应该在发生无论用户做什么都不应该发生的事情时调用（即，实际的 m5 bug）。`panic()` 调用 `abort()`，它可以转储核心或进入调试器。
* `fatal()` 应该在由于用户错误（配置错误、无效参数等）导致模拟无法继续时调用，而不是模拟器 bug。`fatal()` 调用 `exit(1)`，即带有错误代码的"正常"退出。

这些定义背后的原因是，如果只是用户的小错误，就没有必要 panic；只有当 m5 本身出现问题时我们才会 panic。另一方面，用户犯致命错误并不难，即严重到 m5 进程无法继续的错误。
### Inform、Warn 和 Hack

文件 `src/base/logging.hh` 还包含 3 个函数，用于提醒用户模拟中发生的各种情况：`inform()`、`warn()` 和 `hack()`。这些函数的目的是严格向用户提供模拟状态，因此这些函数都不会停止模拟器运行。

* `inform()` 和 `inform_once()` 应该用于用户应该知道但不必担心的信息性消息。`inform_once()` 只会在第一次调用时显示由 `inform_once()` 函数生成的状态消息。

* `warn()` 和 `warn_once()` 应该在某个功能不一定正确实现，但可能足够有效时调用。`warn()` 背后的想法是告知用户，如果他们在 `warn()` 之后不久看到一些奇怪的行为，描述可能是查找错误的好地方。

* `hack()` 应该在某个功能的实现远不如它可能或应该的那样好，但为了便利性或历史原因尚未修复时调用。
* `inform()` 向控制台提供状态消息和正常操作消息供用户查看，没有任何错误行为的含义。
