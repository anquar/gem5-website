---
layout: bootcamp
title: gem5 和 Python 编程
permalink: /bootcamp/introduction/python-background
section: introduction
---
<!-- _class: title -->

## gem5 和 Python 编程

本节的目的是向您介绍 Python 编程以及它在 gem5 中的使用方式。

---

## 核心思想：gem5 解释 Python

gem5 模拟器可以被认为是一个解释定义模拟的 Python 脚本的 C++ 程序。`gem5` *是一个 Python 解释器*，它包含 gem5 Python 库。

> **警告**：这是一个简化。
> 一些模拟配置信息存在于 C++ 代码中。
> 然而，这个简单的想法可以作为一个有用的心理模型。

Python 脚本_导入_模拟组件（**SimObject**）并使用 Python 配置脚本来指定它们的配置以及与其他 SimObject 的互连。

---

```python
from m5.objects import CPU, L1Cache

cpu = CPU() # 创建 CPU SimObject
cpu.clock = '1GHz' # 设置其参数
cpu.l1_cache = L1Cache(size="64kB") # 将其连接到其他 SimObject

# ... 更多配置 ...
```

`CPU` 和 `L1Cache` 不是真正的 SimObject，但这可以作为如何使用 Python 配置脚本的示例。

---

## 使用 gem5 运行脚本

以下是如何使用 Python 配置脚本运行 gem5 模拟的示例。
`gem5` 二进制文件用于运行模拟，并具有可以设置以配置模拟的参数（如 `--outdir`）。
Python 配置脚本被传递给 `gem5`。
Python 配置脚本之后的所有参数都传递给 Python 脚本。

```shell
gem5 --outdir=mydir my-simulation.py --num-cores 4
```

语法是 `gem5 {gem5 的参数} {gem5 python 配置脚本} {脚本参数}`。

虽然 gem5 配置脚本主要是 Python，但它有一些特殊功能和限制。
我们将在本节中介绍这些。
最重要的区别是 gem5 二进制文件为脚本提供了 `m5` 模块，该模块提供配置脚本和 gem5 模拟器之间的接口。

---

<!-- _class: start -->

## 一些 Python 提醒

---

## 练习：在 gem5 中字面意思的 "Hello world"

对于所有编码示例，我们将在 `materials` 目录中。

```sh
cd /workspaces/2024/materials/01-Introduction/03-python-background
```

1. 创建一个名为 "mysim.py" 的文件并添加以下内容：

```python
print("hello from the config script")
```

使用 gem5 执行脚本：

```shell
gem5 mysim.py
```

> Python 文件名以 ".py" 结尾。
> Python 无法导入名称中带有短横线（`-`）的文件。对于模块使用 `_`。
> 对于要运行的脚本（您不希望其他人导入的脚本）使用短横线（`-`）。

---

## Python 入门：基本类型

在最内层，Python 有 4 种基本数据类型。
所有其他数据类型都建立在这些之上。

- 整数 (int)。
- 浮点数 (float)。
- 字符串 (str)。
- 布尔值 (bool)。

这些是所有 Python 程序的基本构建块，可以以各种方式设置和用于操作。

---

## 基本类型：整数

[`materials/01-Introduction/03-python-background/02-primitives-int.py`](../../materials/01-Introduction/03-python-background/02-primitives-int.py) 可以用作基本整数用法的参考。
本教程将涵盖基础知识。

### 声明整数

```python
x = 1
y = 2
```

---

## 基本整数运算

```python
a = x + y
b = x - y
c = x * y
d = x / y

# 使用 f-strings 打印值
print(f"a: {a}, b: {b}, c: {c}, d: {d}")
```

**关于 f-strings**：f-strings 是 Python 中格式化字符串的一种方式。
它们由字符串前的 `f` 定义，允许您通过将变量包装在花括号 `{}` 中来将变量插入字符串。
我们在这里稍微提前了一点，但它们非常有用，我们建议在代码中使用它们来输出变量。

---

## 基本类型：浮点数

[`materials/01-Introduction/03-python-background/03-primitives-float.py`](../../materials/01-Introduction/03-python-background/03-primitives-float.py) 可以用作基本浮点数用法的参考。

### 声明浮点数

浮点数是 Python 中的基本数据类型。它们是"实数"，声明方式如下。这里我们声明一个变量 `x` 并将其赋值为字面值 `1.5`。

```python
x = 1.5
```

---

## 基本浮点数运算

```python
# 与整数一样，浮点数可以使用算术运算设置

# 将变量 `y` 设置为 `10.5 + 5.5`
y = 10.5 + 5.5

# 将变量 `z` 设置为 `y - x`（在这种情况下，16 - 1.5）
z = y - x
print(f"Value of z: {z}")
```

> 在 Python 3（gem5 使用的版本）中，两个整数的除法将返回浮点数。

---

```Python
# 乘法
multi_xy = x * y
print(f"Value of multi_xy: {multi_xy}")

# 除法
div_xy = y / x
print(f"Value of div_xy: {div_xy}")
```

---

## 基本类型：字符串

[`materials/01-Introduction/03-python-background/04-primitives-string.py`](../../materials/01-Introduction/03-python-background/04-primitives-string.py) 可以用作基本字符串用法的参考。

字符串是 Python 中的基本数据类型。它们是字符序列，声明方式如下。这里我们声明一个变量 `x` 并将其赋值为字面值 `"Hello World!"`。

```python
x = "Hello World!"
print(x)
```

连接两个字符串
注意使用字面字符串 ("GoodBye!") 和变量 `x`。

```python
y = x + " GoodBye!"
print(y)
```

---

## 打印字符串

我们使用 "f-string" 语法将值字符串插入到其他字符串中。花括号之间的内容被评估为 Python。

在以下代码中，我们将 x 与 " GoodBye " 以及 x + y 的值（"Hello World! GoodBye!"）连接起来。这个 z 将被设置为 "Hello World! GoodBye Hello World! Goodbye!"

```python
z = f"{x} GoodBye {x + y}"
print(z)
```

---

<!-- _class: two-col -->

## 基本类型：布尔值

[`materials/01-Introduction/03-python-background/05-primitives-bool.py`](../../materials/01-Introduction/03-python-background/05-primitives-bool.py) 可以用作基本布尔值用法的参考。

布尔值是 Python 中的基本数据类型。它们是 "True" 或 "False"，声明方式如下。这里我们声明一个变量 `x` 并将其赋值为字面值 `True`。

```python
x = True
print(f"Value of x: {x}")
```

布尔值可以使用字面值或其他布尔变量的逻辑运算来设置。这些逻辑运算是 `is`、`and`、`or` 和 `not`，用于比较值。

```python
y = x and True
print(f"Value of y: {y}")

z = x or False
print(f"Value of z: {z}")

a = not x
print(f"Value of a: {a}")
```

---

<!-- _class: two-col -->

## 布尔比较

`==`、`!=`、`<`、`>`、`<=` 和 `>=` 运算符可用于比较其他基本数据类型的值。这些运算的结果是布尔值。

```python
# 如果 `1 + 1` 等于 `2`，则将 `b` 设置为 True
b = (1 + 1) == 2
print(f"Value of b: {b}")

# 如果 `1 + 1` 不等于 `2`，则将 `c` 设置为 True
c = (1 + 1) != 2
print(f"Value of c: {c}")
```

###

```python
# 如果 `1 + 1` 小于 `3`，则将 `d` 设置为 True
d = (1 + 1) < 3
print(f"Value of d: {d}")

# 如果 `1 + 1` 大于 `3`，则将 `e` 设置为 True
e = (1 + 1) > 3
print(f"Value of e: {e}")

# 如果 `1 + 1` 小于或等于 `2`，则将 `f` 设置为 True
f = (1 + 1) <= 2

# 如果 `1 + 1` 大于或等于 `2`，则将 `g` 设置为 True
g = (1 + 1) >= 2
```

---

<!-- _class: two-col -->

## Python 入门：集合

Python 有许多内置的集合类型，但最常用的是列表、字典和集合。在所有情况下，它们都用于在单个集合变量中存储多个变量。

列表是有序的变量集合。允许重复。
它们使用方括号。

```python
a_list = [1, 1, 2]
```

更多关于列表的内容可以在 [`materials/01-Introduction/03-python-background/06-collections-list.py`](../../materials/01-Introduction/03-python-background/06-collections-list.py) 找到

### 集合

集合是无序的变量集合。不允许重复。
它们使用花括号。

```python
a_set = {"one", "two", "three", "four", "five"}
```

更多关于集合的示例可以在 [`materials/01-Introduction/03-python-background/07-collections-set.py`](../../materials/01-Introduction/03-python-background/07-collections-set.py) 找到。

---

## 字典

字典是键值对的集合。这些实际上是集合，其中集合中的每个值（'键'）映射到另一个变量（'值'）。不允许键重复（但允许值重复）。

```python
a_dict = {1: "one", 2: "two"}
```

更多关于字典的示例可以在 [`materials/01-Introduction/03-python-background/08-collections-dict.py`](../../materials/01-Introduction/03-python-background/08-collections-dict.py) 找到。

---

<!-- _class: code-80-percent -->

### Python 集合用法

```python
# 过去几张幻灯片中的集合示例
a_list = [1, 1, 2]
a_set = {"one", "two", "three", "four", "five"}
a_dict = {1: "one", 2: "two"}

# 访问列表中的元素
# 每个元素都有一个索引，可用于访问元素。索引从 0 开始
print(a_list[0])
print(a_list[1])

# 向列表末尾添加元素。`a_list` 将被设置为 `[1, 1, 2, 1]`
a_list.append(1)

# 访问集合中的元素。集合不使用索引来访问元素
for element in a_set:
    print(element)
```

<!--
---

```python
# Add an element to the set.
a_set.add("six")

# Adding the same to the set again will not change the set.
a_set.add("six")

# Accessing elements in a dictionary
# Elements are accessed by their key.
print(a_dict[1]) # "one"

# Add an element to the dictionary.
# `a_dict` will be set to `{1: "one", 2: "two", 3: "three"}`.
a_dict[3] = "three"

# Adding the same key the dictionary will overwrite the value.
# `a_dict` will be set to `{1: "one", 2: "two", 3: "four"}`.
a_dict[3] = "four"
```
-->
---

## 更多关于 Python 基本类型和集合

Python 的独特之处在于它带有大量内置功能。
虽然有用，但这通常意味着有多种方法可以做同样的事情。

例如，在以下代码片段中，`dict_1`、`dict_2` 和 `dict_3` 都是等价的。

```python
dict_1 = {'key_one': "one", 'key_two': "two"}

dict_2 = dict(key_one="one", key_two="two")

dict_3 = dict()
dict_3['key_one'] = "one"
dict_3['key_two'] = "two"
```

那些 Python 新手可能想今晚花一些时间浏览使用 Python "内置"函数的示例。

---

## 列表推导式

列表推导式是在 Python 中创建列表的一种方式，在 gem5 中常用。

它们允许通过迭代另一个列表并对每个元素应用操作，在一行代码中创建列表。

以下代码创建从 1 到 20 的偶数列表：

```python
even_numbers = [x for x in range(1, 21) if x % 2 == 0]
```

其非推导式等价形式为：

```python
even_numbers = []
for x in range(1, 21):
    if x % 2 == 0:
        even_numbers.append(x)
```

---

## 列表推导式

列表推导式的语法是：

```python
[expression for item in iterable if condition]
```

例如，假设我们想要商店中所有价格低于 10 美元的商品的价格列表。
假设 `store` 是商品的集合，每个商品都有一个返回商品价格的函数 `get_price` 和一个返回商品名称的函数 `get_name`。

以下将获取商品列表。

```python
item_under_10 = [item.get_name() for item in store if item.get_price() < 10]
```

---

## 列表推导式

也可以嵌套列表推导式。

例如，假设我们有一个列表的列表，我们想要将其展平。

```python
list_of_lists = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
flattened_list = [item for sublist in list_of_lists for item in sublist]
```

在上面的代码中，我们有一个列表的列表。
外循环迭代列表的列表中的每个子列表。
内循环迭代子列表中的每个项目。

非推导式等价形式为：

```python
flattened_list = []
for sublist in list_of_lists:
    for item in sublist:
        flattened_list.append(item)
```

---

## Python `if`

```python
condition = True and False

if condition:
    print("The condition is True")
else:
    print("The condition is False")
```

[`materials/01-Introduction/03-python-background/09-if-statements.py`](../../materials/01-Introduction/03-python-background/09-if-statements.py) 可以用作基本 `if` 用法的参考。

- Python 不使用大括号来定义代码块。相反，它使用缩进。
- `print` 语句被缩进以显示它们是 `if` 块的一部分（例如，"The condition is True" `print` 只有在 `condition` 为 `True` 时才会执行）。
- 确保您的缩进一致。如果不一致，Python 将抛出错误。
- 在 gem5 中，我们使用 4 个空格进行缩进。

---

## Python `for`

`for` 遍历项目集合。

```python
for value in [1, 2, 3]:
    print(value)
```

同样，`print` 语句被缩进以显示它是 `for` 的一部分。

[`materials/01-Introduction/03-python-background/10-for-loops.py`](../../materials/01-Introduction/03-python-background/10-for-loops.py) 可以用作基本 `for` 用法的参考。

---

## Python `while`

`while` 将执行代码块，直到条件为 `False`。

```python
counter = 0
while counter < 3:
    print(counter)
    counter += 1
```

[`materials/01-Introduction/03-python-background/11-while-loop.py`](../../materials/01-Introduction/03-python-background/11-while-loop.py) 可以用作基本 `while` 用法的参考。

> **注意：** `counter += 1` 行是 `counter = counter + 1` 的简写。
这会将计数器值设置为当前计数器值加 1。例如，
如果计数器是 0，`counter += 1` 会将 `counter` 变量设置为 1。

---

## Python 函数

函数使用 `def` 关键字定义。

```python
def my_function(arg1, arg2):
    return arg1 + arg2

result = my_function(1, 2)
print(result) # 3
```

---

## Python 函数

以下显式引用参数的风格也很常见。

```python
def my_function(arg1: int, arg2: int) -> int:
    return arg1 + arg2
```

我们强烈建议在函数中使用类型提示。这提高了代码可读性并有助于捕获错误。

[`materials/01-Introduction/03-python-background/12-function.py`](../../materials/01-Introduction/03-python-background/12-function.py) 可以用作基本函数用法的参考。

> 幻灯片中的示例以及大部分材料都不使用类型提示以节省空间。这不是推荐的做法。

---

<!-- _class: two-col -->

## 导入代码

Python 允许您从其他文件导入代码。

假设我们在一个名为 `math_funcs.py` 的文件中有函数 `add`、`subtract` 和 `multiply`：

```python
def add(a: int b: int) -> int:
    return a + b

def subtract(a: int, b: int) -> int:
    return a - b

def multiply(a: int, b: int) -> int:
    return a * b
```

###

我们可以导入这些函数并使用它们：

```python
from math_funcs import add, subtract, multiply

print(add(1,2))
print(subtract(4,2))
print(multiply(3,3))
```

如果 `math_funcs.py` 在一个目录中，比如 "math_dir"，我们可以使用：

```python
from math_dir.math_funcs import add, subtract, multiply
```

完整和扩展的示例可以在 [`13-importing-code.py`](../../materials/01-Introduction/03-python-background/13-importing-code.py) 找到。

---

## Python 生成器

生成器是在 Python 中创建迭代器的一种方式。它们类似于函数，但不是一次返回所有值，而是一次生成一个值。

```python
def my_generator():
    yield 1
    yield 2
    yield 3

for value in my_generator():
    print(value)
```

语法上的区别是 `yield` 关键字。这用于从生成器返回值。

---

## Python 生成器

除了更节省内存外，生成器对于创建无限序列也很有用。


```python
def infinite_flip_flop() -> Generator[bool]:
    bool val = True
    while True:
        yield val
        val = not val
```

上面的生成器将无限地生成 `True`、`False`、`True`、`False`、`True`、`False`，依此类推。

虽然返回列表可能很诱人，但如果您想一次迭代一个值序列，生成器是正确的方法。

---

## gem5 和面向对象设计

gem5 利用面向对象设计 (OOD) 来建模计算机系统的组件。这是建模复杂系统的强大方法，也是软件工程中的常见设计模式。简而言之，它是一种将逻辑上属于一起的数据和函数封装在称为"对象"的实体中的方法。

类允许您在 Python 中创建自己的数据类型。它们是将数据和功能捆绑在单个单元中的一种方式。类是对象的蓝图。它定义了类的对象实例将具有的属性和方法。例如，我们可以有一个类 `Car`，具有 `color`、`make`、`model` 等属性，以及 `drive`、`stop`、`park` 等方法。
当我们创建类 `Car` 的对象时，我们可以设置汽车对象的属性，如 `color`、
`make`、`model`，并调用方法，如 `drive`、`stop`、`park`。
虽然类 `Car` 的每个对象都具有相同的属性和方法，但每个对象的属性值可能不同。

---

## Python 中的基本面向对象设计

此示例的代码可以在 [`materials/01-Introduction/03-python-background/14-basic-class-and-object.py`](../../materials/01-Introduction/03-python-background/14-basic-class-and-object.py) 找到。

让我们创建一个简单的类和一些对象实例化。

```python
class Animal:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def eat(self, food):
        print(f"{self.name} is eating {food}")

    def sleep(self):
        print(f"{self.name} is sleeping")
```

<!--
    # def __init__(self, weight, height, name):
    #     self.weight = weight
    #     self.height = height
    #     self.name = name
 -->

---

## Python 中的基本面向对象设计

`__init__` 方法是在创建对象时调用的特殊方法。
它用于初始化对象的属性。
现在我们可以从这个类创建对象。

<!-- ```python
dog = Animal(100, 5, "Dog")
cat = Animal(200, 6, "Cat")
``` -->
```python
dog = Animal("Dog", 5)
cat = Animal("Cat", 6)
```

我们可以这样访问属性：

```python
print(f"Name of animal: {dog.name}")
print(f"Age of animal: {dog.age}")
```
<!-- print(f"Height of animal: {dog.height}")
print(f"Weight of animal: {dog.weight}") -->
并这样调用其方法：

```python
dog.eat("meat")
dog.sleep()
```

---

## Python 中的基本面向对象设计

尽管 `name` 和 `age` 的值不同，但 `dog` 和 `cat` 对象都具有相同的类型 `Animal`。
因此，它们可以传递给期望 `Animal` 对象的函数。

```python
def feed_animal(animal):
    animal.eat("food")

feed_animal(dog)
feed_animal(cat)
```

---

## 您应该知道的面向对象设计术语

- **类 (Class)**：对象的蓝图。它定义了类的对象实例将具有的属性和方法。
（即，我们示例中的 `Animal`）。
- **对象 (Object)**：类的实例。
（即，我们示例中的 `dog` 和 `cat`）。
- **成员变量 (Member Variable)**：封装在特定对象内的变量。
（即，我们示例中的 `weight`、`height` 和 `name`）。
- **成员函数 (Member Function)**：封装在特定对象内的函数。
（即，我们示例中的 `eat` 和 `sleep`）。
- **构造函数 (Constructor)**：用于创建对象的特殊方法。
（即，我们示例中的 `__init__`）。
- **实例化 (Instantiation)**/**构造 (Construction)**：从类创建对象。
（即，我们示例中的 `dog = Animal(100, 5, "Dog")`）。

---

## 继承

继承允许相对于另一个类定义类。这个其他类被称为基类、父类或超类，新类被称为派生类、子类或子类。

有很多情况需要新类，但与现有类共享许多相同的属性和方法。在这些情况下，可以从现有类继承并用新属性和方法扩展它。

让我们想象我们想使用我们的 Animal 类添加一个大象对象。我们想要一个新的成员变量 `trunk_length` 和一个新的成员函数 `trumpet`。这里的见解是大象是动物，但并非所有动物都是大象。大象将始终具有动物的所有共同属性和方法，但并非所有动物都具有大象的属性和方法。

<!-- 在此之前，Animal 类的构造函数接受 weight、height 和 name 作为参数，但在此之后，构造函数似乎接受 name 和 age。这种不一致可能会让观众感到困惑 -->

---

## 继承示例

此部分的代码可以在 [`materials/01-Introduction/03-python-background/15-inheritance.py`](../../materials/01-Introduction/03-python-background/15-inheritance.py) 找到

```python
class Elephant(Animal):
    def __init__(self, name, age, trunk_length):
        # 调用父类的构造函数
        super().__init__(name, age)
        self.trunk_length = trunk_length

    def trumpet(self):
        print("Trumpeting")
```

Elephant 类继承自 Animal 类。这意味着 Elephant 类具有 Animal 类的所有属性和方法。这不仅通过借用 Animal 类的属性和方法节省了大量输入和时间，而且使代码更具可读性和可维护性。

---

<!-- _class: two-col -->

## 继承示例

最重要的是，Elephant 可以作为 Animal 传递给任何函数。

```python
def print_animal(animal):
    print(f"Name: {animal.name}")
    print(f"Age: {animal.age}")

dog = Animal("Dog", 10)
elephant = Elephant("Dumbo", 10)
print_animal(elephant)
print_animal(dog)
```

###

但是，期望 Elephant 对象的函数不会接受 Animal 对象。这是因为 Elephant 是 Animal，但 Animal 不是 Elephant。

```python
def toot_horn(elephant):
    elephant.trumpet()

# 这将起作用
toot_horn(elephant)

# 这将不起作用
toot_horn(dog)
```

---

## 重写方法

最后，子类可以重写父类的方法。当父类的方法对子类没有意义时，这很有用。例如，Elephant 类可以重写 Animal 类的 `eat` 方法，以便在大象吃东西时打印不同的消息。

```python
class Elephant(Animal):
    def __init__(self, name, age, trunk_length):
        super().__init__(name, age)
        self.trunk_length = trunk_length

    def trumpet(self):
        print("Trumpeting")

    def eat(self, food): # 重写 eat 方法
        print(f"{self.name} is eating {food} with its trunk")
```

---

## 重写方法

期望 `Animal` 的代码因此可以根据传递给它的对象类型执行完全不同的代码。

```python
def feed_animal(animal):
    animal.eat("food")

feed_animal(dog)
feed_animal(elephant)
```

回到日常的面向对象设计术语，`Animal` 类是基类，`Elephant` 类是派生类。
派生类可以重写基类的方法。这意味着期望基类对象的函数可以根据传递给它的对象类型执行完全不同的代码。

---

## 抽象类

在过去的几个示例中，我们设想了一个具有对象实例化的简单类 `Animal`。有些情况下，您不希望类有任何对象实例化。这就是抽象基类有用的地方。在我们的例子中，当我们可以为每种动物类型创建子类时，拥有一个通用的 Animal 是没有意义的。

抽象基类是用于继承但不实例化的类。它们用于定义子类要实现的通用接口。

Python 中的 `abc` 模块提供了可以继承以创建抽象基类的 `ABC` 类。
方法不必在抽象基类中实现，但它们可以。这对于您希望强制在子类中定义方法的情况很有用。

---

<!-- _class: code-80-percent -->

## 抽象类示例

此部分的代码可以在 [`materials/01-Introduction/03-python-background/16-inheritance-with-abstract-base.py`](../..//materials/01-Introduction/03-python-background/16-inheritance-with-abstract-base.py) 找到

```python
from abc import ABC, abstractmethod

class Animal(ABC):
    """
    表示动物的抽象类
    """

    def eat(self, food):
        print("Is eating {food}")

    @abstractmethod
    def move(self):
        raise NotImplementedError("move method not implemented")
```

---

## 抽象类示例

然后我们可以添加动物。假设是 Dog 和 Cat：

```python
class Dog(Animal):
    def move(self):
        print("Dog is running")

class Cat(Animal):
    def move(self):
        print("Cat is walking")
```

我们需要做的就是在子类中指定 Animal 类的未实现方法。

---

<!-- _class: two-col -->

## 抽象类示例

我们可以向 cat 添加一个子类。假设是 "LazyCat"，它有一个新方法 "sleep"，这是它独有的，同时共享所有其他 Cat 方法。

```python
class LazyCat(Cat):
    def sleep(self):
        print("Cat is sleeping")
```

我们可以实例化这些类并调用它们的方法，除了抽象基类之外的所有内容。

###

```python
dog1 = Dog(); dog2 = Dog(); cat = Cat()
lazy_cat = LazyCat()

dog1.eat("meat")
dog1.move()
dog2.eat("bones")
dog2.move()

cat.eat("fish")
cat.move()

lazy_cat.eat("milk")
lazy_cat.move()
lazy_cat.sleep()
```

---

## 更多面向对象设计术语

- **继承 (Inheritance)**：类从另一个类继承属性和方法的能力。
（即，我们示例中的 `Elephant` 继承自 `Animal`）。
- **基类 (Base Class)**：从中继承属性和方法的类。
这也可以称为父类或超类。
（即，我们示例中的 `Animal`）。
- **派生类 (Derived Class)**：从另一个类继承属性和方法的类。
这也可以称为子类或子类。
（即，我们示例中的 `Elephant`）。
- **重写 (Overriding)**：子类提供其超类之一已提供的方法的特定实现的能力。
（即，我们示例中的 `Elephant` 重写 `Animal` 的 `eat` 方法）。
- **抽象类 (Abstract class)**：用于继承但不直接实例化的类。
（即，我们示例中的 `Animal`）。
- **抽象方法 (Abstract Method)**：在抽象类中声明但未实现的方法。
由子类实现。
（即，我们示例中的 `move`）。

---

## SimObject 和面向对象设计

SimObject 是 gem5 中表示模拟系统组件的对象。
它们从继承自 `SimObject` 抽象类的类实例化，并封装模拟组件的参数（例如，内存大小），以及它以标准方式与其他组件交互的方法。

由于这些都共享一个公共基类，gem5 可以以一致的方式处理它们，尽管模拟了各种各样的组件。
如果需要新组件，我们只需从最合理的现有组件创建一个子类，并用新功能扩展它。

> gem5 还具有称为"端口 (Ports)"的特殊参数，用于定义 SimObject 之间的通信通道。
> 更多内容将在以后的课程中介绍。

---

## SimObject 面向对象设计示例

在 gem5 中，获取 SimObject 并扩展它以添加新功能是很有用的。
gem5 理想情况下应该**对扩展开放但对修改封闭**。
直接修改 gem5 代码可能难以维护，并且在更新到新版本的 gem5 时可能导致合并冲突。


以下显示了特化 gem5 SimObject 以创建抽象
L1 缓存的示例。然后将其用作 L1 指令缓存的基类。

以下示例的代码也可以在 [`materials/01-Introduction/03-python-background/17-inheriting-from-a-simobject.py`](../../materials/01-Introduction/03-python-background/17-inheriting-from-a-simobject.py) 找到

---

<!-- _class: code-80-percent -->

## SimObject 面向对象设计示例

```python
from m5.objects import Cache
from abc import ABC

class L1Cache(type(Cache), type(ABC)):
    """具有默认值的简单 L1 缓存"""

    def __init__(self):
        # 这里我们设置/覆盖缓存的默认值
        self.assoc = 8
        self.tag_latency = 1
        self.data_latency = 1
        self.response_latency = 1
        self.mshrs = 16
        self.tgts_per_mshr = 20
        self.writeback_clean = True
        super().__init__()
```

---

<!-- _class: two-col -->

## SimObject 面向对象设计示例

我们扩展功能。在这种情况下，通过添加一个方法来帮助将缓存添加到总线和处理器。连接到 CPU 保持未实现，因为每种类型的缓存都会不同。

```python
class L1Cache(type(Cache), type(ABC)):
    ...
    def connectBus(self, bus):
        """将此缓存连接到内存端总线"""
        self.mem_side = bus.cpu_side_ports

    def connectCPU(self, cpu):
        """将此缓存的端口连接到 CPU 端端口
        这必须在子类中定义"""
        raise NotImplementedError
```

###

```python
class L1ICache(L1Cache):
    """具有默认值的简单 L1 指令缓存
    """

    def __init__(self):
        # 设置大小
        self.size = "32kB"
        super().__init__()

    # 这是 L1ICache 连接到 CPU 所需的实现
    def connectCPU(self, cpu):
        """将此缓存的端口连接到 CPU icache 端口
        """
        self.cpu_side = cpu.icache_port
```

---

## 有时 gem5 有点不同

虽然配置脚本主要是 Python，但 Python 和 gem5 的 Python 之间存在一些差异。
以下是一些需要记住的重要差异：

### gem5 有一个特殊的模块 `m5`

`m5` 模块是一个特殊模块，提供配置脚本和 gem5 模拟器之间的接口。这是_编译到 gem5 二进制文件中_的，因此不是标准的 Python 模块。最常见的抱怨是 `import m5` 会被大多数 Python IntelliSense 工具视为错误。但是，当脚本由 gem5 解释时，它是一个有效的导入。

---

<!-- _class: two-col -->

## SimObject 参数赋值是特殊的

在大多数情况下，Python 允许这样做：

```python
class Example():
    hello = 6
    bye = 6

example = Example()
example.whatever = 5
print(f"{example.hello} {example.whatever} {example.bye}")
```

这里我们向对象添加了另一个变量。

但是，如果您尝试对 SimObject 执行此操作，gem5 将抛出错误。

```shell
AttributeError: 'example' object has no attribute 'whatever'
```

关于您可以和不能分配给 SimObject 的内容有规则。

SimObject 仅在 3 种情况下允许参数赋值：

1. 参数存在于参数列表中。因此您正在设置参数（`simobject.param1 = 3`）。
2. 您设置的值是 SimObject，其变量名与 SimObject 参数不冲突（`simobject.another_simobject = Cache()`）。
3. 参数名以 `_` 开头。gem5 将忽略这一点（`simobject._new_variable = 5`）。

---

## SimObject 端口赋值是特殊的

端口是一种特殊类型的 SimObject 变量。
它们用于将 SimObject 连接在一起。
设置响应和请求端口的语法是 `simobject1.{response_port} = simobject1.{request_port}`（或反之）。
这不是传统的 `=` 赋值，而是在端口上调用 `connect` 函数。

---

## SimObject 向量参数是不可变的

向量参数是其他 SimObject 的参数值向量。

它们是一种特殊类型的 SimObject 参数，用于在单个参数中存储多个值。

但是，与典型的 Python 列表不同，它们一旦创建就无法更改。创建后，您无法从向量中添加或删除 SimObject。

```python
simobject = ASimObject()
simobject.vector_param = [1, 2]
simobject.vector_param = [3, 4] # 这是可以的，但只是覆盖了先前的值
simobject.vector_param.append(5) # 这是不允许的
simobject.vector_param.remove(1) # 这是不允许的
```

---

## SimObject 向量参数是不可变的

以下是一个常见错误：

```python
processor_simobject.cpus = []
for cpu in range(4):
    processor_simobject.cpus.append(CPU())
```

正确的方法是一次性设置向量参数：

```python
simobject.cpus = [CPU() for _ in range(4)]
```

---

## 模拟初始化后，您无法向 SimObject 添加新变量

```python
simobject = ASimObject()
simobject.var1 = 5
simobject.var2 = 6

m5.instantiate()
# 也可以是 `Simulator` 的 `run()` 函数

simobject.var3 = 7 # 这是不允许的
```

在某些情况下，这可能不会失败，但 SimObject 配置中的更改不会反映在模拟中。

---

## 总结

- Python 是一种强大而灵活的语言。
- 它在 gem5 中用于配置和运行模拟。
- Python 有许多内置数据类型和集合。
- Python 是一种面向对象的语言。
- gem5 使用面向对象设计来建模计算机系统的组件。
- gem5 对 SimObject 有一些特殊规则。
