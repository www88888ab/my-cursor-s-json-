# MSYS2 下载脚本
$msys2Url = "https://www.msys2.org/release/msys2-x86_64-latest.exe"
$msys2Installer = "$env:TEMP\msys2-installer.exe"

Write-Host "正在从官方源下载 MSYS2..." -ForegroundColor Cyan
Write-Host "下载地址: $msys2Url" -ForegroundColor Gray

try {
    Invoke-WebRequest -Uri $msys2Url -OutFile $msys2Installer -UseBasicParsing
    if (Test-Path $msys2Installer) {
        $fileSize = (Get-Item $msys2Installer).Length / 1MB
        Write-Host "下载成功！" -ForegroundColor Green
        Write-Host "文件大小: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Green
        Write-Host "文件位置: $msys2Installer" -ForegroundColor Green
        Write-Host ""
        Write-Host "下一步: 运行安装程序" -ForegroundColor Yellow
        Write-Host "命令: Start-Process '$msys2Installer'" -ForegroundColor White
    }
} catch {
    Write-Host "自动下载失败: $_" -ForegroundColor Red
    Write-Host "请手动访问: https://www.msys2.org/" -ForegroundColor Yellow
    Write-Host "或访问: https://github.com/msys2/msys2-installer/releases" -ForegroundColor Yellow
}
