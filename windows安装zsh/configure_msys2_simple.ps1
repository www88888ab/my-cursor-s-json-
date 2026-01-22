# MSYS2 配置脚本 - 简化版
# 配置 MSYS2 使其能够调用 Windows 上的 Git 和 Python

$msys2Path = "C:\msys64"
$msys2Home = "$msys2Path\home\$env:USERNAME"

Write-Host "=== MSYS2 配置脚本 ===" -ForegroundColor Green
Write-Host ""

if (-not (Test-Path $msys2Path)) {
    Write-Host "错误: 未找到 MSYS2 安装目录" -ForegroundColor Red
    exit 1
}

Write-Host "检测到 MSYS2 安装目录: $msys2Path" -ForegroundColor Green
Write-Host ""

# 检测 Git 和 Python
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue

if ($gitCmd) {
    $gitPath = $gitCmd.Source
    $gitDir = Split-Path (Split-Path $gitPath -Parent) -Parent
    Write-Host "找到 Git: $gitPath" -ForegroundColor Green
} else {
    $gitPath = "C:\Program Files\Git\cmd\git.exe"
    if (Test-Path $gitPath) {
        $gitDir = "C:\Program Files\Git"
        Write-Host "找到 Git: $gitPath" -ForegroundColor Green
    } else {
        $gitDir = $null
        Write-Host "未找到 Git" -ForegroundColor Yellow
    }
}

if ($pythonCmd) {
    $pythonPath = $pythonCmd.Source
    $pythonDir = Split-Path $pythonPath -Parent
    $pythonScriptsDir = Join-Path $pythonDir "Scripts"
    Write-Host "找到 Python: $pythonPath" -ForegroundColor Green
} else {
    $pythonPath = "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python314\python.exe"
    if (Test-Path $pythonPath) {
        $pythonDir = Split-Path $pythonPath -Parent
        $pythonScriptsDir = Join-Path $pythonDir "Scripts"
        Write-Host "找到 Python: $pythonPath" -ForegroundColor Green
    } else {
        $pythonDir = $null
        $pythonScriptsDir = $null
        Write-Host "未找到 Python" -ForegroundColor Yellow
    }
}

# 创建 home 目录
if (-not (Test-Path $msys2Home)) {
    New-Item -ItemType Directory -Path $msys2Home -Force | Out-Null
    Write-Host "创建 MSYS2 home 目录" -ForegroundColor Green
}

# 路径转换函数
function Convert-ToMsysPath {
    param([string]$winPath)
    if ([string]::IsNullOrWhiteSpace($winPath)) { return $null }
    $path = $winPath -replace '^([A-Z]):', '/$1' -replace '\\', '/' -replace '^/([A-Z])', '/$1'
    $path = $path -replace ' ', '\ '
    return $path.ToLower()
}

# 转换路径
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

# 创建 .bashrc
$bashrcPath = "$msys2Home\.bashrc"
$bashrcContent = @"
# MSYS2 配置文件 - 使用 Windows 的 Git 和 Python
# 此文件由 configure_msys2.ps1 自动生成

"@

if ($gitCmdPath) {
    $bashrcContent += "# 将 Windows Git 路径添加到 PATH`n"
    $bashrcContent += "export PATH=`"$gitCmdPath`:`$PATH`"`n"
    $bashrcContent += "`n"
}

if ($pythonDirPath) {
    $bashrcContent += "# 将 Windows Python 路径添加到 PATH`n"
    $bashrcContent += "export PATH=`"$pythonDirPath`:`$PATH`"`n"
    if ($pythonScriptsPath) {
        $bashrcContent += "export PATH=`"$pythonScriptsPath`:`$PATH`"`n"
    }
    $bashrcContent += "`n"
}

if ($gitCmdPath) {
    $gitExePath = Convert-ToMsysPath (Join-Path $gitDir "cmd\git.exe")
    $bashrcContent += "# Git 别名`n"
    $bashrcContent += "alias git='$gitExePath'`n"
    $bashrcContent += "`n"
}

if ($pythonExePath) {
    $bashrcContent += "# Python 别名`n"
    $bashrcContent += "alias python='$pythonExePath'`n"
    $bashrcContent += "alias python3='$pythonExePath'`n"
    if ($pythonScriptsPath) {
        $pipExePath = "$pythonScriptsPath/pip.exe"
        $bashrcContent += "alias pip='$pipExePath'`n"
    }
    $bashrcContent += "`n"
}

if ($gitDir) {
    $gitConfigGlobal = Convert-ToMsysPath "$env:USERPROFILE\.gitconfig"
    $gitConfigSystem = Convert-ToMsysPath (Join-Path $gitDir "etc\gitconfig")
    $bashrcContent += "# 设置 Git 使用 Windows 的配置`n"
    $bashrcContent += "export GIT_CONFIG_GLOBAL='$gitConfigGlobal'`n"
    $bashrcContent += "export GIT_CONFIG_SYSTEM='$gitConfigSystem'`n"
    $bashrcContent += "`n"
}

$bashrcContent += "# 显示配置信息`n"
$bashrcContent += 'echo "MSYS2 已配置为使用 Windows 的 Git 和 Python"`n'
$bashrcContent += "if command -v git >/dev/null 2>&1; then`n"
$bashrcContent += '    echo "Git: $(git --version)"`n'
$bashrcContent += "fi`n"
$bashrcContent += "if command -v python >/dev/null 2>&1; then`n"
$bashrcContent += '    echo "Python: $(python --version)"`n'
$bashrcContent += "fi`n"

# 备份现有文件
if (Test-Path $bashrcPath) {
    $backupPath = "$bashrcPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $bashrcPath $backupPath
    Write-Host "已备份现有 .bashrc" -ForegroundColor Yellow
}

# 写入 .bashrc
$bashrcContent | Out-File -FilePath $bashrcPath -Encoding UTF8 -NoNewline
Write-Host "已创建/更新 .bashrc: $bashrcPath" -ForegroundColor Green

# 创建 .zshrc
$zshrcPath = "$msys2Home\.zshrc"
$zshrcContent = @"
# MSYS2 Zsh 配置文件 - 使用 Windows 的 Git 和 Python
# 此文件由 configure_msys2.ps1 自动生成

"@

if ($gitCmdPath) {
    $zshrcContent += "# 将 Windows Git 路径添加到 PATH`n"
    $zshrcContent += "export PATH=`"$gitCmdPath`:`$PATH`"`n"
    $zshrcContent += "`n"
}

if ($pythonDirPath) {
    $zshrcContent += "# 将 Windows Python 路径添加到 PATH`n"
    $zshrcContent += "export PATH=`"$pythonDirPath`:`$PATH`"`n"
    if ($pythonScriptsPath) {
        $zshrcContent += "export PATH=`"$pythonScriptsPath`:`$PATH`"`n"
    }
    $zshrcContent += "`n"
}

if ($gitCmdPath) {
    $gitExePath = Convert-ToMsysPath (Join-Path $gitDir "cmd\git.exe")
    $zshrcContent += "# Git 别名`n"
    $zshrcContent += "alias git='$gitExePath'`n"
    $zshrcContent += "`n"
}

if ($pythonExePath) {
    $zshrcContent += "# Python 别名`n"
    $zshrcContent += "alias python='$pythonExePath'`n"
    $zshrcContent += "alias python3='$pythonExePath'`n"
    if ($pythonScriptsPath) {
        $pipExePath = "$pythonScriptsPath/pip.exe"
        $zshrcContent += "alias pip='$pipExePath'`n"
    }
    $zshrcContent += "`n"
}

if ($gitDir) {
    $gitConfigGlobal = Convert-ToMsysPath "$env:USERPROFILE\.gitconfig"
    $gitConfigSystem = Convert-ToMsysPath (Join-Path $gitDir "etc\gitconfig")
    $zshrcContent += "# 设置 Git 使用 Windows 的配置`n"
    $zshrcContent += "export GIT_CONFIG_GLOBAL='$gitConfigGlobal'`n"
    $zshrcContent += "export GIT_CONFIG_SYSTEM='$gitConfigSystem'`n"
    $zshrcContent += "`n"
}

$zshrcContent += "# 显示配置信息`n"
$zshrcContent += 'echo "MSYS2 Zsh 已配置为使用 Windows 的 Git 和 Python"`n'
$zshrcContent += "if command -v git >/dev/null 2>&1; then`n"
$zshrcContent += '    echo "Git: $(git --version)"`n'
$zshrcContent += "fi`n"
$zshrcContent += "if command -v python >/dev/null 2>&1; then`n"
$zshrcContent += '    echo "Python: $(python --version)"`n'
$zshrcContent += "fi`n"

$zshrcContent | Out-File -FilePath $zshrcPath -Encoding UTF8 -NoNewline
Write-Host "已创建 .zshrc: $zshrcPath" -ForegroundColor Green

Write-Host ""
Write-Host "=== 配置完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "下一步：" -ForegroundColor Cyan
Write-Host "1. 打开 MSYS2 终端: $msys2Path\msys2_shell.cmd" -ForegroundColor Yellow
Write-Host "2. 或者使用 MSYS2 UCRT64 终端: $msys2Path\ucrt64.exe" -ForegroundColor Yellow
Write-Host "3. 在终端中运行: git --version 和 python --version 来验证" -ForegroundColor Yellow
Write-Host ""
Write-Host "要安装 oh-my-zsh，请在 MSYS2 终端中运行安装命令" -ForegroundColor Cyan
