---
layout: documentation
title: 磁盘镜像
doc: gem5art
parent: main
permalink: /documentation/gem5art/main/disks
Authors:
  - Hoa Nguyen
  - Ayaz Akram
---

# 磁盘镜像

## 简介
本节讨论创建带有 Ubuntu 服务器安装的 gem5 兼容磁盘镜像的自动化方法。我们使用 [Packer](https://www.packer.io/)，它使用 .json 模板文件来构建和配置磁盘镜像。这些模板文件可以配置为构建安装了特定基准测试的磁盘镜像。

## 使用 Packer 构建简单磁盘镜像
<a name="packerbriefly"></a>
### a. 工作原理（简要说明）
我们使用 [Packer](https://www.packer.io/) 和 [QEMU](https://www.qemu.org/) 来自动化磁盘创建过程。
本质上，QEMU 负责设置虚拟机以及在构建过程中与磁盘镜像的所有交互。
交互包括将 Ubuntu Server 安装到磁盘镜像、从您的机器复制文件到磁盘镜像，以及在安装 Ubuntu 后在磁盘镜像上运行脚本。
但是，我们不会直接使用 QEMU。
Packer 提供了一种使用 JSON 脚本与 QEMU 交互的更简单方法，这比从命令行使用 QEMU 更具表现力。
<a name="dependencies"></a>
### b. 安装所需的软件/依赖项
如果尚未安装，可以使用以下命令安装 QEMU：
```shell
sudo apt-get install qemu
```
packer 二进制文件可以从[官方网站](https://www.packer.io/downloads.html)下载。
例如，以下命令下载适用于 Linux 平台的 packer 版本 1.7.2，

```sh
wget https://releases.hashicorp.com/packer/1.7.2/packer_1.7.2_linux_amd64.zip
unzip packer_1.7.2_linux_amd64.zip
```

<a name="customizing"></a>
### c. 自定义 Packer 脚本
默认的 packer 脚本 `template.json` 应根据所需的磁盘镜像和构建过程的可用资源进行修改和调整。我们将默认模板重命名为 `[disk-name].json`。应修改的变量出现在 `[disk-name].json` 文件的末尾，在 `variables` 部分。
我们用于构建磁盘镜像的配置文件和目录结构如下所示：
```shell
disk-image/
  experiment-specific-folder/
    [disk-name].json: packer script
    Any experiment-specific post installation script

  shared/
    post-installation.sh: generic shell script that is executed after Ubuntu is installed
    preseed.cfg: pre-seeded configuration to install Ubuntu
```

<a name="customizingVM"></a>
#### i. 自定义 VM（虚拟机）
在 `[disk-name].json` 中，以下变量可用于自定义 VM（用于磁盘构建过程）：

| 变量         | 用途     | 示例  |
| ---------------- |-------------|----------|
| [vm_cpus](https://www.packer.io/docs/builders/qemu.html#cpus) **（应修改）** | VM 使用的宿主机 CPU 数量 | "2": VM 使用 2 个 CPU |
| [vm_memory](https://www.packer.io/docs/builders/qemu.html#memory) **（应修改）** | VM 使用的内存量，以兆字节为单位 | "2048": VM 使用 2 GB RAM |
| [vm_accelerator](https://www.packer.io/docs/builders/qemu.html#accelerator) **（应修改）** | VM 使用的加速器，例如 kvm | "kvm": 将使用 kvm |

<a name="customizingscripts"></a>
#### ii. 自定义磁盘镜像
在 `[disk-name].json` 中，可以使用以下变量自定义磁盘镜像大小：

| 变量        | 用途     | 示例  |
| ---------------- |-------------|----------|
| [image_size](https://www.packer.io/docs/builders/qemu.html#disk_size) **（应修改）** | 磁盘镜像的大小，以兆字节为单位 | "8192": 镜像大小为 8 GB  |
| [image_name] | 构建的磁盘镜像的名称 | "boot-exit"  |




<a name="customizingscripts2"></a>
#### iii. 文件传输
在构建磁盘镜像时，用户需要将文件（基准测试、数据集等）移动到磁盘镜像。
为了进行此文件传输，在 `[disk-name].json` 的 `provisioners` 下，您可以添加以下内容：

```shell
{
    "type": "file",
    "source": "shared/post_installation.sh",
    "destination": "/home/gem5/",
    "direction": "upload"
}
```
上面的示例将文件 `shared/post_installation.sh` 从宿主机复制到磁盘镜像中的 `/home/gem5/`。
此方法还能够将文件夹从宿主机复制到磁盘镜像，反之亦然。
重要的是要注意尾随斜杠会影响复制过程 [（更多详细信息）](https://www.packer.io/docs/provisioners/file.html#directory-uploads)。
以下是在路径末尾使用斜杠的效果的一些值得注意的示例。

| `source`        | `destination`     | `direction`  |  `Effect`  |
| ---------------- |-------------|----------|-----|
| `foo.txt` | `/home/gem5/bar.txt` | `upload` | 将文件（宿主机）复制到文件（镜像） |
| `foo.txt` | `bar/` | `upload` | 将文件（宿主机）复制到文件夹（镜像） |
| `/foo` | `/tmp` | `upload` | `mkdir /tmp/foo` (镜像);  `cp -r /foo/* (宿主机) /tmp/foo/ (镜像)`; |
| `/foo/` | `/tmp` | `upload` | `cp -r /foo/* (宿主机) /tmp/ (镜像)` |

如果 `direction` 是 `download`，文件将从镜像复制到宿主机。
**注意**：[这是在安装 Ubuntu 后运行脚本而不复制到磁盘镜像的一种方法](#customizingscripts3)。

<a name="customizingscripts3"></a>
#### iv. 安装基准测试依赖项
为了安装依赖项，我们使用 bash 脚本 `shared/post_installation.sh`，该脚本将在 Ubuntu 安装和文件复制完成后运行。
例如，如果我们想安装 `gfortran`，请在 `scripts/post_installation.sh` 中添加以下内容：
```shell
echo '12345' | sudo apt-get install gfortran;
```
在上面的示例中，我们假设用户密码是 `12345`。
这本质上是一个在文件复制完成后在 VM 上执行的 bash 脚本，您可以修改脚本作为 bash 脚本以适应任何目的。
<a name="customizingscripts4"></a>
#### v. 在磁盘镜像上运行其他脚本
在 `[disk-name].json` 中，我们可以向 `provisioners` 添加更多脚本。
请注意，文件在宿主机上，但效果在磁盘镜像上。
例如，以下示例在安装 Ubuntu 后运行 `shared/post_installation.sh`，

{% raw %}
```shell
{
    "type": "shell",
    "execute_command": "echo '{{ user `ssh_password` }}' | {{.Vars}} sudo -E -S bash '{{.Path}}'",
    "scripts":
    [
        "scripts/post-installation.sh"
    ]
}
```
{% endraw %}

<a name="buildsimple"></a>
### d. 构建磁盘镜像
<a name="simplebuild"></a>
#### i. 构建磁盘镜像
为了构建磁盘镜像，首先使用以下命令验证模板文件：
```sh
./packer validate [disk-name].json
```
然后，可以使用模板文件构建磁盘镜像：
```sh
./packer build [disk-name].json
```

在相当新的机器上，构建过程应该不会超过 15 分钟。
具有用户定义名称（image_name）的磁盘镜像将在名为 [image_name]-image 的文件夹中生成。
[我们建议使用 VNC 查看器来检查构建过程](#inspect)。
<a name="inspect"></a>
#### ii. 检查构建过程
在磁盘镜像的构建过程进行时，packer 将运行 VNC（虚拟网络计算）服务器，您可以通过从 VNC 客户端连接到 VNC 服务器来查看构建过程。VNC 客户端有很多选择。当您运行 packer 脚本时，它会告诉您 VNC 服务器使用哪个端口。例如，如果它显示 `qemu: Connecting to VM via VNC (127.0.0.1:5932)`，则 VNC 端口是 5932。
要从 VNC 客户端连接到 VNC 服务器，对于端口号 5932，使用地址 `127.0.0.1:5932`。
如果您需要端口转发以将 VNC 端口从远程机器转发到本地机器，请使用 SSH 隧道
```shell
ssh -L 5932:127.0.0.1:5932 <username>@<host>
```
此命令将端口 5932 从宿主机转发到您的机器，然后您将能够从 VNC 查看器使用地址 `127.0.0.1:5932` 连接到 VNC 服务器。

**注意**：当 packer 正在安装 Ubuntu 时，终端屏幕将长时间显示"waiting for SSH"而没有任何更新。
这不是 Ubuntu 安装是否产生任何错误的指示。
因此，我们强烈建议至少使用一次 VNC 查看器来检查镜像构建过程。
<a name="checking"></a>
