# 08 · 复试技术讲解、追问与自测

[阅读入口](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/README.md)

本章讲项目本身，不表示个人设计或调试经历。回答中的“实现、报告显示、推断、计划”要对应证据等级。讲解稿长度仅用于组织思路，可按实际语速调整。

答完概念后，可用[第 12 章完整程序](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/12-execution-walkthrough.md)展开逐拍机制，再用[第 13 章决策问答](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/13-architecture-decisions.md#interview)回答“为何选择、能否替换、怎样评价收益”。

## 1. 一分钟项目概览

这是一组基于 FPGA 的 RISC-V 教学／竞赛 SoC 工程，CPU 通过片上存储和内存映射外设驱动虚拟开关、LED、数码管等系统功能。重点比较两版：目录叫 200M 的版本实际配置 CPU 150 MHz，为五级流水，采用 Gshare 风格和 Bimodal 两个分量加选择器；250M 版本是六级，在 EX 后增加 BUFFER，并把访存读返回寄存化，同时简化为 Bimodal 预测。

项目适合讨论的核心是预测复杂度、访存延迟、前递和时序之间的取舍。历史报告分别有 +0.865 ns 和 +0.035 ns 的 setup WNS，但没有本次功能仿真、CPI 或极限频率测量，且历史约束覆盖有缺项。因此可以解释结构和历史路径，不能单凭主频宣布哪个版本整体更快。

依据：[03](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/03-datapath.md)、[05](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/05-prediction.md)、[06](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)。

## 2. 三分钟架构展开

第一层是系统：top 用 PLL 生成 CPU 和 50 MHz 时钟，UART 与 twin_controller 传递虚拟 IO，student_top 集成 CPU、IROM 和外设桥。先确认 XPR 活动文件，再读实际连线，避免旧树和同名文件干扰。

第二层是流水：A 的 ROM 已寄存输出，所以 if_id 的指令直通不是少一个必要边界；B 的 ROM 异步，if_id 才是第一道边界。B 的额外一级来自 EX 后的 MEM_BUFFER，因此是六级。MEM_BUFFER 保存控制与地址，主存返回另在 rd_data_o 寄存，再由 MEM 完成 load 扩展。

第三层是依赖：项目主要把 EX／MEM／WB 的值前递给 ID，B 多一个 BUFFER 来源。值已可用时选择最新生产者，load 未返回时使用重取。代码中 load 冲突会清空前端并跳回后继地址，因此不能直接说成经典的一拍 stall；A 双源同时命中的 case 还有明确遗漏。

第四层是权衡：A 的预测器更复杂，B 简化预测并重新组织访存以适应更短周期。A 的历史最差路径在 PC→IROM，B 在 BRAM→读返回寄存器；这是具体路径证据，却不是单项优化收益的证明。要比较执行时间，还需要同任务的完成指令数与 CPI。

若继续改进，应优先补正确性场景、预测元数据对齐和约束覆盖，再考虑预测器移植或频率扫描。每个建议都要有测试输入、观测信号和通过标准。

## 3. 选一个专题讲深

| 专题 | 建议画出的图 | 推荐展开顺序 |
|---|---|---|
| load-use | L/U 的 EX、ID 与重取周期表 | 为什么值未到 → 检测 → 清空与目标 PC → 重新采样 |
| 分支预测 | PHT、BTB、CPT 与训练箭头 | 方向／目标 → 分量 → 选择 → 对齐与恢复 |
| 访存提频 | A/B 返回 MUX 与寄存点 | 长路径 → 切分 → 控制延迟 → 前递与 CPI |
| 仓库研究 | XPR 到实例到 RTL/IP 到报告 | 排除旧代码 → 固定版本 → 交叉证据 → 纠正旧结论 |

## 4. 分层问答

### Q01 · 为什么这还是 RISC-V CPU，却不是同一种五级结构？

**简答：**RISC-V 是指令语义接口，五级或六级是微架构选择。

**追问展开：**同样的 add、load 可以由不同寄存边界实现；只有架构可见结果符合约定，才算正确。当前并未证明全部 ISA 合规。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/02-repository-soc.md)

### Q02 · 如何证明 A 是五级？

**简答：**ROM 输出已寄存，if_id 的指令组合直通，IF2 例化被注释。

**追问展开：**再追踪 id_ex、EX 输出、MEM 输出和 GPR 写入，不能只数模块。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/03-datapath.md)

### Q03 · 为什么 B 不是七级？

**简答：**B ROM 异步无时钟，if_id 才是首个取指寄存边界。

**追问展开：**EX 后只新增一个完整 BUFFER；读返回延迟线配合控制推进，不能重复计级。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/03-datapath.md)

### Q04 · 为什么不能说 A 是 200 MHz？

**简答：**200M 是目录名与输入时钟，CPU 的 PLL 输出是 150 MHz。

**追问展开：**要沿 clk_out2 到 CPU，再与历史 clock summary 交叉确认。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/02-repository-soc.md)

### Q05 · 增加流水级一定提高性能吗？

**简答：**不一定，频率和 CPI、指令数共同决定执行时间。

**追问展开：**还要考虑 load 延迟、分支错误、寄存器开销和前递复杂度。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)

### Q06 · 前递解决什么？

**简答：**把尚未正式写回、但已生成的正确值送给消费者。

**追问展开：**本项目主要送到 ID 读口，不是直接照搬教科书 EX 输入图。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/04-hazards.md)

### Q07 · 多个来源同时写同一个 rd，选哪个？

**简答：**选择离消费者最近、程序顺序最新且已就绪的生产者。

**追问展开：**EX 优先于较老阶段；x0 读口首先固定为 0。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/04-hazards.md)

### Q08 · 为什么 load 不能直接用 EX 前递？

**简答：**EX 生成的是访存地址，真正的值在读返回后才可用。

**追问展开：**not_mem 屏蔽 load 地址，控制还必须延后消费者。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/04-hazards.md)

### Q09 · 项目 load-use 是暂停一拍吗？

**简答：**不能这样概括；当前代码会冲刷前端并跳到后继地址重取。

**追问展开：**简单紧邻案例的静态推演会多两拍，但不是测得的平均代价。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/04-hazards.md)

### Q10 · A 的 load-use 有什么具体问题？

**简答：**case 遗漏 rs1、rs2 同时命中 rd 的 11 分支。

**追问展开：**用 lw x5 后接 add x6,x5,x5，并令旧值与内存值不同，才能暴露错读风险。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/04-hazards.md)

### Q11 · B 为什么需要 load_any_use？

**简答：**BUFFER 让 load 返回相对年轻消费者更晚，隔一条依赖也要检测。

**追问展开：**它比较 ID 源地址与前一拍保存的 load rd，并不是任意距离的通用 scoreboard。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/04-hazards.md)

### Q12 · store 也有数据冒险吗？

**简答：**有，rs1 是地址依赖，rs2 是写数据依赖。

**追问展开：**必须同时验证 ALU→store、load→store 数据和 load→store 基地址。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/04-hazards.md)

### Q13 · store→load 和寄存器前递有什么区别？

**简答：**它解决内存写请求尚未落入 RAM 时，后继同地址读应看到新值的问题。

**追问展开：**比较待写地址并选择最新写数据，不能用普通 rd 比较代替。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)

### Q14 · MEM_BUFFER 是读返回缓存吗？

**简答：**不是，它保存 EX 的数据、地址与写回／访存控制。

**追问展开：**读返回寄存在 mem_wr_buffer.rd_data_o；两者的名称相近但功能不同。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/03-datapath.md)

### Q15 · 怎样确认地址没有比控制早一拍？

**简答：**追踪到最终使用地址的组合模块，而不是只看顶层端口名。

**追问展开：**B MEM_UNIT 内又寄存 mem_rd_addr_i；应比较内部地址、funct3、is_load 和数据属于哪条指令。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/03-datapath.md)

### Q16 · PHT 和 BTB 分别做什么？

**简答：**PHT 学方向倾向；BTB 给目标，并用 tag/valid 判断可用性。

**追问展开：**方向想跳但目标无效时不能随意跳；B 的预测使能包含三者门控。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/05-prediction.md)

### Q17 · 二位计数器就是两位分支历史吗？

**简答：**不是，二位计数器是四种饱和倾向状态。

**追问展开：**方向历史是结果序列；A 的 GBHR 与二位 PHT 是不同状态。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/05-prediction.md)

### Q18 · A 的局部预测器真有局部历史表吗？

**简答：**没有；AREA 分量按 PC 索引二位计数器，更准确叫 Bimodal。

**追问展开：**模块名与注释只能作线索，要看索引输入和实际数组。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/05-prediction.md)

### Q19 · 为什么 Gshare 要把 PC 与历史异或？

**简答：**让索引同时受分支位置和历史模式影响，尝试区分不同上下文。

**追问展开：**本项目声明 10-bit 历史但索引仅保留低 6 bit；还需验证历史更新与分支对齐。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/05-prediction.md)

### Q20 · CPT 是第三个预测器和 BTB 吗？

**简答：**CPT 是分量选择器，没有自己的 BTB。

**追问展开：**A 是两套分量与两套 BTB；CPT 在分歧时偏向正确者。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/05-prediction.md)

### Q21 · B 更深，为什么分支不必多冲刷一级？

**简答：**新增 BUFFER 在 EX 之后；EX 前仍只有 IF 和 ID。

**追问展开：**B 训练结果寄存不等于重定向晚一拍；结构冲刷范围和精确平均罚拍要分开。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/03-datapath.md)

### Q22 · 预测错了需要修正哪些信息？

**简答：**首先恢复正确 PC，阻止年轻指令产生架构副作用。

**追问展开：**还要检查原预测方向／目标／索引与当前实际分支一致，历史训练不能串到另一条指令。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/05-prediction.md)

### Q23 · 提高预测命中率一定更快吗？

**简答：**不一定，更复杂预测器可能增加组合延迟、资源和布线。

**追问展开：**需测相同任务的总时间；现有资料没有可用命中率百分比。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)

### Q24 · retiming 和增加流水级有什么区别？

**简答：**前者通常指工具移动已有寄存器跨逻辑，后者改变指令推进边界。

**追问展开：**本项目还手动寄存读返回链；三件事应分别说明，不能把日志 WNS 改善全归给 retiming。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)

### Q25 · WNS 为正可以证明什么？

**简答：**给定报告模型中已约束路径的最差 slack 为正。

**追问展开：**不能证明约束完整；两版历史报告存在 no_clock 和未约束项。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)

### Q26 · 为什么只看逻辑级数不够？

**简答：**物理布线延迟可能占主导。

**追问展开：**A 最差 PC→IROM 路径约 90.9% 是布线，不能只优化逻辑表达式。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)

### Q27 · B 的 35 ps 裕度意味着什么？

**简答：**该次已约束 CPU 路径在 4 ns 要求下只剩很小正 slack。

**追问展开：**不等于实物任意环境安全，也不能据此求得通用极限 Fmax。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)

### Q28 · 为什么 B 的 FF 少了而 BRAM 多了？

**简答：**同时发生预测结构简化、流水变化和 RAM 扩容。

**追问展开：**FF 是整个 top 总数；BRAM 主要对应 64 KiB→256 KiB，不能都归因于流水深度。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)

### Q29 · 0.450 W 与 0.540 W 是实测吗？

**简答：**不是，是历史工具片上功耗估计。

**追问展开：**报告置信度 Medium，未提供仿真活动文件；不能当成板卡输入功耗。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)

### Q30 · 两个时钟不同频率就必须加同步器吗？

**简答：**先看关系与协议；这里两个频率来自同一个 PLL。

**追问展开：**即使 STA 分析了关系，单拍脉冲捕获、总线一致性与复位释放仍要检查；多位总线不能简单逐位两级同步。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/02-repository-soc.md)

### Q31 · 这项目最值得继续改什么？

**简答：**先处理正确性覆盖与验证能力，再做预测和提频实验。

**追问展开：**举双源 load-use、预测元数据、约束覆盖等具体证据，而不是直接增加更复杂模块。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/07-improvements.md)

### Q32 · 如何证明某项优化真的有效？

**简答：**在相同程序、器件、工具与合理控制变量下比较。

**追问展开：**同时报告正确性、周期、频率和资源；对无法隔离的变量说明限制。 [查看机制与证据](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/11-validation.md)

## 5. 闭卷自测

1. 不看资料，画出两版所有主要寄存边界，指出 ROM 差异。
2. 给出三条连续写同一 rd 的指令，说明第三条读哪个旁路。
3. 画出紧邻 load-use 的重取过程，指出与教材 interlock 的区别。
4. 解释为什么 BUFFER 放在 EX 后，对 load 与分支的影响不同。
5. 用一条真实报告路径解释 logic delay、route delay、slack。
6. 用两分钟提出一个有证据、有代价、有验证标准的改进。

评分方式：每题按“结论正确、机制连贯、能指出证据、能说明限制”各一项自查；答出术语但不能画数据流，回到对应专题。能口述答案不等于已经完成工程验证。
