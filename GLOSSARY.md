# gem5 中文术语表

本术语表用于规范 gem5 官网汉化过程中的专业名词翻译。

## 通用原则

1.  **gem5 大小写**：官方建议始终使用小写 `gem5`，即使在句首。如果必须大写（如编辑器强制），可写为 "The gem5 simulator"。
2.  **代码相关**：代码中的类名、函数名、变量名、参数名、文件路径、配置脚本名称**绝对保留英文**。
3.  **中英对照**：对于重要的专业术语，建议在文中首次出现时使用“中文 (English)”格式，后续使用中文。

---

## 核心概念 (Core Concepts)

| 英文 | 中文 | 备注 |
| :--- | :--- | :--- |
| **gem5** | gem5 | 始终小写 g |
| **SimObject** | SimObject | 模拟对象基类，不翻译 |
| **Tick** | Tick | 模拟时间的最小单位，不翻译 |
| **Event** | 事件 | 事件驱动模拟的核心 |
| **Event Queue** | 事件队列 | |
| **Port** | 端口 | 连接 SimObject 的接口 |
| **Requestor Port** | 请求端口 | 旧称 Master Port |
| **Responder Port** | 响应端口 | 旧称 Slave Port |
| **Peer** | 对等端 | 端口连接的另一端 |
| **Packet** | 包 / 数据包 | 内存系统中传输的数据单元 |
| **Drain** | 排空 | 模拟状态切换时的操作（清空流水线/缓存） |
| **Checkpoint** | 检查点 | 保存的模拟状态快照 |
| **Serialize** | 序列化 | 保存状态的过程 |
| **Unserialize** | 反序列化 | 恢复状态的过程 |
| **Stats** | 统计数据 / 统计信息 | |
| **Configuration Script** | 配置脚本 | 通常指 Python 脚本 |

## 模拟模式 (Simulation Modes)

| 英文 | 中文 | 备注 |
| :--- | :--- | :--- |
| **Full System (FS)** | 全系统模式 | 模拟完整的硬件系统，包括 OS |
| **System Emulation (SE)** | 系统仿真模式 | 仅模拟应用程序，通过 syscall 仿真 OS |
| **Guest** | 客户机 | 被模拟的系统 |
| **Host** | 宿主机 | 运行 gem5 的物理机 |
| **Workload** | 工作负载 | |
| **Benchmark** |由于基准测试程序 | |

## CPU 模型 (CPU Models)

| 英文 | 中文 | 备注 |
| :--- | :--- | :--- |
| **SimpleCPU** | SimpleCPU | 基础 CPU 模型系列，不翻译 |
| **AtomicSimpleCPU** | AtomicSimpleCPU | 原子访问模型，不翻译 |
| **TimingSimpleCPU** | TimingSimpleCPU | 时序访问模型，不翻译 |
| **O3CPU** | O3CPU | 乱序执行 (Out-of-Order) CPU 模型，不翻译 |
| **MinorCPU** | MinorCPU | 简单的按序流水线模型，不翻译 |
| **TraceCPU** | TraceCPU | 基于 Trace 回放的 CPU，不翻译 |
| **KVM CPU** | KVM CPU | 基于内核虚拟机的加速 CPU 模型 |
| **In-order** | 按序 | |
| **Out-of-order** | 乱序 | |
| **Pipeline** | 流水线 | |
| **Issue** | 发射 | 指令发射 |
| **Commit** | 提交 | 指令提交 |
| **Fetch** | 取指 | |
| **Decode** | 解码 | |

## 内存系统 (Memory System)

| 英文 | 中文 | 备注 |
| :--- | :--- | :--- |
| **Classic Memory** | 经典内存系统 | gem5 原生的内存模型 |
| **Ruby** | Ruby | 详细的缓存一致性内存系统，不翻译 |
| **Cache Coherence** | 缓存一致性 | |
| **Protocol** | 协议 | 指一致性协议 |
| **Snooping** | 监听 | 监听协议 |
| **Directory** | 目录 | 目录协议 |
| **Crossbar (XBar)** | 交叉开关 / 互连开关 | |
| **Interconnect** | 互连网络 | |
| **SLICC** | SLICC | Ruby 的状态机描述语言，不翻译 |
| **Garnet** | Garnet | 片上网络详细模型，不翻译 |
| **Topology** | 拓扑 | |
| **Mesh** | 网格 | |
| **Torus** | 环面 | |
| **Link** | 链路 | 网络链路 |
| **Router** | 路由器 | |
| **Buffer** | 缓冲区 | |

## 构建与环境 (Build & Environment)

| 英文 | 中文 | 备注 |
| :--- | :--- | :--- |
| **scons** | scons | 构建工具 |
| **build** | 构建 | 动词 |
| **compile** | 编译 | |
| **Target** | 目标 | 编译目标 |
| **Variant** | 变体 | 如 .opt, .debug, .fast |
| **Artifact** | 组件 / 制品 | gem5art 中的概念 |
| **Dependency** | 依赖项 | |
| **Repository** | 仓库 | |

## 其他常见词汇

| 英文 | 中文 | 备注 |
| :--- | :--- | :--- |
| **Documentation** | 文档 | |
| **Tutorial** | 教程 | |
| **Contribution** | 贡献 | |
| **Governance** | 治理 | |
| **Mailing List** | 邮件列表 | |
| **Release** | 发布 / 版本 | 视语境而定 |
