#!/bin/bash

# VPS 管理工具
# 按功能分类管理并执行所有常用脚本

# 主菜单选项
declare -A categories=(
    [1]="性能测试"
    [2]="带宽与网络测试"
    [3]="运维工具"
    [4]="科学工具"
    [5]="DD重装脚本"
    [6]="中转工具"
    [7]="带宽与硬盘测试"
    [8]="IP与路由测试"
    [9]="延迟测试"
    [10]="运维工具包"
    [11]="网络优化"
    [12]="系统优化与安全"
    [13]="常用推荐"
)

# 定义每个分类下的脚本选项和描述
declare -A scripts_per_category=(
    [1_1]="Nlbench.sh - 主机聚合测评脚本"
    [1_2]="融合怪 - VPS 综合测试"
    [1_3]="融合怪 GO 版本 - VPS 综合测试（GO 重构）"
    [1_4]="LemonBench - 检查VPS基本信息"
    [1_5]="UnixBench.sh - 系统基准性能测试"
    [1_6]="YABS - 多项性能测试脚本"
    [1_7]="Geekbench 5 专测脚本"

    [2_1]="Hyperspeed 三网测速"
    [2_2]="综合测速脚本 nws.sh"
    [2_3]="多功能自更新测速脚本"

    [3_1]="vps_scripts - 运维工具包"
    [3_2]="科技 lion 一键脚本工具"
    [3_3]="VPS 一键脚本工具箱"
    [3_4]="BlueSkyXN 综合工具箱"
    [3_5]="jcnf 常用脚本工具包"
    [3_6]="Sm1rkBoy’s 一键脚本"
    [3_7]="轻量VPS测试集合"
    [3_8]="one-click-installation-script 一键修复与安装脚本"
    [3_9]="VPS ToolBox"
    [3_10]="一键删除平台监控"
    [3_11]="PagerMaid-Pyro机器人 Docker安装 TG自走机器人"

    [4_1]="Sing-box 全家桶"
    [4_2]="勇哥 Sing-box"
    [4_3]="Mack-a 8合1"
    [4_4]="新版 X-UI"
    [4_5]="3X-UI"
    [4_6]="勇哥 x-ui"
    [4_7]="Alist 一键安装"
    [4_8]="Xiao Alist 一键安装"
    [4_9]="一键安装filebrowser平台"

    [5_1]="leitbogioro大佬的DD重装脚本（Debian 12）"
    [5_2]="beta.gs 大佬的DD重装脚本"
    [5_3]="Nekoneko - DD一键脚本"

    [6_1]="Realm 转发"
    [6_2]="Nekoneko - 一键Brook转发"
    [6_3]="Nekoneko - Gost一键脚本"
    [6_4]="Nekoneko - Ehco一键脚本"

    [7_1]="Bench.sh - 网络带宽及硬盘读写速率测试"
    [7_2]="SuperBench.sh - 综合带宽与硬盘速率测试"
    [7_3]="dd 磁盘测试 - 生成5G文件（顺序）"
    [7_4]="dd 磁盘测试 - 生成5G文件（随机）"
    [7_5]="Linux-NetSpeed（锐速/bbrplus/bbr 魔改版）"
    [7_6]="ylx 大佬的锐速/BBRPLUS/BBR2"

    [8_1]="AutoTrace 回程路由"
    [8_2]="BestTrace 回程路由"
    [8_3]="BackTrace 回程路由"
    [8_4]="NextTrace 回程路由"
    [8_5]="OpenTrace 回程路由"
    [8_6]="Pingsx MTR 回程路由"
    [8_7]="去程路由"

    [9_1]="Google/Facebook/X/Youtube/Netflix/Chatgpt/Github延迟测试"
    [9_2]="Ping.pe 全球延迟，丢包测试"
    [9_3]="Pingsx Ping 在线Ping，Port，DNS，MTR等测试"
    [9_4]="Itdog Ping 测试"
    [9_5]="测试 IPv4 / IPv6 优先"

    [10_1]="fail2ban 服务器 ssh 防爆破"
    [10_2]="spiritlhl 大佬的 zram 内存压缩脚本"
    [10_3]="moerats 大佬的添加 swap 脚本"

    [11_1]="BBR 脚本"
    [11_2]="Linux-NetSpeed（锐速/bbrplus/bbr 魔改版）"
    [11_3]="ylx 大佬的锐速/BBRPLUS/BBR2"
    [11_4]="Nekoneko - BBR一键安装"

    [12_1]="超售测试脚本"
    [12_2]="移除virtio_balloon模块"
    [12_3]="内存填充测试"
    [12_4]="独服硬盘测试"
    [12_5]="25端口测试"

    [13_1]="哪吒探针 安装"
    [13_2]="常用推荐"
)

# 定义每个分类下脚本的执行命令
declare -A commands_per_category=(
    [1_1]="wget -O Nlbench.sh https://raw.githubusercontent.com/everett7623/nodeloc_vps_test/main/Nlbench.sh && chmod +x Nlbench.sh && ./Nlbench.sh"
    [1_2]="curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh"
    [1_3]="curl -L https://raw.githubusercontent.com/oneclickvirt/ecs/master/goecs.sh -o goecs.sh && chmod +x goecs.sh && bash goecs.sh env && bash goecs.sh install && goecs"
    [1_4]="wget -qO- https://raw.githubusercontent.com/LemonBench/LemonBench/main/LemonBench.sh | bash -s -- --fast"
    [1_5]="wget --no-check-certificate https://github.com/teddysun/across/raw/master/unixbench.sh && chmod +x unixbench.sh && ./unixbench.sh"
    [1_6]="curl -sL yabs.sh | bash"
    [1_7]="bash <(curl -sL gb5.top)"

    [2_1]="bash <(curl -Lso- https://bench.im/hyperspeed)"
    [2_2]="curl -sL nws.sh | bash"
    [2_3]="bash <(curl -sL bash.icu/speedtest)"

    [3_1]="wget -O vps_scripts.sh https://raw.githubusercontent.com/everett7623/vps_scripts/main/vps_scripts.sh && chmod +x vps_scripts.sh && ./vps_scripts.sh"
    [3_2]="curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh"
    [3_3]="curl -fsSL https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh -o ssh_tool.sh && chmod +x ssh_tool.sh && ./ssh_tool.sh"
    [3_4]="wget -O box.sh https://raw.githubusercontent.com/BlueSkyXN/SKY-BOX/main/box.sh && chmod +x box.sh && clear && ./box.sh"
    [3_5]="wget -O jcnfbox.sh https://raw.githubusercontent.com/Netflixxp/jcnf-box/main/jcnfbox.sh && chmod +x jcnfbox.sh && clear && ./jcnfbox.sh"
    [3_6]="bash <(curl -Ls https://raw.githubusercontent.com/Sm1rkBoy/monitor_config/main/install.sh)"
    [3_7]="bash <(curl -Ls resource.yserver.ink/all.sh) --custom"
    [3_8]="bash <(wget -qO- 'https://github.com/spiritLHLS/one-click-installation-script/raw/main/install_scripts/install.sh')"
    [3_9]="bash <(curl -Lso- https://sh.vps.dance/toolbox.sh)"
    [3_10]="curl -L https://raw.githubusercontent.com/spiritLHLS/one-click-installation-script/main/install_scripts/dlm.sh -o dlm.sh && chmod +x dlm.sh && bash dlm.sh"
    [3_11]="wget https://raw.githubusercontent.com/TeamPGM/PagerMaid-Pyro/development/utils/docker.sh -O docker.sh && chmod +x docker.sh && bash docker.sh"

    [4_1]="bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh)"
    [4_2]="bash <(curl -Ls https://gitlab.com/rwkgyg/sing-box-yg/raw/main/sb.sh)"
    [4_3]="wget -P /root -N --no-check-certificate \"https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh\" && chmod 700 /root/install.sh && /root/install.sh"
    [4_4]="bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh) || bash <(wget -qO- https://raw.githubusercontent.com/sing-web/x-ui/main/install_CN.sh)"
    [4_5]="bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)"
    [4_6]="bash <(curl -Ls https://gitlab.com/rwkgyg/x-ui-yg/raw/main/install.sh)"
    [4_7]="curl -fsSL \"https://alist.nn.ci/v3.sh\" | bash -s install"
    [4_8]="bash -c \"$(curl --insecure -fsSL https://ddsrem.com/xiaoya_install.sh)\""
    [4_9]="curl -L https://raw.githubusercontent.com/spiritLHLS/one-click-installation-script/main/install_scripts/filebrowser.sh -o filebrowser.sh && chmod +x filebrowser.sh && bash filebrowser.sh"

    [5_1]="wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh && bash InstallNET.sh -debian 12 -pwd '密码'"
    [5_2]="bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -d 12 -v 64 -p 密码 -port 端口 -a -firmware"
    [5_3]="wget --no-check-certificate -O NewReinstall.sh https://raw.githubusercontent.com/fcurrk/reinstall/master/NewReinstall.sh && chmod +x NewReinstall.sh && bash NewReinstall.sh"

    [6_1]="wget https://raw.githubusercontent.com/Jaydooooooo/Port-forwarding/main/RealmOneKey.sh && chmod +x RealmOneKey.sh && ./RealmOneKey.sh"
    [6_2]="bash <(curl -Lso- http://sh.nekoneko.cloud/brook-pf/brook-pf.sh)"
    [6_3]="bash <(curl -Lso- http://sh.nekoneko.cloud/EasyGost/gost.sh)"
    [6_4]="bash <(curl -Lso- http://sh.nekoneko.cloud/ehco.sh/ehco.sh)"

    [7_1]="wget -qO- bench.sh | bash"
    [7_2]="wget -qO- --no-check-certificate https://raw.githubusercontent.com/oooldking/script/master/superbench.sh | bash"
    [7_3]="dd if=/dev/zero of=5gb bs=1M count=5120"
    [7_4]="dd if=/dev/urandom of=5gb bs=1M count=5120"
    [7_5]="wget -N --no-check-certificate \"https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh\" && chmod +x tcp.sh && ./tcp.sh"
    [7_6]="wget -O tcpx.sh \"https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh\" && chmod +x tcpx.sh && ./tcpx.sh"

    [8_1]="wget -N --no-check-certificate https://raw.githubusercontent.com/Chennhaoo/Shell_Bash/master/AutoTrace.sh && chmod +x AutoTrace.sh && bash AutoTrace.sh"
    [8_2]="wget -qO- git.io/besttrace | bash"
    [8_3]="curl https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh -sSf | sh"
    [8_4]="curl nxtrace.org/nt | bash"
    [8_5]="bash <(curl -fsSL git.io/warp.sh) menu"
    [8_6]="echo '访问 https://ping.sx/mtr 进行回程路由测试'"
    [8_7]="echo '请选择去程路由测试 URL:' && echo '1) https://www.itdog.cn/traceroute/' && echo '2) https://tools.ipip.net/traceroute.php' && read route_choice && case \$route_choice in 1) curl https://www.itdog.cn/traceroute/ ;; 2) curl https://tools.ipip.net/traceroute.php ;; *) echo \"无效的选择。\" ;; esac"

    [9_1]="bash <(curl -sL https://nodebench.mereith.com/scripts/curltime.sh)"
    [9_2]="echo '请访问 https://ping.pe 进行全球延迟，丢包测试'"
    [9_3]="echo '请访问 https://ping.sx 进行在线Ping，Port，DNS，MTR等测试'"
    [9_4]="echo '请访问 https://www.itdog.cn/ping/ 进行Itdog Ping 测试'"
    [9_5]="curl ip.p3terx.com"

    [10_1]="wget https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/fail2ban.sh && bash fail2ban.sh 2>&1 | tee fail2ban.log"
    [10_2]="curl -L https://raw.githubusercontent.com/spiritLHLS/addzram/main/addzram.sh -o addzram.sh && chmod +x addzram.sh && bash addzram.sh"
    [10_3]="wget https://www.moerats.com/usr/shell/swap.sh && bash swap.sh"

    [11_1]="echo '正在安装 BBR...' && echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf && echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf && sysctl -p && sysctl net.ipv4.tcp_available_congestion_control && lsmod | grep bbr"
    [11_2]="wget -N --no-check-certificate \"https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh\" && chmod +x tcp.sh && ./tcp.sh"
    [11_3]="wget -O tcpx.sh \"https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh\" && chmod +x tcpx.sh && ./tcpx.sh"
    [11_4]="bash <(curl -Lso- http://sh.nekoneko.cloud/bbr/bbr.sh)"

    [12_1]="wget --no-check-certificate -O memoryCheck.sh https://raw.githubusercontent.com/uselibrary/memoryCheck/main/memoryCheck.sh && chmod +x memoryCheck.sh && bash memoryCheck.sh"
    [12_2]="rmmod virtio_balloon"
    [12_3]="apt-get update && apt-get install wget build-essential -y && wget https://raw.githubusercontent.com/FunctionClub/Memtester/master/memtester.cpp && gcc -l stdc++ memtester.cpp && ./a.out"
    [12_4]="wget -q https://github.com/Aniverse/A/raw/i/a && bash a"
    [12_5]="telnet smtp.aol.com 25"

    [13_1]="curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh"
    [13_2]="echo '常用推荐脚本，请手动选择相应脚本执行。'"
)

# 显示主菜单函数
show_main_menu() {
    echo "==============================="
    echo "        VPS 管理工具菜单         "
    echo "==============================="
    for key in "${!categories[@]}"; do
        echo "$key) ${categories[$key]}"
    done
    echo "q) 退出"
    echo "==============================="
}

# 显示子菜单函数
show_sub_menu() {
    local category=$1
    echo "==============================="
    echo "     ${categories[$category]} 脚本列表     "
    echo "==============================="
    for key in "${!scripts_per_category[@]}"; do
        if [[ $key == ${category}_* ]]; then
            sub_key=$(echo $key | cut -d'_' -f2)
            echo "$sub_key) ${scripts_per_category[$key]}"
        fi
    done
    echo "0) 返回主菜单"
    echo "==============================="
}

# 执行选定脚本函数
execute_script() {
    local category=$1
    local choice=$2
    if [[ $choice == "0" ]]; then
        return
    fi
    local script_key="${category}_$choice"
    local command=${commands_per_category[$script_key]}
    if [[ -n $command ]]; then
        echo "正在执行: ${scripts_per_category[$script_key]}"
        eval $command
    else
        echo "无效的选项，请重新选择。"
    fi
}

# 主循环
while true; do
    show_main_menu
    read -p "请输入分类选项 (数字或 'q' 退出): " main_choice
    if [[ $main_choice == "q" || $main_choice == "Q" ]]; then
        echo "退出脚本。"
        exit 0
    elif [[ -n "${categories[$main_choice]}" ]]; then
        while true; do
            show_sub_menu $main_choice
            read -p "请输入脚本选项 (数字或 '0' 返回主菜单): " sub_choice
            if [[ $sub_choice == "0" ]]; then
                clear
                break
            elif [[ $sub_choice =~ ^[0-9]+$ ]]; then
                execute_script $main_choice $sub_choice
                echo ""
                read -p "按 Enter 键返回菜单..."
                clear
            else
                echo "无效的输入，请重新选择。"
            fi
        done
    else
        echo "无效的输入，请重新选择。"
    fi
    clear
done