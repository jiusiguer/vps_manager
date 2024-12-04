# 获取 Prometheus 最新版本
github_project="prometheus/node_exporter"
tag=$(wget -qO- -t1 -T2 "https://api.github.com/repos/${github_project}/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
echo ${tag}
echo ${tag#*v}

# 检测系统架构并选择正确的二进制文件
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

# 后续步骤保持不变
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
