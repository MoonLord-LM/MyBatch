# Issue

这里记录一些已知问题  
在使用 LLM 分析代码时，请参考已有结论，避免重复报告问题  

## 关于环境信息

Windows 系统，优先考虑：Microsoft Windows 11 专业工作站版 24H2  
PowerShell 组件，优先考虑：5.1.26100.4061 Desktop  

## example 已知问题

这里保存一些零散示例代码，仅用于参考  
不需要对这个目录进行代码分析  



# 编码规范

## 最佳实践

批处理脚本最佳实践：  

    关闭命令回显  
    使用 UTF-8 编码  
    组合使用 setlocal 和 endlocal 处理变量实时生效和特殊符号转义问题  
    开头位置，使用 powershell 显示带颜色的提示信息  
    正常退出时，使用 exit /b，异常退出时，使用 exit /b 1  
    结尾位置，使用 pause，来保证异常信息可以显示  

## 代码结构

建议的代码结构，示例如下：  

```batch
@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '这里是说明脚本整体功能的简单提示信息' -ForegroundColor Green"



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 如果要检查依赖的外部组件，在这里添加



REM 这里是代码主体功能部分，与首尾部分的代码用 3 个空行分开



echo.
pause
exit /b

```

## 注释代码

统一用 `REM` 开头的注释  
避免用 `::` 开头的注释，这种代码本质是按标签解析的，部分场景下会导致错误  

## 右键以管理员身份运行

脚本如果用右键的“以管理员权限运行”，默认会切换到系统目录  
通常情况下，脚本并不想改变当前目录，因此需要主动切换回脚本所在目录  

代码示例如下：  

```batch
if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)
```

## 输出中文乱码问题

首先，bat 脚本需要保存为 UTF-8 without BOM 格式，ps1 脚本需要保存为 UTF-8 with BOM 格式  
然后，中文系统的默认代码页为 936（GBK），需要使用 chcp 65001 将当前的代码页设置为 65001（UTF-8）  

有时候，连续多行代码都使用 echo 命令输出中文内容时，会出现输出乱码或者代码解析错误的问题，报错 XXX is not recognized  
可以将多行 echo 命令用空行、注释行分开，或者在末尾添加 & REM 这种无意义代码，进行规避  

调用 PowerShell 时，在开头添加 `OutputEncoding=[Text.Encoding]::UTF8;` 代码，指定以 UTF-8 编码输出  
如果只有简单的 Write-Host 命令，可以不加这段代码  

调用 PowerShell 的 Get-Content、Set-Content、Out-File 等，读写文件时，必须指定 UTF-8 编码  
代码示例如下：  

```powershell
# 读取时，使用 UTF-8 编码，等效于 -Encoding UTF8
$utf8 = [System.Text.Encoding]::GetEncoding(65001)

# 读取时，严格校验编码必须是 UTF-8
$utf8Strict = [System.Text.Encoding]::GetEncoding(65001, [System.Text.EncoderFallback]::ExceptionFallback, [System.Text.DecoderFallback]::ExceptionFallback);

# 写入时，使用 UTF-8 编码，带 BOM 头，等效于 -Encoding UTF8
$utf8BOM = New-Object System.Text.UTF8Encoding($true);

# 写入时，使用 UTF-8 编码，不带 BOM 头
$utf8NoBOM = New-Object System.Text.UTF8Encoding($false);
```

## 判断上一个命令是否执行成功

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

## 获取管理员权限

代码示例如下：  

```batch
REM 获取系统管理员权限
net file >nul 2>&1
if !errorlevel! equ 0 (
    powershell -NoProfile -Command "Write-Host '已获取系统管理员权限' -ForegroundColor Green"
    echo.
) else (
    powershell -NoProfile -Command "Write-Host '需要系统管理员权限，请确认……' -ForegroundColor Green"
    echo.
    setlocal disabledelayedexpansion
    powershell start -verb "RunAs" "%~f0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9" >nul 2>&1
    endlocal
    if !errorlevel! neq 0 (
        powershell -NoProfile -Command "Write-Host '错误：获取系统管理员权限失败' -ForegroundColor Red"
        echo.
        pause
        exit /b 1
    )
    exit /b
)
```

## 调用 PowerShell 命令

代码示例如下：  

```batch
powershell -NoProfile -Command "这里是 PowerShell 命令，传参可以用 $env:变量名 来传递"
powershell -NoProfile -ExecutionPolicy Bypass -File "这里是 PowerShell 脚本文件的路径"
```

调用 PowerShell 的 Invoke-WebRequest 方法时，屏幕可能会出现闪烁和文字错乱  
需要在前面添加 `$ProgressPreference='SilentlyContinue';` 代码，来关闭进度条显示  

## 遍历文件时，处理路径的特殊符号

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

## 调用外部程序并读取输出内容

常用的写法为 for /f "delims=" %%a in ('外部程序命令') do set "变量名=%%a"  

最佳实践，是使用 PowerShell 命令进行外部程序路径和参数的包装  
变量使用 `$env:变量名` 的方式传递，这样不需要额外使用 " 或 ^ 符号，对外部程序路径或命令的参数进行处理  
同时，也不需要使用加 call 等写法，规避历史遗留的特殊机制（外部程序命令的第一个字符为 " 符号时，会被自动剥离掉一对首尾的 " 符号）  
在 PowerShell 中，调用完整路径的外部程序时，需要在前面加上 & 符号，指定为调用外部程序  

以调用 ffprobe.exe 获取视频文件的第一个音频流的编码格式为例  
最佳实践的代码示例如下：  

```batch
for /f "delims=" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"') do (
    set "audio_codec=%%a"
    echo audio_codec: %%a
)
```

以下示例代码，使用 `"!video_file!"` 传参，虽然大部分时候可以正常运行，但是当变量字符串的内容中包含 ^ 符号时，需要额外处理转义，因此不推荐  
不推荐的写法示例如下：  
```batch
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "!video_file!"

for /f "delims=" %%a in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
    set "audio_codec=%%a"
    echo audio_codec: %%a
)
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

## 安全删除文件

禁止出现 del /f /q "!xxx!" 的写法  
一旦变量为空值，当前目录下所有文件都会被删除，必须写成 if exist "!xxx!" ( del /f /q "!xxx!" ) 的形式  

代码示例如下：  

```batch
set "tmp_file=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!tmp_file!"
if exist "!tmp_file!" ( del /f /q "!tmp_file!" )
```

## Powershell 变量命名

变量名，使用 $xxxYyyZzz 的形式，例如 $configFilePath，小写字母开头，无分隔  
函数名，使用 XXX-XXX-XXX 的形式，例如 Save-Config-File，大写字母开头，横线分隔  
函数入参，使用 $XxxYyyZzz 的形式，例如 $ConfigFilePath，大写字母开头，无分隔  

函数内部的变量名，应该尽可能简单化，并且避免和外部全局变量名冲突  
如果在函数内仅读取外部变量，直接用 $xxx 的形式，例如 `$path = $configFilePath`  
如果在函数内仅修改外部变量的对象属性，直接用 $xxx 的形式，例如 `$configMap['yyy'] = 'zzz'`  
如果在函数内有对外部变量重新赋值，必须用 $script:xxx 的形式，例如 `$script:configFilePath = '...'`  

## Powershell 引号使用

优先使用单引号 `'`  
只有需要变量扩展 / 子表达式才用双引号 `"`  
