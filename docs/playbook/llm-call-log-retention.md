# llm_call_log 30 天保留策略

## 生产位置

- 主机：`avatar-01`
- 目录：`/home/flow/docker-services/services-db-maintenance/`
- MySQL 私有配置：`mysql.cnf`，权限必须为 `0600`，不进入 Git
- 定时任务：`flow` 用户 crontab，北京时间每天 03:30

## 自动部署

- GitHub：`https://github.com/AmorErwanc/services-db-maintenance`
- `main` 不部署；推送 `deploy/prod` 自动同步到生产。
- GitHub Secrets：`AVATAR_HOST`、`AVATAR_PORT`、`AVATAR_USER`、`AVATAR_SSH_KEY`。
- 部署保留服务器私有 `mysql.cnf`，重新安装 crontab，并以 dry-run 验证数据库连通性和过期数量。

## 安全边界

- 默认 dry-run；只有 `--apply` 才删除。
- 固定每次运行的截止时间，不在循环过程中移动边界。
- 每批 10,000 行并自动提交，批次间暂停 0.2 秒。
- 单次最多 100 批；仍有剩余时退出码为 2，下一轮继续。
- 删除范围是共享表全部业务，不按 `service` 过滤，这是已确认的统一保留策略。
- 不执行 `OPTIMIZE TABLE`，避免在线重建 20 GiB 以上共享表。

## 操作

```bash
cd /home/flow/docker-services/services-db-maintenance

# 预览
./scripts/cleanup-llm-call-log.sh

# 正式执行
./scripts/cleanup-llm-call-log.sh --apply

# 查看定时执行日志
journalctl -t services-db-maintenance --since today
```

## 验收

1. 脚本输出 `remaining_expired_rows=0`。
2. 再次 dry-run 输出 `expired_rows=0`。
3. 检查 dream-avatar 与 mingle 健康接口。
4. 核对 crontab 中只有一条 `services-db-maintenance` 任务。
