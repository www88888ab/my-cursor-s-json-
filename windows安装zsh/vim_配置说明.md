# Vim 安装和配置说明

## ✅ Vim 已安装

Vim 已通过 MSYS2 的 pacman 包管理器安装完成。

## 🚀 使用方法

### 基本使用

```bash
# 打开文件
vim 文件名

# 打开文件并跳转到指定行
vim +行号 文件名

# 打开多个文件
vim 文件1 文件2
```

### Vim 基本操作

#### 进入编辑模式
- 按 `i` - 进入插入模式（在光标前插入）
- 按 `a` - 在光标后插入
- 按 `o` - 在下一行插入

#### 保存和退出
- 按 `Esc` 退出编辑模式
- 输入 `:w` 保存文件
- 输入 `:q` 退出
- 输入 `:wq` 保存并退出
- 输入 `:q!` 强制退出（不保存）

#### 移动光标
- `h` - 左
- `j` - 下
- `k` - 上
- `l` - 右
- `gg` - 跳到文件开头
- `G` - 跳到文件末尾
- `:行号` - 跳转到指定行

#### 搜索
- `/关键词` - 向下搜索
- `?关键词` - 向上搜索
- `n` - 下一个匹配
- `N` - 上一个匹配

## ⚙️ 配置 Vim（可选）

### 创建 .vimrc 配置文件

在 MSYS2 中创建 `~/.vimrc` 文件来配置 vim：

```bash
vim ~/.vimrc
```

### 推荐的 .vimrc 配置

```vim
" 基本设置
set number              " 显示行号
set relativenumber      " 显示相对行号
set tabstop=4           " Tab 键宽度
set shiftwidth=4        " 自动缩进宽度
set expandtab           " 将 Tab 转换为空格
set autoindent          " 自动缩进
set smartindent         " 智能缩进
set showmatch           " 显示匹配的括号
set incsearch           " 增量搜索
set hlsearch            " 高亮搜索结果
set ignorecase          " 搜索时忽略大小写
set smartcase           " 智能大小写
set cursorline          " 高亮当前行
syntax on               " 语法高亮
set encoding=utf-8       " 编码设置
set fileencoding=utf-8  " 文件编码

" 中文支持
set langmenu=zh_CN.UTF-8
language messages zh_CN.UTF-8

" 颜色方案
colorscheme default

" 快捷键映射
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
```

## 📝 常用 Vim 命令

### 编辑命令
- `dd` - 删除当前行
- `yy` - 复制当前行
- `p` - 粘贴
- `u` - 撤销
- `Ctrl+r` - 重做
- `x` - 删除当前字符
- `dw` - 删除一个单词

### 查找替换
- `:%s/旧文本/新文本/g` - 全文替换
- `:%s/旧文本/新文本/gc` - 全文替换（确认）

### 多文件编辑
- `:e 文件名` - 打开新文件
- `:bn` - 下一个文件
- `:bp` - 上一个文件
- `:bd` - 关闭当前文件

## 🎯 快速参考

### 进入 Vim
```bash
vim 文件名
```

### 编辑文件
1. 按 `i` 进入插入模式
2. 编辑内容
3. 按 `Esc` 退出插入模式
4. 输入 `:wq` 保存并退出

### 退出 Vim（不保存）
1. 按 `Esc`
2. 输入 `:q!`

## 💡 提示

- 如果卡在 Vim 中，按 `Esc` 然后输入 `:q!` 强制退出
- 使用 `vimtutor` 命令可以学习 Vim 教程
- 在 MSYS2 中，vim 已经配置好中文支持

## 🔗 相关资源

- Vim 官方文档: https://www.vim.org/docs.php
- Vim 教程: 运行 `vimtutor` 命令
