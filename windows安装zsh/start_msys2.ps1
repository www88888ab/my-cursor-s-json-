# MSYS2 快速启动脚本
# 启动配置好的 MSYS2 终端

$msys2Path = "C:\msys64"

# 检查 MSYS2 是否已安装
if (-not (Test-Path $msys2Path)) {
    Write-Host "错误: 未找到 MSYS2 安装目录: $msys2Path" -ForegroundColor Red
    Write-Host "请先运行 install_msys2.ps1 安装 MSYS2" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== MSYS2 终端启动器 ===" -ForegroundColor Green
Write-Host ""
Write-Host "请选择要启动的终端类型:" -ForegroundColor Cyan
Write-Host "1. MSYS2 MSYS (基础环境)" -ForegroundColor Yellow
Write-Host "2. MSYS2 MinGW 64-bit (推荐用于开发)" -ForegroundColor Yellow
Write-Host "3. MSYS2 UCRT64 (使用 UCRT 运行时)" -ForegroundColor Yellow
Write-Host "4. MSYS2 CLANG64 (使用 Clang 编译器)" -ForegroundColor Yellow
Write-Host "5. 直接启动 UCRT64 (默认)" -ForegroundColor Yellow
Write-Host ""

$choice = Read-Host "请输入选项 (1-5，默认 5)"

switch ($choice) {
    "1" {
        $terminal = "$msys2Path\msys2_shell.cmd"
        $args = "-msys"
    }
    "2" {
        $terminal = "$msys2Path\msys2_shell.cmd"
        $args = "-mingw64"
    }
    "3" {
        $terminal = "$msys2Path\ucrt64.exe"
        $args = ""
    }
    "4" {
        $terminal = "$msys2Path\msys2_shell.cmd"
        $args = "-clang64"
    }
    default {
        $terminal = "$msys2Path\ucrt64.exe"
        $args = ""
    }
}

Write-Host ""
Write-Host "正在启动: $terminal" -ForegroundColor Green

if ($args) {
    Start-Process -FilePath $terminal -ArgumentList $args
} else {
    Start-Process -FilePath $terminal
}

Write-Host "终端已启动！" -ForegroundColor Green
