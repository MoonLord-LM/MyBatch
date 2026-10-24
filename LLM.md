# Issue

这里记录一些已知问题  
在使用 LLM 分析代码时，请参考已有结论，避免重复报告问题  

## 关于环境信息与兼容性

Windows 系统，只需要考虑：Microsoft Windows 11  
PowerShell 组件，只需要考虑：5.1.26100.4061 Desktop  
不需要为了兼容更多环境，而做额外适配，增加代码复杂度  

## example 已知问题

这里保存一些零散示例代码，仅用于参考，不保证质量  
不需要对这个目录进行代码分析  



# TODO

这里记录一些代办事项  

## MyBatchTask 任务管理.ps1

TODO 对任务增加：指定 exe 进程存在状态的检查机制  
TODO 对任务增加：指定 URL 可访问的健康检查机制  
TODO 对任务增加：按时间间隔，自动重启的机制  
TODO 对任务增加：健康检查失败后，自动重启的机制  
TODO 对任务增加：延迟 XX 秒后自动输入内容并回车的机制  

## 图片处理导致 exif 信息丢失

TODO 考虑使用 exiftool 来复制原始图片的 exif 信息  



# 编码规范

## 最佳实践

批处理脚本最佳实践：  

    关闭命令回显  
    使用 UTF-8 编码  
    组合使用 setlocal 和 endlocal 处理变量实时生效和特殊符号转义问题  
    开头位置，使用 powershell 显示带颜色的提示信息  
    正常退出时，使用 exit /b，异常退出时，使用 exit /b 1  
    结尾位置，使用 pause 或 timeout /t 3 /nobreak ，确保异常信息可以显示  

## 代码结构

建议的代码结构：  
统一基础配置 + 3 个空行 + 整体功能说明 + 3 个空行 + 权限检查/依赖组件检查 + 3 个空行 + 校验输入参数/定义公共变量 + 3 个空行 + 代码功能实现 + 3 个空行 + 尾部等待处理  

代码示例如下：  

```batch
@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '这里是说明脚本整体功能的简单提示信息' -ForegroundColor Green"
echo.



REM 如果要获取管理员权限，在这里添加

REM 如果要检查依赖的外部组件，在这里添加



REM 如果要校验输入的参数，在这里添加

REM 如果要定义公共变量，在这里添加



REM 这里是代码主体功能部分



echo.
pause
exit /b

```

如果需要接收外部参数，可以在 `script` 行的后面，继续增加 `param_???` 的变量定义  
代码示例如下：  

```batch
@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
set "param2=%~2" & set "param2_path=%~f2" & set "param2_dir=%~dp2" & set "param2_name=%~n2" & set "param2_ext=%~x2" & set "param2_name_ext=%~nx2"
set "param3=%~3" & set "param3_path=%~f3" & set "param3_dir=%~dp3" & set "param3_name=%~n3" & set "param3_ext=%~x3" & set "param3_name_ext=%~nx3"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.
```

## 右键以管理员身份运行

脚本如果用右键的"以管理员权限运行"，默认会切换到 `"!SystemRoot!\System32"` 系统目录  
通常情况下，脚本并不想改变当前目录，因此需要主动调用 `cd /d "!script_dir!"` 切换回脚本所在目录  

## 注释代码

统一用 `REM` 开头的注释  
避免用 `::` 开头的注释，这种代码本质是按标签解析的，部分场景下会导致错误  

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

## 组件检查

示例代码 1 如下：  

```batch
REM 检查 ffmpeg 组件
if exist "!script_dir!ffmpeg.exe" (
    set "ffmpeg_path=!script_dir!ffmpeg.exe"
) else if exist "!cd!\ffmpeg.exe" (
    set "ffmpeg_path=!cd!\ffmpeg.exe"
) else if exist "!script_dir!..\ffmpeg.exe" (
    set "ffmpeg_path=!script_dir!..\ffmpeg.exe"
) else if exist "..\ffmpeg.exe" (
    set "ffmpeg_path=..\ffmpeg.exe"
) else (
    set "ffmpeg_path=ffmpeg"
)
"!ffmpeg_path!" -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 ffmpeg 组件 & REM
    echo 请从 https://ffmpeg.org/download.html 下载，然后把 ffmpeg.exe 放到脚本所在文件夹 & REM
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)
```

示例代码 2 如下：  

```batch
REM 检查 RHash 组件
if exist "!script_dir!rhash.exe" (
    set "rhash_path=!script_dir!rhash.exe"
) else if exist "!cd!\rhash.exe" (
    set "rhash_path=!cd!\rhash.exe"
) else if exist "!script_dir!..\rhash.exe" (
    set "rhash_path=!script_dir!..\rhash.exe"
) else if exist "..\rhash.exe" (
    set "rhash_path=..\rhash.exe"
) else (
    set "rhash_path=rhash"
)
"!rhash_path!" --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 RHash 组件 & REM
    echo 请从 https://rhash.sourceforge.io 下载，然后把 rhash.exe 放到脚本所在文件夹 & REM
    "explorer.exe" "https://rhash.sourceforge.io"
    echo.
    pause
    exit /b 1
)
```

示例代码 3 如下：  

```batch
REM 检查 OpenSSL-Win64 组件
set "libcrypto="
if exist "!script_dir!libcrypto-4-x64.dll" (
    set "libcrypto=!script_dir!libcrypto-4-x64.dll"
) else if exist "!cd!\libcrypto-4-x64.dll" (
    set "libcrypto=!cd!\libcrypto-4-x64.dll"
) else if exist "!script_dir!..\libcrypto-4-x64.dll" (
    set "libcrypto=!script_dir!..\libcrypto-4-x64.dll"
) else if exist "..\libcrypto-4-x64.dll" (
    set "libcrypto=..\libcrypto-4-x64.dll"
) else if exist "!ProgramFiles!\OpenSSL-Win64\bin\libcrypto-4-x64.dll" (
    set "libcrypto=!ProgramFiles!\OpenSSL-Win64\bin\libcrypto-4-x64.dll"
) else if exist "!ProgramFiles!\Git\mingw64\bin\libcrypto-4-x64.dll" (
    set "libcrypto=!ProgramFiles!\Git\mingw64\bin\libcrypto-4-x64.dll"
)
if "!libcrypto!" == "" (
    echo 错误：缺少 OpenSSL-Win64 组件 & REM
    echo 请从 https://slproweb.com/products/Win32OpenSSL.html 下载，然后把 libcrypto-4-x64.dll 放到脚本所在文件夹 & REM
    "explorer.exe" "https://slproweb.com/products/Win32OpenSSL.html"
    echo.
    pause
    exit /b 1
)
```

示例代码 4 如下：  

```batch
REM 检查 Video2X 组件
if exist "!script_dir!Video2X\video2x.exe" (
    set "video2x_path=!script_dir!Video2X\video2x.exe"
) else if exist "!cd!\Video2X\video2x.exe" (
    set "video2x_path=!cd!\Video2X\video2x.exe"
) else if exist "!script_dir!..\Video2X\video2x.exe" (
    set "video2x_path=!script_dir!..\Video2X\video2x.exe"
) else if exist "..\Video2X\video2x.exe" (
    set "video2x_path=..\Video2X\video2x.exe"
) else (
    set "video2x_path=video2x"
)
"!video2x_path!" --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 Video2X 组件 & REM
    echo 请从 https://github.com/k4yt3x/video2x/releases 下载，然后把 Video2X 文件夹放到脚本所在文件夹 & REM
    "explorer.exe" "https://github.com/k4yt3x/video2x/releases"
    echo.
    pause
    exit /b 1
)
```

示例代码 5 如下：  

```batch
REM 检查 Node.js 组件
call node -v >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 Node.js 组件 & REM
    echo 请从 https://nodejs.org/en/download 下载，并完成安装 & REM
    "explorer.exe" "https://nodejs.org/en/download"
    echo.
    pause
    exit /b 1
)
```

## 跳转标签

统一使用单个冒号 `:` 开头的标签，避免使用双冒号 `::` 写法，与注释混淆  
标签相关的代码，增加 4 个空格缩进，方便理解  

## 输入文件路径

需要删除引号、检查路径是否存在、检查路径是否是文件夹  

代码示例如下：  

```batch
:input_file
    if "!input_file!"=="" (
        echo 请输入要处理的文件的路径
        set /p "input_file="
        if !errorlevel! neq 0 (
            echo 无输入，退出脚本
            echo.
            exit /b 1
        )
        echo.
    )
    if "!input_file!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_file
    )
    set "input_file=!input_file:"=!"
    if "!input_file!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_file
    )
    if "!input_file:~-1!"=="\" set "input_file=!input_file:~0,-1!"
    if not exist "!input_file!" (
        echo 错误：路径不存在："!input_file!"，请重新输入
        echo.
        set "input_file="
        goto input_file
    )
    if exist "!input_file!\" (
        echo 错误：不支持文件夹，请输入单个文件
        echo.
        set "input_file="
        goto input_file
    )
```

## 输出中文乱码问题

首先，bat 脚本需要保存为 UTF-8 without BOM 格式，ps1 脚本需要保存为 UTF-8 with BOM 格式  
然后，中文系统的默认代码页为 936（GBK），需要使用 chcp 65001 将当前的代码页设置为 65001（UTF-8）  

有时候，连续多行代码都使用 echo 命令输出中文内容时，会出现输出乱码或者代码解析错误的问题，报错 XXX is not recognized  
可以将多行 echo 命令用空行、注释行分开，或者在末尾添加 & REM 这种无意义代码，进行规避  

调用 PowerShell 时，在开头添加 `[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;` 代码，指定以 UTF-8 编码输出  
如果只是简单的一行命令，可以不加这段代码  

调用 PowerShell 的 Get-Content、Set-Content、Add‑Content、Out-File 等，读写文件时，必须指定 UTF-8 编码  
优先考虑用 `[System.IO.File]` 的 `ReadAllText`、`WriteAllText`、`AppendAllText` 等方法替代  

代码示例如下：  

```powershell
# 读取时，使用 UTF-8 编码，等效于 -Encoding UTF8
$utf8 = [System.Text.Encoding]::UTF8
$utf8 = [System.Text.Encoding]::GetEncoding(65001)

# 读取时，严格校验编码必须是 UTF-8
$utf8Strict = [System.Text.Encoding]::GetEncoding(65001, [System.Text.EncoderFallback]::ExceptionFallback, [System.Text.DecoderFallback]::ExceptionFallback)

# 写入时，使用 UTF-8 编码，带 BOM 头，等效于 -Encoding UTF8
$utf8BOM = [System.Text.Encoding]::UTF8
$utf8BOM = [System.Text.UTF8Encoding]::new($true)
$utf8BOM = New-Object System.Text.UTF8Encoding($true)

# 写入时，使用 UTF-8 编码，不带 BOM 头
$utf8NoBOM = [System.Text.UTF8Encoding]::new($false)
$utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
```

## 判断上一个命令是否执行成功

需要考虑到一些程序的异常退出码可能是负数，因此不建议使用 `if errorlevel 1` 的写法，这种写法是判断大于等于 1，才认为出现异常  
推荐使用 `if !errorlevel! neq 0` 的写法，`!errorlevel!` 不等于 0，就认为出现异常  

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

## 调用 PowerShell 命令

代码示例如下：  

```batch
powershell -NoProfile -Command "这里是 PowerShell 代码，传参可以用 $env:变量名 来传递"
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
    set "file_path=%%f"
    set "file_dir=%%~dpf"
    set "base_name=%%~nf"
    set "file_ext=%%~xf"
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
for /f "delims=" %%f in ('
    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
        "Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | ForEach-Object { $_.FullName }"
    ') do (
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
for /f "delims=" %%a in ('
    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
        "& $env:ffprobe_path -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"
    ') do (
    set "audio_codec=%%a"
    echo audio_codec: %%a
)
```

以下示例代码，使用 `"!video_file!"` 传参  
虽然大部分时候可以正常运行，但是当变量字符串的内容中包含 ^ 符号时，需要额外处理转义，因此不推荐  
不推荐的写法示例如下：  

```batch
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "!video_file!"

for /f "delims=" %%a in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
    set "audio_codec=%%a"
    echo audio_codec: %%a
)

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

## 获取文件大小

避免使用 `%%~zf` 的写法，受 32 位有符号整数的返回值限制，无法处理超过 2GB 的文件，存在溢出风险  

代码示例如下：  

```batch
set "file_size=-1"
for /f %%s in ('powershell -NoProfile -Command "try { ([System.IO.FileInfo]($env:file_path)).Length } catch { -1 }"') do set "file_size=%%s"
if "!file_size!"=="-1" (
    echo 错误：文件大小获取失败："!file_path!"
    echo.
    pause
    exit /b 1
)
```

## 安全比较数字大小

谨慎使用 `( equ | neq | lss | leq | gtr | geq )` 这种比较数字的写法  
批处理的 `if` 数字比较底层用 **32-bit signed int**，范围：`-2147483648 ~ +2147483647`，存在溢出风险  
除了 `!errorlevel! equ 0` 这种与固定小数字的 `equ`、`neq` 的比较之外，其它场景都建议改为用 powershell 来做比较  

代码示例如下：  

```batch
set "size_smaller=0"
for /f "delims=" %%c in ('
    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
        "Write-Output ([int]([int64]$env:file_size -lt [int64]$env:smallest_size));"
') do (
    set "size_smaller=%%c"
)
if "!size_smaller!"=="1" (
    set "smallest_size=!file_size!"
)
```

## echo 输出与括号问题

`echo` 后面的输出内容，应该避免出现 `(` 和 `)` 符号的硬编码  
否则，容易与上下文的括号产生错误配对，导致语法错误  
如果必须在代码块中输出英文括号，需要使用转义符 `^`  

代码示例如下：  

```batch
echo 英文括号需要转义：^(Hello^)
echo 中文括号可以不转义：（Hello）
```

## PowerShell 变量命名

变量名，使用 $xxxYyyZzz 的形式，例如 $configFilePath，小写字母开头，无分隔  
函数名，使用 XXX-XXX-XXX 的形式，例如 Save-Config-File，大写字母开头，横线分隔  
函数入参，使用 $XxxYyyZzz 的形式，例如 $ConfigFilePath，大写字母开头，无分隔  

函数内部的变量名，应该尽可能简单化，并且避免和外部全局变量名冲突  
如果在函数内仅读取外部变量，直接用 $xxx 的形式，例如 `$path = $configFilePath`  
如果在函数内仅修改外部变量的对象属性，直接用 $xxx 的形式，例如 `$configMap['yyy'] = 'zzz'`  
如果在函数内有对外部变量重新赋值，必须用 $script:xxx 的形式，例如 `$script:configFilePath = '...'`  

## PowerShell 引号使用

优先使用单引号 `'`  
只有需要变量扩展 / 子表达式才用双引号 `"`  

## PowerShell 命名空间

一般情况下，尽量不要使用命名空间或简写，应该写出完整的类名称  
类型加速器 [string]、[int]、[array]、[datetime]、[regex]、[char]、[double]、[type] 等除外  

代码示例如下：  

```powershell
[System.Console]::OutputEncoding
[System.Convert]::DBNull
[System.DateTimeOffset]::Now
[System.Diagnostics.ProcessStartInfo]::new()
[System.Drawing.Color]::Black
[System.Environment]::UserName
[System.Windows.Forms.Form]::new()
[System.Globalization.CultureInfo]::CurrentCulture
[System.IO.Directory]::GetCurrentDirectory()
[System.Math]::PI
[System.Net.Dns]::GetHostName()
[System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
[System.Text.Encoding]::UTF8
[System.Threading.Thread]::CurrentThread
[System.Uri]::EscapeUriString('')
```

## 临时文件缓存

如果已知文件名和文件内容，需要将文件释放到临时文件目录，并进行缓存  
可以使用 %temp% + \MyBatch\cache + \文件大小 + \文件 SHA-512 的值 + \文件名，拼接一个较为安全的临时文件路径  

代码示例如下：  

```batch
REM 已知 input_file、file_size、file_name

set "file_sha512="
for /f "delims=" %%a in ('
    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
        "$sha512 = [System.Security.Cryptography.SHA512]::Create();" ^
        "$fileBytes = [System.IO.File]::ReadAllBytes($env:input_file);" ^
        "Write-Output ([System.BitConverter]::ToString($sha512.ComputeHash($fileBytes)).Replace('-', '').ToLowerInvariant());"
') do (
    set "file_sha512=%%a"
)
if "!file_sha512!"=="" (
    echo 错误：计算文件内容的 SHA512 哈希值失败："!input_file!"
    echo.
    pause
    exit /b 1
)

set "temp_dir=%temp%\MyBatch\cache\!file_size!\!file_sha512!"
if not exist "!temp_dir!" ( mkdir "!temp_dir!" )
set "temp_file=!temp_dir!\!file_name!"
```
