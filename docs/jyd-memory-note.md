# JYD RISC-V SoC 分析要点速记

> 从分析记忆中摘出的 JYD 技术要点(已脱敏:不含其它项目、内网信息、私密内容)。完整内容见 `study_riscv_soc_family.md`。

## 工程集
`D:\JYD` = 集创赛 JYD2025「数字孪生」赛道 RISC-V SoC 工程集(内核 tinyriscv 派生)。5 个工程:
- `JYD2025_Contest-Template0003`(赛方基线,自带部分 FPU) — 活动核 `rtl_full2/RISCV`;另挂遗留核 `rtl_full/RISCV_CORE`(RV32IM+CSR+CLINT,被 .xpr 排除=死码)。
- `five_level_200MHz_with_all_branch`(=A)、`five_level_area_250M`(=B) — 数字孪生工程,顶层 `student_top`。
- `riscv_coremark` + `riscv_coremark1` — 内核抽出跑分版,两者仅 rom.v 的 readmemh 路径不同,近乎重复。

## A vs B 核心结论
- **A**:5 级 + 锦标赛预测器(Gshare+Bimodal+CPT 选择器),CPU 实 150MHz、WNS+0.865(稳)、LUT5482/FF4111/BRAM16。
- **B**:7 级(if_id 寄存指令 + 新增 MEM_BUFFER 级)+ 单表 Bimodal,CPU 250MHz、WNS+0.035(压线)、LUT4448/FF2622/BRAM64。
- **B 提频关键 = retiming**:`mem_wr_buffer.rd_data_o` 组合→寄存 + MEM_BUFFER 打拍,切开访存读长链(时序最差路径落在 mem_wr_buffer_inst,logic 2.015ns)。

## 命名 / 结构坑(易误判,已核验)
1. 文件夹名 `"200MHz"` 是**板载差分输入钟**,CPU 真时钟是 PLL `clk_out2_pll`——A=150MHz、B=250MHz。
2. `IF2_UNIT` 在 A 的 `top/RISCV.v:142-152` 是**注释死码**(grep 会误匹配成六级),A 实为 5 级;真正的深流水是 B。
3. `Gshare/` 目录下小写叶子模块(ghr/pht/btb/arbitration/global_predictor)两版都是**未例化死码**,真正生效的是 `top/` 大写模块。
4. B 的 BRAM 16→64 是主 RAM `blk_mem_gen_0` 深度 16K→64K **扩容**(容量升级,非时序优化)。

## 模板基线要点
- 活动核 rtl_full2 = 纯 5 级 IF/ID/EX/MEM/WB,**无预测/无 IF2/无写缓冲**,分支 EX 段解析冲刷。
- **FPU 是活的**:cu.v 真例化 normalizer/rounding + 双寄存器堆(整数 u_int + 浮点 u_float),部分单周期 F(FADD/FSUB.S/FMV.S.X/FLW/FSW)。→ A/B 删 FPU 是砍功能非清死码。
- 活动核**无硬件 M**(0 个 mul/div 模块 + 综合 DSP=0)→ CoreMark 走软件乘除;硬件 M 只在被排除的遗留核 rtl_full。
- 模板 `test.hex` 在仓 `imports/test_src`,故**模板可仿真**(不像 coremark 缺固件)。

## CoreMark 本机现状
固件 `final.hex` 缺失(rom.v 载 `D:\final.hex` 不存在;coremark1 指向别人桌面路径)+ 无 RISC-V GCC 工具链 + `tb_top.v` 是裸时钟/复位壳无评分读出 → 本机跑不出分。Vivado 2023.2 设计套件 + xsim 在 `D:\Vivado\Vivado\2023.2`。

## 环境备忘
- `unzip` 对 `D:/…` 路径报 "cannot find or open"(Info-ZIP 把 `:` 当 host:archive)→ 列 zip 内容改用 Python `zipfile`,须 `PYTHONUTF8=1`(源码/路径含中文)。
- 分析方法:实现报告(硬数据) + Read/Grep 亲验 RTL + 并行子代理交叉验证;注意 grep 会命中**注释块内**的模块名,务必 Read 上下文辨死活。
