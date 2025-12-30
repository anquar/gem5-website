---
layout: documentation
title: 运行
doc: gem5art
parent: main
permalink: /documentation/gem5art/main/run
Authors:
  - Ayaz Akram
  - Jason Lowe-Power
---

# 运行

## 简介

每个 gem5 实验都包装在一个运行对象中。
这些运行对象包含执行 gem5 实验所需的所有信息，可以通过 gem5art tasks 库（或使用 `run()` 函数手动）执行。gem5Run 与 gem5art 的 Artifact 类交互，以确保 gem5 实验的可重现性，并将当前的 gem5Run 对象和输出结果存储在数据库中以供以后分析。

## SE 和 FS 模式运行

接下来是 gem5Run 类的两个方法（用于 gem5 的 SE (system-emulation) 和 FS (full-system) 模式），它们从用户的角度给出了创建 gem5Run 对象所需参数的思路：

```python

@classmethod
def createSERun(cls,
                name: str,
                gem5_binary: str,
                run_script: str,
                outdir: str,
                gem5_artifact: Artifact,
                gem5_git_artifact: Artifact,
                run_script_git_artifact: Artifact,
                *params: str,
                timeout: int = 60*15) -> 'gem5Run':
.......


@classmethod
def createFSRun(cls,
                name: str,
                gem5_binary: str,
                run_script: str,
                outdir: str,
                gem5_artifact: Artifact,
                gem5_git_artifact: Artifact,
                run_script_git_artifact: Artifact,
                linux_binary: str,
                disk_image: str,
                linux_binary_artifact: Artifact,
                disk_image_artifact: Artifact,
                *params: str,
                timeout: int = 60*15) -> 'gem5Run':
.......

```

对于用户来说，理解传递给运行对象的不同参数很重要：

- `name`: 运行的名称，可以作为标签来搜索数据库以找到所需的运行（期望用户为不同的实验使用唯一的名称）
- `gem5_binary`: 要使用的实际 gem5 二进制文件的路径
- `run_script`: 将与 gem5 二进制文件一起使用的 python 运行脚本的路径
- `outdir`: gem5 结果应写入的目录路径
- `gem5_artifact`: gem5 二进制 git 组件对象
- `gem5_git_artifact`: gem5 源代码 git 仓库组件对象
- `run_script_git_artifact`: 运行脚本组件对象
- `linux_binary`（仅全系统）：要使用的实际 linux 二进制文件的路径（也由运行脚本使用）
- `disk_image`（仅全系统）：要使用的实际磁盘镜像的路径（也由运行脚本使用）
- `linux_binary_artifact`（仅全系统）：linux 二进制组件对象
- `disk_image_artifact`（仅全系统）：磁盘镜像组件对象
- `params`: 传递给运行脚本的其他参数
- `timeout`: 允许当前 gem5 作业执行的最长时间（以秒为单位）

组件参数（`gem5_artifact`、`gem5_git_artifact` 和 `run_script_git_artifact`）用于确保这是可重现的运行。
除了上述参数外，gem5Run 类还跟踪 gem5 运行的其他特征，例如，开始时间、结束时间、gem5 运行的当前状态、终止原因（如果运行已完成）等。

虽然用户可以编写自己的运行脚本与 gem5 一起使用（使用任何命令行参数），但目前当使用 `createFSRun` 方法为全系统实验创建 `gem5Run` 对象时，假设 `linux_binary` 和 `disk_image` 的路径在命令行上传递给运行脚本（作为 `createFSRun` 方法的参数）。

## 运行实验

`gem5Run` 对象具有运行一次 gem5 执行所需的一切。
通常，这将通过使用 gem5art *tasks* 包来执行。
但是，也可以手动执行 gem5 运行。

`run` 函数执行 gem5 实验。
它接受两个可选参数：与运行关联的任务（用于簿记）和用于执行运行的可选目录。

`run` 函数通过使用 `Popen` 执行 gem5 二进制文件。
这会创建另一个进程来执行 gem5。
`run` 函数是*阻塞*的，在子进程完成之前不会返回。

当子进程运行时，父 python 进程每 5 秒更新一次 `info.json` 文件中的状态。

`info.json` 文件是序列化的 `gem5run` 对象，包含所有运行信息和当前状态。

`gem5Run` 对象有 7 种可能的状态。
这些目前是存储在 `status` 属性中的简单字符串。

- `Created`: 运行已创建。在调用 `createSRRun` 或 `createFSRun` 时，在构造函数中设置此状态。
- `Begin run`: 当调用 `run()` 时，在检查数据库后，我们进入 `Begin run` 状态。
- `Failed artifact check for ...`: 当组件检查失败时，状态设置为此。
- `Spawning`: 接下来，就在调用 `Popen` 之前，运行进入 `Spawning` 状态。
- `Running`: 一旦父进程开始旋转等待子进程完成，运行就进入 `Running` 状态。
- `Finished`: 当子进程以退出代码 `0` 完成时，运行进入 `Finished` 状态。
- `Failed`: 当子进程以非零退出代码完成时，运行进入 `Failed` 状态。

## 数据库中已存在的运行

使用 gem5art 启动运行时，它可能会抱怨运行已存在于数据库中。
基本上，在启动 gem5 作业之前，gem5art 会检查此运行是否与数据库中的现有运行匹配。
为了唯一标识运行，从以下内容生成单个哈希：

- 运行脚本
- 传递给运行脚本的参数
- 运行对象的组件，对于 SE 运行，包括：gem5 二进制组件、gem5 源代码 git 组件、运行脚本（实验仓库）组件。对于 FS 运行，组件列表还包括 linux 二进制组件和磁盘镜像组件，以及 SE 运行的组件。

如果此哈希已存在于数据库中，gem5art 将不会基于此运行对象启动新作业，因为具有相同参数的运行已经执行。
如果用户仍然想要启动此作业，用户必须从数据库中删除现有的运行对象。

## 搜索数据库以查找运行

### 实用脚本

gem5art 提供实用程序 `gem5art-getruns` 来搜索数据库并检索运行。
根据参数，`gem5art-getruns` 将结果转储到 json 格式的文件中。

```
usage: gem5art-getruns [-h] [--fs-only] [--limit LIMIT] [--db-uri DB_URI]
                       [-s SEARCH_NAME]
                       filename

Dump all runs from the database into a json file

positional arguments:
  filename              Output file name

optional arguments:
  -h, --help            show this help message and exit
  --fs-only             Only output FS runs
  --limit LIMIT         Limit of the number of runs to return. Default: all
  --db-uri DB_URI       The database to connect to. Default
                        mongodb://localhost:27017
  -s SEARCH_NAME, --search_name SEARCH_NAME
                        Query for the name field
```

### 手动搜索数据库

一旦您开始使用 gem5 运行实验并想知道这些运行的状态，您可以查看数据库中的 gem5Run 组件。
为此，gem5art 提供了一个方法 `getRuns`，您可以按如下方式使用：

```python
import gem5art.run
from gem5art.artifact import getDBConnection
db = getDBConnection()
for i in gem5art.run.getRuns(db, fs_only=False, limit=100):
    print(i)
```

## 搜索数据库以查找具有特定名称的运行

如上所述，在创建 FS 或 SE 模式运行对象时，用户必须传递一个 name 字段来识别特定的运行集（或实验）。
我们期望用户会注意使用完全表征一组实验的名称字符串，可以将其视为 `Nonce`。
例如，如果我们要运行实验来测试 gem5 上的 linux 内核启动，我们可以使用名称字段 `boot_tests_v1` 或 `boot_tests_[month_year]`（其中 month_year 对应于运行实验的月份和年份）。

之后，可以使用相同的名称在数据库中搜索相关的 gem5 运行。
为此，gem5art 提供了一个方法 `getRunsByName`，可以按如下方式使用：

```python
import gem5art.run
from gem5art.artifact import getDBConnection
db = getDBConnection()
for i in gem5art.run.getRunsByName(db, name='boot_tests_v1', fs_only=True, limit=100):
    print(i)
```
