@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '生成指定文件的 ed2k 链接，并自动复制到剪贴板' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '选中一个文件，拖拽到此脚本上执行；不支持拖入文件夹' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



REM 检查 rhash 组件
if exist "!script_dir!rhash.exe" (
    set "rhash_path=!script_dir!rhash.exe"
) else if exist "!cd!\rhash.exe" (
    set "rhash_path=!cd!\rhash.exe"
) else if exist "!script_dir!..\rhash.exe" (
    set "rhash_path=!script_dir!..\rhash.exe"
) else if exist "..\rhash.exe" (
    set "rhash_path=..\rhash.exe"
) else (
    set "rhash_path=rhash"
)
"!rhash_path!" --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 rhash 组件
    echo 请从 https://rhash.sourceforge.io 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://rhash.sourceforge.io"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



if "!param1!" == "" (
    echo 错误：不支持双击运行，请拖入文件运行
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
if not exist "!param1!" (
    echo 错误：路径不存在："!param1!"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
if exist "!param1!\" (
    echo 错误：不支持拖入文件夹，请拖入单个文件
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



set "link_file=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp"
"!rhash_path!" --utf8 --ed2k-link "!param1_path!" > "!link_file!" 2>&1
if !errorlevel! neq 0 (
    if exist "!link_file!" ( del /f /q "!link_file!" )
    echo 错误：生成 ed2k 链接失败："!param1_path!"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)

echo 文件 "!param1_name_ext!" 的 ed2k 链接：
echo.
type "!link_file!"
echo.

clip < "!link_file!"
echo 链接已复制到剪贴板

if exist "!link_file!" ( del /f /q "!link_file!" )



echo.
pause
endlocal & endlocal & exit /b
