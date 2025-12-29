# gem5 官网汉化指南

本指南旨在规范 gem5 官网 (gem5-website) 的汉化工作，确保风格统一、术语准确且维护方便。

## 1. 核心原则

*   **原地修改**：直接修改现有的 Markdown 文件，**不要**创建新文件或重命名文件。
*   **结构不变**：保持原有的目录结构和文件名，以保证网站链接（Permalink）的有效性。
*   **术语统一**：严格参考 `GLOSSARY.md` 进行专业术语的翻译。

## 2. 文件操作规范

### 2.1 Front Matter (YAML 头信息)
Markdown 文件顶部的 YAML 区域（被 `---` 包裹的部分）包含了页面的元数据。

*   **需要修改的字段**：
    *   `title`: 将英文标题翻译为中文。
*   **严禁修改的字段**：
    *   `permalink`: 绝对不要修改，这决定了页面的 URL。
    *   `layout`: 页面布局模板。
    *   `parent`: 父级菜单标识。
    *   `nav_order`: 导航顺序。
    *   `id`: 页面唯一标识。

**示例：**

*原文：*
```yaml
---
layout: documentation
title: Memory System
parent: gem5_documentation
permalink: /documentation/general_docs/memory_system/
---
```

*汉化后：*
```yaml
---
layout: documentation
title: 内存系统  <-- 仅修改此处
parent: gem5_documentation
permalink: /documentation/general_docs/memory_system/
---
```

### 2.2 链接 (Links)
*   **站内链接**：保留原有的相对路径，**不要**翻译链接地址。
    *   ❌ 错误：`[入门指南](/ru_men_zhi_nan)`
    *   ✅ 正确：`[入门指南](/getting_started)`
*   **站外链接**：保留原样。

### 2.3 代码块与命令
*   Markdown 代码块 (``` ... ```) 中的内容通常不翻译，尤其是具体的命令、代码片段、变量名。
*   代码块内的注释 (`//`, `#`) 如果有助于理解，**建议翻译**。

## 3. 排版与格式规范

### 3.1 中英文混排（盘古之白）
*   中文与英文、中文与数字之间，请务必添加一个**空格**。
    *   ❌ 错误：使用gem5进行模拟
    *   ✅ 正确：使用 gem5 进行模拟
    *   ❌ 错误：gem5的20.1版本
    *   ✅ 正确：gem5 的 20.1 版本

### 3.2 标点符号
*   在中文句子中，使用**全角**标点符号（，。：；？！（））。
*   英文专业名词后的补充说明或原文引用，建议使用**半角**括号，并在括号外添加空格。
    *   示例：全系统模式 (Full System)

### 3.3 液体标签 (Liquid Tags)
*   Jekyll 使用 `{% %}` 或 `{{ }}` 包裹的标签是动态脚本，**绝对不要翻译或修改**。
    *   示例：`{% include footer.html %}`
    *   示例：`{{ site.baseurl }}`

## 4. 翻译流程建议

1.  **领取任务**：确定要翻译的文件（例如 `_pages/documentation/general_docs/memory_system/index.md`）。
2.  **参考术语表**：打开根目录下的 `GLOSSARY.md` 随时查阅。
3.  **翻译内容**：
    *   修改 YAML 头部 `title`。
    *   翻译正文内容，注意保留 Markdown 语法（粗体、链接、列表等）。
    *   **SimObject**, **Port**, **gem5** 等词汇保留英文。
4.  **本地预览**：
    *   运行 `bundle exec jekyll serve`。
    *   访问 `http://localhost:4000` 检查页面渲染是否正常，链接是否可跳转。
5.  **提交更改**。

## 5. 常见问题 (FAQ)

**Q: 遇到不确定的术语怎么办？**
A: 首先查看 `GLOSSARY.md`。如果没有收录，建议保留英文原文，或者使用“中文 (英文原文)”的格式。

**Q: 侧边栏的菜单名在哪里修改？**
A: 侧边栏菜单通常由 `_data/documentation.yml` 控制（已完成汉化）或由页面 Front Matter 中的 `title` 字段决定。修改页面的 `title` 通常会自动更新对应的菜单项。

**Q: 图片下的说明文字需要翻译吗？**
A: 需要翻译。

**Q: 警告框（Note/Warning）怎么处理？**
A: gem5 网站通常使用特殊的 HTML 类或 Markdown 引用块来表示警告。请保留格式，仅翻译文本内容。
