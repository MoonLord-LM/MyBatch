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
powershell -NoProfile -Command "Write-Host '选中一个文件，拖拽到此脚本上执行；不支持拖入文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '如果原始文件已存在，则跳过不处理' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



if "!param1!" == "" (
    echo 用法：把要解码的 .pem 文件，拖拽到本脚本上
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
if exist "!param1!\" (
    echo 错误：不支持拖入文件夹，请拖入单个 .pem 文件
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
if not exist "!param1_path!" (
    echo 错误：文件不存在："!param1_path!"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



echo 输入文件："!param1_path!"
if /i not "!param1_path:~-4!" == ".pem" (
    echo 错误：请拖入 .pem 后缀的文件
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
set "output_file=!param1_path:~0,-4!"
echo 输出文件："!output_file!"
if "!output_file!" == "" (
    echo 错误：无法确定输出路径
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
if exist "!output_file!" (
    echo 输出文件已存在："!output_file!"，跳过不处理
    echo 如果需要重新解码，请先移走旧文件
    echo.
    pause
    endlocal & endlocal & exit /b 2
)
echo.

set "certutil_path=!SystemRoot!\System32\certutil.exe"
"!certutil_path!" -decode "!param1_path!" "!output_file!"
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
