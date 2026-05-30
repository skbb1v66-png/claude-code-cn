#!/bin/bash
# =============================================================================
# Claude Code 启动脚本 (WSL / Linux)
# =============================================================================
# 功能：以不同配置启动 Claude Code CLI，支持 DeepSeek API、代理、电脑控制
# 用法：
#   ./start_claude.sh                                    # 使用默认配置启动
#   ./start_claude.sh -p deepseek -k "sk-xxx"            # 指定 DeepSeek API
#   ./start_claude.sh -c                                 # 启用电脑控制
#   ./start_claude.sh -x "http://127.0.0.1:7890"         # 使用代理
# =============================================================================

set -e

# ---------- 颜色定义 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[2m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}$1${NC}"; }
ok()    { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }
dim()   { echo -e "${GRAY}$1${NC}"; }

# ---------- 参数解析 ----------
usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -p, --provider <provider>   API 提供商 (deepseek|openai|anthropic)"
    echo "  -k, --api-key <key>          API Key"
    echo "  -m, --model <model>          模型名称 (默认: deepseek-chat)"
    echo "  -c, --computer-use           启用电脑控制功能"
    echo "  -x, --proxy <url>            HTTP/HTTPS 代理地址"
    echo "  -h, --help                   显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -p deepseek -k sk-xxxxxx"
    echo "  $0 -c"
    echo "  $0 -x http://127.0.0.1:7890"
    exit 0
}

PROVIDER=""
API_KEY=""
MODEL="deepseek-chat"
COMPUTER_USE=false
PROXY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--provider)
            PROVIDER="$2"
            shift 2
            ;;
        -k|--api-key)
            API_KEY="$2"
            shift 2
            ;;
        -m|--model)
            MODEL="$2"
            shift 2
            ;;
        -c|--computer-use)
            COMPUTER_USE=true
            shift
            ;;
        -x|--proxy)
            PROXY="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            err "未知参数: $1"
            usage
            ;;
    esac
done

# ---------- Banner ----------
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║           Claude Code 启动脚本 v1.0             ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ---------- 读取 settings.json ----------
SETTINGS_FILE="$HOME/.claude/settings.json"

load_settings() {
    if [[ -f "$SETTINGS_FILE" ]]; then
        # 使用 grep 和 sed 解析简单的 JSON（避免 jq 依赖）
        local key api_key_from_file api_base model_from_file

        api_key_from_file=$(grep -o '"apiKey"[[:space:]]*:[[:space:]]*"[^"]*"' "$SETTINGS_FILE" 2>/dev/null | head -1 | sed 's/.*: *"\(.*\)"/\1/')
        api_base=$(grep -o '"apiBaseUrl"[[:space:]]*:[[:space:]]*"[^"]*"' "$SETTINGS_FILE" 2>/dev/null | head -1 | sed 's/.*: *"\(.*\)"/\1/')
        model_from_file=$(grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' "$SETTINGS_FILE" 2>/dev/null | head -1 | sed 's/.*: *"\(.*\)"/\1/')

        if [[ -n "$api_key_from_file" && "$api_key_from_file" != "你的真实API-Key" ]]; then
            echo "$api_key_from_file"
        fi

        if [[ -n "$api_base" ]]; then
            CLAUDE_API_BASE="$api_base"
        fi

        if [[ -n "$model_from_file" ]]; then
            CLAUDE_MODEL="$model_from_file"
        fi

        return 0
    fi
    return 1
}

# ---------- 构建环境变量 ----------
echo -e "\n${CYAN}📋 启动配置：${NC}"

# API Key 优先级：命令行参数 > 环境变量 > settings.json
if [[ -n "$API_KEY" ]]; then
    export ANTHROPIC_API_KEY="$API_KEY"
elif [[ -n "$ANTHROPIC_API_KEY" ]]; then
    : # 已存在环境变量中
else
    LOADED_KEY=$(load_settings)
    if [[ -n "$LOADED_KEY" ]]; then
        export ANTHROPIC_API_KEY="$LOADED_KEY"
    fi
fi

if [[ -n "$ANTHROPIC_API_KEY" ]]; then
    MASKED="${ANTHROPIC_API_KEY:0:8}..."
    ok "API Key: $MASKED"
else
    warn "API Key: 未设置"
    warn "请通过 -k 参数指定或配置 ~/.claude/settings.json"
fi

# API Base URL
if [[ -n "$PROVIDER" ]]; then
    case "$PROVIDER" in
        deepseek)
            export CLAUDE_API_BASE="https://api.deepseek.com/v1"
            ;;
        openai)
            export CLAUDE_API_BASE="https://api.openai.com/v1"
            ;;
        anthropic)
            # 使用官方 API，不设置 Base URL
            unset CLAUDE_API_BASE
            ;;
    esac
fi

if [[ -n "$CLAUDE_API_BASE" ]]; then
    ok "API Base: $CLAUDE_API_BASE"
fi

# 模型名称
if [[ -n "$MODEL" ]]; then
    export CLAUDE_MODEL="$MODEL"
    ok "Model: $MODEL"
fi

# 代理设置
if [[ -n "$PROXY" ]]; then
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
    ok "Proxy: $PROXY"
fi

# 电脑控制
if [[ "$COMPUTER_USE" == true ]]; then
    export CLAUDE_COMPUTER_USE="1"
    info "🖥️  电脑控制模式已启用"
fi

# ---------- 启动 Claude Code ----------
echo -e "\n${GREEN}🚀 正在启动 Claude Code...${NC}\n"

if command -v claude &> /dev/null; then
    claude
else
    err "启动失败：claude 命令未找到"
    warn "请确认已安装 @anthropic-ai/claude-code"
    warn "或运行 setup/install_claude_wsl.sh 进行安装"
    exit 1
fi
