---
layout: documentation
title: "构建 Android Marshmallow"
doc: gem5 documentation
parent: fullsystem
permalink: /documentation/general_docs/fullsystem/building_android_m
---

# 构建 Android Marshmallow

本指南提供了构建 Android Marshmallow 镜像以及适用于 gem5 的内核和 .dtb 文件的详细分步说明。

## 概述
要在 gem5 中成功运行 Android，需要镜像、兼容的内核和为模拟器配置的设备树 blob.dtb 文件。本指南展示了如何使用支持 Mali 的 3.14 内核构建 Android Marshmallow 32 位版本。将来将添加关于如何构建支持 Mali 的 4.4 内核的额外部分。

## 先决条件
本指南假设使用运行 14.04 LTS Ubuntu 的 64 位系统。在开始之前，首先正确设置系统很重要。为此，需要通过 shell 安装以下软件包。

**提示：始终在 Android 构建页面检查最新的先决条件。**

更新并安装所有依赖项。这可以通过以下命令完成：

```
sudo apt-get update

sudo apt-get install openjdk-7-jdk git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip
```

此外，确保正确安装了 repo [（说明在此）](https://source.android.com/source/downloading.html#installing-repo)。

确保默认 JDK 是 OpenJDK 1.7：

```
javac -version
```

要交叉编译内核（32 位）和设备树，我们需要安装以下软件包：

```
sudo apt-get install gcc-arm-linux-gnueabihf device-tree-compiler
```

在开始之前，作为最后一步，确保拥有 32 位 ARM 的 gem5 二进制文件和 busybox。

对于 gem5 二进制文件，只需从您的 gem5 目录开始执行以下操作：
```
cd util/m5
make -f Makefile.arm
cd ../term
make
cd ../../system/arm/simple_bootloader/
make
```

对于 busybox，您可以在此处找到指南 [here](http://wiki.beyondlogic.org/index.php?title=Cross_Compiling_BusyBox_for_ARM)。

## 构建 Android
我们使用基于 Pixel C 发布的 AOSP 运行构建来构建 Android Marshmallow。AOSP 提供[其他构建](https://source.android.com/source/build-numbers.html#source-code-tags-and-builds)，这些构建未使用本指南进行测试。

**提示：与 repo 同步将需要很长时间。使用 -jN 标志来加速 make 过程，其中 N 是要运行的并行作业数。**

创建目录并拉取 Android 仓库：

```
mkdir android
cd android
repo init --depth=1 -u https://android.googlesource.com/platform/manifest -b android-6.0.1_r63
repo sync -c -jN
```

在开始 AOSP 构建之前，您需要对构建系统进行一项更改以启用构建 libion.so，它由 Mali 驱动程序使用。编辑文件 `aosp/system/core/libion/Android.mk`，将 libion 的 `LOCAL_MODULE_TAGS` 从 'optional' 更改为 'debug'。以下是 `repo diff` 的输出：

```
  --- a/system/core/libion/Android.mk
  +++ b/system/core/libion/Android.mk
  @@ -3,7 +3,7 @@ LOCAL_PATH := $(call my-dir)
  include $(CLEAR_VARS)
  LOCAL_SRC_FILES := ion.c
  LOCAL_MODULE := libion
  -LOCAL_MODULE_TAGS := optional
  +LOCAL_MODULE_TAGS := debug
  LOCAL_SHARED_LIBRARIES := liblog
  LOCAL_C_INCLUDES := $(LOCAL_PATH)/include $(LOCAL_PATH)/kernel-headers
  LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/include
  $(LOCAL_PATH)/kernel-headers
```

源环境设置并构建 Android：

**提示：为了 root 访问和"可调试性"[原文如此]，我们选择 userdebug。构建可以在不同模式下完成，如[此处](https://source.android.com/source/building.html#choose-a-target)所示。**
**提示：构建 Android 将需要很长时间。使用 -jN 标志来加速 make 过程，其中 N 是要运行的并行作业数。**

***确保在 bash shell 中执行此操作。***

```
source build/envsetup.sh
lunch aosp_arm-userdebug
make -jN
```

## 创建 Android 镜像

构建成功后，我们创建 Android 镜像并添加为 gem5 配置系统的 init 文件和二进制文件。以下示例创建一个 3GB 镜像。

**提示：如果您想添加应用程序或数据，请使镜像足够大以容纳构建和任何其他要写入其中的内容。**

创建一个空镜像以刷入 Android 构建，并将镜像附加到回环设备：

```
dd if=/dev/zero of=myimage.img bs=1M count=2560
sudo losetup /dev/loop0 myimage.img
```

我们现在需要创建三个分区：AndroidRoot (1.5GB)、AndroidData (1GB) 和 AndroidCache (512MB)。

首先，对设备进行分区：

```
sudo fdisk /dev/loop0
```

更新分区表：

```
sudo partprobe /dev/loop0
```

命名分区 / 将文件系统定义为 ext4：

```
sudo mkfs.ext4 -L AndroidRoot /dev/loop0p1
sudo mkfs.ext4 -L AndroidData /dev/loop0p
sudo mkfs.ext4 -L AndroidCache /dev/loop0p3
```

将 Root 分区挂载到目录：

```
sudo mkdir -p /mnt/androidRoot
sudo mount /dev/loop0p1 /mnt/androidRoot
```

将构建加载到分区：

```
cd /mnt/androidRoot
sudo zcat <path/to/build/android>/out/target/product/generic/ramdisk.img | sudo cpio -i
sudo mkdir cache
sudo mkdir /mnt/tmp
sudo mount -oro,loop <path/to/build/android>/out/target/product/generic/system.img /mnt/tmp
sudo cp -a /mnt/tmp/* system/
sudo umount /mnt/tmp
```

从 [gem5 Android KitKat 页面](http://old.gem5.org/Android_KitKat.html "wikilink")下载并解压必要的[覆盖层](http://dist.gem5.org/dist/current/arm/kitkat-overlay.tar.bz2)，并对 `init.gem5.rc` 文件进行以下更改。以下是 `repo diff` 的输出：

```
  --- /kitkat_overlay/init.gem5.rc
  +++ /m_overlay/init.gem5.rc
  @@ -1,21 +1,13 @@
  +
   on early-init
       mount debugfs debugfs /sys/kernel/debug

   on init
  -    export LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:/vendor/lib/egl
  -
  -    # See storage config details at http://source.android.com/tech/storage/
  -    mkdir /mnt/media_rw/sdcard 0700 media_rw media_rw
  -    mkdir /storage/sdcard 0700 root root
  +    # Support legacy paths
  +    symlink /sdcard /mnt/sdcard
       chmod 0666 /dev/mali0
       chmod 0666 /dev/ion
  -
  -    export EXTERNAL_STORAGE /storage/sdcard
  -
  -    # Support legacy paths
  -    symlink /storage/sdcard /sdcard
  -    symlink /storage/sdcard /mnt/sdcard

   on fs
       mount_all /fstab.gem5
  @@ -60,7 +52,6 @@
       group root
       oneshot

  -# fusewrapped external sdcard daemon running as media_rw (1023)
  -service fuse_sdcard /system/bin/sdcard -u 1023 -g 1023 -d
  /mnt/media_rw/sdcard /storage/sdcard
  +service fingerprintd /system/bin/fingerprintd
       class late_start
  -    disabled
  +    user system
```

添加 Android 覆盖层并配置其权限：

```
sudo cp -r <path/to/android/overlays>/* /mnt/androidRoot/
sudo chmod ug+x /mnt/androidRoot/init.gem5.rc
/mnt/androidRoot/gem5/postboot.sh
```

在 sbin 目录下添加 m5 和 busybox 二进制文件并使它们可执行：

```
sudo cp <path/to/gem5>/util/m5/m5 /mnt/androidRoot/sbin
sudo cp <path/to/busybox>/busybox /mnt/androidRoot/sbin
sudo chmod a+x /mnt/androidRoot/sbin/busybox /mnt/androidRoot/sbin/m5
```

使目录可读和可搜索：

```
sudo chmod a+rx /mnt/androidRoot/sbin/ /mnt/androidRoot/gem5/
```

删除启动动画：

```
sudo rm /mnt/androidRoot/system/bin/bootanimation
```

从[此处](https://developer.arm.com/downloads/-/mali-drivers/midgard-kernel)下载并解压适用于 gem5 Android 4.4 的 Mali 驱动程序。然后，为驱动程序创建目录并复制它们：

```
sudo mkdir -p /mnt/androidRoot/system/vendor/lib/egl
sudo mkdir -p /mnt/androidRoot/system/vendor/lib/hw
sudo cp <path/to/userspace/Mali/drivers>/lib/egl/libGLES_mali.so /mnt/androidRoot/system/vendor/lib/egl
sudo cp <path/to/userspace/Mali/drivers>/lib/hw/gralloc.default.so /mnt/androidRoot/system/vendor/lib/hw
```

更改权限

```
sudo chmod 0755 /mnt/androidRoot/system/vendor/lib/hw
sudo chmod 0755 /mnt/androidRoot/system/vendor/lib/egl
sudo chmod 0644 /mnt/androidRoot/system/vendor/lib/egl/libGLES_mali.so
sudo chmod 0644 /mnt/androidRoot/system/vendor/lib/hw/gralloc.default.so
```

卸载并删除回环设备：

```
cd /..
sudo umount /mnt/androidRoot
sudo losetup -d /dev/loop0
```

## 构建内核 (3.14)

成功设置镜像后，需要构建兼容的内核并生成 .dtb 文件。

克隆包含 gem5 特定内核的仓库：

```
git clone -b ll_20140416.0-gem5 https://github.com/gem5/linux-arm-gem5.git
```

对 `<path/to/kernel/repo>/arch/arm/configs/vexpress_gem5_defconfig` 处的内核 gem5 配置文件进行以下更改。以下是 `repo diff` 的输出：

```
  --- a/arch/arm/configs/vexpress_gem5_defconfig
  +++ b/arch/arm/configs/vexpress_gem5_defconfig
  @@ -200,4 +200,15 @@ CONFIG_EARLY_PRINTK=y
  CONFIG_DEBUG_PREEMPT=n
  # CONFIG_CRYPTO_ANSI_CPRNG is not set
  # CONFIG_CRYPTO_HW is not set
  +CONFIG_MALI_MIDGARD=y
  +CONFIG_MALI_MIDGARD_DEBUG_SYS=y
  +CONFIG_ION=y
  +CONFIG_ION_DUMMY=y
  CONFIG_BINARY_PRINTF=y
  +CONFIG_NET_9P=y
  +CONFIG_NET_9P_VIRTIO=y
  +CONFIG_9P_FS=y
  +CONFIG_9P_FS_POSIX_ACL=y
  +CONFIG_9P_FS_SECURITY=y
  +CONFIG_VIRTIO_BLK=y
  +CONFIG_VMSPLIT_3G=y
  +CONFIG_DNOTIFY=y
  +CONFIG_FUSE_FS=y
```

对于设备树，添加 Mali GPU 设备并将内存增加到 1.8GB。在 `<path/to/kernel/repo>/arch/arm/boot/dts/vexpress-v2p-ca15-tc1-gem5.dts.` 处进行以下更改。以下是 `repo diff` 的输出：

```
  --- a/arch/arm/boot/dts/vexpress-v2p-ca15-tc1-gem5.dts
  +++ b/arch/arm/boot/dts/vexpress-v2p-ca15-tc1-gem5.dts
  @@ -45,7 +45,7 @@

           memory@80000000 {
                   device_type = "memory";
  -                reg = <0 0x80000000 0 0x40000000>;
  +                reg = <0 0x80000000 0 0x74000000>;
           };

          hdlcd@2b000000 {
  @@ -59,6 +59,14 @@
  //                mode = "3840x2160MR-16@60"; // UHD4K mode string
                    framebuffer = <0 0x8f000000 0 0x01000000>;
            };
  +
  +    gpu@0x2d000000 {
  +        compatible = "arm,mali-midgard";
  +        reg = <0 0x2b400000 0 0x4000>;
  +        interrupts = <0 86 4>, <0 87 4>, <0 88 4>;
  +        interrupt-names = "JOB", "MMU", "GPU";
  +    };
  +
  /*
          memory-controller@2b0a0000 {
                    compatible = "arm,pl341", "arm,primecell";
```

从[此处](http://malideveloper.arm.com/resources/drivers/open-source-mali-midgard-gpu-kernel-drivers/)下载并解压适用于 gem5 的用户空间匹配 Mali 内核驱动程序。将它们复制到 gpu 驱动程序目录：

```
cp -r <path/to/kernelspace/Mali/drivers>/driver/product/kernel/drivers/gpu/arm/ drivers/gpu
```

根据以下差异，在 `<path/to/kernelspace/Mali/drivers>/drivers/video/Kconfig` 和 `<path/to/kernelspace/Mali/drivers>/drivers/gpu/Makefile` 中进行以下更改：

Here is the output of the Kconfig `repo diff`:

```
  --- a/drivers/video/Kconfig
  +++ b/drivers/video/Kconfig
  @@ -23,6 +23,8 @@ source "drivers/gpu/host1x/Kconfig"

  source "drivers/gpu/drm/Kconfig"

  +source "drivers/gpu/arm/Kconfig"
  +
   config VGASTATE
          tristate
          default n
```

Here is the output of the drivers/gpu/Makefile `repo diff`:

```
  --- a/drivers/gpu/Makefile
  +++ b/drivers/gpu/Makefile
  @@ -1,2 +1,2 @@
  -obj-y                += drm/ vga/
  +obj-y                += drm/ vga/ arm/
```

最后，构建内核和 .dtb 文件。

**提示：使用 -jN 标志来加速 make 过程，其中 N 是要运行的并行作业数。**

构建内核：
```
make CROSS_COMPILE=arm-linux-gnueabihf- ARCH=arm vexpress_gem5_defconfig
make CROSS_COMPILE=arm-linux-gnueabihf- ARCH=arm vmlinux -jN
```

创建 .dtb 文件：

```
dtc -I dts -O dtb arch/arm/boot/dts/vexpress-v2p-ca15-tc1-gem5.dts > vexpress-v2p-ca15-tc1-gem5.dtb
```

## 测试构建

对 example/fs.py 进行以下更改。以下是 ``repo diff`` 的输出：

```
  --- a/configs/example/fs.py Thu Jun 02 20:34:39 2016 +0100
  +++ b/configs/example/fs.py Fri Jun 10 15:37:29 2016 -0700
  @@ -144,6 +144,13 @@
       if is_kvm_cpu(TestCPUClass) or is_kvm_cpu(FutureClass):
           test_sys.vm = KvmVM()

  +    test_sys.gpu = NoMaliGpu(
  +        gpu_type="T760",
  +        ver_maj=0, ver_min=0, ver_status=1,
  +        int_job=118, int_mmu=119, int_gpu=120,
  +        pio_addr=0x2b400000,
  +        pio=test_sys.membus.master)
  +
      if options.ruby:
          # Check for timing mode because ruby does not support atomic accesses
          if not (options.cpu_type == "detailed" or options.cpu_type == "timing"):
```

以及对 FS 配置的更改以启用或禁用软件渲染。

```
  --- a/configs/common/FSConfig.py Thu Jun 02 20:34:39 2016 +0100
  +++ b/configs/common/FSConfig.py Thu Jun 16 10:23:44 2016 -0700
  @@ -345,7 +345,7 @@

             # release-specific tweaks
             if 'kitkat' in mdesc.os_type():
  -                cmdline += " androidboot.hardware=gem5 qemu=1 qemu.gles=0 " + \
  +                cmdline += " androidboot.hardware=gem5 qemu=1 qemu.gles=1 " + \
                            "android.bootanim=0"

         self.boot_osflags = fillInCmdline(mdesc, cmdline
```

设置以下 M5\_PATH：

```
M5_PATH=. build/ARM/gem5.opt configs/example/fs.py --cpu-type=atomic --mem-type=SimpleMemory --os-type=android-kitkat --disk-image=myimage.img --machine-type=VExpress_EMM --dtb-filename=vexpress-v2p-ca15-tc1-gem5.dtb -n 1 --mem-size=1800MB
```

## 构建旧版本的 Android

gem5 支持运行甚至更旧版本的 Android，如 KitKat。执行此操作的文档以及所需的必要驱动程序和文件可以在旧 wiki [此处](http://old.gem5.org/Android_KitKat.html)找到。
