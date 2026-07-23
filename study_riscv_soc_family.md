# JYD 集创赛 RISC-V SoC 工程族 · 技术研究底本

> 路径管理说明（2026-07-23）：A/200M 与 B/250M 的有效内核已由历史目录 `new/rtl_full2` 统一迁移到 `digital_twin.srcs/sources_1/rtl/cpu`。本文中的 `rtl_full2` 若表示架构血统则保留原称；已经删除的旧树和死码请到 `_archive_restore_only/source-98f3aab/` 查证。

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
  │      + 锦标赛分支预测(Gshare+Bimodal+CPT、两套BTB) + 写请求寄存/同址读旁路 + IF2例化仅存于注释 − FPU
  │      = 5级, CPU 150MHz, WNS+0.865(稳), LUT5482/FF4111/BRAM16, 0.45W
  │
  └─▶ B = five_level_area_250M
         + 单一Bimodal方向表/BTB64 + MEM_BUFFER级 + 读返回寄存化 + 四路前递 − FPU
         = 6级, CPU 250MHz, WNS+0.035(压线), LUT4448/FF2622/BRAM64, 0.54W
         │
         └─▶ riscv_coremark / riscv_coremark1
                B血统核(MEM_BUFFER+单表AREA,无IF2)抽出做CoreMark, 100MHz/16K, 无硬件M(软件乘除), 缺固件
```

| 工程 | 类型 | 活动核 | 流水级 | 分支预测 | ISA | 实现频率 | 状态 |
|---|---|---|---|---|---|---|---|
| **Template** | 数字孪生 | rtl_full2 RISCV | 5 | 无(静态) | RV32I+部分F | 未实现 | 基线 |
| **A / 200M** | 数字孪生 | rtl_full2 RISCV+预测 | 5 | 锦标赛 | RV32I | 150 MHz | 已实现 |
| **B / 250M** | 数字孪生 | RISCV+MEM_BUFFER | 6 | Bimodal PHT64+BTB64 | RV32I | 250 MHz | 已实现 |
| **coremark** | 跑分 | B血统核 | 未复核 | 单表 | RV32I(软M) | 100 MHz | 缺固件 |
| **coremark1** | 跑分 | 同上 | 未复核 | 单表 | RV32I(软M) | 100 MHz | 缺固件·近重复 |

---

## 2. 公共底座（所有工程共享）

- **SoC 结构**：`top` 例化 PLL/UART/孪生控制器并进入 `student_top`；后者包含 `RISCV`、`perip_bridge` 与 ROM。A 的有效 IP 是 `dist_mem_gen_1 + blk_mem_gen_0 + pll`，B 是 `IROM + blk_mem_gen_0 + pll`；两者都只有一个 PLL IP、两个输出时钟。
- **内核基线（历史名 rtl_full2）**：A 是 5 级 IF/ID/EX/MEM/WB；B 在 EX 与 MEM 间增加一个 `MEM_BUFFER`，成为 6 级 IF/ID/EX/BUFFER/MEM/WB。两者都在 EX 解析分支并清除 IF/ID 两个年轻级；A 是 EX/MEM/WB 三源前递，B 是 EX/MBEM/MEM/WB 四路前递。
- **时钟**："200/250MHz"文件夹名里，200 是**板载差分输入钟**；CPU 真时钟是 PLL `clk_out2_pll`（A=150M、B=250M）。`defines.v CLK_FREQ=50MHz` 只是 UART/外设域常数。XDC 无 `create_clock`，CPU 约束由 PLL IP 自动生成。
- **遗留核(rtl_full)**：整理前快照中另有一颗 `RISCV_CORE`（IFU/IDU/EXU/LSU/WBU + mul/div/csr/clint），从未成为 A/B 的活动实现；现已仅保存在 `_archive_restore_only/source-98f3aab/`，可作为历史血统参考。

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
- **分支预测=锦标赛**：`GLOBAL_PREDICTOR`（Gshare 风格，GBHR 寄存器声明 10 bit、实际低 6 bit 参与 PHT64×2b 索引）+ `AREA_PREDICTOR`（PC 索引的 Bimodal PHT64×2b）+ `CPT`（64×2b 选择器）。全局/AREA 各有一套 BTB64，共两套；只预测条件分支，JAL/JALR 仍在 EX 重定向。
- **流水线**：仍 **5 级**——`RISCV.v:142-152` 的 IF2 例化整段在注释中，当前活动树没有 `IF2_UNIT.v`；`ID_UNIT` 直吃 `if_ins_o`，`if_id.v:67-69` 使用 ROM 已寄存的输出。
- **访存**：`mem_wr_buffer` 的写请求先寄存一拍，读返回与同地址 store-to-load 旁路为组合逻辑；不能笼统称为“纯组合缓冲”。
- **实测**：CPU 150MHz、WNS **+0.865ns**、LUT5482/FF4111/BRAM16/0.45W；CPU 域最差路径在 **PC/取指**，**route 占 91%**（高扇出布线主导）。
- **评判**：✅ 预测器结构完整、历史实现有 +0.865ns 余量。⚠️ IF2 只剩注释；历史 `Gshare/` 叶子死码已经移入归档。当前最差路径组包含预测反馈/PC/取指且布线占比高，但 PLL 只配置到 150MHz、未做极限频率扫描，不能把预测器写成已证明的唯一 Fmax 根因。

### 3.3 B = 250M 面积/深流水（6 级）
- **深流水**：B 的 IROM 是异步、零流水，`if_id` 是唯一取指输出边界；相对五级 A 只在 EX↔MEM 间新增一个 `MEM_BUFFER` 整级（`RISCV.v:245-268`）。实际级链为 IF→ID→EX→**BUFFER**→MEM→WB = **6 级**。
- **访存时序改造**：`MEM_BUFFER` 锁存 EX 控制/地址/store 数据，主存返回数据则在 `mem_wr_buffer.rd_data_o` 寄存；历史报告的最差路径终点正是该寄存器、slack +0.035ns。该实现同时改变预测器、流水和存储规模，因此只能说读链寄存化与关键路径证据一致，不能单独归因为一次严格可比的 retiming 实验。
- **冒险处理**：`RISCV.v:112-119` 建立 EX→MBEM→MEM→WB 四路前递；`EX_UNIT` 另有 `load_use/load_any_use` 两阶段冲突检测。`MEM_BUFFER` 的 `_hypass` 端口在当前实例中未连接，不能写成依靠该端口补偿 load。
- **预测器**：活动实现只有单一 Bimodal 方向表（PHT64×2b）+ direct-mapped BTB64，无全局/局部历史；“单表”仅指方向预测表，不代表整个预测器只有一张存储表。
- **历史实现数据**：CPU 250MHz、WNS **+0.035ns(压线)**、LUT4448(−19%)/FF2622(−36%)/BRAM64(+300%)/0.54W；主 RAM 从 A 的 16384 words（64 KiB）扩到 B 的 65536 words（256 KiB）。
- **评判**：✅ 读链寄存化与新增 BUFFER 级是明确的时序工程手段。⚠️ 历史 WNS 仅 +0.035ns；预测器无全局历史；BRAM×4 主要来自扩容。store→load、连续 load-use、精确 CPI/罚拍仍需定向仿真，不能从静态 RTL直接宣称正确或性能净胜。

### 3.4 coremark / coremark1
- **血统**：B 系核(有 `MEM_BUFFER`+单表 `AREA_PREDICTOR`、无 IF2/bpu/CPT)抽出、去数字孪生外壳，`tb_top.v` 裸壳跑分，100MHz/16K。
- **无硬件 M**：DSP=0、无 mul/div 模块 → CoreMark 必是 **rv32i 软件乘除**编译，分数被软乘除开销主导。
- **状态**：`rom.v` 的 `$readmemh` 指向 `D:\final.hex`(coremark)/别人桌面(coremark1)，**固件均缺失** → 本机跑不出分；两者仅 rom 路径不同，**近乎重复**。
- **评判**：✅ 便于纯核跑分。⚠️ 固件路径硬编码且缺失 = **不可复现**；⚠️ 无硬件 M 使 CoreMark 更像"软乘除+分支"混合负载，弱化了分支预测差异的体现；⚠️ 两份重复、`tb_top` 无评分读出。

---

## 4. 横向对比矩阵

| 维度 | Template | A / 200M | B / 250M | coremark |
|---|---|---|---|---|
| 流水级数 | 5 | 5 | **6** | 未复核 |
| CPU 时钟 | 未实现 | 150 MHz | 250 MHz | 100 MHz |
| WNS | — | +0.865 | +0.035 | — |
| 分支预测 | 无(静态) | 锦标赛(2个方向分量+选择器、2套BTB) | Bimodal PHT64+BTB64 | 单表 |
| 误预测冲刷 | ~2 | 结构推断约2 | 结构推断约2 | 未复核 |
| IF2 | 无 | 仅有注释例化 | 无（IROM异步、零流水） | 未复核 |
| 访存写缓冲 | 无 | 写请求寄存+同址读组合旁路 | +MEM_BUFFER+读返回寄存 | +MEM_BUFFER |
| 前递级数 | EX/MEM(gpr内) | 3源(gpr内) | 4源(顶层上提) | 4源 |
| ISA | RV32I+部分F | RV32I | RV32I | RV32I(软M) |
| 硬件 M | 无(DSP0) | 无 | 无 | 无 |
| FPU | **有(部分F+双堆)** | 删 | 删 | 删 |
| LUT | — | 5482 | 4448 | — |
| FF | — | 4111 | 2622 | — |
| BRAM tile | — | 16 | 64 | — |
| 主RAM深度 | 4096 words | 16384 words / 64 KiB | 65536 words / 256 KiB | 16K（未复核单位） |
| 功耗 | — | 0.45W | 0.54W | — |
| CPU域瓶颈 | — | PC/取指(route91%) | 访存写缓冲(logic51%) | — |

---

## 5. 关键技术专题（深挖点）

- **5.1 分支预测演进 无→锦标赛→Bimodal**：Template 零预测 → A 使用 Gshare 风格全局分量+Bimodal 分量+CPT → B 只保留 Bimodal PHT64+BTB64。当前没有预测命中率计数；A/B 的 150/250MHz 是各自 PLL 配置，不是统一约束下的极限 Fmax 对比。
- **5.2 访存关键路径改造**：B 插入 `MEM_BUFFER` 并把 `mem_wr_buffer.rd_data_o` 寄存，历史最差路径与该寄存点吻合；同时配套四路前递和两阶段 load 冲突检测。因其余结构也有变化，不能据两份报告单独量化“近翻倍”或 load 的精确 CPI 代价。
- **5.3 深度×频率×IPC 权衡**：A 为 5 级/150MHz，B 为 6 级/250MHz；预测器和访存延迟不同，但两者都没有本次可复现的 IPC/CoreMark 数据。只能比较历史频率与结构，不能宣称 B 的 MIPS 净胜。
- **5.4 命名/历史陷阱**：①“200MHz”是输入钟，A CPU 为150MHz；②A 的 IF2 只有注释例化；③历史 `Gshare/`、`rtl_full` 已移入归档；④A/B 的有效 ROM 都由工程内 COE 初始化，`rom.v` 硬编码问题只属于模板/CoreMark支线；⑤活动 A/B 无硬件 M。

---

## 6. 已知限制与验证边界

- A 的 load-use `case` 只处理 `2'b10/01`，漏掉 rs1、rs2 同时命中 load 目的寄存器的 `2'b11`；需要定向回归。
- A/B 的 BTB tag 参数为 6 bit，但代码写入/比较 `pc[14:8]` 七位；当前 16 KiB IROM 中高位恒零，扩展地址空间前必须统一。
- A 的 `GLOBAL_PREDICTOR`、B 的 `EX_UNIT` 存在“先使用后声明”Vivado warning，宜做无行为变化的声明顺序清理。
- A 的 counter 控制从 150MHz CPU 域直接进入 50MHz counter 域，未见显式 CDC；B 的分支修正只比较方向，未单独检测 BTB 目标错误。
- 两个现有 `top_tb` 都不是完整自检 testbench。本轮 Vivado 只确认工程可打开、IP/编译序可解析；尚无整理后的完整综合/实现/功能仿真。

---

## 7. 评判速览（每工程"最该学 / 最该改"）

| 工程 | 最值得学的一点 | 最该改的一点 |
|---|---|---|
| Template | 部分 FPU + 双寄存器堆的挂法 | 清掉 rtl_full 死码、修 rom 硬编码路径与 ROM_NUM |
| A / 200M | 两分量锦标赛预测器结构 | 修正声明顺序/BTB tag宽度，并补齐 load-use 双源同目的检测 |
| B / 250M | 访存 retiming 切关键路径 | 给 WNS 留余量(降档或再切一刀)；补回全局历史 |
| coremark | 纯核跑分隔离 | 固件入仓 + 相对路径；补硬件 M；去重 |

---

## 8. 研究接口 / 未来实验清单（留给将来的你）

> 每条含：目的 / 前置 / 步骤 / 预期。工具链：Vivado 2023.2 在 `D:\Vivado\Vivado\2023.2`（xsim 齐）；无 RISC-V GCC 工具链（GFW 下难装，见 §9.2）。

- **E1 · 模板可跑基线**（最易）：目的=拿一个能实跑的参考核。前置=模板 `test.hex` 已在仓(`imports/test_src/test.hex`)，仅需把 `rom.v:21` 硬编码路径改成该相对路径。步骤=改路径→`vivado -mode batch launch_simulation` 跑 `top_tb`→抓 uart_tx/波形。预期=基线核正常执行 riscv-tests。
- **E2 · 实测 CoreMark**：目的=把 §5.3 的结构推断换成实数。CoreMark 支线仍缺 `final.hex`；A/B 已有工程内 COE，如需横向跑分应把同一固件转换为各自 COE 后分别仿真/上板，测周期与 UART 输出，而不是预设 B 一定更快。
- **E3 · 统一实现扫描**：目的=Template/A/B 在**同一约束**下的面积-时序曲线。步骤=给三者同一 XDC/PLL 目标，逐一 implement，收集 LUT/FF/BRAM/WNS/Fmax。预期=量化"预测器换面积、深流水换频率"。
- **E4 · 合并版**：把 A 的锦标赛预测器移植进 B，同时保留 B 的访存时序改造；B 当前没有额外取指级，如预测回路不收敛，应显式新增独立预测级。性能结果必须通过统一固件和约束验证。
- **E5 · 预测命中率仿真**：目的=量化 A vs B 预测精度。做法=用 riscv-tests/分支密集程序，在 EX 段计数 `jump_flag ^ predict_taken` 误预测。预期=A 明显低于 B 的误预测率。
- **E6 · 归档考古**：只读比较 `_archive_restore_only` 中历史 `Gshare/` 叶子模块与当前大写预测器，确认演化关系；不要把归档文件直接加入活动 XPR。
- **E7 · B 时序余量扫描**：目的=找 B 真正安全的 Fmax。做法=PLL 扫 230/240/250MHz，看 WNS 回正点。预期=~230–240MHz 有健康余量。
- **E8 · 恢复硬件 M**：从归档 `rtl_full` 考证 `mul.v/div.v`，再以新模块方式接入当前 `rtl/cpu`；功能、冒险和时序都需独立验证。
- **E9 · 重集成 FPU**：把模板的部分 F 移回 A/B，做 RV32IF 流水，评估对时序/面积的冲击。

**开放问题**：①CoreMark 是否确为 rv32i 软件乘除编译（需固件反汇编）；②B 的 store→load、连续 load-use 与地址对齐是否正确（需定向激励）；③A 的 load-use `2'b11` 漏检如何修复并回归；④归档 `rtl_full` 是否适合作为 RV32IM 升级参考。A/B 的 `RF_UNIT` 已确认只有整数寄存器堆。

---

## 9. 附录

### 9.1 代码锚点总表
| 事项 | 文件:行号 |
|---|---|
| 模板活动核例化 | `Template/.../student_top.sv:79`（myCPU 死码 :63-77） |
| 模板核排除证据 | `Template/.../digital_twin.xpr:157`（rtl_full 仅 defines.v） |
| 模板 FPU 例化 | `Template/.../rtl_full2/core/cu.v:220/235/247`；双寄存器堆 `RF_UNIT.v:55/75` |
| 遗留核 RV32IM | `Template/.../rtl_full/top/RISCV_CORE.v`+`EXU.v:242-250`（mul/div）+`:178`(clint) |
| A 锦标赛预测器 | `five_level_200MHz_with_all_branch/.../rtl/cpu/top/{bpu,CPT,GLOBAL_PREDICTOR,AREA_PREDICTOR}.v` |
| A IF2 注释 | `five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v:142-152` |
| A/B IF 边界 | `five_level_200MHz_with_all_branch/.../rtl/cpu/core/if_id.v:51-69`；`five_level_area_250M/.../rtl/cpu/core/if_id.v:48-60`；B IROM `IROM.xci:14,19-20,42,61` |
| B 访存时序改造 | `five_level_area_250M/.../rtl/cpu/core/mem_wr_buffer.v:40-50`；`.../top/MEM_BUFFER.v:35-55`；`RISCV.v:245-268` |
| B 四路前递/冲突检测 | `five_level_area_250M/.../rtl/cpu/top/RISCV.v:112-119`；`core/gpr.v:39-74`；`top/EX_UNIT.v:65-72` |
| coremark 固件路径 | `riscv_coremark/.../perips/rom.v:54`（`D:\final.hex` 缺失） |
| 历史实现数据 | `reports/200M/` 与 `reports/250M/`（整理后尚未重跑完整实现） |

### 9.2 工具链 / 环境备忘
- Vivado 2023.2 设计套件 + xsim：`D:\Vivado\Vivado\2023.2\bin\{vivado,xsim,xelab,xvlog}.bat`。
- 无 RISC-V GCC 工具链；GFW 下 github/pypi 受限，装工具链/取 CoreMark 源需走 aliyun/gitee 镜像。
- `unzip` 对 `D:/…` 路径报错(Info-ZIP 把 `:` 当 host:archive)→ 列 zip 用 `/d/Miniconda3/python`+`zipfile`，且须 `PYTHONUTF8=1`(源码/路径含中文)。
- 分析方法：两个上下文隔离的独立审计分别复核 A/B，主线程再以实现报告、XPR/XCI 与 Read/Grep 亲验 RTL 交叉校正；注意 grep 会命中**注释块内**的模块名，务必结合活动 XPR 和上下文辨死活。
