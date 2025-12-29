---
layout: documentation
title: 编译 SLICC 协议
doc: Learning gem5
parent: part3
permalink: /documentation/learning_gem5/part3/MSIbuilding/
author: Jason Lowe-Power
---


## 构建 MSI 协议

### SLICC 文件

既然我们已经完成了协议的实现，我们需要编译它。您可以下载完整的 SLICC 文件：

- [MSI-cache.sm](https://gem5.googlesource.com/public/gem5/+/refs/heads/stable/src/learning_gem5/part3/MSI-cache.sm)
- [MSI-dir.sm](https://gem5.googlesource.com/public/gem5/+/refs/heads/stable/src/learning_gem5/part3/MSI-dir.sm)
- [MSI-msg.sm](https://gem5.googlesource.com/public/gem5/+/refs/heads/stable/src/learning_gem5/part3/MSI-msg.sm)

在构建协议之前，我们需要再创建一个文件：`MSI.slicc`。此文件告诉 SLICC 编译器为此协议编译哪些状态机文件。第一行包含我们的协议名称。然后，该文件包含许多 `include` 语句。每个 `include` 语句都有一个文件名。此文件名可以来自任何环境变量 `PROTOCOL_DIRS` 目录。我们在 SConsopts 文件中声明了当前目录为 `PROTOCOL_DIRS` 的一部分 (`main.Append(PROTOCOL_DIRS=[Dir('.')])`)。另一个目录是 `src/mem/protocol/`。这些文件像 C++ 头文件一样被包含。实际上，所有文件都被处理为一个大型 SLICC 文件。因此，任何声明在其他文件中使用的类型的文件必须在它们被使用的文件之前（例如，`MSI-msg.sm` 必须在 `MSI-cache.sm` 之前，因为 `MSI-cache.sm` 使用 `RequestMsg` 类型）。

```cpp
protocol "MSI";
include "RubySlicc_interfaces.slicc";
include "MSI-msg.sm";
include "MSI-cache.sm";
include "MSI-dir.sm";
```

您可以下载完整文件
[这里](https://github.com/gem5/gem5/blob/stable/src/learning_gem5/part3/MSI.slicc)。

### 添加新的配置选项 RUBY_PROTOCOL_MSI (gem5 >= 23.1)

注意：如果用户使用比 23.0 更新的 gem5 版本，则需要执行一些额外的步骤来设置 Kconfig 文件。否则，用户可以跳过步骤到 `使用 SCons 编译协议` 部分。

然后您需要在 `learning_gem5/part3/Kconfig` 文件中添加 MSI 协议，以让 scons 启用构建带有 MSI 协议的 gem5。

```
# 如果 RUBY_PROTOCOL_MSI=y，则设置 PROTOCOL="MSI"
config PROTOCOL
    default "MSI" if RUBY_PROTOCOL_MSI

# 添加新选项 RUBY_PROTOCOL_MSI
cont_choice "Ruby protocol"
    config RUBY_PROTOCOL_MSI
        bool "MSI"
endchoice
```

在 `src/Kconfig` 中

```
rsource "base/Kconfig"
rsource "mem/ruby/Kconfig"
rsource "learning_gem5/part3/Kconfig"
```

请在 `mem/ruby/Kconfig` 下面添加 `learning_gem5/part3/Kconfig`。

### 使用 SCons 编译协议

#### 在较旧的 gem5 版本中 (gem5 <= 23.0)

大多数 SCons 默认值（在 `build_opts/` 中找到）指定协议为 `MI_example`，这是一个示例，但性能较差的协议。因此，我们不能简单地使用默认构建名称（例如，`X86` 或 `ARM`）。我们必须在命令行上指定 SCons 选项。下面的命令行将使用 X86 ISA 构建我们的新协议。

```sh
scons build/X86_MSI/gem5.opt --default=X86 PROTOCOL=MSI SLICC_HTML=True
```

此命令将在目录 `build/X86_MSI` 中构建 `gem5.opt`。您可以在此处指定 *任何* 目录。此命令行有两个新参数：`--default` 和 `PROTOCOL`。首先，`--default` 指定在 `build_opts` 中使用哪个文件作为所有 SCons 变量（例如，`ISA`, `CPU_MODELS`）的默认值。接下来，`PROTOCOL` *覆盖* 指定默认值中 `PROTOCOL` SCons 变量的任何默认值。因此，我们告诉 SCons 专门编译我们的新协议，而不是 `build_opts/X86` 中指定的任何协议。

构建 gem5 的命令行上还有一个变量：`SLICC_HTML=True`。当您在构建命令行上指定此项时，SLICC 将为您的协议生成 HTML 表格。您可以在 `<build directory>/mem/protocol/html` 中找到 HTML 表格。默认情况下，SLICC 编译器会跳过构建 HTML 表格，因为它会影响编译 gem5 的性能，尤其是在网络文件系统上编译时。

gem5 完成编译后，您将拥有一个带有新协议的 gem5 二进制文件！如果您想将另一个协议构建到 gem5 中，您必须更改 `PROTOCOL` SCons 变量。因此，为每个协议使用不同的构建目录是一个好主意，特别是如果您要比较协议。

构建协议时，您可能会遇到 SLICC 编译器报告的 SLICC 代码中的错误。大多数错误包括错误的文件和行号。有时，此行号是发生错误 *之后* 的行。实际上，行号可能远低于实际错误。例如，如果大括号不匹配，错误会将文件的最后一行报告为位置。

#### 在较新的 gem5 版本中 (gem5 >= 23.1)

大多数 Kconfig 默认值（在 `build_opts/` 中找到）指定协议为 `MI_example`，这是一个示例，但性能较差的协议。因此，我们不能简单地使用默认构建名称（例如，`X86` 或 `ARM`）。我们必须通过 `menuconfig`、`setconfig` 等指定 Kconfig 选项。下面的命令行将使用 X86 ISA 构建我们的新协议。

```sh
scons defconfig build/X86_MSI build_opts/X86
scons setconfig build/X86_MSI RUBY_PROTOCOL_MSI=y SLICC_HTML=y
scons build/X86_MSI/gem5.opt
```

此命令将在目录 `build/X86_MSI` 中构建 `gem5.opt`。您可以在此处指定 *任何* 目录。第一个命令告诉 SCons 创建一个新的构建目录，并使用 `build_opts/X86` 中的默认值对其进行配置。第二个命令使用 `setconfig` kconfig 工具使用 `RUBY_PROTOCOL_MSI=y` 更新 `build/X86_MSI` 目录配置中的 `PROTOCOL` 和 `SLICC_HTML` 选项。您也可以使用其他工具（如 `menuconfig`）以交互方式更新这些设置。最后，最后一个命令告诉 SCons 使用此新配置在我们的构建目录中构建。

还有一个 kconfig 设置我们要更改：`SLICC_HTML=y`。当您指定此项时，SLICC 将为您的协议生成 HTML 表格。您可以在 `<build directory>/mem/protocol/html` 中找到 HTML 表格。默认情况下，SLICC 编译器会跳过构建 HTML 表格，因为它会影响编译 gem5 的性能，尤其是在网络文件系统上编译时。

gem5 完成编译后，您将拥有一个带有新协议的 gem5 二进制文件！如果您想将另一个协议构建到 gem5 中，您必须在 setconfig 步骤中设置 `RUBY_PROTOCOL_{NAME}=y` 以更改 `PROTOCOL` kconfig 变量。因此，为每个协议使用不同的构建目录是一个好主意，特别是如果您要比较协议。

构建协议时，您可能会遇到 SLICC 编译器报告的 SLICC 代码中的错误。大多数错误包括错误的文件和行号。有时，此行号是发生错误 *之后* 的行。实际上，行号可能远低于实际错误。例如，如果大括号不匹配，错误会将文件的最后一行报告为位置。

有关 gem5 kconfig 文档，请参阅
[这里](https://www.gem5.org/documentation/general_docs/kconfig_build_system/)
