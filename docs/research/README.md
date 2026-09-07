# 00 · JYD 项目重新理解与复试阅读入口

> 研究日期：2026-09-05。源码基线：bfd0e14fff512095bb8cb5ab9d8520b247069148；开始研究时工作树干净。研究方式：静态读码、配置与历史报告核对、可访问历史对话考证。没有运行仿真、综合、布局布线或上板测试。

2026-09-06 补充第 12、13 章：同一段完整程序的 A／B 逐拍推演，以及十项架构决策复盘。仍沿用上述源码基线；新增内容属于静态推断和待验证方案。

这套文档帮助你重新建立三个层次的理解：**指令要完成什么、硬件怎样让它正确完成、工程为了速度付出什么代价**。阅读起点是“学过五级流水，但可能忘了细节”。单周期只作简短参照，不作为教程主线。

## 先记住这张表

A 指目录 five_level_200MHz_with_all_branch，B 指 five_level_area_250M。目录名不等于实际时钟，也不保证流水级数。

| 维度 | A | B | 怎样证明 |
|---|---|---|---|
| 逻辑流水 | IF / ID / EX / MEM / WB | IF / ID / EX / BUFFER / MEM / WB | 沿有效 RTL 和 IP 找寄存边界 |
| CPU 配置时钟 | 150 MHz | 250 MHz | PLL XCI 与历史 clock summary |
| 取指边界 | ROM 输出寄存，if_id 指令组合直通 | ROM 异步，if_id 寄存指令 | ROM 的 output_options 与 if_id |
| 预测器 | Gshare 风格分量＋Bimodal＋CPT，两套 BTB | Bimodal＋一套 BTB | 实例、表索引、更新逻辑 |
| 寄存器前递 | EX / MEM / WB 三源，送到 ID 读口 | EX / BUFFER / MEM / WB 四源，送到 ID 读口 | gpr 选择优先级及顶层连线 |
| load-use | 检测后冲刷并重取后继；双源同时命中遗漏 | 增加隔一条 load 的检测，仍有冲刷重取 | 不能直接套用教材“一拍暂停” |
| 数据 RAM 配置容量 | 64 KiB | 256 KiB | BRAM 的 word 深度乘以 4 字节 |
| 历史 setup WNS | +0.865 ns | +0.035 ns | 整理前 routed report |
| 历史 LUT / FF / BRAM tile | 5482 / 4111 / 16 | 4448 / 2622 / 64 | placed utilization，整个 top |
| 工具估计片上功耗 | 0.450 W | 0.540 W | Medium 置信度，无仿真活动文件 |

来源：[证据索引 E01—E18](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)。历史时序报告还存在约束覆盖问题，见[时序专题](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)。这张表不构成 IPC、CoreMark、极限 Fmax 或整机可靠性的证明。

## 三条阅读路线

| 目的 | 阅读顺序 | 完成标志 |
|---|---|---|
| 快速恢复记忆，约 30—45 分钟 | 本页 → 01 → 03 → 07 → 08 的讲解稿 | 能画出两版流水并说出三个取舍 |
| 系统重新学习，分多次完成 | 01 → 02 → 03 → 04 → 05 → 12 → 06 → 07 → 13 → 11 | 能用完整程序解释机制，并比较替代方案 |
| 复试前速查 | 08 → 12 的操作数账本／13 的决策问答 → 答不出的专题 → 09 → 10 | 结论、机制、证据、限制都能回答 |

时间是阅读安排建议，不是学习效果保证。遇到“为什么”等问题时，先画寄存器两侧的组合路径，再回到代码。

## 全部分章

1. [01 五级流水关键知识恢复](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/01-pipeline-refresh.md)
2. [02 从仓库还原 CPU 与 SoC](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/02-repository-soc.md)
3. [03 五级与六级的真实数据通路](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/03-datapath.md)
4. [04 冒险、前递、暂停与冲刷](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/04-hazards.md)
5. [05 分支预测与设计取舍](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/05-prediction.md)
6. [06 访存、时序与性能证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)
7. [07 项目特色、已知问题与改进路线](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/07-improvements.md)
8. [08 复试讲解、追问与自测](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/08-interview.md)
9. [09 代码与报告证据索引](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)
10. [10 历史对话与旧结论纠错](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/10-history.md)
11. [11 未来实验清单与文书验收](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/11-validation.md)
12. [12 完整程序的 A／B 执行推演](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/12-execution-walkthrough.md)
13. [13 架构决策与替代方案复盘](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/13-architecture-decisions.md)

如果已经读懂单项机制，建议直接进入第 12 章：沿“两轮读数累加 → 写出 → 同址读回”的程序，追踪 PC、流水位置、旁路值、预测训练和最终状态。随后读第 13 章，练习回答“为什么这样做、还有什么选择、代价与验证是什么”。

## 如何读证据等级

- **S：源码／配置事实。** 例如某寄存器在上升沿更新。能证明结构，不自动证明所有输入下功能正确。
- **H：历史工具报告。** 证明当时工具在给定设计和约束下报告了什么；不等于本次重新实现。
- **I：静态推断。** 在明确前提下由逻辑推演出的行为；周期表属于这一类。
- **P：待验证方案。** 改进设想和未来实验，不作为既有成果。
- 教学原理单独说明；假设算例不是项目测量值。外部规范用于校准概念，不为本项目背书。

## 术语速查

| 术语 | 本文含义 |
|---|---|
| stage / 流水级 | 相邻有效寄存边界之间的处理阶段 |
| forwarding / bypass | 数据未正式写回时，直接送给消费者 |
| stall / hold | 必须看实现：可能保持，也可能被用来表示清空 |
| flush / bubble | 杀掉年轻指令／让该位置没有有效副作用 |
| replay / 重取 | 把 PC 指回要重做的位置，重新取指 |
| RAW | 后一条指令要读前一条尚未可用的结果 |
| PHT / BTB / CPT | 方向计数表／目标地址表／预测分量选择表 |
| CPI / IPC | 每条已完成指令平均周期数／每周期完成指令数 |
| WNS / TNS | 最差 slack／负 slack 总和，需区分 setup 与 hold |
| retiming | 工具移动寄存器跨越逻辑；不要与手动增加流水级混称 |
| MMIO / CDC | 内存映射外设／跨时钟域传递 |

本版不认定技术原创性，不写个人贡献。已有 study、comparison 和 memory-note 保留作历史底稿；与新研究有差异时，沿证据索引核对，并阅读纠错章。源码均未修改。
