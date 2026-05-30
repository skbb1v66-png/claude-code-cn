# 常见问题

> 用户高频问题汇总，持续更新中。

---

## 基础问题

### Q: Claude Code 是什么？

Claude Code 是 Anthropic 官方推出的 AI 编程助手，集成在命令行终端中。它能理解代码库，帮助编写、重构、测试和调试代码——无需离开终端。

### Q: Claude Code 收费吗？

Claude Code 本身是**免费**的命令行工具。但调用 API 需要付费：
- **Anthropic 官方 API**：按 token 计费，需海外支付方式
- **DeepSeek API**：按 token 计费，支持支付宝/微信（推荐国内用户使用）
- **API 代理服务**：部分第三方提供中转服务

### Q: Claude Code 和 GitHub Copilot 有什么区别？

| 特性 | Claude Code | GitHub Copilot |
|------|-------------|----------------|
| 交互方式 | 终端对话式 | IDE 内联补全 |
| 代码库理解 | 完整项目上下文 | 当前文件/附近代码 |
| 操作能力 | 读写文件、执行命令 | 代码补全建议 |
| 国内可用性 | 需配置 API | 相对稳定 |
| 价格 | API 按量付费 | 订阅制 ($10/月) |

### Q: 必须使用 DeepSeek 吗？能用其他 API 吗？

可以。任何兼容 OpenAI API 格式的服务都可以使用，只需修改 `apiBaseUrl`。支持的 API 包括：
- DeepSeek（推荐，国内直连）
- 阿里通义千问
- Moonshot（月之暗面）
- 智谱 GLM
- 百度千帆

---

## 安装问题

### Q: 安装需要多长时间？

取决于网络状况：
- **有代理 / 镜像源配置正确**：约 2-5 分钟
- **无代理 / 直连**：可能失败或需要 10-30 分钟
- **首次安装 Electron 依赖**：可能额外 1-3 分钟

### Q: 安装时提示 "Permission denied"

**Windows**：右键 PowerShell → "以管理员身份运行"

**WSL/Linux**：
```bash
# 添加执行权限
chmod +x setup/install_claude_wsl.sh

# 使用 sudo 安装全局包
sudo npm install -g @anthropic-ai/claude-code
```

### Q: 可以离线安装吗？

目前 Claude Code 需要联网安装。安装完成后，运行时需要联网调用 API。

---

## 配置问题

### Q: 如何获取 DeepSeek API Key？

1. 访问 [platform.deepseek.com](https://platform.deepseek.com/)
2. 注册账号（支持邮箱/手机号）
3. 进入 API Keys 页面
4. 点击 "Create API Key"
5. 复制生成的 Key（以 `sk-` 开头）

### Q: 配置完还是连不上 DeepSeek API？

请按以下步骤排查：
1. **验证 API Key**：登录 DeepSeek 平台确认 Key 有效
2. **检查账户余额**：新注册账户有赠送额度，但可能已用完
3. **测试 API 连接**：
   ```bash
   curl https://api.deepseek.com/v1/chat/completions \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer 你的Key" \
     -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"hello"}]}'
   ```
4. **检查配置文件**：确认 `settings.json` 中 `apiBaseUrl` 为 `https://api.deepseek.com/v1`

### Q: settings.json 在哪里？

| 系统 | 路径 |
|------|------|
| Windows | `%USERPROFILE%\.claude\settings.json` |
| WSL/Linux | `~/.claude/settings.json` |
| macOS | `~/.claude/settings.json` |

### Q: 如何切换不同的 API 提供商？

编辑 `~/.claude/settings.json`，修改 `apiBaseUrl`：

```json
{
  "apiKey": "你的Key",
  "model": "deepseek-chat",
  "apiBaseUrl": "https://api.deepseek.com/v1"
}
```

或使用环境变量（优先级更高）：
```bash
export CLAUDE_API_BASE="https://api.deepseek.com/v1"
export ANTHROPIC_API_KEY="你的Key"
claude
```

---

## 使用问题

### Q: 为什么 Claude Code 输出全是英文？

Claude Code 会根据你的提问语言自动回复。用中文提问就会得到中文回答。你也可以在对话中明确要求：

> "请用中文回答"
> "请用简体中文解释"

### Q: 如何查看当前配置？

```bash
claude config list
```

### Q: Claude Code 支持哪些编程语言？

所有主流语言都支持：Python、JavaScript/TypeScript、Java、Go、Rust、C/C++、C#、Ruby、PHP、Swift、Kotlin、Shell 等。

### Q: 电脑控制（Computer Use）功能如何使用？

电脑控制功能允许 Claude 直接操作你的桌面。

**启用方式：**
```powershell
# Windows
.\scripts\start_claude.ps1 -ComputerUse
```

```bash
# WSL/Linux
CLAUDE_COMPUTER_USE=1 claude
```

**注意事项：**
- Windows 需要管理员权限
- 建议在沙箱或虚拟机中使用
- 不要在无人值守时使用

### Q: 如何升级 Claude Code？

```bash
npm update -g @anthropic-ai/claude-code

# 或重新安装最新版
npm install -g @anthropic-ai/claude-code@latest
```

---

## 网络问题

### Q: 国内一定要配置代理吗？

不一定。如果你使用 DeepSeek API，直接可以访问，无需代理。只有在安装 npm 包或访问 GitHub 时才可能需要代理。

### Q: 如何在 WSL 中使用 Windows 的代理？

WSL 可以通过以下方式访问 Windows 宿主机的代理：

```bash
# 方法一：自动检测（Windows 宿主机 IP）
export HOST_IP=$(ip route | grep default | awk '{print $3}')
export HTTP_PROXY="http://$HOST_IP:7890"
export HTTPS_PROXY="http://$HOST_IP:7890"

# 方法二：写入 .bashrc 永久生效
echo 'export HOST_IP=$(ip route | grep default | awk '\''{print $3}'\'')' >> ~/.bashrc
echo 'export HTTP_PROXY="http://$HOST_IP:7890"' >> ~/.bashrc
echo 'export HTTPS_PROXY="http://$HOST_IP:7890"' >> ~/.bashrc
```

### Q: 淘宝镜像源不稳定怎么办？

```bash
# 备用镜像源列表
npm config set registry https://registry.npmmirror.com/      # 淘宝（主选）
npm config set registry https://mirrors.huaweicloud.com/repository/npm/  # 华为云
npm config set registry https://registry.npmjs.org/          # 官方（直连慢）
```

---

## 错误与调试

### Q: 出现乱码怎么办？

**PowerShell 乱码：**
```powershell
# 设置 UTF-8 编码
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
```

**WSL 乱码：**
```bash
# 检查 locale
locale
# 如果需要，配置 UTF-8
sudo locale-gen zh_CN.UTF-8
```

### Q: 如何查看详细日志？

```bash
claude --verbose
# 或
claude --log-level debug
```

### Q: 如何完全重置 Claude Code？

```bash
# 1) 卸载全局包
npm uninstall -g @anthropic-ai/claude-code

# 2) 删除配置文件
# Windows:
rm -r $HOME\.claude
# WSL/Linux:
rm -rf ~/.claude

# 3) 清除 npm 缓存
npm cache clean --force

# 4) 重新安装
npm install -g @anthropic-ai/claude-code
```

---

## 其他

### Q: 此项目会长期维护吗？

是的。只要 Claude Code 和 DeepSeek 等国内 API 服务存在，我们会持续更新。

### Q: 如何贡献代码？

欢迎提交 Pull Request！请先阅读 [贡献指南](../CONTRIBUTING.md)（如果有）。

### Q: 安全问题如何报告？

请不要在公开 Issue 中提交安全漏洞。请发送邮件至 [security@example.com]。

---

> 如果以上内容没有解决你的问题，请 [提交 Issue](https://github.com/skbb1v66-png/claude-code-cn/issues/new)。
