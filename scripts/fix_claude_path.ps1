<#
.SYNOPSIS
    Claude Code 路径修复与代理配置脚本
.DESCRIPTION
    自动检测并修复以下问题：
    1. npm 全局模块路径不在 PATH 中
    2. Claude Code 命令不可用
    3. npm 镜像源未配置（国内优化）
    4. 代理环境变量配置
    5. Electron 镜像源配置
.PARAMETER FixPath
    仅修复 PATH 问题
.PARAMETER SetMirror
    仅设置 npm 镜像源
.PARAMETER SetProxy
    设置代理（需配合 -ProxyUrl 参数）
.PARAMETER ProxyUrl
    代理地址，如 http://127.0.0.1:7890
.PARAMETER All
    执行所有修复（默认）
.EXAMPLE
    .\fix_claude_path.ps1                                # 执行全部修复
    .\fix_claude_path.ps1 -FixPath                        # 仅修复 PATH
    .\fix_claude_path.ps1 -SetProxy -ProxyUrl "http://127.0.0.1:7890"  # 设置代理
#>

param(
    [switch]$FixPath,
    [switch]$SetMirror,
    [switch]$SetProxy,
    [string]$ProxyUrl = "",
    [switch]$All
)

$ErrorActionPreference = "Stop"

# 如果未指定任何开关，默认执行全部
if (-not $FixPath -and -not $SetMirror -and -not $SetProxy -and -not $All) {
    $All = $true
}

function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Step {
    param([string]$Text)
    Write-Host "`n🔧 $Text" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Text)
    Write-Host "✅ $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "⚠️  $Text" -ForegroundColor Yellow
}

# ============================================================================
# 1. 修复 PATH
# ============================================================================
function Repair-Path {
    Write-Step "修复 PATH 环境变量..."

    $fixed = $false

    # 获取 npm 全局路径
    $npmPrefix = npm config get prefix 2>$null
    if ([string]::IsNullOrEmpty($npmPrefix)) {
        $npmPrefix = "$env:APPDATA\npm"
    }

    $npmBinPath = $npmPrefix
    $npmModulesPath = "$env:APPDATA\npm\node_modules"

    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")

    # 检查用户 PATH
    $pathsToAdd = @()
    if ($userPath -notlike "*$npmBinPath*") {
        $pathsToAdd += $npmBinPath
    }
    if ($userPath -notlike "*$npmModulesPath*" -and $npmModulesPath -ne $npmBinPath) {
        $pathsToAdd += $npmModulesPath
    }

    if ($pathsToAdd.Count -gt 0) {
        Write-Warn "发现以下路径未在 PATH 中："
        foreach ($p in $pathsToAdd) {
            Write-Color "    - $p" Yellow
        }

        $newPath = $userPath
        foreach ($p in $pathsToAdd) {
            $newPath = "$newPath;$p"
        }
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Success "已更新用户 PATH 环境变量"

        # 刷新当前会话
        $env:Path = "$machinePath;$newPath"
        $fixed = $true
    }
    else {
        Write-Success "PATH 环境变量正常"
    }

    # 验证 claude 命令
    Write-Step "验证 claude 命令..."
    try {
        $claudePath = Get-Command claude -ErrorAction Stop
        Write-Success "claude 命令可用: $($claudePath.Source)"
    }
    catch {
        Write-Warn "claude 命令未找到，请确认是否已安装 @anthropic-ai/claude-code"
        Write-Color "  安装命令: npm install -g @anthropic-ai/claude-code" Yellow
        Write-Color "  或使用安装脚本: .\setup\install_claude_windows.ps1" Yellow
    }

    return $fixed
}

# ============================================================================
# 2. 设置 npm 镜像
# ============================================================================
function Set-NpmMirror {
    Write-Step "配置 npm 镜像源..."

    # 淘宝 npm 镜像
    $taobaoRegistry = "https://registry.npmmirror.com/"
    $currentRegistry = npm config get registry 2>$null

    if ($currentRegistry -ne $taobaoRegistry) {
        Write-Warn "当前 npm registry: $currentRegistry"
        npm config set registry $taobaoRegistry
        Write-Success "npm registry 已切换至淘宝镜像: $taobaoRegistry"
    }
    else {
        Write-Success "npm registry 已正确配置: $taobaoRegistry"
    }

    # Electron 镜像
    $electronMirror = "https://npmmirror.com/mirrors/electron/"
    npm config set electron_mirror $electronMirror
    [Environment]::SetEnvironmentVariable("ELECTRON_MIRROR", $electronMirror, "User")
    Write-Success "Electron 镜像源已配置"

    # node-sass 镜像（国内常用）
    npm config set sass_binary_site "https://npmmirror.com/mirrors/node-sass/"
    Write-Success "node-sass 镜像源已配置"

    # Python 镜像（node-gyp 依赖）
    npm config set python_mirror "https://npmmirror.com/mirrors/python/"
    Write-Success "Python 镜像源已配置"
}

# ============================================================================
# 3. 设置代理
# ============================================================================
function Set-ProxyConfig {
    param([string]$ProxyUrl)

    Write-Step "配置网络代理..."

    if ([string]::IsNullOrEmpty($ProxyUrl)) {
        Write-Color "请输入代理地址（例如 http://127.0.0.1:7890）:" Yellow
        $ProxyUrl = Read-Host "代理地址"
        if ([string]::IsNullOrEmpty($ProxyUrl)) {
            Write-Warn "未输入代理地址，跳过代理配置"
            return $false
        }
    }

    # 验证代理是否可用
    try {
        $request = [System.Net.WebRequest]::Create($ProxyUrl)
        $request.Timeout = 3000
        $response = $request.GetResponse()
        $response.Close()
        Write-Success "代理地址可访问: $ProxyUrl"
    }
    catch {
        Write-Warn "代理地址不可达: $ProxyUrl（将仍会设置环境变量）"
    }

    # 设置环境变量
    $proxyVars = @("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy")
    foreach ($var in $proxyVars) {
        [Environment]::SetEnvironmentVariable($var, $ProxyUrl, "User")
        Set-Item -Path "env:$var" -Value $ProxyUrl -ErrorAction SilentlyContinue
    }

    # 配置 npm 代理
    npm config set proxy $ProxyUrl
    npm config set https-proxy $ProxyUrl

    Write-Success "代理已配置: $ProxyUrl"
    Write-Color "  环境变量已写入用户变量 (HTTP_PROXY / HTTPS_PROXY)" DarkGray
    Write-Color "  注意：某些终端需要重启才能生效" DarkGray

    return $true
}

# ============================================================================
# 4. 检测 Claude Code settings.json
# ============================================================================
function Check-ClaudeConfig {
    Write-Step "检查 Claude Code 配置文件..."

    $settingsFile = "$HOME\.claude\settings.json"
    if (-not (Test-Path $settingsFile)) {
        Write-Warn "settings.json 不存在"
        $create = Read-Host "是否创建默认配置文件？[Y/n]"
        if ($create -ne "n" -and $create -ne "N") {
            if (-not (Test-Path "$HOME\.claude")) {
                New-Item -ItemType Directory -Path "$HOME\.claude" -Force | Out-Null
            }
            $template = @"
{
  "apiKey": "你的真实API-Key",
  "model": "deepseek-chat",
  "apiBaseUrl": "https://api.deepseek.com/v1"
}
"@
            Set-Content -Path $settingsFile -Value $template -Encoding UTF8
            Write-Success "已创建配置文件: $settingsFile"
            Write-Warn "请编辑该文件并填入你的真实 API Key"
        }
    }
    else {
        Write-Success "配置文件存在: $settingsFile"
        try {
            $content = Get-Content $settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($content.apiKey -eq "你的真实API-Key") {
                Write-Warn "检测到 API Key 仍为占位符，请修改为真实 Key"
            }
            else {
                Write-Success "API Key 已配置"
            }
        }
        catch {
            Write-ErrorMsg "settings.json 格式错误，请检查 JSON 语法"
        }
    }
}

# ============================================================================
# 主流程
# ============================================================================
Write-Color "╔══════════════════════════════════════════════════╗" Cyan
Write-Color "║     Claude Code 环境修复工具 v1.0               ║" Cyan
Write-Color "╚══════════════════════════════════════════════════╝" Cyan

if ($All) {
    Write-Color "  执行全部修复操作" Green
}

if ($FixPath -or $All) {
    Repair-Path
}

if ($SetMirror -or $All) {
    Set-NpmMirror
}

if ($SetProxy -or $All) {
    if ([string]::IsNullOrEmpty($ProxyUrl)) {
        Set-ProxyConfig
    }
    else {
        Set-ProxyConfig -ProxyUrl $ProxyUrl
    }
}

if ($All) {
    Check-ClaudeConfig
}

Write-Color "`n📋 修复完成后的建议操作：" Cyan
Write-Color "  1. 重新打开终端窗口以使 PATH 生效" DarkGray
Write-Color "  2. 运行 claude --version 确认安装" DarkGray
Write-Color "  3. 运行 .\scripts\start_claude.ps1 启动" DarkGray
Write-Color "`n"
