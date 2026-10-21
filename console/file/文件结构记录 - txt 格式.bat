@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
set "param2=%~2"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '记录指定文件夹的树形结构，生成 txt 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动扫描当前文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则递归处理其中所有文件；不支持拖入单个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '参数1：要记录的文件夹路径，可选参数2：探索深度，默认 0 代表不限制深度' -ForegroundColor Green"
echo.



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

if "!param2!" == "" (
    set "depth_value=0"
    echo 未提供探索深度，默认不限制深度
    echo.
) else (
    set "depth_value=!param2!"
)



if not "!working_dir!" == "" (
    set "file_path=!working_dir!"
    if "!file_path:~-1!"=="\" set "file_path=!file_path:~0,-1!"
    for %%i in ("!file_path!") do (
        setlocal disabledelayedexpansion
        set "file_name=%%~ni"
        setlocal enabledelayedexpansion

        set "output_file=!file_path!\!file_name!.tree.txt"
        echo 输出结构文件："!output_file!"
        echo.

        set "self_script=!script_path!"
        powershell -NoProfile -Command ^
            "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
            "$utf8NoBOM = [System.Text.UTF8Encoding]::new($false);" ^
            "$targetPath = $env:file_path;" ^
            "$rawDepth = $env:depth_value;" ^
            "if (-not ($rawDepth -match '^\d+$')) { Write-Host '错误：探索深度必须是非负整数' -ForegroundColor Red; exit 1 };" ^
            "$maxDepth = [int]$rawDepth;" ^
            "function Print-Tree { param($Path, $Prefix, $Depth, $MaxDepth)" ^
            "    $items = @(Get-ChildItem -LiteralPath $Path | Where-Object { $_.FullName -ne $env:self_script -and $_.FullName -ne $env:output_file } | Sort-Object PSIsContainer, Name);" ^
            "    $result = @();" ^
            "    for ($i = 0; $i -lt $items.Count; $i++) {" ^
            "        $isLast = ($i -eq ($items.Count - 1));" ^
            "        $conn = if ($isLast) { '└───' } else { '├───' };" ^
            "        $result += ($Prefix + $conn + $items[$i].Name);" ^
            "        if ($items[$i].PSIsContainer) {" ^
            "            $canRecurse = ($MaxDepth -eq 0) -or ($Depth -lt $MaxDepth);" ^
            "            if ($canRecurse) {" ^
            "                $childPrefix = $Prefix + $(if ($isLast) { '    ' } else { '│   ' });" ^
            "                $result += Print-Tree -Path $items[$i].FullName -Prefix $childPrefix -Depth ($Depth + 1) -MaxDepth $MaxDepth;" ^
            "            }" ^
            "        }" ^
            "    }" ^
            "    return $result" ^
            "};" ^
            "$lines = @($targetPath);" ^
            "$lines += Print-Tree -Path $targetPath -Prefix '' -Depth 1 -MaxDepth $maxDepth;" ^
            "[System.IO.File]::WriteAllLines($env:output_file, [string[]]$lines, $utf8NoBOM);" ^
            "Write-Host ('处理完成，共计 ' + $lines.Count + ' 行');"
        if !errorlevel! neq 0 (
            echo.
            echo 结构生成失败
        ) else if exist "!output_file!" (
            echo.
            echo 结构生成成功
        ) else (
            echo.
            echo 错误：未生成结构文件
            echo.
            pause
            exit /b 1
        )

        endlocal
        endlocal
    )
)



echo.
pause
exit /b
