# 06 · 访存、时序与性能证据

[阅读入口](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/README.md) · [报告锚点 E16—E18](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

## 1. 访存优化改变的是哪些边界

A 的 EX 提前生成读地址；BRAM 同步读与桥地址寄存后，返回经旁路选择和 load 扩展送入 MEM 输出寄存器。B 把读返回选择结果额外寄存，下一阶段再扩展，同时以 MEM_BUFFER 延迟控制。[E09—E12](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

~~~mermaid
flowchart LR
  subgraph A["A 读返回处理"]
    AR["BRAM / MMIO 返回"] --> AM["缓存同址比较与 MUX"]
    AM --> AE["字节选择和符号扩展"]
    AE --> AW["MEM 输出寄存"]
  end
  subgraph B["B 读返回处理"]
    BR["BRAM / MMIO 返回"] --> BM["当前写或缓存同址比较与 MUX"]
    BM --> BD["rd_data_o 寄存"]
    BD --> BE["字节选择和符号扩展"]
    BE --> BW["MEM 输出寄存"]
  end
~~~

这张图画 CPU 返回处理，不省略说明 RAM wrapper 也有同拍读写旁路、perip_bridge 也有返回选择。实际关键路径需沿报告从 BRAM 端点追到 CPU 寄存器。

增加寄存边界可以把原来一周期内要完成的工作分开，但必须同时处理控制延迟、load 返回时间和前递。B 的 MEM_BUFFER 延迟指令控制，MEM_UNIT 内部延迟地址，使扩展操作使用正确字节偏移。不能只给 32-bit 数据打拍，漏掉低两位地址。

## 2. 写缓存不是 cache，也不是完整 store queue

A/B 的 mem_wr_buffer 保存一拍写地址、数据、使能；没有多项队列的 head/tail、满空和背压机制。注释中出现“FIFO”不足以证明它是多项 FIFO。它也没有 cache 的 line、miss、替换和回填。

A 返回优先取上一拍待写缓存；B 先取当前写请求，再取缓存，再取内存。比较使用地址 [31:2]，按 word 匹配。SB/SH 在 mem 中用原字与新字节／半字拼出整字，这是读改写；若旧字或低位地址不同步，会损坏未写字节。连续 SB/SH、同址读写必须单列测试，不能以 SW/LW 通过代替。

B 的 rd_data_o 在 posedge 中使用阻塞赋值，是静态可见的仿真调度风险；当前文档按意图中的寄存边界解释，不把它当成仿真／综合语义完全一致的已验证实现。

## 3. 三种常被统称 retiming 的操作

| 操作 | 对本项目怎样说 | 必须付出的验证 |
|---|---|---|
| 手动增加完整流水级 | B 的 MEM_BUFFER 延迟数据与控制 | 旁路、暂停、写回、store 副作用 |
| 手动把返回链寄存化 | rd_data_o 从 A 组合输出变为 B 时钟寄存 | 读地址、返回、funct3 和 rd 对齐 |
| 工具 retiming | 工具把寄存器跨组合逻辑移动，需看实际报告 | 等价性、约束、复位和使能语义，以及前后路径 |

AMD 对 RETIMING_FORWARD 的定义是把寄存器向其驱动的时序单元方向跨逻辑移动；phys_opt_design 中的 retime 是诸多物理优化选项之一。[UG901](https://docs.amd.com/r/2023.2-English/ug901-vivado-synthesis/RETIMING_FORWARD) · [UG835](https://docs.amd.com/r/2023.2-English/ug835-vivado-tcl-commands/phys_opt_design)

B 的 runme.log 在 2390 / 2413 行附近为 WNS=-0.052，2430 行附近为 +0.034，2504 行最终 +0.035。**这是布线优化过程的改善轨迹，不能据此把改善归因于某一次寄存器移动。** 日志另一个物理优化汇总的 Retime 行显示创建／删除／优化单元为 0；它不能证明所有阶段都没做 retiming，但足以说明“看到阶段名或 WNS 变化就证明 retiming 成功”不成立。[E18](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

## 4. 如何读一条真实时序路径

先读报告头部的器件、速度等级、工具、日期、设计状态，再读时钟组、setup/hold、起点与终点。setup slack 是数据要求到达时间减去实际到达时间；hold 是最小延迟检查，不能把两者混用。[AMD Timing Path Details](https://docs.amd.com/r/en-US/ug906-vivado-design-analysis/Timing-Path-Details)

| 历史报告内容 | A | B |
|---|---|---|
| 日期 | 2025-07-15 | 2025-07-14 |
| 工具 / 器件 | Vivado 2023.2 / Kintex-7 325T，-2 | 同类器件与工具 |
| CPU 周期 | 6.667 ns | 4.000 ns |
| CPU 组最差 setup slack | +0.865 ns | +0.035 ns |
| 起点 | PC 的 pc_o_reg[10] | 数据 BRAM 的时钟端点 |
| 终点 | IROM 输出 qspo_int_reg[11] | mem_wr_buffer.rd_data_o_reg[9] |
| 数据路径延迟 | 5.569 ns | 3.907 ns |
| 逻辑延迟 | 0.506 ns，约 9.1% | 2.015 ns，约 51.6% |
| 布线延迟 | 5.063 ns，约 90.9% | 1.892 ns，约 48.4% |
| 逻辑级数 | 4 | 5 |

A 的具体最差路径是 PC→IROM，不足以把预测器定成唯一瓶颈。布线占比高，提示布局距离、扇出与映射值得查；不能由“只有四级逻辑”认为该路径轻松。

B 最差端点与读返回寄存点吻合，说明这段返回处理仍受紧约束。+0.035 ns 即 35 ps，但它只是在该次模型与约束下的 slack，不是实物任何环境下的通用安全裕度。

为什么 4.000-3.907=0.093，却报告只剩 0.035？完整 slack 还包含时钟路径、偏斜、uncertainty、端点时序等；不能只减组合延迟，更不能直接用其倒数宣布 Fmax。

## 5. 正 WNS 之外必须看的历史限制

两份报告的 check_timing 都列出 no_clock(65)、unconstrained_internal_endpoints(1)、no_input_delay(1)、no_output_delay(69)。它们是报告检查项的计数，不是“65 个独立时钟源”。还有同源 PLL 两时钟之间的 inter-clock timing 记录。[E17](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

因此精确表述是：“历史 routed report 中，已分析约束下 setup/hold 汇总为正，但约束覆盖存在未解决项。” 不能表述为“整个系统已经完成时序签核”。

no_clock 的若干描述指向写缓存寄存器 Q；当前 RTL 无法仅凭该文字解释历史网表为何如此分类，需历史 DCP 或重建后检查网表和时钟传播。**本次不把历史告警直接认定为当前代码某个确定根因。**

## 6. 面积与功耗：先把比较条件说清

历史整个 top 的 LUT 从 5482 到 4448，减少约 18.86%；FF 从 4111 到 2622，减少约 36.22%。BRAM tile 从 16 到 64，增加 300%，对应主 RAM 64 KiB→256 KiB 的配置扩容。DSP 都为 0。[E18](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

这些是 placed utilization，并非单独 CPU 核的分层面积；不同结构、频率和 RAM 配置混在一起，无法把全部差值归给预测器简化。FPGA 的 LUT / FF / BRAM 是不同资源，不能直接相加得到“总面积减少多少”。

功耗报告 0.450 / 0.540 W 为片上总功耗估计，Confidence Level=Medium，Simulation Activity File=---。没有实测电流和同一活动输入，不能说“B 实测多耗电 20%”，也不能代替板卡电源功耗。

## 7. 用 CPI 和频率一起比较

相同完成指令数 N 时：

~~~text
T_A = N × CPI_A / 150 MHz
T_B = N × CPI_B / 250 MHz
T_B / T_A = (CPI_B / CPI_A) × 0.6
~~~

所以在“同一任务、同一完成指令数”的前提下，B 更快需要 CPI_B/CPI_A < 5/3。这里没有测得两版 CPI，只是比较条件。

假设例一：CPI_A=1.2，CPI_B=1.5，则时间比=0.75，B 用时少 25%。
假设例二：CPI_A=1.2，CPI_B=2.2，则时间比=1.10，B 用时多 10%。
这两个数字都不属于项目测试结果。若编译器、软件乘除法或指令数改变，必须使用完整 N×CPI/f，不能继续约去 N。

平均 CPI 可由理想吞吐、load 等待、分支错误等开销理解；多个事件可能重叠，统计时不可把所有计数无条件相加。

## 8. 提频研究应该怎样继续

先解决功能与约束覆盖，再在相同程序、工具、器件、RAM 容量、实现策略下作变量对照。分别改变预测器、BUFFER、读返回寄存，观察周期数、时序与资源；可行性受设计耦合限制，不能保证每种组合无需改控制就能运行。

未来优先观察 PC→IROM 与 BRAM→返回寄存两类路径，检查前递新增长组合路径，避免只减少某个 ALU 表达式。是否降频、再切级或改布局，需由新的报告决定，本版不给未经扫描的“安全 Fmax”数值。
