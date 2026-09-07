# 04 · 冒险、前递、暂停与冲刷

[阅读入口](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/README.md) · [未来定向实验](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/11-validation.md)

本章拆开解释单项依赖；[第 12 章完整程序](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/12-execution-walkthrough.md)把前递、load 重取、循环误预测和同址读写串成一条时间线。[D04 决策复盘](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/13-architecture-decisions.md#d04)进一步比较重取与保持插泡。

## 1. 先定位生产者和消费者

本项目主要在 ID 的寄存器读口前递，id_ex 再把选好的值寄存给 EX。顶层名称容易误导：id_reg1_rd_addr_o / id_reg2_rd_addr_o 来自当前 ID 译码，id_reg_wr_addr_o 已经过 id_ex，属于当前 EX 指令。load 检测正是利用这两代信息比较。[E05—E08](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

| 来源优先级 | A 选择条件概要 | B 选择条件概要 | 值来自哪里 |
|---|---|---|---|
| 最高 | 源地址=0 | 源地址=0 | 常数 0，屏蔽所有旁路 |
| EX | rd 命中、写使能且 not_mem | ex_bypass 命中 | 当前 EX 组合结果 |
| BUFFER | 不存在 | mbem_bypass 命中且 not_mem_from_buffer | EX 输出寄存器保存的较老结果 |
| MEM | rd 命中且写使能 | mem_bypass 命中 | 当前 MEM 组合完成值，包括 load 扩展 |
| WB | rd 命中且写使能 | wb_bypass 命中 | 即将写回的结果 |
| 最后 | 以上都不命中 | 以上都不命中 | 寄存器阵列旧值 |

要选择**最新且已就绪**的生产者。不能因为较旧值已经写回就跳过还没完成的新写入。not_mem 阻止把 load 地址当成寄存器结果；但仅屏蔽错误前递还不够，消费者必须等待真实结果。

## 2. 连续 ALU 依赖：结果走 EX → ID

~~~asm
addi x5, x0, 7
add  x6, x5, x5
sub  x7, x6, x5
~~~

静态推演前提：这些整数操作的译码有效、无重定向、时序满足。这里只展示前端共同部分，A/B 后端长度分别不同。

| 周期 | EX 中的指令 | ID 中的指令 | ID 采样什么 |
|---|---|---|---|
| C3 | addi x5，算出 7 | add x6 | 两个读口都选 EX 的 7 |
| C4 | add x6，算出 14 | sub x7 | x6 选 EX；x5 在 A 选 MEM，在 B 选 BUFFER |
| C5 | sub x7，算出 7 | 后继 | 后继按同样规则选值 |

收益是无需等到 GPR 写回；代价是形成从当前 EX 运算经旁路 MUX 到年轻指令 id_ex 输入的组合路径。它可能比只比较地址更长，所以前递本身也可能成为时序优化对象。此表是静态逻辑推演，不是仿真通过记录。

## 3. 多个来源命中：为什么不能随便选

~~~asm
addi x5, x0, 1
addi x5, x5, 1
add  x6, x5, x0
~~~

当第三条在 ID、第二条在 EX、第一条在 MEM（A）或 BUFFER（B）时，多个来源都写 x5。第三条必须读第二条的 2。gpr 的 if / else if 顺序使 EX 优先；若改成无优先的或运算或顺序颠倒，会读错值。两源依赖、同一个 rd 被连续覆盖，都是前递验证的必要场景。

## 4. 紧邻 load-use：当前代码用冲刷重取

~~~asm
L: lw  x5, 0(x10)
U: add x6, x5, x7
V: addi x8, x0, 1
~~~

A 在 L 位于 EX、U 位于 ID 时，比较 U 的源寄存器与 L 的 rd。命中单个源后，cu 令 jump=1、hold=1、目标=L.PC+4；EX_UNIT 编成 HOLD_ID_EX。PC 跳到 U，IF/ID 和 ID/EX 清为无副作用状态。L 自己继续前进。[E06](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

B 的 load_use 做类似比较，cu 把它并入 jump 和 hold；重定向目标也为当前 EX.PC+4。[E07](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

| 周期 | L / A | L / B | U 状态 | 边沿动作／取值 |
|---|---|---|---|---|
| C1 | IF | IF | — | — |
| C2 | ID | ID | IF | — |
| C3 | EX | EX | ID，结果未到 | 检测单源依赖；末端清空前端并把 PC 指回 U |
| C4 | MEM | BUFFER | 重新 IF | 前端还有清空后的气泡 |
| C5 | WB | MEM | 重新 ID | A 从 WB、B 从 MEM 取得 load 数据 |
| C6 | — | WB | EX | 用重新读取的操作数运算 |

这是**无重叠事件、非零 rd、有效 RAM 返回、复位完成**下的静态推演。与理想 U 在 C4 进入 EX 相比，本例 U 到 C6 才进入 EX，推演为多两拍。因此旧说法“本项目紧邻 load-use 一定插一拍”没有依据。该数字不是实测平均 CPI，也不外推到所有 load 和外设情况。

经典五级常保持 U 在 ID，只插一个气泡；项目把 U 清掉并重新取，结构可以更直接，却可能付出更多周期。改进时需要权衡控制简化与重取代价。

## 5. 隔一条 load-use：B 为什么多一层检测

~~~asm
L: lw   x5, 0(x10)
M: addi x8, x0, 1
U: add  x6, x5, x7
~~~

| 周期 | A | B |
|---|---|---|
| C3 | L 在 EX；M 在 ID，无依赖 | 同左 |
| C4 | L 在 MEM；M 在 EX；U 在 ID，可从 MEM 取得 x5 | L 在 BUFFER；M 在 EX；U 在 ID，BUFFER 的 load 值不可前递 |
| C4 末端 | U 正常进入 EX | load_any_use=1；目标=M.PC+4，也就是 U；清空前端 |
| C5 | U 在 EX | U 重新 IF，L 已在 MEM |
| C6 | U 继续后端 | U 重新 ID，L 在 WB，可读 x5 |
| C7 | — | U 在 EX |

同样是有条件静态推演。B 的检测把上一拍 EX 的 rd 保存为 reg_wr_addr_reg，并配合 is_load_o 判断 BUFFER 中的 load。不能仅凭名字把 load_any_use 说成全流水任意距离的通用依赖检测。

## 6. 双源同时依赖 load：A 的明确覆盖遗漏

~~~asm
lw  x5, 0(x10)
add x6, x5, x5
~~~

A 的比较结果为 2'b11，但 case 只处理 10、01，其余落到不触发重取的 default。这个**分支遗漏是源码事实**；在没有其他控制事件且寄存器旧值不同于内存值时，消费者可能带旧值前进。不要宣称本次已经仿真复现错误。

B 用 OR 合并两个源比较，逻辑上覆盖双源命中。仍应检查 rd=0、未使用源字段和复位状态；地址相等并不总代表语义上的真依赖。两版解码会把某些未使用源设为 0，因此 load 写 x0 时尤其可能产生无意义重取。[E06、E07](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

未来测试让 RAM 值=7、x5 旧值=99，期待 x6=14。观察检测位、跳转目标、消费者进入 id_ex 的值与最终写回；不能只检查程序没有卡住。

## 7. store 数据也是消费者

~~~asm
addi x5, x0, 42
sw   x5, 0(x10)
~~~

store 有两个不同依赖：rs1 决定地址，rs2 决定写数据。ID 前递必须分别处理两个读口；EX 保存 reg2_rd_data，B 还要通过 MEM_BUFFER 保存它。不能只验证 load 与算术，而漏掉 store 写入旧数据。

若改为 lw x5 后紧邻 sw x5，则是 load→store 数据依赖，应走相应重取。若 load 产生基地址 x10，store 的 rs1 也必须检查。store 本身不写 GPR，不应成为普通寄存器旁路的生产者。

## 8. 同址 store→load：寄存器旁路之外的第二类旁路

~~~asm
sw x5, 0(x10)
lw x6, 0(x10)
~~~

问题是 store 请求被寄存后，RAM 可能尚未在消费者需要时提供新数据。mem_wr_buffer 按 word 地址比较待写数据；B 同时比较当前写请求与上一拍缓存，优先当前写请求，再选缓存，最后取内存返回。[E10](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

| 关键时刻 | A | B |
|---|---|---|
| store 在 MEM | 生成写请求，末端保存进写缓存 | 同样保存；多出的 BUFFER 延迟已在前面发生 |
| 后继 load 需要返回 | 组合选择缓存数据或 RAM 返回 | 返回选择在时钟沿寄存，之后再由 MEM 扩展 |
| 最终验证 | 写入 x6 的必须是最新 store 值 | 还需检查当前写与缓存写同时命中的优先级 |

这里不填写未经确定的“RAM 完成写入固定第几拍”。RAM wrapper 另有同拍读写旁路，且 SB/SH 采用读改写；必须把请求、BRAM 输出、桥地址对齐、读返回寄存共同观察。见[访存图](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)和实验 V06。

## 9. 分支操作数依赖与冲刷

~~~asm
addi x5, x0, 1
beq  x5, x0, wrong
addi x6, x0, 7
~~~

branch 在 ID 同样需要最新 x5；若未前递，EX 会比较错误值，分支预测器再好也救不了“实际条件算错”。若前驱是 load，则先处理数据依赖，再讨论控制依赖。

独立的误预测例子：假设分支 P 在 C3 的 EX，预测不跳而实际跳，Y1 在 ID、Y2 在 IF。

| 周期 | 分支 P | 年轻指令 | PC / 后续 |
|---|---|---|---|
| C3 | EX 算出需跳转 | Y1、Y2 是错误路径 | 末端 PC=目标，前端清空 |
| C4 | 已过 EX | 两个位置为空 | 正确目标指令 IF |
| C5 | 后端继续 | 目标在 ID | 后继进入 IF |
| C6 | — | 目标在 EX | — |

前提是预测元数据与 P 对齐、没有重叠事件、ROM 延迟如配置。结构上两个年轻位置被杀，不能据此宣传已测出固定平均分支罚拍。

## 10. 暂停与冲刷同时出现，看真实优先级

A/B pc 均为复位 → 实际 jump → hold → 预测跳转 → PC+4。A EX_UNIT 中 jump 或内部 hold 优先于 rib_hold；活动 student_top 又将 rib_hold 固定为 0。不要把接口存在当成真实总线背压已验证。[E06、E07](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

B cu 同时有分支修正与 load_any_use 时，jump_addr1 的实际分支修正优先。必须按指令年龄理解：EX 中的分支较年轻前端指令更老，有资格杀掉它们。当前代码没有独立 valid 信号随预测元数据传递，连续分支、复位、气泡和重取时的对齐值得单独测试。

## 复试回答结构

“这是 RAW 依赖，消费者在 ID 采样。先判断生产者值是否已经可用：可用则按年龄优先前递；load 尚未返回时，当前代码用冲刷和重取延后消费者。B 增加 BUFFER 后还需要覆盖隔一条的依赖。代价包括选择逻辑、控制复杂度和重取周期，正确性应通过带已知结果的定向指令序列验证。”
