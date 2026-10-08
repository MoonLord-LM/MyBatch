@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '把 ps1 bat exe 文件转换为 bat 脚本，双击生成的 bat 脚本，即可运行原来的文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽 ps1 bat exe 文件到此脚本上，则在源文件所在的文件夹，生成名称带有 3 清理注释换行 的 bat 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '转换方式：先清理注释、空行和多余的换行，再用 gzip 压缩后转换为 Base64 编码嵌入 bat 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host 'exe 文件属于二进制文件，不清理内容，直接压缩后嵌入 bat 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '优先使用 7-Zip 组件压缩，找不到时自动改用 PowerShell 内置的 GZipStream 压缩' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '这种方式的体积最小，但是清理代码的规则比较简单，转换完成后请务必运行测试' -ForegroundColor Green"
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
set "output_path=!param1_dir!!param1_name! - 3 清理注释换行.bat"
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

REM 清理注释行、空行、行首尾的空格，并把上一行结尾为 { 或本行开头为 } 的代码合并到上一行
REM ps1 文件的注释为 # 开头，bat 文件的注释为 REM 或 :: 开头，exe 文件为二进制文件，直接复制不清理
REM 统一为 UTF-8 编码后保存到临时文件，ps1 文件保存为带 BOM 的编码，bat 文件保存为不带 BOM 的编码
set "temp_payload=%temp%\MyBatch_%random%_%random%_%random%_%random%!payload_ext!" & type nul > "!temp_payload!"
set "step_desc=清理 bat 文件的注释和换行"
if /i "!payload_ext!" == ".ps1" set "step_desc=清理 ps1 文件的注释和换行"
if /i "!payload_ext!" == ".exe" set "step_desc=复制源文件"
powershell -NoProfile -Command ^
    "$ext = $env:payload_ext.ToLower();" ^
    "if ($ext -eq '.exe') {" ^
    "    [System.IO.File]::Copy($env:source_path, $env:temp_payload, $true);" ^
    "} elseif ($ext -eq '.ps1') {" ^
    "    $lines = [System.IO.File]::ReadAllLines($env:source_path, [System.Text.Encoding]::UTF8);" ^
    "    $out = New-Object System.Collections.Generic.List[string];" ^
    "    foreach ($line in $lines) {" ^
    "        $line = $line.Trim();" ^
    "        if ($line.StartsWith('#')) {" ^
    "            continue;" ^
    "        }" ^
    "        if ($line -eq '') {" ^
    "            continue;" ^
    "        }" ^
    "        if ($out.Count -gt 0) {" ^
    "            $prev = $out[$out.Count - 1];" ^
    "            if ($prev.Contains('#') -eq $false) {" ^
    "                if ($prev.EndsWith('{')) {" ^
    "                    $out[$out.Count - 1] = $prev + $line;" ^
    "                    continue;" ^
    "                }" ^
    "                if ($line.StartsWith('}')) {" ^
    "                    $out[$out.Count - 1] = $prev + $line;" ^
    "                    continue;" ^
    "                }" ^
    "            }" ^
    "        }" ^
    "        $out.Add($line);" ^
    "    }" ^
    "    $enc = New-Object System.Text.UTF8Encoding($true);" ^
    "    [System.IO.File]::WriteAllLines($env:temp_payload, $out, $enc);" ^
    "} else {" ^
    "    $lines = [System.IO.File]::ReadAllLines($env:source_path, [System.Text.Encoding]::UTF8);" ^
    "    $out = New-Object System.Collections.Generic.List[string];" ^
    "    foreach ($line in $lines) {" ^
    "        $line = $line.Trim();" ^
    "        if ($line -eq '') {" ^
    "            continue;" ^
    "        }" ^
    "        if ($line -match '^@?(rem(\s|$)|:{2,})') {" ^
    "            continue;" ^
    "        }" ^
    "        $out.Add($line);" ^
    "    }" ^
    "    $enc = New-Object System.Text.UTF8Encoding($false);" ^
    "    [System.IO.File]::WriteAllLines($env:temp_payload, $out, $enc);" ^
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

REM 生成 bat 文件时，切换到 disabledelayedexpansion 环境，保证 ! 和 ^ 等符号可以按原样写入
setlocal disabledelayedexpansion
(
    echo @echo off
    echo chcp 65001 ^>nul
    echo setlocal disabledelayedexpansion
    echo set "script=%%~0" ^& set "script_path=%%~f0" ^& set "script_dir=%%~dp0" ^& set "script_name=%%~n0" ^& set "script_ext=%%~x0" ^& set "script_name_ext=%%~nx0"
    echo setlocal enabledelayedexpansion
    echo powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" ^&^& echo.
    echo.
    echo.
    echo.
    echo REM 本文件由 %payload_ext:~1% 文件自动打包生成
    echo REM 开源地址: https://github.com/MoonLord-LM/MyBatch
    echo powershell -NoProfile -Command "Write-Host '把内嵌的 Base64 编码内容解码解压还原为 %payload_ext:~1% 文件，然后自动运行' -ForegroundColor Green"
    echo echo.
    echo.
    echo.
    echo.
    echo if /i "!cd!"=="!SystemRoot!\System32" ^(
    echo     echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 ^& echo.
    echo     cd /d "!script_dir!"
    echo ^)
    echo.
    echo.
    echo.
    echo set "payload_ext=%payload_ext%"
    echo set "temp_file=%%temp%%\MyBatch_%%random%%_%%random%%_%%random%%_%%random%%!payload_ext!"
    echo set "self_path=%%~f0"
    echo set "begin_marker=%BEGIN_MARKER%"
    echo set "end_marker=%END_MARKER%"
    echo.
    echo powershell -NoProfile -Command ^^
    echo     "Add-Type -AssemblyName System.IO.Compression;" ^^
    echo     "$lines = [System.IO.File]::ReadAllLines($env:self_path, [System.Text.Encoding]::UTF8);" ^^
    echo     "$begin = -1;" ^^
    echo     "$end = -1;" ^^
    echo     "for ($i = 0; $i -lt $lines.Count; $i++) {" ^^
    echo     "    if ($lines[$i] -eq $env:begin_marker) {" ^^
    echo     "        $begin = $i;" ^^
    echo     "        break;" ^^
    echo     "    }" ^^
    echo     "}" ^^
    echo     "if ($begin -lt 0) {" ^^
    echo     "    Write-Host '错误：找不到压缩内容的开始标记' -ForegroundColor Red;" ^^
    echo     "    exit 1;" ^^
    echo     "}" ^^
    echo     "for ($i = $begin + 1; $i -lt $lines.Count; $i++) {" ^^
    echo     "    if ($lines[$i] -eq $env:end_marker) {" ^^
    echo     "        $end = $i;" ^^
    echo     "        break;" ^^
    echo     "    }" ^^
    echo     "}" ^^
    echo     "if ($end -lt 0) {" ^^
    echo     "    Write-Host '错误：找不到压缩内容的结束标记' -ForegroundColor Red;" ^^
    echo     "    exit 1;" ^^
    echo     "}" ^^
    echo     "if ($end - $begin -le 1) {" ^^
    echo     "    Write-Host '错误：压缩内容为空' -ForegroundColor Red;" ^^
    echo     "    exit 1;" ^^
    echo     "}" ^^
    echo     "$base64 = ($lines[($begin + 1)..($end - 1)] -join '') -replace '\s', '';" ^^
    echo     "$bytes = [Convert]::FromBase64String($base64);" ^^
    echo     "$ms = New-Object System.IO.MemoryStream (,$bytes);" ^^
    echo     "$gzip = New-Object System.IO.Compression.GzipStream($ms, [System.IO.Compression.CompressionMode]::Decompress);" ^^
    echo     "$outMs = New-Object System.IO.MemoryStream;" ^^
    echo     "$gzip.CopyTo($outMs);" ^^
    echo     "$gzip.Close();" ^^
    echo     "$ms.Close();" ^^
    echo     "$rawBytes = $outMs.ToArray();" ^^
    echo     "$outMs.Close();" ^^
    echo     "[System.IO.File]::WriteAllBytes($env:temp_file, $rawBytes);"
    echo.
    echo if !errorlevel! neq 0 goto fail_extract
    echo.
    echo if /i "!payload_ext!" == ".ps1" ^(
    echo     powershell -NoProfile -ExecutionPolicy Bypass -File "!temp_file!"
    echo ^) else if /i "!payload_ext!" == ".bat" ^(
    echo     call "!temp_file!"
    echo ^) else ^(
    echo     "!temp_file!"
    echo ^)
    echo set "exitcode=!errorlevel!"
    echo if exist "!temp_file!" ^( del /f /q "!temp_file!" ^)
    echo.
    echo.
    echo.
    echo echo.
    echo pause
    echo endlocal ^& endlocal ^& exit /b %%exitcode%%
    echo.
    echo :fail_extract
    echo echo 错误：还原文件内容失败
    echo echo.
    echo if exist "!temp_file!" ^( del /f /q "!temp_file!" ^)
    echo pause
    echo endlocal ^& endlocal ^& exit /b 1
    echo.
    echo.
    echo.
    echo %BEGIN_MARKER%
    type "%temp_base64%"
    echo %END_MARKER%
) > "%output_path%"
endlocal

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
