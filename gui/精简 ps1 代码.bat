@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '精简 ps1 代码文件，输出精简后的 .min.ps1 代码文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '使用 System.Management.Automation.Language.Parser 解析代码' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '移除多余的注释和空行' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入要精简的 ps1 文件路径；也可以拖拽 ps1 文件到此脚本上' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

set "input_file=!param1_path!"

:input_file
    if "!input_file!"=="" (
        echo 请输入要精简的 ps1 文件的路径
        set /p "input_file="
        if !errorlevel! neq 0 (
            echo 无输入，退出脚本
            echo.
            exit /b 1
        )
        echo.
    )
    if "!input_file!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_file
    )
    set "input_file=!input_file:"=!"
    if "!input_file!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_file
    )
    if "!input_file:~-1!"=="\" set "input_file=!input_file:~0,-1!"
    if not exist "!input_file!" (
        echo 错误：路径不存在："!input_file!"，请重新输入
        echo.
        set "input_file="
        goto input_file
    )
    if exist "!input_file!\" (
        echo 错误：不支持文件夹，请输入单个 ps1 文件
        echo.
        set "input_file="
        goto input_file
    )
    for %%i in ("!input_file!") do set "input_ext=%%~xi"
    if /i not "!input_ext!"==".ps1" (
        echo 错误：仅支持 ps1 文件，请输入 ps1 文件的路径
        echo.
        set "input_file="
        goto input_file
    )



echo 开始处理："!input_file!"
echo.

for %%i in ("!input_file!") do (
    setlocal disabledelayedexpansion
    set "base_name=%%~ni"
    set "file_dir=%%~dpi"
    setlocal enabledelayedexpansion

    for /f %%s in ('powershell -NoProfile -Command "try { ([System.IO.FileInfo]($env:input_file)).Length } catch { -1 }"') do set "input_size=%%s"
    echo 原始大小：!input_size! 字节
    echo.
    set "output_file=!file_dir!!base_name!.min.ps1"
    echo 输出精简版："!output_file!"
    echo.

    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8;" ^
        "$tokens = $null;" ^
        "$errors = $null;" ^
        "[void][System.Management.Automation.Language.Parser]::ParseFile($env:input_file, [ref] $tokens, [ref] $errors);" ^
        "" ^
        "if ($errors) {" ^
        "    $errors | ForEach-Object { Write-Host ('解析错误: ' + $_) };" ^
        "    exit 1" ^
        "};" ^
        "" ^
        "$newSource = [System.Text.StringBuilder]::new();" ^
        "$prev = $null;" ^
        "" ^
        "for ($i = 0; $i -lt $tokens.Count; $i++) {" ^
        "    $token = $tokens[$i];" ^
        "    $next = if ($i + 1 -lt $tokens.Count) { $tokens[$i + 1] } else { $null };" ^
        "" ^
        "    if ($token.Kind -eq 'Comment') {" ^
        "        continue;" ^
        "    };" ^
        "" ^
        "    if ($prev -and $prev.Kind -eq 'LCurly' -and $token.Kind -eq 'NewLine') {" ^
        "        continue;" ^
        "    };" ^
        "    if ($next -and $next.Kind -eq 'RCurly' -and $token.Kind -eq 'NewLine') {" ^
        "        continue;" ^
        "    };" ^
        "    if (-not $prev -and $token.Kind -eq 'NewLine') {" ^
        "        continue;" ^
        "    };" ^
        "    if ($prev -and $prev.Kind -eq 'NewLine' -and $token.Kind -eq 'NewLine') {" ^
        "        continue;" ^
        "    };" ^
        "" ^
        "    if ($token.Kind -eq 'NewLine') {" ^
        "        $newSource.Append($token.Text) | Out-Null;" ^
        "        $prev = $token;" ^
        "        continue;" ^
        "    };" ^
        "" ^
        "    if ($null -eq $next) {" ^
        "        $newSource.Append($token.Text) | Out-Null;" ^
        "        $prev = $token;" ^
        "        continue;" ^
        "    };" ^
        "" ^
        "    $padding = $next.Extent.StartOffset - $token.Extent.EndOffset;" ^
        "" ^
        "    if ($padding -eq 0) {" ^
        "        $newSource.Append($token.Text) | Out-Null;" ^
        "        $prev = $token;" ^
        "        continue;" ^
        "    }" ^
        "    else {" ^
        "        $newSource.Append($token.Text + ' ') | Out-Null;" ^
        "        $prev = @{ Kind = $token.Kind; Text = $token.Text + ' ' };" ^
        "        continue;" ^
        "    }" ^
        "};" ^
        "" ^
        "$txt = $newSource.ToString();" ^
        "if ($txt.Length -eq 0) { Write-Host '警告：精简后内容为空' };" ^
        "$txt | Out-File $env:output_file -Encoding UTF8;"
    if !errorlevel! neq 0 (
        echo 精简失败
    ) else (
        for /f %%s in ('powershell -NoProfile -Command "try { ([System.IO.FileInfo]($env:output_file)).Length } catch { -1 }"') do set "output_size=%%s"
        echo 精简成功，最终大小：!output_size! 字节
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
