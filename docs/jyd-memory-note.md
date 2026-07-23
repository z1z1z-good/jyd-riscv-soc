# JYD RISC-V SoC 分析要点速记

> 当前路径：200M/250M 的有效 CPU 统一位于 `digital_twin.srcs/sources_1/rtl/cpu`；`rtl_full2` 是历史称呼，旧树在 `_archive_restore_only/source-98f3aab/`。

## 工程集

- `JYD2025_Contest-Template0005`：赛方模板支线，含部分 FPU；本轮未复核。
- `five_level_200MHz_with_all_branch`（A）与 `five_level_area_250M`（B）：活动工程顶层均为 `top`，层次为 `top → student_top → RISCV`。
- `riscv_coremark` / `riscv_coremark1`：CoreMark 支线，仍缺原 `final.hex`；本轮未复核其流水级数。

## A / B 已复核结论

- **A**：5 级 IF/ID/EX/MEM/WB；CPU 150 MHz；历史 WNS +0.865 ns、LUT5482/FF4111/BRAM16。
- **A 预测器**：Gshare 风格全局分量+Bimodal 分量+CPT，只有两套 BTB64。GBHR 寄存器声明 10 bit，但 PHT64 索引实际只用低 6 bit。只预测条件分支，JAL/JALR 在 EX 重定向。
- **B**：6 级 IF/ID/EX/BUFFER/MEM/WB，不是 7 级；CPU 250 MHz；历史 WNS +0.035 ns、LUT4448/FF2622/BRAM64。
- **B 预测器**：单一 Bimodal 方向 PHT64×2b + BTB64，无全局/局部历史。“单表”仅指方向表。
- **B 访存时序**：`MEM_BUFFER` 锁存 EX 控制/地址/store 数据；主存返回数据在 `mem_wr_buffer.rd_data_o` 寄存。历史最差路径与该寄存点吻合，但不能据此把 250 MHz 完全归因于单一 retiming 动作。
- **冒险**：A 是 EX/MEM/WB 三源前递；B 是 EX/MBEM/MEM/WB 四路前递，并有 `load_use/load_any_use` 两阶段检测。两者分支均在 EX 解析，结构性冲刷约 2 拍，精确罚拍尚未仿真。

## 命名与结构坑

1. `200MHz` 是板载差分输入钟，A CPU 实际为 150 MHz；B CPU 为 250 MHz。
2. A 的 `RISCV.v:142-152` 只有 IF2 注释例化，当前活动树没有 `IF2_UNIT.v`。
3. B 的 IROM 是异步、零流水，`if_id` 不是第二个取指寄存级；B 只比 A 多一个 `MEM_BUFFER` 级。
4. 历史 `Gshare/`、`rtl_full` 等死码已移入归档，不应重新加入活动 XPR。
5. A 数据 RAM 是 16384 words×32 = 64 KiB；B 是 65536 words×32 = 256 KiB。BRAM 16→64 主要是扩容。
6. A/B 的有效 IROM/DRAM 都使用工程内 `irom.coe/dram.coe`，不依赖 `D:\final.hex`。

## 已知限制

- A 的 load-use case 漏掉 rs1、rs2 同时命中 load 目的寄存器的 `2'b11`。
- A/B 的 BTB tag 参数宽度与 `[14:8]` 切片不一致；当前 16 KiB IROM 中高位恒零，扩展地址空间前需修正。
- A `GLOBAL_PREDICTOR`、B `EX_UNIT` 有声明顺序 Vivado warning。
- A counter 的 150 MHz→50 MHz 控制路径未见显式 CDC。
- B `MEM_BUFFER` 的 `_hypass` 端口在当前实例中未连接。
- 预测命中率、IPC、CoreMark、精确罚拍与极限 Fmax 都没有本轮实测数据。

## 验证状态

- 两个 XPR 的活动文件、IP/COE、编译序与归档隔离检查通过。
- Vivado 2023.2 可在临时副本打开工程、识别顶层/器件/IP；A 的三个 IP output products 已成功生成。
- 尚未完成管理后工程的完整 `synth_1`、implementation、bitstream 或自检仿真。
- `reports/200M`、`reports/250M` 是整理前的历史实现证据，不等价于当前工程已重综合。

## 环境备忘

- Vivado 2023.2：`D:\Vivado\Vivado\2023.2`。
- 提交前运行：`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\check-projects.ps1`。
- Grep 会命中注释和归档文件；技术结论必须结合活动 XPR、实例层次和 RTL 上下文。
