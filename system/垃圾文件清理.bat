@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)
echo.



REM 龙之谷 DragonNest
set "reg_value="
for /f "tokens=2,*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\SHENGQUGAMES\DN" /v "Loader"') do (
    setlocal disabledelayedexpansion
    set "reg_value=%%b"
    set "root_dir=%%~dpb"
    setlocal enabledelayedexpansion
    if not "!reg_value!"=="" (
        echo 正在清理文件夹："!root_dir!"
        set "temp_list=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!temp_list!"
        dir /b /a-d "!root_dir!*.dmp" 2>nul >> "!temp_list!"
        dir /b /a-d "!root_dir!Log\*.log" 2>nul >> "!temp_list!"
        dir /b /a-d "!root_dir!TempRes\*.tmp" 2>nul >> "!temp_list!"
        powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; Get-Content -Encoding UTF8 -LiteralPath $env:temp_list | ForEach-Object { [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile((Join-Path $env:root_dir $_),'OnlyErrorDialogs','SendToRecycleBin') }"
        if exist "!temp_list!" ( del /f /q "!temp_list!" )
    )
    endlocal
    endlocal
)
echo.



REM 原神 Genshin Impact
set "reg_value="
for /f "tokens=2,*" %%a in ('reg query "HKEY_CURRENT_USER\Software\miHoYo\HYP\1_1\hk4e_cn" /v "GameInstallPath"') do (
    setlocal disabledelayedexpansion
    set "reg_value=%%b"
    set "root_dir=%%b"
    setlocal enabledelayedexpansion
    if not "!reg_value!"=="" (
        if not "!root_dir:~-1!"=="\" set "root_dir=!root_dir!\"
        echo 正在清理文件夹："!root_dir!"
        set "temp_list=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!temp_list!"
        dir /b /a-d "!root_dir!Genshin Impact Game\*.dmp" 2>nul >> "!temp_list!"
        powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; Get-Content -Encoding UTF8 -LiteralPath $env:temp_list | ForEach-Object { [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile((Join-Path $env:root_dir $_),'OnlyErrorDialogs','SendToRecycleBin') }"
        if exist "!temp_list!" ( del /f /q "!temp_list!" )
    )
    endlocal
    endlocal
)



echo.
pause
endlocal & endlocal & exit /b
