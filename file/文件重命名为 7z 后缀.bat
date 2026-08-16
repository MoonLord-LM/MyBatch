@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将当前目录下的所有文件重命名为 7z 后缀，例如 1.jpg 改为 1.jpg.7z' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前目录下所有的文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '不处理文件后缀为 7z、zip、rar、tar、bat、exe、dll、ini、lnk 的，或者属性为隐藏文件、系统文件的' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)



if "%~1" == "" (
    echo 开始处理当前文件夹: "!cd!"
    echo.

    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "skipped=0"
    set /a "failed=0"
    set "file_path=!cd!"
    for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | ForEach-Object { $_.FullName }"') do (
        setlocal disabledelayedexpansion
        set "file_path=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!file_path!"

        REM 跳过不处理的后缀：7z zip rar tar bat exe dll ini lnk
        set "is_skip_ext="
        for %%e in (.7z .zip .rar .tar .bat .exe .dll .ini .lnk) do (
            if /i "!file_ext!"=="%%e" set "is_skip_ext=1"
        )

        if "!is_skip_ext!"=="1" (
            echo set /a "skipped+=1">> "!temp_set!"
            echo 文件后缀 "!file_ext!"，跳过此文件
        ) else (
            REM 跳过隐藏文件、系统文件
            set "is_hidden="
            set "is_system="
            attrib "!file_path!" | findstr /b /r /i "....H" >nul && set "is_hidden=1"
            attrib "!file_path!" | findstr /b /r /i "...S" >nul && set "is_system=1"
            if "!is_hidden!"=="1" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 隐藏文件，跳过此文件
            ) else if "!is_system!"=="1" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 系统文件，跳过此文件
            ) else (
                set "new_name=!base_name!!file_ext!.7z"
                echo 目标文件名: "!new_name!"
                if exist "!file_dir!!new_name!" (
                    echo set /a "skipped+=1">> "!temp_set!"
                    echo 目标文件已存在，跳过此文件
                ) else (
                    ren "!file_path!" "!new_name!"
                    if !errorlevel! equ 0 (
                        echo set /a "succeeded+=1">> "!temp_set!"
                        echo 重命名成功
                    ) else (
                        echo set /a "failed+=1">> "!temp_set!"
                        echo 重命名失败
                    )
                )
            )
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
    set "file_path=%~1"
    set "file_dir=%~dp1"
    set "base_name=%~n1"
    set "file_ext=%~x1"
    setlocal enabledelayedexpansion

    if not exist "!file_path!" (
        echo 错误: 文件不存在: "!file_path!"
        echo.
        pause
        exit /b 1
    )

    if exist "!file_path!\" (
        echo 开始处理文件夹: "!file_path!"
        echo.

        REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
        set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

        set /a "total=0"
        set /a "succeeded=0"
        set /a "skipped=0"
        set /a "failed=0"
        for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | ForEach-Object { $_.FullName }"') do (
            setlocal disabledelayedexpansion
            set "file_path=%%f"
            set "file_dir=%%~dpf"
            set "base_name=%%~nf"
            set "file_ext=%%~xf"
            setlocal enabledelayedexpansion

            echo 正在处理: "!file_path!"

            REM 跳过不处理的后缀：7z zip rar tar bat exe dll ini lnk
            set "is_skip_ext="
            for %%e in (.7z .zip .rar .tar .bat .exe .dll .ini .lnk) do (
                if /i "!file_ext!"=="%%e" set "is_skip_ext=1"
            )

            if "!is_skip_ext!"=="1" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 文件后缀 "!file_ext!"，跳过此文件
            ) else (
                REM 跳过隐藏文件、系统文件
                set "is_hidden="
                set "is_system="
                attrib "!file_path!" | findstr /b /r /i "....H" >nul && set "is_hidden=1"
                attrib "!file_path!" | findstr /b /r /i "...S" >nul && set "is_system=1"
                if "!is_hidden!"=="1" (
                    echo set /a "skipped+=1">> "!temp_set!"
                    echo 隐藏文件，跳过此文件
                ) else if "!is_system!"=="1" (
                    echo set /a "skipped+=1">> "!temp_set!"
                    echo 系统文件，跳过此文件
                ) else (
                    set "new_name=!base_name!!file_ext!.7z"
                    echo 目标文件名: "!new_name!"
                    if exist "!file_dir!!new_name!" (
                        echo set /a "skipped+=1">> "!temp_set!"
                        echo 目标文件已存在，跳过此文件
                    ) else (
                        ren "!file_path!" "!new_name!"
                        if !errorlevel! equ 0 (
                            echo set /a "succeeded+=1">> "!temp_set!"
                            echo 重命名成功
                        ) else (
                            echo set /a "failed+=1">> "!temp_set!"
                            echo 重命名失败
                        )
                    )
                )
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
        echo 开始处理文件: "!file_path!"

        REM 跳过不处理的后缀：7z zip rar tar bat exe dll ini lnk
        set "is_skip_ext="
        for %%e in (.7z .zip .rar .tar .bat .exe .dll .ini .lnk) do (
            if /i "!file_ext!"=="%%e" set "is_skip_ext=1"
        )

        if "!is_skip_ext!"=="1" (
            echo 文件后缀 "!file_ext!"，跳过此文件
        ) else (
            REM 跳过隐藏文件、系统文件
            set "is_hidden="
            set "is_system="
            attrib "!file_path!" | findstr /b /r /i "....H" >nul && set "is_hidden=1"
            attrib "!file_path!" | findstr /b /r /i "...S" >nul && set "is_system=1"
            if "!is_hidden!"=="1" (
                echo 隐藏文件，跳过此文件
            ) else if "!is_system!"=="1" (
                echo 系统文件，跳过此文件
            ) else (
                set "new_name=!base_name!!file_ext!.7z"
                echo 目标文件名: "!new_name!"
                if exist "!file_dir!!new_name!" (
                    echo 目标文件已存在，跳过此文件
                ) else (
                    ren "!file_path!" "!new_name!"
                    if !errorlevel! equ 0 (
                        echo 重命名成功
                    ) else (
                        echo 重命名失败
                    )
                )
            )
        )
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
