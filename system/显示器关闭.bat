@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '关闭显示器' -ForegroundColor Green"
echo.



powershell -NoProfile -WindowStyle Hidden -Command ^
    "$source = 'using System.Runtime.InteropServices;' +" ^
    "    'public static class ScreenPower {' +" ^
    "    '[DllImport(\"user32.dll\")] public static extern bool PostMessage(int hWnd, int Msg, int wParam, int lParam);' +" ^
    "    '}';" ^
    "Add-Type -TypeDefinition $source;" ^
    "[ScreenPower]::PostMessage(-1, 0x0112, 0xF170, 2) | Out-Null;"



echo.
timeout /t 3 /nobreak
endlocal & endlocal & exit /b
