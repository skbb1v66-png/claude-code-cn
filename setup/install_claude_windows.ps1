<#
.SYNOPSIS
    Claude Code 中国安装脚本（Windows PowerShell）
.DESCRIPTION
    在中国大陆网络环境下自动安装 Claude Code CLI，支持代理检测、依赖安装、DeepSeek API 配置。
.NOTES
    建议以管理员身份运行此脚本。
    作者: Claude Code China Setup Team
#>

#Requires -Version 5.1

$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "Claude Code 中国安装脚本"

# ---------- 颜色输出函数 ----------
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Step {
    param([string]$Text)
    Write-Host "`n🔧 [$((Get-Date).ToString('HH:mm:ss'))] $Text" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Text)
    Write-Host "✅ $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "⚠️  $Text" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Text)
    Write-Host "❌ $Text" -ForegroundColor Red
}

# ---------- 管理员检测 ----------
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ---------- 网络检测 ----------
function Test-NetworkAccess {
    Write-Step "检测网络连接..."

    $testUrls = @(
        "https://registry.npmjs.org",
        "https://api.github.com",
        "https://www.google.com"
    )

    $proxy = $null
    $hasDirectAccess = $false

    # 检测系统代理
    $proxyKeys = @(
        "HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy"
    )
    foreach ($key in $proxyKeys) {
        $val = [Environment]::GetEnvironmentVariable($key, "User")
        if ([string]::IsNullOrEmpty($val)) {
            $val = [Environment]::GetEnvironmentVariable($key, "Machine")
        }
        if (-not [string]::IsNullOrEmpty($val)) {
            Write-Success "检测到系统代理: $key = $val"
            $proxy = $val
            break
        }
    }

    # 测试直连
    try {
        $request = [System.Net.WebRequest]::Create("https://registry.npmjs.org/")
        $request.Timeout = 5000
        $response = $request.GetResponse()
        $response.Close()
        $hasDirectAccess = $true
        Write-Success "直连 registry.npmjs.org 成功"
    }
    catch {
        Write-Warn "直连 registry.npmjs.org 失败"
    }

    # 测试 GitHub
    try {
        $request = [System.Net.WebRequest]::Create("https://api.github.com/")
        $request.Timeout = 5000
        $response = $request.GetResponse()
        $response.Close()
        Write-Success "直连 api.github.com 成功"
    }
    catch {
        Write-Warn "直连 api.github.com 失败"
    }

    return @{
        HasDirectAccess = $hasDirectAccess
        Proxy = $proxy
    }
}

# ---------- 安装 Node.js ----------
function Install-NodeJS {
    Write-Step "检查 Node.js 环境..."

    $nodeVersion = $null
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Success "Node.js 已安装: $nodeVersion"
            return $true
        }
    }
    catch {
        Write-Warn "未检测到 Node.js"
    }

    Write-Step "正在安装 Node.js (LTS 版本)..."
    Write-Color "  请访问 https://nodejs.org/zh-cn/ 下载并安装 Node.js LTS 版本" Yellow
    Write-Color "  或使用 winget 安装:" Yellow
    Write-Color "  winget install OpenJS.NodeJS.LTS" Yellow

    # 尝试使用 winget
    try {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if ($winget) {
            Write-Color "  正在通过 winget 安装 Node.js..." Yellow
            winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
            # 刷新 PATH
            $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
            $nodeVersion = node --version 2>$null
            if ($nodeVersion) {
                Write-Success "Node.js 安装成功: $nodeVersion"
                return $true
            }
        }
    }
    catch {
        Write-Warn "winget 安装失败，请手动安装 Node.js"
    }

    return $false
}

# ---------- 安装 npm 依赖与国内镜像配置 ----------
function Install-NPMDependencies {
    Write-Step "配置 npm 镜像源..."

    # 设置淘宝镜像源
    Write-Color "  设置 npm 镜像源为 https://registry.npmmirror.com ..." Yellow
    npm config set registry https://registry.npmmirror.com/
    Write-Success "npm 镜像源已设置为淘宝镜像"

    # 设置 Electron 镜像（Claude Code 依赖 Electron）
    Write-Step "配置 Electron 镜像源..."
    $electronMirror = "https://npmmirror.com/mirrors/electron/"
    npm config set electron_mirror $electronMirror
    [Environment]::SetEnvironmentVariable("ELECTRON_MIRROR", $electronMirror, "User")
    Write-Success "Electron 镜像源已配置"

    # 安装 claude-code
    Write-Step "安装 @anthropic-ai/claude-code..."
    try {
        npm install -g @anthropic-ai/claude-code --registry=https://registry.npmmirror.com/
        Write-Success "@anthropic-ai/claude-code 安装成功！"
    }
    catch {
        Write-Warn "通过镜像源安装失败，尝试直连安装..."
        try {
            npm install -g @anthropic-ai/claude-code
            Write-Success "@anthropic-ai/claude-code 安装成功！"
        }
        catch {
            Write-ErrorMsg "安装失败: $_"
            Write-Color "  请检查网络连接后重试" Yellow
            return $false
        }
    }

    return $true
}

# ---------- 配置 settings.json ----------
function Setup-ClaudeConfig {
    Write-Step "配置 Claude Code 设置..."

    $claudeDir = "$HOME\.claude"
    $settingsFile = "$claudeDir\settings.json"

    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
        Write-Success "创建目录: $claudeDir"
    }

    if (Test-Path $settingsFile) {
        Write-Warn "settings.json 已存在，将创建备份"
        $backupFile = "$settingsFile.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $settingsFile $backupFile
        Write-Success "备份已创建: $backupFile"
    }

    # 询问是否配置 DeepSeek API
    $useDeepSeek = $true
    $userInput = Read-Host "`n是否配置 DeepSeek API？（推荐，国内直接可用）[Y/n]"
    if ($userInput -eq "n" -or $userInput -eq "N") {
        $useDeepSeek = $false
    }

    if ($useDeepSeek) {
        $apiKey = Read-Host "请输入你的 DeepSeek API Key（留空则生成占位符）"
        if ([string]::IsNullOrEmpty($apiKey)) {
            $apiKey = "你的真实API-Key"
            Write-Warn "API Key 已设为占位符，请稍后手动修改"
        }

        $config = @{
            "apiKey" = $apiKey
            "model" = "deepseek-chat"
            "apiBaseUrl" = "https://api.deepseek.com/v1"
        } | ConvertTo-Json
    }
    else {
        $config = @{
            "apiKey" = "你的真实API-Key"
        } | ConvertTo-Json
    }

    Set-Content -Path $settingsFile -Value $config -Encoding UTF8
    Write-Success "配置文件已写入: $settingsFile"
    return $true
}

# ---------- 修复 PATH ----------
function Repair-Path {
    Write-Step "检查 PATH 环境变量..."

    $npmGlobalPath = $(npm config get prefix 2>$null)
    if ([string]::IsNullOrEmpty($npmGlobalPath)) {
        $npmGlobalPath = "$env:APPDATA\npm"
    }

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$npmGlobalPath*") {
        Write-Warn "npm 全局路径不在 PATH 中，正在添加..."
        $newPath = "$currentPath;$npmGlobalPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Success "已添加 $npmGlobalPath 到 PATH"
    }
    else {
        Write-Success "npm 全局路径已在 PATH 中"
    }

    # 刷新当前会话的 PATH
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
}

# ---------- 验证安装 ----------
function Test-Installation {
    Write-Step "验证安装..."

    try {
        $version = claude --version 2>$null
        if ($version) {
            Write-Success "Claude Code 安装成功！版本: $version"
            Write-Color "`n🎉 安装完成！现在你可以使用以下命令启动 Claude Code：" Green
            Write-Color "  claude" -ForegroundColor Cyan
            return $true
        }
    }
    catch {
        Write-ErrorMsg "claude 命令未找到"
        Write-Color "  请尝试重新打开终端窗口，然后执行：" Yellow
        Write-Color "  claude --version" Yellow
        return $false
    }
}

# ---------- 主函数 ----------
function Main {
    Write-Color "╔══════════════════════════════════════════════════╗" Cyan
    Write-Color "║     Claude Code 中国安装脚本 v1.0               ║" Cyan
    Write-Color "║     适用于 Windows PowerShell 5.1+              ║" Cyan
    Write-Color "╚══════════════════════════════════════════════════╝" Cyan
    Write-Color "  项目: https://github.com/skbb1v66-png/claude-code-china-setup" DarkGray

    # 管理员检测
    if (-not (Test-Administrator)) {
        Write-Warn "当前未以管理员身份运行"
        Write-Warn "部分操作（如 PATH 修改）可能需要管理员权限"
        $continue = Read-Host "是否继续？[Y/n]"
        if ($continue -eq "n" -or $continue -eq "N") {
            Write-Color "请以管理员身份重新运行此脚本" Yellow
            return
        }
    }

    # 网络检测
    $networkStatus = Test-NetworkAccess
    if (-not $networkStatus.HasDirectAccess -and [string]::IsNullOrEmpty($networkStatus.Proxy)) {
        Write-Warn "未检测到有效网络连接或代理"
        $continue = Read-Host "网络连接可能存在问题，是否继续？[Y/n]"
        if ($continue -eq "n" -or $continue -eq "N") {
            return
        }
    }

    # 安装 Node.js
    Install-NodeJS

    # 安装 npm 依赖
    if (-not (Install-NPMDependencies)) {
        Write-ErrorMsg "依赖安装失败，请检查错误信息后重试"
        return
    }

    # 配置 Claude Code
    Setup-ClaudeConfig

    # 修复 PATH
    Repair-Path

    # 验证安装
    Test-Installation

    Write-Color "`n📚 更多帮助：" Cyan
    Write-Color "  - 安装指南: docs/installation_guide.md" DarkGray
    Write-Color "  - 故障排除: docs/troubleshooting_guide.md" DarkGray
    Write-Color "  - 常见问题: docs/faq.md" DarkGray
    Write-Color "`n💡 提示：如果遇到任何问题，请重新打开终端窗口后重试。`n" Yellow
}

# 执行主函数
Main
