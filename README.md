# JYD 集创赛 RISC-V SoC 工程族 · 归档仓

`D:\JYD` 下 5 个 Vivado 工程的**源码级归档 + 完整技术分析**。
构建产物（原 4.7 GB 的 Xilinx 仿真库 / IP 缓存 / 综合结果，**全部可再生**）已用 `.gitignore` 排除；clone 回来后用 Vivado 从 `.xpr` 重新生成即可。归档日期 2026-07-03。

---

## 仓库内容
| 路径 | 内容 |
|---|---|
| `study_riscv_soc_family.md` | **全族谱技术研究底本**（逐工程解析 + 横向矩阵 + 研究路线 E1–E9 + 代码锚点）——**先读这个** |
| `comparison_200M_vs_250M.md` | A(200M) vs B(250M) 聚焦深挖（§0–§8） |
| `reports/{200M,250M}/` | 关键实现报告：`top_timing_summary_routed.rpt` / `top_utilization_placed.rpt` / `top_power_routed.rpt` + 250M 的 `runme.log`（记录 WNS −0.052→+0.035 的 retiming 收敛） |
| `docs/jyd-memory-note.md` | 分析要点速记 |
| `JYD2025_Contest-Template0005/` | 赛方基线模板（源码；未实现） |
| `five_level_200MHz_with_all_branch/` | A：5 级 + 锦标赛预测（CPU 150 MHz） |
| `five_level_area_250M/` | B：7 级深流水 + 单表预测 + MEM_BUFFER retiming（CPU 250 MHz） |
| `riscv_coremark/` `riscv_coremark1/` | B 血统核抽出的 CoreMark 跑分工程（缺固件，近重复） |

> 每个工程只入库其 `*.srcs/`（RTL / 约束 / 仿真 tb / IP 定义 `.xci` / 初始化 `.coe`/`.hex`/`test.hex`）与 `.xpr`。

## 工程族谱（详见 study 文档 §1）
```
Template(基线·5级·RV32I+部分F·无预测·未实现)   └ 另挂遗留核 rtl_full(RV32IM+CSR,被.xpr排除=死码)
   ├─▶ A/200M：+锦标赛预测(Gshare+Bimodal+CPT)+mem_wr_buffer(组合) −FPU  = 5级/150MHz/WNS+0.865
   └─▶ B/250M：+单表预测 +深流水(if_id寄存+MEM_BUFFER) +读转发寄存化(retiming) +2级前递 −FPU = 7级/250MHz/WNS+0.035
           └─▶ coremark/coremark1：B血统核抽出跑分(100MHz/16K/无硬件M/缺固件)
```

---

## 🔄 从零取回与重建（假设本地已全部删除，什么都不记得也能照做）

**① 取回源码（约 20 MB，秒级）**
```
git clone https://github.com/z1z1z-good/jyd-riscv-soc.git
```
克隆下来只有源码 + 分析文档 + 关键报告，**没有任何 Vivado 构建产物**。

**② 用 Vivado 打开工程**
- 版本 **Vivado 2023.2**（原构建版本；本机曾装在 `D:\Vivado\Vivado\2023.2`，xsim/xelab/xvlog/vivado.bat 齐）。
- 打开工程文件：数字孪生三工程 = `<工程>/digital_twin.xpr`；CoreMark 两工程 = `<工程>/riscv_coremark.xpr`。
- 打开后会提示 IP / 输出产物缺失或过期（因 `.gen/.cache` 未入库）——**正常现象**，见下一步。

**③ 未上传部分如何再生（那 4.7 GB 构建产物全部可自动重建）**
被 `.gitignore` 排除的都是**工具生成物**，不含任何手写内容：

| 排除目录 | 是什么 | 如何再生 |
|---|---|---|
| `*.gen` | 各 IP 生成的 HDL / 仿真模型 / 网表 | 由 `.srcs` 里的 `.xci` 定义生成 |
| `*.cache` | ModelSim 仿真库 + IP 离线综合缓存 | 综合时自动生成 |
| `*.runs` | 综合 / 实现运行目录 + 报告 | 跑 synth / impl 生成 |
| `.Xil` `*.log` `*.jou` `*.str` | 临时 / 日志 / 崩溃转储 | 运行自动产生 |

- **GUI**：Sources 面板右键任一 IP → *Generate Output Products*；再 *Run Synthesis* / *Run Implementation*（或直接 *Generate Bitstream* 连带全做）。
- **Tcl 一键**（Vivado Tcl Console）：
```tcl
open_project <工程>.xpr
upgrade_ip          [get_ips *]     ;# 需要时升级 IP
generate_target all [get_ips *]     ;# 重生成所有 IP 输出产物（.gen）
launch_runs synth_1 -jobs 8 ; wait_on_run synth_1
launch_runs impl_1  -jobs 8 ; wait_on_run impl_1
```
重建后每个数字孪生工程会重新长回约 1 GB（`cache≈800MB` + `gen≈160MB`），属正常。

**④ 仿真（要跑运行结果时）**
- **模板可直接跑**：程序 `test.hex` 已在 `imports/test_src/`；只需把 `rom.v` 的 `$readmemh` 硬编码绝对路径改成该相对路径，即可 xsim 跑 `top_tb`。
- **A / B / CoreMark 需自备 `final.hex`**（原在作者机器 `D:\final.hex`，未入库）；放回 `rom.v` 指定路径即可。详见 study §7 E2。

**⑤ 不想重跑也能查数据**：`reports/{200M,250M}/` 已存好当时的 timing / util / power 报告 + 250M 的 retiming 日志；`study` / `comparison` 文档的结论据此得出，重拾时直接看即可，不必重新 implement。

## 分析方法（供复现 / 扩展）
- **硬数据**：各 `digital_twin.runs/impl_1/` 的 `top_utilization_placed.rpt` / `top_power_routed.rpt` / `top_timing_summary_routed.rpt` + `runme.log`（抓 `WNS=` 行）。已挑关键报告放入 `reports/`。
- **RTL 核验**：Read/Grep 亲验。**注意 grep 会命中注释块内的模块名**——本工程多处死码陷阱：A 的 `IF2_UNIT` 例化被 `/* */` 注释、`Gshare/` 叶子模块未例化、`rtl_full` 整核被 `.xpr` 排除。务必 Read 上下文辨死活。
- **交叉验证**：三路并行分析（分支预测 / 流水线访存 / 模板基线）互校。
- **命名陷阱**：`"200MHz"` 是**板载差分输入钟**，CPU 真时钟是 PLL `clk_out2_pll`（A=150M、B=250M）；详见 study §5.4。

## 研究路线（study §7，E1–E9）
最易上手 **E1**：改 `rom.v` 路径 → xsim 跑模板基线；最有价值 **E4**：把 A 的锦标赛预测器移植进 B 的深流水（B 多出的取指拍正好容纳预测查表）。其余：E2 实测 CoreMark（需 final.hex）、E3 统一实现扫描、E5 预测命中率仿真、E7 B 时序余量扫描、E8 恢复硬件 M、E9 重集成 FPU。

## 环境备忘
- 无 RISC-V GCC 工具链（本机 GFW 环境走 aliyun/gitee 镜像装）。
- `unzip` 对 `D:/…` 路径报错（Info-ZIP 把 `:` 当 host:archive）→ 列 zip 用 Python `zipfile`。
