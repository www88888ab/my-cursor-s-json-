# MSYS2 安装和配置指南

本指南将帮助您在 Windows 上安装 MSYS2，并配置其使用 Windows 上已安装的 Git 和 Python。

## 系统信息

- **Git 路径**: `C:\Program Files\Git\cmd\git.exe`
- **Python 路径**: `C:\Users\dev-yangyi\AppData\Local\Programs\Python\Python314\python.exe`
- **MSYS2 安装路径**: `C:\msys64` (默认)

## 安装步骤

### 方法一：使用提供的脚本（推荐）

1. **运行安装脚本**:
   ```powershell
   .\install_msys2.ps1
   ```
   脚本会：
   - 下载 MSYS2 安装程序
   - 提供安装指导

2. **运行安装程序**:
   - 双击下载的 `msys2-installer.exe`
   - 按照向导完成安装
   - 建议使用默认安装路径 `C:\msys64`

3. **配置 MSYS2**:
   ```powershell
   .\configure_msys2.ps1
   ```
   脚本会：
   - 检测 Windows 上的 Git 和 Python
   - 创建配置文件，使 MSYS2 能够调用它们
   - 配置 `.bashrc` 和 `.zshrc`

### 方法二：手动安装

1. **下载 MSYS2**:
   - 访问 https://www.msys2.org/
   - 下载最新版本的安装程序
   - 或直接下载: https://github.com/msys2/msys2-installer/releases

2. **安装 MSYS2**:
   - 运行安装程序
   - 选择安装路径（默认: `C:\msys64`）
   - 完成安装

3. **首次启动和更新**:
   - 打开 `MSYS2 MSYS` 终端
   - 运行以下命令更新系统:
     ```bash
     pacman -Syu
     ```
   - 如果提示关闭终端，关闭后重新打开，再次运行:
     ```bash
     pacman -Syu
     ```

## 配置 MSYS2 使用 Windows 的 Git 和 Python

### 自动配置（推荐）

运行配置脚本：
```powershell
.\configure_msys2.ps1
```

### 手动配置

编辑 `C:\msys64\home\<你的用户名>\.bashrc`，添加以下内容：

```bash
# 将 Windows 路径添加到 PATH
export PATH="/c/Program Files/Git/cmd:$PATH"
export PATH="/c/Users/dev-yangyi/AppData/Local/Programs/Python/Python314:$PATH"
export PATH="/c/Users/dev-yangyi/AppData/Local/Programs/Python/Python314/Scripts:$PATH"

# 创建别名
alias git='/c/Program\ Files/Git/cmd/git.exe'
alias python='/c/Users/dev-yangyi/AppData/Local/Programs/Python/Python314/python.exe'
alias python3='/c/Users/dev-yangyi/AppData/Local/Programs/Python/Python314/python.exe'
alias pip='/c/Users/dev-yangyi/AppData/Local/Programs/Python/Python314/Scripts/pip.exe'
```

**注意**: 请根据您的实际路径修改上述配置。

## 验证配置

打开 MSYS2 终端，运行以下命令验证：

```bash
# 检查 Git
git --version

# 检查 Python
python --version
python3 --version

# 检查 pip
pip --version
```

## 安装 oh-my-zsh

1. **安装 zsh** (如果还没有):
   ```bash
   pacman -S zsh
   ```

2. **安装 oh-my-zsh**:
   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

3. **配置 zsh 使用 Windows 的 Git 和 Python**:
   
   编辑 `~/.zshrc`，在文件末尾添加：
   ```bash
   # 使用 Windows 的 Git 和 Python
   export PATH="/c/Program Files/Git/cmd:$PATH"
   export PATH="/c/Users/dev-yangyi/AppData/Local/Programs/Python/Python314:$PATH"
   export PATH="/c/Users/dev-yangyi/AppData/Local/Programs/Python/Python314/Scripts:$PATH"
   
   alias git='/c/Program\ Files/Git/cmd/git.exe'
   alias python='/c/Users/dev-yangyi/AppData/Local/Programs/Python/Python314/python.exe'
   alias python3='/c/Users/dev-yangyi/AppData/Local/Programs/Python/Python314/python.exe'
   alias pip='/c/Users/dev-yangyi/AppData/Local/Programs/Python/Python314/Scripts/pip.exe'
   ```

4. **重新加载配置**:
   ```bash
   source ~/.zshrc
   ```

## 常用 MSYS2 终端类型

MSYS2 提供多种终端环境：

- **MSYS2 MSYS**: 基础环境，适合系统维护
- **MSYS2 MinGW 64-bit**: 64位 MinGW 环境
- **MSYS2 UCRT64**: 推荐用于开发（使用 UCRT 运行时）
- **MSYS2 CLANG64**: 使用 Clang 编译器

启动方式：
- 从开始菜单启动
- 或直接运行: `C:\msys64\msys2_shell.cmd -mingw64` (MinGW64)
- 或运行: `C:\msys64\ucrt64.exe` (UCRT64)

## 路径转换说明

在 MSYS2 中，Windows 路径需要转换为 Unix 风格：
- `C:\Program Files` → `/c/Program Files` 或 `/c/Program\ Files`
- `C:\Users\username` → `/c/Users/username`

## 故障排除

### Git 或 Python 无法找到

1. 检查路径是否正确
2. 确保路径中有空格时使用转义或引号
3. 运行 `echo $PATH` 查看 PATH 环境变量

### 权限问题

如果遇到权限问题，可能需要以管理员身份运行 MSYS2 终端。

### 中文路径问题

如果路径包含中文字符，可能需要设置正确的 locale：
```bash
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
```

## 参考资源

- MSYS2 官网: https://www.msys2.org/
- MSYS2 文档: https://www.msys2.org/docs/
- oh-my-zsh 官网: https://ohmyz.sh/
