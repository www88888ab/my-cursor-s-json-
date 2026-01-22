#!/bin/bash
# 测试 zsh 配置脚本

echo "=== zsh 配置测试 ==="
echo ""

# 检查 zsh
if command -v zsh &> /dev/null; then
    echo "✓ zsh 已安装: $(zsh --version)"
else
    echo "✗ zsh 未安装"
    exit 1
fi

# 检查 oh-my-zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "✓ oh-my-zsh 已安装"
else
    echo "✗ oh-my-zsh 未安装"
    echo "  运行: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
    exit 1
fi

# 检查 .zshrc
if [ -f "$HOME/.zshrc" ]; then
    echo "✓ .zshrc 文件存在"
    
    # 检查插件配置
    if grep -q "plugins=(" "$HOME/.zshrc"; then
        echo "✓ 插件配置存在"
        grep "^plugins=" "$HOME/.zshrc"
    else
        echo "✗ 未找到插件配置"
    fi
    
    # 检查插件加载
    if grep -q "zsh-syntax-highlighting" "$HOME/.zshrc"; then
        echo "✓ 语法高亮插件已配置"
    else
        echo "✗ 语法高亮插件未配置"
    fi
    
    if grep -q "zsh-autosuggestions" "$HOME/.zshrc"; then
        echo "✓ 自动补全插件已配置"
    else
        echo "✗ 自动补全插件未配置"
    fi
else
    echo "✗ .zshrc 文件不存在"
    exit 1
fi

# 检查插件文件
echo ""
echo "检查插件文件:"
PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"

if [ -d "$PLUGINS_DIR/zsh-syntax-highlighting" ]; then
    echo "✓ zsh-syntax-highlighting 已安装"
else
    echo "✗ zsh-syntax-highlighting 未安装"
fi

if [ -d "$PLUGINS_DIR/zsh-autosuggestions" ]; then
    echo "✓ zsh-autosuggestions 已安装"
else
    echo "✗ zsh-autosuggestions 未安装"
fi

if [ -d "$PLUGINS_DIR/zsh-completions" ]; then
    echo "✓ zsh-completions 已安装"
else
    echo "✗ zsh-completions 未安装"
fi

echo ""
echo "=== 测试完成 ==="
echo ""
echo "如果所有项目都显示 ✓，则可以正常使用！"
echo "如果有 ✗，请按照提示完成配置。"
