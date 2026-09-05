@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '扫描当前文件夹下的所有 bat 文件，自动处理编码规范问题' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



REM 设置 Git 仓库的本地配置
git config --local core.autocrlf false
git config --local core.safecrlf false
git config --local core.ignorecase false
git config --local core.quotepath false
git config --local i18n.logoutputencoding utf-8
git config --local i18n.commitencoding utf-8

echo.
echo 当前 Git 配置：
git config --local --list
echo.

set "root_dir=!script_dir!"
for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:root_dir -File -Force -Recurse -Filter *.bat | ForEach-Object { $_.FullName }"') do (
    setlocal disabledelayedexpansion
    set "bat_file=%%f"
    set "file_dir=%%~dpf"
    set "base_name=%%~nf"
    set "file_ext=%%~xf"
    setlocal enabledelayedexpansion

    echo 检查文件："!bat_file!"

    REM 统一编码为 UTF-8 without BOM，统一换行符为 CRLF
    powershell -NoProfile -Command ^
        "$bytes = [System.IO.File]::ReadAllBytes($env:bat_file);" ^
        "$utf8NoBOM = New-Object System.Text.UTF8Encoding($false);" ^
        "$utf8Decoder = [System.Text.Encoding]::UTF8.GetDecoder();" ^
        "$utf8Decoder.Fallback = [System.Text.DecoderExceptionFallback]::new();" ^
        "try {" ^
            "$chars = New-Object Char[] ($utf8Decoder.GetCharCount($bytes, 0, $bytes.Length));" ^
            "$utf8Decoder.GetChars($bytes, 0, $bytes.Length, $chars, 0);" ^
            "$content = -join $chars;" ^
        "} catch [System.Text.DecoderFallbackException] {" ^
            "$content = [System.Text.Encoding]::GetEncoding(936).GetString($bytes);" ^
        "}" ^
        "$content = $content -replace '(\r?\n)', \""`r`n\"";" ^
        "[System.IO.File]::WriteAllText($env:bat_file, $content, $utf8NoBOM);"

    REM 检查并添加 @echo off
    powershell -NoProfile -Command ^
        "$lines = [System.IO.File]::ReadAllLines($env:bat_file, [System.Text.Encoding]::UTF8);" ^
        "if (($lines -join '`n') -notmatch '@echo off') {" ^
            "$lines = @('@echo off') + $lines;" ^
            "[System.IO.File]::WriteAllLines($env:bat_file, $lines, $utf8NoBOM);" ^
        "}"

    REM 检查并添加 chcp 65001 >nul
    powershell -NoProfile -Command ^
        "$lines = [System.IO.File]::ReadAllLines($env:bat_file, [System.Text.Encoding]::UTF8);" ^
        "if (($lines -join '`n') -notmatch 'chcp 65001') {" ^
            "$newLines = New-Object System.Collections.Generic.List[string];" ^
            "$newLines.Add($lines[0]);" ^
            "$newLines.Add('chcp 65001 >nul');" ^
            "if ($lines.Count -gt 1) {" ^
                "$newLines.AddRange($lines[1..($lines.Count - 1)]);" ^
            "}" ^
            "[System.IO.File]::WriteAllLines($env:bat_file, $newLines, $utf8NoBOM);" ^
        "}"

    endlocal
    endlocal
    echo.
)



echo.
pause
endlocal & endlocal & exit /b
