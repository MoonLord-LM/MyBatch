@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '生成指定文件的常用哈希值' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入要生成哈希值的文件的路径；也可以拖拽单个文件到此脚本上' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '计算 MD5 SHA1 SHA256 SHA384 SHA512 共 5 种哈希值' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



set "input_file=!param1_path!"

:input_file
if "!input_file!"=="" (
    echo 请输入要生成哈希值的文件的路径
    set /p "input_file="
    echo.
)
if "!input_file!"=="" (
    echo 输入不能为空，请重新输入
    echo.
    goto input_file
)
set "input_file=!input_file:"=!"
if not exist "!input_file!" (
    echo 错误：路径不存在："!input_file!"，请重新输入
    echo.
    set "input_file="
    goto input_file
)
if exist "!input_file!\" (
    echo 错误：不支持文件夹，请输入单个文件
    echo.
    set "input_file="
    goto input_file
)

for %%i in ("!input_file!") do (
    setlocal disabledelayedexpansion
    set "param1_path=%%~fi"
    set "param1_name_ext=%%~nxi"
    setlocal enabledelayedexpansion

    echo 开始处理："!input_file!"
    echo.



    set "certutil_path=!SystemRoot!\System32\certutil.exe"
    echo 文件 "!param1_name_ext!" 的常用哈希值：
    echo.

    "!certutil_path!" -hashfile "!param1_path!" MD5
    if !errorlevel! neq 0 (
        echo 错误：生成 MD5 失败："!param1_path!"
        echo.
        pause
        endlocal & endlocal & exit /b 1
    )
    echo.

    "!certutil_path!" -hashfile "!param1_path!" SHA1
    if !errorlevel! neq 0 (
        echo 错误：生成 SHA1 失败："!param1_path!"
        echo.
        pause
        endlocal & endlocal & exit /b 1
    )
    echo.

    "!certutil_path!" -hashfile "!param1_path!" SHA256
    if !errorlevel! neq 0 (
        echo 错误：生成 SHA256 失败："!param1_path!"
        echo.
        pause
        endlocal & endlocal & exit /b 1
    )
    echo.

    "!certutil_path!" -hashfile "!param1_path!" SHA384
    if !errorlevel! neq 0 (
        echo 错误：生成 SHA384 失败："!param1_path!"
        echo.
        pause
        endlocal & endlocal & exit /b 1
    )
    echo.

    "!certutil_path!" -hashfile "!param1_path!" SHA512
    if !errorlevel! neq 0 (
        echo 错误：生成 SHA512 失败："!param1_path!"
        echo.
        pause
        endlocal & endlocal & exit /b 1
    )



    endlocal
    endlocal
)

echo.
pause
endlocal & endlocal & exit /b
