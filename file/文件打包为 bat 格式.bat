@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '把 ps1 bat exe 文件转换为 bat 脚本，双击生成的 bat 脚本，即可运行原来的文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽 ps1 bat exe 文件到此脚本上，则在源文件所在的文件夹，生成名称带有 2 压缩编码 的 bat 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '转换方式：把源文件内容用 gzip 压缩后转换为 Base64 编码嵌入 bat 文件，运行时自动解码解压并执行' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '优先使用 7-Zip 组件压缩，找不到时自动改用 PowerShell 内置的 GZipStream 压缩' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '这种方式完整保留了注释和换行，只是看不到原始代码' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 检查 7-Zip 组件
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
if not "!seven_zip!" == "" (
    "!seven_zip!" i >nul 2>&1
    if !errorlevel! neq 0 ( set "seven_zip=" )
)



if "!param1!" == "" (
    echo 请把要转换的 ps1 bat exe 文件，拖拽到此脚本上
    echo.
    exit /b 1
)
if not exist "!param1!" (
    echo 错误：路径不存在："!param1!"
    echo.
    pause
    exit /b 1
)
if exist "!param1!\" (
    echo 错误：路径不是文件："!param1!"
    echo.
    pause
    exit /b 1
)
set "payload_ext="
for %%e in (.ps1 .bat .exe) do (
    if /i "!param1_ext!" == "%%e" set "payload_ext=%%e"
)
if "!payload_ext!" == "" (
    echo 错误：不是 ps1 bat exe 文件："!param1!"
    echo.
    pause
    exit /b 1
)



set "source_path=!param1_path!"
set "output_path=!param1_dir!!param1_name! - 2 压缩编码.bat"
set "BEGIN_MARKER=REM -----BEGIN PAYLOAD ZIP-----"
set "END_MARKER=REM -----END PAYLOAD ZIP-----"

echo 源文件："!source_path!"
powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Write-Output ('源文件大小：' + (Get-Item -LiteralPath $env:source_path).Length + ' 字节')"
echo 输出文件："!output_path!"
echo.

if "!seven_zip!" == "" (
    echo 压缩方式：PowerShell 内置的 GZipStream 压缩
) else (
    echo 压缩方式：7-Zip 压缩
)
echo.

if exist "!output_path!" ( del /f /q "!output_path!" )

REM 读取源文件的全部内容，保存到临时文件，exe 文件直接复制，ps1 文件统一为带 BOM 的 UTF-8 编码，bat 文件统一为不带 BOM 的 UTF-8 编码
set "temp_payload=%temp%\MyBatch_%random%_%random%_%random%_%random%!payload_ext!" & type nul > "!temp_payload!"
set "step_desc=读取源文件"
if /i "!payload_ext!" == ".exe" set "step_desc=复制源文件"
powershell -NoProfile -Command ^
    "$ext = $env:payload_ext.ToLower();" ^
    "if ($ext -eq '.exe') {" ^
    "    [System.IO.File]::Copy($env:source_path, $env:temp_payload, $true);" ^
    "} else {" ^
    "    $lines = [System.IO.File]::ReadAllLines($env:source_path, [System.Text.Encoding]::UTF8);" ^
    "    if ($ext -eq '.ps1') { $enc = New-Object System.Text.UTF8Encoding($true) } else { $enc = New-Object System.Text.UTF8Encoding($false) }" ^
    "    [System.IO.File]::WriteAllLines($env:temp_payload, $lines, $enc);" ^
    "}"
if !errorlevel! neq 0 (
    echo 错误：!step_desc!失败："!source_path!"
    echo.
    if exist "!temp_payload!" ( del /f /q "!temp_payload!" )
    pause
    exit /b 1
)

powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Write-Output ('处理后的大小：' + (Get-Item -LiteralPath $env:temp_payload).Length + ' 字节')"
echo.

REM 用 gzip 压缩源文件内容，保存到临时文件
set "temp_gzip=%temp%\MyBatch_%random%_%random%_%random%_%random%.gz"
if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
if "!seven_zip!" == "" (
    powershell -NoProfile -Command ^
        "Add-Type -AssemblyName System.IO.Compression;" ^
        "$rawBytes = [System.IO.File]::ReadAllBytes($env:temp_payload);" ^
        "$ms = New-Object System.IO.MemoryStream;" ^
        "$gzip = New-Object System.IO.Compression.GzipStream($ms, [System.IO.Compression.CompressionMode]::Compress);" ^
        "$gzip.Write($rawBytes, 0, $rawBytes.Length);" ^
        "$gzip.Close();" ^
        "$bytes = $ms.ToArray();" ^
        "$ms.Close();" ^
        "[System.IO.File]::WriteAllBytes($env:temp_gzip, $bytes);"
    if !errorlevel! neq 0 (
        echo 错误：压缩源文件失败："!source_path!"
        echo.
        if exist "!temp_payload!" ( del /f /q "!temp_payload!" )
        if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
        pause
        exit /b 1
    )
) else (
    "!seven_zip!" a -tgzip -mx=9 -mtc=off -mtm=off -mta=off -si"!param1_name_ext!" "!temp_gzip!" < "!temp_payload!" >nul
    if !errorlevel! neq 0 (
        echo 错误：使用 7-Zip 压缩失败："!source_path!"
        echo.
        if exist "!temp_payload!" ( del /f /q "!temp_payload!" )
        if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
        pause
        exit /b 1
    )
)
if not exist "!temp_gzip!" (
    echo 错误：压缩源文件失败："!source_path!"
    echo.
    if exist "!temp_payload!" ( del /f /q "!temp_payload!" )
    pause
    exit /b 1
)

if exist "!temp_payload!" ( del /f /q "!temp_payload!" )

REM 把压缩后的内容转换为 Base64 编码，每 64 个字符一行，保存到临时文件
set "temp_base64=%temp%\MyBatch_%random%_%random%_%random%_%random%.txt" & type nul > "!temp_base64!"
powershell -NoProfile -Command ^
    "$bytes = [System.IO.File]::ReadAllBytes($env:temp_gzip);" ^
    "$base64 = [Convert]::ToBase64String($bytes);" ^
    "$list = New-Object System.Collections.Generic.List[string];" ^
    "for ($i = 0; $i -lt $base64.Length; $i += 64) {" ^
    "    $list.Add($base64.Substring($i, [Math]::Min(64, $base64.Length - $i)));" ^
    "}" ^
    "$utf8NoBOM = New-Object System.Text.UTF8Encoding($false);" ^
    "[System.IO.File]::WriteAllLines($env:temp_base64, $list, $utf8NoBOM);"
if !errorlevel! neq 0 (
    echo 错误：Base64 编码失败："!source_path!"
    echo.
    if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
    if exist "!temp_base64!" ( del /f /q "!temp_base64!" )
    pause
    exit /b 1
)

if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )

REM 生成 bat 文件时，从自身文件末尾的 -----BEGIN BATCH CODE----- / -----END BATCH CODE----- 之间提取 bat 代码原样写入
REM 这样生成的 bat 代码里的 ! 和 ^ 和 % 等符号都不需要转义处理，统一保存为不带 BOM 的 UTF-8 编码
powershell -NoProfile -Command ^
    "$lines = [System.IO.File]::ReadAllLines($env:script_path, [System.Text.Encoding]::UTF8);" ^
    "$begin = [array]::IndexOf($lines, '-----BEGIN BATCH CODE-----');" ^
    "$end = [array]::IndexOf($lines, '-----END BATCH CODE-----');" ^
    "if ($begin -lt 0 -or $end -le $begin) {" ^
    "    Write-Host '错误：未找到内嵌的 bat 代码块' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "}" ^
    "$code = $lines[($begin + 1)..($end - 1)];" ^
    "for ($i = 0; $i -lt $code.Count; $i++) {" ^
    "    $code[$i] = $code[$i].Replace('__PAYLOAD_EXT_NAME__', $env:payload_ext.TrimStart('.')).Replace('__PAYLOAD_EXT__', $env:payload_ext).Replace('__BEGIN_MARKER__', $env:BEGIN_MARKER).Replace('__END_MARKER__', $env:END_MARKER);" ^
    "}" ^
    "$enc = New-Object System.Text.UTF8Encoding($false);" ^
    "[System.IO.File]::WriteAllLines($env:output_path, $code, $enc);"
if !errorlevel! neq 0 (
    echo 错误：生成 bat 文件失败："!output_path!"
    echo.
    if exist "!temp_base64!" ( del /f /q "!temp_base64!" )
    pause
    exit /b 1
)

REM 把 Base64 编码内容，追加到生成文件的开始标记之后，并补上结束标记
(
    type "!temp_base64!"
    echo !END_MARKER!
) >> "!output_path!"

if exist "!temp_base64!" ( del /f /q "!temp_base64!" )

if not exist "!output_path!" (
    echo 错误：生成 bat 文件失败："!output_path!"
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Write-Output ('输出文件大小：' + (Get-Item -LiteralPath $env:output_path).Length + ' 字节')"
echo 生成成功："!output_path!"



echo.
pause
endlocal & endlocal & exit /b


-----BEGIN BATCH CODE-----
@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.
echo.
echo.
echo.
REM 本文件由 __PAYLOAD_EXT_NAME__ 文件自动打包生成
REM 开源地址: https://github.com/MoonLord-LM/MyBatch
powershell -NoProfile -Command "Write-Host '把内嵌的 Base64 编码内容解码解压还原为 __PAYLOAD_EXT_NAME__ 文件，然后自动运行' -ForegroundColor Green"
echo.
echo.
echo.
echo.
if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)
echo.
echo.
echo.
set "payload_ext=__PAYLOAD_EXT__"
set "temp_file=%temp%\MyBatch_%random%_%random%_%random%_%random%!payload_ext!"
set "self_path=%~f0"
set "begin_marker=__BEGIN_MARKER__"
set "end_marker=__END_MARKER__"
echo.
powershell -NoProfile -Command ^
    "Add-Type -AssemblyName System.IO.Compression;" ^
    "$lines = [System.IO.File]::ReadAllLines($env:self_path, [System.Text.Encoding]::UTF8);" ^
    "$begin = -1;" ^
    "$end = -1;" ^
    "for ($i = 0; $i -lt $lines.Count; $i++) {" ^
    "    if ($lines[$i] -eq $env:begin_marker) {" ^
    "        $begin = $i;" ^
    "        break;" ^
    "    }" ^
    "}" ^
    "if ($begin -lt 0) {" ^
    "    Write-Host '错误：找不到压缩内容的开始标记' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "}" ^
    "for ($i = $begin + 1; $i -lt $lines.Count; $i++) {" ^
    "    if ($lines[$i] -eq $env:end_marker) {" ^
    "        $end = $i;" ^
    "        break;" ^
    "    }" ^
    "}" ^
    "if ($end -lt 0) {" ^
    "    Write-Host '错误：找不到压缩内容的结束标记' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "}" ^
    "if ($end - $begin -le 1) {" ^
    "    Write-Host '错误：压缩内容为空' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "}" ^
    "$base64 = ($lines[($begin + 1)..($end - 1)] -join '') -replace '\s', '';" ^
    "$bytes = [Convert]::FromBase64String($base64);" ^
    "$ms = New-Object System.IO.MemoryStream (,$bytes);" ^
    "$gzip = New-Object System.IO.Compression.GzipStream($ms, [System.IO.Compression.CompressionMode]::Decompress);" ^
    "$outMs = New-Object System.IO.MemoryStream;" ^
    "$gzip.CopyTo($outMs);" ^
    "$gzip.Close();" ^
    "$ms.Close();" ^
    "$rawBytes = $outMs.ToArray();" ^
    "$outMs.Close();" ^
    "[System.IO.File]::WriteAllBytes($env:temp_file, $rawBytes);"
echo.
if !errorlevel! neq 0 goto fail_extract
echo.
if /i "!payload_ext!" == ".ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!temp_file!"
) else if /i "!payload_ext!" == ".bat" (
    call "!temp_file!"
) else (
    "!temp_file!"
)
set "exitcode=!errorlevel!"
if exist "!temp_file!" ( del /f /q "!temp_file!" )
echo.
echo.
echo.
echo.
pause
endlocal & endlocal & exit /b %exitcode%
echo.
:fail_extract
echo 错误：还原文件内容失败
echo.
if exist "!temp_file!" ( del /f /q "!temp_file!" )
pause
endlocal & endlocal & exit /b 1
echo.
echo.
echo.
__BEGIN_MARKER__
-----END BATCH CODE-----
