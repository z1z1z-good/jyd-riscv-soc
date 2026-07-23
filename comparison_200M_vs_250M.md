# RISC-V SoC 对比复核：五级 A 与六级 B

> 对比对象：
>
> - A：`five_level_200MHz_with_all_branch`，5 级、两分量锦标赛预测器、CPU 150 MHz。
> - B：`five_level_area_250M`，6 级、单一 Bimodal 方向表 + BTB64、CPU 250 MHz。
>
> 2026-07-23 复核：两个独立审计分别检查管理后的 A/B，并在仓库外临时副本调用 Vivado 2023.2。本文区分“RTL 静态确认”“历史 routed report”与“尚未实测”。

---

## 0. 先给出关键更正

1. A 是 5 级，这一点成立；IF2 只有注释例化，当前活动树没有 `IF2_UNIT.v`。
2. B 是 **6 级 IF/ID/EX/BUFFER/MEM/WB**，不是旧文档所写的 7 级。B 的 IROM 是异步、零流水，`if_id` 不是建立在另一个“ROM 输出寄存级”之后。
3. B 的 `MEM_BUFFER` 是真实整级，但锁存的是 EX 控制、地址、store 数据和写回信息；主存返回数据的寄存点是 `mem_wr_buffer.rd_data_o`。
4. A 有两套 BTB，不是三套；CPT 是选择器，没有自己的 BTB。
5. A 的 GBHR 寄存器声明为 10 bit，但 64 项 PHT 的索引只保留 XOR 结果低 6 bit。
6. 两者都在 EX 解析分支，前端均只有 IF、ID 两个年轻级；误预测损失可结构性描述为约 2 拍，旧文档的 B≈3 拍没有 RTL 支持。
7. 预测命中率、IPC、CoreMark、精确罚拍和极限 Fmax 均未实测，不能继续使用 96%/88% 等数字。

---

## 1. 总览

| 维度 | A（200M·全预测） | B（250M·面积/时序） | 证据等级 |
|---|---|---|---|
| CPU 时钟 | 150 MHz | 250 MHz | PLL XCI + 历史 routed report |
| 输入时钟 | 200 MHz | 200 MHz | PLL XCI/XDC |
| 历史 WNS | +0.865 ns | +0.035 ns | `reports/{200M,250M}` |
| 流水级数 | 5 | 6（多一个 BUFFER） | 活动 RTL 寄存边界 |
| 分支预测 | Gshare 风格+Bimodal+CPT，2×BTB64 | Bimodal PHT64×2b + BTB64 | 活动 RTL |
| 全局历史 | 10-bit 寄存器，实际低 6 bit参与索引 | 无 | 活动 RTL |
| 误预测冲刷 | 结构推断约 2 拍 | 结构推断约 2 拍 | 未做周期仿真 |
| 前递 | EX/MEM/WB 三源 | EX/MBEM/MEM/WB 四路 | 活动 RTL |
| 数据 RAM | 16384 words×32 = 64 KiB | 65536 words×32 = 256 KiB | XCI |
| Slice LUT / FF | 5482 / 4111 | 4448 / 2622 | 历史实现报告 |
| BRAM tile | 16 | 64 | 历史实现报告 |
| 功耗 | 0.45 W | 0.54 W | 历史功耗报告 |

“200M”指工程名和板载差分输入钟；A 的 CPU 并不是 200 MHz。历史 WNS/资源/功耗来自整理前一次 routed build，尚未用管理后的工程重新实现。

---

## 2. 流水线结构

```text
A（5级）
IF（同步 ROM 输出） → ID → EX → MEM → WB
       if_id          id_ex  EX寄存  MEM寄存  GPR写入

B（6级）
IF（异步 IROM） → ID → EX → BUFFER → MEM → WB
       if_id      id_ex  EX寄存  MEM_BUFFER  MEM寄存  GPR写入
```

A：

- `dist_mem_gen_1` 的输出是 registered；`if_id` 只寄存地址，指令字使用 ROM 已寄存输出。
- `RISCV.v:142-152` 的 IF2 例化处于注释中，`ID_UNIT` 直接接 `if_ins_o`。
- EX 结果在 `EX_UNIT` 寄存，MEM 结果在 `MEM_UNIT` 寄存，WB 为组合直通后在 GPR 写入边沿提交。

B：

- `IROM.xci` 明确为 `non_registered`、`Pipeline_Stages=0`、`C_HAS_CLK=0`。
- `if_id` 是取指后的第一道寄存边界。
- `MEM_BUFFER` 位于 EX 和 MEM 之间并对所有指令控制打一拍，因此 B 比 A 多一个级，而不是两个。

---

## 3. 访存时序改造

A 的 `mem_wr_buffer`：

- store 请求先寄存一拍；
- 读返回与同地址 store-to-load 旁路为组合逻辑。

B 的变化：

1. `MEM_BUFFER` 锁存 EX 的控制、地址、store 数据和写回信息；
2. `mem_wr_buffer.rd_data_o` 在时钟沿寄存主存返回数据；
3. `MEM_UNIT` 再完成 load 扩展并锁存写回数据。

历史 250M timing report 的最差路径终点是 `mem_wr_buffer_inst/rd_data_o_reg/D`，说明读链寄存化确实位于关键路径上。但 B 同时改变了预测器、流水深度、RAM 容量和实现条件，不能仅凭 A/B 两份报告量化“单路径 Fmax 翻倍”，也不能把 250 MHz 完全归因于单一 retiming 动作。

`MEM_BUFFER` 定义了 `_hypass` 输出，但当前 `RISCV` 实例没有连接这些端口；旧文档“靠 `_hypass` 补偿 load”的说法错误。

---

## 4. 分支预测

### A：两分量锦标赛

- `GLOBAL_PREDICTOR`：64×2-bit PHT + BTB64；索引是 `pc[7:2] XOR GBHR` 的低 6 bit。
- GBHR 物理寄存器为 10 bit，但当前 PHT 深度只让低 6 bit参与索引。
- `AREA_PREDICTOR`：按 PC 索引的 64×2-bit Bimodal PHT + BTB64，没有 local history table。
- `CPT`：64×2-bit 选择器，只在两个分量预测不同时训练；MSB 选择全局或 Bimodal 分量。
- 合计两套 BTB；CPT 没有 BTB。

### B：单一方向表

- 方向预测为 PC 索引的 64×2-bit Bimodal PHT；
- 目标来自 direct-mapped BTB64，并有 tag/valid；
- 没有 GHR/LHR。

所以“单表”只能解释为“单一方向预测表”，不能理解为整个预测器只有一个数组。

两者都只预测条件分支；JAL/JALR 在 EX 无条件重定向。条件分支修正主要比较 taken/not-taken 方向，没有独立的 BTB target-mismatch 比较。预测精度百分比必须通过分支计数仿真获得，本仓库当前没有这类实测数据。

---

## 5. 冒险、前递与已知 RTL 限制

| 机制 | A | B |
|---|---|---|
| 前递源 | EX→MEM→WB 三源 | EX→MBEM→MEM→WB 四路 |
| load 冲突 | `cu` 内 load-use case | `EX_UNIT` 的 `load_use/load_any_use` 两阶段检测 |
| hold/冲刷 | 3-bit 分级编码 | 1-bit 统一信号 |
| 分支方向修正 | 逻辑展开 | `actual_taken XOR predict_taken` |

已知限制：

- A 的 load-use `case` 只覆盖 `2'b10` 和 `2'b01`，漏掉 rs1、rs2 同时等于 load 目的寄存器的 `2'b11`。
- A/B 的 `BTB_TAG_WIDTH` 参数为 6 bit，但 RTL 写入/比较 `pc[14:8]` 七位；当前 16 KiB IROM 中高位恒零，扩大地址空间前必须统一。
- A 的 `GLOBAL_PREDICTOR` 和 B 的 `EX_UNIT` 存在声明顺序 Vivado warning。
- A 的 counter 控制从 150 MHz CPU 域进入 50 MHz 域，未见显式同步/握手。
- store→load、连续 load-use、BTB alias/目标错误仍需定向仿真。

---

## 6. 面积、存储与功耗

历史实现报告显示：

- B 的 LUT 比 A 少约 19%，FF 少约 36%；
- B 的 BRAM 从 16 tile 增到 64 tile，主要对应数据 RAM 从 64 KiB 扩到 256 KiB；
- B 的历史功耗从 0.45 W 增到 0.54 W。

因此 `area` 更接近“逻辑精简”而不是“总存储/功耗都更小”。这些数字是不同结构、不同目标频率的两次历史实现结果，不是控制变量实验。

---

## 7. 性能结论的边界

可以确认：

- A 的 PLL 配置为 150 MHz，B 为 250 MHz；
- A 的预测器更复杂，B 的流水多一个 BUFFER 级；
- B 的历史时序余量只有 +0.035 ns。

不能确认：

- A/B 的极限 Fmax；
- 预测命中率；
- 精确误预测罚拍、load CPI 代价；
- CoreMark 或 MIPS 谁更高。

因此不再使用“B 大概率净胜”“A 被预测器锁死在 150 MHz”等结论。若要严肃比较，必须使用同一固件、同一约束/器件策略，分别完成仿真或上板计数以及实现扫描。

---

## 8. 验证状态与建议

本轮已完成：

- 两个 XPR 的 XML、文件存在性、活动 RTL 收录和归档隔离检查；
- Vivado 2023.2 在仓库外临时副本中打开工程、识别顶层/器件/IP并建立编译序；
- 200M 三个 IP 的 output products 成功重新生成；
- 对流水边界、预测器、冒险、PLL、IROM/DRAM XCI 和历史报告逐行交叉核对。

尚未完成：整理后的完整 `synth_1`、implementation、bitstream、自检仿真和动态性能测试。现有 `top_tb` 也不是完整自检 testbench。

建议后续顺序：

1. 先修复声明顺序、BTB tag 宽度和 A 的 load-use `2'b11`；
2. 增加 load/store、连续分支和 BTB alias 的定向自检；
3. 用同一固件统计预测命中率/CPI；
4. 在统一约束下扫描频率，再讨论合并 A 预测器与 B 访存结构；B 当前没有可直接复用的“额外取指拍”，若组合回路不收敛应显式新增预测级。

### 关键证据锚点

- A IF2 注释：`five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v:142-152`
- A 预测器：`five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/{bpu,CPT,GLOBAL_PREDICTOR,AREA_PREDICTOR}.v`
- A IROM：`five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/ip/dist_mem_gen_1/dist_mem_gen_1.xci:19-26`
- B IF 边界：`five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/if_id.v:48-60`
- B 异步 IROM：`five_level_area_250M/digital_twin.srcs/sources_1/ip/IROM/IROM.xci:14,19-20,42,61`
- B BUFFER：`five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/MEM_BUFFER.v:35-55`
- B 读返回寄存：`five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/mem_wr_buffer.v:40-50`
- B 四路前递：`five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v:112-119`
- 历史实现数据：`reports/200M/`、`reports/250M/`
