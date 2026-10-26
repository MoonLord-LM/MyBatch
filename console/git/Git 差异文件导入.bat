@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '批量把补丁文件中的改动，导入到 Git 仓库' -ForegroundColor Green"
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



set "temp_list=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!temp_list!"

set "repo_count=0"
for /f "delims=" %%n in ('
    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
        "$utf8NoBOM = [System.Text.UTF8Encoding]::new($false);" ^
        "$rootPath = $env:working_dir;" ^
        "if (Test-Path -LiteralPath (Join-Path $rootPath '.git')) {" ^
        "    [System.IO.File]::WriteAllText($env:temp_list, $rootPath, $utf8NoBOM);" ^
        "    Write-Output 1;" ^
        "} else {" ^
        "    $found = @(Get-ChildItem -LiteralPath $rootPath -Directory -Force -Recurse -ErrorAction SilentlyContinue |" ^
        "        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName '.git') } |" ^
        "        Where-Object { $parent = $_.Parent; while ($parent -ne $null -and $parent.FullName -ne $rootPath) { if (Test-Path -LiteralPath (Join-Path $parent.FullName '.git')) { return $false }; $parent = $parent.Parent }; return $true } |" ^
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
    set "repo_name=%%~nxd"
    set "parent_dir=%%~dpd"
    setlocal enabledelayedexpansion

    set "patch_file=!parent_dir!!repo_name!.patch"

    echo 正在处理仓库："!repo_dir!"
    echo.

    if not exist "!patch_file!" (
        echo 当前仓库没有对应的补丁文件，跳过
        echo set /a "skipped+=1">>"!temp_set!"
    ) else (
        echo 补丁文件位置："!patch_file!"
        set "patch_size=-1"
        for /f %%s in ('powershell -NoProfile -Command "try { ([System.IO.FileInfo]($env:patch_file)).Length } catch { -1 }"') do set "patch_size=%%s"
        if "!patch_size!"=="-1" (
            echo 错误：补丁文件大小获取失败："!patch_file!"
            echo set /a "failed+=1">>"!temp_set!"
        ) else if "!patch_size!"=="0" (
            echo 错误：补丁文件内容为空："!patch_file!"
            echo set /a "failed+=1">>"!temp_set!"
        ) else (
            "git.exe" -C "!repo_dir!" apply --check "!patch_file!" >nul 2>&1
            if !errorlevel! neq 0 (
                "git.exe" -C "!repo_dir!" apply --check -R "!patch_file!" >nul 2>&1
                if !errorlevel! equ 0 (
                    echo 当前仓库已包含补丁中的改动，跳过
                    echo set /a "skipped+=1">>"!temp_set!"
                ) else (
                    echo 错误：补丁与当前仓库的文件内容不匹配
                    echo set /a "failed+=1">>"!temp_set!"
                )
            ) else (
                "git.exe" -C "!repo_dir!" apply "!patch_file!"
                if !errorlevel! neq 0 (
                    echo 错误：导入差异文件失败
                    echo set /a "failed+=1">>"!temp_set!"
                ) else (
                    echo 导入完成，补丁文件大小："!patch_size!" 字节
                    echo set /a "succeeded+=1">>"!temp_set!"
                )
            )
        )
    )
    echo set /a "total+=1">>"!temp_set!"
    echo.

    endlocal
    endlocal
)

REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )
if exist "!temp_list!" ( del /f /q "!temp_list!" )

echo 全部处理完成
echo 共计：!total! 个仓库，导入成功：!succeeded! 个，导入失败：!failed! 个，跳过：!skipped! 个 & REM



echo.
pause
exit /b
