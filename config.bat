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



for %%f in (*.bat) do (
    echo 处理文件：%%f
    powershell -NoProfile -Command ^
        "$path='%%f';" ^
        "$bytes = [System.IO.File]::ReadAllBytes($path);" ^
        "try {" ^
            "$content = [System.Text.Encoding]::UTF8.GetString($bytes);" ^
            "if (-not ($content -as [string])) { throw 'not utf8' }" ^
        "} catch {" ^
            "$content = [System.Text.Encoding]::GetEncoding(936).GetString($bytes);" ^
        "}" ^
        "$content = $content -replace '(\r?\n)', \""`r`n\"";" ^
        "Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline;"
)



pause
exit
