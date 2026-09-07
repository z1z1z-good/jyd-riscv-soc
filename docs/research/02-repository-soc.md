# 02 · 从仓库还原 CPU 与 SoC

[阅读入口](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/README.md) · [证据索引](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

## 1. 工程究竟运行什么

研究的两个有效工程由 XPR 指定 top，目标器件为 xc7k325tffg900-2。顶层连接如下；箭头表示连接关系，不代表全部接口具有握手或已经通过 CDC 验证。[E01、E02](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

~~~mermaid
flowchart TD
  IN["板载差分输入 200 MHz"] --> PLL["PLL"]
  PLL --> C50["50 MHz"]
  PLL --> CPUCLK["CPU A 150 / B 250 MHz"]
  C50 --> UART["UART 9600"]
  UART <--> TWIN["twin_controller"]
  TWIN --> VIN["虚拟开关和按键"]
  VIN --> BRIDGE["perip_bridge"]
  CPUCLK --> CPU["student_top 内 RISCV"]
  CPU --> IROM["IROM 指令地址"]
  IROM --> CPU
  CPU <--> BRIDGE
  BRIDGE <--> RAM["dram_driver / ram / BRAM"]
  BRIDGE --> VOUT["LED 和数码管"]
  VOUT --> TWIN
  BRIDGE <--> CNT["50 MHz counter"]
~~~

CPU 执行固件，通过普通 load/store 地址访问 RAM 和虚拟外设。UART 与 twin_controller 负责板外通信和虚拟 IO 状态；CPU 自身、SoC 外设、展示通信是不同层次。不能把 UART 的存在说成 CPU 自带串口指令。

## 2. 从陌生仓库建立证据的做法

| 步骤 | 查看什么 | 要得到什么 |
|---|---|---|
| 固定版本 | 提交号、工作区差异 | 确保后续引用属于同一份代码 |
| 确定入口 | XPR 的 sources_1、TopModule、UsedIn、IP fileset | 真正参与工程的文件集合 |
| 沿实例读 | top → student_top → RISCV / perip_bridge | 模块层次和信号端点 |
| 找状态 | always 的触发条件、复位、赋值、IP 延迟 | 寄存边界与状态更新规则 |
| 检查地址 | 位宽、切片、译码范围、初始化文件 | 可见地址空间与实际容量 |
| 跟踪代表指令 | ALU、load、store、分支 | 功能路径、依赖与副作用 |
| 读报告 | 器件、日期、约束覆盖、路径起终点 | 有条件的历史量化证据 |
| 建立问题单 | 确认事实与触发假设分开 | 可复查、可验证的改进方向 |

XPR 文件存在性检查不等于 elaboration 或功能验证。一次 rg 命中也不等于代码生效：B 的 ram.v 有大段旧实现注释；A 的 IF2 例化被注释；defines 中有 M/CSR 常量但没有相应完整活动执行链。

本次有效工程之外的原始归档、同级 managed 副本只用于追溯。当前 CPU 源码位于 sources_1/rtl/cpu；旧对话中的 new/rtl_full2 是历史路径。

## 3. 指令与数据地址

| 对象 | 配置与连接 | 限制 |
|---|---|---|
| 取指窗口 | PC 输出 14 bit，ROM 地址取 pc[13:2]，逻辑 PC 高位重构为 0x80000000 区域 | 可达指令窗口为 16 KiB；跳转高地址不能仅按完整 RV32 地址空间理解 |
| A IROM | 4096 words × 32 bit，输出 registered | ROM 自身形成取指末端寄存边界 |
| B IROM | 配置为 4096 words × 32 bit；实例输入由两个 0 加 12-bit inst_addr 组成 | 配置容量与可达窗口均为 16 KiB；输出 non_registered；仍应检查实例与 IP 地址端口宽度 |
| A 数据 RAM | 16384 words × 32 bit = 64 KiB | 桥声明的窗口更大，低位寻址存在别名风险 |
| B 数据 RAM | 65536 words × 32 bit = 256 KiB | 与桥名义 256 KiB 窗口相符，但边界比较另有细节 |
| 初始化 | A/B IP 引用工程内 irom.coe / dram.coe | 文件存在不证明固件覆盖所有指令或冒险 |

[E03、E04、E11、E12](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)。这里的 DRAM 是项目“数据 RAM”的命名，实际由 FPGA BRAM 构成，不应讲成已实现外部 DDR 控制器或数据 cache。

桥定义 RAM 起点 0x80100000，END 为 0x8013FFFF，但比较使用“小于 END”，而不是“小于等于 END”。对于字对齐访问和最高字节访问影响不同；应按实际访问地址与宽度讨论，不把这两个写法当作等价。

MMIO 地址分别为 SW0=0x80200000、SW1=0x80200004、KEY=0x80200010、SEG=0x80200020、LED=0x80200040、CNT=0x80200050。写地址与读地址独立；桥把读地址寄存一拍以选择返回值。每种外设是否允许读、返回什么，以 case 和输出选择器为准，不能假设所有可写地址都可读。[E11](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

## 4. 时钟和复位怎样传递

top 把 PLL clk_out1 用作 50 MHz，clk_out2 用作 CPU 时钟。PLL locked 高时，UART/twin_controller 的 rst_n 为高；student_top 收到反相 locked，再反相送 CPU 的 rst_n。[E02](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

这证明极性连接，不证明复位释放已在每个域中同步。counter、虚拟 IO、CPU 之间有跨频率连接。两时钟来自同一个 PLL，不能仅凭频率不同认定异步；历史报告也分析了两个域之间的时序。仍需检查关系约束、单拍控制能否被较慢域接收、总线是否一致，以及复位释放。counter 的 start 在组合过程中保持自身还构成锁存语义，见改进章。

## 5. 指令支持应怎样表述

A/B 活动译码和 cu 包含整数立即数／寄存器运算、LUI/AUIPC、六类条件分支、JAL/JALR、整数 load/store；mem 做字节／半字选取与符号或零扩展。这足以称为“以 RV32I 常用整数指令为主的教学／竞赛 CPU”。不能凭宏定义宣布完整 RV32IM、浮点、CSR、异常、中断或 ISA 合规。[E19](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

RISC-V 规范定义指令行为，不规定必须五级。完整合规还涉及非法编码、异常、对齐、FENCE、ECALL/EBREAK 等语义；本次不做逐条合规认证。[RV32I 规范](https://docs.riscv.org/reference/isa/v20240411/unpriv/rv32.html)

## 6. 模板和 CoreMark 支线放在什么位置

模板有效 XPR 收录 new/rtl_full2，cu 有 FP 运算及 FLW/FSW 分支，顶层有相关连接。它用于观察版本差异；仅存在浮点通路不等于实现完整 F 扩展，也不能证明这份名为模板的本地快照完全等于赛方最初发布物。[E20](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

CoreMark 支线顶层出现 MEM_BUFFER 和 AREA_PREDICTOR；ROM 仍有仓库外 final.hex 路径，仓库中未发现对应原始固件。不能用目录名推断“已经跑出 CoreMark 分数”。本版不继续推定该支线实际流水与时钟，避免只看到某个 PLL 参数就认定 CPU 运行频率。[E21](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

## 复试如何解释这层工程价值

可以说：“CPU 之外还需要存储、地址译码、时钟复位和外设连接，才能让程序驱动实际系统。研究时先确认工程真的编译了哪套源码，再解释它的体系结构。” 若被问为什么不能直接读目录里的 RISCV.v，举同名旧树和注释 IF2 的例子即可。
