---
layout: documentation
title: 设置您的开发环境
doc: Learning gem5
parent: part2
permalink: /documentation/learning_gem5/part2/environment/
author: Jason Lowe-Power
---


设置您的开发环境
=======================================

这里将讨论如何开始开发 gem5。

gem5 风格指南
---------------------

修改任何开源项目时，遵循项目的风格指南都很重要。有关 gem5 风格的详细信息，请参阅 gem5 [代码风格页面](http://www.gem5.org/documentation/general_docs/development/coding_style/)。

为了帮助您遵守风格指南，gem5 包含一个脚本，每当您在 git 中提交变更集时都会运行该脚本。您第一次构建 gem5 时，SCons 会自动将此脚本添加到您的 .git/config 文件中。请不要忽略这些警告/错误。但是，在极少数情况下，当您尝试提交不符合 gem5 风格指南的文件（例如，来自 gem5 源代码树之外的内容）时，您可以使用 git 选项 `--no-verify` 跳过运行风格检查器。

风格指南的要点是：

-   使用 4 个空格，而不是制表符 (tab)
-   对 include 进行排序
-   类名使用大驼峰命名法 (CapitalizedCamelCase)，成员变量和函数使用小驼峰命名法 (camelCase)，局部变量使用蛇形命名法 (snake_case)。
-   记录您的代码

git 分支
------------

大多数使用 gem5 进行开发的人使用 git 的分支功能来跟踪他们的更改。这使得将您的更改提交回 gem5 变得非常简单。此外，使用分支可以更轻松地使用其他人所做的新更改更新 gem5，同时保持您自己的更改独立。[Git book](https://git-scm.com/book/en/v2) 有一章很棒的 [章节](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell) 描述了如何使用分支的详细信息。
