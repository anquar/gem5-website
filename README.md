# gem5 website


## 中文翻译版

本仓库维护 **gem5 官网/文档的中文翻译**，并部署到 **Cloudflare Pages**：

- **main 分支 = 可部署稳定线**：任何改动（翻译/同步上游）都通过 PR 合入，`main` 永远保持能 `jekyll build`。
- **upstream-main 分支 = 上游镜像**：定时从上游拉取并强制镜像，保持“干净对齐上游”，不在此分支做翻译提交。
- **工作分支**：
  - **翻译**：`tr/<topic>` → PR → `main`
  - **同步上游**：`sync/YYYYMMDD`（从 `main` 拉出）→ 合并 `upstream-main` 并解决冲突 → PR → `main`

### 远端（remotes）建议

- **origin**：本 GitHub 仓库（Cloudflare Pages 拉取这里的 `main`）
- **upstream**：源仓库（gem5/website 或你实际跟随的上游）

示例：

```
git remote add upstream https://github.com/gem5/website.git
git remote -v
```

### Cloudflare Pages 推荐配置

- **生产分支（Production branch）**: `main`
- **构建命令（Build command）**: `bundle exec jekyll build --config _config.yml`
- **构建输出目录（Build output directory）**: `_site`

> 仓库已在 `.gitignore` 中忽略 `_site/`，建议不要提交构建产物。

### 自动化（已内置在本仓库）

- **CI 构建检查**：`.github/workflows/ci.yml`（对 `main` 的 push/PR 自动跑 `jekyll build`）
- **上游镜像 + 提醒**：`.github/workflows/sync-upstream.yml`
  - 定时把 `upstream-main` 镜像到上游最新
  - 若检测到更新，会自动创建一个带 `sync` 标签的 Issue，提醒你开 `sync/YYYYMMDD` PR 进行人工同步与冲突处理


## 开发

你可以克隆本仓库，并通过以下命令在本地运行网站：

```
git clone https://github.com/anquar/gem5-website
cd website
bundle
jekyll serve --config _config.yml,_config_dev.yml
```

也可以使用 `bundle exec` 的方式启动 Jekyll 服务器：

```
bundle exec jekyll serve --config _config.yml,_config_dev.yml
```

修改完成后，可用以下命令提交：

```
git add <changed files>
git commit
```

提交信息（commit message）必须遵循我们的格式规范。提交信息第一行是“标题（header）”。
**标题行不得超过 65 个字符，并应准确描述本次变更**。为与 gem5 仓库的提交风格保持一致，
标题应以 `website` 标签开头，后跟冒号。

在标题之后，你可以添加更详细的说明：与标题之间用一个空行分隔。详细说明是可选的，
但对于复杂改动强烈建议填写。说明可以跨多行、甚至多段。**说明中的任意一行不得超过
72 个字符**。我们也建议关联相关的 GitHub Issue，方便读者理解改动背景。

下面是 gem5 网站仓库提交信息的示例格式：

```
这是一个示例标题

这里是更详细的提交说明。你可以写到足够长，以便充分描述本次改动。

如有需要，说明也可以分成多段。
```

## 目录结构

#### _data

YAML 文件，用于便捷地编辑导航。

#### _includes

页面的 `<head>` 区段和主导航栏在这里。

#### _layouts

网站使用的不同布局模板：
* default：基础布局
* page：普通页面
* toc：需要目录（Table of Contents）的页面
* post：博客文章页面
* documentation：文档页面

#### _pages

所有页面（除首页 `index.html` 之外）都应放在此目录。这里有一个子目录 `/documentation`，用于存放网站文档部分的页面。这只是为了组织结构清晰、便于查找。重新组织 `_pages` 目录一般不应影响网站。

#### _posts

存放博客文章。

#### _sass

所有自定义 CSS 都放在 `_layout.scss` 中。

#### assets

图片与 JavaScript 文件。

#### blog

存放博客列表页的 `index.html`。


## 导航栏

要编辑导航栏：
打开 `_includes/header.html`
* 不带子菜单的导航项：

```
<li class="nav-item {% if page.title == "Home" %}active{% endif %}">
  <a class="nav-link" href="{{ "/" | prepend: site.baseurl }}">Home</a>
</li>
```

将 `{% if page.title == "Home" %}` 中的 `Home` 替换为你的页面标题。
将 `href="{{ "/" | prepend: site.baseurl }}"` 中的 `/` 替换为页面的 permalink。
将 `>Home</a>` 中的 `Home` 替换为你希望导航栏显示的文本。


* 带子菜单的导航项：

```
<li class="nav-item dropdown {% if page.parent == "about" %}active{% endif %}">
  <a class="nav-link dropdown-toggle" id="navbarDropdownMenuLink" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
    About
  </a>
  <div class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink">
    <a class="dropdown-item" href="{{ "/about" | prepend: site.baseurl }}">About</a>
    <a class="dropdown-item" href="{{ "/publications" | prepend: site.baseurl }}">Publications</a>
    <a class="dropdown-item" href="{{ "/governance" | prepend: site.baseurl }}">Governance</a>
  </div>
</li>
```

将 `{% if page.parent == "about" %}` 中的 `about` 替换为一个标识符，用来表示该子菜单下所有页面的“父级”。并确保这些页面的 frontmatter 中包含 `parent: [你的父级标识符]`。
将子菜单中所有 `<a></a>` 的 permalink 与显示标题按需替换。


## 文档

#### 编辑文档导航

##### 结构：

父级主题：
- 子主题
- 子主题
- ...

父级主题：
- 子主题
- ...

要编辑文档导航，只需编辑 `_data` 目录下的 `documentation.yml` 文件。`docs` 列出父级主题，而每个主题中的 `subitems` 列出其子主题。下面是格式示例：

```
title: Documentation

docs:
  - title: Getting Started     # 父级主题
    id: gettingstarted     # 见下文
    url: /gettingstarted     # 见下文
    subitems:
      - page: Introduction     # 导航中显示的名称
        url: /introduction     # 链接
      - page: Dependencies
        url: /dependencies
  - title: Debugging     # 父级主题
    id: debugging     # 见下文
    subitems:
      - page: Piece 1
        url: /piece1
      - page: Piece 2
        url: /piece2

```

说明：
`id` 是用于把子主题关联到父主题的标识符。它是必填项，且不得包含空格。子主题页面的 frontmatter 必须包含 `parent: id`，其中 `id` 为其父主题的 `id`。

如果父主题本身也有页面，则父主题的 `url` 可选；若未提供 `url`，父主题会自动链接到第一个子主题。

#### 添加新页面

要添加新的文档页面，先在将要新增的 Markdown 或 HTML 文件顶部添加 frontmatter。

```
---
layout: documentation     // 指定页面布局
title: Getting Started     // 页面标题
parent: gettingstarted     // 见下文
permalink: /gettingstarted/     // url
---
```

说明：

`parent` 的值应与 `_data/documentation.yml` 中为其父主题设置的 `id` 完全一致。（若该页面本身是父主题，则 `parent` 与在 `_data/documentation.yml` 中为其设置的 `id` 相同。）

将文件放到 `_pages/documentation` 目录，并确保按上文所述将该页面加入文档导航中。

#### 标注过期信息

要标注某页内容已过期，请在该页的 `.md` 文件中使用 “outdated notice”：

```
{: .outdated-notice}
This page is outdated!
```

这段内容会被替换为一个警告提示元素，包含文本 “**Note: This page is outdated.**”，并在其后附上该提示之后的内容——此处即 “This page is outdated!”。你可以在提示后补充更多说明，例如为什么过期、如何过期，以及缓解或替代方案的通用建议。

说明：

请确保 `{: .outdated-notice}` 之后的文本不要用作标题、段落标题或其它重要的 Markdown 元素，否则它会被并入过期提示中并破坏排版。

## 博客

将博客文章放到 `_posts` 目录中。
文件名必须符合以下格式：
`yyyy-mm-dd-name-of-file.md`
并在文件顶部添加：

```
---
layout: post     // 指定页面布局
title: How to Debug
author: John
date: yyyy-mm-dd
---
```
