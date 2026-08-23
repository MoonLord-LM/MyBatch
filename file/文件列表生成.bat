@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '递归扫描文件夹中的所有文件，生成 txt 列表文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动扫描当前文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则递归处理其中所有文件；不支持拖入单个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '列表文件的内容为：完整路径 + 字节数 + 修改时间，每个文件一行' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



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
        echo 错误：不支持拖入单个文件，请拖入文件夹或双击运行
        echo.
        pause
        endlocal & endlocal & exit /b 1
    )
)

if not "!working_dir!" == "" (
    set "file_path=!working_dir!"
    if "!file_path:~-1!"=="\" set "file_path=!file_path:~0,-1!"
    for %%i in ("!file_path!") do (
        setlocal disabledelayedexpansion
        set "file_name=%%~ni"
        setlocal enabledelayedexpansion

        set "output_file=!file_path!\!file_name!.list.txt"
        echo 输出列表文件："!output_file!"
        echo.

        set "self_script=!script_path!"
        powershell -NoProfile -Command ^
         "[Console]::OutputEncoding=[Text.Encoding]::UTF8; $files = @(Get-ChildItem -LiteralPath $env:file_path -File -Recurse | Where-Object { $_.FullName -ne $env:self_script -and $_.FullName -ne $env:output_file });" ^
         "if ($files.Count -eq 0) { Write-Host '文件夹中没有文件'; exit 0 };" ^
         "$lines = @($files | Sort-Object FullName | ForEach-Object { '\"{0}\",\"{1}\",\"{2:yyyy-MM-dd HH:mm:ss}\"' -f $_.FullName, $_.Length, $_.LastWriteTime });" ^
         "[System.IO.File]::WriteAllLines($env:output_file, [string[]]$lines);" ^
         "Write-Host ('处理完成，共计 ' + $files.Count + ' 个文件');"
        echo.
        if !errorlevel! neq 0 (
            echo 列表生成失败
        ) else if exist "!output_file!" (
            echo 列表生成成功
        ) else (
            echo 文件夹中没有文件，未生成列表
        )

        endlocal
        endlocal
    )
)



echo.
pause
endlocal & endlocal & exit /b
