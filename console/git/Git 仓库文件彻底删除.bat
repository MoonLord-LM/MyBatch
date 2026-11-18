@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
set "param2=%~2"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '从 Git 仓库中彻底删除指定文件，并清理相关的历史记录' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '此操作不可逆，执行前请先备份仓库，并确保没有未提交的改动' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动扫描当前文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则处理拖入的文件夹；不支持拖入单个文件' -ForegroundColor Green"
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

REM 检查 git-filter-repo 组件，缺少时自动安装
python.exe -m git_filter_repo -h >nul 2>&1
if !errorlevel! neq 0 (
    echo 缺少 git-filter-repo 组件，正在尝试安装 & REM
    python.exe -m pip install git-filter-repo
    if !errorlevel! neq 0 (
        echo 错误：执行 python.exe -m pip install git-filter-repo 失败，请检查报错信息 & REM
        echo.
        pause
        exit /b 1
    )
    python.exe -m git_filter_repo -h
    if !errorlevel! neq 0 (
        echo 错误：执行 python.exe -m git_filter_repo -h 失败，请检查报错信息 & REM
        echo.
        pause
        exit /b 1
    )
    echo 安装完成
    echo.
)



set "repo_dir=!param1!"
set "delete_file_path=!param2!"

:input_repo_dir
    if "!repo_dir!"=="" (
        if exist "!cd!\.git" (
            set "repo_dir=!cd!"
            echo 当前仓库文件夹："!repo_dir!"
            echo.
        ) else (
            echo 请输入 Git 仓库文件夹路径：
            set /p "repo_dir="
            if !errorlevel! neq 0 (
                echo 无输入，退出脚本
                echo.
                exit /b 1
            )
            echo.
        )
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



echo 警告：彻底删除指定文件，并清理相关的历史记录
echo 此操作不可逆，执行前请先备份仓库，并确保没有未提交的改动
echo.
pause
echo.



:loop

    :input_file_path
        if "!delete_file_path!"=="" (
            echo 请输入要彻底删除的文件或文件夹路径：
            set /p "delete_file_path="
            if !errorlevel! neq 0 (
                echo 无输入，退出脚本
                echo.
                exit /b 1
            )
            echo.
        ) else (
            echo 要彻底删除的文件路径："!delete_file_path!"
            echo.
        )
        if "!delete_file_path!"=="" (
            echo 输入不能为空，请重新输入
            echo.
            goto input_file_path
        )
        set "delete_file_path=!delete_file_path:"=!"
        if "!delete_file_path!"=="" (
            echo 输入不能为空，请重新输入
            echo.
            goto input_file_path
        )

        REM 从自身文件末尾的 -----BEGIN POWERSHELL CODE----- / -----END POWERSHELL CODE----- 之间提取 PowerShell 代码
        powershell -NoProfile -Command ^
            "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
            "$lines = Get-Content -Encoding UTF8 -LiteralPath $env:script_path;" ^
            "$begin = [array]::IndexOf($lines, '-----BEGIN POWERSHELL CODE-----') + 1;" ^
            "$end = [array]::IndexOf($lines, '-----END POWERSHELL CODE-----');" ^
            "if ($begin -lt 1 -or $end -lt $begin) {" ^
            "    Write-Host '错误：未找到内嵌的 PowerShell 代码块' -ForegroundColor Red;" ^
            "    exit 1;" ^
            "};" ^
            "$code = $lines[$begin..($end - 1)] -join [System.Environment]::NewLine;" ^
            "Invoke-Expression $code"
        if !errorlevel! equ 2 (
            echo 输入异常，请重新输入
            echo.
            set "delete_file_path="
            goto input_file_path
        )
        if !errorlevel! neq 0 (
            echo 文件删除失败，请检查报错信息
            echo.
            pause
            exit /b 1
        )

        echo.
        echo 处理完成
        echo.
        echo 请手动推送所有分支
        echo git push origin --force --all
        echo git push origin --force --tags
        echo.
        set "delete_file_path="

goto loop



echo.
pause
exit /b



-----BEGIN POWERSHELL CODE-----
[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;

$repoDir = $env:repo_dir;
$deleteFilePath = $env:delete_file_path;
$isDirectory = $deleteFilePath.EndsWith('/') -or $deleteFilePath.EndsWith('\');

# 检查工作区是否干净
$changedLines = @(& git.exe -C $repoDir status --porcelain 2>$null);
if ($LASTEXITCODE -ne 0) {
    Write-Host '错误：检查仓库状态失败' -ForegroundColor Red;
    exit 1;
}
if ($changedLines.Count -ne 0) {
    Write-Host '错误：仓库存在未提交的改动，请先提交后再运行' -ForegroundColor Red;
    exit 1;
}

# 记录原始 origin 地址，filter-repo 默认会移除 origin
$originUrl = ((@(& git.exe -C $repoDir remote get-url origin 2>$null)) -join '').Trim();
if ([string]::IsNullOrEmpty($originUrl)) {
    Write-Host '提示：当前仓库没有配置 origin 远程仓库';
} else {
    Write-Host "当前 origin 地址：$originUrl";
}
Write-Host '';

# 规范化为仓库内路径
$inputValue = $deleteFilePath;
$repoRoot = [System.IO.Path]::GetFullPath($env:repo_dir).Replace('/', '\');
$isAbsolute = ($inputValue.Length -ge 2 -and $inputValue[1] -eq ':') -or $inputValue.StartsWith('//');
if ($isAbsolute) {
    $fullPath = [System.IO.Path]::GetFullPath($inputValue);
    $prefix = $repoRoot.TrimEnd('\') + '\';
    if (-not $fullPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Host "错误：路径无效或不在当前仓库内：$inputValue" -ForegroundColor Red;
        exit 2;
    }
    $relative = $fullPath.Substring($prefix.Length);
} else {
    $relative = $inputValue;
}
$relative = $relative.Replace('\', '/');
if ($relative.StartsWith('./')) { $relative = $relative.Substring(2) };
if ($relative.StartsWith('/')) { $relative = $relative.Substring(1) };
if ($relative -eq '' -or $relative.Split('/') -contains '..') {
    Write-Host "错误：路径无效或不在当前仓库内：$inputValue" -ForegroundColor Red;
    exit 2;
}
$deleteFilePath = $relative;
if ($isDirectory) {
    if (-not $deleteFilePath.EndsWith('/')) { $deleteFilePath = $deleteFilePath + '/' };
    Write-Host "文件夹模式：将删除该路径下的所有文件";
};

# 查看该路径在历史中的提交数量
$commits = @(& git.exe -C $repoDir log --all --full-history --oneline -- $deleteFilePath 2>$null);
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误：检查历史记录失败：$deleteFilePath" -ForegroundColor Red;
    exit 1;
}
Write-Host "历史中有 $($commits.Count) 个提交：$deleteFilePath";
Write-Host '';

# 重写历史：删除所有分支和标签中匹配的路径
Write-Host "执行 python.exe -m git_filter_repo --path '$deleteFilePath' --invert-paths --force";
Push-Location $repoDir;
try {
    & python.exe -m git_filter_repo --path $deleteFilePath --invert-paths --force;
    $frExit = $LASTEXITCODE;
} finally {
    Pop-Location;
}
if ($frExit -ne 0) {
    Write-Host '错误：重写历史失败' -ForegroundColor Red;
    exit 1;
}

# 恢复 origin 远程仓库，便于手动推送
if (-not [string]::IsNullOrEmpty($originUrl)) {
    Write-Host '恢复 origin 远程仓库';
    & git.exe -C $repoDir remote remove origin >$null 2>&1;
    & git.exe -C $repoDir remote add origin $originUrl;
    if ($LASTEXITCODE -ne 0) {
        Write-Host '错误：恢复 origin 远程仓库失败' -ForegroundColor Red;
        exit 1;
    }
}

# 验证：该路径在历史中不再有提交
Write-Host '';
Write-Host '验证历史清理结果：';
$verifyCommits = @(& git.exe -C $repoDir log --all --full-history --oneline -- $deleteFilePath 2>$null);
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误：检查历史记录失败：$deleteFilePath" -ForegroundColor Red;
    Write-Host '错误：历史清理验证未通过' -ForegroundColor Red;
    exit 1;
}
if ($verifyCommits.Count -ne 0) {
    Write-Host "错误：历史中仍有 $($verifyCommits.Count) 个提交：$deleteFilePath" -ForegroundColor Red;
    Write-Host '错误：历史清理验证未通过' -ForegroundColor Red;
    exit 1;
}
Write-Host "已彻底删除：$deleteFilePath";
-----END POWERSHELL CODE-----
