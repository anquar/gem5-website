---
layout: documentation
title: "发布流程"
doc: gem5 documentation
parent: development
permalink: /documentation/general_docs/development/release_procedures/
---

有关何时进行发布、如何通知社区、版本信息以及如何为发布做出贡献的信息可以在我们的 [CONTRIBUTING.md 文档](https://github.com/gem5/gem5/blob/stable/CONTRIBUTING.md#releases)中找到。
本文档的目的是概述发布期间执行的具体流程。

## gem5 代码仓库

[gem5 git 仓库](https://github.com/gem5/gem5) 有两个分支：[stable](https://github.com/gem5/gem5/tree/stable) 和 [develop](https://github.com/gem5/gem5/tree/develop)。
stable 分支的 HEAD 是 gem5 的最新正式发布版本，并将被标记为如此。
用户不允许向 stable 分支提交补丁，而是向 develop 分支提交补丁。
在发布前至少两周，从 develop 分支创建一个 staging 分支。
这个 staging 分支经过严格测试，只允许提交 bug 修复或不重要的更改（格式修复、拼写错误修复等）。

staging 分支会进行以下更新：

* 移除 `-werror`。
这确保 gem5 在较新的编译器上能够编译，因为会加入新的/更严格的编译器警告。
例如：<https://gem5-review.googlesource.com/c/public/gem5/+/43425>。
* 更新 [Doxygen "Project Number" 字段](https://github.com/gem5/gem5/blob/v21.0.1.0/src/Doxyfile#34) 为版本 ID。
例如：<https://gem5-review.googlesource.com/c/public/gem5/+/47079>。
* 更新 [`src/base/version.cc`](https://github.com/gem5/gem5/blob/stable/src/base/version.cc) 文件以声明版本 ID。
例如：<https://gem5-review.googlesource.com/c/public/gem5/+/47079>。
* 更新 [`ext/testlib/configuration.py`](https://github.com/gem5/gem5/blob/stable/ext/testlib/configuration.py) 文件的 `default.resource_url` 字段，指向正确的 Google Cloud 发布存储桶（参见 [云存储桶发布流程](#gem5-resources-google-cloud-bucket)）。
例如：<https://gem5-review.googlesource.com/c/public/gem5/+/44725>。
* Resource 下载器 `src/python/gem5/resources/downloader.py` 有一个函数 `def _resources_json_version_required()`。必须将其更新为要使用的 `resources.json` 文件的正确版本（有关此内容的更多信息，请参见 [gem5 resources 仓库发布流程](#gem5-resources-repository)）。
* 应更新 `tests/weekly.sh`、`tests/nightly.sh`、`tests/compiler-tests.sh` 和 `tests/jenkins/presubmit.sh`，确保它们在不同 gem5 版本之间保持稳定。这通过以下方式实现：
    1. 通过附加版本来修复 docker 拉取镜像（示例见[此处](https://gem5-review.googlesource.com/c/public/gem5/+/54470)）。这将在遵循 [Docker 镜像发布流程](#the-docker-images) 后完成。
    2. 确保下载链接从正确的 Google Cloud 存储桶下载发布版本。
* 在 `util/dockerfiles/gcn-gpu` 中将 `rocm_patches/ROCclr.patch` 下载链接硬编码为正确的 Google 存储桶。
* 更新当前版本的 `ext/sst/README.md` 文件。这仅意味着更新下载链接。
有关如何执行此操作的示例，请参见[此处](https://gem5-review.googlesource.com/c/public/gem5/+/54703)。

当确认 staging 分支处于令人满意的状态时，它将被合并到 develop 和 stable 分支。
然后还有两个额外的操作：

1. 上述对 staging 分支的更改在 develop 分支上被还原。
2. stable 分支在其 HEAD 处标记为最新发布版本 id。
    * 例如：`git tag -a v21.1.0.0 -m "gem5 version 21.1.0.0" && git push --tags`

应更新 [RELEASE-NOTES.md](https://github.com/gem5/gem5/blob/stable/RELEASE-NOTES.md) 以通知社区此发布中的主要更改。
这可以在创建 staging 分支之前在 develop 分支上完成，或在 staging 分支上完成。
习惯上会在 <http://www.gem5.org> 上创建一篇博客文章概述发布。
虽然这很受欢迎，但不是强制性的。

**重要说明：**
* 您必须是 "Project Owners" 或 "google/gem5-admins@googlegroups.com" Gerrit 权限组的成员才能推送到 stable 分支。
如需帮助推送到 gem5 stable 分支，请联系 Bobby R. Bruce (bbruce@ucdavis.edu)。

## gem5 resources 仓库

[gem5 resources git 仓库](https://github.com/gem5/gem5-resources) 有两个分支：[stable](https://github.com/gem5/gem5-resources/tree/stable) 和 [develop](https://github.com/gem5/gem5-resources/tree/develop)。
stable 分支的 HEAD 包含与最近发布的 gem5 具有已知兼容性的资源源代码。
例如，如果 gem5 的当前发布版本是 v22.3，则 gem5 resources 仓库的 HEAD 将包含与 v22.3 具有已知兼容性的资源源代码。
develop 分支包含与 gem5 仓库的 develop 分支兼容的源代码。
与 gem5 仓库不同，对 gem5 resources 仓库的更改可以提交到 stable 分支，前提是这些更改与最新发布的 gem5 兼容。

与 gem5 仓库一样，在发布前至少两周创建一个 staging 分支。
此 staging 分支的用途与主 gem5 仓库相同，在 gem5 发布时合并到 stable 和 develop 分支。
在此之前，应对 staging 分支应用以下更改：

* 应为该版本创建一个新的 Google Cloud Bucket 目录（参见 [云存储桶发布流程](#gem5-resources-google-cloud-bucket)），并且 staging 分支中的所有资源必须与 Google Cloud Bucket 目录中找到的资源匹配（即，存储桶中的编译资源是从 staging 分支中的源代码构建的）。
* 应更新 resources 仓库中的 URL 下载链接，指向正确的 Google Cloud Bucket 目录。
* 必须更新仓库根目录中的 `resources.json` 文件以适应当前发布。
[此补丁](https://gem5-review.googlesource.com/c/public/gem5-resources/+/54403) 显示了如何执行此操作的示例。
`version` 字段必须更新为与 `src/python/gem5/resources/downloader.py` 文件中的版本匹配的版本。
`previous-version` 列表必须更新以支持所有之前的版本，包括 develop。
每个之前的版本必须映射到一个可下载的文件。
* 必须将 `resources.json` 的 `url_base` 字段更新为 Google Cloud Bucket 中的正确目录。

合并到 develop 分支时，URL 下载链接应还原回 `http://dist.gem5.org/dist/develop`。

在合并之前，stable 分支会立即标记为之前的发布版本 ID。
例如，如果 staging 分支用于 `v22.2`，而 stable 分支上的内容用于 `v22.1`，则 stable 分支将在合并之前立即标记为 `v22.1`。
这是因为我们希望用户能够还原 gem5 resources 以获取与之前 gem5 发布版本兼容的源代码。
因此，如果用户希望获取与 v20.1 发布版本兼容的资源源代码，他们将在 stable 分支上检出标记为 `v20.1` 的修订版本。

### gem5 resources Google Cloud Bucket

构建的 gem5 resources 位于 gem5 Google Cloud Bucket 中。

[gem5 resources git 仓库](#gem5-resources-repository) 包含 gem5 resources 的源代码，这些源代码随后被编译并存储在 Google Cloud Bucket 中。
gem5 resources 仓库的 [README.md](https://github.com/gem5/gem5-resources/blob/stable/README.md) 包含从 Google Cloud Bucket 下载构建资源的链接。

Google Cloud Bucket 与 gem5 resources 仓库一样，是版本化的。
每个资源存储在 `http://dist.gem5.org/dist/{major version}` 下。
例如，版本 20.1 的 PARSEC Benchmark 镜像存储在 <http://dist.gem5.org/dist/v20-1/images/x86/ubuntu-18-04/parsec.img.gz>，而版本 21.0 的镜像存储在 <http://dist.gem5.org/dist/v21-0/images/x86/ubuntu-18-04/parsec.img.gz>（注意 URL 中版本号的 `.` 替换为 `-`）。
develop 分支的构建位于 <http://dist.gem5.org/dist/develop>。

由于 gem5 resources staging 分支来自 develop，创建 develop 存储桶目录副本的最简单方法是：

```
gsutil -m cp -r gs://dist.gem5.org/dist/develop gsutil -m cp -r gs://dist.gem5.org/dist/{major version}
```

develop 存储桶**应该**与 develop 上的更改保持同步。
不过值得检查一下。
当然，staging 分支上的任何更改都必须相应地反映在 Cloud Bucket 中。

**重要说明：**
* 由于历史原因，<http://dist.gem5.org/dist/current> 用于存储与 gem5 v19 相关的旧资源。
* 推送到 Google Cloud Bucket 需要特殊权限。
如需帮助推送资源到存储桶，请联系 Bobby R. Bruce (bbruce@ucdavis.edu)。

## Docker 镜像

目前在 gem5 仓库的 [`util/dockerfiles`](https://github.com/gem5/gem5/tree/stable/util/dockerfiles/) 中托管，我们有一系列 Dockerfile，可以构建这些文件以生成可以构建和运行 gem5 的环境。
这些镜像主要用于测试目的。
[`ubuntu-20.04_all-dependencies`](https://github.com/gem5/gem5/tree/stable/util/dockerfiles/ubuntu-20.04_all-dependencies/) Dockerfile 最适合希望在受支持环境中构建和执行 gem5 的用户。

我们在 <ghcr.io> 上提供预构建的 Docker 镜像，位于 "gem5" 下。
在 `util/dockerfiles` 中找到的所有 Dockerfile 都已构建并存储在那里。
例如，`ubuntu-20.04_all-dependencies` 可以在 <ghcr.io/gem5/ubuntu-20.04_all-dependencies> 找到（因此可以通过 `docker pull ghcr.io/gem5/ubuntu-20.04_all-dependencies` 获取）。

Docker 镜像持续从 develop 分支上的 Dockerfile 构建。
因此，带有 `latest` 标签的 docker 镜像与 gem5 仓库 develop 分支上的 Dockerfile 保持同步。
在发布最新版本的 gem5 时，当 staging 分支合并到 develop 时，托管在 <ghcr.io> 上的构建镜像将使用 gem5 版本号进行标记。
因此，在发布 `v23.2` 时，镜像将标记为 `v23-2`。
这样做的目的是让使用旧版本 gem5 的用户可以获得与其发布版本兼容的镜像。
即，gem5 `v21.0` 的用户可以通过 `docker pull ghcr.io/gem5/ubuntu-20.04_all-dependencies:v21-0` 获取 `ubuntu-20.04_all-dependencies` 的 `v21.0` 版本。

**重要说明：**
* 如果对 Dockerfile 的更改在 staging 分支上完成，则需要手动将这些更改推送到 <ghcr.io>。
* 推送到 <ghcr.io> 需要特殊权限。
如需帮助推送镜像，请联系 Bobby R. Bruce (bbruce@ucdavis.edu)。
* 我们的未来目标是将 [Dockerfile 从 `util/dockerfiles` 移动到 gem5-resources](https://gem5.atlassian.net/browse/GEM5-1044)。

## gem5 网站仓库

[gem5 网站 git 仓库](https://github.com/gem5/website/) 有两个分支：[stable](https://github.com/gem5/website/tree/stable) 和 [develop](https://github.com/gem5/website/tree/develop)。
stable 分支是在 <http://www.gem5.org> 构建和可查看的内容，并与当前 gem5 发布版本保持同步。
例如，如果 gem5 的当前发布版本（在其 stable 分支上）是 `v20.1`，则 stable 分支上的文档将与 `v20.1` 相关。
develop 分支包含即将发布的 gem5 版本的网站状态。
例如，它包含在发布新版本的 gem5 时需要应用到网站的更改。

由于 stable 分支可能随时更新（只要这些更新与当前发布版本相关），stable 会定期合并到 develop。
与 gem5 resources 和主 gem5 仓库一样，在 gem5 发布前至少两周从 develop 分支创建一个 staging 分支。

需要更新 staging 分支，以便文档与即将发布的版本保持同步。
特别要注意的是，应更新对托管在 Google Cloud 存储桶上的 gem5 resources 的引用。
例如，从 `v21-0` 过渡到 `v21-1` 时，需要将链接（例如 <http://dist.gem5.org/dist/v21-0/images/x86/ubuntu-18-04/parsec.img.gz>）更新为 <http://dist.gem5.org/dist/v21-1/images/x86/ubuntu-18-04/parsec.img.gz>。

在新的主要 gem5 发布时，develop 分支合并到 stable。
在将 staging 分支合并到 stable 之前，网站仓库会标记为之前的版本。
这与 gem5 resources 仓库相同。
例如，如果当前发布版本是 v21.1.0.4，下一个发布版本是 v21.2.0.0，则在发布 v21.2.0.0 之前，stable 分支将立即标记为 v21.1.0.4，然后将 develop 分支合并到 stable。
这确保用户可以根据需要将网站还原到之前发布版本的状态。

## gem5 Doxygen

[gem5 Doxygen 网站](http://doxygen.gem5.org) 由 [Doxygen 文档生成器](https://www.doxygen.nl/index.html) 创建。
可以在 gem5 仓库中按以下方式创建：

```
cd src
doxygen
```

HTML 将输出到 `src/doxygen/html`。

gem5 Doxygen 网站作为静态网页托管在 Google Cloud Bucket 中。
目录结构如下：

```
doxygen.gem5.org/
    - develop/              # 包含 gem5 develop 分支的 Doxygen。
        - index.html
        ...
    - release/              # 每个 gem5 发布版本的 Doxygen 存档。
        - current/          # 当前 gem5 发布版本的 Doxygen。
            - index.html
            ...
        - v21-0-1-0/
            - index.html
            ...
        - v21-0-0-0/
            - index.html
            ...
        - v20-1-0-5/
            - index.html
            ...
        ...
    - index.html           # 重定向到 release/current/index.html。
```

因此，最新发布版本的 Doxygen 可以在 <http://doxygen.gem5.org/> 获取，develop 分支的 Doxygen 在 <http://doxygen.gem5.org/develop>，过去发布版本的 Doxygen 在 <http://doxygen.gem5.org/release/{version}>（例如，<http://doxygen.gem5.org/release/v20-1-0-5>）。

在 gem5 发布后，以下代码在 gem5 仓库的 stable 分支上运行：

```
cd src
doxygen

gsutil -m rm gs://doxygen.gem5.org/release/current/*
gsutil -m cp -r doxygen/html/* gs://doxygen.gem5.org/release/current/
gsutil -m cp -r gs://doxygen.gem5.org/release/current gs://doxygen.gem5.org/release/{version id}
```

最后一步是通过 [`_data/documentation.yml` 文件](https://github.com/gem5/website/blob/stable/_data/documentation.yml) 在网站上添加指向此 gem5 Doxygen 版本的链接。
例如：<https://gem5-review.googlesource.com/c/public/gem5-website/+/43385>。


**重要说明：**
* gem5 develop 分支的 Doxygen 网站通过自动化构建过程每天更新。
Doxygen 网站页脚将说明页面生成时间。
* 推送到 Google Cloud Bucket 需要特殊权限。
如需帮助推送到 Google Cloud Bucket，请联系 Bobby R. Bruce (bbruce@ucdavis.edu)。

## 次要版本和热修复发布

前面的部分主要关注 gem5 的主要发布。
gem5 的次要版本和热修复发布不应以重大方式更改任何 API 或功能。
因此，对于 gem5 的次要版本和热修复发布，我们只执行 [gem5 代码仓库](#gem5-repository) 和 [gem5 Doxygen 网站](#gem5-doxygen) 的发布流程。
后者可能是不必要的，具体取决于更改，但这是一项低成本的工作。
