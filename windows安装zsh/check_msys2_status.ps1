# MSYS2 安装状态检查脚本

$user = $env:USERNAME
$msys2Path = "C:\msys64"
$homePath = "C:\msys64\home\$user"
$bashrc = Join-Path $homePath ".bashrc"
$zshrc = Join-Path $homePath ".zshrc"

Write-Host "=== MSYS2 安装状态检查 ===" -ForegroundColor Cyan
Write-Host ""

# 检查 MSYS2 安装
Write-Host "1. MSYS2 安装: " -NoNewline
if (Test-Path $msys2Path) {
    Write-Host "[已安装]" -ForegroundColor Green
    Write-Host "   安装路径: $msys2Path" -ForegroundColor Gray
} else {
    Write-Host "[未安装]" -ForegroundColor Red
    Write-Host "   请先安装 MSYS2" -ForegroundColor Yellow
    exit 1
}

# 检查 MSYS2 可执行文件
Write-Host ""
Write-Host "2. MSYS2 可执行文件: " -NoNewline
$shellExists = Test-Path "$msys2Path\msys2_shell.cmd"
$ucrtExists = Test-Path "$msys2Path\ucrt64.exe"
if ($shellExists -or $ucrtExists) {
    Write-Host "[存在]" -ForegroundColor Green
    if ($shellExists) { Write-Host "   msys2_shell.cmd: 存在" -ForegroundColor Gray }
    if ($ucrtExists) { Write-Host "   ucrt64.exe: 存在" -ForegroundColor Gray }
} else {
    Write-Host "[不存在]" -ForegroundColor Red
}

# 检查 Home 目录
Write-Host ""
Write-Host "3. MSYS2 Home 目录: " -NoNewline
if (Test-Path $homePath) {
    Write-Host "[存在]" -ForegroundColor Green
    Write-Host "   路径: $homePath" -ForegroundColor Gray
} else {
    Write-Host "[不存在]" -ForegroundColor Yellow
    Write-Host "   需要运行配置脚本创建" -ForegroundColor Yellow
}

# 检查配置文件
Write-Host ""
Write-Host "4. 配置文件:" -ForegroundColor Cyan
Write-Host "   .bashrc: " -NoNewline
if (Test-Path $bashrc) {
    Write-Host "[已创建]" -ForegroundColor Green
    $bashrcSize = (Get-Item $bashrc).Length
    Write-Host "     大小: $bashrcSize 字节" -ForegroundColor Gray
} else {
    Write-Host "[未创建]" -ForegroundColor Yellow
    Write-Host "     需要运行 configure_msys2.ps1" -ForegroundColor Yellow
}

Write-Host "   .zshrc: " -NoNewline
if (Test-Path $zshrc) {
    Write-Host "[已创建]" -ForegroundColor Green
    $zshrcSize = (Get-Item $zshrc).Length
    Write-Host "     大小: $zshrcSize 字节" -ForegroundColor Gray
} else {
    Write-Host "[未创建]" -ForegroundColor Yellow
    Write-Host "     需要运行 configure_msys2.ps1" -ForegroundColor Yellow
}

# 检查 Windows Git 和 Python
Write-Host ""
Write-Host "5. Windows 工具检测:" -ForegroundColor Cyan
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
    Write-Host "   Git: [已找到]" -ForegroundColor Green
    Write-Host "     路径: $($gitCmd.Source)" -ForegroundColor Gray
} else {
    Write-Host "   Git: [未找到]" -ForegroundColor Red
}

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCmd) {
    Write-Host "   Python: [已找到]" -ForegroundColor Green
    Write-Host "     路径: $($pythonCmd.Source)" -ForegroundColor Gray
} else {
    Write-Host "   Python: [未找到]" -ForegroundColor Red
}

# 检查配置脚本
Write-Host ""
Write-Host "6. 配置脚本:" -ForegroundColor Cyan
$configScript = ".\configure_msys2.ps1"
if (Test-Path $configScript) {
    Write-Host "   configure_msys2.ps1: [存在]" -ForegroundColor Green
} else {
    Write-Host "   configure_msys2.ps1: [不存在]" -ForegroundColor Red
}

# 总结
Write-Host ""
Write-Host "=== 总结 ===" -ForegroundColor Cyan
$allGood = $true

if (-not (Test-Path $msys2Path)) {
    Write-Host "[ ] MSYS2 未安装" -ForegroundColor Red
    $allGood = $false
} else {
    Write-Host "[X] MSYS2 已安装" -ForegroundColor Green
}

if (-not (Test-Path $bashrc) -or -not (Test-Path $zshrc)) {
    Write-Host "[ ] 配置文件未创建" -ForegroundColor Yellow
    Write-Host "   请运行: .\configure_msys2.ps1" -ForegroundColor Yellow
    $allGood = $false
} else {
    Write-Host "[X] 配置文件已创建" -ForegroundColor Green
}

if ($allGood) {
    Write-Host ""
    Write-Host "所有配置已完成！" -ForegroundColor Green
    Write-Host "可以使用 .\start_msys2.ps1 启动 MSYS2 终端" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "还需要完成配置步骤" -ForegroundColor Yellow
}
