#!/bin/bash

# Claude Code 一键安装脚本 for Linux
# 自动检测系统类型并安装 Claude Code，配置 API 密钥和端点

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 检查是否以 root 权限运行
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "检测到 root 权限，建议使用普通用户运行此脚本"
        read -p "是否继续? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        print_error "无法检测操作系统类型"
        exit 1
    fi
    print_message "检测到操作系统: $OS $VERSION"
}

# 检查网络连接
check_network() {
    print_message "检查网络连接..."
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "网络连接失败，请检查网络设置"
        exit 1
    fi
    print_success "网络连接正常"
}

# 安装 Node.js
install_nodejs() {
    print_message "检查 Node.js 安装状态..."
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_message "已安装 Node.js 版本: $NODE_VERSION"
        
        # 检查版本是否满足要求 (>= 18)
        NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
        if [[ $NODE_MAJOR -lt 18 ]]; then
            print_warning "Node.js 版本过低 (需要 >= 18)，正在更新..."
            install_nodejs_by_os
        else
            print_success "Node.js 版本满足要求"
        fi
    else
        print_message "未检测到 Node.js，正在安装..."
        install_nodejs_by_os
    fi
}

# 根据操作系统安装 Node.js
install_nodejs_by_os() {
    case $OS in
        ubuntu|debian)
            print_message "在 Ubuntu/Debian 上安装 Node.js..."
            sudo apt update
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        centos|rhel|rocky|almalinux)
            print_message "在 CentOS/RHEL 上安装 Node.js..."
            sudo yum install -y nodejs npm
            ;;
        fedora)
            print_message "在 Fedora 上安装 Node.js..."
            sudo dnf install -y nodejs npm
            ;;
        arch|manjaro)
            print_message "在 Arch Linux 上安装 Node.js..."
            sudo pacman -S --noconfirm nodejs npm
            ;;
        *)
            print_error "不支持的操作系统: $OS"
            print_message "请手动安装 Node.js 18+ 后重新运行此脚本"
            exit 1
            ;;
    esac
}

# 安装 Claude Code
install_claude_code() {
    print_message "安装 Claude Code..."
    
    if command -v claude &> /dev/null; then
        print_message "Claude Code 已安装，正在更新..."
    fi
    
    npm install -g @anthropic-ai/claude-code
    
    if command -v claude &> /dev/null; then
        CLAUDE_VERSION=$(claude --version)
        print_success "Claude Code 安装成功，版本: $CLAUDE_VERSION"
    else
        print_error "Claude Code 安装失败"
        exit 1
    fi
}

# 配置 API 密钥和端点
configure_api() {
    print_message "配置 API 密钥和端点..."
    
    # 获取用户输入的 API 密钥
    while true; do
        read -p "请输入您的 API 密钥 (从 https://instcopilot-api.com/console/token 获取): " API_KEY
        if [[ -n "$API_KEY" ]]; then
            break
        else
            print_error "API 密钥不能为空"
        fi
    done
    
    # 询问是否使用默认端点
    read -p "使用默认 API 端点 (https://instcopilot-api.com)? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        API_ENDPOINT="https://instcopilot-api.com"
    else
        read -p "请输入自定义 API 端点: " API_ENDPOINT
    fi
    
    # 检测 shell 类型
    SHELL_TYPE=$(basename $SHELL)
    case $SHELL_TYPE in
        bash)
            SHELL_RC="$HOME/.bashrc"
            ;;
        zsh)
            SHELL_RC="$HOME/.zshrc"
            ;;
        *)
            SHELL_RC="$HOME/.bashrc"
            print_warning "未识别的 shell: $SHELL_TYPE，使用默认配置文件: $SHELL_RC"
            ;;
    esac
    
    # 备份原配置文件
    if [[ -f $SHELL_RC ]]; then
        cp $SHELL_RC $SHELL_RC.backup.$(date +%Y%m%d_%H%M%S)
        print_message "已备份原配置文件: $SHELL_RC"
    fi
    
    # 删除旧的配置（如果存在）
    sed -i '/ANTHROPIC_AUTH_TOKEN/d' $SHELL_RC 2>/dev/null || true
    sed -i '/ANTHROPIC_BASE_URL/d' $SHELL_RC 2>/dev/null || true
    
    # 添加新配置
    echo "" >> $SHELL_RC
    echo "# Claude Code 配置" >> $SHELL_RC
    echo "export ANTHROPIC_AUTH_TOKEN=\"$API_KEY\"" >> $SHELL_RC
    echo "export ANTHROPIC_BASE_URL=\"$API_ENDPOINT\"" >> $SHELL_RC
    
    # 应用配置
    export ANTHROPIC_AUTH_TOKEN="$API_KEY"
    export ANTHROPIC_BASE_URL="$API_ENDPOINT"
    
    print_success "API 配置已保存到 $SHELL_RC"
}

# 验证安装
verify_installation() {
    print_message "验证安装..."
    
    # 检查 Claude Code 版本
    if claude --version &> /dev/null; then
        print_success "Claude Code 命令可用"
    else
        print_error "Claude Code 命令不可用"
        exit 1
    fi
    
    # 检查环境变量
    if [[ -n "$ANTHROPIC_AUTH_TOKEN" ]]; then
        print_success "API 密钥配置正确"
    else
        print_error "API 密钥配置失败"
        exit 1
    fi
    
    if [[ -n "$ANTHROPIC_BASE_URL" ]]; then
        print_success "API 端点配置正确"
    else
        print_error "API 端点配置失败"
        exit 1
    fi
}

# 显示使用指南
show_usage() {
    echo
    print_success "🎉 Claude Code 安装配置完成！"
    echo
    echo -e "${BLUE}使用指南:${NC}"
    echo "1. 重启终端或运行: source $SHELL_RC"
    echo "2. 进入项目目录: cd your-project-folder"
    echo "3. 启动 Claude Code: claude"
    echo
    echo -e "${BLUE}首次使用:${NC}"
    echo "• 选择喜欢的主题"
    echo "• 确认安全须知"
    echo "• 使用默认 Terminal 配置"
    echo "• 信任工作目录"
    echo "• 开始编程！🚀"
    echo
    echo -e "${BLUE}更多帮助:${NC}"
    echo "• Claude Code 文档: https://docs.anthropic.com/en/docs/claude-code"
    echo "• API 控制台: https://instcopilot-api.com/console"
    echo
}

# 主函数
main() {
    echo "================================================================"
    echo "              Claude Code Linux 一键安装脚本"
    echo "================================================================"
    echo
    
    check_root
    detect_os
    check_network
    install_nodejs
    install_claude_code
    configure_api
    verify_installation
    show_usage
    
    print_success "安装完成！请重启终端或运行 'source $SHELL_RC' 以生效配置"
}

# 运行主函数
main "$@"
