# 05 · 分支预测与设计取舍

[阅读入口](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/README.md) · [证据 E13—E15](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

## 1. 要提前回答两个问题

方向：这条条件分支跳不跳？目标：跳到哪里？PHT 用于方向，BTB 保存目标和 tag / valid。没有有效目标时，即使方向计数器偏向跳，也不能随便使用某个旧地址。

本项目的 AREA_PREDICTOR 名字容易被解释成“局部历史预测器”。实际只是 pc[7:2] 索引二位计数器，没有 local history table，因此本文称它为 **Bimodal 分量**。

## 2. B：单一方向表＋BTB

~~~mermaid
flowchart LR
  PC["IF PC"] --> IX["索引 PC 的 7:2 位"]
  IX --> PHT["64 项 2-bit PHT"]
  IX --> BTB["64 项 BTB / tag / valid"]
  PHT --> GATE["方向 MSB 与 tag 命中和 valid"]
  BTB --> GATE
  GATE --> TAKEN["predict_taken"]
  BTB --> TARGET["predict_target"]
  EX["EX 解析结果经寄存"] --> UPDATE["更新 PHT / BTB"]
  UPDATE --> PHT
  UPDATE --> BTB
~~~

方向表 64×2=128 bit；BTB 还需要目标、标签、有效位，不能把 128 bit 当成整个预测器资源。RTL 将跳转门控为 PHT 的 MSB、BTB valid、tag 比较三者同时满足。BTB 在 actual_jump_flag 有效时写入，PHT 则受 is_branch 限定训练。

二位计数器状态为 00 强不跳、01 弱不跳、10 弱跳、11 强跳。遇到跳转递增，不跳递减，饱和不回绕；复位初始化 01。它的价值是增加“改变倾向的惯性”，不是保存最近两次结果。

| 示例：同一分支重复 T、T、T、N | 训练前状态 | 方向 MSB | 训练后状态 |
|---|---|---|---|
| 第一次 T | 01 | 不跳；BTB 初始也无效 | 10，并建立目标 |
| 第二次 T | 10 | 跳 | 11 |
| 第三次 T | 11 | 跳 | 11 |
| 最后 N | 11 | 跳，发生方向误预测 | 10 |

这是教学状态演示，假定训练已完成、无表冲突；相邻动态分支可能还没看到前一次更新，因此不作为项目命中率统计。

## 3. A：两个分量竞争，由 CPT 学习选择

~~~mermaid
flowchart TD
  PC["IF PC"] --> BI["PC 索引 Bimodal PHT"]
  PC --> XOR["PC 索引 XOR 历史低 6 位"]
  GH["GBHR"] --> XOR
  XOR --> GP["Gshare 风格 PHT"]
  PC --> BTB1["Bimodal BTB"]
  PC --> BTB2["Global BTB"]
  BI --> BP["分量方向和目标"]
  BTB1 --> BP
  GP --> GPR["分量方向和目标"]
  BTB2 --> GPR
  XOR --> CPT["CPT 二位选择表"]
  BP --> MUX["选择方向和目标"]
  GPR --> MUX
  CPT --> MUX
  MUX --> NEXT["PC 预测输入"]
~~~

A 的全局分量把 PC 索引与历史异或。GBHR 声明为 10 bit，但 ifpcindex/expcindex 只有 6 bit，赋值保留异或结果低 6 bit，所以“真正参与当前索引的历史”只有低 6 位。

CPT 也是 64 项二位状态，索引沿用全局分量索引。MSB 选分量；当两个分量一个对一个错时，状态偏向正确者；两者一致时没有相对优劣可学。它没有自己的 BTB，A 总共只有两套 BTB。

收益假设是不同分支可能分别适合 PC 偏置或历史相关性；代价是额外表、读出、选择与布线，训练元数据也更复杂。仓库没有可核验命中率，不能把这种理论动机当成 A 实际优于 B 的结果。

## 4. 预测结果必须与原来的那条指令同行

在 IF 预测的是某个 PC；到 EX 判断错误时，必须比较那条指令当时的预测，而不是当前 IF 的预测。A/B 在 EX_UNIT 中都用两拍延迟的 predict_taken_reg1。A 的 bpu 还延迟两个分量的方向，供 CPT 比较。[E13—E15](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

A 的 GBHR_old 来自 GBHR 两拍延迟；PHT 更新索引用 EX PC XOR GBHR_old，GBHR 自身更新也使用 GBHR_old。静态读码可以确认这些表达式，但不能保证连续分支时它等价于通常描述的“最近已解析分支历史”。这也是采用“Gshare 风格”表述的原因。

现有延迟链未见显式随指令 valid、hold、flush 一同携带的完整元数据束。改进可考虑保存预测时索引、方向、目标和有效性；训练时用原记录回写，以减少时间对齐歧义。是否必然造成当前错误仍需序列验证。

## 5. 解析、重定向和训练不是同一件事

A 实际分支结果直接由 EX 组合输出送预测器；B 把实际方向、目标、is_branch 与 PC 再寄存后送训练。B 的前端修正仍由 EX 内 cu 的 jump 输出组合驱动。因此训练晚一拍不等于前端重定向晚一拍。[E13](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

两版条件分支错误判断主要看方向不一致；未见将“原先预测目标”带到 EX 后独立检查目标错误的完整路径。在当前固定代码窗口内，tag 和分支立即数限制了部分风险，但扩大地址空间、代码变化或 BTB 内容错配时要重新审查。

JAL/JALR 在 cu 中直接生成跳转和链接地址，不像条件分支那样依赖方向表来决定是否重定向。不要声称项目已实现返回地址栈、间接跳转专用预测或所有控制流的统一预测。

## 6. 别名与位宽问题怎样准确讲

表只有 64 项，不同 PC 可能落到相同索引。方向表共享会互相干扰；BTB 需要 tag 区分目标属于哪个 PC。

当前 BTB_TAG_WIDTH=6，但写入与比较使用 pc[14:8] 七位：写入会截断，比较会扩展。当前可达 16 KiB 窗口中 bit14 为 0，不能因此保证未来扩展仍正确。若 bit14=1，截断后的 6-bit tag 与 7-bit 查询可能不再匹配；这不应简单说成“必然错误命中”，也可能表现为该区域一直不预测。[E15](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

## 7. 未来如何量化“预测器更好”

用同一程序分别统计：条件分支总数、方向错误数、目标错误数、BTB miss、被冲刷指令、总周期、完成指令数。冷启动和稳态分开，循环偏置、交替分支、分支相关序列和同索引冲突分别测试。

命中率好不等于执行时间好。若更复杂的读表链降低可达频率或增加解析延迟，需要把 CPI 与频率一起比较。是否移植 A 到 B 应在正确性、训练对齐和时序约束齐备后决定，不能直接把“复杂表＋深流水”相加就宣称得到两个版本的全部优点。

## 复试追问

问：“二位计数器是两位历史吗？”答：“不是，是带饱和的置信倾向；全局历史寄存器才记录方向序列。A 把历史与 PC 异或索引，B 没有历史表。”

问：“CPT 为什么只在分量分歧时学习？”答：“两者一致时没有相对选择信息；分歧时根据实际结果向正确分量调整。工程还必须保证送到训练端的两份预测属于同一条分支。”
