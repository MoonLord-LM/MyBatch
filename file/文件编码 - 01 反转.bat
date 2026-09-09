@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将单个文件的二进制 0 1 值反转，逐字节按位处理' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '每个字节中为 0 的位变为 1，为 1 的位变为 0，按位取反' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '生成的文件名以 _r01 结尾；如果已经是这个结尾，则去掉 _r01 结尾，还原为原始文件名' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入要反转的文件的路径；也可以拖拽单个文件到此脚本上' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '如果输出文件已存在，则跳过不处理' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



set "input_file=!param1_path!"

:input_file
if "!input_file!"=="" (
    echo 请输入要反转的文件的路径
    set /p "input_file="
    echo.
)
set "input_file=!input_file:"=!"
if "!input_file!"=="" (
    echo 输入不能为空，请重新输入
    echo.
    goto input_file
)
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



echo 开始处理："!input_file!"
echo.

for %%i in ("!input_file!") do (
    setlocal disabledelayedexpansion
    set "file_dir=%%~dpi"
    set "base_name=%%~ni"
    set "file_ext=%%~xi"
    setlocal enabledelayedexpansion

    if /i "!base_name:~-4!"=="_r01" (
        set "output_file=!file_dir!!base_name:~0,-4!!file_ext!"
    ) else (
        set "output_file=!file_dir!!base_name!_r01!file_ext!"
    )
    echo 输出文件："!output_file!"
    echo.

    if exist "!output_file!" (
        echo 输出文件已存在："!output_file!"，跳过不处理 & REM
        echo 如果需要重新反转，请先移走旧文件 & REM
        echo.
        pause
        endlocal & endlocal & endlocal & endlocal & exit /b 1
    )

    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$bytes = [System.IO.File]::ReadAllBytes($env:input_file);" ^
        "for ($i = 0; $i -lt $bytes.Length; $i++) {" ^
        "    $byte = $bytes[$i];" ^
        "    $newByte = 0;" ^
        "    for ($j = 0; $j -lt 8; $j++) {" ^
        "        if (-not ($byte -band (1 -shl $j))) {" ^
        "            $newByte = $newByte -bor (1 -shl $j);" ^
        "        }" ^
        "    }" ^
        "    $bytes[$i] = $newByte;" ^
        "}" ^
        "[System.IO.File]::WriteAllBytes($env:output_file, $bytes);"
    if !errorlevel! neq 0 (
        echo 反转失败
    ) else (
        for %%j in ("!output_file!") do (
            setlocal disabledelayedexpansion
            set "file_size=%%~zj"
            setlocal enabledelayedexpansion

            echo 反转成功，大小：!file_size! 字节

            endlocal
            endlocal
        )
    )

    endlocal
    endlocal
)

echo.
pause
endlocal & endlocal & exit /b
