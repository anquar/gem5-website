---
layout: documentation
title: X86 微操作 ISA
doc: gem5 documentation
parent: architecture_support
permalink: documentation/general_docs/architecture_support/x86_microop_isa/
---

# 寄存器操作
这些微操作通常采用两个源并产生一个结果。大多数都有一个仅对寄存器进行操作的版本和一个对寄存器和立即数进行操作的版本。有些根据其操作可选择设置标志。其中一些可以被断言 (predicated)。

### Add
加法。

#### add Dest, Src1, Src2
Dest # Dest <- Src1 + Src2

将 Src1 和 Src2 寄存器的内容相加，并将结果放入 Dest 寄存器。

#### addi Dest, Src1, Imm
Dest # Dest <- Src1 + Imm

将 Src1 寄存器的内容与立即数 Imm 相加，并将结果放入 Dest 寄存器。

#### 标志
此微操作可选择设置 CF, ECF, ZF, EZF, PF, AF, SF, 和 OF 标志。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 最高有效位的进位输出。
ZF 和 EZF | 结果是否为零。
PF         | 结果的奇偶校验。
AF         | 从第四位到第五位的进位。
SF	   | 结果的符号。
OF	   | 是否有溢出。

### Adc
带进位加法。

#### adc Dest, Src1, Src2
Dest # Dest <- Src1 + Src2 + CF

将 Src1 和 Src2 寄存器的内容与进位标志相加，并将结果放入 Dest 寄存器。

#### adci Dest, Src1, Imm
Dest # Dest <- Src1 + Imm + CF

将 Src1 寄存器的内容、立即数 Imm 和进位标志相加，并将结果放入 Dest 寄存器。

#### 标志
此微操作可选择设置 CF, ECF, ZF, EZF, PF, AF, SF, 和 OF 标志。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 最高有效位的进位输出。
ZF 和 EZF | 结果是否为零。
PF         | 结果的奇偶校验。
AF         | 从第四位到第五位的进位。
SF	   | 结果的符号。
OF	   | 是否有溢出。

### Sub
减法。

#### sub Dest, Src1, Src2
Dest # Dest <- Src1 - Src2

从 Src1 寄存器中减去 Src2 寄存器的内容，并将结果放入 Dest 寄存器。

#### subi Dest, Src1, Imm
Dest # Dest <- Src1 - Imm

从 Src1 寄存器中减去立即数 Imm 的内容，并将结果放入 Dest 寄存器。

#### 标志
此微操作可选择设置 CF, ECF, ZF, EZF, PF, AF, SF, 和 OF 标志。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 最高有效位的借位。
ZF 和 EZF | 结果是否为零。
PF         | 结果的奇偶校验。
AF         | 从第四位到第五位的借位。
SF	   | 结果的符号。
OF	   | 是否有溢出。

### Sbb

带借位减法。

#### sbb Dest, Src1, Src2
Dest # Dest <- Src1 - Src2 - CF

从 Src1 寄存器中减去 Src2 寄存器的内容和进位标志，并将结果放入 Dest 寄存器。

#### sbbi Dest, Src1, Imm
Dest # Dest <- Src1 - Imm - CF

从 Src1 寄存器中减去立即数 Imm 和进位标志，并将结果放入 Dest 寄存器。

#### 标志
此微操作可选择设置 CF, ECF, ZF, EZF, PF, AF, SF, 和 OF 标志。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 最高有效位的借位。
ZF 和 EZF | 结果是否为零。
PF         | 结果的奇偶校验。
AF         | 从第四位到第五位的借位。
SF	   | 结果的符号。
OF	   | 是否有溢出。

### Mul1s

有符号乘法。

#### mul1s Src1, Src2
ProdHi:ProdLo # Src1 * Src2

将 Src1 和 Src2 寄存器的无符号内容相乘，并将乘积的高位和低位部分分别放入内部寄存器 ProdHi 和 ProdLo 中。

#### mul1si Src1, Imm
ProdHi:ProdLo # Src1 * Imm

将 Src1 寄存器的无符号内容与立即数 Imm 相乘，并将乘积的高位和低位部分分别放入内部寄存器 ProdHi 和 ProdLo 中。

#### 标志
此微操作不设置任何标志。

### Mul1u

无符号乘法。

#### mul1u Src1, Src2
ProdHi:ProdLo # Src1 * Src2

将 Src1 和 Src2 寄存器的无符号内容相乘，并将乘积的高位和低位部分分别放入内部寄存器 ProdHi 和 ProdLo 中。

#### mul1ui Src1, Imm
ProdHi:ProdLo # Src1 * Imm

将 Src1 寄存器的无符号内容与立即数 Imm 相乘，并将乘积的高位和低位部分分别放入内部寄存器 ProdHi 和 ProdLo 中。

#### 标志
此微操作不设置任何标志。

### Mulel

卸载乘法结果低位。

#### mulel Dest
Dest # Dest <- ProdLo

将内部 ProdLo 寄存器的值移动到 Dest 寄存器中。

#### 标志
此微操作不设置任何标志。

### Muleh

卸载乘法结果高位。

#### muleh Dest
Dest # Dest <- ProdHi

将内部 ProdHi 寄存器的值移动到 Dest 寄存器中。

#### 标志
此微操作可选择设置 CF, ECF, 和 OF 标志。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | ProdHi 是否非零。
OF	   | ProdHi 是否为零。

### Div1

除法的第一阶段。

#### div1 Src1, Src2
Quotient * Src2 + Remainder # Src1
Divisor # Src2

开始除法运算，其中 SrcReg1 的内容是被除数的高位部分，SrcReg2 的内容是除数。此部分除法的余数放入内部寄存器 Remainder 中。商放入内部寄存器 Quotient 中。除数放入内部寄存器 Divisor 中。

#### div1i Src1, Imm:
Quotient * Imm + Remainder # Src1
Divisor # Imm

开始除法运算，其中 SrcReg1 的内容是被除数的高位部分，立即数 Imm 是除数。此部分除法的余数放入内部寄存器 Remainder 中。商放入内部寄存器 Quotient 中。除数放入内部寄存器 Divisor 中。

#### 标志
此微操作不设置任何标志。

### Div2

除法的第二阶段及后续阶段。

#### div2 Dest, Src1, Src2
Quotient * Divisor + Remainder # 原始 Remainder 与从 Src1 移入的位

Dest # Dest <- Src2 - 上面移入的位数

执行 div1 指令后的除法后续步骤。寄存器 Src1 的内容是被除数的低位部分。寄存器 Src2 的内容表示在此除法步骤之前 Src1 中尚未使用的位数。Dest 设置为在此步骤之后 Src1 中尚未使用的位数。内部寄存器 Quotient、Divisor 和 Remainder 由此指令更新。

如果 Src1 中没有剩余位，则此指令除了可选择计算标志外不执行任何操作。

#### div2i Dest, Src1, Imm
Quotient * Divisor + Remainder # 原始 Remainder 与从 Src1 移入的位

Dest # Dest <- Imm - 上面移入的位数

执行 div1 指令后的除法后续步骤。寄存器 Src1 的内容是被除数的低位部分。立即数 Imm 表示在此除法步骤之前 Src1 中尚未使用的位数。Dest 设置为在此步骤之后 Src1 中尚未使用的位数。内部寄存器 Quotient、Divisor 和 Remainder 由此指令更新。

如果 Src1 中没有剩余位，则此指令除了可选择计算标志外不执行任何操作。

#### 标志
此微操作可选择设置 EZF 标志。

标志       | 含义
---------- | ------------------------------------------
EZF	   | 在此步骤之后 Src1 中是否还有任何剩余位。

### Divq

卸载除法商。

#### divq Dest
Dest # Dest <- Quotient

将内部 Quotient 寄存器的值移动到 Dest 寄存器中。

#### 标志
此微操作不设置任何标志。

### Divr

卸载除法余数。

#### divr Dest
Dest # Dest <- Remainder

将内部 Remainder 寄存器的值移动到 Dest 寄存器中。

#### 标志
此微操作不设置任何标志。

### Or

逻辑或。

#### or Dest, Src1, Src2
Dest # Dest <- Src1 | Src2

计算 Src1 和 Src2 寄存器内容的按位或，并将结果放入 Dest 寄存器中。

#### ori Dest, Src1, Imm
Dest # Dest <- Src1 | Imm

计算 Src1 寄存器内容和立即数 Imm 的按位或，并将结果放入 Dest 寄存器中。

#### 标志
此微操作可选择设置 CF, ECF, ZF, EZF, PF, AF, SF, 和 OF 标志。
没有什么能阻止计算 AF 标志的值，但其值将毫无意义。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 清除。
ZF 和 EZF | 结果是否为零。
PF         | 结果的奇偶校验。
AF         | 未定义。
SF	   | 结果的符号。
OF	   | 清除。

### And

逻辑与

#### and Dest, Src1, Src2
Dest # Dest <- Src1 & Src2

计算 Src1 和 Src2 寄存器内容的按位与，并将结果放入 Dest 寄存器中。

#### andi Dest, Src1, Imm
Dest # Dest <- Src1 & Imm

计算 Src1 寄存器内容和立即数 Imm 的按位与，并将结果放入 Dest 寄存器中。

#### 标志
此微操作可选择设置 CF, ECF, ZF, EZF, PF, AF, SF, 和 OF 标志。
没有什么能阻止计算 AF 标志的值，但其值将毫无意义。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 清除。
ZF 和 EZF | 结果是否为零。
PF         | 结果的奇偶校验。
AF         | 未定义。
SF	   | 结果的符号。
OF	   | 清除。

### Xor

逻辑异或。

#### xor Dest, Src1, Src2
Dest # Dest <- Src1 | Src2

计算 Src1 和 Src2 寄存器内容的按位异或，并将结果放入 Dest 寄存器中。

#### xori Dest, Src1, Imm
Dest # Dest <- Src1 | Imm

计算 Src1 寄存器内容和立即数 Imm 的按位异或，并将结果放入 Dest 寄存器中。

#### 标志
此微操作可选择设置 CF, ECF, ZF, EZF, PF, AF, SF, 和 OF 标志。
没有什么能阻止计算 AF 标志的值，但其值将毫无意义。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 清除。
ZF 和 EZF | 结果是否为零。
PF         | 结果的奇偶校验。
AF         | 未定义。
SF	   | 结果的符号。
OF	   | 清除。

### Sll

逻辑左移。

#### sll Dest, Src1, Src2
Dest # Dest <- Src1 << Src2

将 Src1 寄存器的内容向左移动 Src2 寄存器中的值，并将结果写入 Dest 寄存器。移位量被截断为 5 或 6 位，具体取决于操作数大小。

#### slli Dest, Src1, Imm
Dest # Dest <- Src1 << Imm

将 Src1 寄存器的内容向左移动立即数 Imm 中的值，并将结果写入 Dest 寄存器。移位量被截断为 5 或 6 位，具体取决于操作数大小。

#### 标志
此微操作可选择设置 CF, ECF, 和 OF 标志。如果移位量为零，则不修改任何标志。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 移出结果的最后一位。
OF	   | 如果请求，此指令将设置 CF 标志的值与结果的最高有效位的异或。

### Srl

逻辑右移。

#### srl Dest, Src1, Src2
Dest # Dest <- Src1 >>(logical) Src2

将 Src1 寄存器的内容向右移动 Src2 寄存器中的值，并将结果写入 Dest 寄存器。移入的位对结果进行符号扩展。移位量被截断为 5 或 6 位，具体取决于操作数大小。

#### srli Dest, Src1, Imm
Dest # Dest <- Src1 >>(logical) Imm

将 Src1 寄存器的内容向右移动立即数 Imm 中的值，并将结果写入 Dest 寄存器。移入的位对结果进行符号扩展。移位量被截断为 5 或 6 位，具体取决于操作数大小。

#### 标志
此微操作可选择设置 CF, ECF, 和 OF 标志。如果移位量为零，则不修改任何标志。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 移出结果的最后一位。
SF	   | 原始值的最高有效位。

### Sra

算术右移。

#### sra Dest, Src1, Src2
Dest # Dest <- Src1 >>(arithmetic) Src2

将 Src1 寄存器的内容向右移动 Src2 寄存器中的值，并将结果写入 Dest 寄存器。移入的位对结果进行零扩展。移位量被截断为 5 或 6 位，具体取决于操作数大小。

#### srai Dest, Src1, Imm
Dest # Dest <- Src1 >>(arithmetic) Imm

将 Src1 寄存器的内容向右移动立即数 Imm 中的值，并将结果写入 Dest 寄存器。移入的位对结果进行零扩展。移位量被截断为 5 或 6 位，具体取决于操作数大小。

#### 标志
此微操作可选择设置 CF, ECF, 和 OF 标志。如果移位量为零，则不修改任何标志。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 移出结果的最后一位。
OF	   | 清除。

### Ror

向右旋转。

#### ror Dest, Src1, Src2
将 Src1 寄存器的内容向右旋转 Src2 寄存器中的值，并将结果写入 Dest 寄存器。旋转量被截断为 5 或 6 位，具体取决于操作数大小。

#### rori Dest, Src1, Imm
将 Src1 寄存器的内容向右旋转立即数 Imm 中的值，并将结果写入 Dest 寄存器。旋转量被截断为 5 或 6 位，具体取决于操作数大小。

#### 标志
此微操作可选择设置 CF, ECF, 和 OF 标志。如果旋转量为零，则不修改任何标志。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 结果的最高有效位。
OF	   | 原始值的最高两位有效位的异或。

### Rcr

通过进位向右旋转。

#### rcr Dest, Src1, Src2
将 Src1 寄存器的内容通过进位标志向右旋转 Src2 寄存器中的值，并将结果写入 Dest 寄存器。旋转量被截断为 5 或 6 位，具体取决于操作数大小。

#### rcri Dest, Src1, Imm
将 Src1 寄存器的内容通过进位标志向右旋转立即数 Imm 中的值，并将结果写入 Dest 寄存器。旋转量被截断为 5 或 6 位，具体取决于操作数大小。

#### 标志
此微操作可选择设置 CF, ECF, 和 OF 标志。如果旋转量为零，则不修改任何标志。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 移出结果的最后一位。
OF	   | 旋转前 CF 标志与原始值的最高有效位的异或。

### Rol

向左旋转。

#### rol Dest, Src1, Src2
将 Src1 寄存器的内容向左旋转 Src2 寄存器中的值，并将结果写入 Dest 寄存器。旋转量被截断为 5 或 6 位，具体取决于操作数大小。

#### roli Dest, Src1, Imm
将 Src1 寄存器的内容向左旋转立即数 Imm 中的值，并将结果写入 Dest 寄存器。旋转量被截断为 5 或 6 位，具体取决于操作数大小。

#### 标志
此微操作可选择设置 CF, ECF, 和 OF 标志。如果旋转量为零，则不修改任何标志。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 结果的最低有效位。
OF	   | 结果的最高和最低有效位的异或。

### Rcl

通过进位向左旋转。

#### rcl Dest, Src1, Src2
将 Src1 寄存器的内容通过进位标志向左旋转 Src2 寄存器中的值，并将结果写入 Dest 寄存器。旋转量被截断为 5 或 6 位，具体取决于操作数大小。

#### rcli Dest, Src1, Imm
将 Src1 寄存器的内容通过进位标志向左旋转立即数 Imm 中的值，并将结果写入 Dest 寄存器。旋转量被截断为 5 或 6 位，具体取决于操作数大小。

#### 标志
此微操作可选择设置 CF, ECF, 和 OF 标志。如果旋转量为零，则不修改任何标志。

标志       | 含义
---------- | ------------------------------------------
CF 和 ECF | 旋转出结果的最后一位。
OF	   | 旋转前 CF 与结果的最高有效位的异或。

### Mov

移动。

#### mov Dest, Src1, Src2
Dest # Src1 <- Src2

将 Src2 寄存器的内容合并到 Src1 的内容中，并将结果放入 Dest 寄存器中。

#### movi Dest, Src1, Imm
Dest # Src1 <- Imm

将立即数 Imm 的内容合并到 Src1 的内容中，并将结果放入 Dest 寄存器中。

#### 标志
此微操作不设置任何标志。它是可选断言的。

### Sext

符号扩展。

#### sext Dest, Src1, Imm
Dest # Dest <- sign_extend(Src1, Imm)

从立即数 Imm 中的位位置开始对 Src1 寄存器中的值进行符号扩展，并将结果放入 Dest 寄存器中。

#### 标志
此微操作不设置任何标志。

### Zext

零扩展。

#### zext Dest, Src1, Imm
Dest # Dest <- zero_extend(Src1, Imm)

从立即数 Imm 中的位位置开始对 Src1 寄存器中的值进行零扩展，并将结果放入 Dest 寄存器中。

#### 标志
此微操作不设置任何标志。

### Ruflag

读取用户标志。

#### ruflag Dest, Imm
读取立即数 Imm 指定的位位置中存储的用户级标志，并将其存储在寄存器 Dest 中。

Imm 值与用户级标志之间的映射如下表所示。

Imm        | 标志
---------- | ------------------------------------------
0          | CF (进位标志)
2          | PF (奇偶校验标志)
3          | ECF (仿真进位标志)
4          | AF (辅助标志)
5          | EZF (仿真零标志)
6          | ZF (零标志)
7          | CF (符号标志)
10         | CF (方向标志)
11         | CF (溢出标志)

#### 标志
EZF 标志始终设置。将来这可能会变成可选的。


### Ruflags

读取所有用户标志。

#### ruflags Dest
Dest # user flags

将用户级标志存储到 Dest 寄存器中。

#### 标志
此微操作不设置任何标志。

### Wruflags

写入所有用户标志。

#### wruflags Src1, Src2
user flags # Src1 ^ Src2

将用户级标志设置为 Src1 和 Src2 寄存器的异或。

#### wruflagsi Src1, Imm
user flags # Src1 ^ Imm

将用户级标志设置为 Src1 寄存器和立即数 Imm 的异或。

#### 标志
见上文。

### Rdip

读取指令指针。

#### rdip Dest
Dest # rIP

将 Dest 寄存器设置为 rIP 的当前值。

#### 标志
此微操作不设置任何标志。

### Wrip

写入指令指针。

#### wrip Src1, Src2
rIP # Src1 + Src2

将 rIP 设置为 Src1 和 Src2 寄存器之和。这会导致当前宏操作结束时的宏操作分支。

#### wripi Src1, Imm
micropc # Src1 + Imm

将 rIP 设置为 Src1 寄存器和立即数 Imm 之和。这会导致当前宏操作结束时的宏操作分支。

#### 标志
此微操作不设置任何标志。它是可选断言的。

### Chks
检查选择器。

尚未实现。

# 加载/存储操作 (Load/Store Ops)

### Ld
加载。
#### ld Data, Seg, Sib, Disp
从内存加载整数寄存器 Data。

### Ldf
加载浮点。
#### ldf Data, Seg, Sib, Disp
从内存加载浮点寄存器 Data。

### Ldm
加载多媒体。
#### ldm Data, Seg, Sib, Disp
从内存加载多媒体寄存器 Data。
这未实现，可能永远不会实现。

### Ldst
加载并检查存储。
#### Ldst Data, Seg, Sib, Disp
从内存加载整数寄存器 Data，同时还要检查该位置的存储是否会成功。
目前尚未实现。

### Ldstl
加载并检查存储，锁定。
#### Ldst Data, Seg, Sib, Disp
从内存加载整数寄存器 Data，同时还要检查该位置的存储是否会成功，并提供 "LOCK" 指令前缀的语义。
目前尚未实现。

### St
存储。
#### st Data, Seg, Sib, Disp
将整数寄存器 Data 存储到内存。

### Stf
存储浮点。
#### stf Data, Seg, Sib, Disp
将浮点寄存器 Data 存储到内存。

### Stm
存储多媒体。
#### stm Data, Seg, Sib, Disp
将多媒体寄存器 Data 存储到内存。
这未实现，可能永远不会实现。

### Stupd
带基址更新的存储。
#### Stupd Data, Seg, Sib, Disp
将整数寄存器 Data 存储到内存并更新基址寄存器。

### Lea
加载有效地址。
#### lea Data, Seg, Sib, Disp
计算此参数组合的地址并将其存储在 Data 中。

### Cda
检查数据地址。
#### cda Seg, Sib, Disp
检查数据地址是否有效。
目前尚未实现。

### Cdaf
带缓存行刷新的 CDA。
#### cdaf Seg, Sib, Disp
检查数据地址是否有效，并刷新缓存行。
目前尚未实现。

### Cia
检查指令地址。
#### cia Seg, Sib, Disp
检查指令地址是否有效。
目前尚未实现。

### Tia
TLB 无效地址
#### tia Seg, Sib, Disp
使对应于此地址的 tlb 条目无效。
目前尚未实现。

# 加载立即数操作 (Load immediate Op)

### Limm
#### limm Dest, Imm
将 64 位立即数 Imm 存储到整数寄存器 Dest 中。

# 浮点操作 (Floating Point Ops)

### Movfp
#### movfp Dest, Src
Dest # Src

将浮点寄存器 Src 的内容移动到浮点寄存器 Dest 中。

此指令是断言的。

### Xorfp
#### xorfp Dest, Src1, Src2
Dest # Src1 ^ Src2

计算浮点寄存器 Src1 和 Src2 的按位异或，并将结果放入浮点寄存器 Dest 中。

### Sqrtfp
#### sqrtfp Dest, Src
Dest # sqrt(Src)

计算浮点寄存器 Src 的平方根，并将结果放入浮点寄存器 Dest 中。

### Addfp
#### addfp Dest, Src1, Src2
Dest # Src1 + Src2

计算浮点寄存器 Src1 和 Src2 的和，并将结果放入浮点寄存器 Dest 中。

### Subfp
#### subfp Dest, Src1, Src2
Dest # Src1 - Src2

计算浮点寄存器 Src1 和 Src2 的差，并将结果放入浮点寄存器 Dest 中。

### Mulfp
#### mulfp Dest, Src1, Src2
Dest # Src1 * Src2

计算浮点寄存器 Src1 和 Src2 的积，并将结果放入浮点寄存器 Dest 中。

### Divfp
#### divfp Dest, Src1, Src2
Dest # Src1 / Src2

用 Src1 除以 Src2，并将结果放入浮点寄存器 Dest 中。

### Compfp
#### compfp Src1, Src2
比较浮点寄存器 Src1 和 Src2。

### Cvtf_i2d
#### cvtf_i2d Dest, Src
将整数寄存器 Src 转换为双精度浮点值，并将结果存储在 Dest 的下半部分。

### Cvtf_i2d_hi
#### cvtf_i2d_hi Dest, Src
将整数寄存器 Src 转换为双精度浮点值，并将结果存储在 Dest 的上半部分。

### Cvtf_d2i
#### cvtf_d2i Dest, Src
将浮点寄存器 Src 转换为整数值，并将结果存储在整数寄存器 Dest 中。

# 特殊操作 (Special Ops)

### Fault
生成故障。
#### fault fault_code
使用 C++ 代码 fault_code 分配要返回的 Fault 对象。

### Lddha
设置故障的默认处理程序。
目前尚未实现。

### Ldaha
设置故障的备用处理程序
目前尚未实现。

# 排序操作 (Sequencing Ops)
这些微操作用于微码内的控制流

### Br

微码分支。这永远不被视为序列的最后一个微操作。如果它出现在宏操作的末尾，则假定它分支到 ROM 中的微码。

#### br target
micropc # target

将 micropc 设置为 16 位立即数 target。

#### 标志
此微操作不设置任何标志。它是可选断言的。

### Eret

从仿真返回。此指令始终被视为序列中的最后一个微操作。从 ROM 执行时，这是返回正常指令解码的唯一方法。

#### eret

从仿真返回。

#### 标志
此微操作不设置任何标志。它是可选断言的。
