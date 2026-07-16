# 数据模型

本项目不拥有数据库或业务表，只维护公司共享生产库 `services`。

当前维护对象：

| 表 | 策略 | 边界 |
|---|---|---|
| `llm_call_log` | 原始调用记录保留 30 天 | 对表内所有 `service` 统一生效；按 `created_at` 与 `idx_created` 分批删除 |

共享表 schema 的唯一事实源为 `~/backend/conventions/shared-tables.md`；本项目不负责修改表结构。
