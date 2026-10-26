@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '把补丁文件中的改动，导入到指定 Git 仓库' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '补丁文件必须在 Git 仓库的同级目录，文件名格式为：仓库名.patch' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动扫描当前文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则处理拖入的文件夹；不支持拖入单个文件' -ForegroundColor Green"
echo.



REM 检查 Git 组件
"git.exe" --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 Git 组件 & REM
    echo 请从 https://git-scm.com/install/windows 下载，并完成安装 & REM
    "explorer.exe" "https://git-scm.com/install/windows"
    echo.
    pause
    exit /b 1
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
        exit /b 1
    )
    if exist "!param1!\" (
        echo 开始处理文件夹："!param1!"
        set "working_dir=!param1!"
        echo.
    ) else (
        echo 错误：不支持拖入单个文件，请拖入文件夹或双击运行
        echo.
        pause
        exit /b 1
    )
)

if not exist "!working_dir!\.git" (
    echo 错误：不是 Git 仓库，未找到 .git 文件夹："!working_dir!"
    echo.
    pause
    exit /b 1
)



for %%i in ("!working_dir!") do (
    setlocal disabledelayedexpansion
    set "repo_name=%%~nxi"
    set "parent_dir=%%~dpi"
    setlocal enabledelayedexpansion

    set "patch_file=!parent_dir!!repo_name!.patch"

    if not exist "!patch_file!" (
        echo 错误：补丁文件不存在："!patch_file!"
        echo.
        pause
        exit /b 1
    )

    echo 补丁文件位置："!patch_file!"
    echo.

    set "patch_size=-1"
    for /f %%s in ('powershell -NoProfile -Command "try { ([System.IO.FileInfo]($env:patch_file)).Length } catch { -1 }"') do set "patch_size=%%s"
    if "!patch_size!"=="-1" (
        echo 错误：补丁文件大小获取失败："!patch_file!"
        echo.
        pause
        exit /b 1
    )

    if "!patch_size!"=="0" (
        echo 错误：补丁文件内容为空："!patch_file!"
        echo.
        pause
        exit /b 1
    )

    echo 开始导入未提交的改动
    echo.

    "git.exe" -C "!working_dir!" apply "!patch_file!"
    if !errorlevel! neq 0 (
        echo 错误：导入差异文件失败
        echo.
        pause
        exit /b 1
    )

    echo 导入完成，补丁文件大小："!patch_size!" 字节
    echo.

    endlocal
    endlocal
)



echo.
pause
exit /b
