---
layout: documentation
title: gem5 中的常见错误
doc: gem5 documentation
parent: common-errors
permalink: /documentation/general_docs/common-errors/
---

以下是一些用户在使用 gem5 时遇到的常见问题，以及如何修复它们的信息。

## 构建错误

如果您的 gem5 编译失败并出现以下消息：

```txt
[    LINK]  -> ALL/gem5.opt
collect2: fatal error: ld terminated with signal 9 [Killed]
compilation terminated.
scons: *** [build/ALL/gem5.opt] Error 1
scons: building terminated because of errors.
```

这表示您的机器在尝试构建 gem5 时内存不足，并因此终止了进程。
如果发生这种情况，请尝试使用更少的线程编译 gem5，因为这将消耗更少的内存。
如果系统上有其他进程使用大量内存，请尝试在更多内存可用时构建 gem5。

## 段错误

可能会出现段错误，并将输出到终端，如下所示：

```bash
gem5 has encountered a segmentation fault!

— BEGIN LIBC BACKTRACE —
gem5/build/X86/gem5.opt(_Z15print_backtracev+0x2c)[0x55ead536d5bc]
gem5/build/X86/gem5.opt(+0x1030b8f)[0x55ead537fb8f]
/lib/x86_64-linux-gnu/libpthread.so.0(+0x128a0)[0x7f50fb78b8a0]
/lib/x86_64-linux-gnu/libgcc_s.so.1(_Unwind_Resume+0xcf)[0x7f50fa12ad9f]
gem5/build/X86/gem5.opt(_ZN6X86ISA7Decoder10decodeInstENS_11ExtMachInstE+0x5d19e)[0x55ead4e5ea8e]
gem5/build/X86/gem5.opt(_ZN6X86ISA7Decoder6decodeENS_11ExtMachInstEm+0x244)[0x55ead4dc74a4]
gem5/build/X86/gem5.opt(_ZN6X86ISA7Decoder6decodeERNS_7PCStateE+0x22b)[0x55ead4dc779b]
gem5/build/X86/gem5.opt(_ZN12DefaultFetchI9O3CPUImplE5fetchERb+0x942)[0x55ead54695f2]
gem5/build/X86/gem5.opt(_ZN12DefaultFetchI9O3CPUImplE4tickEv+0xd3)[0x55ead546a7b3]
gem5/build/X86/gem5.opt(_ZN9FullO3CPUI9O3CPUImplE4tickEv+0x12b)[0x55ead5448e3b]
gem5/build/X86/gem5.opt(_ZN10EventQueue10serviceOneEv+0xa5)[0x55ead5375a95]
gem5/build/X86/gem5.opt(_Z9doSimLoopP10EventQueue+0x87)[0x55ead539a7b7]
gem5/build/X86/gem5.opt(_Z8simulatem+0xcba)[0x55ead539b80a]
gem5/build/X86/gem5.opt(+0x11d3431)[0x55ead5522431]
gem5/build/X86/gem5.opt(+0x6df0b4)[0x55ead4a2e0b4]
/usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0(PyEval_EvalFrameEx+0x64d7)[0x7f50fba38c47]
/usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0(PyEval_EvalCodeEx+0x7d8)[0x7f50fbb77908]
/usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0(PyEval_EvalFrameEx+0x5bf6)[0x7f50fba38366]
/usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0(PyEval_EvalCodeEx+0x7d8)[0x7f50fbb77908]
/usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0(PyEval_EvalCode+0x19)[0x7f50fba325d9]
/usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0(PyEval_EvalFrameEx+0x6ac0)[0x7f50fba39230]
/usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0(PyEval_EvalCodeEx+0x7d8)[0x7f50fbb77908]
/usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0(PyEval_EvalFrameEx+0x5bf6)[0x7f50fba38366]
/usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0(PyEval_EvalCodeEx+0x7d8)[0x7f50fbb77908]
/usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0(PyEval_EvalCode+0x19)[0x7f50fba325d9]
/usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0(PyRun_StringFlags+0x76)[0x7f50fbae26f6]
gem5/build/X86/gem5.opt(_Z6m5MainiPPc+0x83)[0x55ead537e823]
gem5/build/X86/gem5.opt(main+0x38)[0x55ead48d5068]
/lib/x86_64-linux-gnu/libc.so.6(__libc_start_main+0xe7)[0x7f50f9d4ab97]
gem5/build/X86/gem5.opt(_start+0x2a)[0x55ead48fd37a]
— END LIBC BACKTRACE —
```

重要的是要注意，为了验证您遇到的是段错误，请向上滚动回溯输出并验证 `gem5 has encountered a segmentation fault!` 行已输出。
此类错误的原因通常是 C++ 文件中的错误导致不正确的地址访问。
在 gem5 中调试段错误的最佳方法是使用 gdb，我们在此处提供了文档 [here](https://www.gem5.org/documentation/general_docs/debugging_and_testing/debugging/debugger_based_debugging)。

## Fatal（致命错误）

当模拟配置无效且 gem5 模拟器无法处理时，通常会发生致命错误。
致命错误前面是此错误来源的文件，这通常是查找问题所在位置的良好指示。
例如，在下面的错误中，`gem5/src/cpu/base.cc` 将是调试此错误的良好起点。

```bash
build/ALL/cpu/base.cc:186: fatal: Number of processes (cpu.workload) (0) assigned to the CPU does not equal number of threads (1).
```

此类错误可能涵盖的情况包括传递给 gem5 的错误文件类型或无效值，或未连接的端口，仅举几个例子。
这应该为您提供有关当前问题的更多信息，但如果仍然没有足够的信息，使用 gem5 中的一些[调试技术](https://www.gem5.org/documentation/general_docs/debugging_and_testing/debugging/trace_based_debugging)，例如 gdb 或调试标志可能会有所帮助。


## Panic（恐慌错误）

如果您遇到 panic 错误，这通常表示 gem5 本身存在问题。
gem5 中一些更常见的 panic 错误是使用了无法识别的值或未实现的函数。
要调试这些错误，您可以从查看生成此错误的文件开始，该文件在终端中 panic 错误之前指示。
例如，在下面的错误中，最好从查看 `gem5/src/sim/mem_pool.cc` 开始

```bash
build/ARM/sim/mem_pool.cc:45: panic: assert(_totalPages > 0) failed
```

这应该为您提供有关当前问题的更多信息，尽管与上面的致命错误类似，如果仍然没有足够的信息，使用 gem5 中的一些[调试技术](https://www.gem5.org/documentation/general_docs/debugging_and_testing/debugging/trace_based_debugging)可能会有所帮助。

## Python 脚本错误

对于任何类型的 Python 错误，例如 AttributeError 或 OSError，最好从查看错误消息下方开始，您应该在那里看到跟踪输出。
第一个文件和行号应指示错误发生的位置。
例如，对于下面的错误，您应该从查看 `build/ARM/python/m5/SimObject.py(908)` 开始，如果这不能提供足够的信息，请继续查看 `configs/example/gem5_library/arm-ubuntu-run.py(70)`。

```bash
AttributeError: Class PrivateL1PrivateL2CacheHierarchy has no parameter l1_size

At:
  build/ARM/python/m5/SimObject.py(908): __setattr__
  configs/example/gem5_library/arm-ubuntu-run.py(70): <module>
  build/ARM/python/m5/main.py(597): main
```

同样，如果您收到如下所示的回溯错误，您还需要参考输出的最底部，以了解从哪里开始调试。在这个 IOError 示例中，您首先需要查看 `gem5/configs/common/SysPaths.py`

```bash
Traceback (most recent call last):
File "<string>", line 1, in <module>
File "/opt/gem5/src/python/m5/main.py", line 389, in main
exec filecode in scope
File "./configs/example/fs.py", line 327, in <module>
test_sys = build_test_system(np)
File "./configs/example/fs.py", line 96, in build_test_system
options.ruby, cmdline=cmdline)
File "/opt/gem5/configs/common/FSConfig.py", line 580, in
makeLinuxX86System
makeX86System(mem_mode, numCPUs, mdesc, self, Ruby)
File "/opt/gem5/configs/common/FSConfig.py", line 506, in makeX86System
disk2.childImage(disk('linux-bigswap2.img'))
File "/opt/gem5/configs/common/SysPaths.py", line 45, in disk
return searchpath(disk.path, filename)
File "/opt/gem5/configs/common/SysPaths.py", line 41, in searchpath
raise IOError, "Can't find file '%s' on path." % filename
IOError: Can't find file 'linux-bigswap2.img' on path.
```

查看此文件应该为您提供更多信息以帮助调试，但如果这还不够，您可以查看[此处](https://www.gem5.org/documentation/general_docs/debugging_and_testing/debugging/trace_based_debugging)以启用基于跟踪的调试以获取更多信息。

## PreCommit

如果您在将代码推送到 develop 分支时遇到错误，一个潜在问题是您可能没有通过 gem5 在提交任何更改之前所需的 precommit 检查。
如果您在 Gerrit 中看到已验证检查出现以下错误，您可以导航到测试输出的日志。

```bash
Kokoro presubmit build finished with status: FAILURE
```

如果这些日志中的输出包含如下行，您需要验证您的更改是否符合 gem5 中的编码风格。

```bash
trim trailing whitespace.................................................Failed
```

为了确保您的代码通过这些检查，您应该在更改上安装并运行 precommit。
您可以通过运行以下行来安装它。

```bash
pip install pre-commit
pre-commit install
```

此外，您可以改为运行 `util/pre-commit-install.sh` 来设置它。
从这里开始，pre-commit 将在您使用 `git commit` 时始终运行。
但是，如果您已经提交了这些文件，可以通过运行 `pre-commit run --files <files to format>` 来检查特定文件，运行 `pre-commit run --all-files` 来测试整个目录，或运行 `pre-commit run <hook_id>` 来检查单个钩子。
运行这些命令时，pre-commit 将检测任何样式问题，并自动为您重新格式化文件。

## Change-ID

如果您在让持续集成测试在 GitHub 上通过时遇到问题，您可能忘记在提交消息中添加 Change-Id。
尽管我们已经迁移不再使用 Gerrit，但我们仍然需要添加 Change-Id。
为了修改您的提交并使所有检查通过，您必须从 Gerrit 安装提交消息钩子。
您可以通过运行以下命令来安装和更新您的提交。

```bash
n f=.git/hooks/commit-msg ; mkdir -p  ;  curl -Lo  https://gerrit-review.googlesource.com/tools/hooks/commit-msg ; chmod +x
git commit --amend --no-edit
```

如果您想了解有关提交消息钩子的更多信息，请阅读[此处](https://gerrit-review.googlesource.com/Documentation/cmd-hook-commit-msg.html)，如果您想了解有关 Change-Id 的更多信息，请查看[此处](https://gerrit-review.googlesource.com/Documentation/user-changeid.html)

## 其他问题

如果您在使用 gem5 时继续遇到错误，请随时[寻求帮助](/ask-a-question)。
此外，如果其他渠道没有涵盖您需要的所有信息，您可以在此处找到有关如何报告可能需要修复的错误的信息 [here](https://www.gem5.org/documentation/reporting_problems/)。
