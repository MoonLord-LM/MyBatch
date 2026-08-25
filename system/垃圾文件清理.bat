@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，自动扫描和清理各种垃圾文件' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)
echo.



echo 开始扫描
echo.
set "log_file=!script_name!.log"
powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; ('-- ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' --') | Out-File -LiteralPath $env:log_file -Append -Encoding UTF8"

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
        dir /s /b /a-d "!root_dir!*.dmp" 2>nul >> "!temp_list!"
        dir /s /b /a-d "!root_dir!Log\*.log" 2>nul >> "!temp_list!"
        dir /s /b /a-d "!root_dir!TempRes\*.tmp" 2>nul >> "!temp_list!"
        powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Add-Type -AssemblyName Microsoft.VisualBasic; $files = Get-Content -Encoding UTF8 -LiteralPath $env:temp_list; $files | ForEach-Object { [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($_,'OnlyErrorDialogs','SendToRecycleBin') }; Write-Host ('删除完成，共删除 ' + $files.Count + ' 个文件') -ForegroundColor Green"

        type "!temp_list!" >> "!log_file!"
        if exist "!temp_list!" ( del /f /q "!temp_list!" )
    )
    endlocal
    endlocal
)

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
        dir /s /b /a-d "!root_dir!*.dmp" 2>nul >> "!temp_list!"
        powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Add-Type -AssemblyName Microsoft.VisualBasic; $files = Get-Content -Encoding UTF8 -LiteralPath $env:temp_list; $files | ForEach-Object { [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($_,'OnlyErrorDialogs','SendToRecycleBin') }; Write-Host ('删除完成，共删除 ' + $files.Count + ' 个文件') -ForegroundColor Green"

        type "!temp_list!" >> "!log_file!"
        if exist "!temp_list!" ( del /f /q "!temp_list!" )
    )
    endlocal
    endlocal
)

REM Intel Extreme Tuning Utility
set "root_dir=C:\ProgramData\Intel\Intel Extreme Tuning Utility\"
if exist "!root_dir!Logs\*.log" (
    echo 正在清理文件夹："!root_dir!"

    set "temp_list=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!temp_list!"
    dir /s /b /a-d "!root_dir!Logs\*.log" 2>nul >> "!temp_list!"
    powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Add-Type -AssemblyName Microsoft.VisualBasic; $files = Get-Content -Encoding UTF8 -LiteralPath $env:temp_list; $files | ForEach-Object { [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($_,'OnlyErrorDialogs','SendToRecycleBin') }; Write-Host ('删除完成，共删除 ' + $files.Count + ' 个文件') -ForegroundColor Green"

    type "!temp_list!" >> "!log_file!"
    if exist "!temp_list!" ( del /f /q "!temp_list!" )
)

echo.
echo 完成扫描，清理记录已保存到 "!log_file!" 文件中
echo.>> "!log_file!"



echo.
pause
endlocal & endlocal & exit /b
