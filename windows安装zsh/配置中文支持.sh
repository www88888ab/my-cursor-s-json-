#!/bin/bash
# 配置 MSYS2 中文支持

echo "=== 配置中文支持 ==="
echo ""

# 1. 安装中文语言包
echo "步骤 1: 安装中文语言包..."
pacman -S --noconfirm glibc-locales 2>/dev/null || echo "语言包可能已安装"

# 2. 配置 locale
echo ""
echo "步骤 2: 配置 locale..."

# 生成中文 locale（如果还没有）
if ! locale -a | grep -q "zh_CN.utf8"; then
    echo "生成中文 locale..."
    # 编辑 /etc/locale.gen 或直接设置
    export LANG=zh_CN.UTF-8
    export LC_ALL=zh_CN.UTF-8
else
    echo "中文 locale 已存在"
fi

# 3. 设置环境变量
echo ""
echo "步骤 3: 配置环境变量..."

# 更新 .bashrc
BASHRC="$HOME/.bashrc"
if ! grep -q "LANG=zh_CN.UTF-8" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" << 'EOF'

# 中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
EOF
    echo "✓ 已更新 .bashrc"
else
    echo "✓ .bashrc 已包含中文配置"
fi

# 更新 .zshrc
ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ]; then
    if ! grep -q "LANG=zh_CN.UTF-8" "$ZSHRC" 2>/dev/null; then
        cat >> "$ZSHRC" << 'EOF'

# 中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
EOF
        echo "✓ 已更新 .zshrc"
    else
        echo "✓ .zshrc 已包含中文配置"
    fi
fi

# 4. 设置当前会话
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8

echo ""
echo "=== 配置完成 ==="
echo ""
echo "当前 locale 设置:"
locale
echo ""
echo "请重新打开终端或运行以下命令使配置生效:"
echo "  source ~/.bashrc"
echo "  或"
echo "  source ~/.zshrc"
