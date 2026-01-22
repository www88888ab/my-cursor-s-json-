# MSYS2 安装脚本
# 此脚本将下载并安装 MSYS2，并配置其使用 Windows 上的 Git 和 Python

Write-Host "=== MSYS2 安装脚本 ===" -ForegroundColor Green
Write-Host ""

# MSYS2 下载 URL（最新版本）
$msys2Url = "https://github.com/msys2/msys2-installer/releases/download/2024-01-13/msys2-x86_64-latest.exe"
$msys2Installer = "$env:TEMP\msys2-installer.exe"
$msys2Path = "C:\msys64"

# 检查是否已安装
if (Test-Path $msys2Path) {
    Write-Host "检测到 MSYS2 已安装在 $msys2Path" -ForegroundColor Yellow
    $continue = Read-Host "是否要重新安装？(y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "安装已取消" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "步骤 1: 下载 MSYS2 安装程序..." -ForegroundColor Cyan
Write-Host "下载地址: $msys2Url" -ForegroundColor Gray
Write-Host "保存位置: $msys2Installer" -ForegroundColor Gray
Write-Host ""

$download = Read-Host "是否现在下载？(Y/n)"
if ($download -ne "n" -and $download -ne "N") {
    try {
        Invoke-WebRequest -Uri $msys2Url -OutFile $msys2Installer -UseBasicParsing
        Write-Host "下载完成！" -ForegroundColor Green
    } catch {
        Write-Host "下载失败: $_" -ForegroundColor Red
        Write-Host "请手动下载: $msys2Url" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "请手动下载 MSYS2 安装程序到: $msys2Installer" -ForegroundColor Yellow
    Write-Host "或访问: https://www.msys2.org/" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "步骤 2: 安装 MSYS2" -ForegroundColor Cyan
Write-Host "请运行安装程序: $msys2Installer" -ForegroundColor Yellow
Write-Host "安装路径建议: $msys2Path" -ForegroundColor Yellow
Write-Host ""
Write-Host "安装完成后，请运行 configure_msys2.ps1 来配置 MSYS2" -ForegroundColor Green
