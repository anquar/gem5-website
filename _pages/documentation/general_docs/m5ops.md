---
layout: documentation
title: M5ops
doc: gem5 documentation
parent: m5ops
permalink: /documentation/general_docs/m5ops/
---

# M5ops

此页面解释了可用于 M5 执行检查点等的特殊操作码。m5 实用程序（在我们的磁盘镜像和 util/m5/* 中）在命令行上提供了一些此类功能。在许多情况下，最好直接在您感兴趣的应用程序的源代码中插入操作。您应该能够链接相应的 libm5.a 文件，并且 m5ops.h 头文件包含所有函数的原型。
关于使用 M5ops 的教程是 gem5 2022 Bootcamp 的一部分。此活动的录音可以在 [这里](https://youtu.be/TeHKMVOWUAY) 找到。

## 构建 M5 和 libm5

为了构建目标的 m5 和 libm5.a，请在 util/m5/ 目录中运行以下命令。

```bash
scons build/{TARGET_ISA}/out/m5
```

目标 ISA 列表如下所示。

* x86
* arm (arm-linux-gnueabihf-gcc)
* thumb (arm-linux-gnueabihf-gcc)
* sparc (sparc64-linux-gnu-gcc)
* arm64 (aarch64-linux-gnu-gcc)
* riscv (riscv64-unknown-linux-gnu-gcc)

注意：如果您在 x86 系统上用于其他 ISA，则需要安装交叉编译器。交叉编译器的名称显示在上面列表中的括号内。

有关更多详细信息，请参阅 [util/m5/README.md](https://github.com/gem5/gem5/blob/stable/util/m5/README.md)。

## m5 实用程序 (FS 模式)

m5 实用程序（参见 util/m5/）可用于在 FS 模式下发出特殊指令以触发特定于模拟的功能。它目前提供以下选项：

* initparam: 已弃用，仅出于旧二进制兼容性而存在
* exit [delay]: 在 delay 纳秒内停止模拟。
* resetstats [delay [period]]: 在 delay 纳秒内重置模拟统计信息；每 period 纳秒重复一次。
* dumpstats [delay [period]]: 在 delay 纳秒内将模拟统计信息保存到文件；每 period 纳秒重复一次。
* dumpresetstats [delay [period]]: 与 dumpstats 相同；resetstats
* checkpoint [delay [period]]: 在 delay 纳秒内创建检查点；每 period 纳秒重复一次。
* readfile: 打印由配置参数 system.readfile 指定的文件。这是将 rcS 文件复制到模拟环境中的方式。
* debugbreak: 在模拟器中调用 debug_break()（导致模拟器获取 SIGTRAP 信号，如果使用 GDB 调试则很有用）。
* switchcpu: 导致类型为“switch cpu”的退出事件，允许 Python 切换到不同的 CPU 模型（如果需要）。
* workbegin: 导致类型为“workbegin”的退出事件，可用于标记 ROI 的开始。
* workend: 导致类型为“workend”的退出事件，可用于标记 ROI 的终止。

## 其他 M5 ops

这些是其他在命令行形式中无用的 M5 ops。

* quiesce: 取消调度 CPU 的 tick() 调用，直到某些异步事件将其唤醒（中断）
* quiesceNS: 与上面相同，但如果没有在此之前被唤醒，则在若干纳秒后自动唤醒
* quiesceCycles: 与上面相同，但使用 CPU 周期而不是纳秒
* quisceTIme: CPU 静止的时间量
* addsymbol: 将符号添加到模拟器符号表。例如加载内核模块时

## 在 Java 代码中使用 gem5 ops

这些 ops 也可以在 Java 代码中使用。这些 ops 允许从 java 程序中调用 gem5 ops，如下所示：

```python
import jni.gem5Op;

public  class HelloWorld {

   public static void main(String[] args) {
       gem5Op gem5 = new gem5Op();
       System.out.println("Rpns0:" + gem5.rpns());
       System.out.println("Rpns1:" + gem5.rpns());
   }

   static {
       System.loadLibrary("gem5OpJni");
   }
}
```

构建时，您需要确类路径包含 gem5OpJni.jar：

```javascript
javac -classpath $CLASSPATH:/path/to/gem5OpJni.jar HelloWorld.java
```

运行时，您需要确保同时设置了 java 和库路径：

```javascript
java -classpath $CLASSPATH:/path/to/gem5OpJni.jar -Djava.library.path=/path/to/libgem5OpJni.so HelloWorld
```

## 在 Fortran 代码中使用 gem5 ops

gem5 的特殊操作码（伪指令）可以与 Fortran 程序一起使用。在 Fortran 代码中，可以添加对调用特殊操作码的 C 函数的调用。在创建最终二进制文件时，将 Fortran 程序和 C 程序（用于操作码）的目标文件一起编译。我发现 [这里](https://gcc.gnu.org/wiki/GFortranGettingStarted) 提供的文档很有用。阅读 **-****- Compiling a mixed C-Fortran program** 部分。

在 Fortran 代码中使用 gem5 ops 的想法本质上是将 m5 ops C 代码编译为目标文件，然后将目标文件链接到调用 m5 ops 的二进制文件。
Fortran 中的 C 函数调用约定是，如果 C 代码中的函数名称是 `void foo_bar_(void)`，那么在 Fortran 中，您可以通过 `call foo_bar` 调用该函数。

## 将 M5 链接到您的 C/C++ 代码

为了将 m5 链接到您的代码，首先如上节所述构建 `libm5.a`。

然后

* 在您的源文件中包含 `gem5/m5ops.h`
* 将 `gem5/include` 添加到编译器的包含搜索路径
* 将 `gem5/util/m5/build/{TARGET_ISA}/out` 添加到链接器搜索路径
* 链接 `libm5.a`

例如，可以通过将以下内容添加到 Makefile 来实现：

```
CFLAGS += -I$(GEM5_PATH)/include
LDFLAGS += -L$(GEM5_PATH)/util/m5/build/$(TARGET_ISA)/out -lm5
```

这是一个简单的 Makefile 示例：

```make
TARGET_ISA=x86

GEM5_HOME=$(realpath ./)
$(info   GEM5_HOME is $(GEM5_HOME))

CXX=g++

CFLAGS=-I$(GEM5_HOME)/include

LDFLAGS=-L$(GEM5_HOME)/util/m5/build/$(TARGET_ISA)/out -lm5

OBJECTS= hello_world

all: hello_world

hello_world:
	$(CXX) -o $(OBJECTS) hello_world.cpp $(CFLAGS) $(LDFLAGS)

clean:
	rm -f $(OBJECTS)
```


## 使用 M5ops 的 "_addr" 版本

m5ops 的 "_addr" 版本触发与默认 m5ops 相同的模拟特定功能，但它们使用不同的触发机制。下面是 m5 实用程序 README.md 的引用，解释了触发机制。

```markdown
头文件中定义的裸函数名将使用基于魔术指令的触发机制，这在历史上是默认的。

头文件末尾的一些宏将设置其他声明，这些声明镜像所有其他定义，但带有 "_addr" 和 "_semi" 后缀。这些其他版本将触发相同的 gem5 操作，但使用“魔术”地址或 semihosting 触发机制。虽然这些函数将在头文件中无条件声明，但只有在该 ABI 支持该触发机制时，库中才会存在定义。
```

*注意*: 生成 "_addr" 和 "_semi" m5ops 的宏称为 `M5OP`，它们在 `util/m5/abi/*/m5op_addr.S` 和 `util/m5/abi/*/m5op_semi.S` 中定义。

为了使用 m5ops 的 "_addr" 版本，您需要包含 m5_mmap.h 头文件，将“魔术”地址（例如，x86 为 "0xFFFF0000"，arm64/riscv 为 "0x10010000"）传递给 m5op_addr，然后调用 map_m5_mem() 以打开 /dev/mem。您可以通过在原始 m5ops 函数末尾添加 "_addr" 来插入 m5ops。

这是一个使用 m5ops 的 "_addr" 版本的简单示例：

```c
#include <gem5/m5ops.h>
#include <m5_mmap.h>
#include <stdio.h>

#define GEM5

int main(void) {
#ifdef GEM5
    m5op_addr = 0xFFFF0000;
    map_m5_mem();
    m5_work_begin_addr(0,0);
#endif

    printf("hello world!\n");

#ifdef GEM5
    m5_work_end_addr(0,0);
    unmap_m5_mem();
#endif
}
```

*注意*: 您需要为编译器添加新的头文件位置以查找 `m5_mmap.h`。
如果您遵循上面的 Makefile 示例，您可以在定义 CFLAGS 的位置下方添加以下行，

```c
CFLAGS += $(GEM5_PATH)/util/m5/src/
```

当您在带有 KVM CPU 的 FS 模式下运行插入了 m5ops 的应用程序时，可能会出现此错误。

    ```illegal instruction (core dumped)```

这是因为 m5ops 指令对主机来说不是有效指令。使用 m5ops 的 "_addr" 版本可以解决此问题，因此如果您想将 m5ops 集成到您的应用程序中或在使用 KVM CPU 运行时使用 m5 二进制实用程序，则必须使用 "_addr" 版本。
