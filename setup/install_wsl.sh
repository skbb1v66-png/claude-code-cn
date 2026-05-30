#!/bin/bash
# =============================================================================
# Claude Code 中国安装脚本 (WSL / Linux)
# =============================================================================
# 功能：在中国大陆网络环境下自动安装 Claude Code CLI
# 适用系统：Ubuntu 20.04+, Debian 11+, WSL 2
# 用法：
#   chmod +x install_wsl.sh
#   ./install_wsl.sh
# =============================================================================

set -e

# ---------- 颜色定义 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} $1"; }
step()  { echo -e "\n${CYAN}🔧 [$(date '+%H:%M:%S')]${NC} $1"; }
ok()    { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }

# ---------- Banner ----------
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║     Claude Code 中国安装脚本 v1.0               ║"
echo "║     适用于 WSL2 / Ubuntu / Debian               ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ---------- 网络检测 ----------
step "检测网络连接..."

PROXY=""

# 检测环境变量代理
for var in HTTP_PROXY HTTPS_PROXY http_proxy https_proxy; do
    if [ -n "${!var}" ]; then
        warn "检测到代理: $var = ${!var}"
        PROXY="${!var}"
        break
    fi
done

# 检测 WSL 宿主机代理（Windows 宿主机的常见端口）
if [ -z "$PROXY" ] && grep -qi microsoft /proc/version 2>/dev/null; then
    HOST_IP=$(ip route | grep default | awk '{print $3}' 2>/dev/null)
    if [ -n "$HOST_IP" ]; then
        for port in 7890 7891 10809 1080; do
            if timeout 1 bash -c "echo > /dev/tcp/$HOST_IP/$port" 2>/dev/null; then
                warn "检测到宿主机代理: http://$HOST_IP:$port"
                PROXY="http://$HOST_IP:$port"
                break
            fi
        done
    fi
fi

# 测试直连
if timeout 3 curl -s https://registry.npmjs.org/ > /dev/null 2>&1; then
    ok "直连 registry.npmjs.org 成功"
else
    warn "直连 registry.npmjs.org 失败"
    if [ -n "$PROXY" ]; then
        export HTTP_PROXY="$PROXY"
        export HTTPS_PROXY="$PROXY"
        ok "已设置代理: $PROXY"
    else
        warn "未检测到可用代理，后续安装可能失败"
        read -p "是否继续? [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            exit 1
        fi
    fi
fi

# ---------- 系统依赖检测 ----------
step "检测系统依赖..."

# 检测包管理器
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
else
    err "未检测到支持的包管理器 (apt/yum/dnf)"
    exit 1
fi
ok "包管理器: $PKG_MANAGER"

# 检测并安装基础依赖
install_system_deps() {
    local deps=("curl" "wget" "git" "build-essential")

    if [ "$PKG_MANAGER" = "apt" ]; then
        local to_install=()
        for pkg in "${deps[@]}"; do
            if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
                to_install+=("$pkg")
            fi
        done
        if [ ${#to_install[@]} -gt 0 ]; then
            info "安装系统依赖: ${to_install[*]}"
            sudo apt update -qq && sudo apt install -y -qq "${to_install[@]}"
        fi
    elif [ "$PKG_MANAGER" = "yum" ]; then
        local to_install=()
        for pkg in "${deps[@]}"; do
            if ! rpm -q "$pkg" &>/dev/null; then
                to_install+=("$pkg")
            fi
        done
        if [ ${#to_install[@]} -gt 0 ]; then
            info "安装系统依赖: ${to_install[*]}"
            sudo yum install -y "${to_install[@]}"
        fi
    fi

    ok "系统依赖检查完成"
}

install_system_deps

# ---------- 安装 Node.js ----------
step "检查 Node.js 环境..."

if command -v node &> /dev/null; then
    NODE_VER=$(node --version)
    ok "Node.js 已安装: $NODE_VER"
else
    warn "未检测到 Node.js，正在安装..."

    # 使用 nvm 或 nodesource
    if command -v nvm &> /dev/null || [ -f "$HOME/.nvm/nvm.sh" ]; then
        source "$HOME/.nvm/nvm.sh" 2>/dev/null
        nvm install --lts
        nvm use --lts
        ok "Node.js 已通过 nvm 安装: $(node --version)"
    else
        info "通过 NodeSource 安装 Node.js LTS..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt install -y nodejs
        ok "Node.js 已安装: $(node --version)"
    fi
fi

# ---------- 配置 npm 镜像 ----------
step "配置 npm 镜像源..."

# 淘宝镜像源（国内速度最佳）
npm config set registry https://registry.npmmirror.com/
ok "npm 镜像源已设置为 https://registry.npmmirror.com"

# 配置 Electron 镜像
npm config set electron_mirror https://npmmirror.com/mirrors/electron/
if ! grep -q "ELECTRON_MIRROR" ~/.bashrc 2>/dev/null; then
    echo 'export ELECTRON_MIRROR="https://npmmirror.com/mirrors/electron/"' >> ~/.bashrc
fi
ok "Electron 镜像源已配置"

# ---------- 安装 Claude Code ----------
step "安装 @anthropic-ai/claude-code..."

if npm install -g @anthropic-ai/claude-code --registry=https://registry.npmmirror.com/; then
    ok "@anthropic-ai/claude-code 安装成功！"
else
    warn "通过镜像源安装失败，尝试直连..."
    if npm install -g @anthropic-ai/claude-code; then
        ok "@anthropic-ai/claude-code 安装成功！"
    else
        err "安装失败，请检查网络连接后重试"
        exit 1
    fi
fi

# ---------- 配置 Claude Code ----------
step "配置 Claude Code..."

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

mkdir -p "$CLAUDE_DIR"

if [ -f "$SETTINGS_FILE" ]; then
    warn "settings.json 已存在，创建备份..."
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup.$(date +%Y%m%d%H%M%S)"
    ok "备份已创建"
fi

# 询问是否使用 DeepSeek
read -p "是否配置 DeepSeek API？（推荐，国内直接可用）[Y/n] " use_deepseek
if [[ "$use_deepseek" =~ ^[Nn]$ ]]; then
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "apiKey": "你的真实API-Key"
}
EOF
    ok "已生成占位配置文件，请手动修改 ~/.claude/settings.json"
else
    read -p "请输入你的 DeepSeek API Key（留空则生成占位符）: " api_key
    if [ -z "$api_key" ]; then
        api_key="你的真实API-Key"
        warn "API Key 已设为占位符，请稍后手动修改"
    fi

    cat > "$SETTINGS_FILE" << EOF
{
  "apiKey": "$api_key",
  "model": "deepseek-chat",
  "apiBaseUrl": "https://api.deepseek.com/v1"
}
EOF
    ok "DeepSeek 配置已写入 $SETTINGS_FILE"
fi

# ---------- 修复 PATH ----------
step "检查 PATH 环境变量..."

NPM_PREFIX=$(npm config get prefix)
if [[ ":$PATH:" != *":$NPM_PREFIX/bin:"* ]]; then
    warn "npm 全局 bin 目录不在 PATH 中，正在修复..."
    echo "export PATH=\"\$PATH:$NPM_PREFIX/bin\"" >> ~/.bashrc
    export PATH="$PATH:$NPM_PREFIX/bin"
    ok "已添加 $NPM_PREFIX/bin 到 PATH"
else
    ok "npm 全局路径已在 PATH 中"
fi

# 如果使用 zsh，也配置
if [ -f ~/.zshrc ]; then
    if ! grep -q "$NPM_PREFIX/bin" ~/.zshrc 2>/dev/null; then
        echo "export PATH=\"\$PATH:$NPM_PREFIX/bin\"" >> ~/.zshrc
        echo "export ELECTRON_MIRROR=\"https://npmmirror.com/mirrors/electron/\"" >> ~/.zshrc
        ok "已将 npm 路径写入 ~/.zshrc"
    fi
fi

# ---------- 验证安装 ----------
step "验证安装..."

if command -v claude &> /dev/null; then
    CLAUDE_VER=$(claude --version 2>/dev/null || echo "版本信息获取成功")
    ok "Claude Code 安装成功！版本: $CLAUDE_VER"
    echo ""
    echo -e "${GREEN}🎉 安装完成！${NC}"
    echo -e "现在你可以使用以下命令启动 Claude Code："
    echo -e "  ${CYAN}claude${NC}"
    echo ""
    echo -e "或者使用 DeepSeek API 启动："
    echo -e "  ${CYAN}ANTHROPIC_API_KEY=你的Key claude${NC}"
else
    err "claude 命令未找到"
    warn "请尝试执行: source ~/.bashrc"
    warn "然后运行: claude --version"
fi

echo ""
echo -e "${CYAN}📚 更多帮助：${NC}"
echo "  - 安装指南: docs/install.md"
echo "  - 故障排除: docs/troubleshooting.md"
echo "  - 常见问题: docs/faq.md"
echo ""
echo -e "${YELLOW}💡 提示：如果遇到任何问题，请重新打开终端后重试。${NC}"
echo ""
