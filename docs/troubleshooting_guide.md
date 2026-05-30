# 故障排除指南

> 收集了 Claude Code 在中国大陆使用时的常见错误及解决方案。

## 目录

1. [网络连接问题](#1-网络连接问题)
2. [安装问题](#2-安装问题)
3. [运行问题](#3-运行问题)
4. [API 问题](#4-api-问题)
5. [配置文件问题](#5-配置文件问题)
6. [PATH 相关错误](#6-path-相关错误)
7. [MCP 服务器问题](#7-mcp-服务器问题)
8. [电脑控制功能问题](#8-电脑控制功能问题)

---

## 1. 网络连接问题

### 1.1 无法访问 registry.npmjs.org

**错误信息：**
```
npm ERR! request to https://registry.npmjs.org/ failed
npm ERR! connect ETIMEDOUT
```

**解决方案：**
```bash
# 1) 切换到淘宝镜像源
npm config set registry https://registry.npmmirror.com/

# 2) 配置代理（如果有）
npm config set proxy http://127.0.0.1:7890
npm config set https-proxy http://127.0.0.1:7890

# 3) 设置代理环境变量
$env:HTTP_PROXY="http://127.0.0.1:7890"  # PowerShell
export HTTP_PROXY="http://127.0.0.1:7890"  # WSL
```

### 1.2 无法访问 api.github.com

**错误信息：**
```
fatal: unable to access 'https://github.com/...'
```

**解决方案：**
```bash
# 1) 配置 git 代理
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# 2) 使用 GitHub 镜像
git config --global url."https://github.com.cnpmjs.org/".insteadOf "https://github.com/"
```

### 1.3 无法访问 api.deepseek.com

**错误信息：**
```
Error: connect ETIMEDOUT api.deepseek.com:443
```

**解决方案：**
- 检查防火墙是否阻止了出站连接
- 尝试使用代理：`$env:HTTPS_PROXY="http://127.0.0.1:7890"`
- 检查 DNS 解析：`nslookup api.deepseek.com`
- 如被 DNS 污染，可修改 hosts 文件或使用 114.114.114.114 DNS

### 1.4 npm install 电子包下载失败

**错误信息：**
```
npm ERR! Error downloading electron
```

**解决方案：**
```bash
# 设置 Electron 镜像
npm config set electron_mirror https://npmmirror.com/mirrors/electron/
# 或通过环境变量
$env:ELECTRON_MIRROR="https://npmmirror.com/mirrors/electron/"  # PowerShell
export ELECTRON_MIRROR="https://npmmirror.com/mirrors/electron/"  # WSL
```

### 1.5 Claude Code 启动后卡住或超时

**可能原因：** Claude Code 启动时需要连接 API 进行初始化验证。

**解决方案：**
```bash
# 1) 检查 API Base URL 是否正确（确认使用国内可访问的地址）
# 2) 检查 API Key 是否有效
# 3) 尝试使用代理
$env:HTTPS_PROXY="http://127.0.0.1:7890"
claude

# 4) 使用 --verbose 查看详细日志
claude --verbose
```

---

## 2. 安装问题

### 2.1 npm install -g 权限错误

**错误信息：**
```
npm ERR! Error: EACCES: permission denied
```

**解决方案：**
```bash
# Windows: 以管理员身份运行 PowerShell
# Linux/Mac:
sudo npm install -g @anthropic-ai/claude-code

# 或修改 npm 全局路径（推荐）
npm config set prefix $HOME/.npm-global
echo 'export PATH=$PATH:$HOME/.npm-global/bin' >> ~/.bashrc
source ~/.bashrc
```

### 2.2 安装时磁盘空间不足

**错误信息：**
```
npm ERR! ENOSPC: no space left on device
```

**解决方案：**
```bash
# 清理 npm 缓存
npm cache clean --force

# 清理临时文件
# Windows: 运行磁盘清理工具
# WSL:
sudo apt clean
sudo journalctl --vacuum-size=100M
```

### 2.3 安装过程中断

**解决方案：**
```bash
# 清理缓存后重试
npm cache clean --force
npm install -g @anthropic-ai/claude-code

# 如果还是失败，尝试使用不同的 Node.js 版本
nvm install 20
nvm use 20
```

---

## 3. 运行问题

### 3.1 "claude" 命令找不到

**错误信息：**
```
claude : 无法将 "claude" 项识别为 cmdlet、函数、脚本文件或可运行程序的名称。
```

**解决方案：**
```bash
# 1) 运行修复脚本
.\scripts\fix_claude_path.ps1

# 2) 手动添加 PATH
# PowerShell:
$env:Path += ";$env:APPDATA\npm"
[Environment]::SetEnvironmentVariable("Path", "$env:Path;$env:APPDATA\npm", "User")

# WSL:
export PATH="$PATH:$(npm config get prefix)/bin"
echo 'export PATH="$PATH:$(npm config get prefix)/bin"' >> ~/.bashrc

# 3) 确认安装成功
npm list -g @anthropic-ai/claude-code
```

### 3.2 claude 命令无响应

**解决方案：**
```bash
# 1) 检查 Node.js 版本
node --version  # 需要 18+，推荐 20 LTS

# 2) 检查磁盘和内存
# 3) 重新安装
npm uninstall -g @anthropic-ai/claude-code
npm install -g @anthropic-ai/claude-code
```

### 3.3 Node.js 版本不兼容

**错误信息：**
```
Error: The engine "node" is incompatible with this module
```

**解决方案：**
```bash
# 使用 nvm 切换版本
nvm install 20
nvm use 20

# 或强制安装（不推荐）
npm install -g @anthropic-ai/claude-code --ignore-engines
```

---

## 4. API 问题

### 4.1 401 Unauthorized

**错误信息：**
```
Error: 401 Unauthorized
```

**解决方案：**
```bash
# 1) 检查 API Key 是否正确
cat ~/.claude/settings.json | grep apiKey

# 2) 确认 API Key 未过期（DeepSeek Key 长期有效）
# 3) 检查是否有空格或换行符
# 4) 重新生成 API Key
```

### 4.2 429 Too Many Requests

**错误信息：**
```
Error: 429 Too Many Requests
```

**解决方案：**
```bash
# 1) 降低请求频率
# 2) 检查账户余额（DeepSeek 平台）
# 3) 升级 API 套餐
# 4) 使用多个 API Key 轮换
```

### 4.3 400 Bad Request - 模型不存在

**错误信息：**
```
Error: 400 - model "deepseek-chat" not found
```

**解决方案：**
```bash
# DeepSeek 最新模型名称可能已变更，请检查文档
# 当前 DeepSeek 模型列表：
# - deepseek-chat (推荐)
# - deepseek-coder
# - deepseek-reasoner

# 更新配置文件
# ~/.claude/settings.json
{
  "model": "deepseek-chat",
  "apiBaseUrl": "https://api.deepseek.com/v1"
}
```

### 4.4 API 返回空响应

**解决方案：**
```bash
# 1) 检查 API 计费状态
# 2) 测试 API 可用性
curl https://api.deepseek.com/v1/models \
  -H "Authorization: Bearer $ANTHROPIC_API_KEY"

# 3) 检查请求参数是否合法
```

---

## 5. 配置文件问题

### 5.1 JSON 解析错误

**错误信息：**
```
Error parsing JSON in settings file
```

**解决方案：**
```json
// 常见错误：末尾多了一个逗号
// ❌ 错误：
{
  "apiKey": "sk-xxx",
  "model": "deepseek-chat",  // ← 这里多了逗号
}

// ✅ 正确：
{
  "apiKey": "sk-xxx",
  "model": "deepseek-chat"
}
```

使用 JSON 验证工具：
```bash
# Node.js 方式验证
node -e "console.log(JSON.stringify(JSON.parse(require('fs').readFileSync('$HOME/.claude/settings.json', 'utf8'))))"

# 或使用在线工具：jsonlint.com
```

### 5.2 配置文件被忽略

**解决方案：**
```bash
# 1) 确认文件位置正确（必须是 ~/.claude/settings.json）
# 2) 检查文件编码（必须是 UTF-8）
# 3) 检查文件权限
chmod 600 ~/.claude/settings.json
```

### 5.3 环境变量优先级问题

Claude Code 的配置优先级：**环境变量 > settings.json > 默认值**

```bash
# 如果设置了环境变量，settings.json 中的值会被覆盖
# 检查当前环境变量
echo $ANTHROPIC_API_KEY
echo $CLAUDE_API_BASE

# 清除环境变量（让 settings.json 生效）
unset ANTHROPIC_API_KEY
unset CLAUDE_API_BASE
```

---

## 6. PATH 相关错误

### 6.1 npm 全局包安装后找不到命令

**错误信息：**
```
'claude' 不是内部或外部命令，也不是可运行的程序
```

**解决方案：**
```powershell
# 1) 查找 npm 全局路径
npm config get prefix

# 2) 添加 PATH（PowerShell）
[Environment]::SetEnvironmentVariable("Path", 
  "$env:Path;$(npm config get prefix)", "User")

# 3) 立即生效
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + 
           [Environment]::GetEnvironmentVariable("Path", "User")
```

### 6.2 WSL 中 PATH 未继承

**解决方案：**
```bash
# 在 ~/.bashrc 中添加
export PATH="$PATH:$(npm config get prefix)/bin"
source ~/.bashrc
```

---

## 7. MCP 服务器问题

### 7.1 MCP 服务器无法启动

**解决方案：**
```bash
# 1) 检查 MCP 服务器是否已安装
npm list -g @modelcontextprotocol/server-filesystem

# 2) 检查 settings.json 配置
cat ~/.claude/settings.json | grep mcpServers

# 3) 手动测试启动
npx -y @modelcontextprotocol/server-filesystem /
```

### 7.2 MCP GitHub 认证失败

**解决方案：**
```bash
# 1) 生成 GitHub Token
#    Settings → Developer settings → Personal access tokens → Fine-grained tokens
# 2) 更新 settings.json
{
  "mcpServers": {
    "github": {
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_你的Token"
      }
    }
  }
}
```

---

## 8. 电脑控制功能问题

### 8.1 电脑控制功能不可用

**解决方案：**
```bash
# 1) Windows：以管理员身份运行
# 2) 启用相应的系统权限
#    - Windows: 无障碍权限
#    - macOS: 屏幕录制权限
#    - Linux: xdotool / xte 依赖

# 3) 检查环境变量
$env:CLAUDE_COMPUTER_USE="1"
claude
```

---

## 获取更多帮助

- 查看 [常见问题](faq.md)
- [提交 Issue](https://github.com/skbb1v66-png/claude-code-china-setup/issues/new)
- 搜索相似问题
