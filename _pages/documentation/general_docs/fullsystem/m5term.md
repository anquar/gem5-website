---
layout: documentation
title: "m5 终端"
doc: gem5 documentation
parent: fullsystem
permalink: /documentation/general_docs/fullsystem/m5term
---
# m5 终端

m5term 程序允许用户连接到全系统 gem5 提供的模拟控制台接口。只需切换到 util/term 目录并构建 m5term：

```
% cd gem5/util/term
% make
gcc  -o m5term term.c
% make install
sudo install -o root -m 555 m5term /usr/local/bin
```

m5term 的用法是：

```
./m5term <host> <port>
```
	<host> 是运行 gem5 的主机

	<port> 是要连接的控制台端口。gem5 默认使用端口 3456，但如果该端口被使用，它将尝试下一个更高的端口，直到找到一个可用的端口。

	如果在一个模拟中运行多个系统，每个系统都会有一个控制台。（例如，第一个系统的控制台将在 3456，第二个在 3457）

	m5term 使用 '~' 作为转义字符。如果您输入转义字符后跟 '.'，m5term 程序将退出。

m5term 可用于与模拟器进行交互式工作，尽管用户通常必须设置各种终端设置才能使其正常工作

m5term 运行的一个稍微简短的示例：

	% m5term localhost 3456
	==== m5 slave console: Console 0 ====
	M5 console
	Got Configuration 127
	memsize 8000000 pages 4000
	First free page after ROM 0xFFFFFC0000018000
	HWRPB 0xFFFFFC0000018000 l1pt 0xFFFFFC0000040000 l2pt 0xFFFFFC0000042000 l3pt_rpb 0xFFFFFC0000044000 l3pt_kernel 0xFFFFFC0000048000 l2reserv 0xFFFFFC0000046000
	CPU Clock at 2000 MHz IntrClockFrequency=1024
	Booting with 1 processor(s)
	...
	...
	VFS: Mounted root (ext2 filesystem) readonly.
	Freeing unused kernel memory: 480k freed
	init started:  BusyBox v1.00-rc2 (2004.11.18-16:22+0000) multi-call binary

	PTXdist-0.7.0 (2004-11-18T11:23:40-0500)

	mounting filesystems...
	EXT2-fs warning: checktime reached, running e2fsck is recommended
	loading script...
	Script from M5 readfile is empty, starting bash shell...
	# ls
	benchmarks  etc         lib         mnt         sbin        usr
	bin         floppy      lost+found  modules     sys         var
	dev         home        man         proc        tmp         z
	#
