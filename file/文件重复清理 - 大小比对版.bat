@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
set "param2=%~2" & set "param2_path=%~f2" & set "param2_dir=%~dp2" & set "param2_name=%~n2" & set "param2_ext=%~x2" & set "param2_name_ext=%~nx2"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '搜索和清理重复文件，将会清理第 1 个文件夹中的，已经在第 2 个文件夹中存在的文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入两个文件夹路径' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '也可以选中两个文件夹，拖拽到此脚本上，自动识别处理' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '当两次输入的文件夹路径相同时，则清理该文件夹自身的重复文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '文件名称一致 + 文件大小相等或更小，即判定为重复，不做内容比对，将重复文件删除到回收站' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



set "path1=!param1!"
set "path2=!param2!"

:input_path1
if "!path1!"=="" (
    echo 请输入要清理多余文件的文件夹
    set /p "path1="
    echo.
) else (
    echo 要清理多余文件的文件夹："!path1!"
    echo.
)
if "!path1!"=="" (
    echo 输入不能为空，请重新输入
    echo.
    goto input_path1
)
set "path1=!path1:"=!"
if "!path1:~-1!"=="\" set "path1=!path1:~0,-1!"
if not exist "!path1!\" (
    echo 错误：路径 1 不存在或不是文件夹："!path1!"，请重新输入
    echo.
    set "path1="
    goto input_path1
)

:input_path2
if "!path2!"=="" (
    echo 请输入作为参考的文件夹，仅用于文件比对
    set /p "path2="
    echo.
) else (
    echo 作为参考的文件夹，仅用于文件比对："!path2!"
    echo.
)
if "!path2!"=="" (
    echo 输入不能为空，请重新输入
    echo.
    goto input_path2
)
set "path2=!path2:"=!"
if "!path2:~-1!"=="\" set "path2=!path2:~0,-1!"
if not exist "!path2!\" (
    echo 错误：路径 2 不存在或不是文件夹："!path2!"，请重新输入
    echo.
    set "path2="
    goto input_path2
)



echo 清理文件夹："!path1!"
echo 参考文件夹："!path2!"
echo.
if /i "!path1!"=="!path2!" (
    echo 提示：两次输入的文件夹相同，将清理该文件夹自身的重复文件
    echo.
)



powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "Add-Type -AssemblyName Microsoft.VisualBasic;" ^
    "$p1=$env:path1;" ^
    "$p2=$env:path2;" ^
    "$files1=@(Get-ChildItem -LiteralPath $p1 -File -Recurse);" ^
    "$total=$files1.Count;" ^
    "$duplicate=0;" ^
    "$deleted=0;" ^
    "$failed=0;" ^
    "if ($p1 -eq $p2) {" ^
    "    $group=@{};" ^
    "    foreach ($f in $files1) {" ^
    "        $k=$f.Name+'|'+$f.Length;" ^
    "        if (-not $group.ContainsKey($k)) { $group[$k]=@() };" ^
    "        $group[$k]+=$f.FullName;" ^
    "    };" ^
    "    foreach ($k in $group.Keys) {" ^
    "        if ($group[$k].Count -ge 2) {" ^
    "            $group[$k] | Select-Object -Skip 1 | ForEach-Object {" ^
    "                $duplicate++;" ^
    "                Write-Host ('删除: '+$_);" ^
    "                try { [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($_, 'OnlyErrorDialogs', 'SendToRecycleBin'); $deleted++ } catch { $failed++ };" ^
    "            };" ^
    "        };" ^
    "    };" ^
    "} else {" ^
    "    $map=@{};" ^
    "    Get-ChildItem -LiteralPath $p2 -File -Recurse | ForEach-Object { $map[$_.Name+'|'+$_.Length]=$true };" ^
    "    foreach ($f in $files1) {" ^
    "        $k=$f.Name+'|'+$f.Length;" ^
    "        if ($map.ContainsKey($k)) {" ^
    "            $duplicate++;" ^
    "            Write-Host ('删除: '+$f.FullName);" ^
    "            try { [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($f.FullName, 'OnlyErrorDialogs', 'SendToRecycleBin'); $deleted++ } catch { $failed++ };" ^
    "        };" ^
    "    };" ^
    "}" ^
    "Write-Host '';" ^
    "Write-Host ('共计: '+$total+' 个文件，重复: '+$duplicate+' 个，删除成功: '+$deleted+' 个，删除失败: '+$failed+' 个');"



echo.
pause
endlocal & endlocal & exit /b
