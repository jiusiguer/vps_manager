#!/bin/bash

# 卸载 Nezha Agent 脚本

# 停止服务
echo "正在停止 nezha-agent.service 服务..."
sudo systemctl stop nezha-agent.service

# 禁用服务
echo "正在禁用 nezha-agent.service 服务..."
sudo systemctl disable nezha-agent.service

# 删除服务文件
echo "正在删除服务文件 /etc/systemd/system/nezha-agent.service..."
sudo rm /etc/systemd/system/nezha-agent.service

# 重新加载 systemd 守护进程
echo "正在重新加载 systemd 守护进程..."
sudo systemctl daemon-reload

# 删除相关文件夹
echo "正在删除 /opt/nezha 目录及其内容..."
sudo rm -rf /opt/nezha

# 验证服务是否已删除
echo "正在验证 nezha-agent.service 是否已成功删除..."
if systemctl list-units --type=service | grep -q nezha-agent.service; then
    echo "警告: nezha-agent.service 服务仍然存在。卸载可能未完全成功。"
else
    echo "成功: nezha-agent.service 服务已成功卸载。"
fi

echo "卸载过程完成。"
