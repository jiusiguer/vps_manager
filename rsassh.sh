#!/bin/bash

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 创建.ssh目录
echo "正在创建并配置.ssh目录..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 获取公钥
read -p "请输入您的SSH公钥: " pubkey
echo "$pubkey" > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 询问是否允许密码认证
read -p "是否允许密码认证? (y/n): " allow_password
if [ "$allow_password" = "y" ]; then
    password_auth="yes"
else
    password_auth="no"
fi

# 配置sshd_config
echo "正在配置SSH..."
cat > /etc/ssh/sshd_config.d/custom.conf << EOF
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication $password_auth
EOF

# 重启SSH服务
echo "正在重启SSH服务..."
systemctl restart sshd

# 检查SSH服务状态
if systemctl is-active --quiet sshd; then
    echo "SSH服务已成功重启"
    echo "配置完成！请保持当前会话，新开一个终端测试SSH连接是否正常"
else
    echo "警告：SSH服务可能未正常启动，请检查配置"
fi
