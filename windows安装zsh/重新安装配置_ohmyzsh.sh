#!/bin/bash
# 在 zsh 下重新安装 oh-my-zsh 并配置所有功能

echo "=== 重新安装和配置 oh-my-zsh ==="
echo ""

# 检查是否在 zsh 中运行
if [ -z "$ZSH_VERSION" ]; then
    echo "错误: 请在 zsh 中运行此脚本"
    echo "运行: zsh"
    exit 1
fi

echo "当前 shell: zsh $ZSH_VERSION"
echo ""

# 1. 备份现有配置
echo "步骤 1: 备份现有配置..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    BACKUP_DIR="$HOME/.oh-my-zsh.backup.$(date +%Y%m%d_%H%M%S)"
    cp -r "$HOME/.oh-my-zsh" "$BACKUP_DIR"
    echo "✓ 已备份到: $BACKUP_DIR"
fi

if [ -f "$HOME/.zshrc" ]; then
    BACKUP_RC="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$HOME/.zshrc" "$BACKUP_RC"
    echo "✓ 已备份 .zshrc 到: $BACKUP_RC"
fi

echo ""

# 2. 卸载旧版本（如果存在）
echo "步骤 2: 卸载旧版本 oh-my-zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
    echo "✓ 已删除旧版本"
fi

echo ""

# 3. 安装 oh-my-zsh
echo "步骤 3: 安装 oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
if [ $? -eq 0 ]; then
    echo "✓ oh-my-zsh 安装完成"
else
    echo "✗ oh-my-zsh 安装失败"
    exit 1
fi

echo ""

# 4. 安装插件
echo "步骤 4: 安装插件..."
PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"
mkdir -p "$PLUGINS_DIR"

# 安装 zsh-syntax-highlighting
if [ ! -d "$PLUGINS_DIR/zsh-syntax-highlighting" ]; then
    echo "安装 zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGINS_DIR/zsh-syntax-highlighting"
    echo "✓ zsh-syntax-highlighting 安装完成"
else
    echo "✓ zsh-syntax-highlighting 已存在"
fi

# 安装 zsh-autosuggestions
if [ ! -d "$PLUGINS_DIR/zsh-autosuggestions" ]; then
    echo "安装 zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$PLUGINS_DIR/zsh-autosuggestions"
    echo "✓ zsh-autosuggestions 安装完成"
else
    echo "✓ zsh-autosuggestions 已存在"
fi

# 安装 zsh-completions
if [ ! -d "$PLUGINS_DIR/zsh-completions" ]; then
    echo "安装 zsh-completions..."
    git clone https://github.com/zsh-users/zsh-completions.git "$PLUGINS_DIR/zsh-completions"
    echo "✓ zsh-completions 安装完成"
else
    echo "✓ zsh-completions 已存在"
fi

echo ""

# 5. 配置 .zshrc
echo "步骤 5: 配置 .zshrc..."

# 创建新的 .zshrc 文件
cat > "$HOME/.zshrc" << 'ZSH_RC_EOF'
# MSYS2 Zsh 配置文件 - 使用 Windows 的 Git 和 Python
# 此文件由重新安装配置脚本生成

# 检查是否在 zsh 中运行
if [ -z "$ZSH_VERSION" ]; then
    echo "警告: .zshrc 是 zsh 专用配置文件，请在 zsh 中运行" >&2
    return 2>/dev/null || exit 0
fi

# 将 Windows Git 路径添加到 PATH
export PATH="/c/program\ files/git/cmd:$PATH"

# 将 Windows Python 路径添加到 PATH
export PATH="/c/users/dev-yangyi/appdata/local/programs/python/python314:$PATH"
export PATH="/c/users/dev-yangyi/appdata/local/programs/python/python314/scripts:$PATH"

# Git 别名
alias git='/c/program\ files/git/cmd/git.exe'

# Python 别名
alias python='/c/users/dev-yangyi/appdata/local/programs/python/python314/python.exe'
alias python3='/c/users/dev-yangyi/appdata/local/programs/python/python314/python.exe'
alias pip='/c/users/dev-yangyi/appdata/local/programs/python/python314/scripts/pip.exe'

# 设置 Git 使用 Windows 的配置
export GIT_CONFIG_GLOBAL='/c/users/dev-yangyi/.gitconfig'
export GIT_CONFIG_SYSTEM='/c/program\ files/git/etc/gitconfig'

# 中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8

# oh-my-zsh 配置
export ZSH="$HOME/.oh-my-zsh"

# 设置主题（使用简洁的主题，不需要特殊字体）
ZSH_THEME="robbyrussell"

# 配置插件
plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-completions
)

# 加载 oh-my-zsh
source $ZSH/oh-my-zsh.sh

# 加载插件（确保在 oh-my-zsh 之后加载）
source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
fpath=($ZSH/custom/plugins/zsh-completions/src $fpath)

# 自定义增强提示符
# 显示：用户名@主机名 当前目录 [Git分支] >
autoload -U colors && colors
setopt prompt_subst

# Git 分支信息（如果 oh-my-zsh 的 git 插件没有显示）
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' [%b]'
zstyle ':vcs_info:*' enable git

# 如果使用默认主题，可以自定义提示符
# 或者保持默认的 robbyrussell 主题

# 显示配置信息（仅在首次加载时）
if [ -z "$OMZ_LOADED" ]; then
    echo "MSYS2 Zsh 已配置为使用 Windows 的 Git 和 Python"
    if command -v git >/dev/null 2>&1; then
        echo "Git: $(git --version)"
    fi
    if command -v python >/dev/null 2>&1; then
        echo "Python: $(python --version)"
    fi
    export OMZ_LOADED=1
fi
ZSH_RC_EOF

echo "✓ .zshrc 配置完成"

echo ""
echo "=== 配置完成 ==="
echo ""
echo "已安装和配置："
echo "  ✓ oh-my-zsh"
echo "  ✓ zsh-syntax-highlighting (语法高亮)"
echo "  ✓ zsh-autosuggestions (自动补全建议)"
echo "  ✓ zsh-completions (增强补全)"
echo "  ✓ 自定义提示符"
echo "  ✓ Windows Git 和 Python 配置"
echo "  ✓ 中文支持"
echo ""
echo "现在运行: source ~/.zshrc"
echo "或重新打开终端"
