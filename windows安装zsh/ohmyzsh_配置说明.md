# oh-my-zsh 安装和配置说明

## ✅ 已完成的步骤

1. **zsh 已安装** - zsh 5.9-4
2. **插件已安装**：
   - ✅ zsh-syntax-highlighting (语法高亮)
   - ✅ zsh-autosuggestions (自动补全建议)
   - ✅ zsh-completions (增强补全)

## 📝 需要完成的配置

### 方法一：在 MSYS2 终端中手动配置（推荐）

1. **打开 MSYS2 终端**（在 Cursor 中按 `Ctrl + ` `）

2. **安装 oh-my-zsh**（如果还没安装）：
   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```
   如果提示是否将 zsh 设为默认 shell，选择 `Y`

3. **配置 .zshrc 文件**：
   ```bash
   # 编辑 .zshrc
   nano ~/.zshrc
   # 或使用 vim
   vim ~/.zshrc
   ```

4. **找到 `plugins=(git)` 这一行，修改为**：
   ```bash
   plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)
   ```

5. **在文件末尾添加以下内容**：
   ```bash
   # 加载插件
   source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
   source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
   fpath=($ZSH/custom/plugins/zsh-completions/src $fpath)
   ```

6. **保存文件并重新加载配置**：
   ```bash
   source ~/.zshrc
   ```

### 方法二：使用自动配置脚本

在 MSYS2 终端中运行：

```bash
# 创建配置脚本
cat > /tmp/configure_zsh.sh << 'EOF'
#!/bin/bash
ZSH_RC="$HOME/.zshrc"

# 更新插件列表
if grep -q "^plugins=(" "$ZSH_RC"; then
    sed -i 's/^plugins=(.*)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)/' "$ZSH_RC"
else
    sed -i '/source.*oh-my-zsh/i plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)' "$ZSH_RC"
fi

# 添加插件加载代码
if ! grep -q "zsh-syntax-highlighting.zsh" "$ZSH_RC"; then
    cat >> "$ZSH_RC" << 'INNER_EOF'

# 加载插件
source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fpath=($ZSH/custom/plugins/zsh-completions/src $fpath)
INNER_EOF
fi

echo "Configuration complete!"
EOF

# 运行配置脚本
bash /tmp/configure_zsh.sh

# 重新加载配置
source ~/.zshrc
```

## 🎨 插件功能说明

### 1. zsh-syntax-highlighting (语法高亮)
- **功能**：命令会根据正确性显示不同颜色
  - ✅ 绿色：正确的命令
  - ❌ 红色：错误的命令
  - 🟡 黄色：需要引用的字符串
- **自动启用**：无需额外操作

### 2. zsh-autosuggestions (自动补全建议)
- **功能**：根据历史命令提供智能建议
- **使用方法**：
  - 输入命令时，会显示灰色建议文本
  - 按 **右箭头键 (→)** 接受建议
  - 按 **Ctrl + →** 接受一个单词
  - 按 **End** 接受到行尾

### 3. zsh-completions (增强补全)
- **功能**：提供更强大的命令补全功能
- **使用方法**：
  - 输入命令时按 **Tab** 键
  - 会显示所有可能的补全选项
  - 支持更多命令的补全

## 🔧 设置 zsh 为默认 shell

如果 oh-my-zsh 安装时没有设置 zsh 为默认 shell，可以手动设置：

```bash
# 查看当前 shell
echo $SHELL

# 设置 zsh 为默认 shell
chsh -s /usr/bin/zsh

# 重新打开终端或运行
exec zsh
```

## 🎯 验证配置

配置完成后，在终端中测试：

```bash
# 1. 检查 zsh 版本
zsh --version

# 2. 检查 oh-my-zsh
echo $ZSH

# 3. 测试语法高亮
# 输入一个错误的命令，应该显示红色
xyz123

# 4. 测试自动补全
# 输入之前用过的命令的开头，应该显示灰色建议

# 5. 测试命令补全
# 输入 git 然后按 Tab，应该显示所有 git 子命令
git <Tab>
```

## 📋 常用 oh-my-zsh 主题

可以修改 `.zshrc` 中的 `ZSH_THEME` 来更换主题：

```bash
# 编辑 .zshrc
nano ~/.zshrc

# 找到 ZSH_THEME 行，修改为：
ZSH_THEME="robbyrussell"  # 默认主题
# 或
ZSH_THEME="agnoster"      # 更漂亮的主题（需要安装 Powerline 字体）
# 或
ZSH_THEME="ys"            # 简洁主题
```

查看所有可用主题：
```bash
ls $ZSH/themes/
```

## 🐛 故障排除

### 插件不工作

1. 检查插件是否安装：
   ```bash
   ls ~/.oh-my-zsh/custom/plugins/
   ```

2. 检查 .zshrc 配置：
   ```bash
   cat ~/.zshrc | grep plugins
   cat ~/.zshrc | grep zsh-syntax-highlighting
   ```

3. 重新加载配置：
   ```bash
   source ~/.zshrc
   ```

### 自动补全建议不显示

1. 检查插件是否正确加载：
   ```bash
   echo $plugins
   ```

2. 确保插件目录存在：
   ```bash
   ls ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
   ```

### 语法高亮不工作

1. 确保插件在 plugins 列表的最后：
   ```bash
   plugins=(git zsh-autosuggestions zsh-completions zsh-syntax-highlighting)
   ```
   注意：`zsh-syntax-highlighting` 必须在最后！

## 📚 更多资源

- oh-my-zsh 官网: https://ohmyz.sh/
- zsh-syntax-highlighting: https://github.com/zsh-users/zsh-syntax-highlighting
- zsh-autosuggestions: https://github.com/zsh-users/zsh-autosuggestions
- zsh-completions: https://github.com/zsh-users/zsh-completions

## ✅ 完成检查清单

- [ ] zsh 已安装
- [ ] oh-my-zsh 已安装
- [ ] 插件已安装（三个插件）
- [ ] .zshrc 已配置插件列表
- [ ] 插件加载代码已添加
- [ ] zsh 已设为默认 shell（可选）
- [ ] 配置已重新加载
- [ ] 功能测试通过

完成以上步骤后，您就可以享受强大的 zsh 命令行体验了！🎉
