@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '关闭显示器' -ForegroundColor Green"
echo.



powershell -NoProfile -Command ^
    "$q = [char]34;" ^
    "$sig = '[DllImport(' + $q + 'user32.dll' + $q + ')]public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);';" ^
    "$type = Add-Type -MemberDefinition $sig -Name 'NativeMethods' -Namespace 'Win32' -PassThru;" ^
    "$r = [int]$type::SendMessage(-1, 0x0112, 0xF170, 2);" ^
    "if ($r -eq 0) { exit 1 }"
if !errorlevel! equ 0 (
    echo 关闭成功
) else (
    echo 关闭失败
)



echo.
timeout /t 3 /nobreak
endlocal & endlocal & exit /b
