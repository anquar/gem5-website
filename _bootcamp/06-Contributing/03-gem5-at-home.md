---
layout: bootcamp
title: gem5 在家使用
permalink: /bootcamp/contributing/gem5-at-home
section: contributing
author: William Shaddix
---
<!-- _class: title -->

## gem5 在家（或工作/学校）使用

---

## 获取帮助

gem5 有很多获取帮助的资源：

1. 文档位于 [gem5 doxygen](http://doxygen.gem5.org/)
2. 寻求帮助的方式：
   - [Github discussions](https://github.com/orgs/gem5/discussions) **这是提问的主要场所**
   - [gem5 Slack 频道](https://join.slack.com/t/gem5-workspace/shared_invite/zt-2e2nfln38-xsIkN1aRmofRlAHOIkZaEA)
   - 加入我们的邮件列表：
      - [gem5-dev@gem5.org : 用于讨论 gem5 开发相关话题](https://harmonylists.io/list/gem5-dev.gem5.org)
      - [gem5-users@gem5.org : 用于讨论 gem5 及其使用的一般话题](https://harmonylists.io/list/gem5-users.gem5.org)
      - [gem5-announce@gem5.org : 用于 gem5 的一般公告](https://harmonylists.io/list/gem5-announce.gem5.org)
3. [Youtube 视频](https://www.youtube.com/@gem5)

这些链接和更多信息也可在 [https://www.gem5.org/ask-a-question/](https://www.gem5.org/ask-a-question/) 获取

> 我们尽力回答问题，但问题经常得不到回复。这不是因为问题不好，而是因为我们没有足够的志愿者。

---

## 在家运行 gem5

- gem5 性能特点
   - 单线程
   - 消耗大量 RAM（如果你想模拟 32 GB 的内存，它需要 32 GB 的内存来模拟它）
   - 可能需要很长时间
- 因此，最好并行运行多个实验
- 推荐的硬件：
   - 高单线程性能
   - 不需要太多核心
   - 大量内存

---

## 系统软件要求

- Ubuntu 22.04+（至少 GCC 10）
   - 20.04 也可以工作，但 GCC 8（或 9，无论默认是什么）存在 bug，你必须升级 GCC 版本。
- Python 3.6+
- SCons
- 许多可选要求。

这在大多数 Linux 系统和 MacOS 上*应该*可以工作。

查看我们的 Dockerfiles 以获取最新的版本信息：

[`gem5/util/dockerfiles/`](https://github.com/gem5/gem5/tree/stable/util/dockerfiles)

---

## 使用 dockerfiles

如果你遇到问题，我们提供了 docker 镜像。

这是一个应该可以工作的通用 docker 命令。

```sh
docker run --rm -v $(pwd):$(pwd) -w $(pwd) ghcr.io/gem5/ubuntu-24.04_all-dependencies:v24-0 <your command>
```

- 运行位于 `https://ghcr.io/gem5/ubuntu-24.04_all-dependencies:v24-0` 的镜像。
- 自动删除 docker 镜像（`--rm`）
- 设置当前目录（`-v $(pwd):$(pwd)`）在 docker 容器内可用
- 将工作目录设置为当前目录（`-w $(pwd)`）
- 运行命令。
- 现在每个命令都需要使用此方式运行，以确保库设置正确。

> 我**强烈**强调，你不应该在 docker 容器中交互式运行。使用它一次只运行一个命令。

---

## 开发容器

我们一直在使用的开发容器基于 `ghcr.io/gem5/ubuntu-24.04_all-dependencies:v24-0`，但也包含一些 gem5 二进制文件。

你可以在 `ghcr.io/gem5/devcontainer:bootcamp-2024` 找到它。

源代码将很快在 [`gem5/utils/dockerfiles/devcontainer`](https://github.com/gem5/gem5/blob/stable/util/dockerfiles/devcontainer/Dockerfile) 提供。

---

## 推荐实践

- 除非计划为 gem5 做贡献或需要使用最近开发的工作，否则使用 ```stable``` 分支。
- 从 stable 创建分支。
- 不要修改 `src/` 中 python 文件的参数。相反，创建 stdlib 类型或 SimObjects 的*扩展*。
- 不要害怕阅读代码。代码是最好的文档。

---

<!-- _class: start -->

## 最后

---

## 非常感谢

![Everyone who has contributed to the bootcamp width:1200px](/bootcamp/06-Contributing/../01-Introduction/00-introduction-to-bootcamp-imgs/devs.drawio.svg)

---

## 非常感谢大家！

![Group photo height:300px](/bootcamp/06-Contributing/03-gem5-at-home-imgs/group.jpg)

请告诉我们您的反馈：

<https://forms.gle/ZLZdv9h126d8GFrS7>

![QR code for google form bg right 60%](/bootcamp/06-Contributing/03-gem5-at-home-imgs/qr-code.png)
