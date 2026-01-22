# 安装和配置 oh-my-zsh 及其插件
# 包括语法高亮和自动补全功能

$msys2Path = "C:\msys64"
$msys2Home = "$msys2Path\home\$env:USERNAME"

Write-Host "=== oh-my-zsh 安装和配置脚本 ===" -ForegroundColor Green
Write-Host ""

# 检查 MSYS2 是否安装
if (-not (Test-Path $msys2Path)) {
    Write-Host "错误: 未找到 MSYS2 安装目录" -ForegroundColor Red
    exit 1
}

Write-Host "MSYS2 路径: $msys2Path" -ForegroundColor Cyan
Write-Host ""

# 检查 zsh 是否安装
$zshPath = "$msys2Path\usr\bin\zsh.exe"
if (-not (Test-Path $zshPath)) {
    Write-Host "步骤 1: 安装 zsh 和 curl..." -ForegroundColor Cyan
    Write-Host "请在 MSYS2 终端中运行以下命令:" -ForegroundColor Yellow
    Write-Host "  pacman -S zsh curl git" -ForegroundColor White
    Write-Host ""
    Write-Host "或者运行以下命令自动安装:" -ForegroundColor Yellow
    $installCmd = "& '$msys2Path\usr\bin\bash.exe' -lc 'pacman -S --noconfirm zsh curl git'"
    Write-Host $installCmd -ForegroundColor White
    Write-Host ""
    $install = Read-Host "是否现在自动安装 zsh? (Y/n)"
    if ($install -ne "n" -and $install -ne "N") {
        Write-Host "正在安装 zsh..." -ForegroundColor Cyan
        & "$msys2Path\usr\bin\bash.exe" -lc "pacman -S --noconfirm zsh curl git"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "zsh 安装完成" -ForegroundColor Green
        } else {
            Write-Host "安装失败，请手动安装" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "请先安装 zsh，然后重新运行此脚本" -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "zsh 已安装" -ForegroundColor Green
}

Write-Host ""
Write-Host "步骤 2: 安装 oh-my-zsh..." -ForegroundColor Cyan

# 检查 oh-my-zsh 是否已安装
$ohmyzshPath = "$msys2Home\.oh-my-zsh"
if (Test-Path $ohmyzshPath) {
    Write-Host "oh-my-zsh 已安装" -ForegroundColor Green
    $reinstall = Read-Host "是否重新安装? (y/N)"
    if ($reinstall -ne "y" -and $reinstall -ne "Y") {
        Write-Host "跳过 oh-my-zsh 安装" -ForegroundColor Yellow
    } else {
        Write-Host "正在安装 oh-my-zsh..." -ForegroundColor Cyan
        & "$msys2Path\usr\bin\bash.exe" -lc "sh -c `"`$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)`""
    }
} else {
    Write-Host "正在安装 oh-my-zsh..." -ForegroundColor Cyan
    & "$msys2Path\usr\bin\bash.exe" -lc "sh -c `"`$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)`""
}

Write-Host ""
Write-Host "步骤 3: 安装插件..." -ForegroundColor Cyan

# 创建插件目录
$pluginsDir = "$ohmyzshPath\custom\plugins"
if (-not (Test-Path $pluginsDir)) {
    New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
}

# 安装 zsh-syntax-highlighting (语法高亮)
$syntaxHighlightingPath = "$pluginsDir\zsh-syntax-highlighting"
if (-not (Test-Path $syntaxHighlightingPath)) {
    Write-Host "安装 zsh-syntax-highlighting..." -ForegroundColor Yellow
    & "$msys2Path\usr\bin\bash.exe" -lc "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $syntaxHighlightingPath"
} else {
    Write-Host "zsh-syntax-highlighting 已安装" -ForegroundColor Green
}

# 安装 zsh-autosuggestions (自动补全)
$autosuggestionsPath = "$pluginsDir\zsh-autosuggestions"
if (-not (Test-Path $autosuggestionsPath)) {
    Write-Host "安装 zsh-autosuggestions..." -ForegroundColor Yellow
    & "$msys2Path\usr\bin\bash.exe" -lc "git clone https://github.com/zsh-users/zsh-autosuggestions.git $autosuggestionsPath"
} else {
    Write-Host "zsh-autosuggestions 已安装" -ForegroundColor Green
}

# 安装 zsh-completions (增强补全)
$completionsPath = "$pluginsDir\zsh-completions"
if (-not (Test-Path $completionsPath)) {
    Write-Host "安装 zsh-completions..." -ForegroundColor Yellow
    & "$msys2Path\usr\bin\bash.exe" -lc "git clone https://github.com/zsh-users/zsh-completions.git $completionsPath"
} else {
    Write-Host "zsh-completions 已安装" -ForegroundColor Green
}

Write-Host ""
Write-Host "步骤 4: 配置 .zshrc..." -ForegroundColor Cyan

$zshrcPath = "$msys2Home\.zshrc"

# 读取现有配置
$zshrcContent = ""
if (Test-Path $zshrcPath) {
    $zshrcContent = Get-Content $zshrcPath -Raw
}

# 检查是否需要更新插件配置
$needsUpdate = $false

# 检查插件是否在配置中
if ($zshrcContent -notmatch "zsh-syntax-highlighting") {
    $needsUpdate = $true
}

if ($zshrcContent -notmatch "zsh-autosuggestions") {
    $needsUpdate = $true
}

if ($needsUpdate) {
    # 备份现有配置
    if (Test-Path $zshrcPath) {
        $backupPath = "$zshrcPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $zshrcPath $backupPath
        Write-Host "已备份现有 .zshrc" -ForegroundColor Yellow
    }

    # 读取现有内容
    $lines = @()
    if (Test-Path $zshrcPath) {
        $lines = Get-Content $zshrcPath
    }

    # 查找 plugins= 行并更新
    $newLines = @()
    $pluginsUpdated = $false
    
    foreach ($line in $lines) {
        if ($line -match "^plugins=\(.*\)") {
            # 更新插件列表
            $plugins = "git"
            if ($syntaxHighlightingPath -and (Test-Path $syntaxHighlightingPath)) {
                $plugins += " zsh-syntax-highlighting"
            }
            if ($autosuggestionsPath -and (Test-Path $autosuggestionsPath)) {
                $plugins += " zsh-autosuggestions"
            }
            if ($completionsPath -and (Test-Path $completionsPath)) {
                $plugins += " zsh-completions"
            }
            $newLines += "plugins=($plugins)"
            $pluginsUpdated = $true
        } else {
            $newLines += $line
        }
    }

    # 如果没有找到 plugins= 行，添加它
    if (-not $pluginsUpdated) {
        # 查找 oh-my-zsh 初始化行之后插入
        $insertIndex = -1
        for ($i = 0; $i -lt $newLines.Count; $i++) {
            if ($newLines[$i] -match "source.*oh-my-zsh") {
                $insertIndex = $i + 1
                break
            }
        }
        
        if ($insertIndex -ge 0) {
            $plugins = "git"
            if ($syntaxHighlightingPath -and (Test-Path $syntaxHighlightingPath)) {
                $plugins += " zsh-syntax-highlighting"
            }
            if ($autosuggestionsPath -and (Test-Path $autosuggestionsPath)) {
                $plugins += " zsh-autosuggestions"
            }
            if ($completionsPath -and (Test-Path $completionsPath)) {
                $plugins += " zsh-completions"
            }
            $newLines = $newLines[0..($insertIndex-1)] + "plugins=($plugins)" + $newLines[$insertIndex..($newLines.Count-1)]
        }
    }

    # 添加插件加载代码（在文件末尾）
    $pluginLoadCode = @"

# 加载插件
source `$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
source `$ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
fpath=(`$ZSH/custom/plugins/zsh-completions/src `$fpath)
"@

    # 检查是否已包含插件加载代码
    $hasPluginLoad = $false
    foreach ($line in $newLines) {
        if ($line -match "zsh-syntax-highlighting\.zsh") {
            $hasPluginLoad = $true
            break
        }
    }

    if (-not $hasPluginLoad) {
        $newLines += $pluginLoadCode
    }

    # 写入更新后的配置
    $newLines | Out-File -FilePath $zshrcPath -Encoding UTF8
    Write-Host "已更新 .zshrc 配置" -ForegroundColor Green
} else {
    Write-Host ".zshrc 配置已是最新" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== 配置完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "已安装的插件:" -ForegroundColor Cyan
Write-Host "  - zsh-syntax-highlighting (语法高亮)" -ForegroundColor White
Write-Host "  - zsh-autosuggestions (自动补全建议)" -ForegroundColor White
Write-Host "  - zsh-completions (增强补全)" -ForegroundColor White
Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "1. 在 Cursor 中打开 MSYS2 终端 (Ctrl+`)" -ForegroundColor Yellow
Write-Host "2. 如果 zsh 不是默认 shell，运行: zsh" -ForegroundColor Yellow
Write-Host "3. 或者运行: chsh -s /usr/bin/zsh" -ForegroundColor Yellow
Write-Host ""
Write-Host "插件功能:" -ForegroundColor Cyan
Write-Host "  - 语法高亮: 命令会显示不同颜色" -ForegroundColor White
Write-Host "  - 自动补全: 输入时会显示历史命令建议（按右箭头接受）" -ForegroundColor White
Write-Host "  - 增强补全: 更强大的命令补全功能" -ForegroundColor White
