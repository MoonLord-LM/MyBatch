# Batch 编码问题和解决方案

## 测试环境

| 系统版本 | PowerShell 版本 | Windows 语言设置 |
| -- | -- | -- |
| Microsoft Windows 11 专业工作站版 24H2 | 5.1.26100.4061 Desktop | 中文 |

## 问题清单

### 1. 编码规范

批处理脚本最佳实践的代码示例如下：  
```batch
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



REM 这里是代码主体功能部分



echo.
pause
exit /b

```

### 2. 输出中文乱码问题

首先，脚本需要保存为 UTF-8 without BOM 格式  
然后，中文系统的默认代码页为 936（GBK），需要使用 chcp 65001 将当前的代码页设置为 65001（UTF-8）  

有时候，连续多行代码都使用 echo 命令输出中文内容时，会出现输出乱码或者代码解析错误的问题，报错 XXX is not recognized  
可以将多行 echo 命令用空行、注释行分开，或者在末尾添加 & REM、& echo off 这种无意义代码，进行规避  

### 3. 调用外部程序并读取输出内容

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
