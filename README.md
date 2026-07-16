# services-db-maintenance

公司共享 `services` MySQL 数据库的轻量维护脚本项目。

当前能力：

- `llm_call_log` 原始调用日志只保留最近 30 天。
- 默认 dry-run；显式传入 `--apply` 才执行删除。
- 每批删除 10,000 行，批次间暂停 0.2 秒，单次最多 100 批。
- 生产由 `avatar-01` 宿主机每天 03:30 定时执行，不运行常驻服务或容器。

公开仓库：`https://github.com/AmorErwanc/services-db-maintenance`

- `main`：源码主分支，不触发部署。
- `deploy/prod`：唯一部署分支，推送后由 GitHub Actions 自动部署生产。

## 使用

```bash
# 只读预览
MYSQL_DEFAULTS_FILE=./mysql.cnf ./scripts/cleanup-llm-call-log.sh

# 执行删除
MYSQL_DEFAULTS_FILE=./mysql.cnf ./scripts/cleanup-llm-call-log.sh --apply
```

生产配置与定时任务见 [`docs/playbook/llm-call-log-retention.md`](docs/playbook/llm-call-log-retention.md)。
