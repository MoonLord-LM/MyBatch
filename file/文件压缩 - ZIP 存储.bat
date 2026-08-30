@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '使用 7-Zip 对文件或文件夹进行仅存储压缩，输出 ZIP 格式压缩包' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '压缩等级设为 0 - 仅存储' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '参数使用 -mtc=on -mta=on -mtm=on，保存文件的创建、修改和访问时间' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，压缩当前文件夹为同名 zip 文件，并保存到上一级的文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件或文件夹到此脚本上时，压缩为同名 zip 文件，保存到其所在的文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '如果输出 zip 已存在，则跳过不处理' -ForegroundColor Green"
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

if "!param1!" == "" (
    echo 开始处理当前文件夹："!cd!"
    echo.
    set "input_path=!cd!"
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
        echo.
        set "input_path=!param1!"
    ) else (
        echo 开始处理文件："!param1!"
        echo.
        set "input_path=!param1_path!"
    )
)

set "zip_params=-tzip -mx=0 -mmt=on -mtc=on -mta=on -mtm=on"

for %%i in ("!input_path!") do (
    setlocal disabledelayedexpansion
    set "out_name=%%~nxi"
    set "parent_dir=%%~dpi"
    setlocal enabledelayedexpansion

    set "output_path=!parent_dir!!out_name!.zip"
    echo 输出压缩包："!output_path!"
    echo.

    if exist "!output_path!" (
        echo 输出压缩包已存在："!output_path!"，跳过不处理
    ) else (
        REM -sccUTF-8 避免中文路径乱码；-y 自动确认；<nul 防止 7-Zip 交互等待
        "!seven_zip!" a %zip_params% -sccUTF-8 -y "!output_path!" "!input_path!" <nul
        if !errorlevel! equ 0 (
            for %%j in ("!output_path!") do (
                setlocal disabledelayedexpansion
                set "zip_size=%%~zj"
                setlocal enabledelayedexpansion

                echo 压缩成功："!output_path!"，大小：!zip_size! 字节

                endlocal
                endlocal
            )
        ) else (
            echo 压缩失败："!input_path!"
            if exist "!output_path!" ( del /f /q "!output_path!" )
        )
    )

    endlocal
    endlocal
)



echo.
pause
endlocal & endlocal & exit /b
