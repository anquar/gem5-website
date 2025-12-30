---
layout: documentation
title: 功耗与热模型
doc: gem5 documentation
parent: thermal_model
permalink: /documentation/general_docs/thermal_model
---

# 功耗与热模型

本文档概述了 gem5 中的功耗和热建模基础设施。

目的是提供所有相关组件的高级视图，以及它们如何相互交互以及与模拟器交互。

## 类概述

功耗模型中涉及的类包括：

* [PowerModel](http://doxygen.gem5.org/release/current/classgem5_1_1ThermalResistor.html)：
表示硬件组件的功耗模型。
* [PowerModelState](
http://doxygen.gem5.org/release/current/classgem5_1_1PowerModelState.html)：表示硬件组件在特定功耗状态下的功耗模型。它是一个抽象类，定义了每个模型必须实现的接口。
* [MathExprPowerModel](
http://doxygen.gem5.org/release/current/classgem5_1_1MathExprPowerModel.html)：[PowerModelState](
http://doxygen.gem5.org/release/current/classgem5_1_1PowerModelState.html) 的简单实现，假设可以使用简单的功耗方程进行建模。

热模型中涉及的类包括：

* [ThermalModel](http://doxygen.gem5.org/release/current/classgem5_1_1ThermalModel.html)：
包含系统热模型逻辑和状态。它执行功耗查询和温度更新。它还使 gem5 能够查询温度（用于操作系统报告）。
* [ThermalDomain](http://doxygen.gem5.org/release/current/classgem5_1_1ThermalDomain.html)：
表示产生热量的实体。它本质上是一组 [SimObjects](http://doxygen.gem5.org/release/current/classgem5_1_1SubSystem.html)，这些对象在 SubSystem 组件下分组，具有自己的热行为。
* [ThermalNode](http://doxygen.gem5.org/release/current/classgem5_1_1ThermalNode.html)：
表示热等效电路中的一个节点。节点具有温度，并通过连接（热阻和热容）与其他节点交互。
* [ThermalReference](
http://doxygen.gem5.org/release/current/classgem5_1_1ThermalReference.html)：热模型的温度参考（本质上是一个具有固定温度的热节点），可用于模拟空气或任何其他恒定温度域。
* [ThermalEntity](http://doxygen.gem5.org/release/current/classgem5_1_1ThermalEntity.html)：
连接两个热节点并模拟它们之间热阻抗的热组件。此类只是一个抽象接口。
* [ThermalResistor](
http://doxygen.gem5.org/release/current/classgem5_1_1ThermalResistor.html)：实现
[ThermalEntity](http://doxygen.gem5.org/release/current/classgem5_1_1ThermalEntity.html) 以模拟其连接的两个节点之间的热阻。热阻模拟材料传递热量的能力（单位为 K/W）。
* [ThermalCapacitor](
http://doxygen.gem5.org/release/current/classgem5_1_1ThermalCapacitor.html)：实现
[ThermalEntity](http://doxygen.gem5.org/release/current/classgem5_1_1ThermalEntity.html) 以模拟热容。热容用于模拟材料的热容，即改变特定材料温度的能力（单位为 J/K）。

## 热模型

热模型通过创建模拟平台的等效电路来工作。电路中的每个节点都有一个温度（作为电压等效），功率在节点之间流动（作为电路中的电流）。

要构建此等效温度模型，平台需要将功耗参与者（任何具有功耗模型的组件）分组到 SubSystem 下，并将 ThermalDomain 附加到这些子系统。还可以创建其他组件（如 ThermalReference），并通过创建热实体（电容和电阻）将它们全部连接在一起。

完成热模型的最后一步是创建 [ThermalModel](
http://doxygen.gem5.org/release/current/classgem5_1_1ThermalModel.html) 实例本身，并将所有使用的实例附加到它，以便它可以在运行时正确更新它们。
目前仅支持一个热模型实例，它会在适当的时候自动报告温度（例如平台传感器设备）。

## 功耗模型

每个 [ClockedObject](
http://doxygen.gem5.org/release/current/classgem5_1_1ClockedObject.html) 都有一个关联的功耗模型。如果此功耗模型非空，则将在每次统计信息转储时计算功耗（尽管可能可以在任何其他点强制进行功耗评估，但如果功耗模型使用统计信息，最好保持两个事件同步）。功耗模型的定义相当模糊，因为它的灵活性取决于用户的需求。到目前为止，唯一强制执行的约束是功耗模型具有多个功耗状态模型，每个硬件块的可能功耗状态对应一个。在计算功耗消耗时，功耗只是每个功耗模型的加权平均值。

功耗状态模型本质上是一个接口，允许我们为动态和静态定义两个功耗函数。作为一个示例实现，已提供了一个名为 [MathExprPowerModel](
http://doxygen.gem5.org/release/current/classgem5_1_1MathExprPowerModel.html) 的类。此实现允许用户将功耗模型定义为涉及多个统计信息的方程。还有一些自动（或"魔法"）变量，例如 "temp"，它报告温度。
