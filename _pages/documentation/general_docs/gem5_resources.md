---
layout: documentation
title: gem5 资源
doc: gem5 documentation
parent: gem5_resources
permalink: /documentation/general_docs/gem5_resources/
authors: Bobby R. Bruce, Kunal Pai, Parth Shah
---

# gem5 资源

gem5 Resources 是一个仓库，提供已知并证明与 gem5 架构模拟器兼容的工件源。这些资源对于 gem5 的编译或运行不是必需的，但可能有助于用户生成某些模拟。

## 为什么需要 gem5 资源？

gem5 的设计考虑了灵活性。用户可以模拟各种各样的硬件，以及同样各种各样的工作负载。然而，要求用户查找和配置 gem5 的工作负载（他们自己的磁盘镜像、他们自己的 OS 引导、他们自己的测试等）是一项重大投资，对许多人来说是一个障碍。

因此，gem5 Resources 的目的是 **提供一套稳定的常用资源，并具有经过验证和记录的与 gem5 的兼容性**。除此之外，gem5 资源还通过提供可引用、稳定的资源（绑定到 gem5 的特定版本）来强调 **实验的可重复性**。

## 我在哪里可以获得 gem5 资源？

要在 gem5 Resources 中查找特定资源，我们建议使用 [gem5 Resources 网站](https://resources.gem5.org)。有关如何在此网站上搜索、过滤和排序的详细信息，请参阅此 [帮助页面](https://resources.gem5.org/help)。

gem5 Resources 托管在我们的 Google Cloud Bucket 上。资源的链接可以在 [gem5 resources README.md 文件](
https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/stable/README.md) 中找到。
资源元数据存储在托管于 MongoDB Atlas 的 MongoDB 数据库中。
要请求更新 gem5 资源，请创建 issue 或邮件 gem5-dev。

## 在 gem5 中使用 gem5 Resources 网站的资源

当您找到要在模拟中使用的资源时，请导航到该资源的“Usage”选项卡。

为了本教程的目的，让我们假设您正在寻找的资源是 `riscv-hello`，在 [这里](https://resources.gem5.org/resources/riscv-hello) 找到。在该资源的 ['Usage'](https://resources.gem5.org/resources/riscv-hello/usage) 选项卡中，您将找到可以粘贴到 gem5 模拟中以使用此资源的代码。

在这种情况下，代码是 `obtain_resource(resource_id="riscv-hello")`。

要使用 `obtain_resource` 函数，您需要以下导入语句：

```
from gem5.resources.resource import obtain_resource
```

`obtain_resource` 函数接受以下参数：

- `resource_id`: 您要使用的资源的 ID。
- `resource_version`: 可选参数，指定您要使用的资源版本。如果未指定，将使用与正在使用的 gem5 版本兼容的资源的最新版本。
- `clients`: 可选参数，指定 gem5 搜索资源的客户端列表。如果未指定，gem5 将在 `src/python/gem5_default_config.py` 文件中指定的所有客户端中搜索资源。默认情况下，gem5 将使用公共 MongoDB 元数据数据库来查找资源。这可以被覆盖以指定您自己的本地资源元数据。

## 在 gem5 中使用 gem5 Resources 网站的工作负载

当您找到要在模拟中使用的工作负载时，请导航到该工作负载的“Usage”选项卡。

为了本教程的目的，让我们假设您正在寻找的工作负载是 `riscv-ubuntu-20.04-boot`，在 [这里](https://resources.gem5.org/resources/riscv-ubuntu-20.04-boot) 找到。在该工作负载的 ['Usage'](https://resources.gem5.org/resources/riscv-ubuntu-20.04-boot/usage) 选项卡中，您将找到可以粘贴到 gem5 模拟中以使用此工作负载的代码。

在这种情况下，代码是 `Workload("riscv-ubuntu-20.04-boot")`。

要使用 `Workload` 类，您需要以下导入语句：

```
from gem5.resources.workload import Workload
```

`Workload` 类接受以下参数：

- `workload_name`: 您要使用的工作负载的名称。
- `resource_directory`: 可选参数，指定应从何处下载和访问任何资源。
- `resource_version`: 可选参数，指定应使用的资源版本。如果未指定，将使用与正在使用的 gem5 版本兼容的资源的最新版本。
- `clients`: 可选参数，指定 gem5 搜索资源的客户端列表。如果未指定，gem5 将在 `src/python/gem5_default_config.py` 文件中指定的所有客户端中搜索资源。

## 在 gem5 中使用自定义资源

要在 gem5 中使用自定义资源，我们建议使用 gem5 中支持的数据源格式之一。目前，我们支持 MongoDB Atlas、本地 JSON 文件和远程 JSON 文件。

您可以通过在运行文件时覆盖 `GEM5_DEFAULT_CONFIG` 变量来使用您自己的配置文件。

注意：您添加的任何自定义资源都必须符合 [gem5 Resources Schema](https://resources.gem5.org/gem5-resources-schema.json)。

`utils/gem5-resources-manager` 中有一个实用程序，它提供了一个 GUI 来更新和创建公共资源（只能由 gem5 管理员修改）和本地资源元数据。
您可以在 README 文件中找到有关 gem5 Resources Manager 的更多信息。

## 我如何获取 gem5 Resource 源码？

gem5 resources 源码可以从以下位置获得
<https://github.com/gem5/gem5-resources>:

```bash
git clone https://github.com/gem5/gem5-resources
```

`stable` 分支的 HEAD 将指向一组与最新发布的 gem5 版本兼容的资源源（可以通过 `git clone https://github.com/gem5/gem5.git` 获得）。

请查阅 [README.md](
https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/stable/README.md)
文件以获取有关编译单个 gem5 资源的信息。在许可允许的情况下，[README.md](
https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/stable/README.md)
文件将提供从我们的 dist.gem5.org Google Cloud Bucket 下载编译资源的链接。

## gem5 Resources 仓库是如何构建的？

该仓库的结构如下：

* **README.md** : 此 README 将概述每个资源、它们的来源、它们如何修改以与 gem5 一起工作（如果适用）、相关的许可信息和编译说明。对于那些希望使用 gem5 资源的人来说，这应该是第一个停靠港。
* **src** : 资源源。gem5 资源可以在此目录中找到。每个子目录概述一个资源。每个资源都包含其自己的 README.md 文件，记录相关信息——编译说明、使用说明等。
* **CHANGELOG.md** : 此 CHANGELOG 将概述特定资源在其版本之间的更改。

### 版本控制

每个资源可以有多个版本。版本采用 `<major>.<minor>.<patch>` 的形式。版本控制方案基于 [语义化版本控制 (Semantic Versioning)](https://semver.org/)。资源的每个版本都链接到一个或多个 gem5 版本（例如，v20.0, v20.1, v20.2 等）。

默认情况下，gem5 使用与正在使用的 gem5 版本兼容的资源的最新版本。但是，用户可以指定要使用的资源的特定版本。如果用户指定的资源版本与正在使用的 gem5 版本不兼容，gem5 将抛出警告。
您仍然可以使用该资源，但风险自负。

### 引用资源

我们强烈建议在出版物中引用 gem5 Resources，以帮助复制实验、教程等。

要作为 URL 引用，请使用以下格式：

```
# 对于特定修订的 git 仓库：
https://github.com/gem5/gem5-resources/<revision>/src/<resource>

# 对于特定标签的 git 仓库：
https://github.com/gem5/gem5-resources/tree/<branch>/src/<resource>
```

或者，作为 BibTex：

```
@misc{gem5-resources,
  title = {gem5 Resources. Resource: <resource>},
  howpublished = {\url{https://github.com/gem5/gem5-resources/<revision>/src/<resource>}},
  note = {Git repository at revision '<revision>'}
}

@misc{gem5-resources,
  title = {gem5 Resources. Resource: <resource>},
  howpublished = {\url{https://github.com/gem5/gem5-resources/tree/<branch>/src/<resource>}},
  note = {Git repository at tag '<tag>'}
}
```

## 我如何为 gem5 Resources 做贡献？

对 gem5 Resources 仓库的更改是通过我们的 Gerrit 代码审查系统对 develop 分支进行的。因此，要进行更改，首先克隆仓库：

```
git clone https://github.com/gem5/gem5-resources.git
```

然后进行更改并提交。准备好后，使用以下命令推送到 Gerrit：

```
git push origin HEAD:refs/for/stable
```

这将添加将在最新 gem5 版本中使用的资源。

要为下一个 gem5 版本贡献资源，
```
git clone https://github.com/gem5/gem5-resources.git
git checkout --track origin/develop
```

然后进行更改，提交并使用以下命令推送：

```
git push origin HEAD:refs/for/develop
```

提交消息头不应超过 65 个字符，并以标记 `resources:` 开头。标题后的描述不得超过 72 个字符。

例如：

```
resources: Adding a new resources X

This is where the description of this commit will occur taking into
note the 72 character line limit.
```

我们强烈建议贡献者在可能和适当的情况下遵循我们的 [风格指南](
/documentation/general_docs/development/coding_style/)。

任何更改随后将通过我们的 [Gerrit 代码审查系统](
https://gem5-review.googlesource.com) 进行审查。一旦完全接受并合并到 gem5 resources 仓库中，请联系 Bobby R. Bruce
([bbruce@ucdavis.edu](mailto:bbruce@ucdavis.edu)) 将任何编译的源上传到 gem5 resources bucket。
