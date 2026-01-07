---
layout: bootcamp
title: 为 gem5 做贡献
permalink: /bootcamp/contributing/contributing
section: contributing
author: Bobby R. Bruce
---
<!-- _class: title -->

## 为 gem5 做贡献

---

## 简介

gem5 模拟器是一个开源、协作的项目。

任何愿意提交贡献的人都可以这样做，他们的贡献将被评估，如果合适就会被采纳。

可以是新功能、错误修复，甚至是文档更新。无论大小，都可以涵盖整个 gem5 项目。

---

## 我们的策略

![50% bg](/bootcamp/06-Contributing/01-contributing-img/our-strategy.svg)

---

## 我为什么要贡献？

- **你友善且具有社区意识**：
  - 你发现了一个错误并有了修复方案。
  - 你开发了一些真正有用的东西并想分享它。
  - 这是你"回馈"免费获得的东西的方式。
- **为你的研究做宣传**：
  - 许多研究人员使用 gem5。将你的工作纳入 gem5 主线代码库是宣传你的研究并使其更容易复制和使用的好方法。
**注意：** gem5 开发者只会接受高质量、经过充分测试且具有通用性的代码，因此这可能不适用于所有情况。
  - 老实说，你越愿意帮助我们，我们就越愿意帮助你在 gem5 方面的工作。gem5 是一个社区，所有社区都基于给予和接受。

---

- **对雇主来说看起来不错**：
  - 对开源项目的贡献是积累开发经验的好方法。
由于 gem5 是开源的，这些贡献是公开的，因此是向潜在雇主证明你技能的好方法。

---

## "我害怕贡献"

这是可以理解的。

但是，请记住以下几点：

1.  _每个人_，即使是最有经验的 gem5 开发者，都曾有过他们的更改被拒绝的经历。
gem5 GitHub 上总是会存在一个拉取请求，所以更改永远不会"消失"。
拒绝的原因不是个人原因，而通常是关于它如何影响用户或长期可维护性的担忧。
如果一个更改需要大量时间来实现，请尝试联系社区，看看在开始之前是否会受到欢迎。
2. gem5 开发者是友善的人，并不是想刻薄。
我们必须对贡献的代码进行批评，但我们会尽力确保这是建设性的。在可能的情况下，我们会建议如何解决我们的担忧。
再次强调，这不是个人原因。

---

3. 很少有任何规模的更改在没有一些来回请求的情况下被接受。
每个在 gem5 上工作足够长时间的人都有需要 5 或 6 次迭代才能被接受的更改。这不应该被害怕或被视为坏事。
4. 没有人完全理解 gem5 代码库。
gem5 的某些部分没有人理解。感觉你不完全理解代码库是可以的，但这不应该成为你不为你能理解的部分做贡献的理由。

---

## 我可以贡献什么？

当然，请贡献你认为可能对社区有用的更改。
错误修复显然很受欢迎，但新功能、对现有功能的改进和文档更新也是如此。

如果你只是想尝试贡献，但没有具体的想法，可以查看我们的 GitHub Issues 页面：<https://github.com/gem5/gem5/issues>。

---

## 我不能贡献什么？

1. _任何会给社区维护带来负担的东西_：如果你开发了一些复杂的东西，被认为需要随着 gem5 的变化而进行重大更新，它不太可能被接受。
避免或修复更改以解决这个问题的大部分内容涉及测试。
2. _我们无法验证正确性的东西，现在或将来_：如果你开发了一些难以测试的东西，或者我们无法轻易验证它是正确的，它不太可能被接受。我们不能仅仅阅读代码就总是理解它是功能性的。**为避免这种情况，请在你的更改中提供测试**（稍后会详细介绍）。
3. _过于小众且缺乏对典型 gem5 用户通用适用性的功能_：如果这是只有你和一两个人会使用的东西，它不太可能被接受。在这些情况下，最好维护一个包含你更改的 gem5 分支。
4. _它不符合我们的标准_：（通常是风格指南）代码很好，它可以工作，但你需要进行一些更改以使其符合我们的风格指南。这是更改被拒绝的常见原因，但也是最容易修复的原因之一。

---

## 让我们开始：Fork 仓库

我们使用 GitHub 拉取请求（PR）系统通过分叉仓库进行贡献。

分叉仓库是你拥有的仓库副本，可以对其进行更改而不影响原始仓库。

当你在分叉仓库中完成更改的实现后，你可以提交 PR 以请求将分叉仓库中的更改合并到原始仓库中。

---

## 让我们开始：Fork 仓库

你可以访问 gem5 GitHub 页面并点击"Fork"按钮来创建 gem5 仓库的分叉。

![right:40%](/bootcamp/06-Contributing/01-contributing-img/gem5-fork.png)

**取消选中"仅复制稳定分支"**。我们不使用稳定分支进行开发，因此你需要分叉 `develop` 分支。

你可以在本地克隆它：

```shell
git clone https://github.com/your-username/gem5.git
```

---

## 你的分叉仓库：一些提示和良好的维护

- 在 gem5 中，不要对你的仓库的 `stable` 和 `develop` 分支进行更改。
最好将这些分支保留为对主 gem5 仓库的引用。
相反，从这些分支创建新分支：

```shell
git switch develop # 第一次运行时在本地获取分支
git branch -c develop new-branch.
```

然后移动到这些分支开始进行更改：

```shell
git switch new-branch
```

**注意**：将你的新分支命名为描述你正在进行的更改的名称。

---

## 你的分叉仓库：一些提示和良好的维护

- 永远不要在 `stable` 分支上进行更改，在 `develop` 分支上进行更改。
在 gem5 中，开发者的更改只会合并到 `develop` 分支。`develop` 分支会定期合并到 `stable` 分支以创建新的 gem5 版本。
- 保持你的分叉仓库的 `stable` 和 `develop` 分支与主 gem5 仓库同步。

---

## 保持你的仓库更新

有多种方法可以做到这一点。

1. 通过 Web 界面：访问你在 GitHub 上的分叉仓库，转到 `stable` 或 `develop` 分支，然后点击"Fetch upstream"按钮"sync fork"（注意：你必须为每个分支执行此操作）。然后使用 `git pull origin stable` 和/或 `git pull origin develop` 将更改拉取到你的本地仓库。
2. 使用 GitHub CLI：`gh repo sync {username}/gem5 -b develop && gh repo sync {username}/gem5 -b stable` 将同步你的分叉仓库（在 GitHub 上）与主 gem5 仓库。
然后你可以使用 `git switch stable && git pull && git switch develop && git pull` 将更改拉取到你的本地仓库。

> **注意**：我们不会在本教程中介绍这一点。参见 (https://cli.github.com/)

3. 通过本地仓库中的 git 工具，通过获取（主 gem5 仓库）并将上游合并到你的本地仓库。

---

## 同步你的本地仓库

```shell
git remote -v
```
通常你会有一个 `origin`，这是你从中拉取的 GitHub 仓库。
GitHub 还会为分叉仓库添加一个名为 `upstream` 的远程，这是主 gem5 仓库。
我们将遵循此命名约定，但请注意这些"远程"可以命名为任何名称。

如果你需要添加上游，可以使用

```shell
git remote add upstream https://github.com/gem5/gem5.git
```

然后你可以从主 gem5 仓库获取更改：

```bash
git fetch upstream
git switch develop
git merge upstream/develop
```

---

## 更多同步你的本地仓库

然后你可以将此更新推送到你在 GitHub 上的仓库：

```shell
git switch stable
git push origin stable
git switch develop
git push origin develop
```

**请注意：** 要推送到你的 GitHub，你需要在使用的系统上验证自己的身份。
有几种方法可以做到这一点，可能取决于你如何设置 GitHub 账户。我们不会在这里介绍这一点，但你可以在以下位置了解更多信息：<https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github>。在本教程中推送并不重要。你可以自己解决这个问题。

> [更多信息请访问 GitHub 帮助页面](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork)

---

<!-- _class: start -->

## 进行更改和提交

---

## 进行更改并提交它们（基本流程）

让我们暂时忽略风格指南等，专注于进行更改和提交它们的基本流程。

1. 从 `develop` 创建一个分支并在那里进行更改。

```shell
git switch develop
git switch -c my-change
```

---

## 进行更改并提交它们（基本流程）

2. 进行你的更改。如果这是一个大的更改，请将其分解为多个提交。

```shell
echo "Hello, world" > hello.txt
git add hello.txt
git commit -m "misc: Adding hello.txt"

echo "Goodbye, world" >> hello.txt
git add hello.txt
git commit -m "misc: Adding goodbye to hello.txt"
```

请暂时在你的提交消息中包含 `misc:`。
稍后会解释这一点。

---

## 进行更改并提交它们（基本流程）

3. 将你的更改推送到你在 GitHub 上的分叉仓库。
第一次你可能需要设置上游分支：

```shell
git push --set-upstream origin my-change
```

这样做是为了通知你的 git 仓库，这个本地分支将被推送到"origin"远程（你的 GitHub 仓库），并且它应该跟踪远程分支。这就是 `--set-upstream` 的作用。

**注意**：不幸的是，"upstream"在这里用于两种不同的上下文。在这种情况下，upstream 是你的基于 GitHub 的仓库：它是你的本地仓库的直接"上游"。但是 `git remote -v` 中的 upstream 是主 gem5 仓库。在这种情况下，它是 origin 的"上游"。
有一个上游链：你的本地仓库向上游贡献到你的 GitHub 仓库，通过拉取请求，向上游贡献到主 gem5 仓库。

---

## 进行更改并提交它们（基本流程）

4. 创建一个拉取请求。在你的 gem5 分叉的 GitHub 仓库中查找贡献按钮。

![30% bg](/bootcamp/06-Contributing/01-contributing-img/create-pr.png)

---

## 进行更改并提交它们（基本流程）

![70% bg](/bootcamp/06-Contributing/01-contributing-img/pr-create-screen.png)

**注意**：默认情况下，PR 将尝试创建一个请求以合并到 gem5 `stable` 分支。
请确保你选择 `develop` 分支。

---

## PR 审查过程和进行更新

一旦你提交了 PR，gem5 开发者将对其进行审查。
你可以在 <https://github.com/gem5/gem5/pulls> 查看当前正在审查的 PR。

在 PR 合并到 `develop` 分支之前，必须发生两件事：

1. PR 必须通过持续集成（CI）测试。
这些在你提交 PR 时由 GitHub 自动运行。
2. 审查者必须批准 PR。

当这两个条件都满足时，gem5 维护者团队的成员将把 PR 合并到 `develop` 分支。因此，gem5 维护者对是否合并 PR 有最终决定权。

如果 CI 测试失败或审查者在批准前请求更改，你需要对 PR 进行更新。

---

## 更新 PR

在 Github 中，你需要做的就是更新你在 Github 上提交 PR 的分支。
（即，来自你分叉仓库的分支）。

### 添加提交

如果你需要向 PR 添加提交，你可以在本地执行此操作并将其推送到你在 GitHub 上的分叉仓库。

```shell
# 进行你的更改 ()
echo "bla" >> hello.txt

# 添加它们并提交它们
git add hello.txt
git commit -m "misc: Adding bla to hello.txt"

# 将它们推送到你的 PR 所在的分支。
git push origin my-change
```

---

## 当 gem5 更新时进行变基

你可以_变基_你的分支以对其中的现有提交进行更改。
如果你需要更改提交消息或更改提交的顺序、更改提交的内容、合并提交或删除提交，这很有用。

它非常强大，但如果你不确定自己在做什么，可能会很危险。

```shell
# 变基最后 3 个提交（3 是一个示例，你可以更改此数字）
git rebase -i HEAD~3
```

这将返回一个交互式显示，如下所示：

```shell
pick i7j8k9l misc: Adding hello.txt
pick e4f5g6h misc: Adding goodbye to hello.txt
pick a1b2c3d misc: Adding bla to hello.txt
```

---

## 变基

使用这个你可以重新排序提交：

```shell
pick i7j8k9l misc: Adding hello.txt
pick a1b2c3d misc: Adding bla to hello.txt
pick e4f5g6h misc: Adding goodbye to hello.txt
```

删除提交：

```shell
pick i7j8k9l misc: Adding hello.txt
pick a1b2c3d misc: Adding bla to hello.txt
```

标记要重新措辞的提交消息：

```shell
pick i7j8k9l misc: Adding hello.txt
reword a1b2c3d misc: Adding bla to hello.txt
```

---

## 变基

标记要编辑的提交（这允许以与进行提交时相同的方式更改提交）：

```shell
edit i7j8k9l misc: Adding hello.txt
reword a1b2c3d misc: Adding bla to hello.txt
```

或压缩提交：

```shell
pick i7j8k9l misc: Adding hello.txt
fixup a1b2c3d misc: Adding bla to hello.txt
```

**警告**：可能会出现变基错误（类似于合并冲突），可能难以修复。
如果你不确定自己在做什么，最好避免变基，只添加提交。
但是，通常使用 `fixup` 和 `squash` 是安全的，`reword` 也是如此。
在移动、删除或编辑提交时会出现困难。

---

## gem5 项目的贡献要求

以下是 PR 被接受的基本要求：

- 它符合 gem5 Python 风格指南。
- 它符合 gem5 C++ 风格指南。
- 提交消息必须采用正确的格式并包含标签。
- 提交消息包含 Change-Id。

---

## 使用 `pre-commit`

幸运的是，有一个工具可以帮助解决_大部分_这个问题：Python `pre-commit`。
`pre-commit` 是一个在你提交代码之前对你的代码运行一系列检查的工具。
它检查代码风格和格式问题，并在你的本地仓库中运行一些其他基本检查，让你在提交 PR 之前发现问题。


对于以下情况，`pre-commit` 将检测并自动纠正任何问题：

- gem5 Python 代码风格错误。
- 缺少提交 ID。

Pre-commit 会警告（但不纠正）：

- 提交消息采用正确的格式并包含标签。


对于 CPP 格式化的情况，`pre-commit` 运行一些有限的检查，但这些并不全面。
目前 CPP 格式化是一个手动过程。

---

## 安装 pre-commit

`pre-commit` 在运行 `git commit` 时触发一系列检查。它是一个在提交之前执行的 git 钩子。

要安装 `pre-commit`，请执行以下操作：

```shell
./util/pre-commit-install.sh
```

---

## 运行 pre-commit

尝试执行以下操作，看看它是如何工作的。

1. 在 Python 文件的行尾添加一些随机空白。`git add <file> && git commit -m "misc: Adding white space"`。
`pre-commit` 将失败并删除空白，建议你再次添加文件并提交。
2. 添加一个随机提交 `echo "hello" >>hello.txt && git add hello.txt && git commit -m "misc: hello"`。
使用 `git log` 观察 `Change-Id` 添加到提交消息中。
3. 添加一个没有 `misc:` 的提交，看看 `pre-commit` 失败：`echo "hello" >>hello.txt && git add hello.txt && git commit -m "hello"`。

---

## 格式化提交消息

提交消息应采用以下格式，以避免 `pre-commit` 和我们的 CI 系统抱怨：

```txt
test,base: A header no greater than 65 chars inc. tags

A description of the change. This is not necessary but recommended.
Though not enforced we advise line lengths <= 72 chars.

Each header should be a comma separated list of tags followed by ':'
A short description of the change. The valid tags are found in the
"MAINTAINERS.yaml" file in the gem5 repo. Typically one tag is enough.

Issue: https://github.com/gem5/gem5/issues/123
```

---

## 格式化提交消息

如果需要，描述可以跨越多个段落。在末尾添加有关更改的元数据可能很有用。特别是，指向它解决的问题的链接很有帮助。

**重要**：

1. 包含标签！至少一个。
2. 标签必须来自"MAINTAINERS.yaml"文件。
3. 标题不应超过 65 个字符。

**推荐**（但不强制执行）：

1. 更改的描述。
2. 描述行长度 <= 72 个字符。
3. 指向更改解决的问题的链接。

---

## gem5 的代码风格指南

对于 Python，我们简单地推荐 `pre-commit` 建议的任何内容并将你的代码格式化为它。
它使用 Black 格式化程序，这是一个广泛使用的 Python 格式化程序。

对于 CPP，只有部分风格指南由 `pre-commit` 强制执行。
完整的风格指南可以在这里找到：<https://www.gem5.org/documentation/general_docs/development/coding_style>

尽管风格指南很正式，但我们建议**遵循你正在处理的代码的风格**。

---

## 高级 CPP 风格指南要点

**行、缩进和大括号**：

- 行不得超过 79 个字符。
- 缩进是 4 个空格。
- 使用空格，不要使用制表符。
- 控制块（即 `if`、`while`、`for` 等）的主体必须缩进。
- 控制块主体必须用大括号括起来，单行语句除外。
- 控制块开始括号必须与控制块在同一行，结束括号在自己的行上。
- 函数返回类型应该在自己的行上。
- 函数或类的开始和大括号应该在自己的行上
- `else` 和 `if else` 必须在前一个块的结束大括号的同一行上。
- 访问说明符（类中的 `public`、`private`）应该在自己的行上并缩进 2 个空格。

---

## 代码风格示例

```cpp
class ExampleClass
{
  public:
    int exampleVar = 0;

    int
    exampleFunc(bool condition, bool another_condition)
    {
        if (condition) {
           this->exampleVar = 5;
        } else {
           if (another_condition) this->exampleVar;
        }
    }
};
```

---

## 间距

- 关键字（if、for、while 等）和开始括号之间有一个空格
- 二元运算符（+、-、<、> 等）周围有一个空格，包括赋值运算符（=、+= 等）
- 在参数/参数列表中使用 '=' 时周围没有空格，无论是绑定默认参数值（在 Python 或 C++ 中）还是绑定关键字参数（在 Python 中）
- 函数名称和参数开始括号之间没有空格
- 括号内没有空格，除非是非常复杂的表达式。复杂表达式优先使用临时变量分解为多个更简单的表达式。

---

## 命名

- 类和类型名称是 CamelCase，以大写字母开头（例如，`MyClass`）。
- 类成员变量是 camelCase，以小写字母开头（例如 `classVar`）。
- 旨在通过访问器函数访问的类成员变量前面加下划线。（`_accessorVar`）。
- 访问器函数以访问器变量命名，不带下划线（例如，`accessorVar()`）。
- 函数名称是 camelCase，以小写字母开头（例如，`myFunction()`）。
- 局部变量是小写蛇形命名（例如，`local_var`）。
这包括函数参数（例如，`myFunction(int arg_one, int arg_two)`）。

---

## 另一个代码示例

```cpp
class FooBarCPU
{
  private:
    static const int minLegalFoo = 100;
    int _fooVariable;
    int barVariable;

  public:
    int fooVariable() const { return _fooVariable; }

    void
    fooVariable(int new_value)
    {
        _fooVariable = new_value;
    }
};
```

---

<!-- _class: code-60-percent -->

## Include 块

对于 `include` 语句，我们将它们分成块，每个块用空行分隔。每个块按字母顺序排序。

```cpp
// 如果需要，首先包含 Python.h。
#include <Python.h>

// 在任何其他非 Python 头文件之前包含你的主头文件
#include "main_header.hh"

// 按排序顺序的 C 包含
#include <fcntl.h>
#include <sys/time.h>

// C++ 包含
#include <cerrno>
#include <string>

// 位于 include/ 中的共享头文件。
// 这些在模拟器和实用程序（如 m5 工具）中都使用。
#include <gem5/asm/generic/m5ops.h>

// M5 包含
#include "base/misc.hh"
#include "cpu/base.hh"
#include "params/BaseCPU.hh"
#include "sim/system.hh"
```
---

## 恭喜！

你现在知道了为 gem5 做贡献所需了解的一切。
