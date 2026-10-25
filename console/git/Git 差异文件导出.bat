@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '导出指定 Git 仓库中未提交的改动，保存为补丁文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动扫描当前文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则处理拖入的文件夹；不支持拖入单个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '补丁文件保存在 Git 仓库的同级目录，文件名格式为：仓库名.patch' -ForegroundColor Green"
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

    echo 开始导出未提交的改动
    echo.

    REM 暂存所有改动
    "git.exe" -C "!working_dir!" add .
    if !errorlevel! neq 0 (
        echo 错误：暂存改动失败
        echo.
        pause
        exit /b 1
    )

    set "changed_count=-1"
    for /f "delims=" %%s in ('
        powershell -NoProfile -Command ^
            "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
            "$changed = @(& git.exe -C $env:working_dir status --porcelain --untracked-files=no 2>$null);" ^
            "if ($LASTEXITCODE -ne 0) { Write-Output -1; exit 0 };" ^
            "Write-Output $changed.Count;"
    ') do (
        set "changed_count=%%s"
    )
    if "!changed_count!"=="-1" (
        echo 错误：检查未提交的改动失败
        echo.
        pause
        exit /b 1
    )

    if "!changed_count!"=="0" (
        echo 当前仓库没有未提交的改动，未生成补丁文件
        echo.
        pause
        exit /b
    )

    echo 输出补丁文件："!patch_file!"
    echo.

    "git.exe" -C "!working_dir!" diff HEAD --binary --output="!patch_file!"
    if !errorlevel! neq 0 (
        echo 错误：导出差异文件失败
        echo.
        pause
        exit /b 1
    )

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

    echo 导出完成
    echo.

    endlocal
    endlocal
)



echo.
pause
exit /b
