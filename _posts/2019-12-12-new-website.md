---
layout: post
title:  "gem5 网站重新设计"
author: Jason Lowe-Power
date:   2019-12-12
categories: project
---

欢迎来到 gem5 的新网站！
旧的 wiki 已经需要更新好几年了（见下面的截图），我们很高兴终于能与社区分享一些东西！
我们希望新网站具有更好的可用性，并让查找关于 gem5 的信息以及如何使用它变得更加容易。
如果您有任何问题或意见，请随时通过 gem5-dev [邮件列表](/ask-a-question)联系我们！

![](/assets/img/blog/old-website.png "screenshot of the old website")
*gem5 的原始网站*


## 新网站的状态

有关迁移当前状态的详细信息可以在 [Jira](https://gem5.atlassian.net/browse/GEM5-110) 上找到。
我们还有一个关于[将旧文档迁移到新站点](https://gem5.atlassian.net/browse/GEM5-115)的特定问题。
我们已经迁移了大部分文档，但仍有一些页面需要您的帮助！

在过渡期间会有一些粗糙的地方。
一些链接可能会失效，我们可能遗漏了一些应该迁移的页面。
如果您发现任何问题，请通过[邮件列表](/ask-a-question)或[在 Jira 上提交问题](https://gem5.atlassian.net/)告知我们。

该网站目前托管在 GitHub Pages 上。
如果您想贡献，欢迎在[源代码仓库](https://github.com/gem5/new-website)上创建[拉取请求](https://github.com/gem5/new-website/pulls)。

## 下一步

我们将在接下来的几周内将此网站保留在 new.gem5.org。
在我们关闭旧 wiki 页面之前，请告知我们是否有任何阻塞问题。
在完全过渡之前，我们将下载整个旧网站的静态副本（包括旧的代码审查）并将其移动到 old.gem5.org 用于归档目的（以防我们遗漏任何内容！）。

### 待解决的问题

新网站还有很多可以改进的地方，但我认为没有阻塞性问题。
我们希望得到帮助的一些事情包括

- 改进文档界面。添加文档很令人困惑，因为您必须同时创建文件并更新 `_data/documentation.yml`。
- 使文档更容易被发现。
- 添加更多文档（总是需要的！）
- 修复失效的链接
- 小的样式表清理（例如，在文档页面上时徽标会滚动消失）

### 博客文章

我们也在寻找更多的博客贡献者！
我希望每月看到 2-3 篇博客文章，涵盖新 gem5 功能、如何非正式地使用 gem5、工作负载、使用 gem5 发表的酷论文等内容。
如果您有其他想法，也欢迎联系我 (jason@lowepower.com)！
如果您想为博客做出贡献，请在 [GitHub](https://github.com/gem5/new-website) 上提交 PR。
