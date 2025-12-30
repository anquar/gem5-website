---
layout: documentation
title: Kconfig 构建系统
doc: gem5 documentation
parent: kconfig_build_system
permalink: /documentation/general_docs/kconfig_build_system/
---

本指南面向需要构建支持多个 ISA 的 gem5 (>=23.1) 或自定义构建选项（例如 Ruby 内存协议）的高级用户。
需要熟悉 Kconfig 系统。

## 使用 Kconfig 构建系统构建 gem5

```bash
scons [OPTIONS] Kconfig_command TARGET
```

支持的 Kconfig 命令包括：

- `defconfig`
- `setconfig`
- `menuconfig`
- `guiconfig`
- `listnewconfig`
- `oldconfig`
- `olddefconfig`
- `savedefconfig`

最常用的选项是 `defconfig`、`setconfig` 和 `menuconfig`。
您可以使用 `scons --help` 列出这些命令及其附加信息。

使用 Kconfig 构建 gem5 现在有两个步骤。
第一步是初始配置，它使用所需配置设置构建目录。第二步是构建目标。
这通过 `defconfig` 命令完成。
例如：

```bash
scons defconfig gem5_build build_opts/ALL
```

这将在 `gem5_build` 构建目录中创建一个基于 `build_opts/ALL` 中指定的配置。此配置的确切路径存储在 `gem5_build/gem5.build/config` 中。

第二步是在配置的构建目录中构建目标。
这像往常一样使用 `scons` 完成。
例如：


```bash
scons -j$(nproc) gem5_build/gem5.opt
```

注意：为了保持与旧构建方案的向后兼容性，用户需要避免将 "build" 目录用于 Kconfig 构建。

要使用自定义 Kconfig 选项构建 gem5 Kconfig，在**初始配置**和**构建目标**之间需要一个额外的步骤。

此步骤是在配置的构建目录中设置 Kconfig 选项。
有两种方法可以设置 Kconfig 选项。
第一种是使用 `setconfig` 命令在命令行中直接设置 Kconfig 选项。例如：

```bash
scons setconfig gem5_build USE_KVM=y
```

这将在配置中将 `USE_KVM` 选项设置为 `y`，从而启用 KVM 支持。

第二种方法是使用 `menuconfig` 命令打开 menuconfig 编辑器。
menuconfig 编辑器允许您查看和编辑配置值以及查看帮助。
例如：

```bash
scons menuconfig gem5_build
```

## Kconfig 命令详情

### defconfig

`defconfig` 命令使用 defconfig 文件中指定的值设置配置，或者如果没有给定值，则使用默认值。第二个参数指定 defconfig 文件。所有默认的 gem5 defconfig 文件都位于 build_opts 目录中。用户也可以使用自己的 defconfig 文件。

例如：

```bash
scons defconfig gem5_build build_opts/RISCV
```

要使用您自己的 defconfig 文件：

```bash
scons defconfig gem5_build $HOME/foo/bar/myconfig
```

### setconfig

`setconfig` 命令在现有配置目录中设置命令行上指定的值。

用户或开发人员可以通过 `menuconfig` 或 `guiconfig` 获取 Kconfig 选项。

例如，要启用 gem5 在 systemc 内核中构建：

```bash
scons setconfig gem5_build USE_SYSTEMC=y
```

### menuconfig

`menuconfig` 命令打开 menuconfig 编辑器。
此编辑器允许您查看和编辑配置值以及查看帮助文本。`menuconfig` 在 CLI 中运行。

```bash
scons menuconfig gem5_build
```

如果成功，CLI 将如下所示：

![](/assets/img/kconfig/menuconfig.png)

用户可以使用箭头键导航菜单，使用回车键选择菜单项。用户还可以使用空格键选择或取消选择选项。用户还可以使用搜索功能查找特定选项。用户还可以使用 `?` 键查看特定选项的帮助文本。
以下是 `USE_ARM_ISA` 选项的帮助文本截图：

![](/assets/img/kconfig/menuconfig_details.png)

如果 `gem5_build` 目录不存在，SCons 将在路径 `gem5_build` 处设置一个具有默认选项的构建目录，然后调用 menuconfig，以便您可以设置其配置。

### guiconfig

`guiconfig` 命令打开 guiconfig 编辑器。
此编辑器将让您查看和编辑配置值，以及查看帮助文本。guiconfig 作为图形应用程序运行。该命令要求系统安装 `python3-tk` 包。

```bash
scons guiconfig gem5_build
```

如果成功，它将创建新窗口，如下所示：

![](/assets/img/kconfig/guiconfig.png)


### savedefconfig

`savedefconfig` 命令将当前配置保存到 defconfig。
您可以使用 menuconfig 设置包含您关心的选项的配置，然后使用 `savedefconfig` 创建最小配置文件。这些文件适合在 build_opts 目录中使用。第二个参数指定新 defconfig 文件的文件名。

保存的 defconfig 是查看哪些选项已设置为有趣值的好方法，也是将配置传递给其他人使用、放入错误报告等的更简单方法。

```bash
scons savedefconfig gem5_build new_def_config
```

### listnewconfig

`listnewconfig` 命令列出 Kconfig 中哪些选项设置是新的，以及哪些在当前配置文件中未设置。

```bash
scons listnewconfig gem5_build
```

### oldconfig

`oldconfig` 命令更新现有配置，为所需选项设置新值。这与 `olddefconfig` 类似，只是它会询问您希望为新设置使用什么值。

```bash
scons oldconfig gem5_build
```

### oldsaveconfig

`oldsaveconfig` 命令通过为所需选项设置新值来更新现有配置。这与 `oldconfig` 选项类似，只是它对新设置使用默认值。

```bash
scons oldsaveconfig gem5_build
```

用户可以通过运行 `scons -h` 获取 Kconfig 命令的详细信息。

## 报告错误

如果遇到问题，我们建议您通过保存使用的配置并分发它来报告问题。
为此，可以使用 `savedefconfig` 命令：

```bash
scons savedefconfig gem5_build new_config
```

或者，可以在 `gem5_build/gem5.build/config` 文件中找到配置。


# 参考

1. Kconfig 网站：https://www.kernel.org/doc/html/next/kbuild/kconfig-language.html
