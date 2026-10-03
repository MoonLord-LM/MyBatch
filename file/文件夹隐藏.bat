@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '隐藏指定名称的文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，提示用户输入文件夹名称' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则处理拖入的文件夹；不支持拖入单个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '处理方式：重命名为系统名称，再添加隐藏和系统属性' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



set "folder_name=!param1_name!"
if not "!param1_dir!" == "" cd /d "!param1_dir!"

:input_folder_name
    if "!folder_name!"=="" (
        echo 请输入要隐藏的文件夹名称
        set /p "folder_name="
        if !errorlevel! neq 0 (
            echo 无输入，退出脚本
            echo.
            exit /b 1
        )
        echo.
    ) else (
        echo 要隐藏的文件夹名称："!folder_name!"
        echo.
    )
    if "!folder_name!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_folder_name
    )
    set "folder_name=!folder_name:"=!"
    if "!folder_name!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_folder_name
    )
    if "!folder_name:~-1!"=="\" set "folder_name=!folder_name:~0,-1!"
    if not exist "!folder_name!" (
        echo 错误：路径不存在："!folder_name!"，请重新输入
        echo.
        set "folder_name="
        goto input_folder_name
    )
    if not exist "!folder_name!\" (
        echo 错误：路径不是文件夹："!folder_name!"，请重新输入
        echo.
        set "folder_name="
        goto input_folder_name
    )
    set "clsid_name=!folder_name!.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
    if exist "!clsid_name!\" (
        echo 错误：已有文件夹存在："!clsid_name!"，请重新输入
        echo.
        set "folder_name="
        goto input_folder_name
    )



ren "!folder_name!" "!clsid_name!"
if !errorlevel! neq 0 (
    echo 错误：重命名文件夹失败："!folder_name!"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)

attrib +h +s "!clsid_name!"
if !errorlevel! neq 0 (
    echo 错误：设置文件夹 系统+隐藏 属性失败："!clsid_name!"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)

echo 处理文件夹："!folder_name!"
echo 已隐藏，当前文件夹："!clsid_name!"



echo.
pause
endlocal & endlocal & exit /b
