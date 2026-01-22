#!/bin/bash
# 配置 .zshrc 文件，添加插件

USER_HOME="/home/$USER"
ZSH_RC="$USER_HOME/.zshrc"
PLUGINS_DIR="$USER_HOME/.oh-my-zsh/custom/plugins"

echo "Configuring .zshrc..."

# 检查 .zshrc 是否存在
if [ ! -f "$ZSH_RC" ]; then
    echo "Creating .zshrc..."
    cp "$USER_HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSH_RC"
fi

# 更新插件列表
if grep -q "^plugins=(" "$ZSH_RC"; then
    # 更新现有插件配置
    sed -i 's/^plugins=(.*)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)/' "$ZSH_RC"
    echo "Updated plugins list"
else
    # 在 oh-my-zsh 初始化之前添加插件配置
    sed -i '/source.*oh-my-zsh/i plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)' "$ZSH_RC"
    echo "Added plugins list"
fi

# 添加插件加载代码（如果还没有）
if ! grep -q "zsh-syntax-highlighting.zsh" "$ZSH_RC"; then
    cat >> "$ZSH_RC" << 'EOF'

# 加载插件
source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
fpath=($ZSH/custom/plugins/zsh-completions/src $fpath)
EOF
    echo "Added plugin loading code"
fi

echo ".zshrc configuration complete!"
