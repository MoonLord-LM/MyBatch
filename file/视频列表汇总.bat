@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '扫描符合指定格式命名的视频文件，生成汇总的 csv 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入文件夹路径' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '也可以拖拽文件夹到此脚本上，自动识别处理；不支持拖入单个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '视频命名格式：[名称 演员1&演员2&演员3 类型 评分]，各段之间用空格分隔，如果有多个演员用 & 连接' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '汇总表格内容：文件名 + 字节数 + 修改时间 + 名称 + 演员1 + 演员2 + 演员3 + 类型 + 评分' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '文件开头带有 UTF-8 BOM 头，可以在 Excel 中正确打开' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



set "path1=!param1!"

:loop

    :input_path1
    if "!path1!"=="" (
        echo 请输入要扫描的文件夹：
        set /p "path1="
        echo.
    ) else (
        echo 要扫描的文件夹："!path1!"
        echo.
    )
    if "!path1!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto end_loop
    )
    set "path1=!path1:"=!"
    if "!path1!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto end_loop
    )
    if "!path1:~-1!"=="\" set "path1=!path1:~0,-1!"
    if not exist "!path1!" (
        echo 错误：路径不存在："!path1!"，请重新输入
        echo.
        set "path1="
        goto input_path1
    )
    if not exist "!path1!\" (
        echo 错误：路径不是文件夹："!path1!"，请重新输入
        echo.
        set "path1="
        goto input_path1
    )

    set "file_path=!path1!"
    if "!file_path:~-1!"=="\" set "file_path=!file_path:~0,-1!"

    set "output_file=!cd!\!script_name!.csv"
    echo 输出列表文件："!output_file!"
    echo.

    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$files = @(Get-ChildItem -LiteralPath $env:file_path -File -Recurse);" ^
        "$exts = @(" ^
        "    '.mp4', '.mkv', '.ts', '.avi', '.wmv', '.flv', '.rmvb', '.rm'," ^
        "    '.vob', '.mpg', '.mpeg', '.3gp', '.m4v', '.f4v', '.mov', '.webm'" ^
        ");" ^
        "$videos = @($files | Where-Object { $_.Extension -in $exts });" ^
        "$pattern = '^([^ ]+) ([^ &]+(?:&[^ &]+){0,2}) ([^ ]+) ([^ ]+)$';" ^
        "$matched = @($videos | Where-Object { $_.BaseName -match $pattern });" ^
        "$existing = @();" ^
        "if (Test-Path -LiteralPath $env:output_file) {" ^
        "    $existing = @(Get-Content -LiteralPath $env:output_file -Encoding UTF8 | Where-Object { $_ -ne '' });" ^
        "    Write-Host ('加载现有列表，共 ' + $existing.Count + ' 个视频文件');" ^
        "};" ^
        "if ($matched.Count -eq 0 -and $existing.Count -eq 0) {" ^
        "    Write-Host ('扫描到 ' + $videos.Count + ' 个视频文件，没有符合命名格式的');" ^
        "    exit 0;" ^
        "};" ^
        "$lines = @($matched | ForEach-Object {" ^
        "    $null = $_.BaseName -match $pattern;" ^
        "    $actors = @($matches[2] -split '&');" ^
        "    while ($actors.Count -lt 3) { $actors += '' };" ^
        "    '\"{0}\",\"{1}\",\"{2:yyyy-MM-dd HH:mm:ss}\",\"{3}\",\"{4}\",\"{5}\",\"{6}\",\"{7}\",\"{8}\"' -f" ^
        "        $_.Name, $_.Length, $_.LastWriteTime," ^
        "        $matches[1], $actors[0], $actors[1], $actors[2]," ^
        "        $matches[3], $matches[4]" ^
        "});" ^
        "$sep = [string][char]34 + ',' + [string][char]34;" ^
        "$nameOf = { param($l) ((@($l -split $sep))[0]).Substring(1) };" ^
        "$idOf = { param($l) (@($l -split $sep))[3] };" ^
        "$oldById = @{};" ^
        "foreach ($l in $existing) { $oldById[(& $idOf $l)] = $l };" ^
        "$updated = 0; $unchanged = 0;" ^
        "foreach ($l in $lines) {" ^
        "    $k = & $idOf $l;" ^
        "    if ($oldById.ContainsKey($k)) {" ^
        "        if ($oldById[$k] -eq $l) {" ^
        "            $unchanged += 1;" ^
        "        } else {" ^
        "            $updated += 1;" ^
        "            Write-Host ('更新 [' + $k + ']：');" ^
        "            Write-Host ('  旧：' + $oldById[$k]);" ^
        "            Write-Host ('  新：' + $l);" ^
        "        };" ^
        "    };" ^
        "};" ^
        "$newIds = @{};" ^
        "foreach ($l in $lines) { $newIds[(& $idOf $l)] = $true };" ^
        "$kept = @($existing | Where-Object { -not $newIds.ContainsKey((& $idOf $_)) });" ^
        "$final = @((($kept + $lines) | Sort-Object { & $idOf $_ }, { & $nameOf $_ }));" ^
        "[System.IO.File]::WriteAllLines($env:output_file, [string[]]$final, (New-Object System.Text.UTF8Encoding($true)));" ^
        "Write-Host ('处理完成，扫描到 ' + $videos.Count + ' 个视频文件，符合命名格式的 ' + $matched.Count + ' 个（更新 ' + $updated + ' 条、相同 ' + $unchanged + ' 条、新增 ' + ($matched.Count - $updated - $unchanged) + ' 条），合并后共 ' + $final.Count + ' 条记录');"
    if !errorlevel! neq 0 (
        echo.
        echo 列表生成失败
    ) else if exist "!output_file!" (
        echo.
        echo 列表生成成功
    ) else (
        echo.
        echo 未生成列表
    )

    echo.
    set "path1="
    goto loop

:end_loop



echo.
pause
endlocal & endlocal & exit /b
