# services-db-maintenance

公司共享 `services` MySQL 数据库的轻量维护脚本项目。

## 遵循的规范

本项目遵循 `~/backend/conventions/` 全部规范。以下仅记录**与基线不同的特例**。

## 项目特例

- 脚本型运维项目：不提供 HTTP API，不运行常驻服务，不需要 Fastify、Prisma、Docker、健康检查或业务表。
- 部署形态：脚本复制到 `avatar-01` 宿主机，由 `flow` 用户 crontab 单实例执行。
- 数据范围：维护跨服务共享表；任何删除策略必须先确认对所有业务统一生效。

## Git 提交规范（必读）

见 `docs/commit-convention.md`

## docs 更新规范（必读）

改代码时必须同步 docs，清单见 `~/backend/conventions/docs-layout.md` 同步矩阵。

## 业务上下文（context-agent 接线）

- **开工先读**：`~/program/context-agent/knowledge/projects/共享数据库维护/dev-brief.md`——业务需求、技术拍板与硬约束的开发简报（权威源）。简报尚未生成或背景不足 → 读同目录 `README.md` 档案正本。
- **只读**：简报与档案由 context-agent 后台维护，本仓库会话不直接改。
- **回流**：开发中发现"需求做完了 / 接口改了 / 冒出新需求 / 档案与实际不符"→ 投一个 md 到 `~/program/context-agent/inbox/`（文件名带日期与项目名），晚间管线自动消化；Claude Code 会话可直接说"记一下"走 context-write skill。
