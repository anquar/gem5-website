---
layout: documentation
title: 转换代码块
doc: Learning gem5
parent: part3
permalink: /documentation/learning_gem5/part3/cache-transitions/
author: Jason Lowe-Power
---


## 转换代码块

终于，我们到了状态机文件的最后一部分！本节包含状态之间所有转换以及在转换期间执行哪些动作的详细信息。

到目前为止，在本章中，我们已经一次一个部分地从上到下编写了状态机。但是，在大多数缓存一致性实现中，您会发现需要在各部分之间移动。例如，在编写转换时，您会意识到忘记添加动作，或者您注意到实际上需要另一个瞬态来实现协议。这是编写协议的正常方式，但为了简单起见，本章从上到下浏览文件。

转换块由两部分组成。首先，转换块的第一行包含开始状态、要转换的事件和结束状态（如下所述，可能不需要结束状态）。其次，转换块包含在此转换上执行的所有动作。例如，MSI 协议中的一个简单转换是在 Load 时转换出 Invalid。

```cpp
transition(I, Load, IS_D) {
    allocateCacheBlock;
    allocateTBE;
    sendGetS;
    popMandatoryQueue;
}
```

首先，您将转换指定为 `transition` 语句的“参数”。在这种情况下，如果初始状态是 `I` 且事件是 `Load`，则转换到 `IS_D`（曾是无效，变为共享，等待数据）。此转换直接来自 Sorin 等人的表 8.3。

然后，在 `transition` 代码块中，按顺序列出将执行的所有动作。对于此转换，首先我们分配缓存块。请记住，在 `allocateCacheBlock` 动作中，新分配的条目设置为将在其余动作中使用的条目。分配缓存块后，我们还分配一个 TBE。如果我们需要等待来自其他缓存的 acks，则可以使用它。接下来，我们向目录发送 GetS 请求，最后我们从强制队列中弹出头条目，因为我们已完全处理了它。

```cpp
transition(IS_D, {Load, Store, Replacement, Inv}) {
    stall;
}
```

在此转换中，我们使用了稍微不同的语法。根据 Sorin 等人的表 8.3，如果缓存在加载、存储、替换和无效时处于 IS\_D，我们应该停顿。我们可以通过在大括号中包含多个事件来为其指定单个转换语句，如上所示。此外，不需要最终状态。如果未指定最终状态，则执行转换并且状态不更新（即，块保持其开始状态）。您可以将上述转换读作“如果缓存块处于状态 IS\_D 并且有加载、存储、替换或无效，则停顿协议并且不转换出该状态。” 您还可以对开始状态使用大括号，如下面的一些转换所示。

下面是实现 MSI 协议中 L1 缓存所需的其余转换。

```cpp
transition(IS_D, {DataDirNoAcks, DataOwner}, S) {
    writeDataToCache;
    deallocateTBE;
    externalLoadHit;
    popResponseQueue;
}

transition({IM_AD, IM_A}, {Load, Store, Replacement, FwdGetS, FwdGetM}) {
    stall;
}

transition({IM_AD, SM_AD}, {DataDirNoAcks, DataOwner}, M) {
    writeDataToCache;
    deallocateTBE;
    externalStoreHit;
    popResponseQueue;
}

transition(IM_AD, DataDirAcks, IM_A) {
    writeDataToCache;
    storeAcks;
    popResponseQueue;
}

transition({IM_AD, IM_A, SM_AD, SM_A}, InvAck) {
    decrAcks;
    popResponseQueue;
}

transition({IM_A, SM_A}, LastInvAck, M) {
    deallocateTBE;
    externalStoreHit;
    popResponseQueue;
}

transition({S, SM_AD, SM_A, M}, Load) {
    loadHit;
    popMandatoryQueue;
}

transition(S, Store, SM_AD) {
    allocateTBE;
    sendGetM;
    popMandatoryQueue;
}

transition(S, Replacement, SI_A) {
    sendPutS;
    forwardEviction;
}

transition(S, Inv, I) {
    sendInvAcktoReq;
    deallocateCacheBlock;
    forwardEviction;
    popForwardQueue;
}

transition({SM_AD, SM_A}, {Store, Replacement, FwdGetS, FwdGetM}) {
    stall;
}

transition(SM_AD, Inv, IM_AD) {
    sendInvAcktoReq;
    forwardEviction;
    popForwardQueue;
}

transition(SM_AD, DataDirAcks, SM_A) {
    writeDataToCache;
    storeAcks;
    popResponseQueue;
}

transition(M, Store) {
    storeHit;
    popMandatoryQueue;
}

transition(M, Replacement, MI_A) {
    sendPutM;
    forwardEviction;
}

transition(M, FwdGetS, S) {
    sendCacheDataToReq;
    sendCacheDataToDir;
    popForwardQueue;
}

transition(M, FwdGetM, I) {
    sendCacheDataToReq;
    deallocateCacheBlock;
    popForwardQueue;
}

transition({MI_A, SI_A, II_A}, {Load, Store, Replacement}) {
    stall;
}

transition(MI_A, FwdGetS, SI_A) {
    sendCacheDataToReq;
    sendCacheDataToDir;
    popForwardQueue;
}

transition(MI_A, FwdGetM, II_A) {
    sendCacheDataToReq;
    popForwardQueue;
}

transition({MI_A, SI_A, II_A}, PutAck, I) {
    deallocateCacheBlock;
    popForwardQueue;
}

transition(SI_A, Inv, II_A) {
    sendInvAcktoReq;
    popForwardQueue;
}
```

您可以下载完整的 `MSI-cache.sm` 文件
[这里](https://gem5.googlesource.com/public/gem5/+/refs/heads/stable/src/learning_gem5/part3/MSI-cache.sm).
