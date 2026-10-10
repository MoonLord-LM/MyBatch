@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '打开当前用户的自启动文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '放在这个目录中的程序或快捷方式，会在用户登录时自动运行' -ForegroundColor Green"
echo.



"explorer.exe" "shell:Startup"



echo.
timeout /t 3 /nobreak
exit /b
