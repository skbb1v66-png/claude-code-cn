<#
.SYNOPSIS
    Claude Code 启动脚本（Windows PowerShell）
.DESCRIPTION
    以不同配置启动 Claude Code CLI，支持 DeepSeek API、自定义代理、电脑控制模式。
.PARAMETER Provider
    API 提供商：deepseek | openai | anthropic（默认 auto-detect）
.PARAMETER ApiKey
    指定 API Key（可选，如不提供则读取 settings.json）
.PARAMETER ComputerUse
    启用电脑控制功能
.PARAMETER Model
    指定模型名称（默认 deepseek-chat）
.PARAMETER Proxy
    指定 HTTP/HTTPS 代理地址
.EXAMPLE
    .\start_claude.ps1 -Provider deepseek -ApiKey "sk-xxxx"
    .\start_claude.ps1 -ComputerUse
    .\start_claude.ps1 -Proxy "http://127.0.0.1:7890"
#>

param(
    [ValidateSet("deepseek", "openai", "anthropic", "")]
    [string]$Provider = "",

    [string]$ApiKey = "",

    [switch]$ComputerUse,

    [string]$Model = "deepseek-chat",

    [string]$Proxy = ""
)

$ErrorActionPreference = "Continue"
$Host.UI.RawUI.WindowTitle = "Claude Code"

# ---------- 颜色函数 ----------
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

# ---------- 检测 settings.json ----------
function Get-ClaudeSettings {
    $settingsFile = "$HOME\.claude\settings.json"
    if (Test-Path $settingsFile) {
        try {
            $content = Get-Content $settingsFile -Raw -Encoding UTF8
            return $content | ConvertFrom-Json
        }
        catch {
            Write-Color "  ⚠️  settings.json 解析失败: $_" Yellow
            return $null
        }
    }
    return $null
}

# ---------- 构建环境变量 ----------
function Build-EnvVars {
    param([string]$Provider, [string]$ApiKey, [string]$Model, [string]$Proxy)

    $envVars = @{}

    # 1. 从 settings.json 读取
    $settings = Get-ClaudeSettings

    # 2. 确定 API Key 优先级：参数 > 环境变量 > settings.json
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $envVars["ANTHROPIC_API_KEY"] = $ApiKey
    }
    elseif ($env:ANTHROPIC_API_KEY) {
        $envVars["ANTHROPIC_API_KEY"] = $env:ANTHROPIC_API_KEY
    }
    elseif ($settings -and $settings.apiKey -and $settings.apiKey -ne "你的真实API-Key") {
        $envVars["ANTHROPIC_API_KEY"] = $settings.apiKey
    }
    else {
        Write-Color "  ⚠️  未设置 API Key，请通过参数 -ApiKey 指定或配置 settings.json" Yellow
    }

    # 3. 确定 API Base URL
    $provider = $Provider
    if ([string]::IsNullOrEmpty($provider)) {
        # 自动检测：扫描 settings.json 中的模型名
        if ($settings -and $settings.apiBaseUrl) {
            $envVars["CLAUDE_API_BASE"] = $settings.apiBaseUrl
            if ($settings.apiBaseUrl -match "deepseek") { $provider = "deepseek" }
        }
        else {
            # 默认为 DeepSeek
            $envVars["CLAUDE_API_BASE"] = "https://api.deepseek.com/v1"
            $provider = "deepseek"
        }
    }
    else {
        switch ($provider) {
            "deepseek" {
                $envVars["CLAUDE_API_BASE"] = "https://api.deepseek.com/v1"
            }
            "openai" {
                $envVars["CLAUDE_API_BASE"] = "https://api.openai.com/v1"
            }
            "anthropic" {
                # 使用官方 API，不设置 Base URL
            }
        }
    }

    # 4. 模型名称
    if ($settings -and $settings.model -and [string]::IsNullOrEmpty($Model)) {
        # 使用 settings.json 中的模型
    }
    else {
        $envVars["CLAUDE_MODEL"] = $Model
    }

    # 5. 代理设置
    if (-not [string]::IsNullOrEmpty($Proxy)) {
        $envVars["HTTP_PROXY"] = $Proxy
        $envVars["HTTPS_PROXY"] = $Proxy
    }

    # 6. 电脑控制
    if ($ComputerUse) {
        $envVars["CLAUDE_COMPUTER_USE"] = "1"
        Write-Color "  🖥️  电脑控制模式已启用" Cyan
    }

    return $envVars
}

# ---------- 主流程 ----------
Write-Color "╔══════════════════════════════════════════════════╗" Cyan
Write-Color "║           Claude Code 启动脚本 v1.0             ║" Cyan
Write-Color "╚══════════════════════════════════════════════════╝" Cyan

Write-Color "`n📋 启动配置：" Cyan
$envVars = Build-EnvVars -Provider $Provider -ApiKey $ApiKey -Model $Model -Proxy $Proxy

if ($envVars["ANTHROPIC_API_KEY"]) {
    $keyMasked = $envVars["ANTHROPIC_API_KEY"].Substring(0, [Math]::Min(8, $envVars["ANTHROPIC_API_KEY"].Length)) + "..."
    Write-Color "  API Key: $keyMasked" Green
}
else {
    Write-Color "  API Key: 未设置" Red
}

if ($envVars["CLAUDE_API_BASE"]) {
    Write-Color "  API Base: $($envVars['CLAUDE_API_BASE'])" Green
}

if ($envVars["CLAUDE_MODEL"]) {
    Write-Color "  Model: $($envVars['CLAUDE_MODEL'])" Green
}

Write-Color "`n🚀 正在启动 Claude Code..." Green

# 设置环境变量并启动
foreach ($key in $envVars.Keys) {
    Set-Item -Path "env:$key" -Value $envVars[$key]
}

# 启动 claude
try {
    $claudePath = Get-Command claude -ErrorAction Stop
    Write-Color "`n" ""
    & $claudePath.Source
}
catch {
    Write-Color "`n❌ 启动失败：claude 命令未找到" Red
    Write-Color "   请确认已安装 @anthropic-ai/claude-code" Yellow
    Write-Color "   或运行 fix_path.ps1 修复 PATH" Yellow
    pause
}
