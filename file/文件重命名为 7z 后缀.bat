@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将当前目录下的所有文件重命名为 7z 后缀，例如 1.jpg 改为 1.jpg.7z' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前目录下所有的文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '已带 7z 后缀的文件和 bat 脚本文件将被跳过' -ForegroundColor Green"
echo.



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)



if "%~1" == "" (
    echo 开始扫描
    echo.

    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "skipped=0"
    set /a "failed=0"
    for /r %%f in (*) do (
        setlocal disabledelayedexpansion
        set "target_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!target_file!"
        set "skip_reason="
        if /i "!file_ext!"==".bat" set "skip_reason=bat 脚本文件"
        if "!skip_reason!"=="" if /i "!file_ext!"==".7z" set "skip_reason=已是 7z 后缀"

        if "!skip_reason!"=="" (
            set "new_name=!base_name!!file_ext!.7z"
            echo 目标文件名: "!new_name!"
            if exist "!file_dir!!new_name!" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 目标文件已存在，跳过此文件
            ) else (
                REM cmd 的 ren 无法重命名带隐藏/系统属性的文件，先临时移除属性，重命名后再恢复
                set "was_hidden="
                set "was_system="
                attrib "!target_file!" | findstr /b /r /i "....H" >nul && set "was_hidden=1"
                attrib "!target_file!" | findstr /b /r /i "...S" >nul && set "was_system=1"
                attrib -h -s "!target_file!" >nul 2>&1
                ren "!target_file!" "!new_name!"
                set "ren_ok=!errorlevel!"
                set "target=!target_file!"
                if !ren_ok! equ 0 set "target=!file_dir!!new_name!"
                if defined was_system if defined was_hidden (
                    attrib +h +s "!target!" >nul 2>&1
                ) else if defined was_hidden (
                    attrib +h "!target!" >nul 2>&1
                ) else if defined was_system (
                    attrib +s "!target!" >nul 2>&1
                )
                if !ren_ok! equ 0 (
                    echo set /a "succeeded+=1">> "!temp_set!"
                    echo 重命名成功
                ) else (
                    echo set /a "failed+=1">> "!temp_set!"
                    echo 重命名失败
                )
            )
        ) else (
            echo set /a "skipped+=1">> "!temp_set!"
            echo !skip_reason!，跳过此文件
        )
        echo set /a "total+=1">> "!temp_set!"
        echo.

        endlocal
        endlocal
    )

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    echo 批量处理完成
    echo 共计: !total! 个，成功: !succeeded! 个，跳过: !skipped! 个，失败: !failed! 个
) else (
    setlocal disabledelayedexpansion
    set "target_file=%~1"
    set "file_dir=%~dp1"
    set "base_name=%~n1"
    set "file_ext=%~x1"
    setlocal enabledelayedexpansion

    if not exist "!target_file!" (
        echo 错误: 文件不存在: "!target_file!"
        echo.
        pause
        exit /b 1
    )

    if exist "!target_file!\" (
        echo 检测到拖拽的是文件夹，递归处理其中所有文件
        echo.

        REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
        set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

        set /a "total=0"
        set /a "succeeded=0"
        set /a "skipped=0"
        set /a "failed=0"
        for /r "!target_file!" %%f in (*) do (
            setlocal disabledelayedexpansion
            set "target_file=%%f"
            set "file_dir=%%~dpf"
            set "base_name=%%~nf"
            set "file_ext=%%~xf"
            setlocal enabledelayedexpansion

            echo 正在处理: "!target_file!"
            set "skip_reason="
            if /i "!file_ext!"==".bat" set "skip_reason=bat 脚本文件"
            if "!skip_reason!"=="" if /i "!file_ext!"==".7z" set "skip_reason=已是 7z 后缀"

            if "!skip_reason!"=="" (
                set "new_name=!base_name!!file_ext!.7z"
                echo 目标文件名: "!new_name!"
                if exist "!file_dir!!new_name!" (
                    echo set /a "skipped+=1">> "!temp_set!"
                    echo 目标文件已存在，跳过此文件
                ) else (
                    ren "!target_file!" "!new_name!"
                    if !errorlevel! equ 0 (
                        echo set /a "succeeded+=1">> "!temp_set!"
                        echo 重命名成功
                    ) else (
                        echo set /a "failed+=1">> "!temp_set!"
                        echo 重命名失败
                    )
                )
            ) else (
                echo set /a "skipped+=1">> "!temp_set!"
                echo !skip_reason!，跳过此文件
            )
            echo set /a "total+=1">> "!temp_set!"
            echo.

            endlocal
            endlocal
        )

        REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
        call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

        echo 批量处理完成
        echo 共计: !total! 个，成功: !succeeded! 个，跳过: !skipped! 个，失败: !failed! 个
    ) else (
        echo 正在处理: "!target_file!"
        set "skip_reason="
        if /i "!file_ext!"==".bat" set "skip_reason=bat 脚本文件"
        if "!skip_reason!"=="" if /i "!file_ext!"==".7z" set "skip_reason=已是 7z 后缀"

        if "!skip_reason!"=="" (
            set "new_name=!base_name!!file_ext!.7z"
            echo 目标文件名: "!new_name!"
            if exist "!file_dir!!new_name!" (
                echo 目标文件已存在，跳过此文件
            ) else (
                REM cmd 的 ren 无法重命名带隐藏/系统属性的文件，先临时移除属性，重命名后再恢复
                set "was_hidden="
                set "was_system="
                attrib "!target_file!" | findstr /b /r /i "....H" >nul && set "was_hidden=1"
                attrib "!target_file!" | findstr /b /r /i "...S" >nul && set "was_system=1"
                attrib -h -s "!target_file!" >nul 2>&1
                ren "!target_file!" "!new_name!"
                set "ren_ok=!errorlevel!"
                set "target=!target_file!"
                if !ren_ok! equ 0 set "target=!file_dir!!new_name!"
                if defined was_system if defined was_hidden (
                    attrib +h +s "!target!" >nul 2>&1
                ) else if defined was_hidden (
                    attrib +h "!target!" >nul 2>&1
                ) else if defined was_system (
                    attrib +s "!target!" >nul 2>&1
                )
                if !ren_ok! equ 0 (
                    echo 重命名成功
                ) else (
                    echo 重命名失败
                )
            )
        ) else (
            echo !skip_reason!，跳过此文件
        )
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
