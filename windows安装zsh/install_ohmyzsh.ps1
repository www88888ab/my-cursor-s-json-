# oh-my-zsh 安装脚本 - PowerShell 包装器
$msys2Path = "C:\msys64"

if (-not (Test-Path $msys2Path)) {
    Write-Host "错误: 未找到 MSYS2" -ForegroundColor Red
    exit 1
}

$scriptPath = Join-Path $PSScriptRoot "install_ohmyzsh_simple.sh"

Write-Host "=== 安装 oh-my-zsh 及插件 ===" -ForegroundColor Green
Write-Host ""
Write-Host "正在在 MSYS2 中运行安装脚本..." -ForegroundColor Cyan
Write-Host ""

# 将脚本复制到 MSYS2 可以访问的位置
$tempScript = "$env:TEMP\install_ohmyzsh.sh"
Copy-Item $scriptPath $tempScript -Force

# 在 MSYS2 中执行
& "$msys2Path\usr\bin\bash.exe" -lc "bash $tempScript"

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "You can now use zsh in Cursor terminal" -ForegroundColor Cyan
