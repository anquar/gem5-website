---
layout: toc
title: "客户机二进制文件"
permalink: /documentation/general_docs/fullsystem/guest_binaries
author: Giacomo Travaglini
---
* TOC
{:toc}

我们提供一组有用的预构建二进制文件，用户可以下载（如果他们不想
从头重新编译它们）。

有两种下载方式：

* 通过手动下载
* 通过 Google Cloud Utilities

## 手动下载

以下是通过单击链接即可下载的预构建二进制文件列表：

### Arm FS 二进制文件

##### 最新 Linux 内核镜像 / 引导加载程序（**推荐**）

下面的压缩包包含一组二进制文件：Linux 内核和一组引导加载程序

* <http://dist.gem5.org/dist/v22-0/arm/aarch-system-20220707.tar.bz2>

##### 最新 Linux 磁盘镜像（**推荐**）

* <http://dist.gem5.org/dist/v22-0/arm/disks/ubuntu-18.04-arm64-docker.img.bz2>

  分区表：是

  gem5 init：
  * 默认（使用 m5 ops）：`/init.gem5`
  * kvm（使用 m5 --addr ops）：`/init.addr.gem5`
  * fast models（使用 m5 --semi ops）：`/init.semi.gem5`

* <http://dist.gem5.org/dist/v22-0/arm/disks/aarch32-ubuntu-natty-headless.img.bz2>

##### 旧版 Linux 内核/磁盘镜像

这些镜像不受支持。如果您遇到问题，我们会尽力提供帮助，但不能保证这些镜像与最新版本的 gem5 兼容。

###### 仅磁盘镜像

* <http://dist.gem5.org/dist/current/arm/disks/aarch64-ubuntu-trusty-headless.img.bz2>
* <http://dist.gem5.org/dist/current/arm/disks/linaro-minimal-aarch64.img.bz2>
* <http://dist.gem5.org/dist/current/arm/disks/linux-aarch32-ael.img.bz2>

###### 磁盘和内核镜像

* <http://dist.gem5.org/dist/current/arm/aarch-system-20170616.tar.xz>
* <http://dist.gem5.org/dist/current/arm/aarch-system-20180409.tar.xz>
* <http://dist.gem5.org/dist/current/arm/arm-system-dacapo-2011-08.tgz>
* <http://dist.gem5.org/dist/current/arm/arm-system.tar.bz2>
* <http://dist.gem5.org/dist/current/arm/arm64-system-02-2014.tgz>
* <http://dist.gem5.org/dist/current/arm/kitkat-overlay.tar.bz2>
* <http://dist.gem5.org/dist/current/arm/linux-arm-arch.tar.bz2>
* <http://dist.gem5.org/dist/current/arm/vmlinux-emm-pcie-3.3.tar.bz2>
* <http://dist.gem5.org/dist/current/arm/vmlinux.arm.smp.fb.3.2.tar.gz>

## Google Cloud Utilities (gsutil)

gsutil 是一个 Python 应用程序，允许您从命令行访问云存储。
请查看以下文档，它将指导您完成
安装该实用程序的过程

* [gsutil 工具](https://cloud.google.com/storage/docs/gsutil)

安装后（注意：它要求您提供有效的 Google 帐户），可以通过以下命令行检查/下载 gem5 二进制文件。

```
gsutil cp -r gs://dist.gem5.org/dist/<binary>
```
