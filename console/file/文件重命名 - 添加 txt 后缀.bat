@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '在原始文件名和文件后缀的后面，统一添加 txt 后缀' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '例如 a1.jpg 改为 a1.jpg.txt' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动扫描当前文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '如果文件已经是 txt 后缀，则跳过不处理' -ForegroundColor Green"
echo.



if "!param1!" == "" (
    echo 开始处理当前文件夹："!cd!"
    set "working_dir=!cd!"
    echo.
) else (
    if "!param1:~-1!"=="\" set "param1=!param1:~0,-1!"
    if not exist "!param1!" (
        echo 错误：路径不存在："!param1!"
        echo.
        pause
        exit /b 1
    )
    if exist "!param1!\" (
        echo 开始处理文件夹："!param1!"
        set "working_dir=!param1!"
        echo.
    ) else (
        echo 开始处理文件："!param1!"
        echo.
        if /i "!param1_ext!"==".txt" (
            echo 跳过，已有 txt 后缀："!param1_name_ext!"
        ) else if exist "!param1_dir!!param1_name_ext!.txt" (
            echo 跳过，目标已存在："!param1_name_ext!"
        ) else (
            ren "!param1_path!" "!param1_name_ext!.txt"
            if !errorlevel! neq 0 (
                echo 重命名失败："!param1_name_ext!"
            ) else (
                echo 重命名成功："!param1_name_ext!"，改为 "!param1_name_ext!.txt"
            )
        )
    )
)



if not "!working_dir!" == "" (
    set "file_path=!working_dir!"
    if "!file_path:~-1!"=="\" set "file_path=!file_path:~0,-1!"

    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "skipped=0"
    set /a "name_conflict=0"
    set /a "rename_failed=0"

    REM 遍历文件夹中所有文件，不处理隐藏和系统属性的文件
    for /f "delims=" %%f in ('dir /s /b /a-d-h-s "!file_path!" 2^>nul') do (
        setlocal disabledelayedexpansion
        set "file_path=%%f"
        set "file_dir=%%~dpf"
        set "file_name_ext=%%~nxf"
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        if /i "!file_ext!"==".txt" (
            echo 跳过，已有 txt 后缀："!file_name_ext!"
            echo set /a "skipped+=1">>"!temp_set!"
        ) else if exist "!file_dir!!file_name_ext!.txt" (
            echo 跳过，目标已存在："!file_name_ext!"
            echo set /a "name_conflict+=1">>"!temp_set!"
        ) else (
            ren "!file_path!" "!file_name_ext!.txt"
            if !errorlevel! neq 0 (
                echo 重命名失败："!file_name_ext!"
                echo set /a "rename_failed+=1">>"!temp_set!"
            ) else (
                echo 重命名成功："!file_name_ext!"，改为 "!file_name_ext!.txt"
                echo set /a "succeeded+=1">>"!temp_set!"
            )
        )
        echo set /a "total+=1">>"!temp_set!"

        endlocal
        endlocal
    )
    echo.

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    set /a "fail_total=name_conflict+rename_failed"
    echo 批量处理完成 & REM
    echo 共计：!total! 个，成功：!succeeded! 个，失败：!fail_total! 个，跳过：!skipped! 个 & REM
    echo 其中，重命名成功 !succeeded! 个，目标文件已存在 !name_conflict! 个，重命名失败 !rename_failed! 个，跳过 !skipped! 个 & REM
)



echo.
pause
exit /b
