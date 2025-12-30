---
layout: documentation
title: 将活动更改从 Gerrit 迁移到 GitHub
doc: gem5 documentation
parent: moving_to_github
permalink: /documentation/general_docs/moving_to_github/
---

# 将活动更改从 Gerrit 迁移到 GitHub

当我们过渡到使用 GitHub 托管 gem5 项目时，我们需要一种方法将任何活动更改从 Gerrit 迁移到 GitHub 进行审查。如果您的更改在 Gerrit 变为只读之前无法准备好合并，请按照以下步骤在 GitHub 上创建一个包含您更改的拉取请求以供审查。

* 访问 https://github.com/gem5/gem5 并创建 gem5 仓库的分支，确保取消选中"仅复制 stable 分支"框
* 创建此分支后，克隆您分叉的仓库，然后运行 `git checkout --track origin/develop`，以便您的更改位于 develop 分支之上
* 现在您的分叉仓库已设置好，导航到 https://gem5-review.googlesource.com/q/status:open+-is:wip 并找到您的更改
* 打开您的更改后，单击屏幕右侧的"Download"按钮，并复制用于 cherry-pick 您的更改的命令
* 将您的更改 cherry-pick 到您的分叉仓库，并处理可能出现的任何合并冲突。如果这些更改是关系更改的一部分，请确保 cherry-pick 其每个部分。
* 所有更改都 cherry-pick 完成后，运行 `git push origin` 以更新您的分叉仓库
* 现在所有更改都已上传，您可以创建拉取请求。为此，在 https://github.com 上打开您的仓库，然后单击页面中间的 Contribute 按钮。执行此操作时，请确保您在 develop 分支上。单击 Contribute 后，应该会出现一个显示"Open pull request"的按钮。
* 这将导航到创建拉取请求的页面。对于基础仓库，应该是 gem5/gem5，分支应该是 develop。对 stable 分支的任何拉取请求都将被忽略。头部仓库将是您的分叉仓库，分支也应该是 develop。在拉取请求的正文中，您可以包含来自 Gerrit 的更改链接，以便可以轻松访问任何评论。此外，在页面的右侧，您可以添加审查者，因此您可以请求任何在 Gerrit 上查看过您更改的人来审查您的拉取请求
* 当您对拉取请求满意时，可以单击页面底部的"Create pull request"按钮。

如果您是 gem5 GitHub 仓库的首次贡献者，您需要在运行任何持续集成测试之前获得拉取请求的正面审查。为了让您的更改被合并，您需要正面审查以及这些测试通过。最后，gem5 维护者将在所有先前的检查通过后压缩并合并您的更改。
