#!/bin/bash
# oh-my-zsh 安装和配置脚本
# 包括语法高亮和自动补全功能

echo "=== oh-my-zsh 安装和配置 ==="
echo ""

# 检查 zsh 是否安装
if ! command -v zsh &> /dev/null; then
    echo "步骤 1: 安装 zsh 和必要工具..."
    pacman -S --noconfirm zsh curl git
    echo "zsh 安装完成"
    echo ""
fi

# 检查 oh-my-zsh 是否已安装
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "步骤 2: 安装 oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "oh-my-zsh 安装完成"
    echo ""
else
    echo "oh-my-zsh 已安装"
    echo ""
fi

# 安装插件
echo "步骤 3: 安装插件..."
PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"

# 安装 zsh-syntax-highlighting
if [ ! -d "$PLUGINS_DIR/zsh-syntax-highlighting" ]; then
    echo "安装 zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGINS_DIR/zsh-syntax-highlighting"
else
    echo "zsh-syntax-highlighting 已安装"
fi

# 安装 zsh-autosuggestions
if [ ! -d "$PLUGINS_DIR/zsh-autosuggestions" ]; then
    echo "安装 zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$PLUGINS_DIR/zsh-autosuggestions"
else
    echo "zsh-autosuggestions 已安装"
fi

# 安装 zsh-completions
if [ ! -d "$PLUGINS_DIR/zsh-completions" ]; then
    echo "安装 zsh-completions..."
    git clone https://github.com/zsh-users/zsh-completions.git "$PLUGINS_DIR/zsh-completions"
else
    echo "zsh-completions 已安装"
fi

echo ""
echo "步骤 4: 配置 .zshrc..."

# 更新插件列表
if grep -q "^plugins=(" "$HOME/.zshrc"; then
    # 更新现有插件配置
    sed -i 's/^plugins=(.*)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)/' "$HOME/.zshrc"
else
    # 在 oh-my-zsh 初始化之前添加插件配置
    sed -i '/source.*oh-my-zsh/i plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)' "$HOME/.zshrc"
fi

# 添加插件加载代码（如果还没有）
if ! grep -q "zsh-syntax-highlighting.zsh" "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" << 'EOF'

# 加载插件
source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
fpath=($ZSH/custom/plugins/zsh-completions/src $fpath)
EOF
fi

echo ".zshrc 配置完成"
echo ""
echo "=== 配置完成 ==="
echo ""
echo "已安装的插件:"
echo "  - zsh-syntax-highlighting (语法高亮)"
echo "  - zsh-autosuggestions (自动补全建议)"
echo "  - zsh-completions (增强补全)"
echo ""
echo "使用方法:"
echo "  1. 运行: zsh"
echo "  2. 或设置 zsh 为默认 shell: chsh -s /usr/bin/zsh"
echo ""
echo "插件功能:"
echo "  - 语法高亮: 命令会显示不同颜色"
echo "  - 自动补全: 输入时会显示历史命令建议（按右箭头键接受）"
echo "  - 增强补全: 更强大的命令补全功能（按 Tab 键）"
