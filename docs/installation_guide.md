# 安装指南

> 详细指导你如何在中国大陆网络环境下安装和配置 Claude Code。

## 系统要求

### Windows

| 要求 | 最低版本 | 推荐版本 |
|------|---------|---------|
| 操作系统 | Windows 10 1809+ | Windows 11 / Windows 10 22H2+ |
| PowerShell | 5.1+ | PowerShell 7.4+ |
| Node.js | 18.x LTS | 20.x LTS 或 22.x LTS |
| 网络 | 可访问 npm 或配置代理 | 宽带连接 |
| 磁盘空间 | 500 MB | 1 GB+ |

### WSL / Linux

| 要求 | 最低版本 | 推荐版本 |
|------|---------|---------|
| 操作系统 | Ubuntu 20.04 / Debian 11 | Ubuntu 24.04 LTS |
| WSL 版本 | WSL 2 | WSL 2 |
| Node.js | 18.x LTS | 20.x LTS |
| 网络 | 可访问 npm 或配置代理 | 宽带连接 |

## 安装方式

### 方式一：一键安装（推荐）

#### Windows

1. 以**管理员身份**打开 PowerShell
2. 执行以下命令之一：

```powershell
# 在线安装
irm https://raw.githubusercontent.com/skbb1v66-png/claude-code-cn/main/setup/install_claude_windows.ps1 | iex

# 或克隆后安装
git clone https://github.com/skbb1v66-png/claude-code-cn.git
cd claude-code-cn
.\setup\install_claude_windows.ps1
```

#### WSL / Linux

```bash
# 克隆仓库
git clone https://github.com/skbb1v66-png/claude-code-cn.git
cd claude-code-cn

# 执行安装
chmod +x setup/install_claude_wsl.sh
./setup/install_claude_wsl.sh
```

### 方式二：手动安装

#### 1. 安装 Node.js

**Windows：**
- 下载安装包：[nodejs.org/zh-cn](https://nodejs.org/zh-cn/)（选择 LTS 版本）
- 或使用 winget：`winget install OpenJS.NodeJS.LTS`

**WSL / Linux：**
```bash
# 使用 nvm（推荐）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
nvm install --lts

# 或使用 apt
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
```

#### 2. 配置 npm 镜像源

```bash
# 设置淘宝镜像源（国内速度最佳）
npm config set registry https://registry.npmmirror.com/

# 配置 Electron 镜像（Claude Code 依赖）
npm config set electron_mirror https://npmmirror.com/mirrors/electron/
```

#### 3. 安装 Claude Code

```bash
# 使用镜像源安装
npm install -g @anthropic-ai/claude-code --registry=https://registry.npmmirror.com/

# 验证安装
claude --version
```

#### 4. 配置 API

```bash
# 创建配置目录
mkdir -p ~/.claude

# 复制模板
cp setup/claude_config.template.json ~/.claude/settings.json

# 编辑配置文件，填入你的 API Key
vim ~/.claude/settings.json
```

### 方式三：使用 Docker

```bash
# 拉取镜像
docker pull anthropic/claude-code

# 使用 DeepSeek API 运行
docker run -it --rm \
  -e ANTHROPIC_API_KEY="你的真实API-Key" \
  -e CLAUDE_API_BASE="https://api.deepseek.com/v1" \
  anthropic/claude-code
```

## 配置 API

### DeepSeek API（推荐，国内可用）

1. 注册并获取 API Key：[platform.deepseek.com](https://platform.deepseek.com/)
2. 配置 `~/.claude/settings.json`：
   ```json
   {
     "apiKey": "sk-你的Key",
     "model": "deepseek-chat",
     "apiBaseUrl": "https://api.deepseek.com/v1"
   }
   ```
3. DeepSeek 计费：约 ¥1 元 / 百万 token（输入），¥2 元 / 百万 token（输出）

### 其他兼容 API

| 服务商 | API Base URL | 备注 |
|--------|-------------|------|
| DeepSeek | `https://api.deepseek.com/v1` | 推荐，国内直连 |
| Moonshot | `https://api.moonshot.cn/v1` | 国内可用 |
| 阿里通义千问 | `https://dashscope.aliyuncs.com/compatible-mode/v1` | 国内可用 |
| 百度千帆 | `https://qianfan.baidubce.com/v2` | 国内可用 |

## 启动 Claude Code

### Windows

```powershell
# 基本启动
claude

# 使用启动脚本（自动设置环境变量）
.\scripts\start_claude.ps1

# 指定 DeepSeek API
.\scripts\start_claude.ps1 -Provider deepseek -ApiKey "sk-xxx"
```

### WSL / Linux

```bash
# 基本启动
claude

# 使用环境变量指定 API
ANTHROPIC_API_KEY="sk-xxx" CLAUDE_API_BASE="https://api.deepseek.com/v1" claude
```

## 验证安装

```bash
# 检查版本
claude --version

# 检查配置
claude config list

# 测试 API 连接
claude --test-api
```

## 下一步

- 阅读 [故障排除](troubleshooting_guide.md) 了解常见问题
- 查看 [常见问题](faq.md) 获取更多帮助
- 配置 [MCP 服务器](../scripts/install_mcp_tools.ps1) 扩展功能
