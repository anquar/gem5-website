---
layout: page
title: gem5 新手入门
permalink: /getting_started/
author: Jason Lowe-Power
---

# gem5 新手入门

## 第一步

当您在当前代码库的基础上构建新模型和新功能时，gem5 模拟器对研究最为有用。
因此，使用 gem5 最常见的方式是下载源代码并自己构建它。

要下载 gem5，您可以使用 [`git`](https://git-scm.com/) 检出当前的 stable 分支。
如果您不熟悉版本控制或 git，[git book](https://git-scm.com/book/zh/v2)（可免费在线阅读）是了解更多关于 git 并熟悉使用版本控制的好方法。
gem5 的规范版本托管在 [GitHub](https://github.com/gem5/gem5) 上。

```
git clone https://github.com/gem5/gem5
```

克隆源代码后，您可以使用 [`scons`](https://scons.org/) 构建 gem5。
构建 gem5 所需的时间从大型服务器上的几分钟到笔记本电脑上的 45 分钟不等。
构建 gem5 是计算和内存密集型的，使用额外的线程会导致构建过程消耗更多内存。
因此，如果在低端机器上构建 gem5，建议使用较少的线程（例如 -j 1 或 -j 2）。
gem5 必须在 Unix 平台上构建。
Linux 在每次提交时都会进行测试，有些人也能使用 MacOS，虽然它没有经过定期测试。
强烈建议 *不要* 尝试在虚拟机上编译 gem5。
当在笔记本电脑上的虚拟机中运行时，gem5 可能需要一个多小时才能完成编译。
[构建 gem5](/documentation/general_docs/building) 提供了有关构建 gem5 及其依赖项的更多详细信息。

```
cd gem5
scons build/ALL/gem5.opt -j <NUMBER OF CPUs ON YOUR PLATFORM>
```

现在您拥有了一个 gem5 二进制文件，可以运行您的第一次模拟了！
gem5 的接口是 Python 脚本。
gem5 二进制文件读取并执行提供的 Python 脚本，该脚本创建待测系统并执行模拟器。
在这个例子中，脚本创建了一个 *非常* 简单的系统并执行一个 "hello world" 二进制文件。
有关脚本的更多信息，可以在 [学习 gem5](/documentation/learning_gem5/introduction) 书籍的 [简单配置章节](/documentation/learning_gem5/part1/simple_config) 中找到。

```
build/ALL/gem5.opt configs/learning_gem5/part1/simple.py
```

运行此命令后，您将看到 gem5 的输出以及 `Hello world`，它来自 hello world 二进制文件！
现在，您可以开始深入研究如何使用和扩展 gem5 了！

## 下一步

- [学习 gem5](/documentation/learning_gem5/introduction) 是一本正在编写中的书籍，描述了如何使用和开发 gem5。它包含有关如何创建配置文件、使用新模型扩展 gem5、gem5 的缓存一致性模型等详细信息。
- [gem5 活动](/events) 经常与计算机架构会议同时举行，也会在其他地点举行。
- 您可以在 [gem5 的频道](/ask-a-question) 上获得帮助，或者关注 [Stack Overflow 上的 gem5 标签](https://stackoverflow.com/questions/tagged/gem5)。
- [贡献指南](/contributing) 描述了如何贡献您的代码更改以及其他为 gem5 做贡献的方式。

## 研究中使用 gem5 的提示

### 我应该使用哪个版本的 gem5？

gem5 git 仓库有两个分支：`develop` 和 `stable`。`develop` 分支包含最新的 gem5 更改，**但不稳定**。它更新频繁。**`develop` 分支应仅在为 gem5 项目做贡献时使用**（有关如何向 gem5 提交代码的更多信息，请参阅我们的 [贡献指南](/contributing)）。

stable 分支包含稳定的 gem5 代码。stable 分支的 HEAD 指向最新的 gem5 版本。我们建议研究人员使用最新的 gem5 稳定版本，并在发表结果时报告使用的版本（使用 `git describe` 查看最新的 gem5 发布版本号）。

如果复现之前的工作，请查找使用了哪个版本的 gem5。
该版本应该在 `stable` 分支上有标签，并可以通过 `git checkout -b {branch} {version}` 检出到一个新分支。
例如，要在一个名为 `version19` 的新分支上检出 `v19.0.0`：
`git checkout -b version19 v19.0.0`。执行 `git tag` 可以查看 `stable` 分支上已发布的 gem5 版本的完整列表。

### 我应该如何引用 gem5？

您应该引用 [gem5-20 论文](https://arxiv.org/abs/2007.03152)。

```
The gem5 Simulator: Version 20.0+. Jason Lowe-Power, Abdul Mutaal Ahmad, Ayaz Akram, Mohammad Alian, Rico Amslinger, Matteo Andreozzi, Adrià Armejach, Nils Asmussen, Brad Beckmann, Srikant Bharadwaj, Gabe Black, Gedare Bloom, Bobby R. Bruce, Daniel Rodrigues Carvalho, Jeronimo Castrillon, Lizhong Chen, Nicolas Derumigny, Stephan Diestelhorst, Wendy Elsasser, Carlos Escuin, Marjan Fariborz, Amin Farmahini-Farahani, Pouya Fotouhi, Ryan Gambord, Jayneel Gandhi, Dibakar Gope, Thomas Grass, Anthony Gutierrez, Bagus Hanindhito, Andreas Hansson, Swapnil Haria, Austin Harris, Timothy Hayes, Adrian Herrera, Matthew Horsnell, Syed Ali Raza Jafri, Radhika Jagtap, Hanhwi Jang, Reiley Jeyapaul, Timothy M. Jones, Matthias Jung, Subash Kannoth, Hamidreza Khaleghzadeh, Yuetsu Kodama, Tushar Krishna, Tommaso Marinelli, Christian Menard, Andrea Mondelli, Miquel Moreto, Tiago Mück, Omar Naji, Krishnendra Nathella, Hoa Nguyen, Nikos Nikoleris, Lena E. Olson, Marc Orr, Binh Pham, Pablo Prieto, Trivikram Reddy, Alec Roelke, Mahyar Samani, Andreas Sandberg, Javier Setoain, Boris Shingarov, Matthew D. Sinclair, Tuan Ta, Rahul Thakur, Giacomo Travaglini, Michael Upton, Nilay Vaish, Ilias Vougioukas, William Wang, Zhengrong Wang, Norbert Wehn, Christian Weis, David A. Wood, Hongil Yoon, Éder F. Zulian. ArXiv Preprint ArXiv:2007.03152, 2021.

```

[下载 .bib 文件。](/assets/files/gem5-20.bib)

您也可以引用 [原始 gem5 论文](http://dx.doi.org/10.1145/2024716.2024718)。

```
The gem5 Simulator. Nathan Binkert, Bradford Beckmann, Gabriel Black, Steven K. Reinhardt, Ali Saidi, Arkaprava Basu, Joel Hestness, Derek R. Hower, Tushar Krishna, Somayeh Sardashti, Rathijit Sen, Korey Sewell, Muhammad Shoaib, Nilay Vaish, Mark D. Hill, and David A. Wood. May 2011, ACM SIGARCH Computer Architecture News.
```

您还应该在方法部分指定您使用的 gem5 **版本**。
如果您没有使用特定的 gem5 稳定版本（例如 gem5-20.1.3），则应声明提交哈希值（*显示在 https://github.com/gem5/gem5 上*）。

如果您使用 GPU 模型、DRAM 模型或 gem5 中任何其他已 [发表](/publications/) 的模型，我们也鼓励您引用这些作品。
请参阅 [出版物页面](/publications/) 以获取除原始论文之外为 gem5 做出贡献的模型列表。

### 我应该如何称呼 gem5？

"gem5" 应 *始终* 使用小写 "g"。
如果不习惯以小写字母开头，或者您的编辑器要求大写字母，您可以将 gem5 称为 "The gem5 Simulator"（gem5 模拟器）。

### 我可以使用 gem5 logo 吗？

当然！
gem5 logo 由 [Nicole Hill](http://nicoledhill.com/) 创作，并在 CC0 许可下进入公共领域。
您可以从以下链接下载全尺寸 logo：
- [垂直彩色](/assets/img/gem5logo/Color/noBackground/vertical/gem5ColorVert.png)
- [水平彩色](/assets/img/gem5logo/Color/noBackground/horizontal/gem5ColorLong.jpg)
- [所有 logo (svg)](/assets/img/gem5logo/gem5masterFile.svg)

使用 gem5 logo 时，请遵循 [gem5 logo 风格指南](/assets/img/gem5logo/gem5styleguide.pdf)。
更多详细信息和更多版本的 logo 可以在 [gem5 文档源码](https://github.com/gem5/new-website/tree/master/assets/img/gem5logo) 中找到。
