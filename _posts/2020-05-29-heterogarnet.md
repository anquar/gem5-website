---
layout: post
title:  "HeteroGarnet - 多样化互连系统的详细模拟器"
author: Srikant Bharadwaj, Jieming Ying, Bradford Beckmann, and Tushar Krishna
date:   2020-05-27
---

随着片上系统 (SoC) 异构性的增加，片上网络 (NoC) 不可避免地变得更加复杂。芯片堆叠和 2.5D 芯片集成的最新进展引入了封装内网络异构性，这可能使互连设计复杂化。对此类复杂系统的详细建模需要准确建模其特性。不幸的是，当今的 NoC 模拟器缺乏对这些多样化互连进行建模所需的灵活性和功能。

我们提出了 HeteroGarnet，它通过支持新兴互连系统的准确模拟，改进了广泛流行的 Garnet 2.0 网络模型。具体来说，HeteroGarnet 添加了对时钟域岛、支持多个频率域的网络交叉以及能够连接到多个物理链路的网络接口控制器的支持。它还通过引入新的可配置串行器-解串器组件来支持可变带宽链路和路由器。我们最近使用 HeteroGarnet [1] 的工作表明，准确的互连建模如何能够带来更好的网络设计。在本演示中，我们将介绍 HeteroGarnet 及其在建模现代异构系统方面的优势。HeteroGarnet 计划集成到 gem5 仓库中，并将被标识为 Garnet 3.0。

# Workshop Presentation

<iframe width="960" height="540" src="https://www.youtube.com/embed/AH9r44r2lHA"
frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope;
picture-in-picture" allowfullscreen style="max-width: 960px";></iframe>
