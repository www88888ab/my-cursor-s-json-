#!/bin/zsh
# 在 zsh 中安装和配置 oh-my-zsh

echo "=== 在 zsh 中安装 oh-my-zsh ==="
echo ""

# 检查是否在 zsh 中
if [ -z "$ZSH_VERSION" ]; then
    echo "错误: 请在 zsh 中运行此脚本"
    exit 1
fi

# 1. 备份
echo "步骤 1: 备份现有配置..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    BACKUP="$HOME/.oh-my-zsh.backup.$(date +%Y%m%d_%H%M%S)"
    cp -r "$HOME/.oh-my-zsh" "$BACKUP"
    echo "已备份到: $BACKUP"
fi

# 2. 卸载旧版本
echo ""
echo "步骤 2: 卸载旧版本..."
rm -rf "$HOME/.oh-my-zsh"

# 3. 安装 oh-my-zsh
echo ""
echo "步骤 3: 安装 oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# 4. 安装插件
echo ""
echo "步骤 4: 安装插件..."
PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"
mkdir -p "$PLUGINS_DIR"

cd "$PLUGINS_DIR"
[ ! -d "zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
[ ! -d "zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions.git
[ ! -d "zsh-completions" ] && git clone https://github.com/zsh-users/zsh-completions.git

echo ""
echo "=== 安装完成 ==="
echo "现在运行: source ~/.zshrc"
