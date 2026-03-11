@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: Git 配置和 Bat 文件格式自检



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

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

for /r %%f in (*.bat) do (
    echo 检查文件：%%f

    :: 统一编码为 UTF-8 without BOM，统一换行符为 CRLF
    powershell -NoProfile -Command ^
        "$path='%%f';" ^
        "$bytes = [System.IO.File]::ReadAllBytes($path);" ^
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
        "[System.IO.File]::WriteAllText($path, $content, $utf8NoBOM);"

    :: 检查并添加 @echo off
    powershell -NoProfile -Command ^
        "$path='%%f';" ^
        "$utf8NoBOM = New-Object System.Text.UTF8Encoding($false);" ^
        "$lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8);" ^
        "if (($lines -join '`n') -notmatch '@echo off') {" ^
            "$lines = @('@echo off') + $lines;" ^
            "[System.IO.File]::WriteAllLines($path, $lines, $utf8NoBOM);" ^
        "}"

    :: 检查并添加 chcp 65001 >nul
    powershell -NoProfile -Command ^
        "$path='%%f';" ^
        "$utf8NoBOM = New-Object System.Text.UTF8Encoding($false);" ^
        "$lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8);" ^
        "if (($lines -join '`n') -notmatch 'chcp 65001') {" ^
            "$newLines = New-Object System.Collections.Generic.List[string];" ^
            "$newLines.Add($lines[0]);" ^
            "$newLines.Add('chcp 65001 >nul');" ^
            "if ($lines.Count -gt 1) {" ^
                "$newLines.AddRange($lines[1..($lines.Count - 1)]);" ^
            "}" ^
            "[System.IO.File]::WriteAllLines($path, $newLines, $utf8NoBOM);" ^
        "}"
)



echo.
pause
exit /b
