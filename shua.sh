#!/bin/bash

# 交互式配置函数
configure() {
    echo "=== 流量消耗配置 ==="
    echo "请输入参数 (直接回车使用默认值)"
    
    # 运行时间配置
    read -p "运行时间(小时) [默认: 24]: " input_duration
    DURATION=${input_duration:-24}
    
    # 并发数配置
    read -p "并发数 [默认: 3]: " input_concurrent
    CONCURRENT=${input_concurrent:-3}
    
    # 最大流量配置
    read -p "最大流量限制(GB) [默认: 500]: " input_traffic
    MAX_TRAFFIC=${input_traffic:-500}
    
    # 每次下载大小配置
    read -p "每次下载大小(MB) [默认: 50]: " input_size
    SIZE=$((${input_size:-50} * 1024 * 1024)) # 转换为bytes

    # 显示配置确认
    echo ""
    echo "=== 配置确认 ==="
    echo "运行时间: $DURATION 小时"
    echo "并发数: $CONCURRENT"
    echo "最大流量: $MAX_TRAFFIC GB"
    echo "下载大小: $((SIZE/1024/1024)) MB"
    echo ""
    
    # 确认是否继续
    read -p "确认开始运行? (y/n) [默认: y]: " confirm
    if [[ ${confirm:-y} != [yY] ]]; then
        echo "已取消运行"
        exit 0
    fi
}

# URL设置
URL="http://speed.cloudflare.com/__down?bytes="

# 初始化配置
configure

# 初始化计数器
total_gb=0
declare -A thread_bytes
for i in $(seq 1 $CONCURRENT); do
    thread_bytes[$i]=0
done

# 转换GB到bytes
MAX_BYTES=$((MAX_TRAFFIC * 1024 * 1024 * 1024))

# 创建临时文件用于线程间通信
TEMP_FILE=$(mktemp)
echo "0" > "$TEMP_FILE"

# 清理函数
cleanup() {
    rm -f "$TEMP_FILE"
    echo -e "\n程序终止，总计消耗流量: ${total_gb:.2f} GB"
    exit
}
trap cleanup SIGINT SIGTERM

# 格式化大小显示
format_size() {
    local bytes=$1
    if [ $bytes -gt 1073741824 ]; then
        echo "$(echo "scale=2; $bytes/1024/1024/1024" | bc) GB"
    else
        echo "$(echo "scale=2; $bytes/1024/1024" | bc) MB"
    fi
}

# 格式化速率显示
format_speed() {
    local bytes=$1
    if [ $bytes -gt 1048576 ]; then
        echo "$(echo "scale=2; $bytes/1024/1024" | bc) MB/s"
    else
        echo "$(echo "scale=2; $bytes/1024" | bc) KB/s"
    fi
}

# 下载函数
download() {
    local thread_id=$1
    local count=0
    local start_time
    local end_time
    
    while true; do
        # 检查是否达到最大流量限制
        current_total=$(cat "$TEMP_FILE")
        if [ $current_total -ge $MAX_BYTES ]; then
            break
        fi

        # 检查是否达到时间限制
        if [ $(date +%s) -ge $END_TIME ]; then
            break
        fi

        start_time=$(date +%s.%N)
        curl -s -L -o /dev/null "${URL}${SIZE}" >/dev/null 2>&1
        end_time=$(date +%s.%N)
        
        # 更新计数器
        thread_bytes[$thread_id]=$((thread_bytes[$thread_id] + SIZE))
        echo "$(($(cat "$TEMP_FILE") + SIZE))" > "$TEMP_FILE"
        
        # 计算这次下载的速率
        duration=$(echo "$end_time - $start_time" | bc)
        speed=$(echo "scale=2; $SIZE/$duration" | bc)
        
        sleep 0.5
    done
}

# 显示实时状态的函数
show_status() {
    local start_bytes
    local current_bytes
    local duration
    
    while true; do
        start_bytes=$(cat "$TEMP_FILE")
        sleep 1
        current_bytes=$(cat "$TEMP_FILE")
        
        # 计算速率
        bytes_per_second=$((current_bytes - start_bytes))
        total_gb=$(echo "scale=2; $current_bytes/1024/1024/1024" | bc)
        
        # 清除当前行并显示状态
        echo -ne "\r\033[K"
        echo -ne "已消耗流量: ${total_gb} GB "
        echo -ne "当前速率: $(format_speed $bytes_per_second) "
        echo -ne "进度: ${total_gb}/${MAX_TRAFFIC} GB"
        
        # 检查是否达到限制
        if [ ${current_bytes%.*} -ge $MAX_BYTES ]; then
            echo -e "\n达到流量限制，程序结束"
            kill -SIGTERM $$
            break
        fi
    done
}

# 主程序
echo "开始流量消耗..."
echo "开始时间: $(date)"
echo "=================="

# 设置结束时间
END_TIME=$(($(date +%s) + DURATION * 3600))

# 启动状态显示
show_status &

# 启动下载线程
for i in $(seq 1 $CONCURRENT); do
    download $i &
done

# 等待所有进程完成
wait

cleanup
