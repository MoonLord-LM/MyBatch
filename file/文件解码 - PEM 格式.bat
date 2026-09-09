@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将 pem 格式的文件解码，还原为原始文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '格式：Base64 编码，并且带 -----BEGIN CERTIFICATE----- 和 -----END CERTIFICATE----- 标记）' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host 'Base64 编码后，体积增大到约 1.33 倍' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入要解码的 .pem 文件的路径；也可以拖拽单个 .pem 文件到此脚本上' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '如果原始文件已存在，则跳过不处理' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



set "input_file=!param1_path!"

:input_file
if "!input_file!"=="" (
    echo 请输入要解码的 .pem 文件的路径
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

if /i not "!input_file:~-4!" == ".pem" (
    echo 错误：只支持 .pem 后缀的文件："!input_file!"，请重新输入
    echo.
    set "input_file="
    goto input_file
)



echo 开始处理："!input_file!"
echo.

set "output_file=!input_file:~0,-4!"
echo 输出文件："!output_file!"
if "!output_file!" == "" (
    echo 错误：无法确定输出路径
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
if exist "!output_file!" (
    echo 输出文件已存在："!output_file!"，跳过不处理 & REM
    echo 如果需要重新解码，请先移走旧文件 & REM
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
echo.

set "certutil_path=!SystemRoot!\System32\certutil.exe"
"!certutil_path!" -decode "!input_file!" "!output_file!"
if !errorlevel! neq 0 (
    echo 解码失败
) else (
    for %%j in ("!output_file!") do (
        setlocal disabledelayedexpansion
        set "file_size=%%~zj"
        setlocal enabledelayedexpansion

        echo 解码成功："!output_file!"，大小：!file_size! 字节

        endlocal
        endlocal
    )
)



echo.
pause
endlocal & endlocal & exit /b
