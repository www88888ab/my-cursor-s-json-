# cursor 调用 clang-format

1. windows 官网现在最新的[LLVM](https://github.com/llvm/llvm-project/tags)并默认安装

2. 在cursor配置文件中添加json配置信息

```json
{
  "C_Cpp.clang_format_path": "C:\\Program Files\\LLVM\\bin\\clang-format.exe",
  "C_Cpp.clang_format_style": "file",
  "editor.formatOnSave": true
}

```

