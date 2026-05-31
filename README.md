# Claude Code 中国安装配置指南 🇨🇳

<p align="center">
  <img src="docs/images/claude-code-screenshot.png" alt="Claude Code 运行截图" width="720"/>
</p>

<p align="center">
  <b>让 Claude Code 在中国大陆网络环境下顺畅运行的完整解决方案</b>
</p>

<p align="center">
  <a href="https://github.com/skbb1v66-png/claude-code-cn/stargazers">
    <img src="https://img.shields.io/github/stars/skbb1v66-png/claude-code-cn?style=for-the-badge&logo=github" alt="GitHub Stars"/>
  </a>
  <a href="https://github.com/skbb1v66-png/claude-code-cn/forks">
    <img src="https://img.shields.io/github/forks/skbb1v66-png/claude-code-cn?style=for-the-badge&logo=github" alt="GitHub Forks"/>
  </a>
  <a href="https://github.com/skbb1v66-png/claude-code-cn/issues">
    <img src="https://img.shields.io/github/issues/skbb1v66-png/claude-code-cn?style=for-the-badge&logo=github" alt="GitHub Issues"/>
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/skbb1v66-png/claude-code-cn?style=for-the-badge" alt="License"/>
  </a>
  <br/>
  <a href="https://github.com/skbb1v66-png/claude-code-cn/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/skbb1v66-png/claude-code-cn/check-scripts.yml?style=for-the-badge&label=CI" alt="CI Status"/>
  </a>
  <a href="https://github.com/skbb1v66-png/claude-code-cn/commits/main">
    <img src="https://img.shields.io/github/last-commit/skbb1v66-png/claude-code-cn?style=for-the-badge" alt="Last Commit"/>
  </a>
</p>

---

## 📖 项目介绍

**Claude Code** 是 Anthropic 官方推出的命令行 AI 编程助手，但在中国大陆网络环境下，默认安装和使用会遇到：

| ❌ 问题 | 原因 |
|--------|------|
| 网络连接失败 | NPM 源 / GitHub 被限制 |
| API 访问超时 | Anthropic API 国内延迟高 |
| 依赖安装缓慢 | 国外 CDN 下载限速 |
| 权限配置繁琐 | Windows/macOS/Linux 各不同 |

**本项目提供了一套完整的一站式解决方案：**

- ✅ **一键安装** — 自动检测环境，无需手动配置
- ✅ **网络优化** — 自动设置国内镜像源 / 代理
- ✅ **DeepSeek 集成** — 国内可直接访问，无需翻墙
- ✅ **开箱即用** — 装好就能跑，零额外配置
- ✅ **跨平台** — Windows + WSL/Linux 全支持

---

## 🚀 快速开始

### Windows 一键安装

以**管理员身份**打开 PowerShell，执行：

```powershell
# 方式一：远程执行（推荐）
irm https://raw.githubusercontent.com/skbb1v66-png/claude-code-cn/main/setup/install_claude_windows.ps1 | iex

# 方式二：克隆后本地执行
git clone https://github.com/skbb1v66-png/claude-code-cn.git
cd claude-code-cn
.\setup\install_claude_windows.ps1
```

### WSL / Linux 一键安装

```bash
git clone https://github.com/skbb1v66-png/claude-code-cn.git
cd claude-code-cn
chmod +x setup/install_claude_wsl.sh && ./setup/install_claude_wsl.sh
```

---

## 🔌 接入 DeepSeek API（推荐）

Claude Code 默认走 Anthropic 官方 API，国内访问极慢。本项目支持一键切换为 **DeepSeek API**：

```powershell
# Windows - 替换成你的真实 API Key
.\scripts\start_claude.ps1 -Provider deepseek -ApiKey "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

```bash
# WSL/Linux
./scripts/start_claude.sh -p deepseek -k "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

> 💡 **DeepSeek API 优势：** 国内直接访问、价格低（约 Anthropic 的 1/10）、支持 1M 上下文
>
> 🔑 **[点此获取 DeepSeek API Key](https://platform.deepseek.com/)**

### 手动配置

编辑 `~/.claude/settings.json`：

```json
{
  "apiKey": "你的DeepSeek API Key",
  "model": "deepseek-chat",
  "apiBaseUrl": "https://api.deepseek.com/v1"
}
```

---

## 🖥️ Computer Use（桌面操控）

启用电脑控制功能：

```powershell
.\scripts\start_claude.ps1 -ComputerUse
```

> 详细配置见 [安装指南](docs/installation_guide.md)

---

## 📋 常见问题速览

| 问题 | 解决方案 |
|------|----------|
| 安装时网络超时 | 执行 `.\scripts\fix_claude_path.ps1` 配置代理 |
| `claude` 命令找不到 | 运行 `.\scripts\fix_claude_path.ps1` 修复 PATH |
| API 返回 401 | 检查 API Key 是否正确 |
| DeepSeek API 限流 | 检查账户余额或降低请求频率 |

---

## 📁 项目结构

```
claude-code-cn/
├── README.md                  # 项目说明（本文件）
├── setup/                     # 安装脚本
│   ├── install_claude_windows.ps1
│   ├── install_claude_wsl.sh
│   └── claude_config.template.json
├── scripts/                   # 工具脚本
│   ├── start_claude.ps1 / .sh
│   ├── fix_claude_path.ps1
│   └── install_mcp_tools.ps1
├── docs/                      # 文档
│   ├── installation_guide.md
│   ├── troubleshooting_guide.md
│   └── faq.md
└── .github/                   # GitHub 配置
    ├── workflows/check-scripts.yml
    └── ISSUE_TEMPLATE.md
```

---

## 🤝 贡献

欢迎提交 Issue 和 PR！详见 [贡献指南](CONTRIBUTING.md)

---

## ⭐ Star History

如果这个项目对你有帮助，请点个 **Star** ⭐ 支持一下！

<p align="center">
  <a href="https://star-history.com/#skbb1v66-png/claude-code-cn&Date">
    <img src="https://api.star-history.com/svg?repos=skbb1v66-png/claude-code-cn&type=Date" alt="Star History" width="600"/>
  </a>
</p>

---

## 📄 许可证

[MIT License](LICENSE) © 2025
