@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将单个 ps1 / bat / exe 文件，打包转换为 bat 脚本' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击生成的 bat 脚本，自动解码解压并执行' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '处理方式：把源文件内容压缩后，转换为 Base64 编码，嵌入 bat 文件末尾' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '不修改源文件内容，完整保留注释和空行等' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '优先使用 7-Zip 组件压缩，找不到时使用 PowerShell 内置的 GZipStream 压缩' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入要转换的文件的路径；也可以拖拽单个文件到此脚本上' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 检查 7-Zip 组件（可选）
if exist "!script_dir!7za.exe" (
    set "seven_zip=!script_dir!7za.exe"
) else if exist "!cd!\7za.exe" (
    set "seven_zip=!cd!\7za.exe"
) else if exist "!script_dir!..\7za.exe" (
    set "seven_zip=!script_dir!..\7za.exe"
) else if exist "..\7za.exe" (
    set "seven_zip=..\7za.exe"
) else if exist "!ProgramFiles!\7-Zip\7z.exe" (
    set "seven_zip=!ProgramFiles!\7-Zip\7z.exe"
) else if exist "!ProgramFiles(x86)!\7-Zip\7z.exe" (
    set "seven_zip=!ProgramFiles(x86)!\7-Zip\7z.exe"
) else (
    set "seven_zip="
)
if not "!seven_zip!"=="" (
    "!seven_zip!" i >nul 2>&1
    if !errorlevel! neq 0 ( set "seven_zip=" )
)



set "input_file=!param1_path!"

:input_file
    if "!input_file!"=="" (
        echo 请输入要转换的 ps1 bat exe 文件的路径
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
    set "payload_ext="
    for %%e in (.ps1 .bat .exe) do (
        if /i "!input_file:~-4!"=="%%e" set "payload_ext=%%e"
    )
    if "!payload_ext!"=="" (
        echo 错误：只支持 ps1 bat exe 后缀的文件："!input_file!"，请重新输入
        echo.
        set "input_file="
        goto input_file
    )



echo 开始处理："!input_file!"
echo.

for %%i in ("!input_file!") do (
    setlocal disabledelayedexpansion
    set "file_dir=%%~dpi"
    set "base_name=%%~ni"
    set "file_name_ext=%%~nxi"
    setlocal enabledelayedexpansion

    REM 如果输出文件已存在，则继续追加 .bat 后缀，直到文件名不重复
    set "output_file=!file_dir!!base_name!.bat"
    for /l %%n in (1,1,8) do (
        if exist "!output_file!" set "output_file=!output_file!.bat"
    )
    echo 输出文件："!output_file!"
    echo.

    REM ps1 文件统一保存为带 BOM 的 UTF-8 编码；bat 文件统一保存为不带 BOM 的 UTF-8 编码；exe 文件为二进制文件，直接复制
    set "temp_payload=%temp%\MyBatch_%random%_%random%_%random%_%random%!payload_ext!" & type nul > "!temp_payload!"
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$ext = $env:payload_ext.ToLower();" ^
        "if ($ext -eq '.ps1') {" ^
        "    $lines = [System.IO.File]::ReadAllLines($env:input_file, [System.Text.Encoding]::UTF8);" ^
        "    $enc = New-Object System.Text.UTF8Encoding($true);" ^
        "    [System.IO.File]::WriteAllLines($env:temp_payload, $lines, $enc);" ^
        "} elseif ($ext -eq '.bat') {" ^
        "    $lines = [System.IO.File]::ReadAllLines($env:input_file, [System.Text.Encoding]::UTF8);" ^
        "    $enc = New-Object System.Text.UTF8Encoding($false);" ^
        "    [System.IO.File]::WriteAllLines($env:temp_payload, $lines, $enc);" ^
        "} else {" ^
        "    [System.IO.File]::Copy($env:input_file, $env:temp_payload, $true);" ^
        "};"
    if !errorlevel! neq 0 (
        echo 错误：获取源文件失败："!input_file!"
        echo.
        if exist "!temp_payload!" ( del /f /q "!temp_payload!" )
        pause
        exit /b 1
    )

    REM 用 gzip 压缩源文件内容，保存到临时文件
    if "!seven_zip!"=="" (
        echo 压缩方式：PowerShell 内置的 GZipStream 压缩
    ) else (
        echo 压缩方式：7-Zip 压缩
    )
    echo.

    set "temp_gzip=%temp%\MyBatch_%random%_%random%_%random%_%random%.gz"
    if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
    if "!seven_zip!"=="" (
        powershell -NoProfile -Command ^
            "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
            "Add-Type -AssemblyName System.IO.Compression;" ^
            "$rawBytes = [System.IO.File]::ReadAllBytes($env:temp_payload);" ^
            "$memStream = New-Object System.IO.MemoryStream;" ^
            "$mode = [System.IO.Compression.CompressionMode]::Compress;" ^
            "$gzipStream = New-Object System.IO.Compression.GzipStream($memStream, $mode);" ^
            "$gzipStream.Write($rawBytes, 0, $rawBytes.Length);" ^
            "$gzipStream.Close();" ^
            "$bytes = $memStream.ToArray();" ^
            "$memStream.Close();" ^
            "[System.IO.File]::WriteAllBytes($env:temp_gzip, $bytes);"
        if !errorlevel! neq 0 (
            echo 错误：压缩源文件失败："!input_file!"
            echo.
            if exist "!temp_payload!" ( del /f /q "!temp_payload!" )
            if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
            pause
            exit /b 1
        )
    ) else (
        "!seven_zip!" a -tgzip -mx=9 -mtc=off -mtm=off -mta=off -si"!file_name_ext!" "!temp_gzip!" < "!temp_payload!" >nul
        if !errorlevel! neq 0 (
            echo 错误：压缩源文件失败："!input_file!"
            echo.
            if exist "!temp_payload!" ( del /f /q "!temp_payload!" )
            if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
            pause
            exit /b 1
        )
    )
    if not exist "!temp_gzip!" (
        echo 错误：压缩源文件失败："!input_file!"
        echo.
        if exist "!temp_payload!" ( del /f /q "!temp_payload!" )
        pause
        exit /b 1
    )
    if exist "!temp_payload!" ( del /f /q "!temp_payload!" )

    REM 把压缩后的内容转换为 Base64 编码，每 64 个字符一行，保存到临时文件
    set "temp_base64=%temp%\MyBatch_%random%_%random%_%random%_%random%.txt" & type nul > "!temp_base64!"
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$bytes = [System.IO.File]::ReadAllBytes($env:temp_gzip);" ^
        "$base64 = [Convert]::ToBase64String($bytes);" ^
        "$list = New-Object System.Collections.Generic.List[string];" ^
        "for ($i = 0; $i -lt $base64.Length; $i += 64) {" ^
        "    $length = [Math]::Min(64, $base64.Length - $i);" ^
        "    $list.Add($base64.Substring($i, $length));" ^
        "};" ^
        "$enc = New-Object System.Text.UTF8Encoding($false);" ^
        "[System.IO.File]::WriteAllLines($env:temp_base64, $list, $enc);"
    if !errorlevel! neq 0 (
        echo 错误：Base64 编码失败："!input_file!"
        echo.
        if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
        if exist "!temp_base64!" ( del /f /q "!temp_base64!" )
        pause
        exit /b 1
    )
    if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )

    REM 从自身文件末尾的 -----BEGIN BATCH CODE----- / -----END BATCH CODE----- 之间提取 bat 代码原样写入，统一保存为不带 BOM 的 UTF-8 编码
    REM 这样生成的 bat 代码里的 ! 和 ^ 和 % 等符号，都不需要转义处理
    REM 生成的 bat 文件中，Base64 编码内容的开始标记和结束标记
    set "begin_marker=-----BEGIN BATCH CODE-----"
    set "end_marker=-----END BATCH CODE-----"
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$lines = Get-Content -Encoding UTF8 -LiteralPath $env:script_path;" ^
        "$begin = [array]::IndexOf($lines, '-----BEGIN BATCH CODE-----') + 1;" ^
        "$end = [array]::IndexOf($lines, '-----END BATCH CODE-----');" ^
        "if ($begin -lt 1 -or $end -lt $begin) {" ^
        "    Write-Host '错误：未找到内嵌的 bat 代码块' -ForegroundColor Red;" ^
        "    exit 1;" ^
        "};" ^
        "$code = $lines[$begin..($end - 1)];" ^
        "for ($i = 0; $i -lt $code.Count; $i++) {" ^
        "    $code[$i] = $code[$i].Replace('__PAYLOAD_EXT_NAME__', $env:payload_ext.TrimStart('.'));" ^
        "    $code[$i] = $code[$i].Replace('__PAYLOAD_EXT__', $env:payload_ext);" ^
        "    $code[$i] = $code[$i].Replace('__BEGIN_MARKER__', $env:begin_marker);" ^
        "    $code[$i] = $code[$i].Replace('__END_MARKER__', $env:end_marker);" ^
        "};" ^
        "$enc = New-Object System.Text.UTF8Encoding($false);" ^
        "[System.IO.File]::WriteAllLines($env:output_file, $code, $enc);"
    if !errorlevel! neq 0 (
        echo 错误：生成 bat 文件失败："!output_file!"
        echo.
        if exist "!temp_base64!" ( del /f /q "!temp_base64!" )
        pause
        exit /b 1
    )

    REM 把 Base64 编码内容，追加到生成文件的开始标记之后，并补上结束标记
    (
        type "!temp_base64!"
        echo !end_marker!
    ) >> "!output_file!"
    if exist "!temp_base64!" ( del /f /q "!temp_base64!" )

    if not exist "!output_file!" (
        echo 转换失败："!input_file!"
        echo.
        pause
        exit /b 1
    ) else (
        for %%j in ("!output_file!") do (
            setlocal disabledelayedexpansion
            set "file_size=%%~zj"
            setlocal enabledelayedexpansion

            echo 转换成功，大小：!file_size! 字节

            endlocal
            endlocal
        )
    )

    endlocal
    endlocal
)



echo.
pause
exit /b



-----BEGIN BATCH CODE-----

@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '把内嵌的 Base64 编码内容解码解压还原为 __PAYLOAD_EXT_NAME__ 文件，然后自动运行' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



set "payload_ext=__PAYLOAD_EXT__"
set "begin_marker=__BEGIN_MARKER__"
set "end_marker=__END_MARKER__"
set "temp_file=%temp%\MyBatch_%random%_%random%_%random%_%random%!payload_ext!"

REM 从自身文件末尾的 __BEGIN_MARKER__ / __END_MARKER__ 之间提取 Base64 编码内容，解码解压还原为 __PAYLOAD_EXT_NAME__ 文件
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "Add-Type -AssemblyName System.IO.Compression;" ^
    "$lines = Get-Content -Encoding UTF8 -LiteralPath $env:script_path;" ^
    "$begin = [array]::IndexOf($lines, $env:begin_marker) + 1;" ^
    "$end = [array]::IndexOf($lines, $env:end_marker);" ^
    "if ($begin -lt 1 -or $end -lt $begin) {" ^
    "    Write-Host '错误：未找到内嵌的压缩内容' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "};" ^
    "$base64 = ($lines[$begin..($end - 1)] -join '');" ^
    "$base64 = $base64 -replace '\s', '';" ^
    "$bytes = [Convert]::FromBase64String($base64);" ^
    "$memStream = New-Object System.IO.MemoryStream (,$bytes);" ^
    "$mode = [System.IO.Compression.CompressionMode]::Decompress;" ^
    "$gzipStream = New-Object System.IO.Compression.GzipStream($memStream, $mode);" ^
    "$outStream = New-Object System.IO.MemoryStream;" ^
    "$gzipStream.CopyTo($outStream);" ^
    "$gzipStream.Close();" ^
    "$memStream.Close();" ^
    "$rawBytes = $outStream.ToArray();" ^
    "$outStream.Close();" ^
    "[System.IO.File]::WriteAllBytes($env:temp_file, $rawBytes);"
if !errorlevel! neq 0 (
    echo 错误：还原内嵌的 __PAYLOAD_EXT_NAME__ 文件失败
    echo.
    if exist "!temp_file!" ( del /f /q "!temp_file!" )
    pause
    exit /b 1
)

if /i "!payload_ext!"==".ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!temp_file!"
) else if /i "!payload_ext!"==".bat" (
    call "!temp_file!"
) else (
    "!temp_file!"
)
if !errorlevel! neq 0 (
    echo 运行失败
    echo.
    if exist "!temp_file!" ( del /f /q "!temp_file!" )
    pause
    exit /b 1
) else (
    echo 运行成功
)
if exist "!temp_file!" ( del /f /q "!temp_file!" )



echo.
pause
exit /b

__BEGIN_MARKER__

-----END BATCH CODE-----
