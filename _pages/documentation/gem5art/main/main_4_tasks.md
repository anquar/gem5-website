---
layout: documentation
title: 任务
doc: gem5art
parent: main
permalink: /documentation/gem5art/main/tasks
Authors:
  - Ayaz Akram
  - Jason Lowe-Power
---

# 任务

此包包含两个用于运行 gem5 实验的并行任务库。
实际的 gem5 实验可以在 [Python 多进程支持](https://docs.python.org/3/library/multiprocessing.html)、[Celery](http://www.celeryproject.org/) 的帮助下执行，甚至可以不使用任何作业管理器（可以通过调用 gem5Run 对象的 `run()` 函数直接启动作业）。
此包隐式依赖于 gem5art run 包。

使用 gem5art 包时，请引用 [gem5art 论文](https://arch.cs.ucdavis.edu/papers/2021-3-28-gem5art)。
此文档可以在 [gem5 网站](http://www.gem5.org/documentation/gem5art/) 上找到。

## 使用 Python 多进程

这是使用 Python 多进程库运行 gem5 作业的简单方法。
您可以在作业启动脚本中使用以下函数来执行 gem5art 运行对象：

```python
run_job_pool([a list containing all run objects to execute], num_parallel_jobs = [Number of parallel jobs])
```

## 使用 Celery

Celery 服务器可以异步运行许多 gem5 任务。
一旦用户在使用 gem5art 时创建了 gem5Run 对象（前面讨论过），需要将此对象传递给在 Celery 应用中注册的方法 `run_gem5_instance()`，该方法负责启动 Celery 任务来运行 gem5。`run_gem5_instance()` 需要的另一个参数是当前工作目录。

可以使用以下命令启动 Celery 服务器：

```sh
celery -E -A gem5art.tasks.celery worker --autoscale=[number of workers],0
```

这将启动一个启用事件的服务器，该服务器将接受 gem5art 中定义的 gem5 任务。
它将从 0 自动缩放到所需的工作进程数。

Celery 依赖消息代理 `RabbitMQ` 在客户端和工作进程之间进行通信。
如果尚未安装，您需要在系统上安装 `RabbitMQ`（在运行 celery 之前）：

```sh
apt-get install rabbitmq-server
```

### 监控 Celery

Celery 默认不明确显示运行状态。
[flower](https://flower.readthedocs.io/en/latest/) 是一个 Python 包，是用于监控和管理 Celery 的基于 Web 的工具。

要安装 flower 包，
```sh
pip install flower
```

您可以通过以下方式监控 celery 集群：

```sh
flower -A gem5art.tasks.celery --port=5555
```
这将在端口 5555 上启动 Web 服务器。

### 删除所有任务

```sh
celery -A gem5art.tasks.celery purge
```

### 查看 celery 中所有作业的状态

```sh
celery -A gem5art.tasks.celery events
```
