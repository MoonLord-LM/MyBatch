@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '显示指定的文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，提示用户输入文件夹路径或名称' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则处理拖入的文件夹；不支持拖入单个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '处理方式：移除隐藏和系统属性，再重命名为原始文件夹名称' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



set "file_path=!param1!"

:input_path
    if "!file_path!"=="" (
        echo 请输入要显示的文件夹路径或名称
        set /p "file_path="
        if !errorlevel! neq 0 (
            echo 无输入，退出脚本
            echo.
            endlocal & endlocal & exit /b 1
        )
        echo.
    ) else (
        echo 要显示的文件夹："!file_path!"
        echo.
    )
    if "!file_path!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_path
    )
    set "file_path=!file_path:"=!"
    if "!file_path!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_path
    )
    if "!file_path:~-1!"=="\" set "file_path=!file_path:~0,-1!"
    set "clsid_path=!file_path!.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
    if not exist "!clsid_path!" (
        echo 错误：路径不存在："!clsid_path!"，请重新输入
        echo.
        set "file_path="
        goto input_path
    )
    if not exist "!clsid_path!\" (
        echo 错误：路径不是文件夹："!clsid_path!"，请重新输入
        echo.
        set "file_path="
        goto input_path
    )
    if exist "!file_path!\" (
        echo 错误：已有文件夹存在："!file_path!"，请重新输入
        echo.
        set "file_path="
        goto input_path
    )



echo attrib -h -s "!clsid_path!"
attrib -h -s "!clsid_path!"
if !errorlevel! neq 0 (
    echo 错误：移除文件夹 系统+隐藏 属性失败："!clsid_path!"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)

echo move /y "!clsid_path!" "!file_path!"
move /y "!clsid_path!" "!file_path!"
if !errorlevel! neq 0 (
    echo 错误：重命名文件夹失败："!clsid_path!"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)

echo 处理文件夹："!clsid_path!"
echo 已显示，当前文件夹："!file_path!"



echo.
pause
endlocal & endlocal & exit /b
