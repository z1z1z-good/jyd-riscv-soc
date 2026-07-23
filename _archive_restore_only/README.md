# 原版恢复区——禁止作为日常工程使用

这里保存 `z1z1z-good/jyd-riscv-soc` 在上游提交
`98f3aab600912aa1ac22ac52660e6c52ac5c7a12` 中的两份原始工程：

- `source-98f3aab/five_level_200MHz_with_all_branch`
- `source-98f3aab/five_level_area_250M`

## 隔离规则

1. 此目录只用于追溯、对比和恢复，不在这里继续开发。
2. 日常打开和综合的工程只允许使用仓库顶层同名目录。
3. 顶层有效工程的 XPR 不得引用 `_archive_restore_only` 中的任何文件。
4. 不直接修改快照内容；若需修复工程，在顶层有效工程中提交。
5. `SHA256SUMS-source-98f3aab.txt` 记录快照的逐文件哈希，检查脚本会验证归档完整性。

GitHub 通过本目录的 `.gitattributes` 将快照标为 generated，减少它进入代码统计和普通差异审查的机会。这不改变文件内容。

恢复时应先建立新分支，再从这里复制所需文件；不要直接把整个归档目录加入 Vivado 工程。
