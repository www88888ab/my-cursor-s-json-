# MSYS2 配置脚本
# 配置 MSYS2 使其能够调用 Windows 上的 Git 和 Python

Write-Host "=== MSYS2 配置脚本 ===" -ForegroundColor Green
Write-Host ""

$msys2Path = "C:\msys64"
$msys2Home = "$msys2Path\home\$env:USERNAME"

# 检查 MSYS2 是否已安装
if (-not (Test-Path $msys2Path)) {
    Write-Host "错误: 未找到 MSYS2 安装目录: $msys2Path" -ForegroundColor Red
    Write-Host "请先安装 MSYS2，或修改脚本中的路径" -ForegroundColor Yellow
    exit 1
}

Write-Host "检测到 MSYS2 安装目录: $msys2Path" -ForegroundColor Green
Write-Host ""

# 自动检测 Windows Git 和 Python 路径
Write-Host "正在检测 Windows 上的 Git 和 Python..." -ForegroundColor Cyan

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue

if ($gitCmd) {
    $gitPath = $gitCmd.Source
    $gitDir = Split-Path (Split-Path $gitPath -Parent) -Parent
    Write-Host "找到 Git: $gitPath" -ForegroundColor Green
} else {
    Write-Host "警告: 未在 PATH 中找到 Git" -ForegroundColor Yellow
    $gitPath = "C:\Program Files\Git\cmd\git.exe"
    if (Test-Path $gitPath) {
        $gitDir = "C:\Program Files\Git"
        Write-Host "在默认位置找到 Git: $gitPath" -ForegroundColor Green
    } else {
        Write-Host "未找到 Git，请手动输入路径" -ForegroundColor Yellow
        $gitPath = Read-Host "请输入 Git 的完整路径（或按 Enter 跳过）"
        if ([string]::IsNullOrWhiteSpace($gitPath)) {
            $gitPath = $null
            $gitDir = $null
        } else {
            $gitDir = Split-Path (Split-Path $gitPath -Parent) -Parent
        }
    }
}

if ($pythonCmd) {
    $pythonPath = $pythonCmd.Source
    $pythonDir = Split-Path $pythonPath -Parent
    $pythonScriptsDir = Join-Path $pythonDir "Scripts"
    Write-Host "找到 Python: $pythonPath" -ForegroundColor Green
} else {
    Write-Host "警告: 未在 PATH 中找到 Python" -ForegroundColor Yellow
    $pythonPath = "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python314\python.exe"
    if (Test-Path $pythonPath) {
        $pythonDir = Split-Path $pythonPath -Parent
        $pythonScriptsDir = Join-Path $pythonDir "Scripts"
        Write-Host "在默认位置找到 Python: $pythonPath" -ForegroundColor Green
    } else {
        Write-Host "未找到 Python，请手动输入路径" -ForegroundColor Yellow
        $pythonPath = Read-Host "请输入 Python 的完整路径（或按 Enter 跳过）"
        if ([string]::IsNullOrWhiteSpace($pythonPath)) {
            $pythonPath = $null
            $pythonDir = $null
            $pythonScriptsDir = $null
        } else {
            $pythonDir = Split-Path $pythonPath -Parent
            $pythonScriptsDir = Join-Path $pythonDir "Scripts"
        }
    }
}

# 创建 home 目录（如果不存在）
if (-not (Test-Path $msys2Home)) {
    New-Item -ItemType Directory -Path $msys2Home -Force | Out-Null
    Write-Host "创建 MSYS2 home 目录: $msys2Home" -ForegroundColor Green
}

# 将 Windows 路径转换为 MSYS2 路径格式
function Convert-ToMsysPath {
    param([string]$winPath)
    if ([string]::IsNullOrWhiteSpace($winPath)) { return $null }
    $path = $winPath -replace '^([A-Z]):', '/$1' -replace '\\', '/' -replace '^/([A-Z])', '/$1'
    $path = $path -replace ' ', '\ '
    return $path.ToLower()
}

$gitCmdPath = $null
$pythonExePath = $null
$pythonDirPath = $null
$pythonScriptsPath = $null

if ($gitDir) {
    $gitCmdPath = Convert-ToMsysPath (Join-Path $gitDir "cmd")
}

if ($pythonDir) {
    $pythonExePath = Convert-ToMsysPath $pythonPath
    $pythonDirPath = Convert-ToMsysPath $pythonDir
    $pythonScriptsPath = Convert-ToMsysPath $pythonScriptsDir
}

# 创建 .bashrc 文件
$bashrcPath = "$msys2Home\.bashrc"
$bashrcLines = @(
    "# MSYS2 配置文件 - 使用 Windows 的 Git 和 Python",
    "# 此文件由 configure_msys2.ps1 自动生成",
    ""
)

if ($gitCmdPath) {
    $bashrcLines += @(
        "# 将 Windows Git 路径添加到 PATH",
        ('export PATH="' + $gitCmdPath + ':$PATH"'),
        ""
    )
}

if ($pythonDirPath) {
    $bashrcLines += @(
        "# 将 Windows Python 路径添加到 PATH",
        ('export PATH="' + $pythonDirPath + ':$PATH"'),
        ""
    )
    if ($pythonScriptsPath) {
        $bashrcLines += @(
            ('export PATH="' + $pythonScriptsPath + ':$PATH"'),
            ""
        )
    }
}

if ($gitCmdPath) {
    $gitExePath = Convert-ToMsysPath (Join-Path $gitDir "cmd\git.exe")
    $bashrcLines += @(
        "# Git 别名",
        "alias git='$gitExePath'",
        ""
    )
}

if ($pythonExePath) {
    $bashrcLines += @(
        "# Python 别名",
        "alias python='$pythonExePath'",
        "alias python3='$pythonExePath'",
        ""
    )
    if ($pythonScriptsPath) {
        $pipExePath = "$pythonScriptsPath/pip.exe"
        $bashrcLines += "alias pip='$pipExePath'"
        $bashrcLines += ""
    }
}

if ($gitDir) {
    $gitConfigGlobal = Convert-ToMsysPath "$env:USERPROFILE\.gitconfig"
    $gitConfigSystem = Convert-ToMsysPath (Join-Path $gitDir "etc\gitconfig")
    $bashrcLines += @(
        "# 设置 Git 使用 Windows 的配置",
        ('export GIT_CONFIG_GLOBAL=''' + $gitConfigGlobal + ''''),
        ('export GIT_CONFIG_SYSTEM=''' + $gitConfigSystem + ''''),
        ""
    )
}

$bashrcLines += @(
    "# 显示配置信息",
    'echo "MSYS2 已配置为使用 Windows 的 Git 和 Python"',
    "if command -v git >/dev/null 2>&1; then",
    '    echo "Git: $(git --version)"',
    "fi",
    "if command -v python >/dev/null 2>&1; then",
    '    echo "Python: $(python --version)"',
    "fi"
)

$bashrcContent = $bashrcLines -join "`n"

# 如果 .bashrc 已存在，备份它
if (Test-Path $bashrcPath) {
    $backupPath = "$bashrcPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $bashrcPath $backupPath
    Write-Host "已备份现有 .bashrc 到: $backupPath" -ForegroundColor Yellow
}

# 写入 .bashrc
$bashrcContent | Out-File -FilePath $bashrcPath -Encoding UTF8
Write-Host "已创建/更新 .bashrc: $bashrcPath" -ForegroundColor Green

# 创建 .zshrc（如果用户想使用 zsh）
$zshrcPath = "$msys2Home\.zshrc"
$zshrcLines = @(
    "# MSYS2 Zsh 配置文件 - 使用 Windows 的 Git 和 Python",
    "# 此文件由 configure_msys2.ps1 自动生成",
    ""
)

if ($gitCmdPath) {
    $zshrcLines += @(
        "# 将 Windows Git 路径添加到 PATH",
        ('export PATH="' + $gitCmdPath + ':$PATH"'),
        ""
    )
}

if ($pythonDirPath) {
    $zshrcLines += @(
        "# 将 Windows Python 路径添加到 PATH",
        ('export PATH="' + $pythonDirPath + ':$PATH"'),
        ""
    )
    if ($pythonScriptsPath) {
        $zshrcLines += @(
            ('export PATH="' + $pythonScriptsPath + ':$PATH"'),
            ""
        )
    }
}

if ($gitCmdPath) {
    $gitExePath = Convert-ToMsysPath (Join-Path $gitDir "cmd\git.exe")
    $zshrcLines += @(
        "# Git 别名",
        "alias git='$gitExePath'",
        ""
    )
}

if ($pythonExePath) {
    $zshrcLines += @(
        "# Python 别名",
        "alias python='$pythonExePath'",
        "alias python3='$pythonExePath'",
        ""
    )
    if ($pythonScriptsPath) {
        $pipExePath = "$pythonScriptsPath/pip.exe"
        $zshrcLines += "alias pip='$pipExePath'"
        $zshrcLines += ""
    }
}

if ($gitDir) {
    $gitConfigGlobal = Convert-ToMsysPath "$env:USERPROFILE\.gitconfig"
    $gitConfigSystem = Convert-ToMsysPath (Join-Path $gitDir "etc\gitconfig")
    $zshrcLines += @(
        "# 设置 Git 使用 Windows 的配置",
        ('export GIT_CONFIG_GLOBAL=''' + $gitConfigGlobal + ''''),
        ('export GIT_CONFIG_SYSTEM=''' + $gitConfigSystem + ''''),
        ""
    )
}

$zshrcLines += @(
    "# 显示配置信息",
    'echo "MSYS2 Zsh 已配置为使用 Windows 的 Git 和 Python"',
    "if command -v git >/dev/null 2>&1; then",
    '    echo "Git: $(git --version)"',
    "fi",
    "if command -v python >/dev/null 2>&1; then",
    '    echo "Python: $(python --version)"',
    "fi"
)

$zshrcContent = $zshrcLines -join "`n"
$zshrcContent | Out-File -FilePath $zshrcPath -Encoding UTF8
Write-Host "已创建 .zshrc: $zshrcPath" -ForegroundColor Green

Write-Host ""
Write-Host "=== 配置完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "下一步：" -ForegroundColor Cyan
Write-Host "1. 打开 MSYS2 终端: $msys2Path\msys2_shell.cmd" -ForegroundColor Yellow
Write-Host "2. 或者使用 MSYS2 UCRT64 终端: $msys2Path\ucrt64.exe" -ForegroundColor Yellow
Write-Host "3. 在终端中运行: git --version 和 python --version 来验证" -ForegroundColor Yellow
Write-Host ""
Write-Host "要安装 oh-my-zsh，请在 MSYS2 终端中运行：" -ForegroundColor Cyan
$ohmyzshUrl = "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
$ohmyzshCmd = "sh -c `"`$(curl -fsSL $ohmyzshUrl)`""
Write-Host "  $ohmyzshCmd" -ForegroundColor Yellow
