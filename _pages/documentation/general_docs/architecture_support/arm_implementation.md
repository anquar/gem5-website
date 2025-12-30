---
layout: documentation
title: "ARM 实现"
doc: gem5 documentation
parent: architecture_support
permalink: /documentation/general_docs/architecture_support/arm_implementation/
---

# ARM 实现

## 支持的功能和模式

gem5 中的 ARM 架构模型支持 ARM® 架构的 [ARMv8.0-A](https://developer.arm.com/docs/den0024/latest/armv8-a-architecture-and-processors/armv8-a) 配置文件以及多处理器扩展。
这包括所有 EL 的 AArch32 和 AArch64 状态。这基本上意味着支持：

* [EL2: 虚拟化](https://developer.arm.com/docs/100942/0100/aarch64-virtualization)
* [EL3: TrustZone®](https://developer.arm.com/ip-products/security-ip/trustzone)

基线模型符合 ARMv8.0，我们也支持一些强制/可选的 ARMv8.x 功能（x > 0）

### 从 gem5 v21.2 开始

获取 Arm 架构功能同步版本的最佳方法是查看发布对象使用的 [ArmExtension](https://github.com/gem5/gem5/blob/develop/src/arch/arm/ArmSystem.py) 枚举以及同一文件中提供的可用示例发布。

用户可以选择以下选项之一：

* 使用默认发布
* 使用另一个示例发布（例如 Armv82）
* 从可用的 ArmExtension 枚举值生成自定义发布

### 在 gem5 v21.2 之前

获取 Arm 架构功能同步版本的最佳方法是查看 Arm ID 寄存器和布尔值：

* [src/arch/arm/ArmISA.py](https://github.com/gem5/gem5/blob/v21.1.0.2/src/arch/arm/ArmISA.py)
* [src/arch/arm/ArmSystem.py](https://github.com/gem5/gem5/blob/v21.1.0.2/src/arch/arm/ArmSystem.py)
