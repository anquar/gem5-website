---
layout: bootcamp
title: gem5 测试
permalink: /bootcamp/contributing/testing
section: contributing
author: Bobby R. Bruce
---
<!-- _class: title -->

## gem5 测试

为了检查您对 gem5 的更改是否正常工作，您应该运行一些 gem5 测试。

---

## 贡献和测试

一般来说，我们希望所有贡献都附带测试。

但实际上，如果我们这样要求测试，我们将收不到任何贡献。

### 我们对测试的看法

- 如果某个功能没有经过测试，我们不会"支持它"（例如，DRAMSim3）。
- 如果"gem5 开发者"想要添加一个受支持的功能，通常由我们来添加测试。
- 添加测试会占用修复错误、添加新功能等的时间。

---

## gem5 测试类别

我们定期在 gem5 代码库上运行测试，以确保更改不会破坏代码。
这些测试主要分为四类：

1. **CPP 单元测试**：这些是运行 C++ 代码的测试。在 gem5 中，我们使用 Google Test 框架。
2. **Python 单元测试**：这些是运行 Python 代码的测试。在 gem5 中，我们使用 Python unittest 框架。
3. **TestLib 测试**：这些测试运行 gem5 模拟，验证退出代码，并将输出与预期输出进行比较（"testlib" 是用于执行此操作的框架名称）。
4. **编译测试**：在不同配置下使用不同编译器/环境编译 gem5 的测试。

> 我们运行的一些测试不属于这些类别，但以上是主要的测试类别。

---

## gem5 测试计划

1. **CI 测试**：这些测试在每次向 gem5 提交 pull request 时运行，以及在每次更新任何 pull request 时运行。CI 测试包括 CPP 和 Python 单元测试以及 TestLib 测试和编译测试的子集。这些测试设计为"快速"运行（按 gem5 标准），在 4 小时内完成。
2. **每日测试**：这些测试每天在 gem5 代码库上运行。
这些测试包括较大的 Testlib 测试。它们通常需要 12 小时或更长时间才能完成。
3.  **每周测试**：这些测试每周在 gem5 代码库上运行。
这些测试包括最大的 Testlib 测试套件和编译测试。这些测试通常需要 1 到 2 天才能完成。
4. **编译器测试**：这些测试每周运行一次。
这些测试运行 gem5 编译目标和项目当前支持的编译器的交叉组合。这些测试通常需要大约 12 小时才能完成。

---

## GitHub Actions

这些测试的完整 GitHub Actions 工作流可以在 gem5 仓库的 [.github/workflows/](https://github.com/gem5/gem5/blob/v24.0/.github/workflows) 中找到。

我们在本次课程中不会详细介绍这些，但您可以查看这些 yaml 文件，了解如何触发 GitHub Actions 来运行这些 gem5 测试。

这些测试在"自托管"运行器上运行。在威斯康星州有一台机器（loupe）运行这些测试。

> 如果您知道"loupe"是什么，会有加分

---

## CPP 单元测试

[src/base/bitfield.test.cc](https://github.com/gem5/gem5/blob/v24.0/src/base/bitfield.test.cc) 是 gem5 中 CPP 单元测试的典型示例。

它是一个 GTest。有关 GTest 的更多信息可以在 <https://google.github.io/googletest/> 找到。

与测试文件位于同一目录中的 SConscript 文件用于构建测试。

```python
GTest('bitfield.test', 'bitfield.test.cc', 'bitfield.cc')
```

格式为 `GTest(<test_name>, <test_source>, <source_files>)`。

---

### 运行 CPP 单元测试

您可以使用 `scons build/ALL/unittests.opt` 命令运行所有单元测试。

要运行特定测试：

```shell
scons build/ALL/base/bitfield.test.opt
./build/ALL/base/bitfield.test.opt
```

---

## Python 单元测试

[tests/pyunit/util/pyunit_convert_check.py](https://github.com/gem5/gem5/blob/v24.0/tests/pyunit/util/pyunit_convert_check.py) 是 gem5 中 Python 单元测试的典型示例。

有关 Python unittest 框架的更多信息可以在 <https://docs.python.org/3/library/unittest.html> 找到。

测试使用 `gem5 tests/run_pyunit.py` 命令运行。
在我们的情况下，测试运行器会将 "tests/pyunit" 目录中任何前缀为 "pyunit_" 的文件视为测试。

可以通过将子目录作为参数传递给 "tests/run_pytests.py" 来指定并单独运行 "tests/pyunit" 中的各个子目录。例如：`gem5 tests/run_pyunit.py --directory tests/pyunit/util`。

---

## 编译测试

编译测试每周在 gem5 代码库上运行。

这些测试直接在 GitHub Action 工作流中指定：[.github/workflows/compiler-tests.yaml](https://github.com/gem5/gem5/blob/v24.0/.github/workflows/compiler-tests.yaml)

这些测试使用一系列 Docker 镜像来测试使用不同编译器编译各种 gem5 配置。

如果您的系统偏离了我们在编译测试中测试的内容，我们不支持该编译器。

---

## TestLib 测试

TestLib 是我们开发的用于帮助运行 gem5 集成测试的库。

> 对于开发自己的测试框架，我们有些遗憾。它增加了维护负担，并没有提供太多好处。

TestLib 测试是 gem5 中最重要的测试。
这些测试运行 gem5 模拟并验证模拟的输出。
测试用 Python 编写，使用 "testlib" 框架来运行模拟并验证输出。

我们的单元测试覆盖率不是很好，因此我们的大部分测试都是通过 TestLib 进行的集成测试。

---

## 使用 TestLib

测试使用 gem5 仓库的 `test` 目录中的 `./main.py` 命令运行。

在运行测试时，只关注测试的子目录很有用：

```shell
./main.py run gem5/memory
```

上述命令只会运行 "tests/gem5/memory" 目录中的"快速"测试。
"快速"测试是在 CI 管道中运行的 testlib 测试。要运行"每日"或"每周"测试套件中的测试，您可以使用 `--length` 指定 `long` 或 `very-long`（`quick` 是 `length` 的默认值）。

---

## 使用 TestLib

`./main.py list` 命令可用于列出目录中的所有测试，我们在这里演示：

```shell
# 列出 tests/gem5/memory 中所有长测试：这些在每日测试中运行。
./main.py list --length long gem5/memory

# 列出 tests/gem5/memory 中所有超长测试：这些在每周测试中运行。
./main.py list --length very-long gem5/memory
```

---

## TestLib 测试的声明方式

让我们查看 ["tests/gem5/m5_util"](https://github.com/gem5/gem5/blob/v24.0/tests/gem5/m5_util) 以了解如何声明测试。

在此目录中有 "test_exit.py"。
任何前缀为 "test_" 的文件都被 testlib 框架视为测试，并在执行测试时自动运行。

"configs" 是一个配置脚本目录，用于运行 "test_exit.py" 中定义的测试。

现在，让我们查看 "test_exit.py" 并了解如何声明测试。

---

## 声明如何测试

导入 testlib 库（位于 `gem5/ext/testlib`）

```python
from testlib import *
```

许多测试使用正则表达式匹配。例如，我们检查下面是否遇到 `m5_exit` 指令，然后创建一个 *verifier*。

**`verifier`** 由 testlib 用于检查输出。

```py
m5_exit_regex = re.compile(
    r"Exiting @ tick \d* because m5_exit instruction encountered"
)
a = verifier.MatchRegex(m5_exit_regex)
```

---

<!-- _class: code-80-percent -->

## 声明测试

现在，我们使用特殊函数 `gem5_verify_config` 来运行 gem5，然后应用我们的验证器。

```py
gem5_verify_config(
    name="m5_exit_test", # 测试名称
    verifiers=[a], # 验证器（必须是可迭代的！）
    fixtures=(),
    config=joinpath( # 要运行的配置文件路径。
        config.base_dir,
        "tests", "gem5", "m5_util", "configs", "simple_binary_run.py",
    ),
    config_args=[ # 传递给配置文件的参数。
        "x86-m5-exit",
        "--resource-directory",
        resource_path,
    ],
    valid_isas=(constants.all_compiled_tag,),
)
```

---

## Valid ISAs 参数

在此测试上运行的 ISA。在这种情况下使用 "ALL/gem5.opt"。

- `constants.arg_tag`: "ARM/gem5.opt"
- `constants.x86_tag`: "X86/gem5.opt"
- `constants.riscv_tag`: "RISCV/gem5.opt"


虽然没有直接指定，但我们可以使用 `length` 参数来确定测试是作为 `quick`、`long` 还是 `very-long` 运行，它接受 `constants.quick_tag`、`constants.long_tag` 或 `constants.very_long_tag` 作为参数（默认是 `constants.quick_tag`）。

---

## 查看测试

```shell
./main.py list gem5/m5_util
```

```txt
Loading Tests
Discovered 12 tests and 6 suites in /workspaces/gem5-bootcamp-2024/gem5/tests/gem5/m5_util/test_exit.py
=====================================================
Listing all Test Suites.
=====================================================
SuiteUID:tests/gem5/m5_util/test_exit.py:m5_exit_test-ALL-x86_64-opt
=====================================================
Listing all Test Cases.
=====================================================
TestUID:tests/gem5/m5_util/test_exit.py:m5_exit_test-ALL-x86_64-opt:m5_exit_test-ALL-x86_64-opt
TestUID:tests/gem5/m5_util/test_exit.py:m5_exit_test-ALL-x86_64-opt:m5_exit_test-ALL-x86_64-opt-MatchRegex
=====================================================
```

---

## 运行测试

然后运行

```shell
./main.py run gem5/m5_util
```

**注意**：这会在每次运行测试时尝试构建 "ALL/gem5.opt"。
这可能很耗时。
您可以使用 `scons build/ALL/gem5.opt -j$(nproc)` 预先构建 ALL/gem5.opt，然后在运行 `./main.py run gem5/m5_util` 时添加 `--skip-build` 标志以跳过构建步骤：`./main.py run --skip-build gem5/m5_util`。

如果您想/需要在此步骤构建，请将 `-j$(nproc)` 传递给 `./main.py run` 命令。

---

## 练习：创建 TestLib 测试

转到 [materials/06-Contributing/02-testing/01-testlib-example](../../materials/06-Contributing/)。

将 "01-testlib-example" 移动到 gem5 仓库中的 "tests/gem5/"。

"test_example.py" 中提供了用于定义 testlib 测试的 `gem5_verify_config` 函数。

```python
gem5_verify_config(
    name="test-example-1", # 测试名称。必须唯一。
    verifiers=(), # 除了退出代码零检查之外，要添加的额外验证器。
    fixtures=(), # Fixtures：这在很大程度上已被弃用，可以忽略。
    config=joinpath(), # 配置脚本的路径。
    config_args=[], # 要传递给配置脚本的参数。
    valid_isas=(constants.arm_tag), # 需要在 ARM ISA 上运行
    length=constants.quick_tag, # 在 CI 管道中运行的快速测试
)
```

---

## 在此练习中，我们将执行以下操作：

1. 创建一个测试，运行 `example_config.py` 脚本而不带任何参数，并验证它正确运行。
2. 让此测试使用 `--to-print` 参数在模拟结束时打印 "Arm Simulation Completed."。
3. 使用验证器更新此测试，该验证器在运行完成后检查模拟的输出。
4. 编写第二个测试，执行与第一个测试相同的操作，但使用不同的输出消息（包括验证器）。

在每一步之后运行测试以验证更改：
`./main.py run gem5/01-testing-example`

---

## 提示和技巧

- 在测试命令末尾添加 `-vvv` 将为您提供有关测试的更多信息，特别是在发生错误时。
- 查看 "tests/gem5" 中的其他测试，了解如何编写测试的示例。
- 您可以使用以下命令预先构建 ARM/gem5.opt：

```bash
scons build/ARM/gem5.opt -j$(nproc)
```

然后，在运行 `./main.py run gem5/02-testing` 时，添加 `--skip-build` 标志以跳过构建步骤。

已完成的示例可以在 [materials/06-Contributing/02-testing/01-testlib-example/completed](/materials/06-Contributing/02-testing/01-testlib-example/completed) 找到。

---

## 恭喜！

您现在知道如何为 gem5 创建测试并运行它们以验证您的更改。

我们强烈建议您为对 gem5 所做的任何更改编写测试，以确保您的更改按预期工作并且不会破坏任何现有功能。
