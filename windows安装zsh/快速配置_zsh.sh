#!/bin/bash
# 快速配置 zsh 和 oh-my-zsh

echo "=== 快速配置 zsh ==="
echo ""

# 1. 安装 oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "正在安装 oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "oh-my-zsh 安装完成"
else
    echo "oh-my-zsh 已安装"
fi

# 2. 配置插件
echo ""
echo "正在配置插件..."

ZSH_RC="$HOME/.zshrc"

# 更新插件列表
if grep -q "^plugins=(" "$ZSH_RC"; then
    # 备份原配置
    cp "$ZSH_RC" "$ZSH_RC.backup.$(date +%Y%m%d_%H%M%S)"
    # 更新插件
    sed -i 's/^plugins=(.*)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)/' "$ZSH_RC"
    echo "✓ 已更新插件列表"
else
    # 添加插件配置（在 oh-my-zsh 初始化之前）
    if grep -q "source.*oh-my-zsh" "$ZSH_RC"; then
        sed -i '/source.*oh-my-zsh/i plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)' "$ZSH_RC"
        echo "✓ 已添加插件列表"
    fi
fi

# 添加插件加载代码
if ! grep -q "zsh-syntax-highlighting.zsh" "$ZSH_RC"; then
    cat >> "$ZSH_RC" << 'EOF'

# 加载插件
source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
fpath=($ZSH/custom/plugins/zsh-completions/src $fpath)
EOF
    echo "✓ 已添加插件加载代码"
else
    echo "✓ 插件加载代码已存在"
fi

echo ""
echo "=== 配置完成 ==="
echo ""
echo "现在可以运行: zsh"
echo "或重新打开终端"
