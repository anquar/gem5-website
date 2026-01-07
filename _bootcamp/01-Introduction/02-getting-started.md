---
layout: bootcamp
title: gem5 入门
permalink: /bootcamp/introduction/getting-started
section: introduction
author: [Jason Lowe-Power, Bobby R. Bruce]
---
<!-- _class: title -->

## gem5 入门

在本节中，我们将熟悉教程的 codespace 环境并运行我们的第一次 gem5 模拟。

---

## 让我们开始吧

### 此示例将展示

1. 如何获取 gem5。
2. 如何构建它。
3. 运行一个非常基础的 "Hello World" 模拟。

- 获取和编译 gem5 通常是最困难的部分。
- 幕后发生了很多复杂的事情。我们稍后会解释。

---

## 典型下载方式

gem5 不是您可以轻松下载二进制文件的典型软件项目。
也就是说，`apt install gem5` 不会起作用。

gem5 的主要分发方式是源代码，您必须构建它。

```sh
git clone https://github.com/gem5/gem5
cd gem5
```

> gem5 仓库中有两个主要分支：
> **stable**：gem5 的默认分支。在稳定版本发布时更新。目前是 v24.0（截至 2024 年 8 月）。
> **develop**：定期添加新功能、改进等的分支，用于下一个版本。

在本教程中，我们将使用包含一些示例材料的仓库的 codespaces。尽管所有 gem5 代码都是 v24.0。

---

## gem5 版本

在 **stable** 分支上，每个版本都有_标签_。

我们大约每年发布 2-3 次 gem5。
我们没有严格的发布时间表或功能或错误修复目标。

版本以年份和编号命名。

例如，最新的 gem5 版本 v24.0 是 2024 年的第一个版本。

完整版本字符串是 `v24.0.0.0`。
最后两个数字用于

- 小版本（当发现重大错误时很少发生）。
- 热修复版本：这些用于发布后发现的小错误。

更多信息请参见 [CONTRIBUTING.md](../06-Contributing/01-contributing.md)。

---

## 使用 codespaces

- 我们将使用"训练营环境"
  - 注意：这也是这些幻灯片的源代码所在位置
  - 您将在 <https://github.com/gem5bootcamp/2024> 找到的仓库中进行所有开发。

这些幻灯片可在 <https://bootcamp.gem5.org/> 获取，供您跟随学习。
（注意：它们将被归档到 <https://gem5bootcamp.github.io/2024>）

> **步骤 1：** 前往教室 <https://classroom.github.com/a/gCcXlgBs>

您需要加入 GitHub 组织（通过教室）才能获得免费的 codespaces。

### 我们强烈建议在训练营中使用 codespaces。

这保证了每个人都使用相同的环境，并使调试更容易。

---

## 使用 codespaces 2

**加入**教室后，您可以前往仓库并点击绿色的 "Code" 按钮。
再次提醒，这是幻灯片所在的仓库。

<https://github.com/gem5bootcamp/2024/>

![启动 codespace 的截图](/bootcamp/01-Introduction/02-getting-started-imgs/codespaces-screenshot-1.drawio.png)

---

## 使用 codespaces 3

> **步骤 3：** 等待环境加载。

如果您安装了 Codespaces 扩展，也可以在本地 VS Code 中打开它。
（如果您这样做，扩展不会自动安装在您的本地 VS Code 中。）

![codespace 已加载并准备使用的截图 width:1100px](/bootcamp/01-Introduction/02-getting-started-imgs/codespaces-screenshot-2.drawio.png)

---

## 浏览仓库

- **`gem5/`**
  - gem5 源代码（v24.0）。一个子仓库
- **`gem5-resources/`**
  - gem5 资源的源代码（工作负载、磁盘等）。也是一个子仓库
- **`slides/`**
  - 这些幻灯片的 Markdown 版本。用于构建网站/幻灯片。
  - 您也可以在 VS Code 中预览幻灯片。
- **`materials/`**
  - 教程的 Python 脚本和其他材料。
  - 大部分现场编码示例将在这里。
  - 已完成的示例在 `completed` 目录中。
- 一些其他内容用于网站、自动构建、VS Code 配置等。

幻灯片和材料都按章节和课程进行分解。
我们使用编号来保持顺序。

---

## 构建 gem5

> 现在不要这样做！

```sh
scons build/ALL/gem5.opt -j [number of cores]
```

- 这需要一些时间（16 核需要 10-15 分钟，1 核约需 1 小时）。
- 如果您使用 codespaces，我们为您准备了预构建的二进制文件。
- 我们稍后会讨论构建系统和选项。

<script src="https://asciinema.org/a/6rAd24brgGqb3Sj8Kmvy1msaG.js" id="asciicast-6rAd24brgGqb3Sj8Kmvy1msaG" async="true"></script>

---
<!-- _class: center-image -->

## 现场编码示例时间

当我们这样做时，请随时在幻灯片中跟随。

幻灯片（位于 `slides/01-Introduction/02-getting-started.md`）包含我们将使用的代码片段。如果您落后了，可以从那里复制粘贴。

在 VS Code 中按 "Preview" 按钮以在本地查看渲染的幻灯片版本。

![按预览按钮的位置](/bootcamp/01-Introduction/02-getting-started-imgs/preview-button.drawio.png)

---

## 让我们开始编写模拟配置

```python
from gem5.prebuilt.demo.x86_demo_board import X86DemoBoard
from gem5.resources.resource import obtain_resource
from gem5.simulate.simulator import Simulator
```

此模板代码可在 `materials/01-Introduction/02-getting-started/` 目录中找到。
打开 [`basic.py`](https://github.com/gem5bootcamp/2024/blob/main/materials/01-Introduction/02-getting-started/basic.py) 文件并开始编辑。

在整个训练营中，我们将在 materials 目录中编辑/扩展文件。

如果您使用 VS Code，幻灯片中提供了代码链接。

---

## 让我们偷懒并使用预构建的板子

```python
board = X86DemoBoard()
```

X86DemoBoard 具有以下属性：

- 单通道 DDR3，2GB 内存。
- 4 核 3GHz 处理器（使用 gem5 的 "timing" 模型）。
- MESI 两级缓存层次结构，32kB 数据和指令缓存以及 1MB L2 缓存。
- 将作为全系统模拟运行。

源代码可用：[src/python/gem5/prebuilt/demo/x86_demo_board.py](../../gem5/src/python/gem5/prebuilt/demo/x86_demo_board.py)。

---

## 让我们加载一些软件

```python
board.set_workload(
    obtain_resource("x86-ubuntu-24.04-boot-no-systemd")
)
```

- `obtain_resource` 下载运行工作负载所需的文件
  - 启动不带 systemd 的 Ubuntu，然后退出模拟
  - 下载磁盘镜像、内核并设置默认参数

请参见 [gem5 资源页面](https://resources.gem5.org/resources/x86-ubuntu-24.04-boot-no-systemd?version=1.0.0)。

---

<!-- _class: center-image -->

## gem5 资源 Web 门户

### [链接](https://resources.gem5.org/resources/x86-ubuntu-24.04-boot-no-systemd?version=1.0.0)

![gem5 资源网页截图](/bootcamp/01-Introduction/02-getting-started-imgs/resources-screenshot.drawio.png)

---

## 现在，让我们创建一个模拟器来实际运行

```python
sim = Simulator(board)
sim.run(20_000_000_000) # 200 亿个 tick 或 20 毫秒
```

---

## 就是这样！

```python
from gem5.prebuilt.demo.x86_demo_board import X86DemoBoard
from gem5.resources.resource import obtain_resource
from gem5.simulate.simulator import Simulator
board = X86DemoBoard()
board.set_workload(
    obtain_resource("x86-ubuntu-24.04-boot-no-systemd")
)
sim = Simulator(board)
sim.run(20_000_000_000) # 200 亿个 tick 或 20 毫秒
```

运行它：

```sh
gem5-mesi basic.py
```

---

## 结果

gem5 有很多输出。
它在 stdout 上很详细，但也会在 `m5out/` 中写入许多文件。

### gem5 的输出

在 `m5out/` 中您会看到：

- `stats.txt`：模拟的统计信息。
- `board.pc.com_1.device`：模拟的控制台输出。
- `citations.bib`：使用的模型和资源的引用。
- `config.ini/json`：使用的配置文件。
- `config*.pdf/svg`：系统和缓存配置的可视化。

---

## 要点

- `gem5` 是一个 Python 解释器。
- `gem5` 的*接口*是 Python 脚本。
- `gem5` 包含许多 Python 库。
  - gem5 中的所有模型（例如，缓存、CPU 等）。
  - 标准库 (stdlib)
- gem5 的输出默认在 `m5out/` 中。
  - 配置详细信息
  - 其他输出
  - **统计信息**（最重要的部分）
- Codespaces 环境已配置，使事情变得简单。
  - 您需要做一些工作来设置自己的环境。
