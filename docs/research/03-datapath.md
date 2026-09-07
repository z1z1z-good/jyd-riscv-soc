# 03 · 五级与六级的真实数据通路

[阅读入口](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/README.md) · 下一章：[冒险](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/04-hazards.md)

延伸阅读：[完整程序的两版逐拍表](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/12-execution-walkthrough.md)将这些边界对应到同一批动态指令；[D01 架构决策](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/13-architecture-decisions.md#d01)比较增级的替代方案。

## 1. 结论及计数口径

A 是五级；B 是六级 IF / ID / EX / BUFFER / MEM / WB。这里按有效指令数据与控制的推进划分，WB 表示写回阶段，实际 GPR 写入发生在该阶段结束的边沿。模块名、时钟端口、备用寄存器都不能单独作为计数依据。[E03—E10](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

~~~mermaid
flowchart LR
  subgraph A["A 五级"]
    A0["PC → 同步 ROM"] --> A1["ROM 输出寄存 / PC 对齐"]
    A1 --> A2["ID 译码和前递读口"]
    A2 --> A3["id_ex"]
    A3 --> A4["EX → EX 输出寄存"]
    A4 --> A5["MEM → MEM 输出寄存"]
    A5 --> A6["WB 组合 → GPR 写入"]
  end
  subgraph B["B 六级"]
    B0["PC → 异步 ROM"] --> B1["if_id 寄存指令和 PC"]
    B1 --> B2["ID 译码和前递读口"]
    B2 --> B3["id_ex"]
    B3 --> B4["EX → EX 输出寄存"]
    B4 --> B5["BUFFER → MEM_BUFFER 输出寄存"]
    B5 --> B6["MEM → MEM 输出寄存"]
    B6 --> B7["WB 组合 → GPR 写入"]
  end
~~~

图中箭头不是“一条箭头一拍”；标有寄存的节点才表示状态边界。访存读返回还有并行的数据延迟线，需要与控制路径对齐，不能再机械加成第七级。

## 2. A：ROM 已经替 if_id 保存了指令

A 的 IROM output_options=registered；if_id 只在时钟沿保存 PC 和中断字段，指令在组合块中根据延迟后的 hold 选择 NOP 或 ROM 输出。它并不是“同步 ROM 之后又有完整一拍 IF/ID 指令寄存器”。

RISCV.v 的 IF2_UNIT 是整块注释，ID_UNIT 实际接 if_ins_o。把这段注释计入流水会凭空增加一级。[E03](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

## 3. B：if_id 是第一道取指寄存边界

B 的 IROM output_options=non_registered、Pipeline_Stages=0、C_HAS_CLK=0；student_top 实例也没有给它接时钟。if_id 在边沿同时寄存指令和 PC，因此它承担的就是取指后的第一道边界。

旧“七级”解释同时计算了不存在的 ROM 输出寄存级与真实 if_id，导致多算一级。判断方法必须把 IP 与 RTL 合起来。[E04](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

## 4. MEM_BUFFER 究竟保存什么

| 内容 | 为什么必须随指令延迟 |
|---|---|
| reg_wr_en / rd / reg_wr_data | 非访存指令也必须按顺序带着写回信息走 |
| reg2_rd_data | store 要保存本条指令的写数据 |
| mem_rd_addr | 地址必须与相同指令的控制对齐 |
| is_load / is_save / funct3 | 决定读写、访问宽度和扩展方式 |

MEM_BUFFER 不接主存返回值；读返回值在 MEM_UNIT 内的 mem_wr_buffer.rd_data_o 寄存。MEM_BUFFER 的三个 _hypass 端口只是输入的组合镜像，当前顶层未连接。有效 BUFFER 前递由顶层直接用 EX 输出值完成。[E08、E09、E10](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

B 另有容易误判的连线：MEM_UNIT 输入接较早的 mem_rd_addr_to_mem，而不是 mem_rd_addr_buffer_mem；但 MEM_UNIT 内部又通过 mem_rd_addr_reg 寄存一拍，才送到 mem 做低位选择与写地址。**不能只凭顶层看起来绕过 BUFFER 就认定地址错拍。** 应比较内部寄存后的地址与 MEM_BUFFER 控制处于同一时刻。[E09](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

## 5. 指令沿边界推进：静态模型

下面使用已稳定复位、无控制重定向、操作数已就绪的前提。Ck 表示两个上升沿之间的一段周期；每格末端采样进入下一格。没有仿真，不表示已验证全部功能。

| 指令 / 版本 | C1 | C2 | C3 | C4 | C5 | C6 |
|---|---|---|---|---|---|---|
| add / A | IF | ID | EX 算结果 | MEM 通过 | WB | — |
| add / B | IF | ID | EX 算结果 | BUFFER | MEM 通过 | WB |
| lw / A | IF | ID | EX 发读地址 | MEM 取读返回并扩展 | WB | — |
| lw / B | IF | ID | EX 发读地址 | BUFFER；返回数据到寄存点 | MEM 取寄存返回并扩展 | WB |
| sw / A | IF | ID 取源操作数 | EX 算地址 | MEM 生成写请求 | 写缓存输出／RAM 接收时机另查 | — |
| sw / B | IF | ID 取源操作数 | EX 算地址 | BUFFER | MEM 生成写请求 | 写缓存输出／RAM 接收时机另查 |

store 不写 GPR，且写请求有缓存寄存和 RAM 采样过程。因此“store 到 WB”与“RAM 已可被后续读取”不能混为一件事。访存返回也依赖 BRAM 同步读和桥读地址寄存共同对齐。[第 06 章](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/06-timing.md)

## 6. 多一级为什么影响旁路，却不必增加分支冲刷级数

B 的 BUFFER 插在 EX 后面。消费者在 ID 读口可能同时看到 EX、BUFFER、MEM、WB 四个不同年龄的生产者，所以新增一个来源与优先级检查。

分支条件仍在 EX 的 cu 组合逻辑里确定；EX 前仍只有 IF、ID 两个年轻位置。因此前端结构上被冲刷的位置数量没有因为 EX 后的 BUFFER 增加。B 把 is_branch、actual_taken、actual_target、PC 寄存后送预测器训练，这是**训练延迟**；jump 仍由 EX 组合结果驱动前端，不应把训练延迟误当成分支解析又晚了一拍。[E07、E13](D:/codex_prj/fpga_dick/jyd-riscv-soc/docs/research/09-evidence.md)

“结构上冲刷两个年轻位置”与“任何程序精确损失两拍”不是同一句话。相邻分支、load 重取、预测历史对齐和复位会改变具体情形，需未来定向验证。

## 复试追问

若问“为什么深流水后 FF 反而少了”，回答：B 同时简化预测器并改变存储配置；总体资源是多个变化叠加的结果。新增一级会增加局部寄存需求，但不能由此推导整个 top 的 FF 必然更多，更不能由两份总数定量分摊每项优化收益。
