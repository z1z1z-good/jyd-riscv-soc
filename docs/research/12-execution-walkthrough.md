# 12 · 一段完整程序怎样穿过 A／B 电路

[阅读入口](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/README.md) · [单项冒险](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/04-hazards.md) · [架构决策复盘](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/13-architecture-decisions.md)

> 2026-09-06 补充；源码基线 bfd0e14fff512095bb8cb5ab9d8520b247069148。**本章是带前提的静态推演，不是运行日志、波形或功能通过证明。** 程序只写在文档中，没有生成或替换工程的 ROM／RAM 初始化文件。

本章将计算、访存和循环放进同一条时间线。读表时反复问三个问题：**这条指令属于哪一次循环？它读到的值来自哪个生产者？本拍末端到底写了哪个寄存器？** 这样才能把“五级／六级”变成对电路的理解。

<a id="premises"></a>

## 1. 推演契约：先规定什么情况下这张表成立

| 项目 | 本例约定及限制 |
|---|---|
| 版本 | A：five_level_200MHz_with_all_branch，五级；B：five_level_area_250M，六级 |
| 起点 | C1 为复位完成后第一条有效指令的 IF 周期；不计复位启动时间 |
| 初始化 | 假设 IROM 装入下列程序，RAM 指定三字；所用 GPR 均先定义后使用，不依赖阵列复位为零 |
| 预测器 | 冷启动：PHT=01，BTB 无效，A 的 CPT=00、GBHR=0；复位与启动留出至少三次时钟边沿让延迟历史稳定 |
| 存储 | 使用活动 BRAM 配置的同步返回；CPU、桥和 RAM 按其接线同拍工作，组合路径满足建立／保持要求 |
| 指令范围 | 仅 LUI、ADDI、ADD、LW、SW、BNE；自然对齐，地址落在两版共有的 RAM 低区 |
| 控制 | 没有外部背压、异步外设变化或额外重定向；预测方向与相应 EX 指令按两拍延迟对齐 |
| B 的关键限制 | rd_data_o 的 posedge 过程使用阻塞赋值；本表采用同步寄存器在边沿采样边沿前输入的硬件解释。实际 RTL 事件调度可能暴露竞争，未经过仿真确认 |
| 不覆盖 | A 双源同时依赖 load 的遗漏、连续相关分支、目标错配、SB／SH、MMIO、非法指令与异常。它们仍需独立测试 |

证据：取指边界 [E03](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e03)／[E04](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e04)，依赖控制 [E06](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e06)／[E07](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e07)，访存 [E09](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e09)／[E10](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e10)／[E11](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e11)／[E12](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e12)，预测 [E13](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e13)／[E14](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e14)／[E15](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e15)，译码 [E19](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e19)。

这张表表达“在这些条件成立时，电路应怎样传递指令与数据”。若未来波形不一致，先定位哪条前提不成立，不要把表格当成实现已经正确的证明。

<a id="program"></a>

## 2. 程序与预期结果

做两次“读一个数、加一、累加”，随后将结果写入 RAM，再立即读回并加一。

~~~text
输入：RAM[0x80100000] = 3
      RAM[0x80100004] = 5
      RAM[0x80100008] = 0
计算：sum = (3 + 1) + (5 + 1) = 10
输出：RAM[0x80100008] = 10；x14 = 10；x15 = 11；x16 = 1
~~~

逻辑指令地址从 0x80000000 开始。下表 PC 为字节偏移：完整逻辑地址为 0x80000000 加偏移；顶层导出的低 14 位 PC 在本例中等于偏移，IROM word 地址为偏移除以 4。

~~~asm
# 偏移  编号
# 00    I0
lui  x10, 0x80100
# 04    I1
addi x11, x0, 2
# 08    I2
addi x12, x0, 0

loop:
# 0c    I3：每次循环记为 L1 / L2
lw   x5, 0(x10)
# 10    I4：U1 / U2
addi x6, x5, 1
# 14    I5：S1 / S2
add  x12, x12, x6
# 18    I6：P1 / P2
addi x10, x10, 4
# 1c    I7：D1 / D2
addi x11, x11, -1
# 20    I8：B1 / B2
bne  x11, x0, loop

# 24    I9
lui  x13, 0x80100
# 28    I10
sw   x12, 8(x13)
# 2c    I11
lw   x14, 8(x13)
# 30    I12
addi x15, x14, 1
# 34    I13
addi x16, x0, 1
# 38 起：假设填充 addi x0, x0, 0，方便观察流水排空
~~~

BNE 的相对偏移是 0x0c−0x20=−20 字节。LUI 的立即数 0x80100 产生 0x80100000；所有实际访存字地址为 0、1、2。没有伪指令扩展导致的隐藏指令。

I13 只设置观察标志，**不是停机指令**。未来验证应在检测到 x16 写为 1 后结束观测，或者由测试平台停止时钟；本章不假设 CPU 支持 halt／ECALL。尾部 NOP 不计入下面的 20 条有意义动态指令。

~~~mermaid
flowchart TD
    Init["I0—I2：设置基址、次数和累加器"] --> Load["L：读当前输入"]
    Load --> Use["U：输入加一"]
    Use --> Sum["S：加入累加器"]
    Sum --> Ptr["P／D：地址加四、次数减一"]
    Ptr --> Branch{"BNE：次数不为零？"}
    Branch -->|"第一次：T"| Load
    Branch -->|"第二次：N"| Save["I9—I10：写出总和"]
    Save --> Read["I11—I12：同址读回并加一"]
    Read --> Done["I13：写入观察标志"]
~~~

图画的是程序语义，暂不表示流水重叠。下面才加入电路时间。

<a id="notation"></a>

## 3. 怎样读逐拍表

- **Ck** 是第 k 个时钟周期区间，**Ek** 是它末端的上升沿。例如 C8 在 ID 读到的数据，E8 写入 id_ex，C9 才由 EX 使用。
- **I0、L1 等标签**用于追踪指令身份。L1／L2 是同一静态 LW 的两次有效执行，不能把它们当成两处代码。
- **×** 标记最终被冲刷的取指尝试。U1× 与后来 U1 地址相同，但第一次没有进入 EX。I9×／I10× 是第一次分支的错误路径；L3×／U3× 是第二次分支误走的第三轮。
- **—** 表示没有本例有效指令；实现通常写入无副作用编码，并不表示 RTL 已有完整 valid 系统。**尾**表示 0x38 起的填充 NOP。
- 表中后端的指令标签是研究用的归属标记。实际寄存器保存的是 rd、写使能、数据、funct3、load／store 控制等，并非每一级都保存完整指令与 PC。
- WB 列意味着该指令的数据此时在写回通路上；GPR 在本拍末端采样。分支和 store 即使列在 WB，也没有 GPR 写入。

寄存边界对应如下。两版都不能通过数文件名来数流水级。

| 表中位置 | A 的实际边界／状态 | B 的实际边界／状态 |
|---|---|---|
| IF | PC 输出正在驱动 IROM | 同左，IROM 为异步输出 |
| ID | ROM 输出寄存器＋if_id 中的 PC／冲刷选择 | if_id 寄存的指令与 PC |
| EX | id_ex 保存的操作数、指令、PC、rd、立即数 | 同左 |
| BUFFER | 无 | EX_UNIT 输出寄存器中的指令控制与结果；本拍继续等待返回 |
| MEM | EX_UNIT 输出寄存器提供控制；读值组合选择和扩展 | MEM_BUFFER 输出提供控制；MEM_UNIT 内地址寄存与 rd_data_o 返回寄存配套 |
| WB | MEM_UNIT 输出寄存器保存待写值，经 WB_UNIT 接 GPR | 同左，较 A 多经历一级 |

来源：[流水专题](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/03-datapath.md)、[E05](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e05)／[E08](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e08)／[E09](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e09)／[E10](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e10)。

<a id="a-cycles"></a>

## 4. A：从第一次取指到 E34 写入观察标志

| 周期 | IF PC 偏移 | IF | ID | EX | MEM | WB | 事件 |
|---|---|---|---|---|---|---|---|
| C1 | 0x00 | I0 | — | — | — | — | — |
| C2 | 0x04 | I1 | I0 | — | — | — | — |
| C3 | 0x08 | I2 | I1 | I0 | — | — | — |
| C4 | 0x0c | L1 | I2 | I1 | I0 | — | — |
| C5 | 0x10 | U1× | L1 | I2 | I1 | I0 | — |
| C6 | 0x14 | S1× | U1× | L1 | I2 | I1 | E6：load 重取 → 10 |
| C7 | 0x10 | U1 | — | — | L1 | I2 | — |
| C8 | 0x14 | S1 | U1 | — | — | L1 | — |
| C9 | 0x18 | P1 | S1 | U1 | — | — | — |
| C10 | 0x1c | D1 | P1 | S1 | U1 | — | — |
| C11 | 0x20 | B1 | D1 | P1 | S1 | U1 | 预测 N，下一 PC=24 |
| C12 | 0x24 | I9× | B1 | D1 | P1 | S1 | — |
| C13 | 0x28 | I10× | I9× | B1 | D1 | P1 | E13：实际 T，修正 → 0c |
| C14 | 0x0c | L2 | — | — | B1 | D1 | — |
| C15 | 0x10 | U2× | L2 | — | — | B1 | — |
| C16 | 0x14 | S2× | U2× | L2 | — | — | E16：load 重取 → 10 |
| C17 | 0x10 | U2 | — | — | L2 | — | — |
| C18 | 0x14 | S2 | U2 | — | — | L2 | — |
| C19 | 0x18 | P2 | S2 | U2 | — | — | — |
| C20 | 0x1c | D2 | P2 | S2 | U2 | — | — |
| C21 | 0x20 | B2 | D2 | P2 | S2 | U2 | 预测 T，下一 PC=0c |
| C22 | 0x0c | L3× | B2 | D2 | P2 | S2 | — |
| C23 | 0x10 | U3× | L3× | B2 | D2 | P2 | E23：实际 N，修正 → 24 |
| C24 | 0x24 | I9 | — | — | B2 | D2 | — |
| C25 | 0x28 | I10 | I9 | — | — | B2 | — |
| C26 | 0x2c | I11 | I10 | I9 | — | — | — |
| C27 | 0x30 | I12× | I11 | I10 | I9 | — | — |
| C28 | 0x34 | I13× | I12× | I11 | I10 | I9 | E28：load 重取 → 30 |
| C29 | 0x30 | I12 | — | — | I11 | I10 | — |
| C30 | 0x34 | I13 | I12 | — | — | I11 | — |
| C31 | 0x38 | 尾 | I13 | I12 | — | — | — |
| C32 | 0x3c | 尾 | 尾 | I13 | I12 | — | — |
| C33 | 0x40 | 尾 | 尾 | 尾 | I13 | I12 | — |
| C34 | 0x44 | 尾 | 尾 | 尾 | 尾 | I13 | A：E34 写 done |

有三个 load 检测事件 E6／E16／E28，以及两个误预测修正 E13／E23。发生重定向时，EX 中的老指令继续，IF 与 ID 的年轻尝试被清掉。这里的“继续”意味着 load 仍能返回、较老的 ALU 指令仍能写回，绝不是整个 CPU 同时停住。

例如 E6 一边处理 L1 导致的前端重取，一边允许 I1 写 x11=2。E13 一边修正 B1 的分支，一边允许 P1 写入下一轮基址。控制与写回不是互相排斥的全局开关。

<a id="b-cycles"></a>

## 5. B：同样的前端轨迹，后端多一个边界

| 周期 | IF PC 偏移 | IF | ID | EX | BUFFER | MEM | WB | 事件 |
|---|---|---|---|---|---|---|---|---|
| C1 | 0x00 | I0 | — | — | — | — | — | — |
| C2 | 0x04 | I1 | I0 | — | — | — | — | — |
| C3 | 0x08 | I2 | I1 | I0 | — | — | — | — |
| C4 | 0x0c | L1 | I2 | I1 | I0 | — | — | — |
| C5 | 0x10 | U1× | L1 | I2 | I1 | I0 | — | — |
| C6 | 0x14 | S1× | U1× | L1 | I2 | I1 | I0 | E6：load 重取 → 10 |
| C7 | 0x10 | U1 | — | — | L1 | I2 | I1 | — |
| C8 | 0x14 | S1 | U1 | — | — | L1 | I2 | — |
| C9 | 0x18 | P1 | S1 | U1 | — | — | L1 | — |
| C10 | 0x1c | D1 | P1 | S1 | U1 | — | — | — |
| C11 | 0x20 | B1 | D1 | P1 | S1 | U1 | — | 预测 N，下一 PC=24 |
| C12 | 0x24 | I9× | B1 | D1 | P1 | S1 | U1 | — |
| C13 | 0x28 | I10× | I9× | B1 | D1 | P1 | S1 | E13：实际 T，修正 → 0c |
| C14 | 0x0c | L2 | — | — | B1 | D1 | P1 | — |
| C15 | 0x10 | U2× | L2 | — | — | B1 | D1 | — |
| C16 | 0x14 | S2× | U2× | L2 | — | — | B1 | E16：load 重取 → 10 |
| C17 | 0x10 | U2 | — | — | L2 | — | — | — |
| C18 | 0x14 | S2 | U2 | — | — | L2 | — | — |
| C19 | 0x18 | P2 | S2 | U2 | — | — | L2 | — |
| C20 | 0x1c | D2 | P2 | S2 | U2 | — | — | — |
| C21 | 0x20 | B2 | D2 | P2 | S2 | U2 | — | 预测 T，下一 PC=0c |
| C22 | 0x0c | L3× | B2 | D2 | P2 | S2 | U2 | — |
| C23 | 0x10 | U3× | L3× | B2 | D2 | P2 | S2 | E23：实际 N，修正 → 24 |
| C24 | 0x24 | I9 | — | — | B2 | D2 | P2 | — |
| C25 | 0x28 | I10 | I9 | — | — | B2 | D2 | — |
| C26 | 0x2c | I11 | I10 | I9 | — | — | B2 | — |
| C27 | 0x30 | I12× | I11 | I10 | I9 | — | — | — |
| C28 | 0x34 | I13× | I12× | I11 | I10 | I9 | — | E28：load 重取 → 30 |
| C29 | 0x30 | I12 | — | — | I11 | I10 | I9 | — |
| C30 | 0x34 | I13 | I12 | — | — | I11 | I10 | — |
| C31 | 0x38 | 尾 | I13 | I12 | — | — | I11 | — |
| C32 | 0x3c | 尾 | 尾 | I13 | I12 | — | — | — |
| C33 | 0x40 | 尾 | 尾 | 尾 | I13 | I12 | — | — |
| C34 | 0x44 | 尾 | 尾 | 尾 | 尾 | I13 | I12 | — |
| C35 | 0x48 | 尾 | 尾 | 尾 | 尾 | 尾 | I13 | B：E35 写 done |

本例刻意使用紧邻 load 消费者，重取后它重新进入 ID 时，B 的 load 恰好已到 MEM。因此两版的 EX 时间一致，B 的 GPR 写回整体晚一拍，最终标志在 E35 写入。

**这不代表任意程序中 A／B 都只差一拍。** 如果把独立指令排在 load 与消费者之间，A 可以在消费者 ID 时从 MEM 前递，B 的 load 还在 BUFFER，load_any_use 可能触发额外重取。参见[隔一条 load-use](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/04-hazards.md)；排指令时必须结合该实现的数据可用时刻。

<a id="operands"></a>

## 6. 操作数账本：值在写回前怎样被用到

“来自寄存器阵列”指本例在该时刻已经完成相应写回；“EX／MEM／WB”指 ID 的读口旁路来源。来源判断依据 [E05](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e05)／[E08](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e08)，不是假设 EX 阶段才选择所有操作数。

| 消费者 | 有效 ID 周期 | A 读值来源 | B 读值来源 | 随后 EX 的含义 |
|---|---|---|---|---|
| I0／I1／I2 | C2／C3／C4 | LUI 立即数；其余 x0=0 | 同左 | 定义基址、次数和总和 |
| L1 | C5 | I0 的 WB：x10=0x80100000 | I0 的 MEM：同值 | C6 发出输入 0 的地址 |
| U1 | C8 | L1 的 WB：x5=3 | L1 的 MEM：x5=3 | C9 算出 x6=4 |
| S1 | C9 | U1 的 EX：x6=4；阵列 x12=0 | 同左 | C10 算出总和 4 |
| P1 | C10 | 阵列 x10=0x80100000 | 同左 | C11 算出下一地址 |
| D1 | C11 | 阵列 x11=2 | 同左 | C12 算出剩余 1 次 |
| B1 | C12 | D1 的 EX：x11=1；x0=0 | 同左 | C13 实际跳转 |
| L2 | C15 | 阵列 x10=0x80100004 | 同左 | C16 发出输入 1 的地址 |
| U2 | C18 | L2 的 WB：x5=5 | L2 的 MEM：x5=5 | C19 算出 x6=6 |
| S2 | C19 | U2 的 EX：x6=6；阵列 x12=4 | 同左 | C20 算出总和 10 |
| P2 | C20 | 阵列 x10=0x80100004 | 同左 | C21 算出结束地址 |
| D2 | C21 | 阵列 x11=1 | 同左 | C22 算出剩余 0 次 |
| B2 | C22 | D2 的 EX：x11=0；x0=0 | 同左 | C23 实际不跳 |
| I9 | C25 | LUI 立即数 | 同左 | C26 算出输出区基址 |
| I10 | C26 | I9 的 EX：x13=基址；阵列 x12=10 | 同左 | C27 算地址并携带 store 数据 |
| I11 | C27 | I9 的 MEM：x13=基址 | I9 的 BUFFER：x13=基址 | C28 发出输出字地址 |
| I12 | C30 | I11 的 WB：x14=10 | I11 的 MEM：x14=10 | C31 算出 x15=11 |
| I13 | C31 | x0=0 | 同左 | C32 算出标志 1 |

### 把 C8／E8／C9 看成一张电路切片

在 A 的 C8，L1 的返回值已经存入 MEM_UNIT 输出寄存器，处于 WB。GPR 旁路把 3 送到 U1 的 ID 读口。E8 同时发生两件事：GPR 阵列写 x5=3，id_ex 保存 U1 的操作数 3。U1 并不需要等待阵列写入后再读一次。

在 B 的 C8，L1 的值来自 MEM 的组合完成通路，MEM_UNIT 输出寄存器尚未保存它。E8 将这个值分别送入写回寄存器和 U1 的 id_ex。下一拍 U1 执行、L1 在 WB；阵列到 E9 才写 x5。B 的读返回寄存化调度风险也正应沿这条路径检查。

### 为什么第一次 U1× 不能拿 EX 算出的“load 结果”

C6 的 L1 在 EX 得到的是地址 0x80100000，尚不是 RAM 中的 3。not_mem 阻止该地址充当 x5 的有效旁路。U1× 被清除，重新取指后才读取正确返回值。若只有“禁用 load 的 EX 旁路”，却不阻止消费者继续，消费者仍可能读到旧 x5。

本例用 ADDI 作 load 的消费者，只命中 rs1；A 的 case 缺少双源命中 11 的问题没有因此消失。将 U 改成 add x6,x5,x5，就是另一项应暴露该遗漏的测试，预期值也要改算。

<a id="memory"></a>

## 7. 内存账本：读到新值不代表 RAM 已先写完

下面细化的是本例对齐 SW→LW 的有条件时序，比[单项冒险章](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/04-hazards.md)的通用讨论多规定了 RAM、桥和边沿契约。不得外推为所有外设或部分写入的固定延迟。依据 [E09](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e09)／[E10](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e10)／[E11](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e11)／[E12](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e12)。

| 事件 | A | B |
|---|---|---|
| L1 地址 | C6 的 EX 给出 0x80100000，E6 由同步读链采样 | 同左 |
| L1 返回与扩展 | C7 的 MEM 使用返回 3；E7 保存 WB 值 | C7 的 BUFFER 对应返回链；E7 保存 rd_data_o；C8 的 MEM 使用 3 |
| L2 地址 | C16 给出 0x80100004，E16 采样 | 同左 |
| L2 返回与扩展 | C17 的 MEM 使用 5 | C18 的 MEM 使用 5 |
| I10 写出地址与数据 | C27 的 EX 算出 0x80100008，携带 x12=10 | 同左，随后还有 BUFFER |
| I10 的 MEM | C28 生成写请求，E28 保存进 mem_wr_buffer | C29 生成写请求，E29 保存进 mem_wr_buffer |
| I11 的早期读 | C28 的 EX 发出同址读，E28 采样；此时实际 RAM 仍可返回旧 0 | 同左，读返回还要在 E29 寄存 |
| I11 取得新 10 | C29 的 MEM 组合选择命中的待写缓存，绕过旧 RAM 值 | C29 时 I10 正在 MEM；E29 由“当前写请求命中”优先选 10，C30 的 MEM 使用寄存后的值 |
| RAM 实际采样 store | E29 采样 E28 已保存的写请求；按本例 IP 契约写入 10 | E30 采样 E29 已保存的写请求；按同样契约写入 10 |
| I11 保存 WB／写 GPR | E29 保存，E30 写 x14=10 | E30 保存，E31 写 x14=10 |

这里有**三种不同的“保存”**：保存待写请求、写进 RAM、保存 load 的返回。不能把它们统称为 MEM 写入。

B 的地址也要同时对齐：EX_UNIT 先将 C28 的读地址保存为 mem_rd_addr_to_mem；C29 它对应 BUFFER 中的 I11，并送到 mem_wr_buffer 的比较端。E29 的 MEM_UNIT 内部 mem_rd_addr_reg 再保存此地址，使 C30 的 load 扩展与 MEM_BUFFER 输出的 I11 控制配套。顶层没有使用 mem_rd_addr_buffer_mem，不代表地址完全没有延迟；真正使用的是内部这份寄存。

~~~mermaid
flowchart LR
    subgraph A["A：本例 C29"]
        AW["待写缓存：地址 +8，数据10"] --> AM["同址比较与组合选择"]
        AR["RAM 返回：可能仍为旧0"] --> AM
        AM --> AX["MEM 的 LW 值10"]
        AX --> AQ["E29：保存 WB 值"]
    end
    subgraph B["B：本例 E29 到 C30"]
        BW["MEM 当前 SW 请求：地址 +8，数据10"] --> BM["当前写优先的返回选择"]
        BR["缓存／RAM 返回"] --> BM
        BM --> BQ["E29：rd_data_o 保存10"]
        BQ --> BX["C30：MEM 的 LW 值10"]
    end
~~~

图只突出同址前递，省略了共同的桥和 BRAM 请求线；不能把 B 的 MEM_BUFFER 误认成图里的 rd_data_o。前者保存指令控制，后者保存返回数据。

**B 的同边沿阻塞赋值仍是待验证项。** 上表 E29／E30 的解释依赖寄存器边沿前值语义；不同 always 过程的仿真执行次序可能让下游观察到不同中间值。未来应检查 rd_data_o、reg_wr_data_first_o、MEM_UNIT 输出和 id_ex 采样值，不能凭最终结果恰巧正确就跳过对齐核查。

<a id="predictor"></a>

## 8. 两次循环怎样训练预测器

T 表示跳，N 表示不跳。这个程序只有一处真正执行的静态分支，PC 偏移 0x20，所以 AREA／BTB 索引为 PC[7:2]=8。本例其他地址没有占用同一表项；不会触发额外别名。下面的 PHT／CPT 数值都是二进制，索引 8／9 是十进制。依据 [E13](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e13)／[E14](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e14)／[E15](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md#e15)。

| 时刻 | A | B | 前端后果 |
|---|---|---|---|
| C11：第一次 B1 在 IF | AREA PHT[8]=01，BTB 无效；GLOBAL 也不跳；CPT[8]=00 选 AREA | PHT[8]=01，BTB 无效 | 最终预测 N，继续取 0x24 |
| C13：B1 在 EX | 用前递得到的 x11=1 判断实际 T | 同左 | E13 修正 PC=0x0c，杀 I9×／I10× |
| E13：第一次结果 | AREA PHT[8] 01→10；BTB 写目标 0x0c；GLOBAL 对应表项也训练，GBHR 0→1；两分量都错，CPT 不变 | 先寄存实际方向、目标、PC 与 is_branch | A 的训练此时发生，B 的前端修正并未等训练 |
| E14 | 延迟历史继续跟随 GBHR | PHT[8] 01→10，BTB 写目标 | 两版在第二次取分支前均已训练 |
| C21：第二次 B2 在 IF | AREA[8]=10 预测 T；GBHR=1，GLOBAL 索引 8 XOR 1=9，PHT[9]=01 预测 N；CPT[9]=00 仍选 AREA | PHT[8]=10，BTB 命中，预测 T | 两版都提前取第三轮 0x0c |
| C23：B2 在 EX | 前递得到 x11=0，实际 N | 同左 | E23 修正 PC=0x24，杀 L3×／U3× |
| E23：第二次结果 | AREA[8] 10→01；GLOBAL[9] 01→00；CPT[9] 00→01，仍未切换到 GLOBAL；GBHR_old 已为 1，GBHR 更新为二进制 10 | 寄存此次实际结果 | 第二次预测失败；A 分量意见不同 |
| E24 | 后续历史继续传播 | PHT[8] 10→01 | 程序进入最终写回段 |

第一次 GLOBAL 与 AREA 都预测错误，选择器没有依据偏向 GLOBAL。第二次 GLOBAL 正确、AREA 错误，CPT 只向 GLOBAL 迈一步，00→01 的最高位仍是 0。这能具体解释“组合预测”不是哪个分量这次正确就立即选哪个。

B 的“训练晚一拍”和“纠错晚一拍”也不能混用：cu 的实际重定向在 EX 当拍可用，延迟的是送往表更新的结果。这个例子中两版都在 E13／E23 修正。

两次都误预测的原因也不同：第一次是冷启动弱不跳与 BTB 未命中；第二次是刚学会跳转，循环便退出。不能据此判定预测器整体无用，或 A 的组合结构没有价值；两轮、单分支样本并不能衡量历史相关模式的收益。

<a id="writeback"></a>

## 9. 最终状态与周期账本

| 动态指令 | EX 周期 | A 写回边沿 | B 写回边沿 | 架构状态变化 |
|---|---|---|---|---|
| I0 | C3 | E5 | E6 | x10=0x80100000 |
| I1 | C4 | E6 | E7 | x11=2 |
| I2 | C5 | E7 | E8 | x12=0 |
| L1 | C6 | E8 | E9 | x5=3 |
| U1 | C9 | E11 | E12 | x6=4 |
| S1 | C10 | E12 | E13 | x12=4 |
| P1 | C11 | E13 | E14 | x10=0x80100004 |
| D1 | C12 | E14 | E15 | x11=1 |
| B1 | C13 | — | — | 无 GPR 写入 |
| L2 | C16 | E18 | E19 | x5=5 |
| U2 | C19 | E21 | E22 | x6=6 |
| S2 | C20 | E22 | E23 | x12=10 |
| P2 | C21 | E23 | E24 | x10=0x80100008 |
| D2 | C22 | E24 | E25 | x11=0 |
| B2 | C23 | — | — | 无 GPR 写入 |
| I9 | C26 | E28 | E29 | x13=0x80100000 |
| I10 | C27 | — | — | 无 GPR 写入；store |
| I11 | C28 | E30 | E31 | x14=10 |
| I12 | C31 | E33 | E34 | x15=11 |
| I13 | C32 | E34 | E35 | x16=1 |

从上表可重建任意时刻 GPR 的已写回状态：按边沿顺序应用已经发生的写入，尚未写回的值要去旁路中找。对尚未首次写入的非 x0 寄存器，值记为未知；不要补成 0。

程序最终还应满足 x10=0x80100008、x11=0、x12=10、x5=5、x6=6、x13=0x80100000，两个输入字保持 3、5。RAM 输出字从初始 0 变成 10；只有 I10 应造成一次有效程序 store。

**本例的条件性周期计算：**

~~~text
有意义动态指令 = 初始化3 + 两轮×6 + 收尾5 = 20
理想无气泡、含填充排空：A = 20+4 = 24；B = 20+5 = 25
本例：3次 load 重取×2拍 + 2次误预测×2拍 = 10拍
于是：A 的 done 写回 E34；B 的 done 写回 E35
~~~

这里的理想值是计算基准。重取与误预测的事件没有重叠，才可以这样相加。34／35 不是项目测得的 CPI、CoreMark 或完整启动耗时，也不能推出 B 在任意程序中更快。若需要比较执行时间，还要使用各版实际时钟、相同输入与边界，并先通过功能验证，参见[性能口径](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)。

<a id="verification"></a>

## 10. 将来如何把这章变成可验证实验

此处只给输入、观测和判定，**本次未执行**。可以作为[既有实验 V01—V09](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/11-validation.md)完成之后的综合案例；它不能替代双源 load 或连续分支等定向测试。

| 观察层次 | 输入／信号 | 判定 |
|---|---|---|
| 装载与起点 | 按本章地址汇编，核对反汇编偏移；初始化三字；记录复位释放与 C1 | BNE 目标准确；预测冷态满足约定；不能假定工程现有 COE 就是本程序 |
| 前端身份 | IF PC、ID 指令／PC、id_ex 指令／PC、jump／hold | 五次重定向的地址依次为 10、0c、10、24、30；被杀尝试不得进入有效 EX |
| 操作数 | 两个 ID 读口、旁路命中、EX 输入、各级 rd／写使能 | 对照操作数账本，尤其 C8、C18、C26、C27、C30 |
| 内存配对 | EX 读地址、桥延迟地址、BRAM 返回、写缓存、B 的 rd_data_o 与 mem_rd_addr_reg | 返回必须属于对应 load；I10 仅一次有效写，I11 读到 10 |
| 预测训练 | 预测时方向与索引、EX 真实方向、PHT／BTB／CPT／GBHR | 对照两次事件；B 的训练晚一拍，修正仍在 EX |
| 结果 | GPR 写端、实际 RAM 写端、done 写回 | 符合结果账本；错误路径没有 GPR 或 store 副作用 |
| 差异定位 | 波形逐边沿对照，并单独检查 B 的阻塞时序过程 | 不符时记录首个差异与原因；不能只修改预期表直到通过 |

**复试自测：** 为什么 C12 分支已经读到 1，而 D1 还没写回？为什么 U1× 被杀以后 L1 没被杀？为什么 B 的 I11 在 BUFFER 时仍不能普通前递 load 值？为什么先读到 store 的 10，不要求 RAM 更早完成写入？为什么两版本例都有两次误预测，却不能说明预测器等效？

答案分别落在[操作数账本](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/12-execution-walkthrough.md#operands)、[逐拍表](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/12-execution-walkthrough.md#a-cycles)、[内存账本](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/12-execution-walkthrough.md#memory)与[预测训练](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/12-execution-walkthrough.md#predictor)。能沿这些表解释，而不只背最终数值，就掌握了完整执行链。
