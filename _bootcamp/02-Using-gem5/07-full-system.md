---
layout: bootcamp
title: gem5 中的全系统模拟
permalink: /bootcamp/using-gem5/full-system
section: using-gem5
excerpt_separator: "<!--more-->"
---
{% raw %}
<!-- _class: title -->

## gem5 中的全系统模拟

---

## 我们将介绍的内容

- 什么是全系统模拟？
- 在 gem5 中启动真实系统的基础知识
- 使用 Packer 和 QEMU 创建磁盘镜像
- 扩展/修改 gem5 磁盘镜像
- 使用 m5term 与运行中的系统交互

---

## 什么是全系统模拟？

全系统模拟是一种模拟完整计算机系统的仿真类型，包括 CPU、内存、I/O 设备以及操作系统等系统软件。

它允许对硬件和软件交互进行详细分析和调试。

**模拟的组件**：

- CPU（多种类型和配置）
- 内存层次结构（缓存、主内存）
- I/O 设备（磁盘、网络接口）
- 完整的软件栈（操作系统、驱动程序、应用程序）

---

## 在 gem5 中启动真实系统的基础知识

**概述**：gem5 可以模拟真实系统的启动过程，提供对启动期间硬件和软件行为的深入洞察。

### 涉及的步骤

1. **设置模拟环境**：
    - 选择 ISA（例如，x86、ARM）。
    - 配置系统组件（CPU、内存、缓存）。
2. **获取正确的资源，如内核、引导加载程序、磁盘镜像等。**
3. **配置启动参数**：
    - 如有必要，设置内核命令行参数。
4. **运行模拟**：
    - 启动模拟并监控启动过程。

---

## 让我们在 gem5 中运行全系统模拟

不完整的代码已经构建了一个板子。

让我们在 gem5 中运行全系统工作负载。

这个工作负载是 Ubuntu 24.04 启动。它将在以下三个时间点触发 m5 退出：

- 内核启动完成
- 当 `after_boot.sh` 运行时
- 运行脚本执行后

---

## 获取工作负载并设置退出事件

要设置工作负载，我们将以下内容添加到
[materials/02-Using-gem5/07-full-system/x86-fs-kvm-run.py](https://github.com/gem5bootcamp/2024/blob/main/materials/02-Using-gem5/07-full-system/x86-fs-kvm-run.py)：

```python
workload = obtain_resource("x86-ubuntu-24.04-boot-with-systemd", resource_version="1.0.0")
board.set_workload(workload)
```

---

<!-- _class: code-80-percent -->

## 获取工作负载并设置退出事件（续）

让我们创建退出事件处理器，并将其设置到我们的模拟器对象中。

```python
def exit_event_handler():
    print("first exit event: Kernel booted")
    yield False
    print("second exit event: In after boot")
    yield False
    print("third exit event: After run script")
    yield True

simulator = Simulator(
    board=board,
    on_exit_event={
        ExitEvent.EXIT: exit_event_handler(),
    },
)
simulator.run()
```

---

## 使用 m5term 查看终端/串口输出

在启动此工作负载之前，让我们构建 `m5term` 应用程序，以便我们可以连接到正在运行的系统。

```bash
cd /workspaces/2024/gem5/util/term
make
```

现在您有了一个 `m5term` 二进制文件。

---

## 查看 gem5 的输出

现在，让我们运行工作负载并使用 `m5term` 连接到磁盘镜像启动的终端。

使用以下命令运行 gem5：

```bash
gem5 x86-fs-kvm-run.py
```

在另一个终端窗口中，运行以下命令以连接到磁盘镜像启动的终端：

```bash
m5term 3456
```

3456 是终端运行的端口号。
您将在 gem5 输出中看到此信息。

如果您运行多个 gem5 实例，它们将具有连续的端口号。
如果您在非交互式环境中运行，将没有端口可以连接。

---

<!-- _class: start -->

## 创建您自己的磁盘镜像

---

## 使用 Packer 和 QEMU 创建磁盘镜像

为了创建一个可以在 gem5 中使用的通用 Ubuntu 磁盘镜像，我们将使用：

- Packer：这将自动化磁盘镜像创建过程。
- QEMU：我们将在 Packer 中使用 QEMU 插件来实际创建磁盘镜像。
- Ubuntu autoinstall：我们将使用 autoinstall 来自动化 Ubuntu 安装过程。

gem5 resources 已经有代码可以使用上述方法创建通用 Ubuntu 镜像。

- 代码路径：[`gem5-resources/src/x86-ubuntu`](https://github.com/gem5/gem5-resources/blob/stable/src/x86-ubuntu)

让我们浏览创建过程的重要部分。

---

## 获取 ISO 和 user-data 文件

由于我们使用 Ubuntu autoinstall，我们需要一个实时服务器安装 ISO。

- 这可以从 Ubuntu 网站在线找到：[iso](https://releases.ubuntu.com/noble/)

我们还需要 user-data 文件，它将告诉 Ubuntu autoinstall 如何安装 Ubuntu。

- gem5-resources 上的 user-data 文件指定了所有默认选项，采用最小服务器安装。

---

## 如何获取我们自己的 user-data 文件

要从头开始获取 user-data 文件，您需要在机器上安装 Ubuntu。

- 安装后，我们可以在系统首次重启后从 `/var/log/installer/autoinstall-user-data` 检索 `autoinstall-user-data`。

您可以在自己的 VM 上安装 Ubuntu 并获取 user-data 文件。

---

## 使用 QEMU 获取 user-data 文件

我们也可以使用 QEMU 安装 Ubuntu 并获取上述文件。

- 首先，我们需要使用以下命令在 QEMU 中创建一个空磁盘镜像：`qemu-img create -f raw ubuntu-22.04.2.raw 5G`
- 然后我们使用 QEMU 启动磁盘镜像：

```bash
qemu-system-x86_64 -m 2G \
      -cdrom ubuntu-22.04.2-live-server-amd64.iso \
      -boot d -drive file=ubuntu-22.04.2.raw,format=raw \
      -enable-kvm -cpu host -smp 2 -net nic \
      -net user,hostfwd=tcp::2222-:22
```

安装 Ubuntu 后，我们可以使用 ssh 获取 user-data 文件。

---

## Packer 脚本的重要部分

让我们浏览 Packer 文件。

- **bootcommand**：

  ```hcl
  "e<wait>",
  "<down><down><down>",
  "<end><bs><bs><bs><bs><wait>",
  "autoinstall  ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
  "<f10><wait>"
  ```

  此启动命令打开 GRUB 菜单以编辑启动命令，然后删除 `---` 并添加 autoinstall 命令。

- **http_directory**：此目录指向包含 user-data 文件和一个名为 meta-data 的空文件的目录。这些文件用于安装 Ubuntu。

---

## Packer 脚本的重要部分（续）

- **qemu_args**：我们需要向 Packer 提供我们将用于启动镜像的 QEMU 参数。
  - 例如，Packer 脚本将使用的 QEMU 命令将是：

  ```bash
  qemu-system-x86_64 -vnc 127.0.0.1:32 -m 8192M \
  -device virtio-net,netdev=user.0 -cpu host \
  -display none -boot c -smp 4 \
  -drive file=<Path/to/image>,cache=writeback,discard=ignore,format=raw \
  -machine type=pc,accel=kvm -netdev user,id=user.0,hostfwd=tcp::3873-:22
  ```

- **File provisioners**：这些命令允许我们将文件从主机移动到 QEMU 镜像。

- **Shell provisioner**：这允许我们运行可以执行后安装命令的 bash 脚本。

---

<!-- _class: no-logo -->

## 让我们使用基础 Ubuntu 镜像创建包含 GAPBS 基准测试的磁盘镜像

更新 [x86-ubuntu.pkr.hcl](https://github.com/gem5bootcamp/2024/blob/main/materials/02-Using-gem5/07-full-system/x86-ubuntu-gapbs/x86-ubuntu.pkr.hcl) 文件。

Packer 文件的一般结构将相同，但有一些关键更改：

- 我们现在将在 `source "qemu" "initialize"` 块中添加一个参数。
  - `diskimage = true`：这将让 Packer 知道我们使用的是基础磁盘镜像，而不是我们将从中安装 Ubuntu 的 iso。
- 删除 `http_directory   = "http"` 目录，因为我们不再需要使用 autoinstall。
- 将 `iso_checksum` 和 `iso_urls` 更改为我们的基础镜像。

    让我们从 gem5 resources 获取基础 Ubuntu 24.04 镜像并解压缩它。

    ```bash
    wget https://storage.googleapis.com/dist.gem5.org/dist/develop/images/x86/ubuntu-24-04/x86-ubuntu-24-04.gz
    gzip -d x86-ubuntu-24-04.gz
    ```

---

<!-- _class: code-80-percent  -->

`iso_checksum` 是我们正在使用的 iso 文件的 `sha256sum`。要获取 `sha256sum`，请在 linux 终端中运行以下命令。

```bash
sha256sum ./x86-ubuntu-24-04.gz
```


- **更新文件和 shell provisioners：** 让我们删除文件 provisioners，因为我们不需要再次传输文件。
- **启动命令：** 由于我们不安装 Ubuntu，我们可以编写登录命令以及我们需要的任何其他命令（例如，设置网络或 ssh）。让我们更新启动命令以登录并启用网络：

```hcl
"<wait30>",
"gem5<enter><wait>",
"12345<enter><wait>",
"sudo mv /etc/netplan/50-cloud-init.yaml.bak /etc/netplan/50-cloud-init.yaml<enter><wait>",
"12345<enter><wait>",
"sudo netplan apply<enter><wait>",
"<wait>"
```

---

## 对后安装脚本的更改

对于此后安装脚本，我们需要获取依赖项并构建 GAPBS 基准测试。

将此添加到 [post-installation.sh](https://github.com/gem5bootcamp/2024/blob/main/materials/02-Using-gem5/07-full-system/x86-ubuntu-gapbs/scripts/post-installation.sh) 脚本

```bash
git clone https://github.com/sbeamer/gapbs
cd gapbs
make
```

让我们运行 Packer 脚本并在 gem5 中使用此磁盘镜像！

```bash
cd /workspaces/2024/materials/02-Using-gem5/07-full-system
x86-ubuntu-gapbs/build.sh
```
---

## 让我们在 gem5 中使用我们构建的磁盘镜像

让我们将 md5sum 和路径添加到我们的 [local JSON ](https://github.com/gem5bootcamp/2024/blob/main/materials/02-Using-gem5/07-full-system/completed/local-gapbs-resource.json)。

让我们运行 [gem5 GAPBS config](https://github.com/gem5bootcamp/2024/blob/main/materials/02-Using-gem5/07-full-system/completed/x86-fs-gapbs-kvm-run.py)。

```bash
GEM5_RESOURCE_JSON_APPEND=./completed/local-gapbs-resource.json gem5 x86-fs-gapbs-kvm-run.py
```

此脚本应该运行 bfs 基准测试。

---

## 让我们看看如何使用 m5term 访问终端

- 我们将运行相同的 [gem5 GAPBS config](https://github.com/gem5bootcamp/2024/blob/main/materials/02-Using-gem5/07-full-system/x86-fs-gapbs-kvm-run.py)，但有一个小更改。

让我们将最后一个 `yield True` 更改为 `yield False`，这样模拟就不会退出，我们可以访问模拟。

```python
def exit_event_handler():
    print("first exit event: Kernel booted")
    yield False
    print("second exit event: In after boot")
    yield False
    print("third exit event: After run script")
    yield False
```

---

## 再次，让我们使用 m5term

现在让我们使用 `m5term` 二进制文件连接到我们的模拟

```bash
m5term 3456
```

{% endraw %}
