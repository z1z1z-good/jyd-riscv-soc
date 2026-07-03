# JYD 集创赛 RISC-V SoC 工程族 · 技术研究底本

> **用途**：`D:\JYD` 下五个工程的族谱级技术存档，供将来重拾时快速恢复"深入掌握"。
> **方法**：实现报告实测 + RTL 亲自核验 + 三个独立分析代理（分支预测 / 流水线访存 / 模板基线）交叉验证。
> **配套**：本文件是主文档；`comparison_200M_vs_250M.md` 是 A vs B 的聚焦深挖（本文 §3.2/§3.3/§5 已吸收其结论）。
> 生成日期：2026-07-03。器件：Kintex-7 类（203800 LUT / 407600 FF / 445 BRAM / 840 DSP）。板载差分输入钟 200 MHz。

---

## 1. 族谱总览

五个工程，**同一颗 tinyriscv 衍生核 `rtl_full2 / RISCV`** 为共同底座，分两类：数字孪生竞赛工程（`digital_twin.xpr`，带虚拟外设）与 CoreMark 跑分工程（`riscv_coremark.xpr`，核抽出）。

```
Template(基线 · 5级 IF/ID/EX/MEM/WB · RV32I+部分F · 无预测/无缓冲 · 未实现)
  │   └ 另挂遗留核 rtl_full/RISCV_CORE(RV32IM+CSR+CLINT,被.xpr排除=死码)
  │
  ├─▶ A = five_level_200MHz_with_all_branch
  │      + 锦标赛分支预测(Gshare+Bimodal+CPT+BTB) + mem_wr_buffer(组合) + IF2(加了但注释) − FPU
  │      = 5级, CPU 150MHz, WNS+0.865(稳), LUT5482/FF4111/BRAM16, 0.45W
  │
  └─▶ B = five_level_area_250M
         + 单表预测(仅AREA) + 深流水(if_id寄存指令 + MEM_BUFFER级) + mem_wr_buffer(改寄存/retiming) + 2级前递 − FPU
         = 7级, CPU 250MHz, WNS+0.035(压线), LUT4448/FF2622/BRAM64, 0.54W
         │
         └─▶ riscv_coremark / riscv_coremark1
                B血统核(MEM_BUFFER+单表AREA,无IF2)抽出做CoreMark, 100MHz/16K, 无硬件M(软件乘除), 缺固件
```

| 工程 | 类型 | 活动核 | 流水级 | 分支预测 | ISA | 实现频率 | 状态 |
|---|---|---|---|---|---|---|---|
| **Template** | 数字孪生 | rtl_full2 RISCV | 5 | 无(静态) | RV32I+部分F | 未实现 | 基线 |
| **A / 200M** | 数字孪生 | rtl_full2 RISCV+预测 | 5 | 锦标赛 | RV32I | 150 MHz | 已实现 |
| **B / 250M** | 数字孪生 | rtl_full2 RISCV+深流水 | 7 | 单表Bimodal | RV32I | 250 MHz | 已实现 |
| **coremark** | 跑分 | B血统核 | ~7 | 单表 | RV32I(软M) | 100 MHz | 缺固件 |
| **coremark1** | 跑分 | 同上 | ~7 | 单表 | RV32I(软M) | 100 MHz | 缺固件·近重复 |

---

## 2. 公共底座（所有工程共享）

- **SoC 结构**：`student_top` → `RISCV` 核 + `perip_bridge` + 虚拟外设(`seg7/display_seg/counter/uart/dram_driver`) + IP(`IROM/DRAM/blk_mem_gen/pll×2`)。数字孪生外壳把核的访存/GPIO 映射到虚拟按键/开关/LED/数码管，供上位机"孪生"显示。
- **内核基线(rtl_full2)**：经典 5 级顺序流水 IF/ID/EX/MEM/WB；`rib` 内部总线；寄存器边界 `pc.v → if_id.v → id_ex.v → EX_UNIT输出寄 → MEM_UNIT输出寄 → wb`。冒险：`gpr` 内 EX/MEM 前递 + load-use 的 `keep_flag` 单拍重放；分支 EX 段解析、组合回灌 PC 冲刷。
- **时钟**："200/250MHz"文件夹名里，200 是**板载差分输入钟**；CPU 真时钟是 PLL `clk_out2_pll`（A=150M、B=250M）。`defines.v CLK_FREQ=50MHz` 只是 UART/外设域常数。XDC 无 `create_clock`，CPU 约束由 PLL IP 自动生成。
- **遗留核(rtl_full)**：磁盘上另有一颗更全的 `RISCV_CORE`(IFU/IDU/EXU/LSU/WBU + mul/div/csr/clint = **RV32IM+CSR+CLINT**)，但 `.xpr` 只收录其 `defines.v`，本体未编译 → 全族谱都不用它。可视作 rtl_full2 的"全功能祖先"。

---

## 3. 逐工程深度解析 + 评判

### 3.1 Template（基线）
- **架构**：rtl_full2 `RISCV`，5 级，**无任何分支预测 / IF2 / 写缓冲**（全树 grep `bpu/btb/ghr/pht/IF2/MEM_BUFFER` 零命中）。分支静态 not-taken + EX 冲刷。
- **FPU 是"活的"**：`cu.v:220/235/247` 真实例化 `normalizer_1/rounding/normalizer_2`，`INS_TYPE_FP` 写回浮点堆（`cu.v:449-452`）；`RF_UNIT` 例化**两套 gpr**(`u_int`+`u_float`)。但只实现 **FADD.S/FSUB.S/FMV.S.X/FLW/FSW** 五条（MUL_FP/DIV_FP/FMV.X.S 有宏无 case）→ **部分、单周期 F 扩展**。
- **ISA**：活动核 = **RV32I + 部分 F，无 M**（mul/div 仅宏、无模块、DSP=0）、无真 CSR/中断。
- **存储/程序**：IROM=`rom.v` 4096×32=16KB，`$readmemh` 载 `test.hex`（**硬编码作者桌面绝对路径** `rom.v:21`，移植即断，但程序本体在仓 `imports/test_src/test.hex`）；`defines ROM_NUM=32768` 与 rom.v 实写 4096 **不一致**。
- **状态**：`impl_1` 无 dcp/报告 → **从未实现**，只有源码/架构价值，无面积时序数据点。
- **评判**：✅ 干净完整的教学基线；✅ 少见地带一个能用的部分 FPU + 双寄存器堆。⚠️ 工程里塞了两颗核(rtl_full 死码)易误导；⚠️ FPU 不完整、rom 路径硬编码、ROM_NUM 名实不符；⚠️ 从 rtl_full 到 rtl_full2 **丢了硬件 M 和 CSR/中断**（功能退化换简化）。

### 3.2 A = 200M 全预测（5 级）
- **分支预测=锦标赛**：`GLOBAL_PREDICTOR`(Gshare, GBHR 10bit, PHT64×2b, idx=`pc^GBHR`) + `AREA_PREDICTOR`(Bimodal, idx=`pc[7:2]`) + `CPT`(64×2b 选择器) + 各带 BTB64，`bpu.v` 顶层按 CPT 选择。方向门控在 BTB 命中之上。
- **流水线**：仍 **5 级**——`IF2_UNIT` 文件在，但 `RISCV.v:142-152` **整段注释**，`ID_UNIT` 直吃 `if_ins_o`；`if_id.v:67-69` 指令字组合直通（靠 ROM 输出寄）。
- **访存**：`mem_wr_buffer` 读转发是 `always@(*)` **组合**（store-to-load 长链）。
- **实测**：CPU 150MHz、WNS **+0.865ns**、LUT5482/FF4111/BRAM16/0.45W；CPU 域最差路径在 **PC/取指**，**route 占 91%**（高扇出布线主导）。
- **评判**：✅ 预测器完整、是最好的"预测器学习样本"；✅ 时序余量大、鲁棒。⚠️ **IF2 白加了(注释未用)**；⚠️ `Gshare/` 目录下 btb/ghr/pht/arbitration/global_predictor **全是未例化死码**（真正生效的是 top/ 大写模块）；⚠️ 预测器全组合汇入 PC = **Fmax 杀手**（150MHz 的根因），逻辑面积最大。

### 3.3 B = 250M 面积/深流水（7 级）
- **深流水**：比 A **多 2 个寄存器级**——① `if_id.v:48-61` 把指令字也寄存(=折入 IF2 那一拍)；② EX↔MEM 间新增 `MEM_BUFFER` 整级(`RISCV.v:245-268`，对所有指令打拍)。级链 IF→ID→EX→**MEM_BUFFER→MEM**→WB = **7 级**。
- **访存 retiming(B 的核心贡献)**：`mem_wr_buffer.rd_data_o` **组合→寄存**(`mem_wr_buffer.v:40`)+ 同拍写读旁路(:41)；把 4ns 塞不下的组合长链一劈为二。时序铁证：最差路径终点=`mem_wr_buffer_inst/rd_data_o_reg/D`，**logic 2.015ns(5级LUT)**、slack **+0.035ns**。
- **配套**：**2 级前递**(`RISCV.v:112-119` `ex_bypass`/`mbem_bypass`，比较从 gpr 内上提到顶层)补偿 load +1 拍；`hold_flag` 3bit→1bit。
- **预测退化**：删 `bpu/CPT`、`GLOBAL_PREDICTOR` 注释，**只剩单表 Bimodal(AREA)**，无全局历史。
- **实测**：CPU 250MHz、WNS **+0.035ns(压线)**、LUT4448(−19%)/FF2622(−36%)/BRAM64(+300%)/0.54W；主 RAM `blk_mem_gen_0` 16K→**64K**(扩容,非时序需要)。
- **评判**：✅ retiming 切访存关键路径是**真时序工程**、逻辑精简、Fmax 高。⚠️ **WNS+0.035 危险压线**(换种子/温度可能掉)；⚠️ 预测退化(丢全局历史)；⚠️ BRAM×4 是容量扩张、功耗反升；⚠️ 存转发寄存化后的**同拍旁路正确性**需重点验证(store 紧跟同地址 load)。

### 3.4 coremark / coremark1
- **血统**：B 系核(有 `MEM_BUFFER`+单表 `AREA_PREDICTOR`、无 IF2/bpu/CPT)抽出、去数字孪生外壳，`tb_top.v` 裸壳跑分，100MHz/16K。
- **无硬件 M**：DSP=0、无 mul/div 模块 → CoreMark 必是 **rv32i 软件乘除**编译，分数被软乘除开销主导。
- **状态**：`rom.v` 的 `$readmemh` 指向 `D:\final.hex`(coremark)/别人桌面(coremark1)，**固件均缺失** → 本机跑不出分；两者仅 rom 路径不同，**近乎重复**。
- **评判**：✅ 便于纯核跑分。⚠️ 固件路径硬编码且缺失 = **不可复现**；⚠️ 无硬件 M 使 CoreMark 更像"软乘除+分支"混合负载，弱化了分支预测差异的体现；⚠️ 两份重复、`tb_top` 无评分读出。

---

## 4. 横向对比矩阵

| 维度 | Template | A / 200M | B / 250M | coremark |
|---|---|---|---|---|
| 流水级数 | 5 | 5 | **7** | ~7 |
| CPU 时钟 | 未实现 | 150 MHz | 250 MHz | 100 MHz |
| WNS | — | +0.865 | +0.035 | — |
| 分支预测 | 无(静态) | 锦标赛(3预测器+选择器) | 单表Bimodal | 单表 |
| 误预测冲刷 | ~2 | ~2 | ~3 | ~3 |
| IF2 | 无 | 有但注释 | 折入if_id | 无 |
| 访存写缓冲 | 无 | mem_wr_buffer(组合) | +MEM_BUFFER+读寄存 | +MEM_BUFFER |
| 前递级数 | EX/MEM(gpr内) | 3源(gpr内) | 4源(顶层上提) | 4源 |
| ISA | RV32I+部分F | RV32I | RV32I | RV32I(软M) |
| 硬件 M | 无(DSP0) | 无 | 无 | 无 |
| FPU | **有(部分F+双堆)** | 删 | 删 | 删 |
| LUT | — | 5482 | 4448 | — |
| FF | — | 4111 | 2622 | — |
| BRAM tile | — | 16 | 64 | — |
| 主RAM深度 | 4096(名义32768) | 16K | 64K | 16K |
| 功耗 | — | 0.45W | 0.54W | — |
| CPU域瓶颈 | — | PC/取指(route91%) | 访存写缓冲(logic51%) | — |

---

## 5. 关键技术专题（深挖点）

- **5.1 分支预测演进 无→锦标赛→单表**：Template 零预测 → A 堆到锦标赛(全局+局部+选择器，~92–96%命中) → B 为提频/减面积退回单表 Bimodal(~85–90%，丢分支相关性)。**反直觉点**：更"高级"的 A 反而更慢——因为预测器全组合挂在 PC 重定向回路、高扇出 route 主导。
- **5.2 访存关键路径 retiming(B 的精华)**：把 `mem_wr_buffer` 读转发 mux 从组合改寄存 + 插 `MEM_BUFFER` 级，一条 ~5.5ns 组合链劈两半 → 单路径 Fmax 近翻倍，代价 load +1 拍(靠 2 级前递补)。这是全族谱里最值得学的一手。
- **5.3 深度×频率×IPC 权衡**：A(浅5级+强预测,150M,高IPC) vs B(深7级+弱预测,250M,IPC打折)。`MIPS=Fmax×IPC`，非极端分支/访存负载下 B 大概率净胜；但 B 时序脆(+0.035)。
- **5.4 命名/死码陷阱(踩坑记录)**：①"200MHz"=输入钟非CPU钟(A实150M)；②A 的 IF2_UNIT 是**注释死码**(grep 会误判成六级)；③`Gshare/`叶子模块全是未例化死码；④rtl_full 整颗核是死码；⑤rom.v 路径硬编码 + ROM_NUM 名实不符；⑥活动核无硬件 M(只有宏)。

---

## 6. 评判速览（每工程"最该学 / 最该改"）

| 工程 | 最值得学的一点 | 最该改的一点 |
|---|---|---|
| Template | 部分 FPU + 双寄存器堆的挂法 | 清掉 rtl_full 死码、修 rom 硬编码路径与 ROM_NUM |
| A / 200M | 完整锦标赛预测器结构 | 要么启用 IF2 消化预测器时序、要么别留注释死码；清 Gshare 死码 |
| B / 250M | 访存 retiming 切关键路径 | 给 WNS 留余量(降档或再切一刀)；补回全局历史 |
| coremark | 纯核跑分隔离 | 固件入仓 + 相对路径；补硬件 M；去重 |

---

## 7. 研究接口 / 未来实验清单（留给将来的你）

> 每条含：目的 / 前置 / 步骤 / 预期。工具链：Vivado 2023.2 在 `D:\Vivado\Vivado\2023.2`（xsim 齐）；无 RISC-V GCC 工具链（GFW 下难装，见 §8）。

- **E1 · 模板可跑基线**（最易）：目的=拿一个能实跑的参考核。前置=模板 `test.hex` 已在仓(`imports/test_src/test.hex`)，仅需把 `rom.v:21` 硬编码路径改成该相对路径。步骤=改路径→`vivado -mode batch launch_simulation` 跑 `top_tb`→抓 uart_tx/波形。预期=基线核正常执行 riscv-tests。
- **E2 · 实测 CoreMark**：目的=把 §5.3 的估计换成实数。前置=需 `final.hex`(缺，见 comparison 文档)。步骤=hex 放回 `D:\final.hex`→跑 `riscv_coremark` 与(可选)A/B 版→解 UART CoreMark 分 + 数周期算 CPI。预期=B(250M)MIPS 高于 A(150M),验证频率增益盖过 IPC 损失。
- **E3 · 统一实现扫描**：目的=Template/A/B 在**同一约束**下的面积-时序曲线。步骤=给三者同一 XDC/PLL 目标，逐一 implement，收集 LUT/FF/BRAM/WNS/Fmax。预期=量化"预测器换面积、深流水换频率"。
- **E4 · 合并版(最有价值)**：目的=证明能兼得。做法=把 A 的锦标赛预测器移植进 B 的深流水(B 多出的取指拍正好容纳预测器查表)+ 保留 B 的访存 retiming。预期=深流水+强预测+切访存，MIPS 大概率超现有两版。
- **E5 · 预测命中率仿真**：目的=量化 A vs B 预测精度。做法=用 riscv-tests/分支密集程序，在 EX 段计数 `jump_flag ^ predict_taken` 误预测。预期=A 明显低于 B 的误预测率。
- **E6 · 复活 Gshare 死码**：目的=搞清 `Gshare/` 叶子模块与 top/ 大写模块的关系/差异，是否曾是早期实现。
- **E7 · B 时序余量扫描**：目的=找 B 真正安全的 Fmax。做法=PLL 扫 230/240/250MHz，看 WNS 回正点。预期=~230–240MHz 有健康余量。
- **E8 · 恢复硬件 M**：目的=CoreMark 用硬件乘除。做法=把 rtl_full 的 `mul.v/div.v` 移植进 rtl_full2 的 EX，接 INS_MUL/INS_DIV。预期=CoreMark 分数显著上升、更能体现分支预测差异。
- **E9 · 重集成 FPU**：把模板的部分 F 移回 A/B，做 RV32IF 流水，评估对时序/面积的冲击。

**开放问题**：①A/B 的 RF_UNIT 是否也删了浮点堆(未逐行核)；②coremark 的 CoreMark 是否真 rv32i 软乘除编译(需看固件反汇编)；③B 同拍存转发旁路在极端 store→load 序列下的正确性(需定向激励)；④rtl_full 死核是否可作 RV32IM 升级路径。

---

## 8. 附录

### 8.1 代码锚点总表
| 事项 | 文件:行号 |
|---|---|
| 模板活动核例化 | `Template/.../student_top.sv:79`（myCPU 死码 :63-77） |
| 模板核排除证据 | `Template/.../digital_twin.xpr:157`（rtl_full 仅 defines.v） |
| 模板 FPU 例化 | `Template/.../rtl_full2/core/cu.v:220/235/247`；双寄存器堆 `RF_UNIT.v:55/75` |
| 遗留核 RV32IM | `Template/.../rtl_full/top/RISCV_CORE.v`+`EXU.v:242-250`（mul/div）+`:178`(clint) |
| A 锦标赛预测器 | `A/.../rtl_full2/top/{bpu,CPT,GLOBAL_PREDICTOR,AREA_PREDICTOR}.v` |
| A IF2 注释死码 | `A/.../rtl_full2/top/RISCV.v:142-152` |
| A/B if_id 组合↔寄存 | `A/.../core/if_id.v:67-69` vs `B/.../core/if_id.v:48-61` |
| B 访存 retiming | `B/.../core/mem_wr_buffer.v:40-50`；新增级 `B/.../top/MEM_BUFFER.v`+`RISCV.v:245-268` |
| B 两级前递 | `B/.../top/RISCV.v:112-119` + `core/gpr.v:44-54` |
| coremark 固件路径 | `riscv_coremark/.../perips/rom.v:54`（`D:\final.hex` 缺失） |
| 实现数据 | 各工程 `digital_twin.runs/impl_1/{top_utilization_placed,top_power_routed,top_timing_summary_routed}.rpt, runme.log` |

### 8.2 工具链 / 环境备忘
- Vivado 2023.2 设计套件 + xsim：`D:\Vivado\Vivado\2023.2\bin\{vivado,xsim,xelab,xvlog}.bat`。
- 无 RISC-V GCC 工具链；GFW 下 github/pypi 受限，装工具链/取 CoreMark 源需走 aliyun/gitee 镜像。
- `unzip` 对 `D:/…` 路径报错(Info-ZIP 把 `:` 当 host:archive)→ 列 zip 用 `/d/Miniconda3/python`+`zipfile`，且须 `PYTHONUTF8=1`(源码/路径含中文)。
- 分析方法：实现报告(硬数据) + Read/Grep 亲验 RTL + 并行子代理(分支预测/流水线访存/模板)交叉验证；注意 grep 会命中**注释块内**的模块名，务必 Read 上下文辨死活。
