@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '批量同步 Git 仓库的远端代码' -ForegroundColor Green"
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



set "temp_list=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!temp_list!"

set "repo_count=0"
for /f "delims=" %%n in ('
    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
        "$utf8NoBOM = [System.Text.UTF8Encoding]::new($false);" ^
        "if (Test-Path -LiteralPath (Join-Path $env:working_dir '.git')) {" ^
        "    [System.IO.File]::WriteAllText($env:temp_list, $env:working_dir, $utf8NoBOM);" ^
        "    Write-Output 1;" ^
        "} else {" ^
        "    $found = @(Get-ChildItem -LiteralPath $env:working_dir -Directory -Force -ErrorAction SilentlyContinue |" ^
        "        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName '.git') } |" ^
        "        ForEach-Object { $_.FullName });" ^
        "    if ($found.Count -gt 0) { [System.IO.File]::WriteAllLines($env:temp_list, [string[]]$found, $utf8NoBOM) };" ^
        "    Write-Output $found.Count;" ^
        "};"
') do (
    set "repo_count=%%n"
)

if "!repo_count!"=="0" (
    echo 错误：未扫描到 Git 仓库文件夹："!working_dir!"
    if exist "!temp_list!" ( del /f /q "!temp_list!" )
    echo.
    pause
    exit /b 1
)

echo 扫描到 !repo_count! 个 Git 仓库
echo.

REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

set /a "total=0"
set /a "succeeded=0"
set /a "failed=0"
set /a "skipped=0"

for /f "usebackq delims=" %%d in ("!temp_list!") do (
    setlocal disabledelayedexpansion
    set "repo_dir=%%d"
    setlocal enabledelayedexpansion

    echo 正在处理仓库："!repo_dir!"
    echo.

    set "branch_name="
    for /f "delims=" %%b in ('
        powershell -NoProfile -Command ^
            "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
            "& git.exe -C $env:repo_dir rev-parse --abbrev-ref HEAD 2>$null"
    ') do (
        set "branch_name=%%b"
    )

    if "!branch_name!"=="HEAD" (
        echo 错误：当前处于分离 HEAD 状态，跳过同步
        echo set /a "skipped+=1">>"!temp_set!"
        echo set /a "total+=1">>"!temp_set!"
        echo.
    ) else if "!branch_name!"=="" (
        echo 错误：获取当前分支失败，跳过同步
        echo set /a "failed+=1">>"!temp_set!"
        echo set /a "total+=1">>"!temp_set!"
        echo.
    ) else (
        echo 当前分支：!branch_name!

        set "worktree_clean=0"
        for /f "delims=" %%s in ('
            powershell -NoProfile -Command ^
                "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                "$changed = @(& git.exe -C $env:repo_dir status --porcelain 2>$null);" ^
                "Write-Output ([int]($changed.Count -eq 0));"
        ') do (
            set "worktree_clean=%%s"
        )

        if "!worktree_clean!"=="0" (
            echo 错误：本地存在未提交的修改，跳过同步
            echo set /a "skipped+=1">>"!temp_set!"
            echo set /a "total+=1">>"!temp_set!"
            echo.
        ) else (
            echo "git.exe" -C "!repo_dir!" fetch --all --prune --progress
            "git.exe" -C "!repo_dir!" fetch --all --prune --progress
            if !errorlevel! neq 0 (
                echo 错误：拉取远端的最新信息失败
                echo set /a "failed+=1">>"!temp_set!"
                echo set /a "total+=1">>"!temp_set!"
                echo.
            ) else (
                echo "git.exe" -C "!repo_dir!" pull --no-rebase --progress
                "git.exe" -C "!repo_dir!" pull --no-rebase --progress
                if !errorlevel! neq 0 (
                    echo 错误：合并远端的分支失败
                    echo set /a "failed+=1">>"!temp_set!"
                    echo set /a "total+=1">>"!temp_set!"
                ) else (
                    echo 同步完成
                    echo set /a "succeeded+=1">>"!temp_set!"
                    echo set /a "total+=1">>"!temp_set!"
                )
                echo.
            )
        )
    )

    endlocal
    endlocal
)

REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )
if exist "!temp_list!" ( del /f /q "!temp_list!" )

echo 全部处理完成
echo 共计：!total! 个仓库，同步成功：!succeeded! 个，同步失败：!failed! 个，跳过：!skipped! 个 & REM



echo.
pause
exit /b
