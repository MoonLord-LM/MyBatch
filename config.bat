@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion



git config --local core.autocrlf false
git config --local core.safecrlf false
git config --local core.ignorecase false

git config --local core.quotepath false
git config --local i18n.logoutputencoding utf-8
git config --local i18n.commitencoding utf-8

echo.
echo 查看当前 Git 配置：
git config --local --list
echo.



for /r %%f in (*.bat) do (
    echo 处理文件：%%f
    powershell -NoProfile -Command ^
        "$path='%%f';" ^
        "$bytes = [System.IO.File]::ReadAllBytes($path);" ^
        "$utf8NoBOM = New-Object System.Text.UTF8Encoding($false);" ^
        "$utf8Decoder = [System.Text.Encoding]::UTF8.GetDecoder();" ^
        "$utf8Decoder.Fallback = [System.Text.DecoderExceptionFallback]::new();" ^
        "try {" ^
            "$chars = New-Object Char[] ($utf8.GetCharCount($bytes, 0, $bytes.Length));" ^
            "$utf8Decoder.GetChars($bytes, 0, $bytes.Length, $chars, 0);" ^
            "$content = -join $chars" ^
        "} catch [System.Text.DecoderFallbackException] {" ^
            "$content = [System.Text.Encoding]::GetEncoding(936).GetString($bytes);" ^
        "}" ^
        "$content = $content -replace '(\r?\n)', \"`r`n\";" ^
        "[System.IO.File]::WriteAllText($path, $content, $utf8NoBOM);"
)



pause
exit
