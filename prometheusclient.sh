# 获取 Prometheus 最新版本
github_project="prometheus/node_exporter"
tag=$(wget -qO- -t1 -T2 "https://api.github.com/repos/${github_project}/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')

# 获取公网 IP
PUBLIC_IP=$(curl -s ipinfo.io/ip)

# 提示用户输入实例名称
echo "请输入此实例的显示名称:"
read INSTANCE_NAME

# 检测系统架构
ARCH=$(uname -m)
case $ARCH in
    aarch64|arm64)
        ARCH_SUFFIX="arm64"
        ;;
    armv7l|armv6l)
        ARCH_SUFFIX="armv7"
        ;;
    x86_64)
        ARCH_SUFFIX="amd64"
        ;;
    *)
        echo "不支持的架构: $ARCH"
        exit 1
        ;;
esac

wget https://github.com/prometheus/node_exporter/releases/download/${tag}/node_exporter-${tag#*v}.linux-${ARCH_SUFFIX}.tar.gz && \
tar xvfz node_exporter-*.tar.gz && \
rm node_exporter-*.tar.gz
sudo mv node_exporter-*.linux-${ARCH_SUFFIX}/node_exporter /usr/local/bin
rm -r node_exporter-*.linux-${ARCH_SUFFIX}*

sudo useradd -rs /bin/false node_exporter

sudo cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
sudo systemctl status node_exporter

echo "监控端安装完成。请在面板端执行以下命令："
echo "sudo sed -i '/job_name: \"node_exporter\"/,/static_configs:/!b;/static_configs:/a\\      - targets: [\"$PUBLIC_IP:9100\"]\n        labels:\n          instance: '\''$INSTANCE_NAME'\''' /etc/prometheus/prometheus.yml && sudo systemctl restart prometheus"
