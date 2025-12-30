---
layout: documentation
title: gem5 中的本地资源支持
parent: gem5-standard-library
doc: gem5 documentation
permalink: /documentation/gem5-stdlib/local-resources-support
author: Kunal Pai, Harshil Patel
---

本教程将引导您完成在 gem5 中创建 WorkloadResource 并测试它的过程，通过 gem5 v23.0 中引入的新 gem5 Resources 基础设施。

工作负载通过以下行设置到 gem5 中的开发板：

``` python
board.set_workload(obtain_resource(<ID_OF_WORKLOAD>))
```

下图显示了资源 ID 是什么，如 [gem5 Resources 网站](https://resources.gem5.org/) 上所示：
![gem5 资源 ID 示例](/assets/img/stdlib/gem5-resource-id-example.png)

因此，ID 为 '<ID_OF_WORKLOAD>' 的 WorkloadResource 将被解析，并将用于构造它定义的函数调用。

然后在开发板上执行 Workload JSON 的 `"function"` 字段中指定的函数调用，以及它在 `"additional_parameters"` 字段中定义的任何参数。

## 简介

gem5 Resources 基础设施允许添加本地 JSON 数据源，可以将其添加到主 gem5 Resources MongoDB 数据库。

我们将使用本地 JSON 数据源向 gem5 添加新的 WorkloadResource。

## 先决条件

本教程假设您已经有一个预编译的资源，您想将其制作为 WorkloadResource。

## 定义工作负载

### 定义资源 JSON

第一步是定义在 WorkloadResource 中使用的资源。
如果资源已存在于 gem5 中，您可以跳过此步骤。
让我们假设我们想要包装在 WorkloadResource 中的资源是为 `RISC-V` 编译的，分类为 `binary`，名称为 `my-benchmark`。

我们可以在 JSON 对象中定义此资源，如下所示：

``` json
{
    "category": "binary",
    "id": "my-benchmark",
    "description": "A RISCV binary used to test a specific RISCV instruction.",
    "architecture": "RISCV",
    "is_zipped": false,
    "resource_version": "1.0.0",
    "gem5_versions": [
        "23.0"
    ],
}
```

正确初始化此处的所有字段很重要，因为 gem5 使用它们来初始化和运行资源。

要查看资源所需和不需要的字段的更多信息，请参阅 [gem5 Resources JSON Schema](https://github.com/gem5/gem5-resources-website/blob/main/public/gem5-resources-schema.json)。

### 定义工作负载 JSON

假设资源的二进制文件已上传到 gem5 Resources 云，其源代码在 [gem5-resources GitHub 仓库](https://github.com/gem5/gem5-resources/) 上可用，并且资源在 [gem5 Resources 网站](https://resources.gem5.org) 上可见，您现在可以定义工作负载 JSON。
让我们假设我们正在构建的 WorkloadResource 包装了 `my-benchmark`，并称为 `binary-workload`。

我们可以在本地 JSON 文件中定义此 WorkloadResource，如下所示：

``` json
{
    "id": "binary-workload",
    "category": "workload",
    "description": "A RISCV binary used to test a specific RISCV instruction.",
    "architecture": "RISCV",
    "function": "set_se_binary_workload",
    "resource_version": "1.0.0",
    "gem5_versions": [
        "23.0"
    ],
    "resources": {
        "binary": "my-benchmark"
    },
    "additional_parameters": {
        "arguments": ["arg1", "arg2"]
    }
}
```

`"function"` 字段定义将在开发板上调用的函数。
`"resources"` 字段定义将传递到工作负载的资源。
`"additional_parameters"` 字段定义将传递到 WorkloadResource 的附加参数。
因此，上面定义的 WorkloadResource 等效于以下代码行：

``` python
board.set_se_binary_workload(binary = obtain_resource("binary_resource"), arguments = ["arg1", "arg2"])
```

要查看工作负载所需和不需要的字段的更多信息，请参阅 [gem5 Resources JSON Schema](https://github.com/gem5/gem5-resources-website/blob/main/public/gem5-resources-schema.json)

## 测试工作负载

要测试 WorkloadResource，我们首先必须将本地 JSON 文件添加为 gem5 的数据源。

这可以通过创建具有以下格式的新 JSON 文件来完成：

``` json
{
    "sources": {
        "my-resources": {
            "url": "<PATH_TO_JSON_FILE>",
            "isMongo": false,
        }
    }
}
```
在运行 gem5 时，如果您创建的新 JSON 配置文件存在于当前工作目录中，它将用作 gem5 的数据源。
如果 JSON 文件不在当前工作目录中，您可以在构建 gem5 时使用 `GEM5_CONFIG` 标志指定 JSON 文件的路径。

您现在应该能够通过其名称 `binary-workload` 在模拟中使用 WorkloadResource。

**注意**：为了检查您指定为 WorkloadResource 一部分的资源是否正确传递到 WorkloadResource，您可以使用 WorkloadResource 类中的 `get_parameters()` 函数。
此函数返回传递到 WorkloadResource 的资源的字典。
其实现可以在 [`src/python/gem5/resources/resource.py`](https://github.com/gem5/gem5/blob/6f5d877b1aacd551749dafa87da26600a4f01155/src/python/gem5/resources/resource.py#L673) 找到。

从 gem5 v23.1 开始，有几种额外的方法来定义本地 `resources.json` 文件。
这两种方法都通过环境变量，并在运行 gem5 模拟时通过命令行定义。

1. `GEM5_RESOURCE_JSON` 变量：此变量用通过此变量传入的路径中存在的 JSON 文件替换 gem5 使用的所有当前数据源。
这等效于如下所示的 gem5 数据源配置文件：

    ``` json
    {
        "sources": {
            "my-resources": {
                "url": $GEM5_RESOURCE_JSON,
                "isMongo": false,
            }
        }
    }
    ```

2. `GEM5_RESOURCE_JSON_APPEND` 变量：此变量将通过此变量传入的路径中存在的 JSON 文件添加到 gem5 使用的所有当前数据源。
这等效于如下所示的 gem5 数据源配置文件：

    ``` json
    {
        "sources": {
            "my-resources-1": {
                "url": '/local/local.json',
                "isMongo": false,
            },
                    "my-resources-2": {
                "url": $GEM5_RESOURCE_JSON_APPEND,
                "isMongo": false,
            },
        }
    }
    ```

## 对资源本地路径的支持

从 gem5 v23.1 开始，已添加支持，通过上述方法创建本地资源的工作负载。

此方法涉及创建与[定义资源 JSON](#defining-the-resource-json) 中提到的相同的 JSON 对象，并添加 "url" 字段。
此字段在 gem5 Resources 数据库中用于指示资源文件的位置。
从 gem5 v23.1 开始，此字段还接受 _file_ URI 方案。
您可以指定本地主机上的路径，gem5 将能够运行它。

通过这些更改，`my-benchmark` 的本地实例的 JSON 对象将如下所示：

``` json
{
    "category": "binary",
    "id": "my-benchmark",
    "description": "A RISCV binary used to test a specific RISCV instruction.",
		"url": "file:/<PATH_TO_LOCAL_FILE>",
    "architecture": "RISCV",
    "is_zipped": false,
    "resource_version": "1.1.0",
    "gem5_versions": [
        "23.0"
    ],
}
```

**注意**：如果您正在创建 ID 存在于 gem5 Resources 中的资源的本地版本，请确保将 `"resource_version"` 字段更改为 gem5 Resources 数据库中不存在的资源版本，以避免在运行 gem5 模拟时收到错误。
