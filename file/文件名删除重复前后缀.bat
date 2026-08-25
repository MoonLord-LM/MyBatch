@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '删除多个文件名中重复的公共前缀和后缀' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则递归处理其中所有文件；不支持拖入单个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 jpg jpeg png webp bmp gif tif tiff heic heif avif mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm ico' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '按格式对文件分组，每种格式单独分析处理' -ForegroundColor Green"
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

    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "skipped=0"
    set /a "name_conflict=0"
    set /a "rename_failed=0"

    powershell -NoProfile -Command ^
     "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
     "$ext_filter = '^\.(jpg|jpeg|png|webp|bmp|gif|tif|tiff|heic|heif|avif|mp4|mkv|ts|avi|wmv|flv|rmvb|rm|vob|mpg|mpeg|3gp|m4v|f4v|mov|webm|ico)$';" ^
     "$files = @(Get-ChildItem -LiteralPath $env:file_path -File -Recurse | Where-Object { $_.Extension -match $ext_filter });" ^
     "if ($files.Count -eq 0) { Write-Host '没有找到指定格式的文件'; exit 0 };" ^
     "Write-Host ('一共 ' + $files.Count + ' 个文件');" ^
     "foreach ($g in ($files | Group-Object Extension)) {" ^
     "    if ($g.Count -eq 1) {" ^
     "        Add-Content -LiteralPath $env:temp_set -Value 'set /a skipped+=1';" ^
     "        Write-Host ('跳过，单文件，无公共前后缀：\"' + $g.Group[0].Name + '\"');" ^
     "        Add-Content -LiteralPath $env:temp_set -Value 'set /a total+=1';" ^
     "        continue;" ^
     "    };" ^
     "    $names = @($g.Group | ForEach-Object { $_.BaseName });" ^
     "    $prefix = $names[0];" ^
     "    foreach ($n in $names) {" ^
     "        while ($prefix.Length -gt 0 -and -not $n.StartsWith($prefix)) { $prefix = $prefix.Substring(0, $prefix.Length - 1) };" ^
     "        if ($prefix.Length -eq 0) { break };" ^
     "    };" ^
     "    $suffix = '';" ^
     "    $minLength = ($names | Measure-Object -Property Length -Minimum).Minimum;" ^
     "    for ($i = 1; $i -le $minLength; $i++) {" ^
     "        $ch = $names[0][$names[0].Length - $i];" ^
     "        $allMatch = $true;" ^
     "        foreach ($n in $names) { if ($n[$n.Length - $i] -ne $ch) { $allMatch = $false; break } };" ^
     "        if (-not $allMatch) { break };" ^
     "        $suffix = $ch + $suffix;" ^
     "    };" ^
     "    if ($prefix.Length -eq 0 -and $suffix.Length -eq 0) {" ^
     "        Write-Host ('跳过，无公共前后缀：\"' + $g.Name + '\"，共 ' + $g.Count + ' 个文件');" ^
     "        Add-Content -LiteralPath $env:temp_set -Value ('set /a skipped+=' + $g.Count);" ^
     "        Add-Content -LiteralPath $env:temp_set -Value ('set /a total+=' + $g.Count);" ^
     "        continue;" ^
     "    };" ^
     "    Write-Host ('\"' + $g.Name + '\"：公共前缀 \"' + $prefix + '\"，公共后缀 \"' + $suffix + '\"');" ^
     "    $coreNames = @();" ^
     "    foreach ($f in $g.Group) {" ^
     "        $core = $f.BaseName;" ^
     "        if ($prefix.Length -gt 0 -and $core.StartsWith($prefix)) { $core = $core.Substring($prefix.Length) };" ^
     "        if ($suffix.Length -gt 0 -and $core.EndsWith($suffix)) { $core = $core.Substring(0, $core.Length - $suffix.Length) };" ^
     "        if ([string]::IsNullOrEmpty($core)) { $core = $f.BaseName };" ^
     "        $coreNames += $core;" ^
     "    };" ^
     "    $maxDigits = 0;" ^
     "    foreach ($cn in $coreNames) { if ($cn -match '^\d+$' -and $cn.Length -gt $maxDigits) { $maxDigits = $cn.Length } };" ^
     "    foreach ($f in $g.Group) {" ^
     "        $core = $f.BaseName;" ^
     "        if ($prefix.Length -gt 0 -and $core.StartsWith($prefix)) { $core = $core.Substring($prefix.Length) };" ^
     "        if ($suffix.Length -gt 0 -and $core.EndsWith($suffix)) { $core = $core.Substring(0, $core.Length - $suffix.Length) };" ^
     "        if ([string]::IsNullOrEmpty($core)) { $core = $f.BaseName };" ^
     "        if ($core -match '^\d+$' -and $maxDigits -gt 0) { $core = $core.PadLeft($maxDigits, '0') };" ^
     "        $newName = $core + $f.Extension;" ^
     "        if ($newName -eq $f.Name) {" ^
     "            Add-Content -LiteralPath $env:temp_set -Value 'set /a skipped+=1';" ^
     "            Write-Host ('跳过，无需更改：\"' + $f.Name + '\"');" ^
     "        } else {" ^
     "            if (Test-Path -LiteralPath (Join-Path $f.DirectoryName $newName)) {" ^
     "                Add-Content -LiteralPath $env:temp_set -Value 'set /a name_conflict+=1';" ^
     "                Write-Host ('跳过，目标已存在：\"' + $f.Name + '\" -> \"' + $newName + '\"');" ^
     "            } else {" ^
     "                try {" ^
     "                    Rename-Item -LiteralPath $f.FullName -NewName $newName;" ^
     "                    Add-Content -LiteralPath $env:temp_set -Value 'set /a succeeded+=1';" ^
     "                    Write-Host ('重命名成功：\"' + $f.Name + '\" -> \"' + $newName + '\"');" ^
     "                } catch {" ^
     "                    Add-Content -LiteralPath $env:temp_set -Value 'set /a rename_failed+=1';" ^
     "                    Write-Host ('重命名失败：\"' + $f.Name + '\" -> \"' + $newName + '\"，报错信息：' + $_.Exception.Message);" ^
     "                };" ^
     "            };" ^
     "        };" ^
     "        Add-Content -LiteralPath $env:temp_set -Value 'set /a total+=1';" ^
     "    };" ^
     "}"
    echo.

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    echo 批量处理完成
    set /a "fail_total=name_conflict+rename_failed"
    echo 共计：!total! 个，成功：!succeeded! 个，失败：!fail_total! 个，跳过：!skipped! 个 & REM
    echo 其中，重命名成功 !succeeded! 个，目标文件已存在 !name_conflict! 个，重命名失败 !rename_failed! 个，跳过 !skipped! 个
)



echo.
pause
endlocal & endlocal & exit /b
