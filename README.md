# Claude Code 中国安装配置指南 🇨🇳

<p align="center">
  <img src="docs/images/claude-code-screenshot.png" alt="Claude Code 运行截图" width="720"/>
</p>

<p align="center">
  <a href="https://github.com/skbb1v66-png/claude-code-cn/stargazers">
    <img src="https://img.shields.io/github/stars/skbb1v66-png/claude-code-cn?style=social" alt="stars"/>
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/skbb1v66-png/claude-code-cn?style=social" alt="license"/>
  </a>
</p>

国内网络环境下安装 Claude Code 会遇到各种奇奇怪怪的问题：npm 源连不上、安装脚本卡住、API 超时……这个仓库把常见的坑都踩了一遍，整理成脚本和文档，帮你省点时间。

## 功能

- 一键安装 Claude Code CLI（Windows + WSL/Linux）
- 自动配置国内镜像源 / 代理
- 集成 DeepSeek API（国内直连，不用翻墙）
- 常见问题修复脚本

## 快速开始

### Windows

以管理员身份打开 PowerShell，执行：

```powershell
irm https://raw.githubusercontent.com/skbb1v66-png/claude-code-cn/main/setup/install_claude_windows.ps1 | iex
```

或者：

```powershell
git clone https://github.com/skbb1v66-png/claude-code-cn.git
cd claude-code-cn
.\setup\install_claude_windows.ps1
```

### WSL / Linux

```bash
git clone https://github.com/skbb1v66-png/claude-code-cn.git
cd claude-code-cn
chmod +x setup/install_claude_wsl.sh && ./setup/install_claude_wsl.sh
```

## 使用 DeepSeek API

Claude Code 默认用 Anthropic 的 API，国内访问延迟高。换成 DeepSeek 会好很多：

```powershell
.\scripts\start_claude.ps1 -Provider deepseek -ApiKey "你的Key"
```

```bash
./scripts/start_claude.sh -p deepseek -k "你的Key"
```

API Key 去 [platform.deepseek.com](https://platform.deepseek.com/) 注册就有。

也可以手动改配置：编辑 `~/.claude/settings.json`

```json
{
  "apiKey": "你的DeepSeek API Key",
  "model": "deepseek-chat",
  "apiBaseUrl": "https://api.deepseek.com/v1"
}
```

## 目录结构

```
claude-code-cn/
├── README.md
├── setup/              # 安装脚本
├── scripts/            # 工具脚本
├── docs/               # 文档
│   ├── installation_guide.md
│   ├── troubleshooting_guide.md
│   └── faq.md
└── .github/            # GitHub 配置
```

## 贡献

提交 Issue 或 PR 都可以，欢迎一起完善。

## License

MIT
