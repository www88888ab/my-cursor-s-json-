# 从 IAR 工程生成 compile_commands.json

用于让 clangd 正确做「转到定义」(F12)、「查找引用」等索引。

## 步骤（在仓库根目录执行）

```bash
# 自动查找 .ewp 并生成
python iar_to_compile_commands.py

# 指定工程文件
python iar_to_compile_commands.py mud_layer_interface_plungeInto_meter/EWARM/mud_layer_interface_plungeInto_meter.ewp

# 指定输出路径
python iar_to_compile_commands.py -o compile_commands.json
```

生成后重启 clangd 或重新打开工程，F12 即可跳到各 .c 中的定义。

## 何时需要重新生成

在 IAR 中新增/删除源文件、修改包含路径或预定义宏后，重新执行脚本即可。

## 依赖

Python 3.6+，仅标准库 (xml.etree, json, pathlib)。
