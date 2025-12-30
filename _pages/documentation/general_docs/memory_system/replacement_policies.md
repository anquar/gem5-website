---
layout: documentation
title: "替换策略"
doc: gem5 documentation
parent: memory_system
permalink: /documentation/general_docs/memory_system/replacement_policies/
author: Jason Lowe-Power
---

# 替换策略

Gem5 实现了多种替换策略。每种策略都使用其特定的替换数据来确定驱逐时的替换受害者。

所有的替换策略都优先驱逐无效块。

替换策略由 reset(), touch(), invalidate() 和 getVictim() 方法组成。每个方法以不同的方式处理替换数据。

-   reset() 用于初始化替换数据（即验证）。它应该仅在条目插入时被调用，并且在无效化之前不得再次调用。对条目的第一次触摸必须始终是 reset()。
-   touch() 用于访问替换数据，因此应在条目访问时调用。它更新替换数据。
-   invalidate() 每当条目无效时调用，可能是由于一致性处理。它使得该条目在下一次受害者搜索中尽可能可能被驱逐。在执行 reset() 之前不需要使条目无效。当模拟开始时，所有条目都是无效的。
-   getVictim() 在未命中且必须进行驱逐时调用。它在所有替换候选者中搜索具有最差替换数据的条目，通常优先驱逐无效条目。

我们简要描述 Gem5 中实现的替换策略。如果需要更多信息，可以研究 [Cache Replacement Policies Wikipedia 页面](https://en.wikipedia.org/wiki/Cache_replacement_policies) 或相应的论文。

Random
------

最简单的替换策略；它不需要替换数据，因为它在候选者中随机选择一个受害者。

Least Recently Used (LRU) {#least_recently_used_lru}
-------------------------

它的替换数据由最后一次触摸的时间戳组成，受害者是根据它选择的：它越旧，其对应的条目就越有可能被驱逐。

Tree Pseudo Least Recently Used (TreePLRU) {#tree_pseudo_least_recently_used_treeplru}
------------------------------------------

LRU 的一种变体，使用二叉树通过 1 位指针来跟踪条目的使用近期性。

Bimodal Insertion Policy (BIP) {#bimodal_insertion_policy_bip}
------------------------------

[Bimodal Insertion Policy] 类似于 LRU，但是，根据双峰节流参数 (btp)，块有一定的概率作为 MRU 插入。btp 越高，新块作为 MRU 插入的可能性就越高。

LRU Insertion Policy (LIP) {#lru_insertion_policy_lip}
--------------------------

[LRU Insertion Policy][Bimodal Insertion Policy] 包含一个 LRU 替换策略，它不插入具有最近最后触摸时间戳的块，而是将它们作为 LRU 条目插入。在随后对该块的触摸中，其时间戳更新为 MRU，如在 LRU 中一样。它也可以被视为 BIP，其中将新块插入为最近使用的可能性为 0%。

Most Recently Used (MRU) {#most_recently_used_mru}
------------------------

Most Recently Used 策略根据近期性选择替换受害者，但是，与 LRU 相反，条目越新，它就越有可能被驱逐。

Least Frequently Used (LFU) {#least_frequently_used_lfu}
---------------------------

使用引用频率选择受害者。引用最少的条目被选择驱逐，无论它被触摸了多少次，或者自上次触摸以来经过了多长时间。

First-In, First-Out (FIFO) {#first_in_first_out_fifo}
--------------------------

使用插入时间戳选择受害者。如果不存在无效条目，则驱逐最旧的条目，无论它被触摸了多少次。

Second-Chance {#second_chance}
-------------

[Second-Chance] 替换策略类似于 FIFO，但在被驱逐之前给条目第二次机会。如果一个条目本应是下一个被驱逐的，但它的第二次机会位被设置，则清除此位，并将该条目重新插入 FIFO 的末尾。在未命中之后，插入一个第二次机会位被清除的条目。

Not Recently Used (NRU) {#not_recently_used_nru}
-----------------------

Not Recently Used (NRU) 是 LRU 的近似值，它使用单个位来确定块是否将在近期或远期被重新引用。如果该位为 1，则它很可能不会很快被引用，因此它被选为替换受害者。当一个块被驱逐时，其所有共同替换候选者的重新引用位都会递增。

Re-Reference Interval Prediction (RRIP) {#re_reference_interval_prediction_rrip}
---------------------------------------

[Re-Reference Interval Prediction (RRIP)] 是 NRU 的扩展，它使用重新引用预测值 (RRPV) 来确定块是否将在不久的将来被重新使用。RRPV 值越高，该块距离其下一次访问越远。从原始论文来看，RRIP 的这种实现也称为 Static RRIP (SRRIP)，因为它总是插入具有相同 RRPV 的块。

Bimodal Re-Reference Interval Prediction (BRRIP) {#bimodal_re_reference_interval_prediction_brrip}
------------------------------------------------

[Bimodal Re-Reference Interval Prediction (BRRIP)][Re-Reference Interval Prediction (RRIP)] 是 RRIP 的扩展，它具有不将块作为 LRU 插入的概率，就像在 Bimodal Insertion Policy 中一样。此概率由双峰节流参数 (btp) 控制。

  [Second-Chance]: https://apps.dtic.mil/docs/citations/AD0687552
  [Re-Reference Interval Prediction (RRIP)]: https://dl.acm.org/citation.cfm?id=1815971
  [Cache Replacement Policies Wikipedia page]: https://en.wikipedia.org/wiki/Cache_replacement_policies
  [Bimodal Insertion Policy]: https://dl.acm.org/citation.cfm?id=1250709
