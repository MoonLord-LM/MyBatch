@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，自动扫描和清理各种垃圾文件，删除到回收站' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 获取系统管理员权限
net file >nul 2>&1
if !errorlevel! equ 0 (
    powershell -NoProfile -Command "Write-Host '已获取系统管理员权限' -ForegroundColor Green"
    echo.
) else (
    powershell -NoProfile -Command "Write-Host '需要系统管理员权限，请确认……' -ForegroundColor Green"
    echo.
    setlocal disabledelayedexpansion
    powershell start -verb "RunAs" "%~f0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9" >nul 2>&1
    endlocal
    if !errorlevel! neq 0 (
        powershell -NoProfile -Command "Write-Host '获取系统管理员权限失败' -ForegroundColor Green"
        echo.
        pause
        exit /b 1
    )
    exit /b
)



echo 开始扫描
echo.
set "log_file=!script_name!.log"
set "temp_list=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!temp_list!"
powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; ('-- ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' --') | Out-File -LiteralPath $env:log_file -Append -Encoding UTF8"

REM 龙之谷 DragonNest
set "reg_value="
for /f "tokens=2,*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\SHENGQUGAMES\DN" /v "Loader"') do (
    setlocal disabledelayedexpansion
    set "reg_value=%%b"
    set "root_dir=%%~dpb"
    setlocal enabledelayedexpansion
    if not "!reg_value!"=="" (
        if "!root_dir:~-1!"=="\" set "root_dir=!root_dir:~0,-1!"
        echo 正在扫描文件夹："!root_dir!"
        dir /s /b /a-d "!root_dir!\*.dmp" 2>nul >> "!temp_list!"
        dir /s /b /a-d "!root_dir!\Log\*.log" 2>nul >> "!temp_list!"
        dir /s /b /a-d "!root_dir!\TempRes\*.tmp" 2>nul >> "!temp_list!"
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
        if "!root_dir:~-1!"=="\" set "root_dir=!root_dir:~0,-1!"
        echo 正在扫描文件夹："!root_dir!"
        dir /s /b /a-d "!root_dir!\*.dmp" 2>nul >> "!temp_list!"
    )
    endlocal
    endlocal
)

REM Intel Extreme Tuning Utility
set "root_dir=!ProgramData!\Intel\Intel Extreme Tuning Utility"
if exist "!root_dir!" (
    echo 正在扫描文件夹："!root_dir!"
    dir /s /b /a-d "!root_dir!\Logs\*.log" 2>nul >> "!temp_list!"
)

REM 系统 Crash Dump
set "root_dir=!LocalAppData!\CrashDumps"
if exist "!root_dir!" (
    echo 正在扫描文件夹："!root_dir!"
    dir /s /b /a-d "!root_dir!\*.dmp" 2>nul >> "!temp_list!"
)

REM 系统 Live Kernel Reports
set "root_dir=!SystemRoot!\LiveKernelReports"
if exist "!root_dir!" (
    echo 正在扫描文件夹："!root_dir!"
    dir /s /b /a-d "!root_dir!\*.dmp" 2>nul >> "!temp_list!"
)

REM 用户临时文件
set "root_dir=!temp!"
if exist "!root_dir!" (
    echo 正在扫描文件夹："!root_dir!"
    dir /s /b /a-d "!root_dir!\*" 2>nul >> "!temp_list!"
)

REM 系统临时文件
set "root_dir=!SystemRoot!\Temp"
if exist "!root_dir!" (
    echo 正在扫描文件夹："!root_dir!"
    dir /s /b /a-d "!root_dir!\*" 2>nul >> "!temp_list!"
)

REM 115Chrome 浏览器缓存
set "root_dir=!LocalAppData!\115Chrome\User Data\Default\Cache"
if exist "!root_dir!" (
    echo 正在扫描文件夹："!root_dir!"
    dir /s /b /a-d "!root_dir!\*" 2>nul >> "!temp_list!"
)

REM 360Chrome 浏览器缓存
set "root_dir=!LocalAppData!\360ChromeX\Chrome\User Data\Default\Cache"
if exist "!root_dir!" (
    echo 正在扫描文件夹："!root_dir!"
    dir /s /b /a-d "!root_dir!\*" 2>nul >> "!temp_list!"
)

REM Edge 浏览器缓存
set "root_dir=!LocalAppData!\Microsoft\Edge\User Data\Default\Cache"
if exist "!root_dir!" (
    echo 正在扫描文件夹："!root_dir!"
    dir /s /b /a-d "!root_dir!\*" 2>nul >> "!temp_list!"
)

REM 夸克 浏览器缓存
set "root_dir=!LocalAppData!\Quark\User Data\Default\Cache"
if exist "!root_dir!" (
    echo 正在扫描文件夹："!root_dir!"
    dir /s /b /a-d "!root_dir!\*" 2>nul >> "!temp_list!"
)

REM NVIDIA 显卡着色器与缓存（仅清理 6 个月前的）
set "root_dir=!LocalAppData!\NVIDIA\DXCache"
if exist "!root_dir!" (
    echo 正在扫描文件夹："!root_dir!"（仅清理 6 个月前的）
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$time = (Get-Date).AddDays(-180);" ^
        "Get-ChildItem -LiteralPath $env:root_dir -File -Recurse -ErrorAction SilentlyContinue |" ^
        "    Where-Object { $_.CreationTime -lt $time -and $_.LastWriteTime -lt $time -and $_.LastAccessTime -lt $time } |" ^
        "    ForEach-Object { $_.FullName } |" ^
        "    Add-Content -LiteralPath $env:temp_list -Encoding UTF8;"
)

REM AMD 显卡着色器与缓存（仅清理 6 个月前的）
set "root_dir=!LocalAppData!\AMD\DXCache"
if exist "!root_dir!" (
    echo 正在扫描文件夹："!root_dir!"（仅清理 6 个月前的）
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$time = (Get-Date).AddDays(-180);" ^
        "Get-ChildItem -LiteralPath $env:root_dir -File -Recurse -ErrorAction SilentlyContinue |" ^
        "    Where-Object { $_.CreationTime -lt $time -and $_.LastWriteTime -lt $time -and $_.LastAccessTime -lt $time } |" ^
        "    ForEach-Object { $_.FullName } |" ^
        "    Add-Content -LiteralPath $env:temp_list -Encoding UTF8;"
)

echo.
echo 开始清理
echo.
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "Add-Type -AssemblyName Microsoft.VisualBasic;" ^
    "$files = Get-Content -Encoding UTF8 -LiteralPath $env:temp_list | Where-Object { $_ -ne $env:temp_list };" ^
    "$ok = 0;" ^
    "$fail = 0;" ^
    "$skip = 0;" ^
    "foreach ($f in $files) {" ^
    "    try {" ^
    "        $fs = [IO.File]::Open($f, 'Open', 'Read', 'None');" ^
    "        $fs.Close();" ^
    "    } catch {" ^
    "        $skip++;" ^
    "        continue;" ^
    "    }" ^
    "    try {" ^
    "        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($f, 'OnlyErrorDialogs', 'SendToRecycleBin');" ^
    "        $ok++;" ^
    "        try {" ^
    "            Add-Content -LiteralPath $env:log_file -Value $f -Encoding UTF8;" ^
    "        } catch {}" ^
    "    } catch {" ^
    "        $fail++;" ^
    "    }" ^
    "}" ^
    "Write-Host ('删除成功 ' + $ok + ' 个文件，删除失败 ' + $fail + ' 个文件，跳过 ' + $skip + ' 个被占用文件');"
if exist "!temp_list!" ( del /f /q "!temp_list!" )

echo.
echo 已完成清理，记录已保存到 "!log_file!" 中
echo.>> "!log_file!"



echo.
pause
endlocal & endlocal & exit /b
