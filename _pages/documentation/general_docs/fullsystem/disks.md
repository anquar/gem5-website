---
layout: documentation
title: 创建磁盘镜像
doc: gem5 documentation
parent: fullsystem
permalink: documentation/general_docs/fullsystem/disks
---

# 为全系统模式创建磁盘镜像

在全系统模式下，gem5 依赖于安装了操作系统的磁盘镜像来运行模拟。
gem5 中的磁盘设备从磁盘镜像获取其初始内容。
磁盘镜像文件存储磁盘上存在的所有字节，就像您在实际设备上找到的那样。
其他一些系统也使用更复杂格式的磁盘镜像，这些格式提供压缩、加密等功能。gem5 目前仅支持原始镜像，因此如果您有其中一种其他格式的镜像，在使用它进行模拟之前，必须将其转换为原始镜像。
通常有可用的工具可以在不同格式之间进行转换。

有多种创建可用于 gem5 的磁盘镜像的方法。
以下是构建磁盘镜像的四种不同方法：

- 使用 gem5 工具创建磁盘镜像
- 使用 gem5 工具和 chroot 创建磁盘镜像
- 使用 QEMU 创建磁盘镜像
- 使用 Packer 创建磁盘镜像

所有这些方法彼此独立。
接下来，我们将逐一讨论这些方法。

## 1) 使用 gem5 工具创建磁盘镜像

```md
免责声明：这来自旧网站，此方法中的某些内容可能已过时。

```
因为磁盘镜像表示磁盘本身上的所有字节，所以它包含的不仅仅是文件系统。
对于大多数系统上的硬盘驱动器，镜像以分区表开头。
表中的每个分区（通常只有一个）也在镜像中。
如果您想操作整个磁盘，您将使用整个镜像，但如果您只想处理一个分区和/或其中的文件系统，您需要专门选择镜像的那部分。
losetup 命令（下面讨论）有一个 -o 选项，可让您指定在镜像中从哪里开始。

<iframe width="560" height="315" src="https://www.youtube.com/embed/Oh3NK12fnbg" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe><div class='thumbcaption'>在 Ubuntu 12.04 64 位上使用 qemu 处理镜像文件的 YouTube 视频。视频分辨率可以设置为 1080</div>


### 创建空镜像

您可以使用 gem5 提供的 ./util/gem5img.py 脚本来构建磁盘镜像。
了解如何构建镜像是个好主意，以防出现问题或您需要以不寻常的方式执行某些操作。
但是，在此方法中，我们使用 gem5img.py 脚本来完成构建和格式化镜像的过程。
如果您想了解它在做什么，请参见下文。
运行 gem5img.py 可能需要您输入 sudo 密码。
*您永远不应该以 root 用户身份运行您不理解的命令！您应该查看文件 util/gem5img.py 并确保它不会对您的计算机执行任何恶意操作！*

您可以使用 gem5img.py 的 "init" 选项创建空镜像，"new"、"partition" 或 "format" 来独立执行 init 的这些部分，以及 "mount" 或 "umount" 来挂载或卸载现有镜像。

### 挂载镜像

要在镜像文件上挂载文件系统，首先找到回环设备，并使用适当的偏移量将其附加到镜像，如[格式化](#formatting)部分中进一步描述。

```sh
mount -o loop,offset=32256 foo.img
```

<iframe width="560" height="315" src="https://www.youtube.com/embed/OXH1oxQbuHA" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe><div class='thumbcaption'>在 Ubuntu 12.04 64 位上使用 mount 添加文件的 YouTube 视频。视频分辨率可以设置为 1080</div>

### 卸载

要卸载镜像，请像往常一样使用 umount 命令。

```sh
umount
```

### 镜像内容

现在您可以创建镜像文件并挂载其文件系统，您会想要在其中实际放置一些文件。
您可以自由使用任何您想要的文件，但 gem5 开发人员发现 Gentoo stage3 压缩包是一个很好的起点。
它们本质上是一个几乎可启动且相当最小的 Linux 安装，可用于多种架构。

如果您选择使用 Gentoo 压缩包，首先将其解压到挂载的镜像中。
/etc/fstab 文件将包含 root、boot 和 swap 设备的占位符条目。
您需要适当地更新此文件，删除您不打算使用的任何条目（例如，boot 分区）。
接下来，您需要修改 inittab 文件，以便它使用 m5 实用程序（在其他地方描述）读取主机提供的 init 脚本并运行它。
如果您允许正常的 init 脚本运行，您感兴趣的工作负载可能需要更长的时间才能启动，您将无法注入自己的 init 脚本来动态控制启动哪些基准测试，例如，您必须通过模拟终端与模拟交互，这会引入非确定性。

#### 修改

默认情况下，gem5 不会将磁盘的修改存储回底层镜像文件。
您所做的任何更改都将存储在中间 COW 层中，并在模拟结束时丢弃。
如果您想修改底层磁盘，可以关闭 COW 层。

#### 内核和引导加载程序

此外，一般来说，gem5 跳过引导的引导加载程序部分，并将内核加载到模拟内存本身。这意味着不需要在磁盘镜像上安装像 grub 这样的引导加载程序，并且您也不必将要从中引导的内核放在镜像上。
内核是单独提供的，可以轻松更换，而无需修改磁盘镜像。

### 使用回环设备操作镜像

#### 回环设备

Linux 支持回环设备，这些设备由文件支持。
通过将其中一个附加到您的磁盘镜像，您可以在其上使用通常在真实磁盘设备上运行的标准 Linux 命令。
您可以使用带有 "loop" 选项的 mount 命令来设置回环设备并将其挂载到某处。
不幸的是，您无法指定镜像中的偏移量，因此这仅对文件系统镜像有用，而不是您需要的磁盘镜像。
但是，您可以使用较低级别的 losetup 命令自己设置回环设备并提供适当的偏移量。
完成后，您可以像在磁盘分区上一样使用 mount 命令，格式化它等。
如果您不提供偏移量，回环设备将引用整个镜像，您可以使用您喜欢的程序在其上设置分区。

### 处理镜像文件

要从头创建空镜像，您需要创建文件本身，对其进行分区，并使用文件系统格式化（其中一个）分区。

#### 创建实际文件

首先，决定您希望镜像有多大。
最好使其足够大以容纳您知道需要的所有内容，再加上一些缓冲空间。
如果您后来发现它太小，您将必须创建一个新的更大的镜像并移动所有内容。
如果您把它做得太大，您将不必要地占用实际磁盘空间，并使镜像更难处理。
一旦您决定了大小，您将想要实际创建文件。
基本上，您需要做的就是创建一个特定大小的文件，其中充满零。
一种方法是使用 dd 命令从 /dev/zero 复制正确数量的字节到新文件。
或者，您可以创建文件，在其中查找到最后一个字节，并写入一个零字节。
您跳过的所有空间将成为文件的一部分，并定义为读取为零，但因为您没有在那里显式写入任何数据，大多数文件系统足够智能，不会实际将其存储到磁盘。
您可以用这种方式创建大镜像，但在物理磁盘上占用很少的空间。
一旦您稍后开始写入文件，这将改变，并且如果您不小心，复制文件可能会将其扩展到完整大小。

#### 分区

首先，使用带有 -f 选项的 losetup 命令找到可用的回环设备。

```sh
losetup -f
```

接下来，使用 losetup 将该设备附加到您的镜像。
如果可用设备是 /dev/loop0 并且您的镜像是 foo.img，您将使用如下命令。

```sh
losetup /dev/loop0 foo.img
```

/dev/loop0（或您正在使用的任何其他设备）现在将引用您的整个镜像文件。
使用您喜欢的任何分区程序在其上设置一个（或多个）分区。
为简单起见，可能最好只创建一个占用整个镜像的分区。
我们说它占用整个镜像，但实际上它占用除文件开头的分区表本身之外的所有空间，以及之后可能为 DOS/引导加载程序兼容性而浪费的一些空间。

从现在开始，我们将使用我们创建的新分区而不是整个磁盘，因此我们将使用 losetup 的 -d 选项释放回环设备

```sh
losetup -d /dev/loop0
```

#### 格式化

首先，像我们在上面的分区步骤中那样，使用 losetup 的 -f 选项找到可用的回环设备。

```sh
losetup -f
```

我们将再次将镜像附加到该设备，但这次我们只想引用我们要在其上放置文件系统的分区。
对于 PC 和 Alpha 系统，该分区通常在一个磁道内，其中一个磁道是 63 个扇区，每个扇区是 512 字节，或 63 * 512 = 32256 字节。
您的正确值可能不同，取决于镜像的几何形状和布局。
无论如何，您应该使用 -o 选项设置回环设备，以便它表示您感兴趣的分区。

```sh
losetup -o 32256 /dev/loop0 foo.img
```

接下来，使用适当的格式化命令（通常是 mke2fs）在分区上放置文件系统。

```sh
mke2fs /dev/loop0
```

您现在已成功创建空镜像文件。
如果您打算继续使用它（可能因为它仍然是空的），可以保留回环设备附加到它，或使用 losetup -d 清理它。

```sh
losetup -d /dev/loop0
```

不要忘记使用 losetup -d 命令清理附加到镜像的回环设备。

```sh
losetup -d /dev/loop0
```

## 2) 使用 gem5 工具和 chroot 创建磁盘镜像

本节中的讨论假设您已经检出 gem5 版本并可以在全系统模式下构建和运行 gem5。
我们将在本讨论中使用 x86 ISA，这也主要适用于其他 ISA。

### 创建空白磁盘镜像

第一步是创建空白磁盘镜像（通常是 .img 文件）。
这与我们在第一种方法中所做的类似。
我们可以使用 gem5 开发人员提供的 gem5img.py 脚本。
要创建空白磁盘镜像（默认格式化为 ext2），只需运行以下命令。

```
> util/gem5img.py init ubuntu-14.04.img 4096
```

此命令创建一个名为 "ubuntu-14.04.img" 的新镜像，大小为 4096 MB。
如果您没有创建回环设备的权限，此命令可能要求您输入 sudo 密码。
*您永远不应该以 root 用户身份运行您不理解的命令！您应该查看文件 util/gem5img.py 并确保它不会对您的计算机执行任何恶意操作！*

我们将在本节中大量使用 util/gem5img.py，因此您可能想更好地了解它。
如果您只运行 `util/gem5img.py`，它会显示所有可能的命令。

```
Usage: %s [command] <command arguments>
where [command] is one of
    init: Create an image with an empty file system.
    mount: Mount the first partition in the disk image.
    umount: Unmount the first partition in the disk image.
    new: File creation part of "init".
    partition: Partition part of "init".
    format: Formatting part of "init".
Watch for orphaned loopback devices and delete them with
losetup -d. Mounted images will belong to root, so you may need
to use sudo to modify their contents
```

### 将根文件复制到磁盘

现在我们已经创建了空白磁盘，我们需要用所有操作系统文件填充它。
Ubuntu 专门为此目的分发一组文件。
您可以在 <http://cdimage.ubuntu.com/releases/14.04/release/> 找到 14.04 的 [Ubuntu core](https://wiki.ubuntu.com/Core) 发行版。由于我们正在模拟 x86 机器，我们将使用 `ubuntu-core-14.04-core-amd64.tar.gz`。
下载适合您正在模拟的系统的任何镜像。

接下来，我们需要挂载空白磁盘并将所有文件复制到磁盘上。

```
mkdir mnt
../../util/gem5img.py mount ubuntu-14.04.img mnt
wget http://cdimage.ubuntu.com/ubuntu-core/releases/14.04/release/ubuntu-core-14.04-core-amd64.tar.gz
sudo tar xzvf ubuntu-core-14.04-core-amd64.tar.gz -C mnt
```

下一步是从您的工作系统复制一些必需的文件到磁盘，以便我们可以 chroot 到新磁盘。我们需要将 `/etc/resolv.conf` 复制到新磁盘。

```
sudo cp /etc/resolv.conf mnt/etc/
```

### 设置 gem5 特定文件

#### 创建串行终端

默认情况下，gem5 使用串行端口允许从主机系统到模拟系统的通信。要使用此功能，我们需要创建串行 tty。
由于 Ubuntu 使用 upstart 来控制 init 过程，我们需要在 /etc/init 中添加一个文件来初始化我们的终端。
此外，在此文件中，我们将添加一些代码来检测是否有脚本传递给模拟系统。
如果有脚本，我们将执行脚本而不是创建终端。

将以下代码放入名为 /etc/init/tty-gem5.conf 的文件中

```
# ttyS0 - getty
#
# This service maintains a getty on ttyS0 from the point the system is
# started until it is shut down again, unless there is a script passed to gem5.
# If there is a script, the script is executed then simulation is stopped.

start on stopped rc RUNLEVEL=[12345]
stop on runlevel [!12345]

console owner
respawn
script
   # Create the serial tty if it doesn't already exist
   if [ ! -c /dev/ttyS0 ]
   then
      mknod /dev/ttyS0 -m 660 /dev/ttyS0 c 4 64
   fi

   # Try to read in the script from the host system
   /sbin/m5 readfile > /tmp/script
   chmod 755 /tmp/script
   if [ -s /tmp/script ]
   then
      # If there is a script, execute the script and then exit the simulation
      exec su root -c '/tmp/script' # gives script full privileges as root user in multi-user mode
      /sbin/m5 exit
   else
      # If there is no script, login the root user and drop to a console
      # Use m5term to connect to this console
      exec /sbin/getty --autologin root -8 38400 ttyS0
   fi
end script
```

#### 设置 localhost

如果我们要使用任何使用它的应用程序，我们还需要设置 localhost 回环设备。
为此，我们需要在 `/etc/hosts` 文件中添加以下内容。

```
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
```

#### 更新 fstab

接下来，我们需要在 `/etc/fstab` 中为我们要能够从模拟系统访问的每个分区创建一个条目。绝对只需要一个分区（`/`）；但是，您可能想要添加其他分区，例如交换分区。

以下内容应出现在文件 `/etc/fstab` 中。

```
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system>    <mount point>   <type>  <options>   <dump>  <pass>
/dev/hda1      /       ext3        noatime     0 1
```

#### 将 `m5` 二进制文件复制到磁盘

gem5 附带一个额外的二进制应用程序，它执行伪指令以允许模拟系统与主机系统交互。
要构建此二进制文件，请在 `gem5/m5` 目录中运行 `make -f Makefile.<isa>`，其中 `<isa>` 是您正在模拟的 ISA（例如，x86）。之后，您应该有一个 `m5` 二进制文件。
将此文件复制到新创建磁盘的 /sbin。

使用所有 gem5 特定文件更新磁盘后，除非您要继续添加更多应用程序或复制其他文件，否则请卸载磁盘镜像。

```
> util/gem5img.py umount mnt
```

### 安装新应用程序

在磁盘上安装新应用程序的最简单方法是使用 `chroot`。
此程序在逻辑上将根目录（"/"）更改为不同的目录，在这种情况下是 mnt。
在更改根目录之前，您首先必须在新根目录中设置特殊目录。为此，我们使用 `mount -o bind`。

```
> sudo /bin/mount -o bind /sys mnt/sys
> sudo /bin/mount -o bind /dev mnt/dev
> sudo /bin/mount -o bind /proc mnt/proc
```

绑定这些目录后，您现在可以 `chroot`：

```
> sudo /usr/sbin/chroot mnt /bin/bash
```

此时您将看到 root 提示符，并且您将在新磁盘的 `/`
目录中。

您应该更新您的仓库信息。

```
> apt-get update
```

您可能希望使用以下命令将 universe 仓库添加到您的列表中。
注意：第一个命令在 14.04 中是必需的。

```
> apt-get install software-properties-common
> add-apt-repository universe
> apt-get update
```

现在，您可以通过 `apt-get` 安装您可以在
原生 Ubuntu 机器上安装的任何应用程序。

请记住，退出后您需要卸载我们
使用 bind 的所有目录。

```
> sudo /bin/umount mnt/sys
> sudo /bin/umount mnt/proc
> sudo /bin/umount mnt/dev
```


## 3) 使用 QEMU 创建磁盘镜像

此方法是创建磁盘镜像的先前方法的后续。
我们将看到如何使用 qemu 创建、编辑和设置磁盘镜像，而不是依赖 gem5 工具。
本节假设您已在系统上安装 qemu。
在 Ubuntu 中，可以通过以下方式完成

```
sudo apt-get install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils
```

### 步骤 1：创建空磁盘
使用 qemu 磁盘工具，创建空白原始磁盘镜像。
在这种情况下，我选择创建一个名为 "ubuntu-test.img" 的 8GB 磁盘。

```
qemu-img create ubuntu-test.img 8G
```

### 步骤 2：使用 qemu 安装 ubuntu
现在我们有了空白磁盘，我们将使用 qemu 在磁盘上安装 Ubuntu。
建议您使用 Ubuntu 的服务器版本，因为 gem5 对显示器的支持不是很好。
因此，桌面环境不是很有用。

首先，您需要从 [Ubuntu 网站](https://www.ubuntu.com/download/server) 下载安装 CD 镜像。

接下来，使用 qemu 从 CD 镜像启动，并将系统中的磁盘设置为您上面创建的空白磁盘。
Ubuntu 需要至少 1GB 内存才能正确安装，因此请确保配置 qemu 使用至少 1GB 内存。

```
qemu-system-x86_64 -hda ../gem5-fs-testing/ubuntu-test.img -cdrom ubuntu-16.04.1-server-amd64.iso -m 1024 -enable-kvm -boot d
```

这样，您可以简单地按照屏幕上的说明将 Ubuntu 安装到磁盘镜像。
安装中唯一需要注意的是 gem5 的 IDE 驱动程序似乎与逻辑分区不太兼容。
因此，在 Ubuntu 安装期间，请确保手动分区磁盘并删除任何逻辑分区。
无论如何，您不需要磁盘上的任何交换空间，除非您专门处理交换空间。

### 步骤 3：启动并安装所需软件

在磁盘上安装 Ubuntu 后，退出 qemu 并删除 `-boot d` 选项，这样您就不再从 CD 启动。
现在，您可以再次从已安装 Ubuntu 的主磁盘镜像启动。

由于我们使用 qemu，您应该有一个网络连接（尽管 [ping 不会
工作](http://wiki.qemu.org/Documentation/Networking#User_Networking_.28SLIRP.29)）。
在 qemu 中启动时，您可以使用 `sudo apt-get install` 并
在磁盘上安装您需要的任何软件。

```
qemu-system-x86_64 -hda ../gem5-fs-testing/ubuntu-test.img -cdrom ubuntu-16.04.1-server-amd64.iso -m 1024 -enable-kvm
```

### 步骤 4：更新 init 脚本

默认情况下，gem5 期望一个修改过的 init 脚本，该脚本从主机加载脚本以在客户机中执行。
要使用此功能，您需要按照以下步骤操作。

或者，您可以安装在此[网站](http://cs.wisc.edu/~powerjg/files/gem5-guest-tools-x86.tgz)上找到的 x86 预编译二进制文件。
从 qemu 中，您可以运行以下命令，这将为您完成上述步骤。

```
wget http://cs.wisc.edu/~powerjg/files/gem5-guest-tools-x86.tgz
tar xzvf gem5-guest-tools-x86.tgz
cd gem5-guest-tools/
sudo ./install
```

现在，您可以在 Python 配置脚本中使用 `system.readfile` 参数。此文件将自动加载（由 `gem5init` 脚本）并执行。

### 手动安装 gem5 init 脚本

首先，在主机上构建 m5 二进制文件。

```
cd util/m5
make -f Makefile.x86
```

然后，将此二进制文件复制到客户机并放在 `/sbin` 中。此外，从 `/sbin/gem5` 创建一个链接。

然后，为了让 init 脚本在 gem5 启动时执行，创建文件 /lib/systemd/system/gem5.service，内容如下：

```
[Unit]
Description=gem5 init script
Documentation=http://gem5.org
After=getty.target

[Service]
Type=idle
ExecStart=/sbin/gem5init
StandardOutput=tty
StandardInput=tty-force
StandardError=tty

[Install]
WantedBy=default.target
```

启用 gem5 服务并**禁用 ttyS0 服务**。
如果您的磁盘启动到登录提示符，可能是由于未禁用 ttyS0 服务造成的。

```
systemctl enable gem5.service
```

最后，创建由服务执行的 init 脚本。在
`/sbin/gem5init` 中：

```
#!/bin/bash -

CPU=`cat /proc/cpuinfo | grep vendor_id | head -n 1 | cut -d ' ' -f2-`
echo "Got CPU type: $CPU"

if [ "$CPU" != "M5 Simulator" ];
then
    echo "Not in gem5. Not loading script"
    exit 0
fi

# Try to read in the script from the host system
/sbin/m5 readfile > /tmp/script
chmod 755 /tmp/script
if [ -s /tmp/script ]
then
    # If there is a script, execute the script and then exit the simulation
    su root -c '/tmp/script' # gives script full privileges as root user in multi-user mode
    sync
    sleep 10
    /sbin/m5 exit
fi
echo "No script found"
```

### 问题和（一些）解决方案

在遵循此方法时，您可能会遇到一些问题。
一些问题和解决方案在此[页面](http://www.lowepower.com/jason/setting-up-gem5-full-system.html)上讨论。

## 4) 使用 Packer 创建磁盘镜像

本节讨论创建安装了 Ubuntu 服务器的 gem5 兼容磁盘镜像的自动化方法。我们使用 packer 来完成此操作，它使用 .json 模板文件来构建和配置磁盘镜像。模板文件可以配置为构建安装了特定基准测试的磁盘镜像。提到的模板文件可以在[此处](/assets/files/packer_template.json)找到。


### 使用 Packer 构建简单磁盘镜像

#### a. 工作原理（简要说明）
我们使用 [Packer](https://www.packer.io/) 和 [QEMU](https://www.qemu.org/) 来自动化磁盘创建过程。
本质上，QEMU 负责设置虚拟机以及在构建过程中与磁盘镜像的所有交互。
交互包括将 Ubuntu Server 安装到磁盘镜像、将文件从您的机器复制到磁盘镜像，以及在安装 Ubuntu 后在磁盘镜像上运行脚本。
但是，我们不会直接使用 QEMU。
Packer 提供了一种使用 JSON 脚本与 QEMU 交互的更简单方法，这比从命令行使用 QEMU 更具表现力。

#### b. 安装所需软件/依赖项
如果尚未安装，可以使用以下方式安装 QEMU：
```shell
sudo apt-get install qemu
```
从[官方网站](https://www.packer.io/downloads.html)下载 Packer 二进制文件。

#### c. 自定义 Packer 脚本
默认的 packer 脚本 `template.json` 应根据所需的磁盘镜像和构建过程的可用资源进行修改和调整。我们将默认模板重命名为 `[disk-name].json`。应该修改的变量出现在 `[disk-name].json` 文件末尾的 `variables` 部分。
用于构建磁盘镜像的配置文件以及目录结构如下所示：
```shell
disk-image/
    [disk-name].json: packer 脚本
    任何实验特定的安装后脚本
    post-installation.sh: 在安装 Ubuntu 后执行的通用 shell 脚本
    preseed.cfg: 用于安装 Ubuntu 的预配置配置
```

##### i. 自定义 VM（虚拟机）
在 `[disk-name].json` 中，以下变量可用于自定义 VM：

| 变量         | 用途     | 示例  |
| ---------------- |-------------|----------|
| [vm_cpus](https://www.packer.io/docs/builders/qemu.html#cpus) **（应修改）** | VM 使用的主机 CPU 数量 | "2"：VM 使用 2 个 CPU |
| [vm_memory](https://www.packer.io/docs/builders/qemu.html#memory) **（应修改）**| VM 内存量，以 MB 为单位 | "2048"：VM 使用 2 GB RAM |
| [vm_accelerator](https://www.packer.io/docs/builders/qemu.html#accelerator) **（应修改）** | VM 使用的加速器，例如 Kvm | "kvm"：将使用 kvm |

<br />

##### ii. 自定义磁盘镜像
在 `[disk-name].json` 中，可以使用以下变量自定义磁盘镜像大小：

| 变量        | 用途     | 示例  |
| ---------------- |-------------|----------|
| [image_size](https://www.packer.io/docs/builders/qemu.html#disk_size) **（应修改）** | 磁盘镜像的大小，以 MB 为单位 | "8192"：镜像大小为 8 GB  |
| [image_name] | 构建的磁盘镜像的名称 | "boot-exit"  |

<br />

##### iii. 文件传输
在构建磁盘镜像时，用户需要将他们的文件（基准测试、数据集等）移动到
磁盘镜像。为了进行此文件传输，在 `[disk-name].json` 的 `provisioners` 下，您可以添加以下内容：

```shell
{
    "type": "file",
    "source": "post_installation.sh",
    "destination": "/home/gem5/",
    "direction": "upload"
}
```
上面的示例将文件 `post_installation.sh` 从主机复制到磁盘镜像中的 `/home/gem5/`。
此方法还能够将文件夹从主机复制到磁盘镜像，反之亦然。
重要的是要注意尾随斜杠会影响复制过程[（更多详细信息）](https://www.packer.io/docs/provisioners/file.html#directory-uploads)。
以下是在路径末尾使用斜杠的一些值得注意的示例。

| `source`        | `destination`     | `direction`  |  `Effect`  |
| ---------------- |-------------|----------|-----|
| `foo.txt` | `/home/gem5/bar.txt` | `upload` | 将文件（主机）复制到文件（镜像） |
| `foo.txt` | `bar/` | `upload` | 将文件（主机）复制到文件夹（镜像） |
| `/foo` | `/tmp` | `upload` | `mkdir /tmp/foo`（镜像）；`cp -r /foo/*（主机）/tmp/foo/（镜像）`； |
| `/foo/` | `/tmp` | `upload` | `cp -r /foo/*（主机）/tmp/（镜像）` |

如果 `direction` 是 `download`，文件将从镜像复制到主机。

**注意**：[这是在安装 Ubuntu 后运行脚本而不复制到磁盘镜像的一种方法](#customizingscripts3)。

##### iv. 安装基准测试依赖项
要安装依赖项，您可以使用 bash 脚本 `post_installation.sh`，该脚本将在 Ubuntu 安装和文件复制完成后运行。
例如，如果我们想安装 `gfortran`，请在 `post_installation.sh` 中添加以下内容：
```shell
echo '12345' | sudo apt-get install gfortran;
```
在上面的示例中，我们假设用户密码是 `12345`。
这本质上是一个在文件复制完成后在 VM 上执行的 bash 脚本，您可以将脚本修改为 bash 脚本以适应任何目的。

##### v. 在磁盘镜像上运行其他脚本
在 `[disk-name].json` 中，我们可以向 `provisioners` 添加更多脚本。
请注意，文件在主机上，但效果在磁盘镜像上。
例如，以下示例在安装 Ubuntu 后运行 `post_installation.sh`，
{% raw %}
```sh
{
    "type": "shell",
    "execute_command": "echo '{{ user `ssh_password` }}' | {{.Vars}} sudo -E -S bash '{{.Path}}'",
    "scripts":
    [
        "post-installation.sh"
    ]
}
```
{% endraw %}

#### d. 构建磁盘镜像

##### i. 构建
为了构建磁盘镜像，首先使用以下命令验证模板文件：
```sh
./packer validate [disk-name].json
```
然后，可以使用模板文件构建磁盘镜像：
```sh
./packer build [disk-name].json
```

在相当新的机器上，构建过程应该不超过 15 分钟即可完成。
具有用户定义名称（image_name）的磁盘镜像将在名为 [image_name]-image 的文件夹中生成。
[我们建议使用 VNC 查看器来检查构建过程](#inspect)。

##### ii. 检查构建过程
在磁盘镜像构建过程中，Packer 将运行 VNC（虚拟网络计算）服务器，您可以通过从 VNC 客户端连接到 VNC 服务器来查看构建过程。VNC 客户端有很多选择。当您运行 Packer 脚本时，它会告诉您 VNC 服务器使用哪个端口。例如，如果它说 `qemu: Connecting to VM via VNC (127.0.0.1:5932)`，则 VNC 端口是 5932。
要从 VNC 客户端连接到 VNC 服务器，对于端口号 5932，使用地址 `127.0.0.1:5932`。
如果您需要端口转发以将 VNC 端口从远程机器转发到本地机器，请使用 SSH 隧道
```shell
ssh -L 5932:127.0.0.1:5932 <username>@<host>
```
此命令将从主机转发端口 5932 到您的机器，然后您将能够从 VNC 查看器使用地址 `127.0.0.1:5932` 连接到 VNC 服务器。

**注意**：当 Packer 正在安装 Ubuntu 时，终端屏幕将显示 "waiting for SSH"，长时间没有任何更新。
这不是 Ubuntu 安装是否产生任何错误的指示。
因此，我们强烈建议至少使用一次 VNC 查看器来检查镜像构建过程。
