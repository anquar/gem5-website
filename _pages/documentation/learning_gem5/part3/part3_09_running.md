---
layout: documentation
title: 运行简单的 Ruby 系统
doc: Learning gem5
parent: part3
permalink: /documentation/learning_gem5/part3/running/
author: Jason Lowe-Power
---


## 运行简单的 Ruby 系统

现在，我们可以使用 MSI 协议运行我们的系统了！

作为有趣的内容，下面是一个简单的多线程程序（注意：截至撰写本文时，gem5 中存在一个错误，阻止了此代码的执行）。

```cpp
#include <iostream>
#include <thread>

using namespace std;

/*
 * c = a + b
 */
void array_add(int *a, int *b, int *c, int tid, int threads, int num_values)
{
    for (int i = tid; i < num_values; i += threads) {
        c[i] = a[i] + b[i];
    }
}


int main(int argc, char *argv[])
{
    unsigned num_values;
    if (argc == 1) {
        num_values = 100;
    } else if (argc == 2) {
        num_values = atoi(argv[1]);
        if (num_values <= 0) {
            cerr << "Usage: " << argv[0] << " [num_values]" << endl;
            return 1;
        }
    } else {
        cerr << "Usage: " << argv[0] << " [num_values]" << endl;
        return 1;
    }

    unsigned cpus = thread::hardware_concurrency();

    cout << "Running on " << cpus << " cores. ";
    cout << "with " << num_values << " values" << endl;

    int *a, *b, *c;
    a = new int[num_values];
    b = new int[num_values];
    c = new int[num_values];

    if (!(a && b && c)) {
        cerr << "Allocation error!" << endl;
        return 2;
    }

    for (int i = 0; i < num_values; i++) {
        a[i] = i;
        b[i] = num_values - i;
        c[i] = 0;
    }

    thread **threads = new thread*[cpus];

    // 注意：在 SE 模式下工作需要 -1。
    for (int i = 0; i < cpus - 1; i++) {
        threads[i] = new thread(array_add, a, b, c, i, cpus, num_values);
    }
    // 使用此线程上下文执行最后一个线程以安抚 SE 模式
    array_add(a, b, c, cpus - 1, cpus, num_values);

    cout << "Waiting for other threads to complete" << endl;

    for (int i = 0; i < cpus - 1; i++) {
        threads[i]->join();
    }

    delete[] threads;

    cout << "Validating..." << flush;

    int num_valid = 0;
    for (int i = 0; i < num_values; i++) {
        if (c[i] == num_values) {
            num_valid++;
        } else {
            cerr << "c[" << i << "] is wrong.";
            cerr << " Expected " << num_values;
            cerr << " Got " << c[i] << "." << endl;
        }
    }

    if (num_valid == num_values) {
        cout << "Success!" << endl;
        return 0;
    } else {
        return 2;
    }
}
```

将上面的代码编译为 `threads` 后，我们可以运行 gem5！

```sh
build/MSI/gem5.opt configs/learning_gem5/part6/simple_ruby.py
```

输出应该类似于以下内容。大多数警告是由于使用 pthreads 而导致的 SE 模式下未实现的系统调用，对于这个简单的示例，可以安全地忽略。

```termout
    gem5 Simulator System.  http://gem5.org
    gem5 is copyrighted software; use the --copyright option for details.

    gem5 compiled Sep  7 2017 12:39:51
    gem5 started Sep 10 2017 20:56:35
    gem5 executing on fuggle, pid 6687
    command line: build/MSI/gem5.opt configs/learning_gem5/part6/simple_ruby.py

    Global frequency set at 1000000000000 ticks per second
    warn: DRAM device capacity (8192 Mbytes) does not match the address range assigned (512 Mbytes)
    0: system.remote_gdb.listener: listening for remote gdb #0 on port 7000
    0: system.remote_gdb.listener: listening for remote gdb #1 on port 7001
    Beginning simulation!
    info: Entering event queue @ 0.  Starting simulation...
    warn: Replacement policy updates recently became the responsibility of SLICC state machines. Make sure to setMRU() near callbacks in .sm files!
    warn: ignoring syscall access(...)
    warn: ignoring syscall access(...)
    warn: ignoring syscall access(...)
    warn: ignoring syscall mprotect(...)
    warn: ignoring syscall access(...)
    warn: ignoring syscall mprotect(...)
    warn: ignoring syscall access(...)
    warn: ignoring syscall mprotect(...)
    warn: ignoring syscall access(...)
    warn: ignoring syscall mprotect(...)
    warn: ignoring syscall access(...)
    warn: ignoring syscall mprotect(...)
    warn: ignoring syscall mprotect(...)
    warn: ignoring syscall mprotect(...)
    warn: ignoring syscall mprotect(...)
    warn: ignoring syscall mprotect(...)
    warn: ignoring syscall mprotect(...)
    warn: ignoring syscall mprotect(...)
    warn: ignoring syscall set_robust_list(...)
    warn: ignoring syscall rt_sigaction(...)
          (further warnings will be suppressed)
    warn: ignoring syscall rt_sigprocmask(...)
          (further warnings will be suppressed)
    info: Increasing stack size by one page.
    info: Increasing stack size by one page.
    Running on 2 cores. with 100 values
    warn: ignoring syscall mprotect(...)
    warn: ClockedObject: Already in the requested power state, request ignored
    warn: ignoring syscall set_robust_list(...)
    Waiting for other threads to complete
    warn: ignoring syscall madvise(...)
    Validating...Success!
    Exiting @ tick 9386342000 because exiting with last active thread context
```
