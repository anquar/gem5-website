---
layout: page
title: 报告问题
parent: documentation
permalink: documentation/reporting_problems/
author: Bobby R. Bruce
---

[gem5 社区](/ask-a-question)中的许多人都乐于在有人遇到问题或某些功能无法正常工作时提供帮助。但是，请注意，从事 gem5 工作的人员还有其他承诺，因此我们希望在报告之前，用户能够努力解决自己的问题，或者至少收集足够的信息来帮助他人解决该问题。

下面我们概述一些关于问题报告的一般建议。

## 报告问题之前

在报告问题之前，最重要的事情是尽可能多地调查该问题。这可能会引导您找到解决方案，或者使您能够向 gem5 社区提供有关该问题的更多信息。以下是我们建议您在报告问题之前执行的一系列步骤/检查：

1. 请检查是否已在[我们的任何渠道](/ask-a-question)上提出过类似问题（也请检查存档）。

2. 确保您正在编译和运行最新版本的 [gem5](https://github.com/gem5/gem5)。该问题可能已经得到解决。

3. 检查[我们 GitHub 系统上正在审查的更改](https://github.com/gem5/gem5/pulls/)。可能已经有一个针对您问题的修复正在合并到项目中。

4. 确保您使用 `gem5.opt` 或 `gem5.debug` 运行，而不是 `gem5.fast`。`gem5.fast` 二进制文件为了速度而编译掉了断言检查，因此在 `gem5.fast` 上导致崩溃或错误的问题可能会在使用 `gem5.opt` 或 `gem5.debug` 时产生更有信息的断言失败。

5. 如果合适，请启用一些调试标志（例如，通过 CLI 使用 `--debug-flags=Foo`）。有关调试标志的更多信息，请查阅我们的[调试教程](/documentation/learning_gem5/part2/debugging)。

6. 如果您的问题发生在 C++ 端，请不要害怕使用 GDB 进行调试。

# 报告问题

一旦您认为已经收集了足够关于您问题的信息，就可以报告它了。

* 如果您有理由相信您的问题是一个 bug，请在 gem5 的 [GitHub issues](https://github.com/gem5/gem5/issues) 上报告该问题。
**请包含任何可能有助于他人在其系统上重现此 bug 的信息**。包括使用的命令行参数、任何相关的系统信息（至少包括您使用什么操作系统，以及您是如何编译 gem5 的？）、收到的错误消息、程序输出、堆栈跟踪等。

* 如果您选择在 [gem5 Discussions 页面](https://github.com/orgs/gem5/discussions)上提问，请提供任何可能有帮助的信息。如果您对问题可能是什么有理论，请告诉我们，但请包含足够的基本信息，以便其他人可以判断您的理论是否正确。


# 解决问题

如果您已经解决了您报告的问题，请通过您的 GitHub issue 或讨论的后续回复让社区了解您的解决方案。如果您修复了一个 bug，我们希望您能够将修复提交到 gem5 源代码。请参阅我们的[贡献者入门指南](/contributing)了解如何执行此操作。

如果您的问题是关于 gem5 文档/教程内容不正确，请考虑提交更改。有关如何为 gem5 网站做出贡献的更多信息，请查阅我们的 [README](https://github.com/gem5/website/blob/stable/README.md)。
