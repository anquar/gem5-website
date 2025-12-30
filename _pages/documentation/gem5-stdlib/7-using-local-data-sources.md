---
layout: documentation
title: 设置 gem5 Resources 数据源以支持本地资源
parent: gem5-standard-library
doc: gem5 documentation
permalink: /documentation/gem5-stdlib/using-local-resources
author: Harshil Patel
---

gem5 支持使用 MongoDB Atlas 和 JSON 数据源形式的本地数据源。gem5 在 `src/python/gem5_default_config.py` 中有一个默认资源配置。此资源配置指向 gem5 资源的 MongoDB Atlas 集合。要使用主 gem5 资源数据库以外的数据源，您需要覆盖 gem5-resources-config。

有几种方法可以更新 gem5 资源配置：

1. **设置 GEM5_CONFIG 环境变量**：您可以设置 GEM5_CONFIG 环境变量以指定新的配置文件。这样做将用您指定的配置替换默认资源配置。

2. **使用 gem5-config.json**：如果当前工作目录中存在名为 gem5-config.json 的文件，它将优先于默认资源配置。

3. **回退到默认资源配置**：如果上述两种方法都未使用，系统将使用默认资源配置。

此外，如果您希望利用或添加本地资源 JSON 文件到当前选定的配置（如上述方法中所述），您还有两种额外的方法可用：

- **GEM5_RESOURCE_JSON 环境变量**：此变量可用于覆盖当前资源配置并使用指定的 JSON 文件。

- **GEM5_RESOURCE_JSON_APPEND 环境变量**：使用此变量将 JSON 文件添加到现有资源配置中，而不替换它。

需要注意的是，覆盖或追加不会修改实际的配置文件本身。这些方法允许您在运行时临时指定或添加资源配置，而无需更改原始配置文件。

MongoDB Atlas 配置格式：

```json
{
    "sources":{
        "example-atlas-config": {
            "dataSource": "datasource name",
            "database": "database name",
            "collection": "collection name",
            "url": "Atlas data API URL",
            "authUrl": "Atlas authentication URL",
            "apiKey": "API key for data API for MongoDB Atlas",
            "isMongo": true
        }
    }
}
```

JSON 配置格式：

```json
{
    "sources":{
        "example-json-config": {
            "url": "local path to JSON file or URL to a JSON file",
            "isMongo": false
        }
    }
}
```

### 设置 MongoDB Atlas 数据库

您需要设置 Atlas 集群，设置 Atlas 集群的步骤可以在这里找到：
- https://www.mongodb.com/basics/mongodb-atlas-tutorial

您还需要启用 Atlas dataAPI，启用 dataAPI 的步骤可以在这里找到：
- https://www.mongodb.com/docs/atlas/app-services/data-api/generated-endpoints/

### 使用多个数据源

gem5 支持使用多个数据源。资源配置的结构如下：

```json
{
    "sources": {
         "gem5-resources": {
            "dataSource": "gem5-vision",
            "database": "gem5-vision",
            "collection": "resources",
            "url": "https://data.mongodb-api.com/app/data-ejhjf/endpoint/data/v1",
            "authUrl": "https://realm.mongodb.com/api/client/v2.0/app/data-ejhjf/auth/providers/api-key/login",
            "apiKey": "OIi5bAP7xxIGK782t8ZoiD2BkBGEzMdX3upChf9zdCxHSnMoiTnjI22Yw5kOSgy9",
            "isMongo": true,
        },
        "data-source-json-1": {
            "url": "path/to/json",
            "isMongo": false,
        },
        "data-source-json-2": {
            "url": "path/to/another/json",
            "isMongo": false,
        },
        // Add more data sources as needed
    }
}
```

上面的示例显示了一个 gem5 资源配置，其中包含一个 MongoDB Atlas 数据源和 2 个 JSON 数据源。默认情况下，gem5 将创建所有指定数据源中存在的所有资源的并集。如果您要求获取多个数据源具有相同 `id` 和 `resource_version` 的资源，则会抛出错误。您还可以指定数据源的子集以从中获取资源：

```python
resource = obtain_resource("id", clients=["data-source-json-1"])
```

### 理解本地资源

本地资源，在 gem5 的上下文中，是指用户拥有并希望集成到 gem5 中但不在 gem5 资源数据库中预先存在的资源。

对于用户来说，这提供了在 gem5 中无缝使用自己资源的灵活性，无需使用 `BinaryResource(local_path=/path/to/binary)` 创建专用资源对象。相反，他们可以直接通过 `obtain_resource()` 使用这些本地资源，简化集成过程。

### 使用自定义资源配置和本地资源

在本示例中，我们将逐步介绍如何设置自定义配置并使用您自己的本地资源。为了说明，我们将使用 JSON 文件作为资源数据源。

#### 创建自定义资源数据源

让我们首先创建一个本地资源。这是一个基础资源，将作为示例。要使用 `obtain_resource()` 使用本地资源，我们的基础资源需要有一个二进制文件。这里我们使用一个名为 `fake-binary` 的空二进制文件。

**注意**：确保 Gem5 二进制文件和 `fake-binary` 具有相同的 ISA 目标（这里是 RISCV）。

接下来，让我们创建 JSON 数据源。我将文件命名为 `my-resources.json`。内容应该如下所示：

```json
[
    {
        "category": "binary",
        "id": "test-binary",
        "description": "A test binary",
        "architecture": "RISCV",
        "size": 1,
        "tags": [
            "test"
        ],
        "is_zipped": false,
        "md5sum": "6d9494d22b90d817e826b0d762fda973",
        "source": "src/simple",
        "url": "file:// path to fake_binary",
        "license": "",
        "author": [],
        "source_url": "https://github.com/gem5/gem5-resources/tree/develop/src/simple",
        "resource_version": "1.0.0",
        "gem5_versions": [
            "23.0"
        ],
        "example_usage": "obtain_resource(resource_id=\"test-binary\")"
    }
]
```

资源的 JSON 文件应遵循 [gem5 resources schema](https://resources.gem5.org/gem5-resources-schema.json)。

**注意**：虽然 `url` 字段可以是链接，但在这种情况下，我使用的是本地文件。

#### 创建您的自定义资源配置

创建一个名为 `gem5-config.json` 的文件，内容如下：

```json
{
    "sources": {
        "my-json-data-source": {
            "url": "path/to/my-resources.json",
            "isMongo": false
        }
    }
}
```

**注意**：隐含的是 isMongo = false 意味着数据源是 JSON 数据源，因为 gem5 目前仅支持 2 种类型的数据源。

#### 使用本地数据源运行 gem5

首先，使用包含 RISCV 的 ALL 构建构建 gem5：

```bash
scons build/ALL/gem5.opt -j`nproc`
```

接下来，使用我们的本地 `test-binary` 资源运行 `local-resource-example.py` 文件：

使用环境变量

```bash
GEM5_RESOURCE_JSON_APPEND=path/to/my-resources.json ./build/ALL/gem5.opt configs/example/gem5_library/local-resource-example.py --resource test-binary
```

或者您可以用我们自己的自定义配置覆盖 `gem5_default_config`：

```bash
GEM5_CONFIG=path/to/gem5-config.json ./build/ALL/gem5.opt configs/example/gem5_library/local-resource-example.py --resource test-binary
```

此命令将使用我们本地下载的资源执行 `local-resource-example.py` 脚本。此脚本只是调用 obtain_resource 函数并打印资源的本地路径。此脚本表明本地资源的功能与 gem5 资源数据库上的资源类似。
