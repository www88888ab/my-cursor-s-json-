#!/bin/bash
# 配置增强的命令行提示符

echo "=== 配置增强的命令行提示符 ==="
echo ""

ZSH_RC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"

# 检查 oh-my-zsh 是否安装
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "检测到 oh-my-zsh，配置 zsh 提示符..."
    
    # 检查是否已有主题配置
    if ! grep -q "^ZSH_THEME=" "$ZSH_RC" 2>/dev/null; then
        # 添加主题配置（使用更漂亮的主题）
        if grep -q "source.*oh-my-zsh" "$ZSH_RC"; then
            sed -i '/source.*oh-my-zsh/i ZSH_THEME="agnoster"' "$ZSH_RC"
            echo "✓ 已设置主题为 agnoster（需要 Powerline 字体）"
        fi
    else
        echo "主题已配置"
    fi
    
    # 添加自定义提示符配置（如果 agnoster 不可用，使用这个）
    if ! grep -q "# 自定义提示符" "$ZSH_RC" 2>/dev/null; then
        cat >> "$ZSH_RC" << 'EOF'

# 自定义提示符（如果主题不可用时的备用方案）
# 显示：用户名@主机名 当前目录 [Git分支] >
autoload -U colors && colors
setopt prompt_subst

# Git 分支信息
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' [%b]'
zstyle ':vcs_info:*' enable git

# 提示符配置
PROMPT='%{$fg[cyan]%}%n@%m%{$reset_color%} %{$fg[yellow]%}%~%{$reset_color%}%{$fg[green]%}${vcs_info_msg_0_}%{$reset_color%}
%{$fg[blue]%}➜%{$reset_color%} '
EOF
        echo "✓ 已添加自定义提示符配置"
    fi
else
    echo "oh-my-zsh 未安装，配置 bash 提示符..."
    
    # 配置 bash 提示符
    if ! grep -q "# 自定义 bash 提示符" "$BASHRC" 2>/dev/null; then
        cat >> "$BASHRC" << 'EOF'

# 自定义 bash 提示符
# 显示：用户名@主机名:当前目录 [Git分支] $
# 获取 Git 分支函数
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ [\1]/'
}

# 设置提示符
export PS1='\[\033[01;36m\]\u@\h\[\033[00m\]:\[\033[01;33m\]\w\[\033[00m\]\[\033[01;32m\]$(parse_git_branch)\[\033[00m\]\n\[\033[01;34m\]\$\[\033[00m\] '
EOF
        echo "✓ 已添加 bash 提示符配置"
    else
        echo "bash 提示符已配置"
    fi
fi

echo ""
echo "=== 配置完成 ==="
echo ""
echo "提示符功能："
echo "  - 显示用户名和主机名"
echo "  - 显示当前目录"
echo "  - 显示 Git 分支（如果在 Git 仓库中）"
echo "  - 彩色显示，更易读"
echo ""
echo "如果使用 zsh 和 oh-my-zsh："
echo "  - 推荐安装 Powerline 字体以支持 agnoster 主题"
echo "  - 或使用自定义提示符（已配置）"
echo ""
echo "请重新加载配置："
echo "  source ~/.zshrc  # 如果使用 zsh"
echo "  或"
echo "  source ~/.bashrc  # 如果使用 bash"
