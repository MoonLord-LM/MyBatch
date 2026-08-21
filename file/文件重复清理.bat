@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '搜索和清理重复文件，将会清理第 1 个文件夹中的，已经在第 2 个文件夹中存在的文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入两个文件夹路径' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '也可以选中两个文件夹，拖拽到此脚本上，自动识别处理' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '当两次输入的文件夹路径相同时，则清理该文件夹自身的重复文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '文件比对一致后，将重复文件删除到回收站' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "%~dp0"
)



setlocal disabledelayedexpansion
set "path1=%~1"
set "path2=%~2"
setlocal enabledelayedexpansion

    :input_path1
    if "!path1!"=="" (
        echo.
        echo 请输入要清理多余文件的文件夹
        set /p "path1="
    )
    if "!path1!"=="" (
        echo 输入不能为空，请重新输入
        goto input_path1
    )
    set "path1=!path1:"=!"
    if "!path1:~-1!"=="\" set "path1=!path1:~0,-1!"
    if not exist "!path1!\" (
        echo 错误：路径 1 不存在或不是文件夹："!path1!"，请重新输入
        set "path1="
        goto input_path1
    )

    :input_path2
    if "!path2!"=="" (
        echo.
        echo 请输入作为参考的文件夹，仅用于文件比对
        set /p "path2="
    )
    if "!path2!"=="" (
        echo 输入不能为空，请重新输入
        goto input_path2
    )
    set "path2=!path2:"=!"
    if "!path2:~-1!"=="\" set "path2=!path2:~0,-1!"
    if not exist "!path2!\" (
        echo 错误：路径 2 不存在或不是文件夹："!path2!"，请重新输入
        set "path2="
        goto input_path2
    )



    echo.
    echo 清理文件夹："!path1!"
    echo 参考文件夹："!path2!"
    echo.

    REM 将两个文件夹的文件列表分别缓存到临时文件，只枚举一次，避免对每个文件重复扫描
    set "tmp_list1=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!tmp_list1!"
    set "tmp_list2=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!tmp_list2!"
    powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:path1 -File -Recurse | ForEach-Object { $_.FullName }" > "!tmp_list1!" 2>nul
    powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:path2 -File -Recurse | ForEach-Object { $_.FullName }" > "!tmp_list2!" 2>nul

    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "deleted=0"
    set /a "failed=0"
    for /f "usebackq delims=" %%i in ("!tmp_list1!") do (
        setlocal disabledelayedexpansion
        set "file1=%%i"
        set "size1=%%~zi"
        setlocal enabledelayedexpansion
        echo set /a "total+=1">> "!temp_set!"
        for /f "usebackq delims=" %%j in ("!tmp_list2!") do (
            setlocal disabledelayedexpansion
            set "file2=%%j"
            set "size2=%%~zj"
            setlocal enabledelayedexpansion
            if not "!file1!"=="!file2!" (
                if "!size1!"=="!size2!" (
                    if exist "!file1!" (
                        if exist "!file2!" (
                            fc /b "!file1!" "!file2!" > nul
                            if !errorlevel! equ 0 (
                                echo 准备删除："!file1!"
                                echo 重复文件："!file2!"
                                set "file_to_delete=!file1!"
                                powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:file_to_delete,'OnlyErrorDialogs','SendToRecycleBin')"
                                if exist "!file1!" (
                                    echo 删除失败
                                    echo set /a "failed+=1">> "!temp_set!"
                                ) else (
                                    echo 已删除到回收站
                                    echo set /a "deleted+=1">> "!temp_set!"
                                )
                            )
                        )
                    )
                )
            )
            endlocal
            endlocal
        )
        endlocal
        endlocal
    )

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    if exist "!tmp_list1!" ( del /f /q "!tmp_list1!" )
    if exist "!tmp_list2!" ( del /f /q "!tmp_list2!" )

    echo.
    echo 处理完成
    echo 共计：!total! 个文件，删除成功：!deleted! 个，删除失败：!failed! 个

endlocal
endlocal



echo.
pause
exit /b
