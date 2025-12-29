---
layout: page
title: 贡献指南
permalink: contributing
author: Bobby R. Bruce
---

本文档是 gem5 的贡献指南。
以下各节按顺序列出了为 gem5 项目做贡献所涉及的步骤。

## 确定你可以贡献什么

了解如何为 gem5 做贡献的最简单方法是查看我们的 GitHub Issue 跟踪器：<https://github.com/gem5/gem5/issues>。

浏览这些未解决的 Issue，看看是否有你有能力处理的。当你找到一个你乐意执行的任务时，确认目前没有人被分配该任务，然后留言询问是否可以将该任务分配给你自己。虽然不是必须的，但我们鼓励首次贡献者这样做，以便熟悉该任务的开发人员可以就如何最好地实施必要的更改给出建议。

一旦开发人员回复了你的评论并提供了建议，你就可以正式将自己分配给该任务。这有助于 gem5 开发社区随时了解项目的哪些部分目前正在进行中。

**如果由于某种原因，你停止处理某项任务，请取消指派你自己。**

## 获取 git 仓库

gem5 git 仓库托管在 <https://github.com/gem5/gem5>。
**重要提示：对其他 gem5 仓库的贡献将不予考虑。请专门向 <https://github.com/gem5/gem5> 提交贡献。**

拉取 gem5 git 仓库：

```sh
git clone https://github.com/gem5/gem5
```

如果你希望使用 gem5 而从不做贡献，这没问题。但是，为了做贡献，我们使用 [GitHub Pull-Request 模型](https://docs.github.com/en/pull-requests)，因此建议在贡献之前 [Fork gem5 仓库](https://docs.github.com/en/get-started/quickstart/fork-a-repo)。

### Forking

请参阅 [关于 fork GitHub 仓库的 GitHub 文档](https://docs.github.com/en/get-started/quickstart/fork-a-repo)。由于我们将在 `develop` 分支上工作，请确保 fork 所有仓库分支，而不仅仅是 `stable` 分支。为此，在创建新 fork 时，取消选中“Copy the stable branch only”选项，以确你的 fork 包含所有仓库分支。

这将在你自己的 GitHub 帐户上创建你自己的 gem5 仓库的 fork 版本。
然后你可以使用以下命令在本地获取它：

```sh
git clone https://github.com/{your github account}/gem5
```

如果你只 fork 了 `stable` 分支，请运行以下两个命令来获取其他分支：

```sh
git remote add gem5 https://github.com/gem5/gem5.git
git fetch gem5
```

### stable 与 develop 分支

克隆后，git 仓库将默认检出 `stable` 分支。
`stable` 分支是 gem5 稳定发布分支。即，该分支的 HEAD 包含 gem5 的最新稳定版本。（在 `stable` 分支上执行 `git tag` 可以查看稳定版本列表。可以通过执行 `git checkout <release>` 检出特定版本）。由于 `stable` 分支仅包含正式发布的 gem5 代码，**贡献者不应在 `stable` 分支之上开发更改**，而应**在 `develop` 分支之上开发更改**。

切换到 `develop` 分支：

```sh
git switch develop
```

develop 分支在 gem5 发布时合并到 `stable` 分支中。
因此，你所做的任何更改都存在于 develop 分支上，直到下一次发布。

我们强烈建议创建你自己的本地分支来进行更改。
如果 `develop` 和 `stable` 没有被直接修改，开发流程效果最好。
这有助于在你的 fork 仓库中的不同分支之间组织你的更改。
以下示例将从 `develop` 创建一个名为 `new-feature` 的新分支：

```sh
git switch -c new-feature
```

## 进行修改

### C/CPP

不同的任务需要以不同的方式修改项目。
但是，在所有情况下，都必须遵守我们的风格指南。完整的 C/C++ 风格指南在 [此处](/documentation/general_docs/development/coding_style) 列出。

高级概述：

* 每行长度不得超过 79 个字符。
* 任何行都不应有尾随空格。
* 缩进必须是 4 个空格（无制表符）。
* 类名必须使用大驼峰命名法 (Upper Camel Case)（例如 `ThisIsAClass`）。
* 类成员变量必须使用小驼峰命名法 (Lower Camel Case)（例如 `thisIsAMemberVariable`）。
* 具有自己公共访问器的类成员变量必须以下划线开头（例如 `_variableWithAccessor`）。
* 局部变量必须使用蛇形命名法 (Snake Case)（例如 `this_is_a_local_variable`）。
* 函数必须使用小驼峰命名法（例如 `thisIsAFunction`）。
* 函数参数必须使用蛇形命名法。
* 宏必须全大写并带下划线（例如 `THIS_IS_A_MACRO`）。
* 函数声明返回类型必须在自己的一行上。
* 函数括号必须在自己的一行上。
* `for`/`if`/`while` 分支操作必须在条件语句前跟一个空格（例如 `for (...)`）。
* `for`/`if`/`while` 分支操作的左括号必须在同一行，右括号在自己的一行（例如 `for (...) {\n ... \n}\n`）。条件和左括号之间应该有一个空格。
* C++ 访问修饰符必须缩进两个空格，其中定义的方法/变量缩进四个空格。

下面是一个关于类应如何格式化的简单示例：

```C++
#DEFINE EXAMPLE_MACRO 7
class ExampleClass
{
  private:
    int _fooBar;
    int barFoo;

  public:
    int
    getFooBar()
    {
        return _fooBar;
    }

    int
    aFunction(int parameter_one, int parameter_two)
    {
        int local_variable = 0;
        if (true) {
            int local_variable = parameter_one + parameter_two + barFoo
                               + EXAMPLE_MACRO;
        }
        return local_variable;
    }

}
```

### Python

我们使用 [Python Black](https://github.com/psf/black) 将我们的 Python 代码格式化为正确的风格。安装：

```sh
pip install black
```

然后在修改/添加的 python 文件上运行：

```sh
black <files/directories>
```

对于变量/方法/等命名约定，请遵循 [PEP 8 命名约定建议](https://peps.python.org/pep-0008/#naming-conventions)。虽然我们尽力在整个 gem5 项目中强制执行命名约定，但我们知道有些情况并未执行。在这种情况下，请**遵循你正在修改的代码的约定**。

### 使用 pre-commit

为了帮助强制执行我们的风格指南，我们使用 [pre-commit](https://pre-commit.com)。pre-commit 是一个 git 钩子，因此必须由 gem5 开发人员显式安装。

要安装 gem5 pre-commit 检查，请在 gem5 目录下执行以下操作：

```sh
pip install pre-commit
pre-commit install
```

一旦安装，pre-commit 将在运行 `git commit` 命令之前对修改的代码运行检查（有关提交更改的更多详细信息，请参阅 [关于提交的部分](#committing)）。如果这些测试失败，你将无法提交。

这些相同的 pre-commit 检查也作为我们要 CI 检查的一部分运行（必须通过这些检查才能将更改合并到 develop 分支）。因此，强烈建议开发人员安装 pre-commit 以尽早发现风格错误。

## 编译和运行测试

提交更改的最低标准是代码可编译且测试用例通过。

以下命令既编译项目又运行我们的“快速”系统级检查：

```sh
cd tests
./main.py run
```

**注意：这些测试可能需要几个小时才能构建和执行。`main.py` 可以使用 `-j` 标志在多个线程上运行。例如：`python main.py run -j6`。**

单元测试也应该通过。运行单元测试：

```sh
scons build/ALL/unittests.opt
```

编译单个 gem5 二进制文件：

```sh
scons build/ALL/gem5.opt
```

这将编译一个包含“ALL” ISA 目标的 gem5 二进制文件。有关构建 gem5 的更多信息，请查阅我们的 [构建文档](/documentation/general_docs/building)。

## 提交 (Committing)

当你觉得你的更改已完成时，你可以提交。首先添加更改的文件 `git add <changed files>`。确保将这些更改添加到你的 fork 仓库中。然后使用 `git commit` 提交。

**提交信息必须遵守我们的风格。**

- **标题格式：** 以一个标签（或多个标签，用逗号分隔）开头，然后是一个冒号。请参阅 [MAINTAINERS.yaml](https://github.com/gem5/gem5/blob/stable/MAINTAINERS.yaml) 获取已接受标签的列表。使用哪些标签取决于你修改了 gem5 的哪些组件。冒号后面必须提供提交的简短描述。**标题行不得超过 65 个字符。**

- **详细描述（可选）：** 添加在标题下方，由空行分隔。包含描述是可选的，但强烈建议这样做。描述可以跨越多行和多段。**每行不应超过 72 个字符。**

为了提高 gem5 项目的可导航性，如果提交信息包含指向相关 GitHub Issue 的链接，我们将不胜感激。下面是 gem5 提交信息应如何格式化的示例：

```
test,base: This commit tests some classes in the base component

This is a more detailed description of the commit. This can be as long
as is necessary to adequately describe the change.

A description may spawn multiple paragraphs if desired.

GitHub Issue: https://github.com/gem5/gem5/issues/123
```

如果你觉得需要更改提交，请添加必要的文件，然后使用 `git commit --amend` _修正_ 提交的更改。这将让你有机会编辑提交信息。

你可以继续添加更多提交作为提交链包含在 Pull Request 中。
但是，我们建议保持 Pull Request 小而专注。
例如，如果你希望添加不同的功能或修复不同的错误，我们建议在另一个 Pull Request 中进行。

## 保持你的 fork 和本地仓库更新

在进行贡献时，我们建议保持你的 fork 仓库与源 gem5 仓库同步。
为此，请定期 [同步你的 fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork)。
这可以通过 GitHub Web 界面完成，如果是这样，你应该在本地 `stable` 和 `develop` 分支之上执行 `git pull`，以确保你的本地仓库是同步的。
从命令行执行此操作：

```sh
# 将主 gem5 仓库添加为你本地仓库的远程仓库。这只需要做一次。
git remote add upstream https://github.com/gem5/gem5.git

git fetch upstream # 从 gem5 仓库获取最新内容。
git switch develop # 切换到 develop 分支。
git merge upstream/develop # 将最新更改合并到 develop 分支。
git push # 推送 develop 到你的 fork 仓库。
git switch stable # 切换到 stable 分支。
git merge upstream/stable # 将最新更改合并到 stable 分支。
git push # 将 stable 的更改推送到你的 fork 仓库。
```

由于我们的本地分支在 `develop` 分支之上工作，一旦我们同步了 fork 仓库，我们就可以将本地分支变基 (rebase) 到 `develop` 分支之上。
假设我们的本地分支名为 `new-feature`：

```sh
git switch develop # 切换回 develop 分支。
git pull # 确保我们拥有来自 fork 仓库的最新内容。
git switch new-feature # 切换回我们的本地分支。
git rebase develop # 将我们的本地分支变基到 develop 分支之上。
```

可能需要解决你的分支与新更改之间的冲突。

## 推送并创建 Pull Request

在本地完成更改后，你可以推送到你的 fork gem5 仓库。
假设我们正在工作的分支是 `new-feature`：

```sh
git switch new-feature # 确保我们在 'new-feature' 分支上。
git push --set-upstream origin new-feature
```

如果这是你第一次推送到你的 fork gem5 仓库，你可能会遇到一个错误，指出 GitHub 在验证 Git 操作时不再接受帐户密码。要解决此问题，请在 [github-tokens](https://github.com/settings/tokens) 生成个人访问令牌，然后按照 [这些步骤](https://docs.github.com/en/get-started/getting-started-with-git/managing-remote-repositories#switching-remote-urls-from-https-to-ssh) 将远程 URL 切换到 SSH。

现在，通过 GitHub Web 界面，你可以 [创建一个 Pull Request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)，将你的更改从你的 fork 仓库的分支合并到 gem5 `develop` 分支。

## 通过检查

创建 Pull Request 后，gem5 持续集成 (CI) 测试将运行。
这些测试运行一系列检查以确保你的更改有效。
这些必须通过才能将你的更改合并到 gem5 `develop` 分支。

除了 CI 测试之外，你的更改还将由 gem5 社区进行审查。
你的 Pull Request 必须在合并之前获得至少一名社区成员的批准。

一旦你的 Pull Request 通过了所有 CI 测试并获得至少一名社区成员的批准，gem5 维护者将在 Pull Request 上执行 [Merge](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/about-pull-request-merges)。
gem5 维护者是被授予将 Pull Request 合并到 gem5 `develop` 分支能力的个人。

### 根据反馈进行迭代改进

审查者将在 GitHub 上提出问题并发布建议。你应该仔细阅读这些评论并回答任何问题。
**审查者和贡献者之间的所有沟通都应保持礼貌，不会容忍粗鲁或轻视的言论。**

当你了解需要进行哪些更改时，请通过向同一分支添加补丁然后推送到 fork 仓库来修改 Pull Request。
如果你希望在本地更改提交以实施更改，Git ‘force push’ (即 `git push --force`) 也是可以接受的。
我们鼓励贡献者帮助保持我们的 `git log` 干净易读。
我们建议用户经常将他们的更改变基到 develop 分支之上，
在适当的情况下压缩他们的提交（例如，在同一个 PR 中对更改进行了许多小的修复提交的情况下），
然后强制推送更改以保持其 PR 提交简洁。

推送到 fork 仓库后，Pull Request 将自动更新你的更改。
然后审查者将重新审查你的更改，并在必要时要求进一步更改，或批准你的 Pull Request。

## 审查其他贡献

我们鼓励所有 gem5 开发人员审查其他人的贡献。
任何人都可以审查 gem5 更改，如果他们觉得准备好了，就可以批准它。
所有 Pull Request 都可以在 <https://github.com/gem5/gem5/pulls> 找到。

在审查 Pull Request 时，我们将执行以下准则。
这些准则旨在确保各方之间清晰礼貌的沟通：

* 在所有形式的交流中，贡献者和审查者必须保持礼貌。
被视为粗鲁或轻视的评论将不被容忍。
* 如果你选择不批准 PR，请清楚说明原因。
要求更改时，评论应具体且可操作。
贡献者无法解决或理解的一般性批评是无益的。
如果贡献需要改进，审查者应清楚列出要求的更改。
如果审查者需要更多信息才能做出决定，他们应该提出明确的问题。
如果 PR 通常不被认为是有价值的贡献，应提供充分的理由，以便贡献者可以公平地回应。
* 默认情况下，假定原始贡献者拥有更改。
即，假定他们是向 Pull Request 提交补丁的唯一方。
如果原始贡献者以外的其他人希望代表原始贡献者提交补丁，他们应先征得许可。
看似被遗弃的 Pull Request 可以被新贡献者接管，只要有充分的理由假设原始贡献者不再处理该 Pull Request。
* 维护者对是否合并更改拥有最终决定权。
维护者会考虑你的审查。
除了最极端的情况外，预计在维护者合并 Pull Request 之前，必须解决审查者的疑虑并获得审查者对贡献的批准。

我们也建议查阅 Google 的 ["How to write code review comments"](https://google.github.io/eng-practices/review/reviewer/comments.html) 以获取有关向贡献者提供反馈的建议。

## 发布 (Releases)

gem5 每年发布 3 次。gem5 的发布流程如下：

1. 开发人员将通过 gem5-dev 邮件列表收到通知，gem5 将发布新版本。这应不早于创建 staging 分支（发布 gem5 新版本的第一步）前 2 周。这让开发人员有时间确保他们为下一个版本所做的更改已提交到 develop 分支。
2. 当发布准备就绪时，项目维护者将从 develop 创建一个新的 staging 分支，名称为 "release-staging-{VERSION}"。gem5-dev 邮件列表将收到通知，staging 分支将在两周后合并到 stable 分支，从而标志着新版本的发布。
3. staging 分支将对其运行全套 gem5 测试，以确保所有测试通过且即将发布的版本处于良好状态。
4. 如果用户向 staging 分支提交 Pull Request，它将被考虑并经过标准的 github 审查流程。但是，只有不能等到下一个版本发布的更改才会被接受提交到该分支（即，提交到 staging 分支以“最后时刻”包含在发布中的更改应具有高优先级，例如关键错误修复）。项目维护者将自行决定是否可以将更改直接提交到 staging 分支。所有其他对 gem5 的提交将继续提交到 develop 分支。提交到 staging 分支的补丁不需要重新添加到 develop 分支。
5. 一旦 staging 分支被认为已准备好发布，将执行 [发布流程](https://www.gem5.org/documentation/general_docs/development/release_procedures/)。
这将以 staging 分支合并到 stable 分支结束。
6. stable 分支将标记该版本的正确版本号。gem5 符合 "v{YY}.{MAJOR}.{MINOR}.{HOTFIX}" 版本控制系统。
例如，2022 年的第一个主要版本将是 "v22.0.0.0"，紧随其后的是 "v22.1.0.0"。所有版本（热修复除外）都被视为主要版本。目前，没有次要版本，尽管我们保留次要版本号以防将来此政策发生变化。
7. gem5-dev 和 gem5-user 邮件列表将收到有关新 gem5 发布的通知。

### 豁免

由于 GitHub 的限制，我们可能会在 gem5 发布之间更新 gem5 仓库 `stable` 分支中的 ".github" 目录。
这是由于 GitHub Actions 基础设施执行的某些过程依赖于仓库主分支上存在的配置。
由于 ".github" 中的文件仅影响我们的 GitHub actions 和其他 GitHub 活动的功能，因此更新这些文件不会以任何方式改变 gem5 的功能。
因此这样做是安全的。
尽管有此例外的常规程序，我们的目标是确保 **`stable` 分支上的 ".github" 目录永远不会“领先”于 `develop` 分支中的目录**。
因此，希望更新 ".github" 中文件的贡献者应将其更改提交到 `develop`，然后请求将其更改应用于 `stable` 分支。


### 热修复 (Hotfixes)

在某些情况下，gem5 的更改被认为是关键的，无法等待正式发布（例如，高优先级的错误修复）。在这些情况下，将进行热修复。

首先，如果开发人员怀疑可能需要热修复，则应在 gem5-dev 邮件列表上讨论该问题。社区将决定该问题是否值得热修复，如果没有达成共识，最终决定应由 PMC 成员做出。假设允许热修复，将采取以下步骤：

1. 将从 stable 分支创建一个带有前缀 "hotfix-" 的新分支。只有 gem5 维护者才能创建分支。如果非维护者需要创建热修复分支，他们应联系 gem5 维护者。
2. 更改应通过 github 提交到 hotfix 分支。与任何其他更改一样，将需要全面审查。
3. 一旦完全提交，hotfix 分支将由 gem5 维护者合并到 develop 和 stable 分支。
4. stable 分支将标记新版本号；与上一个版本相同，但热修复编号增加（例如，"v20.2.0.0" 将变为 "v20.2.0.1"）。
4. 然后将删除 hotfix 分支。
5. gem5-dev 和 gem5-user 邮件列表将收到有关此热修复的通知。
