@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '使用预置的在互联网上公开的密码，对压缩文件尝试进行解压' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的压缩文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个压缩文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '处理的范围为 7z zip rar tar gz bz2 xz tgz tbz2 格式的文件以及无后缀的文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '预置的公开密码，保存在 public_password_list 变量中' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '文件会解压到与压缩文件同名的文件夹中，如果输出文件夹已存在，则跳过不处理' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '对于嵌套压缩的压缩包文件，会尝试深入解压最多 5 层' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 检查 7-Zip 组件
if exist "!script_dir!7za.exe" (
    set "seven_zip=!script_dir!7za.exe"
) else if exist "!cd!\7za.exe" (
    set "seven_zip=!cd!\7za.exe"
) else if exist "!script_dir!..\7za.exe" (
    set "seven_zip=!script_dir!..\7za.exe"
) else if exist "..\7za.exe" (
    set "seven_zip=..\7za.exe"
) else if exist "C:\Program Files\7-Zip\7z.exe" (
    set "seven_zip=C:\Program Files\7-Zip\7z.exe"
) else if exist "C:\Program Files (x86)\7-Zip\7z.exe" (
    set "seven_zip=C:\Program Files (x86)\7-Zip\7z.exe"
) else (
    set "seven_zip=7z"
)
"!seven_zip!" i >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 7-Zip 组件
    echo 请从 https://www.7-zip.org/download.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://www.7-zip.org/download.html"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)

REM 检查 WinRAR 组件
if exist "!script_dir!UnRAR.exe" (
    set "unrar=!script_dir!UnRAR.exe"
) else if exist "!cd!\UnRAR.exe" (
    set "unrar=!cd!\UnRAR.exe"
) else if exist "!script_dir!..\UnRAR.exe" (
    set "unrar=!script_dir!..\UnRAR.exe"
) else if exist "..\UnRAR.exe" (
    set "unrar=..\UnRAR.exe"
) else if exist "C:\Program Files\WinRAR\UnRAR.exe" (
    set "unrar=C:\Program Files\WinRAR\UnRAR.exe"
) else if exist "C:\Program Files (x86)\WinRAR\UnRAR.exe" (
    set "unrar=C:\Program Files (x86)\WinRAR\UnRAR.exe"
) else (
    set "unrar=UnRAR"
)
"!unrar!" -iver >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 WinRAR 组件
    echo 请从 https://www.rarlab.com/download.htm 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://www.rarlab.com/download.htm"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)

REM 预置的公开密码
set "public_password_list=@('02acg.com','acgbns.com','ixyg688.com','laoquzhang.com','misskon.com','mrcong.com','theaic.cn','www.asmr.li','www.ruhuamtv.com','xyg688.com','三次郎')"



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
        endlocal & endlocal & exit /b 1
    )
    if exist "!param1!\" (
        echo 开始处理文件夹："!param1!"
        set "working_dir=!param1!"
        echo.
    ) else (
        echo 开始处理文件："!param1!"
        set "archive_path=!param1!"
        set "file_dir=!param1_dir!"
        set "base_name=!param1_name!"
        set "file_ext=!param1_ext!"

        REM 检查是否为支持的压缩文件后缀：7z zip rar tar gz bz2 xz tgz tbz2，或为无后缀的文件
        set "is_archive="
        if "!file_ext!"=="" set "is_archive=1"
        for %%e in (.7z .zip .rar .tar .gz .bz2 .xz .tgz .tbz2) do (
            if /i "!file_ext!"=="%%e" set "is_archive=1"
        )

        if "!is_archive!"=="1" (
            set "output_dir=!file_dir!!base_name!"
            if exist "!output_dir!" (
                echo 输出文件夹已存在："!output_dir!"，跳过此压缩文件
            ) else (
                set "extracted=0"
                set "used_password="

                REM 先测试无密码是否可解压
                "!seven_zip!" t -y "!archive_path!" <nul >nul 2>&1
                if !errorlevel! equ 0 (
                    "!seven_zip!" x -y -o"!output_dir!" "!archive_path!" <nul >nul 2>&1
                    if !errorlevel! equ 0 set "extracted=1"
                ) else (
                    REM 依次测试密码列表中的密码
                    for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; %public_password_list%"`) do (
                        if "!extracted!"=="0" (
                            "!seven_zip!" t -y -p"%%p" "!archive_path!" <nul >nul 2>&1
                            if !errorlevel! equ 0 (
                                "!seven_zip!" x -y -p"%%p" -o"!output_dir!" "!archive_path!" <nul >nul 2>&1
                                if !errorlevel! equ 0 (
                                    set "extracted=1"
                                    set "used_password=%%p"
                                )
                            )
                        )
                    )
                )

                REM 7-Zip 无法处理时，用 WinRAR 尝试
                if "!extracted!"=="0" (
                    REM 先测试无密码是否可解压
                    "!unrar!" t -y "!archive_path!" <nul >nul 2>&1
                    if !errorlevel! equ 0 (
                        "!unrar!" x -y "!archive_path!" "!output_dir!"\ <nul >nul 2>&1
                        if !errorlevel! equ 0 set "extracted=1"
                    ) else (
                        REM 依次测试密码列表中的密码
                        for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; %public_password_list%"`) do (
                            if "!extracted!"=="0" (
                                "!unrar!" t -y -p"%%p" "!archive_path!" <nul >nul 2>&1
                                if !errorlevel! equ 0 (
                                    "!unrar!" x -y -p"%%p" "!archive_path!" "!output_dir!"\ <nul >nul 2>&1
                                    if !errorlevel! equ 0 (
                                        set "extracted=1"
                                        set "used_password=%%p"
                                    )
                                )
                            )
                        )
                    )
                )

                if "!extracted!"=="1" (
                    if "!used_password!"=="" (
                        echo 解压成功（无密码）
                    ) else (
                        echo 解压成功，密码为："!used_password!"
                    )
                    echo 尝试解压嵌套压缩包，处理文件夹："!output_dir!"
                    set "working_dir=!output_dir!"
                    echo.
                ) else (
                    echo 解压失败：密码都不正确或文件损坏
                )
            )
        ) else (
            echo 错误：不支持的文件后缀 "!file_ext!"，请拖入压缩文件
            echo.
            pause
            endlocal & endlocal & exit /b 1
        )
    )
)

if not "!working_dir!" == "" (
    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "password_succeeded=0"
    set /a "output_exist=0"
    set /a "extract_failed=0"
    set "file_path=!working_dir!"
    set "ext_filter=\.(7z|zip|rar|tar|gz|bz2|xz|tgz|tbz2)$"
    for /l %%d in (1,1,5) do (
        for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { (($_.Extension -match $env:ext_filter -or $_.Extension -eq '') -and (-not (Test-Path (Join-Path $_.DirectoryName $_.BaseName)))) } | ForEach-Object { $_.FullName }"') do (
            setlocal disabledelayedexpansion
            set "archive_path=%%f"
            set "file_dir=%%~dpf"
            set "base_name=%%~nf"
            set "file_ext=%%~xf"
            setlocal enabledelayedexpansion

            echo 处理压缩文件："!archive_path!"
            set "output_dir=!file_dir!!base_name!"
            if exist "!output_dir!" (
                echo set /a "output_exist+=1">> "!temp_set!"
                echo 输出文件夹已存在："!output_dir!"，跳过此压缩文件
            ) else (
                set "extracted=0"
                set "used_password="

                REM 先测试无密码是否可解压
                "!seven_zip!" t -y "!archive_path!" <nul >nul 2>&1
                if !errorlevel! equ 0 (
                    "!seven_zip!" x -y -o"!output_dir!" "!archive_path!" <nul >nul 2>&1
                    if !errorlevel! equ 0 set "extracted=1"
                ) else (
                    REM 依次测试密码列表中的密码
                    for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; %public_password_list%"`) do (
                        if "!extracted!"=="0" (
                            "!seven_zip!" t -y -p"%%p" "!archive_path!" <nul >nul 2>&1
                            if !errorlevel! equ 0 (
                                "!seven_zip!" x -y -p"%%p" -o"!output_dir!" "!archive_path!" <nul >nul 2>&1
                                if !errorlevel! equ 0 (
                                    set "extracted=1"
                                    set "used_password=%%p"
                                )
                            )
                        )
                    )
                )

                REM 7-Zip 无法处理时，用 WinRAR 尝试
                if "!extracted!"=="0" (
                    REM 先测试无密码是否可解压
                    "!unrar!" t -y "!archive_path!" <nul >nul 2>&1
                    if !errorlevel! equ 0 (
                        "!unrar!" x -y "!archive_path!" "!output_dir!"\ <nul >nul 2>&1
                        if !errorlevel! equ 0 set "extracted=1"
                    ) else (
                        REM 依次测试密码列表中的密码
                        for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; %public_password_list%"`) do (
                            if "!extracted!"=="0" (
                                "!unrar!" t -y -p"%%p" "!archive_path!" <nul >nul 2>&1
                                if !errorlevel! equ 0 (
                                    "!unrar!" x -y -p"%%p" "!archive_path!" "!output_dir!"\ <nul >nul 2>&1
                                    if !errorlevel! equ 0 (
                                        set "extracted=1"
                                        set "used_password=%%p"
                                    )
                                )
                            )
                        )
                    )
                )

                if "!extracted!"=="1" (
                    if "!used_password!"=="" (
                        echo set /a "succeeded+=1">> "!temp_set!"
                        echo 解压成功（无密码）
                    ) else (
                        echo set /a "password_succeeded+=1">> "!temp_set!"
                        echo 解压成功，密码为："!used_password!"
                    )
                ) else (
                    echo set /a "extract_failed+=1">> "!temp_set!"
                    echo 解压失败：密码都不正确或文件损坏
                )
            )
            echo set /a "total+=1">> "!temp_set!"
            echo.

            endlocal
            endlocal
        )
    )

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    echo 批量处理完成
    set /a "ok_total=succeeded+password_succeeded"
    set /a "fail_total=extract_failed+output_exist"
    echo 共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个 & REM
    echo 其中，无密码解压成功 !succeeded! 个，密码解压成功 !password_succeeded! 个，解压失败 !extract_failed! 个，输出文件夹已存在 !output_exist! 个
)



echo.
pause
endlocal & endlocal & exit /b
