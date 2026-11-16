@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
set "param2=%~2"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '从 Git 仓库中彻底删除指定文件，清理空间' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动扫描当前文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则处理拖入的文件夹；不支持拖入单个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '此操作不可逆，执行前请先备份仓库，并确保没有未提交的改动' -ForegroundColor Green"
echo.



REM 检查 Git 组件
git --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 Git 组件 & REM
    echo 请从 https://git-scm.com/install/windows 下载，并完成安装 & REM
    "explorer.exe" "https://git-scm.com/install/windows"
    echo.
    pause
    exit /b 1
)

REM 检查 git-filter-repo 组件
git filter-repo -h >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 git-filter-repo 组件 & REM
    echo 请从 https://git-scm.com/install/windows 下载，并完成安装 & REM
    "explorer.exe" "https://git-scm.com/install/windows"
    echo.
    pause
    exit /b 1
)



set "repo_dir=!param1!"
set "delete_file_path=!param2!"

:input_repo_dir
    if "!repo_dir!"=="" (
        echo 请输入 Git 仓库文件夹路径：
        set /p "repo_dir="
        if !errorlevel! neq 0 (
            echo 无输入，退出脚本
            echo.
            exit /b 1
        )
        echo.
    ) else (
        echo 仓库文件夹："!repo_dir!"
        echo.
    )
    if "!repo_dir!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_repo_dir
    )
    set "repo_dir=!repo_dir:"=!"
    if "!repo_dir!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_repo_dir
    )
    if "!repo_dir:~-1!"=="\" set "repo_dir=!repo_dir:~0,-1!"
    if not exist "!repo_dir!" (
        echo 错误：路径不存在："!repo_dir!"，请重新输入
        echo.
        set "repo_dir="
        goto input_repo_dir
    )
    if not exist "!repo_dir!\" (
        echo 错误：路径不是文件夹："!repo_dir!"，请重新输入
        echo.
        set "repo_dir="
        goto input_repo_dir
    )
    if not exist "!repo_dir!\.git" (
        echo 错误：路径不是 Git 仓库，不包含 .git 文件夹："!repo_dir!"，请重新输入
        echo.
        set "repo_dir="
        goto input_repo_dir
    )



REM 检查工作区是否干净
set "dirty_count=-1"
for /f "delims=" %%s in ('
    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
        "$changed = @(& git.exe -C $env:repo_dir status --porcelain 2>$null);" ^
        "if ($LASTEXITCODE -ne 0) { Write-Output -1 } else { Write-Output $changed.Count }"
') do set "dirty_count=%%s"
if "!dirty_count!"=="-1" (
    echo 错误：检查仓库状态失败
    echo.
    pause
    exit /b 1
)
if not "!dirty_count!"=="0" (
    echo 错误：仓库存在未提交的改动，请先提交后再运行
    echo.
    pause
    exit /b 1
)

REM 记录原始 origin 地址，filter-repo 默认会移除 origin
set "origin_url="
for /f "delims=" %%u in ('
    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
        "$url = ((@(& git.exe -C $env:repo_dir remote get-url origin 2>$null)) -join '').Trim();" ^
        "if ($url -ne '') { Write-Output $url }"
') do set "origin_url=%%u"
if "!origin_url!"=="" (
    echo 提示：当前仓库没有配置 origin 远程仓库
) else (
    echo 当前 origin 地址："!origin_url!"
)
echo.

REM 确认操作
echo 警告：即将重写所有分支和标签的历史，并立即清除旧对象，操作不可逆 & REM
echo 建议先备份整个仓库文件夹 & REM
echo.
pause

:loop

    :input_delete_path
        if "!delete_file_path!"=="" (
            echo 请输入要从历史中彻底删除的文件路径：
            set /p "delete_file_path="
            if !errorlevel! neq 0 (
                echo 无输入，退出脚本
                exit /b 1
            )
            echo.
        ) else (
            echo 彻底删除的文件路径："!delete_file_path!"
            echo.
        )
        if "!delete_file_path!"=="" goto input_done
        set "delete_file_path=!delete_file_path:"=!"
        if "!delete_file_path!"=="" (
            echo 输入不能为空，请重新输入
            echo.
            set "delete_file_path="
            goto input_delete_path
        )

        REM 规范化为仓库内路径
        set "path_result="
        for /f "delims=" %%p in ('
            powershell -NoProfile -Command ^
                "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                "$inputValue = $env:delete_file_path;" ^
                "$repoRoot = $env:repo_dir;" ^
                "$isAbsolute = ($inputValue.Length -ge 2 -and $inputValue[1] -eq ':') -or $inputValue.StartsWith('//');" ^
                "if ($isAbsolute) {" ^
                "    $full = [System.IO.Path]::GetFullPath($inputValue);" ^
                "    $prefix = $repoRoot.Replace('/', '\').TrimEnd('\') + '\';" ^
                "    if (-not $full.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) { Write-Output 'ERROR'; exit 0 };" ^
                "    $relative = $full.Substring($prefix.Length);" ^
                "} else {" ^
                "    $relative = $inputValue;" ^
                "};" ^
                "$relative = $relative.Replace('\', '/');" ^
                "if ($relative.StartsWith('./')) { $relative = $relative.Substring(2) };" ^
                "if ($relative -eq '' -or $relative.StartsWith('/') -or $relative.Split('/') -contains '..') { Write-Output 'ERROR'; exit 0 };" ^
                "Write-Output $relative;"
        ') do set "path_result=%%p"
        if "!path_result!"=="ERROR" (
            echo 错误：路径无效或不在当前仓库内："!delete_file_path!"
            echo.
            set "delete_file_path="
            goto input_delete_path
        )
        if "!path_result!"=="" (
            echo 错误：路径解析失败："!delete_file_path!"
            goto cleanup_fail
        )
        set "delete_file_path=!path_result!"

        REM 查看该路径在历史中的提交数量
        set "commit_count=-1"
        for /f "delims=" %%c in ('
            powershell -NoProfile -Command ^
                "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                "$commits = @(& git.exe -C $env:repo_dir log --all --full-history --oneline -- $env:delete_file_path 2>$null);" ^
                "if ($LASTEXITCODE -ne 0) { Write-Output -1 } else { Write-Output $commits.Count }"
        ') do set "commit_count=%%c"
        if "!commit_count!"=="-1" (
            echo 错误：检查历史记录失败："!delete_file_path!"
            goto cleanup_fail
        )
        echo 已添加："!delete_file_path!"，历史中有 !commit_count! 个提交

        echo.



REM 重写历史：删除所有分支和标签中匹配的路径
echo 执行 git filter-repo --path ... --invert-paths --force
git -C "!repo_dir!" filter-repo --path "!delete_file_path!" --invert-paths --force
if !errorlevel! neq 0 (
    echo 错误：重写历史失败
    goto cleanup_fail
)

REM 彻底清理空间
echo 执行 reflog 清理
git -C "!repo_dir!" reflog expire --expire=now --all
if !errorlevel! neq 0 (
    echo 错误：清理 reflog 失败
    goto cleanup_fail
)

echo 执行垃圾回收
git -C "!repo_dir!" gc --prune=now --aggressive
if !errorlevel! neq 0 (
    echo 错误：垃圾回收失败
    goto cleanup_fail
)

echo 执行重新打包
git -C "!repo_dir!" repack -ad --depth=250 --window=250
if !errorlevel! neq 0 (
    echo 错误：重新打包失败
    goto cleanup_fail
)

REM 恢复 origin 远程仓库，便于手动推送
if not "!origin_url!"=="" (
    echo 恢复 origin 远程仓库
    git -C "!repo_dir!" remote remove origin >nul 2>&1
    git -C "!repo_dir!" remote add origin "!origin_url!"
    if !errorlevel! neq 0 (
        echo 错误：恢复 origin 远程仓库失败
        goto cleanup_fail
    )
)

REM 验证：所有被删除路径在历史中都不再有提交
echo.
echo 验证历史清理结果：
set "verify_failed=0"
for /f "tokens=1,* delims=|" %%a in ('
    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
        "$p = $env:delete_file_path;" ^
        "$commits = @(& git.exe -C $env:repo_dir log --all --full-history --oneline -- $p 2>$null);" ^
        "if ($LASTEXITCODE -ne 0) { Write-Output ('ERROR|' + $p) } else { Write-Output ($commits.Count.ToString() + '|' + $p) };"
') do (
    if "%%a"=="ERROR" (
        echo 错误：检查历史记录失败："%%b"
        set "verify_failed=1"
    ) else if "%%a"=="0" (
        echo 已彻底删除："%%b"
    ) else (
        echo 错误：历史中仍有 %%a 个提交："%%b"
        set "verify_failed=1"
    )
)
if "!verify_failed!"=="1" (
    echo 错误：历史清理验证未通过
    goto cleanup_fail
)

set "delete_file_path="
goto loop

:input_done
echo.
echo 全部处理完成，历史清理和空间回收已完成 & REM
echo.
echo 请手动推送所有分支：
echo # 推送所有分支
echo git push origin --force --all
echo # 如果有 tag，一并推送
echo git push origin --force --tags
echo.



echo.
pause
exit /b

:cleanup_fail
    echo.
    pause
    exit /b 1
