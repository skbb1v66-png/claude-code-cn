# 贡献指南

感谢你考虑为 Claude Code 中国安装配置指南做出贡献！

## 贡献方式

### 🐛 报告 Bug

如果你遇到了问题，请 [提交 Issue](https://github.com/skbb1v66-png/claude-code-cn/issues/new) 并包含：

- 操作系统版本
- Node.js / npm 版本
- 完整的错误信息
- 已尝试的解决方法

### ✨ 提交功能请求

欢迎提交改进建议！请在 Issue 中清晰描述：

- 你想要的功能
- 使用场景
- 预期的效果

### 📖 改进文档

文档中的错别字、翻译问题、或更好的解释方式都欢迎指正。

### 🔧 提交代码

1. Fork 本仓库
2. 创建你的特性分支：`git checkout -b feature/your-feature`
3. 提交你的更改：`git commit -m 'feat: add some feature'`
4. 推送到分支：`git push origin feature/your-feature`
5. 提交 Pull Request

## 开发指南

### 项目结构

```
claude-code-cn/
├── setup/          # 安装脚本
├── scripts/        # 工具脚本
├── docs/           # 文档
└── .github/        # GitHub 配置文件
```

### 脚本规范

- **PowerShell 脚本**：使用 `#Requires -Version 5.1`，遵循 PS 最佳实践
- **Shell 脚本**：使用 `#!/bin/bash`，兼容 POSIX，避免 bashism
- **错误处理**：提供友好的中文错误提示
- **颜色输出**：统一使用 `Write-Color` / `echo -e` + 颜色常量

### 提交信息规范

参考 [Conventional Commits](https://www.conventionalcommits.org/)：

```
feat: 新功能
fix: Bug 修复
docs: 文档变更
style: 代码格式调整
refactor: 重构
test: 测试相关
chore: 构建/工具链变更
```

## 行为准则

请保持友善和专业的交流氛围。欢迎任何形式的贡献，无论大小。
