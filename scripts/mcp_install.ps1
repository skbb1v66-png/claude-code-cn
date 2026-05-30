<#
.SYNOPSIS
    Claude Code MCP（Model Context Protocol）服务器安装脚本
.DESCRIPTION
    自动安装和配置常用的 MCP 服务器，支持文件系统、GitHub、数据库等工具。
    在中国大陆网络环境下自动使用镜像源加速下载。
.PARAMETER List
    列出所有可用的 MCP 服务器
.PARAMETER Install
    安装指定的 MCP 服务器（支持通配符，如 "filesystem","github"）
.PARAMETER All
    安装所有推荐的 MCP 服务器
.PARAMETER Remove
    移除指定的 MCP 服务器
.PARAMETER UpdateConfig
    仅更新 settings.json 中的配置（不安装）
.EXAMPLE
    .\mcp_install.ps1 -List                         # 列出可用 MCP 服务器
    .\mcp_install.ps1 -Install "filesystem","github" # 安装指定服务器
    .\mcp_install.ps1 -All                           # 安装全部推荐服务器
    .\mcp_install.ps1 -Remove "filesystem"           # 移除服务器
#>

param(
    [switch]$List,
    [string[]]$Install = @(),
    [switch]$All,
    [string[]]$Remove = @(),
    [switch]$UpdateConfig
)

$ErrorActionPreference = "Continue"

# ============================================================================
# MCP 服务器定义
# ============================================================================
$MCP_SERVERS = @(
    @{
        Name        = "filesystem"
        DisplayName = "文件系统操作"
        Description = "允许 Claude Code 读写文件、目录操作"
        Package     = "@modelcontextprotocol/server-filesystem"
        Command     = "npx"
        Args        = @("-y", "@modelcontextprotocol/server-filesystem", "/")
        Category    = "基础"
    }
    @{
        Name        = "github"
        DisplayName = "GitHub 集成"
        Description = "管理 Issue、PR、代码审查等 GitHub 操作"
        Package     = "@modelcontextprotocol/server-github"
        Command     = "npx"
        Args        = @("-y", "@modelcontextprotocol/server-github")
        Env         = @{ GITHUB_TOKEN = "" }
        Category    = "开发"
    }
    @{
        Name        = "git"
        DisplayName = "Git 操作"
        Description = "Git 仓库管理、提交、分支操作"
        Package     = "@modelcontextprotocol/server-git"
        Command     = "npx"
        Args        = @("-y", "@modelcontextprotocol/server-git")
        Category    = "开发"
    }
    @{
        Name        = "sqlite"
        DisplayName = "SQLite 数据库"
        Description = "查询和管理 SQLite 数据库"
        Package     = "@modelcontextprotocol/server-sqlite"
        Command     = "npx"
        Args        = @("-y", "@modelcontextprotocol/server-sqlite", "./data.db")
        Category    = "数据库"
    }
    @{
        Name        = "postgres"
        DisplayName = "PostgreSQL 数据库"
        Description = "查询和管理 PostgreSQL 数据库"
        Package     = "@modelcontextprotocol/server-postgres"
        Command     = "npx"
        Args        = @("-y", "@modelcontextprotocol/server-postgres", "postgresql://localhost/mydb")
        Category    = "数据库"
    }
    @{
        Name        = "redis"
        DisplayName = "Redis 缓存"
        Description = "操作 Redis 缓存数据库"
        Package     = "@modelcontextprotocol/server-redis"
        Command     = "npx"
        Args        = @("-y", "@modelcontextprotocol/server-redis", "redis://localhost:6379")
        Category    = "数据库"
    }
    @{
        Name        = "docker"
        DisplayName = "Docker 容器管理"
        Description = "管理 Docker 容器、镜像、网络"
        Package     = "@modelcontextprotocol/server-docker"
        Command     = "npx"
        Args        = @("-y", "@modelcontextprotocol/server-docker")
        Category    = "运维"
    }
    @{
        Name        = "kubernetes"
        DisplayName = "Kubernetes 集群管理"
        Description = "管理 K8s 集群资源"
        Package     = "@modelcontextprotocol/server-kubernetes"
        Command     = "npx"
        Args        = @("-y", "@modelcontextprotocol/server-kubernetes")
        Category    = "运维"
    }
    @{
        Name        = "puppeteer"
        DisplayName = "浏览器自动化"
        Description = "网页截图、PDF 生成、页面操作"
        Package     = "@modelcontextprotocol/server-puppeteer"
        Command     = "npx"
        Args        = @("-y", "@modelcontextprotocol/server-puppeteer")
        Category    = "工具"
    }
    @{
        Name        = "memory"
        DisplayName = "记忆存储"
        Description = "基于知识图谱的持久化记忆"
        Package     = "@modelcontextprotocol/server-memory"
        Command     = "npx"
        Args        = @("-y", "@modelcontextprotocol/server-memory")
        Category    = "工具"
    }
)

# ============================================================================
# 工具函数
# ============================================================================
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
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

# ============================================================================
# 获取当前 MCP 配置
# ============================================================================
function Get-MCPConfig {
    $settingsFile = "$HOME\.claude\settings.json"
    $mcpConfig = @{}

    if (Test-Path $settingsFile) {
        try {
            $settings = Get-Content $settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($settings.mcpServers) {
                $mcpConfig = $settings.mcpServers
            }
        }
        catch {
            Write-Warn "settings.json 解析失败"
        }
    }

    return $mcpConfig
}

# ============================================================================
# 保存 MCP 配置到 settings.json
# ============================================================================
function Save-MCPConfig {
    param(
        [hashtable]$NewServers,
        [string[]]$RemoveServers
    )

    $settingsFile = "$HOME\.claude\settings.json"

    if (-not (Test-Path "$HOME\.claude")) {
        New-Item -ItemType Directory -Path "$HOME\.claude" -Force | Out-Null
    }

    # 读取现有配置
    $settings = @{}
    if (Test-Path $settingsFile) {
        try {
            $content = Get-Content $settingsFile -Raw -Encoding UTF8
            $settings = $content | ConvertFrom-Json | ForEach-Object {
                $obj = @{}
                $_.PSObject.Properties | ForEach-Object { $obj[$_.Name] = $_.Value }
                $obj
            }
        }
        catch {
            Write-Warn "无法读取现有 settings.json，将创建新文件"
        }
    }

    # 确保 mcpServers 字段存在
    if (-not $settings.ContainsKey("mcpServers")) {
        $settings["mcpServers"] = @{}
    }

    # 移除指定的服务器
    foreach ($name in $RemoveServers) {
        if ($settings["mcpServers"].ContainsKey($name)) {
            $settings["mcpServers"].Remove($name)
            Write-Success "已移除 MCP 服务器: $name"
        }
    }

    # 添加/更新服务器
    foreach ($name in $NewServers.Keys) {
        $settings["mcpServers"][$name] = $NewServers[$name]
    }

    # 序列化为 JSON（保证格式正确）
    $jsonString = $settings | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsFile -Value $jsonString -Encoding UTF8

    Write-Success "MCP 配置已更新: $settingsFile"
}

# ============================================================================
# 列出 MCP 服务器
# ============================================================================
function Show-MCPList {
    $currentConfig = Get-MCPConfig

    Write-Color "`n📋 可用的 MCP 服务器：" Cyan
    Write-Color ("=" * 70) DarkGray

    $categories = $MCP_SERVERS | Group-Object Category

    foreach ($cat in $categories) {
        Write-Color "`n[${($cat.Name)}]" Yellow
        foreach ($server in $cat.Group) {
            $installed = $currentConfig.ContainsKey($server.Name)
            $status = if ($installed) { "✅ 已安装" } else { "⬜ 未安装" }
            Write-Color "  ${($server.Name)} - ${($server.DisplayName)}" Green
            Write-Color "    描述: ${($server.Description)}" DarkGray
            Write-Color "    状态: ${status}" DarkGray
        }
    }
    Write-Color ""
}

# ============================================================================
# 安装 MCP 服务器
# ============================================================================
function Install-MCPServers {
    param([string[]]$ServerNames)

    if ($ServerNames.Count -eq 0) { return }

    $newServers = @{}
    $npmRegistry = "https://registry.npmmirror.com/"

    foreach ($name in $ServerNames) {
        $server = $MCP_SERVERS | Where-Object { $_.Name -eq $name }
        if (-not $server) {
            Write-Warn "未知的 MCP 服务器: $name"
            continue
        }

        Write-Color "`n📦 正在安装 ${($server.DisplayName)} (${($server.Package)})..." Cyan

        # 安装 npm 包
        $installArgs = @("install", "-g", $server.Package, "--registry=$npmRegistry")
        Write-Color "  执行: npm $($installArgs -join ' ')" DarkGray

        try {
            $process = Start-Process -FilePath "npm" -ArgumentList $installArgs -NoNewWindow -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-Success "npm 包安装成功: ${($server.Package)}"

                # 构建 MCP 配置项
                $mcpEntry = @{
                    command = $server.Command
                    args    = $server.Args
                }

                # 添加环境变量（如果有）
                if ($server.Env) {
                    $envTable = @{}
                    foreach ($key in $server.Env.Keys) {
                        if ([string]::IsNullOrEmpty($server.Env[$key])) {
                            $val = Read-Host "  请输入 $key（留空跳过）"
                            if (-not [string]::IsNullOrEmpty($val)) {
                                $envTable[$key] = $val
                            }
                        }
                        else {
                            $envTable[$key] = $server.Env[$key]
                        }
                    }
                    if ($envTable.Count -gt 0) {
                        $mcpEntry["env"] = $envTable
                    }
                }

                $newServers[$name] = $mcpEntry
                Write-Success "MCP 服务器配置已准备: ${($server.DisplayName)}"
            }
            else {
                Write-ErrorMsg "npm 包安装失败: ${($server.Package)}"
            }
        }
        catch {
            Write-ErrorMsg "安装失败: $_"
        }
    }

    # 保存到 settings.json
    if ($newServers.Count -gt 0) {
        Save-MCPConfig -NewServers $newServers
    }
}

# ============================================================================
# 移除 MCP 服务器配置
# ============================================================================
function Remove-MCPServers {
    param([string[]]$ServerNames)

    foreach ($name in $ServerNames) {
        $server = $MCP_SERVERS | Where-Object { $_.Name -eq $name }
        if ($server) {
            Write-Color "🗑️  正在移除 ${($server.DisplayName)}..." Yellow
            # 卸载 npm 全局包
            try {
                npm uninstall -g $server.Package 2>$null
                Write-Success "npm 包已卸载: ${($server.Package)}"
            }
            catch {
                Write-Warn "npm 包卸载失败（可能已被移除）"
            }
        }
    }

    Save-MCPConfig -RemoveServers $ServerNames
}

# ============================================================================
# 主流程
# ============================================================================
Write-Color "╔══════════════════════════════════════════════════╗" Cyan
Write-Color "║     MCP 服务器管理工具 v1.0                     ║" Cyan
Write-Color "║     Model Context Protocol Installer            ║" Cyan
Write-Color "╚══════════════════════════════════════════════════╝" Cyan

if ($List) {
    Show-MCPList
    return
}

if ($UpdateConfig) {
    Write-Step "更新 MCP 配置..."
    # 读取当前已安装的 npm 全局包，自动检测 MCP
    $globalPackages = npm list -g --depth=0 2>$null
    $detected = @()
    foreach ($server in $MCP_SERVERS) {
        if ($globalPackages -match $server.Package) {
            $detected += $server.Name
            Write-Success "检测到已安装: ${($server.DisplayName)}"
        }
    }
    if ($detected.Count -gt 0) {
        Install-MCPServers -ServerNames $detected
    }
    else {
        Write-Warn "未检测到已安装的 MCP 服务器包"
    }
    return
}

if ($Remove.Count -gt 0) {
    Remove-MCPServers -ServerNames $Remove
    return
}

if ($All) {
    Write-Color "`n📦 即将安装所有推荐的 MCP 服务器..." Cyan
    $names = $MCP_SERVERS | ForEach-Object { $_.Name }
    Install-MCPServers -ServerNames $names
    return
}

if ($Install.Count -gt 0) {
    Install-MCPServers -ServerNames $Install
    return
}

# 如果没有指定参数，显示交互式菜单
Show-MCPList
Write-Color "`n💡 用法示例：" Cyan
Write-Color "  # 列出所有 MCP 服务器" DarkGray
Write-Color "  .\mcp_install.ps1 -List" DarkGray
Write-Color "  # 安装指定服务器" DarkGray
Write-Color "  .\mcp_install.ps1 -Install filesystem,github" DarkGray
Write-Color "  # 安装全部" DarkGray
Write-Color "  .\mcp_install.ps1 -All" DarkGray
Write-Color "  # 从配置中移除" DarkGray
Write-Color "  .\mcp_install.ps1 -Remove filesystem" DarkGray
Write-Color "  # 自动检测并更新配置" DarkGray
Write-Color "  .\mcp_install.ps1 -UpdateConfig" DarkGray
