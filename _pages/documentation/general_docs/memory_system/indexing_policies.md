---
layout: documentation
title: "索引策略"
doc: gem5 documentation
parent: memory_system
permalink: /documentation/general_docs/memory_system/indexing_policies/
author: Jason Lowe-Power
---

# 索引策略

索引策略根据块的地址确定块映射到的位置。

索引策略最重要的方法是 getPossibleEntries() 和 regenerateAddr()：

-   getPossibleEntries() 确定给定地址可以映射到的条目列表。
-   regenerateAddr() 使用存储在条目中的地址信息来确定其完整的原始地址。

有关缓存索引策略的更多信息，请参阅关于 [放置策略](https://en.wikipedia.org/wiki/Cache_Placement_Policies) 和 [关联性](https://en.wikipedia.org/wiki/CPU_cache#Associativity%7C) 的维基百科文章。

Set Associative {#set_associative}
---------------

组相联索引策略是类表结构的标准，可以进一步分为直接映射（或 1 路组相联）、组相联和全相联（N 路组相联，其中 N 是表条目的数量）。

组相联缓存可以看作是一种倾斜相联缓存，其倾斜函数映射到每一路的相同值。

Skewed Associative {#skewed_associative}
------------------

倾斜相联索引策略具有基于哈希函数的可变映射，因此值 x 可以根据所使用的路映射到不同的组。Gem5 实现了 Seznec 等人在 ["Skewed-Associative Caches"](https://www.researchgate.net/publication/220758754_Skewed-associative_Caches) 中描述的倾斜缓存。

请注意，已实现的哈希函数数量有限，因此如果路数高于该数量，则使用次优的自动生成哈希函数。
