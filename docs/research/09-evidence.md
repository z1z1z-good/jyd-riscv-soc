# 09 · 代码与报告证据索引

[阅读入口](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/README.md)

## 基线与使用方法

研究源码基线为 bfd0e14fff512095bb8cb5ab9d8520b247069148，开始时工作树干净；2026-09-05 新增本组文档。S/H/I/P 含义见入口。下方给出模块、核对范围与起始行跳转，固定版本链接用于防止未来源码改动后行号漂移。历史报告的生成日期、器件和工具见各报告开头，不等于当前 commit 生成的报告。

链接中的本地绝对路径适用于本工作区；源码同时提供固定提交的远端链接。内部文档入口适用于本机迁移前的位置，迁移后可直接按同目录文件名阅读。

<a id="e01"></a>

## E01 · 活动工程与顶层（S）

- [five_level_200MHz_with_all_branch/digital_twin.xpr](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.xpr:11)（核对 11—330 行）：器件、sources_1 的活动 RTL 与顶层；IP 还需查看各 IP fileset。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.xpr#L11)
- [five_level_area_250M/digital_twin.xpr](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.xpr:11)（核对 11—320 行）：器件与有效 RTL；MEM_BUFFER 在清单内。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.xpr#L11)
- [tools/check-projects.ps1](D:/codex_prj/fpga_dick/jyd-riscv-soc/tools/check-projects.ps1:1)（核对 1—40 行）：检查范围与项目列表；整份脚本还检查归档哈希。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/tools/check-projects.ps1#L1)

<a id="e02"></a>

## E02 · SoC、PLL 与复位（S）

- [top.sv](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/top.sv:31)（核对 31—89 行）：PLL、UART、twin_controller、student_top。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/top.sv#L31)
- [top.sv](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/top.sv:31)（核对 31—89 行）：同类顶层连接。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/top.sv#L31)
- [student_top.sv](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/student_top.sv:78)（核对 78—114 行）：CPU、IROM、桥；rib_hold 固定 0。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/student_top.sv#L78)
- [student_top.sv](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/student_top.sv:77)（核对 77—109 行）：CPU、异步 IROM 和桥。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/student_top.sv#L77)
- [five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/ip/pll_1/pll.xci](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/ip/pll_1/pll.xci:35)（核对 35—92 行）：输入 200，输出 50/150 MHz。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/ip/pll_1/pll.xci#L35)
- [five_level_area_250M/digital_twin.srcs/sources_1/ip/pll_1/pll.xci](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/ip/pll_1/pll.xci:35)（核对 35—92 行）：输入 200，输出 50/250 MHz。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/ip/pll_1/pll.xci#L35)

<a id="e03"></a>

## E03 · A 的取指边界与 IF2 注释（S）

- [five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/ip/dist_mem_gen_1/dist_mem_gen_1.xci](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/ip/dist_mem_gen_1/dist_mem_gen_1.xci:10)（核对 10—42 行）：4096×32，registered，C_HAS_CLK=1。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/ip/dist_mem_gen_1/dist_mem_gen_1.xci#L10)
- [cpu/core/if_id.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/if_id.v:42)（核对 42—69 行）：hold 延迟；PC 寄存；指令组合选 NOP。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/if_id.v#L42)
- [cpu/top/RISCV.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v:125)（核对 125—169 行）：有效 IF/ID 连接和注释 IF2。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v#L125)

<a id="e04"></a>

## E04 · B 的取指边界（S）

- [five_level_area_250M/digital_twin.srcs/sources_1/ip/IROM/IROM.xci](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/ip/IROM/IROM.xci:10)（核对 10—42 行）：4096×32，non_registered，0 额外 pipeline，C_HAS_CLK=0。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/ip/IROM/IROM.xci#L10)
- [cpu/core/if_id.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/if_id.v:48)（核对 48—60 行）：指令和 PC 同时寄存。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/if_id.v#L48)
- [student_top.sv](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/student_top.sv:58)（核对 58—90 行）：可达地址取 pc[13:2]；IROM 未接 clk。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/student_top.sv#L58)

<a id="e05"></a>

## E05 · A 的 ID 消费位置与三源前递（S）

- [cpu/top/ID_UNIT.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/ID_UNIT.v:49)（核对 49—93 行）：源地址组合输出；rd 经 id_ex。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/ID_UNIT.v#L49)
- [cpu/core/gpr.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/gpr.v:24)（核对 24—83 行）：x0 优先；EX、MEM、WB。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/gpr.v#L24)
- [cpu/top/RISCV.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v:172)（核对 172—226 行）：前递值与各阶段信号连接。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v#L172)

<a id="e06"></a>

## E06 · A load-use 与 PC/清空控制（S / I）

- [cpu/core/cu.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/cu.v:294)（核对 294—315 行）：10/01 重取；11 落入 default。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/cu.v#L294)
- [cpu/top/EX_UNIT.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/EX_UNIT.v:93)（核对 93—168 行）：EX 输出继续推进；hold 编码；两拍预测。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/EX_UNIT.v#L93)
- [cpu/core/pc.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/pc.v:39)（核对 39—59 行）：复位、jump、hold、预测、顺序优先级。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/pc.v#L39)
- [cpu/core/id_ex.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/id_ex.v:48)（核对 48—72 行）：hold >= HOLD_ID_EX 清 NOP。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/id_ex.v#L48)

<a id="e07"></a>

## E07 · B 两阶段 load 检测与重取（S / I）

- [cpu/top/EX_UNIT.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/EX_UNIT.v:65)（核对 65—163 行）：load_use/load_any_use；预测延迟；训练结果寄存。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/EX_UNIT.v#L65)
- [cpu/core/cu.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/cu.v:98)（核对 98—102 行）：jump/hold 合并；实际重定向优先。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/cu.v#L98)
- [cpu/core/pc.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/pc.v:39)（核对 39—59 行）：前端优先级。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/pc.v#L39)
- [cpu/core/id_ex.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/id_ex.v:48)（核对 48—72 行）：hold 清空而不是保持。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/id_ex.v#L48)

<a id="e08"></a>

## E08 · B 四源前递（S）

- [cpu/top/RISCV.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v:112)（核对 112—119 行）：EX/MBEM/MEM/WB 命中判断。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v#L112)
- [cpu/core/gpr.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/gpr.v:39)（核对 39—81 行）：两个读口的优先级与 x0。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/gpr.v#L39)
- [cpu/top/RISCV.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v:185)（核对 185—207 行）：BUFFER 前递直接接 EX 寄存结果。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v#L185)

<a id="e09"></a>

## E09 · B BUFFER 与地址对齐（S）

- [cpu/top/MEM_BUFFER.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/MEM_BUFFER.v:25)（核对 25—55 行）：hypass 组合镜像与实际输出寄存。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/MEM_BUFFER.v#L25)
- [cpu/top/RISCV.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v:245)（核对 245—292 行）：实例未连 hypass；MEM 输入较早地址。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v#L245)
- [cpu/top/MEM_UNIT.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/MEM_UNIT.v:57)（核对 57—111 行）：地址内部寄存；MEM 输出寄存；返回缓存实例。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/MEM_UNIT.v#L57)

<a id="e10"></a>

## E10 · 写缓存和读返回（S / I）

- [cpu/core/mem_wr_buffer.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/mem_wr_buffer.v:15)（核对 15—49 行）：一拍写缓存；读返回组合旁路。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/mem_wr_buffer.v#L15)
- [cpu/core/mem_wr_buffer.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/mem_wr_buffer.v:15)（核对 15—50 行）：当前写优先于缓存；返回 posedge 阻塞赋值。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/mem_wr_buffer.v#L15)
- [cpu/top/MEM_UNIT.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/MEM_UNIT.v:64)（核对 64—113 行）：扩展、MEM 输出寄存和旁路接口。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/MEM_UNIT.v#L64)
- [cpu/core/mem.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/mem.v:52)（核对 52—157 行）：低位选择、符号扩展和 SB/SH 读改写。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/mem.v#L52)

<a id="e11"></a>

## E11 · 地址译码、MMIO 和 RAM 接口（S）

- [perip_bridge.sv](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/perip_bridge.sv:40)（核对 40—123 行）：读地址寄存、窗口、MMIO 和 counter。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/perip_bridge.sv#L40)
- [perip_bridge.sv](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/perip_bridge.sv:40)（核对 40—123 行）：同类桥接连接与末地址比较。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/perip_bridge.sv#L40)
- [dram_driver.sv](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/dram_driver.sv:22)（核对 22—50 行）：按 word 切片转接。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/dram_driver.sv#L22)
- [cpu/perips/ram.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/perips/ram.v:108)（核对 108—145 行）：活动 RAM 以 word 地址 [13:0] 寻址，忽略输入高两位。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/perips/ram.v#L108)
- [cpu/perips/ram.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/perips/ram.v:108)（核对 108—145 行）：活动 RAM 实现与读写旁路。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/perips/ram.v#L108)

<a id="e12"></a>

## E12 · 主存 IP 配置（S）

- [five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci:16)（核对 16—54 行）：Simple_Dual_Port_RAM，32 bit，16384 words，工程内 COE。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci#L16)
- [five_level_area_250M/digital_twin.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci:16)（核对 16—54 行）：32 bit，65536 words；输出附加寄存关闭。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci#L16)

<a id="e13"></a>

## E13 · 预测与训练时机（S）

- [cpu/top/EX_UNIT.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/EX_UNIT.v:139)（核对 139—168 行）：预测两拍、EX 组合结果。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/EX_UNIT.v#L139)
- [cpu/top/EX_UNIT.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/EX_UNIT.v:124)（核对 124—163 行）：方向两拍；训练结果额外寄存。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/EX_UNIT.v#L124)
- [cpu/core/cu.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/cu.v:210)（核对 210—289 行）：JAL/JALR 与条件分支修正。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/cu.v#L210)
- [cpu/core/cu.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/cu.v:225)（核对 225—303 行）：条件分支方向修正，需结合全 cu。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/cu.v#L225)

<a id="e14"></a>

## E14 · A 的全局分量与选择器（S / I）

- [cpu/top/bpu.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/bpu.v:30)（核对 30—103 行）：两个方向延迟与分量/CPT 实例。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/bpu.v#L30)
- [cpu/top/GLOBAL_PREDICTOR.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/GLOBAL_PREDICTOR.v:29)（核对 29—104 行）：6-bit 索引、10-bit GBHR、两拍旧历史、PHT/BTB。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/GLOBAL_PREDICTOR.v#L29)
- [cpu/top/CPT.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/CPT.v:18)（核对 18—90 行）：64 项选择表，分歧时向正确分量调整。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/CPT.v#L18)

<a id="e15"></a>

## E15 · Bimodal 与 BTB tag（S）

- [cpu/top/AREA_PREDICTOR.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/AREA_PREDICTOR.v:1)（核对 1—68 行）：6-bit tag 与七位切片；二位计数。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/top/AREA_PREDICTOR.v#L1)
- [cpu/top/AREA_PREDICTOR.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/AREA_PREDICTOR.v:1)（核对 1—68 行）：除输出名外与 A 分量相同。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/AREA_PREDICTOR.v#L1)
- [cpu/top/RISCV.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v:120)（核对 120—147 行）：单分量生效；global 例化注释。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/top/RISCV.v#L120)

<a id="e16"></a>

## E16 · CPU 时钟和关键路径（H）

- [reports/200M/top_timing_summary_routed.rpt](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/200M/top_timing_summary_routed.rpt:273)（核对 273—315 行）：WNS、clock summary 与 inter-clock 表。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/200M/top_timing_summary_routed.rpt#L273)
- [reports/250M/top_timing_summary_routed.rpt](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/250M/top_timing_summary_routed.rpt:273)（核对 273—315 行）：同上。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/250M/top_timing_summary_routed.rpt#L273)
- [reports/200M/top_timing_summary_routed.rpt](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/200M/top_timing_summary_routed.rpt:1674)（核对 1674—1688 行）：PC→IROM，5.569 ns 数据路径。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/200M/top_timing_summary_routed.rpt#L1674)
- [reports/250M/top_timing_summary_routed.rpt](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/250M/top_timing_summary_routed.rpt:1678)（核对 1678—1692 行）：BRAM→rd_data_o，3.907 ns 数据路径。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/250M/top_timing_summary_routed.rpt#L1678)

<a id="e17"></a>

## E17 · 历史约束覆盖限制（H）

- [reports/200M/top_timing_summary_routed.rpt](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/200M/top_timing_summary_routed.rpt:55)（核对 55—83 行）：check_timing 分类与 no_clock 描述。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/200M/top_timing_summary_routed.rpt#L55)
- [reports/250M/top_timing_summary_routed.rpt](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/250M/top_timing_summary_routed.rpt:55)（核对 55—83 行）：同上。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/250M/top_timing_summary_routed.rpt#L55)
- [reports/200M/top_timing_summary_routed.rpt](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/200M/top_timing_summary_routed.rpt:214)（核对 214—225 行）：未约束内部端点与缺输入 delay。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/200M/top_timing_summary_routed.rpt#L214)
- [reports/250M/top_timing_summary_routed.rpt](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/250M/top_timing_summary_routed.rpt:214)（核对 214—225 行）：同上。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/250M/top_timing_summary_routed.rpt#L214)

<a id="e18"></a>

## E18 · 资源、功耗和实现日志（H）

- [reports/200M/top_utilization_placed.rpt](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/200M/top_utilization_placed.rpt:35)（核对 35—117 行）：top LUT/FF/BRAM/DSP。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/200M/top_utilization_placed.rpt#L35)
- [reports/250M/top_utilization_placed.rpt](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/250M/top_utilization_placed.rpt:35)（核对 35—117 行）：top LUT/FF/BRAM/DSP。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/250M/top_utilization_placed.rpt#L35)
- [reports/200M/top_power_routed.rpt](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/200M/top_power_routed.rpt:33)（核对 33—43 行）：总功耗估计、置信度、无活动文件。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/200M/top_power_routed.rpt#L33)
- [reports/250M/top_power_routed.rpt](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/250M/top_power_routed.rpt:33)（核对 33—43 行）：同上。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/250M/top_power_routed.rpt#L33)
- [reports/250M/runme.log](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/250M/runme.log:392)（核对 392—404 行）：物理优化汇总，Retime 行需按列读。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/250M/runme.log#L392)
- [reports/250M/runme.log](D:/codex_prj/fpga_dick/jyd-riscv-soc/reports/250M/runme.log:2390)（核对 2390—2504 行）：布线 WNS 演进，不能单独证明因果。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/reports/250M/runme.log#L2390)

<a id="e19"></a>

## E19 · 常用整数指令与宏定义边界（S）

- [cpu/core/cu.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/cu.v:118)（核对 118—320 行）：实际整数执行 case。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/cu.v#L118)
- [cpu/core/cu.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/cu.v:133)（核对 133—320 行）：实际整数执行 case。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/cpu/core/cu.v#L133)
- [cpu/core/defines.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/defines.v:47)（核对 47—98 行）：常量不等于已接入 CSR/M 功能。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/defines.v#L47)
- [cpu/core/id.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/id.v:67)（核对 67—135 行）：实际译码与未使用源处理。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/cpu/core/id.v#L67)

<a id="e20"></a>

## E20 · 模板支线（S）

- [JYD2025_Contest-Template0005/JYD2025_Contest-Template0003/digital_twin.xpr](D:/codex_prj/fpga_dick/jyd-riscv-soc/JYD2025_Contest-Template0005/JYD2025_Contest-Template0003/digital_twin.xpr:171)（核对 171—335 行）：有效 rtl_full2 与浮点辅助模块清单。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/JYD2025_Contest-Template0005/JYD2025_Contest-Template0003/digital_twin.xpr#L171)
- [JYD2025_Contest-Template0005/JYD2025_Contest-Template0003/digital_twin.srcs/sources_1/new/rtl_full2/core/cu.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/JYD2025_Contest-Template0005/JYD2025_Contest-Template0003/digital_twin.srcs/sources_1/new/rtl_full2/core/cu.v:425)（核对 425—460 行）：FLW/FSW/FP case；非完整 F 合规证明。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/JYD2025_Contest-Template0005/JYD2025_Contest-Template0003/digital_twin.srcs/sources_1/new/rtl_full2/core/cu.v#L425)
- [JYD2025_Contest-Template0005/JYD2025_Contest-Template0003/digital_twin.srcs/sources_1/new/rtl_full2/top/RISCV.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/JYD2025_Contest-Template0005/JYD2025_Contest-Template0003/digital_twin.srcs/sources_1/new/rtl_full2/top/RISCV.v:206)（核对 206—285 行）：EX/MEM 连接，浮点相关接口。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/JYD2025_Contest-Template0005/JYD2025_Contest-Template0003/digital_twin.srcs/sources_1/new/rtl_full2/top/RISCV.v#L206)

<a id="e21"></a>

## E21 · CoreMark 支线与固件缺口（S）

- [riscv_coremark/riscv_coremark.srcs/sources_1/new/core/RISCV.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/riscv_coremark/riscv_coremark.srcs/sources_1/new/core/RISCV.v:145)（核对 145—163 行）：AREA_PREDICTOR。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/riscv_coremark/riscv_coremark.srcs/sources_1/new/core/RISCV.v#L145)
- [riscv_coremark/riscv_coremark.srcs/sources_1/new/core/RISCV.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/riscv_coremark/riscv_coremark.srcs/sources_1/new/core/RISCV.v:305)（核对 305—329 行）：MEM_BUFFER。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/riscv_coremark/riscv_coremark.srcs/sources_1/new/core/RISCV.v#L305)
- [riscv_coremark/riscv_coremark.srcs/sources_1/new/perips/rom.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/riscv_coremark/riscv_coremark.srcs/sources_1/new/perips/rom.v:45)（核对 45—58 行）：仓库外固件引用；结合条件编译看用途。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/riscv_coremark/riscv_coremark.srcs/sources_1/new/perips/rom.v#L45)
- [riscv_coremark1/riscv_coremark/riscv_coremark.srcs/sources_1/new/perips/rom.v](D:/codex_prj/fpga_dick/jyd-riscv-soc/riscv_coremark1/riscv_coremark/riscv_coremark.srcs/sources_1/new/perips/rom.v:45)（核对 45—58 行）：另一份仓库外 final.hex 引用。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/riscv_coremark1/riscv_coremark/riscv_coremark.srcs/sources_1/new/perips/rom.v#L45)

<a id="e22"></a>

## E22 · counter 状态与跨频率连接（S / I）

- [counter.sv](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/counter.sv:35)（核对 35—69 行）：start 自保持、50 MHz 毫秒计数、读值寄存。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/counter.sv#L35)
- [counter.sv](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_area_250M/digital_twin.srcs/sources_1/rtl/counter.sv:35)（核对 35—69 行）：同类状态结构。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_area_250M/digital_twin.srcs/sources_1/rtl/counter.sv#L35)
- [perip_bridge.sv](D:/codex_prj/fpga_dick/jyd-riscv-soc/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/perip_bridge.sv:108)（核对 108—121 行）：cnt_clk 与 CPU 写信号、返回连接。[固定版本](https://github.com/z1z1z-good/jyd-riscv-soc/blob/bfd0e14fff512095bb8cb5ab9d8520b247069148/five_level_200MHz_with_all_branch/digital_twin.srcs/sources_1/rtl/perip_bridge.sv#L108)

## 外部原始资料

- [RISC-V RV32I 规范（20240411 版本库）](https://docs.riscv.org/reference/isa/v20240411/unpriv/rv32.html)：用于校准指令语义与“ISA 不规定流水级数”的边界；不作为本项目合规结论。
- [AMD Timing Path Details](https://docs.amd.com/r/en-US/ug906-vivado-design-analysis/Timing-Path-Details)：用于核对 slack、路径延迟含义；网页当前展示版本可能不同于历史 Vivado 2023.2，不作为重建说明。
- [AMD UG901 RETIMING_FORWARD，2023.2](https://docs.amd.com/r/2023.2-English/ug901-vivado-synthesis/RETIMING_FORWARD)：用于区分工具移动寄存器与人工增加级。
- [AMD UG835 phys_opt_design，2023.2](https://docs.amd.com/r/2023.2-English/ug835-vivado-tcl-commands/phys_opt_design)：用于解释 retime 是多种物理优化中的一种。

外部资料访问日期 2026-09-05。本文技术主体来自本地活动源码与原始报告；没有用网络文章替代项目取证。
