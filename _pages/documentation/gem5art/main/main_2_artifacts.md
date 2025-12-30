---
layout: documentation
title: 组件
doc: gem5art
parent: main
permalink: /documentation/gem5art/main/artifacts
Authors:
  - Ayaz Akram
  - Jason Lowe-Power
---

# 组件

## gem5art 组件

在 gem5 实验期间使用的所有唯一对象在 gem5art 中称为"组件"。
组件的示例包括：gem5 二进制文件、gem5 源代码仓库、Linux 内核源代码仓库、linux 二进制文件、磁盘镜像和 packer 二进制文件（用于构建磁盘镜像）。
此基础设施的目标是记录特定实验中使用的所有组件，并在将来需要执行相同实验时返回使用的组件集。

组件的描述用作该组件如何创建的文档。
gem5art 的目标之一是使这些组件自包含。
仅使用与组件一起存储的元数据，第三方应该能够完美地重现该组件。
（我们仍在朝着这个目标努力。
例如，我们正在研究使用 docker 创建组件，以将组件创建与其运行的宿主机平台分离。）

每个组件都有一组特征属性，如下所述：

- command: 用于构建此组件的命令
- typ: 组件的类型，例如 binary、git repo 等
- name: 组件的名称
- cwd: 当前工作目录，运行构建组件的命令的位置
- path: 组件位置的实际路径
- inputs: 用于构建当前组件的组件列表
- documentation: 解释组件目的以及有助于重现组件的任何其他有用信息的文档字符串

此外，每个组件还具有以下隐式信息。

- hash: 二进制组件的 MD5 哈希或 git 组件的 git 哈希
- time: 组件的创建时间
- id: 与组件关联的 UUID
- git: 包含 git 组件的 origin、当前提交和仓库名称的字典（对于其他类型的组件将是空字典）

这些属性不是由用户指定的，而是由 gem5art 自动生成的（首次创建 `Artifact` 对象时）。

下面显示了用户如何使用 gem5art 创建 gem5 二进制组件的示例。
在此示例中，类型、名称和文档由 gem5art 用户决定。
建议使用在以后查询数据库时容易记住的名称。
文档属性应用于完整描述您正在保存的组件。

```python
gem5_binary = Artifact.registerArtifact(
    command = 'scons build/X86/gem5.opt',
    typ = 'gem5 binary',
    name = 'gem5',
    cwd = 'gem5/',
    path =  'gem5/build/X86/gem5.opt',
    inputs = [gem5_repo,],
    documentation = '''
      Default gem5 binary compiled for the X86 ISA.
      This was built from the main gem5 repo (github.com/gem5/gem5) without
      any modifications. We recently updated to the current gem5 master
      which has a fix for memory channel address striping.
    '''
)
```

gem5art 的另一个目标是实现多个用户之间的组件共享，这是通过使用集中式数据库实现的。
基本上，每当用户尝试创建新组件时，都会搜索数据库以查找是否存在相同的组件。
如果存在，用户可以下载匹配的组件以供使用。
否则，新创建的组件将上传到数据库以供以后使用。
使用数据库还可以避免运行相同的实验（如果用户尝试执行数据库中已存在的完全相同的运行，则生成错误消息）。

### 创建组件

要创建 `Artifact`，您必须如上例所示使用 `registerArtifact`。
这是一个工厂方法，将最初创建组件。

调用 `registerArtifact` 时，组件将自动添加到数据库。
如果它已经存在，将返回指向该组件的指针。

`registerArtifact` 函数的参数用于*文档*，而不是作为从头创建组件的明确指示。
将来，可能会将此功能添加到 gem5art。

注意：创建新组件时，可能会出现警告消息，显示两个组件的某些属性（除了 hash 和 id）不匹配（在代码中检查组件相似性时）。用户应确保理解任何此类警告的原因。

### 使用数据库中的组件

如果组件已存储在数据库中，您可以仅使用 UUID 创建组件。
行为将与创建已存在的组件时相同。
组件的所有属性将从数据库填充。

## ArtifactDB

此工作中使用的特定数据库是 [MongoDB](https://www.mongodb.com/)。
我们使用 MongoDB，因为它可以轻松存储大文件（例如，磁盘镜像），通过 [pymongo](https://api.mongodb.com/python/current/) 与 Python 紧密集成，并且具有灵活的接口以适应 gem5art 需求的变化。

目前，需要使用数据库才能使用 gem5。
但是，我们计划更改此默认设置，以允许 gem5art 也可以独立使用。

gem5art 允许您连接到任何数据库，但默认情况下假设在 localhost 的 `mongodb://localhost:27017` 上运行 MongoDB 实例。
您可以使用环境变量 `GEM5ART_DB` 来指定运行简单脚本时要连接的默认数据库，例如 `GEM5ART_DB=mongodb://<remote>:27017"`。
此外，您可以在脚本中调用 `getDBConnection` 时指定数据库的位置。

如果没有数据库存在或用户想要自己的数据库，您可以通过创建新目录并运行 mongodb docker 镜像来创建新数据库。
有关更多信息，请参阅 [MongoDB docker 文档](https://hub.docker.com/_/mongo) 或 [MongoDB 文档](https://docs.mongodb.com/)。

```sh
docker run -p 27017:27017 -v <absolute path to the created directory>:/data/db --name mongo-<some tag> -d mongo
```

这使用官方 [MongoDB Docker 镜像](https://hub.docker.com/_/mongo)在 localhost 的默认端口上运行数据库。
如果 Docker 容器被终止，可以使用相同的命令行重新启动它，数据库应该是一致的。

### 连接到现有数据库

默认情况下，gem5art 将假设数据库在 `mongodb://localhost:27017` 上运行，这是 MongoDB 在 localhost 上的默认值。

环境变量 `GEM5ART_DB` 可以覆盖此默认值。

否则，要在使用 gem5art 时以编程方式设置数据库 URI，您可以将 URI 传递给 `getDatabaseConnection` 函数。

目前，gem5art 仅支持 MongoDB 数据库后端，但将其扩展到其他数据库应该很简单。

### 搜索数据库

gem5art 提供了一些用于搜索和访问数据库的便捷函数。
这些函数可以在 `artifact.common_queries` 中找到。

具体来说，我们提供以下函数：

- `getByName`: 返回数据库中与 `name` 匹配的所有对象。
- `getDiskImages`: 返回磁盘镜像的生成器（type = disk image）。
- `getLinuxBinaries`: 返回 Linux 内核二进制文件的生成器（type = kernel）。
- `getgem5Binaries`: 返回 gem5 二进制文件的生成器（type = gem5 binary）。

### 从数据库下载

您还可以使用 gem5art 提供的函数下载与组件关联的文件。搜索和下载数据库中的项目的一个好方法是使用 Python 交互式 shell。
您可以使用 `artifact` 模块提供的函数搜索数据库（例如，`getByName`、`getByType` 等）。
然后，一旦找到要下载的组件的 ID，就可以调用 `downloadFile`。
请参阅下面的示例。

```sh
$ python
Python 3.6.8 (default, Oct  7 2019, 12:59:55)
[GCC 8.3.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> from gem5art.artifact import *
>>> db = getDBConnection()
>>> for i in getDiskImages(db, limit=2): print(i)
...
ubuntu
    id: d4a54de8-3a1f-4d4d-9175-53c15e647afd
    type: disk image
    path: disk-image/ubuntu-image/ubuntu
    inputs: packer:fe8ba737-ffd4-44fa-88b7-9cd072f82979, fs-x86-test:94092971-4277-4d38-9e4a-495a7119a5e5, m5:69dad8b1-48d0-43dd-a538-f3196a894804
    Ubuntu with m5 binary installed and root auto login
ubuntu
    id: c54b8805-48d6-425d-ac81-9b1badba206e
    type: disk image
    path: disk-image/ubuntu-image/ubuntu
    inputs: packer:fe8ba737-ffd4-44fa-88b7-9cd072f82979, fs-x86-test:5bfaab52-7d04-49f2-8fea-c5af8a7f34a8, m5:69dad8b1-48d0-43dd-a538-f3196a894804
    Ubuntu with m5 binary installed and root auto login
>>> for i in getLinuxBinaries(db, limit=2): print(i)
...

vmlinux-5.2.3
    id: 8cfd9fbe-24d0-40b5-897e-beca3df80dd2
    type: kernel
    path: linux-stable/vmlinux-5.2.3
    inputs: fs-x86-test:94092971-4277-4d38-9e4a-495a7119a5e5, linux-stable:25feca9a-3642-458e-a179-f3705266b2fe
    Kernel binary for 5.2.3 with simple config file
vmlinux-5.2.3
    id: 9721d8c9-dc41-49ba-ab5c-3ed169e24166
    type: kernel
    path: linux-stable/vmlinux-5.2.3
    inputs: npb:85e6dd97-c946-4596-9b52-0bb145810d68, linux-stable:25feca9a-3642-458e-a179-f3705266b2fe
    Kernel binary for 5.2.3 with simple config file
>>> from uuid import UUID
>>> db.downloadFile(UUID('8cfd9fbe-24d0-40b5-897e-beca3df80dd2'), 'linux-stable/vmlinux-5.2.3')
```

再举一个例子，假设数据库中有一个名为 `npb` 的磁盘镜像（包含 [NAS Parallel](https://www.nas.nasa.gov/) 基准测试），您想将磁盘镜像下载到本地目录。您可以执行以下操作来下载磁盘镜像：

```python
import gem5art.artifact

db = gem5art.artifact.getDBConnection()

disks = gem5art.artifact.getByName(db, 'npb')

for disk in disks:
    if disk.type == 'disk image' and disk.documentation == 'npb disk image created on Nov 20':
        db.downloadFile(disk._id, 'npb')
```

在这里，我们假设可能有多个名为 `npb` 的磁盘镜像/组件，我们只对下载具有特定文档（'npb disk image created on Nov 20'）的 npb 磁盘镜像感兴趣。另外，请注意还有其他方法可以从数据库下载文件（尽管它们最终会使用 `downloadFile` 函数）。

上面使用的 `downloadFile` 方法的对偶是 `upload`。

#### 数据库模式

或者，您可以使用 pymongo Python 模块或 mongodb 命令行界面与数据库交互。
有关如何查询 MongoDB 数据库的更多信息，请参阅 [MongoDB 文档](https://docs.mongodb.com/)。

gem5art 有两个集合。
`artifact_database.artifacts` 存储所有组件的元数据，`artifact_database.fs` 是所有文件的 [GridFS](https://docs.mongodb.com/manual/core/gridfs/) 存储。
GridFS 中的文件使用与 Artifacts 相同的 UUID 作为其主键。

您可以通过在 Python 中运行以下命令来列出所有组件的所有详细信息。

```python
#!/usr/bin/env python3

from pymongo import MongoClient

db = MongoClient().artifact_database
for i in db.artifacts.find():
    print(i)
```

gem5art 还提供了一些方法来搜索数据库中特定类型或名称的组件。例如，要查找数据库中的所有磁盘镜像，您可以执行以下操作：

```python
import gem5art.artifact
db = gem5art.artifact.getDBConnection('mongodb://localhost')
for i in gem5art.artifact.getDiskImages(db):
    print(i)
```

其他类似的方法包括：`getLinuxBinaries()`、`getgem5Binaries()`

您可以使用 getByName() 方法使用 name 属性搜索数据库中的组件。例如，要搜索名为 gem5 的组件：

```python
import gem5art.artifact
db = gem5art.artifact.getDBConnection('mongodb://localhost')
for i in gem5art.artifact.getByName(db, "gem5"):
    print(i)
```
