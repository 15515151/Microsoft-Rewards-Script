#!/bin/bash
# 该脚本用于初始化容器环境、启动 cron 服务并整合日志输出

# 立即退出（如果命令以非零状态退出）
set -e

# 如果定义了 TZ 环境变量，则设置时区
if [ -n "$TZ" ]; then
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone
    echo "容器时区已设置为: $TZ"
fi

# 准备日志文件并设置权限
touch /var/log/cron.log
chmod 0644 /var/log/cron.log

# 导出环境变量供 cron 使用 (关键修复)
printenv | grep -E "^(PLAYWRIGHT_BROWSERS_PATH|AUTO_INSTALL_BROWSERS|TZ|NODE_ENV)" >> /etc/environment

# 加载 cron 任务
echo "加载 cron 任务..."
crontab /usr/src/microsoft-rewards-script/crontab.txt
echo "cron 任务已加载。"

# 在后台启动 cron 服务
echo "启动 cron 服务 (后台)..."
cron

# 立即执行一次任务，并将输出重定向到日志文件
echo "启动时执行一次初始任务 (日志将在下方显示)..."
node /usr/src/microsoft-rewards-script/dist/index.js >> /var/log/cron.log 2>&1 &

# 使用 tail -F 将日志文件内容实时输出到 stdout
# 这会使容器保持运行，并且 docker logs 可以捕获到所有应用日志
echo "---- 日志开始 ----"
tail -F /var/log/cron.log
