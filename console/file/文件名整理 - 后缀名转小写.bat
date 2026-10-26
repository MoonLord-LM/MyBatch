@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '把文件名后缀中的大写字母，统一转换为小写字母' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动扫描当前文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则递归处理其中所有文件；不支持拖入单个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '只处理文件名的后缀部分，自动跳过无后缀的文件' -ForegroundColor Green"
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



if not "!working_dir!" == "" (
    set "file_path=!working_dir!"
    if "!file_path:~-1!"=="\" set "file_path=!file_path:~0,-1!"

    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "skipped=0"
    set /a "name_conflict=0"
    set /a "rename_failed=0"

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
    if !errorlevel! neq 0 (
        echo 转换失败，请检查报错信息
        echo.
        if exist "!temp_set!" ( del /f /q "!temp_set!" )
        pause
        exit /b 1
    )
    echo.

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    set /a "fail_total=name_conflict+rename_failed"
    echo 批量处理完成 & REM
    echo 共计：!total! 个，成功：!succeeded! 个，失败：!fail_total! 个，跳过：!skipped! 个 & REM
    echo 其中，重命名成功 !succeeded! 个，目标文件已存在 !name_conflict! 个，重命名失败 !rename_failed! 个，跳过 !skipped! 个 & REM
)



echo.
pause
exit /b



-----BEGIN POWERSHELL CODE-----
[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;
$utf8NoBOM = [System.Text.UTF8Encoding]::new($false);
$files = @(Get-ChildItem -LiteralPath $env:file_path -File -Recurse | Where-Object { $_.Extension -ne '' });
if ($files.Count -eq 0) { Write-Host '没有找到带后缀的文件'; exit 0 }
Write-Host ('一共 ' + $files.Count + ' 个文件');
foreach ($d in ($files | Group-Object DirectoryName | Sort-Object Name)) {
    Write-Host ('处理文件夹："' + $d.Name + '"');
    $fileNames = [System.Collections.Generic.HashSet[string]]::new();
    foreach ($f in $d.Group) { [void]$fileNames.Add($f.Name) }
    $renameCount = 0;
    $conflictCount = 0;
    $failCount = 0;
    $skipCount = 0;
    foreach ($f in ($d.Group | Sort-Object Name)) {
        $lowerExt = $f.Extension.ToLowerInvariant();
        if ([string]::Equals($f.Extension, $lowerExt, [System.StringComparison]::Ordinal)) {
            $skipCount++;
            [System.IO.File]::AppendAllText($env:temp_set, 'set /a skipped+=1' + [System.Environment]::NewLine, $utf8NoBOM);
        } else {
            $newName = $f.BaseName + $lowerExt;
            if ($fileNames.Contains($newName)) {
                $conflictCount++;
                [System.IO.File]::AppendAllText($env:temp_set, 'set /a name_conflict+=1' + [System.Environment]::NewLine, $utf8NoBOM);
                Write-Host ('  跳过，目标已存在："' + $f.Name + '" -> "' + $newName + '"');
            } else {
                try {
                    Rename-Item -LiteralPath $f.FullName -NewName $newName;
                    [void]$fileNames.Remove($f.Name);
                    [void]$fileNames.Add($newName);
                    $renameCount++;
                    [System.IO.File]::AppendAllText($env:temp_set, 'set /a succeeded+=1' + [System.Environment]::NewLine, $utf8NoBOM);
                    Write-Host ('  重命名成功："' + $f.Name + '" -> "' + $newName + '"');
                } catch {
                    $failCount++;
                    [System.IO.File]::AppendAllText($env:temp_set, 'set /a rename_failed+=1' + [System.Environment]::NewLine, $utf8NoBOM);
                    Write-Host ('  重命名失败："' + $f.Name + '" -> "' + $newName + '"，报错信息：' + $_.Exception.Message);
                }
            }
        }
        [System.IO.File]::AppendAllText($env:temp_set, 'set /a total+=1' + [System.Environment]::NewLine, $utf8NoBOM);
    }
    Write-Host ('  重命名成功 ' + $renameCount + ' 个，目标文件已存在 ' + $conflictCount + ' 个，重命名失败 ' + $failCount + ' 个，跳过 ' + $skipCount + ' 个');
    Write-Host '';
}
-----END POWERSHELL CODE-----
