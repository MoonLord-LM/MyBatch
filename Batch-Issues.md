# Batch 编码问题和解决方案

## 测试环境

| 系统版本 | PowerShell 版本 | Windows 语言设置 |
| -- | -- | -- |
| Microsoft Windows 11 专业工作站版 24H2 | 5.1.26100.4061 Desktop | 中文 |

## 问题清单

### 1. 基本编码规范

批处理脚本最佳实践：  

    关闭命令回显  
    使用 UTF-8 编码  
    组合使用 setlocal 和 endlocal 处理变量实时生效和特殊符号转义问题  
    开头位置，使用 powershell 显示带颜色的提示信息  
    正常退出时，使用 exit /b，异常退出时，使用 exit /b 1  
    结尾使用 pause，来保证异常信息可以显示  

代码示例如下：  

```batch
@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



REM 这里是代码主体功能部分，与首尾部分的代码用 3 个空行分开



echo.
pause
endlocal & endlocal & exit /b

```

### 2. 注释代码

统一用 `REM` 开头的注释  
避免用 `::` 开头的注释，这种代码本质是按标签解析的，部分场景下会导致错误  

### 3. 判断上一个命令是否执行成功

需要考虑到一些程序的异常退出码可能是负数，因此不建议使用 `if errorlevel 1` 的写法，这种写法是判断大于等于 1，才认为属于异常  
推荐使用 `if !errorlevel! neq 0` 的写法，不等于 0，就认为属于异常  

代码示例如下：  

```batch
REM 这里是上一个命令，注意要和下面的代码紧挨着
if !errorlevel! neq 0 (
    echo 错误：XXXXXX
    echo.
    pause
    exit /b 1
)
```

### 4. 输出中文乱码问题

首先，脚本需要保存为 UTF-8 without BOM 格式  
然后，中文系统的默认代码页为 936（GBK），需要使用 chcp 65001 将当前的代码页设置为 65001（UTF-8）  

有时候，连续多行代码都使用 echo 命令输出中文内容时，会出现输出乱码或者代码解析错误的问题，报错 XXX is not recognized  
可以将多行 echo 命令用空行、注释行分开，或者在末尾添加 & REM、& echo off 这种无意义代码，进行规避  

调用 PowerShell 时，在开头添加 `OutputEncoding=[Text.Encoding]::UTF8;` 代码，指定 UTF-8 编码  
如果只有简单的 Write-Host 命令，可以不加这段代码  

调用 PowerShell 的 Get-Content、Set-Content、Out-File 读写文件时，添加 `-Encoding UTF8` 参数，指定 UTF-8 编码  

### 5. 调用 PowerShell 命令

代码示例如下：  

```batch
powershell -NoProfile -Command "这里是 PowerShell 命令，传参可以用 $env:变量名 来传递"
powershell -NoProfile -ExecutionPolicy Bypass -File "这里是 PowerShell 脚本文件的路径"
```

### 6. 遍历文件时，处理路径的特殊符号

文件路径中可能包含 `!` 等特殊字符，在 enabledelayedexpansion 的环境中会解析为变量，导致错误  
因此，需要切换到 disabledelayedexpansion 的环境中，才能正确读取路径信息  

文件遍历的最佳实践的代码示例如下：  

```batch
for /f "delims=" %%f in (...) do (
    setlocal disabledelayedexpansion
    set "file_path=%%f"   REM 完整路径（含文件名）
    set "file_dir=%%~dpf" REM 所在目录
    set "base_name=%%~nf" REM 主文件名（不含扩展名）
    set "file_ext=%%~xf"  REM 扩展名
    ...
    setlocal enabledelayedexpansion

    REM 这里是代码主体功能部分，可以使用 "!file_path!" 等变量

    endlocal
    endlocal
)
```

如果需要将内层环境的变量（例如结果统计）传递到外部环境，可以使用文件暂存的方式来实现  
代码示例如下：  

```batch
REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

set /a "total=0"
set "file_path=!cd!"
for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | ForEach-Object { $_.FullName }"') do (
    setlocal disabledelayedexpansion
    set "file_path=%%f"
    set "file_dir=%%~dpf"
    set "base_name=%%~nf"
    set "file_ext=%%~xf"
    setlocal enabledelayedexpansion

    REM 这里是代码主体功能部分，可以使用 "!file_path!" 等变量
    echo set /a "total+=1">> "!temp_set!"

    endlocal
    endlocal
)

REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

REM 这里可以获取到内层的 "!total!" 的值
```

### 7. 调用外部程序并读取输出内容

常用的写法为 for /f "delims=" %%a in ('外部程序命令') do set "变量名=%%a"  
例如，调用 ffprobe.exe 获取视频文件的第一个音频流的编码格式，代码示例如下：

写法1：外部程序是一个简单的命令  
外部程序命令的参数中，包含 = , > 符号时，需要使用 ^ 符号进行转义  

```batch
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "!video_file!"

for /f "delims=" %%a in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
    set "audio_codec=%%a"
    echo audio_codec: %%a
)
```

写法2：外部程序是一个可执行文件的完整路径  
可执行文件的路径中可能包含有特殊符号，需要使用 " 符号进行包裹  
由于历史遗留的特殊机制，外部程序命令的第一个字符为 " 符号时，会被自动剥离掉一对首尾的 " 符号，需要使用加 call 等写法，进行规避  

```batch
for /f "delims=" %%a in ('call "!ffprobe_path!" -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
    set "audio_codec=%%a"
    echo audio_codec: %%a
)
for /f "delims=" %%a in ('echo off ^& "!ffprobe_path!" -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
    set "audio_codec=%%a"
    echo audio_codec: %%a
)
for /f "delims=" %%a in ('" "!ffprobe_path!" -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul "') do (
    set "audio_codec=%%a"
    echo audio_codec: %%a
)
```

写法3：外部程序是一个 PowerShell 命令  
不需要使用 ^ 符号，对外部程序命令的参数进行转义  
变量需要改为使用 `$env:变量名` 的方式，这种方式传递变量时，会自动添加 " 符号进行包裹  
在 PowerShell 中，调用完整路径的外部程序时，需要在前面加上 & 符号，指定为调用外部程序  

```batch
for /f "delims=" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"') do (
    set "audio_codec=%%a"
    echo audio_codec: %%a
)
```
