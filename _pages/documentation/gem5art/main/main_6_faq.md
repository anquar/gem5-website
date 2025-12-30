---
layout: documentation
title: 常见问题
doc: gem5art
parent: main
permalink: /documentation/gem5art/main/faq
---

# 常见问题

**什么是 gem5art？**

gem5art（用于组件、可重现性和测试的库）是一组 Python 模块，用于以可重现和结构化的方式使用 gem5 进行实验。

**我需要 celery 来使用 gem5art 运行 gem5 作业吗？**

使用 gem5art 运行 gem5 作业不需要 Celery。
您可以使用任何其他作业调度工具，或者根本不使用任何工具。
为了在没有 celery 的情况下运行作业，只需在创建运行对象后调用运行对象的 run() 方法。
例如，假设创建的运行对象（在启动脚本中）名为 run，您可以执行以下操作：

```python
run.run()
```

**是否有更用户友好的方式来启动 gem5 作业？**

您可以使用基于 Python 多进程库的函数调用（由 gem5art 提供）来并行启动多个 gem5 作业。
具体来说，您可以在 gem5art 启动脚本中调用以下函数：

```python
run_job_pool([a list containing all run objects to execute], num_parallel_jobs = [Number of parralel jobs])
```

**如何访问/搜索数据库中的文件/组件？**

您可以使用 pymongo API 函数来访问数据库中的文件。
gem5art 还提供了使访问数据库中的条目变得容易的方法。
您可以在此处查看不同的可用方法 [here](artifacts.html#searching-the-database)。

**如果我想使用相同的组件重新运行实验怎么办？**

如文档中所述，当在启动脚本中创建新的运行对象时，
会从该运行所依赖的组件创建一个哈希。
此哈希用于检查数据库中是否存在相同的运行。
用于创建哈希的组件之一是运行脚本组件（基本上与实验仓库组件相同，因为 gem5 配置脚本是基础实验仓库的一部分）。
重新运行实验的最简单方法是更新启动脚本的 name 字段，并将启动脚本中的更改提交到基础实验仓库。
确保使用新的 name 字段来查询数据库中的结果或运行。

**如何监控使用 gem5art 启动脚本启动的作业状态？**

Celery 默认不明确显示运行状态。
[flower](https://flower.readthedocs.io/en/latest/) 是一个 Python 包，是用于监控和管理 Celery 的基于 Web 的工具。

要安装 flower 包，
```sh
pip install flower
```

如果您使用 celery 来运行任务，可以使用名为 flower 的 celery 监控工具。
为此，请使用以下命令：

```sh
flower -A gem5art.tasks.celery --port=5555
```

您可以在 Web 浏览器中使用 `http://localhost:5555` 访问此服务器。

Celery 还会在您运行 celery 的目录中生成一些日志文件。
您也可以查看这些日志文件以了解作业的状态。

**如何为 gem5art 做贡献？**

gem5art 是开源的。
如果您想添加新功能或修复错误，可以在 gem5art github 仓库上创建 PR。
