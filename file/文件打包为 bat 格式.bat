@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将单个文件，打包转换为 bat 脚本' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击生成的 bat 脚本，自动解码解压并打开原文件，如果是 ps1 / bat / py / exe 则自动执行' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '处理方式：把原文件内容，执行压缩，转换为 Base64 编码，嵌入自解压的 bat 文件末尾' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '尝试使用 PowerShell 内置的 GZipStream / makecab.exe / 7-Zip 压缩，尽可能压缩到最小' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入要打包转换的文件的路径；也可以拖拽单个文件到此脚本上' -ForegroundColor Green"
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
    set "seven_zip=7z"
)
"!seven_zip!" i >nul 2>&1
if !errorlevel! neq 0 (
    set "seven_zip="
)

REM 检查 7-Zip 自解压模块（可选）
if exist "!script_dir!7zCon.sfx" (
    set "seven_zip_sfx=!script_dir!7zCon.sfx"
) else if exist "!cd!\7zCon.sfx" (
    set "seven_zip_sfx=!cd!\7zCon.sfx"
) else if exist "!script_dir!..\7zCon.sfx" (
    set "seven_zip_sfx=!script_dir!..\7zCon.sfx"
) else if exist "..\7zCon.sfx" (
    set "seven_zip_sfx=..\7zCon.sfx"
) else if exist "!ProgramFiles!\7-Zip\7zCon.sfx" (
    set "seven_zip_sfx=!ProgramFiles!\7-Zip\7zCon.sfx"
) else if exist "!ProgramFiles(x86)!\7-Zip\7zCon.sfx" (
    set "seven_zip_sfx=!ProgramFiles(x86)!\7-Zip\7zCon.sfx"
) else (
    set "seven_zip_sfx="
)



set "input_file=!param1_path!"

:input_file
    if "!input_file!"=="" (
        echo 请输入要打包转换的文件的路径
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



echo 开始处理："!input_file!"
echo.

for %%i in ("!input_file!") do (
    setlocal disabledelayedexpansion
    set "file_size=%%~zi"
    set "file_dir=%%~dpi"
    set "base_name=%%~ni"
    set "file_name_ext=%%~nxi"
    setlocal enabledelayedexpansion

    echo 原始大小：%%~zi 字节
    echo.

    REM 计算文件内容的 SHA512 哈希值
    for /f "delims=" %%a in ('powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$sha512 = [System.Security.Cryptography.SHA512]::Create();" ^
        "$contentBytes = [System.IO.File]::ReadAllBytes($env:input_file);" ^
        "Write-Output ([System.BitConverter]::ToString($sha512.ComputeHash($contentBytes)).Replace('-', '').ToLowerInvariant());"') do (
        set "file_content_sha512=%%a"
    )
    if "!file_content_sha512!"=="" (
        echo 错误：计算文件内容的 SHA512 哈希值失败："!input_file!"
        echo.
        pause
        exit /b 1
    )

    REM 判断 7z 自解压方式是否可用，需要同时具备 7-Zip 组件和 7zCon.sfx
    set "use_7z_exe=0"
    if not "!seven_zip!"=="" (
        if not "!seven_zip_sfx!"=="" (
            set "use_7z_exe=1"
        )
    )
    if "!use_7z_exe!"=="0" (
        echo 缺少 7-Zip 组件或自解压模块，只使用 gzip / cab 方式打包
        echo.
    )

    REM 如果输出文件已存在，则继续追加 .bat 后缀，直到文件名不重复
    set "output_file=!file_dir!!base_name!.bat"
    for /l %%n in (1,1,16) do (
        if exist "!output_file!" set "output_file=!output_file!.bat"
    )
    echo 目标文件："!output_file!"
    echo.



    REM 方式一：压缩为 gzip 格式，转换为 Base64 编码
    set "temp_zip=%temp%\MyBatch_%random%_%random%_%random%_%random%.zip"
    if "!seven_zip!"=="" (
        echo 压缩方式：使用 PowerShell 内置的 GZipStream 压缩
        powershell -NoProfile -Command ^
            "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
            "Add-Type -AssemblyName System.IO.Compression;" ^
            "$rawBytes = [System.IO.File]::ReadAllBytes($env:input_file);" ^
            "$memStream = New-Object System.IO.MemoryStream;" ^
            "$mode = [System.IO.Compression.CompressionMode]::Compress;" ^
            "$gzipStream = New-Object System.IO.Compression.GzipStream($memStream, $mode);" ^
            "$gzipStream.Write($rawBytes, 0, $rawBytes.Length);" ^
            "$gzipStream.Close();" ^
            "$bytes = $memStream.ToArray();" ^
            "$memStream.Close();" ^
            "[System.IO.File]::WriteAllBytes($env:temp_zip, $bytes);"
        if !errorlevel! neq 0 (
            echo 错误：压缩失败："!input_file!"
            echo.
            if exist "!temp_zip!" ( del /f /q "!temp_zip!" )
            pause
            exit /b 1
        )
    ) else (
        echo 压缩方式：使用 7-Zip 压缩 gzip 格式
        "!seven_zip!" a -tgzip -mx=9 -ms=off -mmt=on -mtc=off -mtm=off -mta=off -si"!file_name_ext!" "!temp_zip!" < "!input_file!" >nul
        if !errorlevel! neq 0 (
            echo 错误：压缩失败："!input_file!"
            echo.
            if exist "!temp_zip!" ( del /f /q "!temp_zip!" )
            pause
            exit /b 1
        )
    )
    if not exist "!temp_zip!" (
        echo 错误：压缩文件生成失败："!temp_zip!"
        echo.
        pause
        exit /b 1
    )

    REM 转换 Base64 编码
    set "temp_source=!temp_zip!"
    set "temp_base64=%temp%\MyBatch_%random%_%random%_%random%_%random%.txt" & type nul > "!temp_base64!"
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$bytes = [System.IO.File]::ReadAllBytes($env:temp_source);" ^
        "$base64 = [Convert]::ToBase64String($bytes);" ^
        "$list = New-Object System.Collections.Generic.List[string];" ^
        "for ($i = 0; $i -lt $base64.Length; $i += 64) {" ^
        "    $length = [Math]::Min(64, $base64.Length - $i);" ^
        "    $list.Add($base64.Substring($i, $length));" ^
        "};" ^
        "$utf8NoBom = New-Object System.Text.UTF8Encoding($false);" ^
        "[System.IO.File]::WriteAllLines($env:temp_base64, $list, $utf8NoBom);"
    if !errorlevel! neq 0 (
        echo 错误：转换 Base64 编码失败："!input_file!"
        echo.
        if exist "!temp_zip!" ( del /f /q "!temp_zip!" )
        if exist "!temp_base64!" ( del /f /q "!temp_base64!" )
        pause
        exit /b 1
    )
    if not exist "!temp_base64!" (
        echo 错误：转换 Base64 编码文件生成失败："!temp_base64!"
        echo.
        pause
        exit /b 1
    )
    if exist "!temp_zip!" ( del /f /q "!temp_zip!" )

    REM 提取内嵌代码，使用第 1 段模板
    set "inner_begin_marker=-----BEGIN BATCH CODE 1-----"
    set "inner_end_marker=-----END BATCH CODE 1-----"
    set "origin_file_name_marker=-----ORIGIN FILE NAME-----"
    set "origin_file_size_marker=-----ORIGIN FILE SIZE-----"
    set "origin_file_content_sha512_marker=-----ORIGIN FILE CONTENT SHA512-----"
    set "output_target=!output_file!"
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$lines = Get-Content -Encoding UTF8 -LiteralPath $env:script_path;" ^
        "$begin = [array]::IndexOf($lines, $env:inner_begin_marker) + 1;" ^
        "$end = [array]::IndexOf($lines, $env:inner_end_marker);" ^
        "if ($begin -lt 1 -or $end -lt $begin) {" ^
        "    Write-Host '错误：未找到内嵌的 bat 代码块' -ForegroundColor Red;" ^
        "    exit 1;" ^
        "};" ^
        "$code = $lines[$begin..($end - 1)];" ^
        "$safe_file_name_ext = $env:file_name_ext.Replace('%%', '%%%%');" ^
        "for ($i = 0; $i -lt $code.Count; $i++) {" ^
        "    $code[$i] = $code[$i].Replace($env:origin_file_name_marker, $safe_file_name_ext);" ^
        "    $code[$i] = $code[$i].Replace($env:origin_file_size_marker, $env:file_size);" ^
        "    $code[$i] = $code[$i].Replace($env:origin_file_content_sha512_marker, $env:file_content_sha512);" ^
        "};" ^
        "$utf8NoBom = New-Object System.Text.UTF8Encoding($false);" ^
        "[System.IO.File]::WriteAllLines($env:output_target, $code, $utf8NoBom);"
    if !errorlevel! neq 0 (
        echo 错误：提取内嵌代码失败："!output_target!"
        echo.
        if exist "!temp_base64!" ( del /f /q "!temp_base64!" )
        pause
        exit /b 1
    )
    if not exist "!output_target!" (
        echo 错误：提取内嵌代码文件生成失败："!output_target!"
        echo.
        pause
        exit /b 1
    )

    REM 合并最终文件
    set "output_begin_marker=-----BEGIN GZIP FILE-----"
    set "output_end_marker=-----END GZIP FILE-----"
    (
        echo !output_begin_marker!
        type "!temp_base64!"
        echo !output_end_marker!
    ) >> "!output_target!"
    if exist "!temp_base64!" ( del /f /q "!temp_base64!" )

    for %%j in ("!output_file!") do set "smallest_size=%%~zj"
    set "smallest_format=gzip 格式"
    echo 文件大小：!smallest_size! 字节
    echo.



    REM 方式二：压缩为 cab 格式，转换为 Base64 编码
    echo 压缩方式：使用 makecab 压缩 cab 格式
    set "temp_cab=%temp%\MyBatch_%random%_%random%_%random%_%random%.cab"
    if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
    makecab /D CompressionType=LZX /D CompressionMemory=21 "!input_file!" "!temp_cab!" >nul
    if !errorlevel! neq 0 (
        echo 错误：压缩失败："!input_file!"
        echo.
        if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
        pause
        exit /b 1
    )
    if not exist "!temp_cab!" (
        echo 错误：压缩文件生成失败："!temp_cab!"
        echo.
        pause
        exit /b 1
    )

    REM 转换 Base64 编码
    set "temp_source=!temp_cab!"
    set "temp_base64=%temp%\MyBatch_%random%_%random%_%random%_%random%.cab.txt" & type nul > "!temp_base64!"
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$bytes = [System.IO.File]::ReadAllBytes($env:temp_source);" ^
        "$base64 = [Convert]::ToBase64String($bytes);" ^
        "$list = New-Object System.Collections.Generic.List[string];" ^
        "for ($i = 0; $i -lt $base64.Length; $i += 64) {" ^
        "    $length = [Math]::Min(64, $base64.Length - $i);" ^
        "    $list.Add($base64.Substring($i, $length));" ^
        "};" ^
        "$utf8NoBom = New-Object System.Text.UTF8Encoding($false);" ^
        "[System.IO.File]::WriteAllLines($env:temp_base64, $list, $utf8NoBom);"
    if !errorlevel! neq 0 (
        echo 错误：转换 Base64 编码失败："!input_file!"
        echo.
        if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
        if exist "!temp_base64!" ( del /f /q "!temp_base64!" )
        pause
        exit /b 1
    )
    if not exist "!temp_base64!" (
        echo 错误：转换 Base64 编码文件生成失败："!temp_base64!"
        echo.
        pause
        exit /b 1
    )
    if exist "!temp_cab!" ( del /f /q "!temp_cab!" )

    REM 提取内嵌代码，使用第 2 段模板
    set "inner_begin_marker=-----BEGIN BATCH CODE 2-----"
    set "inner_end_marker=-----END BATCH CODE 2-----"
    set "temp_output=%temp%\MyBatch_%random%_%random%_%random%_%random%.bat"
    set "output_target=!temp_output!"
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$lines = Get-Content -Encoding UTF8 -LiteralPath $env:script_path;" ^
        "$begin = [array]::IndexOf($lines, $env:inner_begin_marker) + 1;" ^
        "$end = [array]::IndexOf($lines, $env:inner_end_marker);" ^
        "if ($begin -lt 1 -or $end -lt $begin) {" ^
        "    Write-Host '错误：未找到内嵌的 bat 代码块' -ForegroundColor Red;" ^
        "    exit 1;" ^
        "};" ^
        "$code = $lines[$begin..($end - 1)];" ^
        "$safe_file_name_ext = $env:file_name_ext.Replace('%%', '%%%%');" ^
        "for ($i = 0; $i -lt $code.Count; $i++) {" ^
        "    $code[$i] = $code[$i].Replace($env:origin_file_name_marker, $safe_file_name_ext);" ^
        "    $code[$i] = $code[$i].Replace($env:origin_file_size_marker, $env:file_size);" ^
        "    $code[$i] = $code[$i].Replace($env:origin_file_content_sha512_marker, $env:file_content_sha512);" ^
        "};" ^
        "$utf8NoBom = New-Object System.Text.UTF8Encoding($false);" ^
        "[System.IO.File]::WriteAllLines($env:output_target, $code, $utf8NoBom);"
    if !errorlevel! neq 0 (
        echo 错误：提取内嵌代码失败："!output_target!"
        echo.
        if exist "!temp_base64!" ( del /f /q "!temp_base64!" )
        pause
        exit /b 1
    )
    if not exist "!output_target!" (
        echo 错误：提取内嵌代码文件生成失败："!output_target!"
        echo.
        pause
        exit /b 1
    )

    REM 合并最终文件
    set "output_begin_marker=-----BEGIN CAB FILE-----"
    set "output_end_marker=-----END CAB FILE-----"
    (
        echo !output_begin_marker!
        type "!temp_base64!"
        echo !output_end_marker!
    ) >> "!output_target!"
    if exist "!temp_base64!" ( del /f /q "!temp_base64!" )

    for %%j in ("!temp_output!") do set "cab_size=%%~zj"
    echo 文件大小：!cab_size! 字节
    echo.

    set "size_smaller=0"
    for /f "delims=" %%c in ('powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "Write-Output ([int]([int64]$env:cab_size -lt [int64]$env:smallest_size));"'
    ) do (
        set "size_smaller=%%c"
    )
    if "!size_smaller!"=="1" (
        copy /b /y "!temp_output!" "!output_file!" >nul
        if !errorlevel! neq 0 (
            echo 错误：保留体积更小的 bat 脚本失败："!output_file!"
            echo.
            if exist "!temp_output!" ( del /f /q "!temp_output!" )
            pause
            exit /b 1
        )
        set "smallest_size=!cab_size!"
        set "smallest_format=cab 格式"
    )
    if exist "!temp_output!" ( del /f /q "!temp_output!" )



    REM 方式三：压缩为 7z 格式的自解压 exe，转换为 Base64 编码
    if "!use_7z_exe!"=="1" (
        echo 压缩方式：使用 7-Zip 压缩 7z 格式，再拼接 7zCon.sfx

        set "temp_7z=%temp%\MyBatch_%random%_%random%_%random%_%random%.7z"
        "!seven_zip!" a -t7z -mx=9 -m0=LZMA2 -md=2048m -mfb=256 -ms=off -mmt=on -mtc=off -mtm=off -mta=off -sccUTF-8 -scsUTF-8 -y "!temp_7z!" "!input_file!" >nul
        if !errorlevel! neq 0 (
            echo 错误：压缩失败："!input_file!"
            echo.
            if exist "!temp_7z!" ( del /f /q "!temp_7z!" )
            pause
            exit /b 1
        )
        if not exist "!temp_7z!" (
            echo 错误：压缩文件生成失败："!temp_7z!"
            echo.
            pause
            exit /b 1
        )

        set "temp_exe=%temp%\MyBatch_%random%_%random%_%random%_%random%.exe"
        copy /b /y "!seven_zip_sfx!" + "!temp_7z!" "!temp_exe!" >nul
        if !errorlevel! neq 0 (
            echo 错误：制作自解压 exe 失败："!temp_exe!"
            echo.
            if exist "!temp_7z!" ( del /f /q "!temp_7z!" )
            if exist "!temp_exe!" ( del /f /q "!temp_exe!" )
            pause
            exit /b 1
        )
        if exist "!temp_7z!" ( del /f /q "!temp_7z!" )

        REM 转换 Base64 编码
        set "temp_source=!temp_exe!"
        set "temp_base64=%temp%\MyBatch_%random%_%random%_%random%_%random%.7z.txt" & type nul > "!temp_base64!"
        powershell -NoProfile -Command ^
            "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
            "$bytes = [System.IO.File]::ReadAllBytes($env:temp_source);" ^
            "$base64 = [Convert]::ToBase64String($bytes);" ^
            "$list = New-Object System.Collections.Generic.List[string];" ^
            "for ($i = 0; $i -lt $base64.Length; $i += 64) {" ^
            "    $length = [Math]::Min(64, $base64.Length - $i);" ^
            "    $list.Add($base64.Substring($i, $length));" ^
            "};" ^
            "$utf8NoBom = New-Object System.Text.UTF8Encoding($false);" ^
            "[System.IO.File]::WriteAllLines($env:temp_base64, $list, $utf8NoBom);"
        if !errorlevel! neq 0 (
            echo 错误：转换 Base64 编码失败："!input_file!"
            echo.
            if exist "!temp_exe!" ( del /f /q "!temp_exe!" )
            if exist "!temp_base64!" ( del /f /q "!temp_base64!" )
            pause
            exit /b 1
        )
        if not exist "!temp_base64!" (
            echo 错误：转换 Base64 编码文件生成失败："!temp_base64!"
            echo.
            pause
            exit /b 1
        )
        if exist "!temp_exe!" ( del /f /q "!temp_exe!" )

        REM 提取内嵌代码，使用第 3 段模板
        set "inner_begin_marker=-----BEGIN BATCH CODE 3-----"
        set "inner_end_marker=-----END BATCH CODE 3-----"
        set "temp_output=%temp%\MyBatch_%random%_%random%_%random%_%random%.bat"
        set "output_target=!temp_output!"
        powershell -NoProfile -Command ^
            "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
            "$lines = Get-Content -Encoding UTF8 -LiteralPath $env:script_path;" ^
            "$begin = [array]::IndexOf($lines, $env:inner_begin_marker) + 1;" ^
            "$end = [array]::IndexOf($lines, $env:inner_end_marker);" ^
            "if ($begin -lt 1 -or $end -lt $begin) {" ^
            "    Write-Host '错误：未找到内嵌的 bat 代码块' -ForegroundColor Red;" ^
            "    exit 1;" ^
            "};" ^
            "$code = $lines[$begin..($end - 1)];" ^
            "$safe_file_name_ext = $env:file_name_ext.Replace('%%', '%%%%');" ^
            "for ($i = 0; $i -lt $code.Count; $i++) {" ^
            "    $code[$i] = $code[$i].Replace($env:origin_file_name_marker, $safe_file_name_ext);" ^
            "    $code[$i] = $code[$i].Replace($env:origin_file_size_marker, $env:file_size);" ^
            "    $code[$i] = $code[$i].Replace($env:origin_file_content_sha512_marker, $env:file_content_sha512);" ^
            "};" ^
            "$utf8NoBom = New-Object System.Text.UTF8Encoding($false);" ^
            "[System.IO.File]::WriteAllLines($env:output_target, $code, $utf8NoBom);"
        if !errorlevel! neq 0 (
            echo 错误：提取内嵌代码失败："!output_target!"
            echo.
            if exist "!temp_base64!" ( del /f /q "!temp_base64!" )
            pause
            exit /b 1
        )
        if not exist "!output_target!" (
            echo 错误：提取内嵌代码文件生成失败："!output_target!"
            echo.
            pause
            exit /b 1
        )

        REM 合并最终文件
        set "output_begin_marker=-----BEGIN 7Z FILE-----"
        set "output_end_marker=-----END 7Z FILE-----"
        (
            echo !output_begin_marker!
            type "!temp_base64!"
            echo !output_end_marker!
        ) >> "!output_target!"
        if exist "!temp_base64!" ( del /f /q "!temp_base64!" )

        for %%j in ("!temp_output!") do set "seven_zip_size=%%~zj"
        echo 文件大小：!seven_zip_size! 字节
        echo.

        set "size_smaller=0"
        for /f "delims=" %%c in ('powershell -NoProfile -Command ^
            "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
            "Write-Output ([int]([int64]$env:seven_zip_size -lt [int64]$env:smallest_size));"'
        ) do (
            set "size_smaller=%%c"
        )
        if "!size_smaller!"=="1" (
            copy /b /y "!temp_output!" "!output_file!" >nul
            if !errorlevel! neq 0 (
                echo 错误：保留体积更小的 bat 脚本失败："!output_file!"
                echo.
                if exist "!temp_output!" ( del /f /q "!temp_output!" )
                pause
                exit /b 1
            )
            set "smallest_size=!seven_zip_size!"
            set "smallest_format=7z 自解压 exe 格式"
        )
        if exist "!temp_output!" ( del /f /q "!temp_output!" )
    )



    echo 打包完成，保留较小的 !smallest_format! 的文件
    echo.

    for %%j in ("!output_file!") do (
        setlocal disabledelayedexpansion
        set "file_size=%%~zj"
        setlocal enabledelayedexpansion

        echo 最终大小：!file_size! 字节

        endlocal
        endlocal
    )

    endlocal
    endlocal
)



echo.
pause
exit /b



-----BEGIN BATCH CODE 1-----
@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "origin_file_name=-----ORIGIN FILE NAME-----"
set "origin_file_size=-----ORIGIN FILE SIZE-----"
set "origin_file_content_sha512=-----ORIGIN FILE CONTENT SHA512-----"
set "all_args=%*"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" (
    cd /d "!script_dir!"
)
set "temp_dir=%temp%\MyBatch\cache\!origin_file_size!\!origin_file_content_sha512!"
if not exist "!temp_dir!" mkdir "!temp_dir!"
set "temp_file=!temp_dir!\!origin_file_name!"
set "already_extracted=0"
if exist "!temp_file!" (
    set "size_matched=0"
    for %%i in ("!temp_file!") do (
        if "!origin_file_size!"=="%%~zi" set "size_matched=1"
    )
    if "!size_matched!"=="1" (
        for /f "delims=" %%j in ('powershell -NoProfile -Command ^
            "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
            "$sha512 = [System.Security.Cryptography.SHA512]::Create();" ^
            "$contentBytes = [System.IO.File]::ReadAllBytes($env:temp_file);" ^
            "Write-Output ([System.BitConverter]::ToString($sha512.ComputeHash($contentBytes)).Replace('-', '').ToLowerInvariant());"'
        ) do (
            if "!origin_file_content_sha512!"=="%%j" set "already_extracted=1"
        )
    )
)
if "!already_extracted!"=="0" (
    set "begin_marker=-----BEGIN GZIP FILE-----"
    set "end_marker=-----END GZIP FILE-----"
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "Add-Type -AssemblyName System.IO.Compression;" ^
        "$lines = Get-Content -Encoding UTF8 -LiteralPath $env:script_path;" ^
        "$begin = [array]::IndexOf($lines, $env:begin_marker) + 1;" ^
        "$end = [array]::IndexOf($lines, $env:end_marker);" ^
        "if ($begin -lt 1 -or $end -lt $begin) {" ^
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
        if exist "!temp_dir!" ( rd /s /q "!temp_dir!" )
        exit /b 1
    )
)
if /i "!origin_file_name:~-4!"==".ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!temp_file!" !all_args!
) else if /i "!origin_file_name:~-4!"==".bat" (
    cmd /s /c ""!temp_file!" !all_args!"
) else if /i "!origin_file_name:~-3!"==".py" (
    python "!temp_file!" !all_args!
) else if /i "!origin_file_name:~-4!"==".exe" (
    "!temp_file!" !all_args!
) else (
    start "" /wait "!temp_file!" !all_args!
)
exit /b !errorlevel!
-----END BATCH CODE 1-----



-----BEGIN BATCH CODE 2-----
@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "origin_file_name=-----ORIGIN FILE NAME-----"
set "origin_file_size=-----ORIGIN FILE SIZE-----"
set "origin_file_content_sha512=-----ORIGIN FILE CONTENT SHA512-----"
set "all_args=%*"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" (
    cd /d "!script_dir!"
)
set "temp_dir=%temp%\MyBatch\cache\!origin_file_size!\!origin_file_content_sha512!"
if not exist "!temp_dir!" mkdir "!temp_dir!"
set "temp_file=!temp_dir!\!origin_file_name!"
set "temp_cab=%temp%\MyBatch_%random%_%random%_%random%_%random%.cab"
set "already_extracted=0"
if exist "!temp_file!" (
    set "size_matched=0"
    for %%i in ("!temp_file!") do (
        if "!origin_file_size!"=="%%~zi" set "size_matched=1"
    )
    if "!size_matched!"=="1" (
        for /f "delims=" %%j in ('powershell -NoProfile -Command ^
            "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
            "$sha512 = [System.Security.Cryptography.SHA512]::Create();" ^
            "$contentBytes = [System.IO.File]::ReadAllBytes($env:temp_file);" ^
            "Write-Output ([System.BitConverter]::ToString($sha512.ComputeHash($contentBytes)).Replace('-', '').ToLowerInvariant());"'
        ) do (
            if "!origin_file_content_sha512!"=="%%j" set "already_extracted=1"
        )
    )
)
if "!already_extracted!"=="0" (
    set "begin_marker=-----BEGIN CAB FILE-----"
    set "end_marker=-----END CAB FILE-----"
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$lines = Get-Content -Encoding UTF8 -LiteralPath $env:script_path;" ^
        "$begin = [array]::IndexOf($lines, $env:begin_marker) + 1;" ^
        "$end = [array]::IndexOf($lines, $env:end_marker);" ^
        "if ($begin -lt 1 -or $end -lt $begin) {" ^
        "    exit 1;" ^
        "};" ^
        "$base64 = ($lines[$begin..($end - 1)] -join '');" ^
        "$base64 = $base64 -replace '\s', '';" ^
        "$bytes = [Convert]::FromBase64String($base64);" ^
        "[System.IO.File]::WriteAllBytes($env:temp_cab, $bytes);"
    if !errorlevel! neq 0 (
        if exist "!temp_dir!" ( rd /s /q "!temp_dir!" )
        exit /b 1
    )
    if exist "!temp_file!" ( del /f /q "!temp_file!" )
    expand "!temp_cab!" "!temp_file!" >nul
    if !errorlevel! neq 0 (
        if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
        if exist "!temp_dir!" ( rd /s /q "!temp_dir!" )
        exit /b 1
    )
    if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
    if not exist "!temp_file!" (
        if exist "!temp_dir!" ( rd /s /q "!temp_dir!" )
        exit /b 1
    )
)
if /i "!origin_file_name:~-4!"==".ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!temp_file!" !all_args!
) else if /i "!origin_file_name:~-4!"==".bat" (
    cmd /s /c ""!temp_file!" !all_args!"
) else if /i "!origin_file_name:~-3!"==".py" (
    python "!temp_file!" !all_args!
) else if /i "!origin_file_name:~-4!"==".exe" (
    "!temp_file!" !all_args!
) else (
    start "" /wait "!temp_file!" !all_args!
)
exit /b !errorlevel!
-----END BATCH CODE 2-----



-----BEGIN BATCH CODE 3-----
@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "origin_file_name=-----ORIGIN FILE NAME-----"
set "origin_file_size=-----ORIGIN FILE SIZE-----"
set "origin_file_content_sha512=-----ORIGIN FILE CONTENT SHA512-----"
set "all_args=%*"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" (
    cd /d "!script_dir!"
)
set "temp_dir=%temp%\MyBatch\cache\!origin_file_size!\!origin_file_content_sha512!"
if not exist "!temp_dir!" mkdir "!temp_dir!"
set "temp_file=!temp_dir!\!origin_file_name!"
set "temp_exe=%temp%\MyBatch_%random%_%random%_%random%_%random%.exe"
set "already_extracted=0"
if exist "!temp_file!" (
    set "size_matched=0"
    for %%i in ("!temp_file!") do (
        if "!origin_file_size!"=="%%~zi" set "size_matched=1"
    )
    if "!size_matched!"=="1" (
        for /f "delims=" %%j in ('powershell -NoProfile -Command ^
            "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
            "$sha512 = [System.Security.Cryptography.SHA512]::Create();" ^
            "$contentBytes = [System.IO.File]::ReadAllBytes($env:temp_file);" ^
            "Write-Output ([System.BitConverter]::ToString($sha512.ComputeHash($contentBytes)).Replace('-', '').ToLowerInvariant());"'
        ) do (
            if "!origin_file_content_sha512!"=="%%j" set "already_extracted=1"
        )
    )
)
if "!already_extracted!"=="0" (
    set "begin_marker=-----BEGIN 7Z FILE-----"
    set "end_marker=-----END 7Z FILE-----"
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$lines = Get-Content -Encoding UTF8 -LiteralPath $env:script_path;" ^
        "$begin = [array]::IndexOf($lines, $env:begin_marker) + 1;" ^
        "$end = [array]::IndexOf($lines, $env:end_marker);" ^
        "if ($begin -lt 1 -or $end -lt $begin) {" ^
        "    exit 1;" ^
        "};" ^
        "$base64 = ($lines[$begin..($end - 1)] -join '');" ^
        "$base64 = $base64 -replace '\s', '';" ^
        "$bytes = [Convert]::FromBase64String($base64);" ^
        "[System.IO.File]::WriteAllBytes($env:temp_exe, $bytes);"
    if !errorlevel! neq 0 (
        if exist "!temp_dir!" ( rd /s /q "!temp_dir!" )
        exit /b 1
    )
    "!temp_exe!" -o"!temp_dir!" -y >nul
    if !errorlevel! neq 0 (
        if exist "!temp_exe!" ( del /f /q "!temp_exe!" )
        if exist "!temp_dir!" ( rd /s /q "!temp_dir!" )
        exit /b 1
    )
    if exist "!temp_exe!" ( del /f /q "!temp_exe!" )
    if not exist "!temp_file!" (
        if exist "!temp_dir!" ( rd /s /q "!temp_dir!" )
        exit /b 1
    )
)
if /i "!origin_file_name:~-4!"==".ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!temp_file!" !all_args!
) else if /i "!origin_file_name:~-4!"==".bat" (
    cmd /s /c ""!temp_file!" !all_args!"
) else if /i "!origin_file_name:~-3!"==".py" (
    python "!temp_file!" !all_args!
) else if /i "!origin_file_name:~-4!"==".exe" (
    "!temp_file!" !all_args!
) else (
    start "" /wait "!temp_file!" !all_args!
)
exit /b !errorlevel!
-----END BATCH CODE 3-----
