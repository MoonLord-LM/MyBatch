@echo off
:: 设置注册表路径
set "RegPath=HKEY_CURRENT_USER\Software\Microsoft\InputMethod\Settings\Common"

:: 检查当前注册表项是否存在
reg query "%RegPath%" | findstr /i "TouchKeyboardHasEverShown"
reg query "%RegPath%" | findstr /i "TouchKeyboardHasEverShown" >nul 2>&1

if %errorlevel% equ 0 (
    echo 正在修改 TouchKeyboardHasEverShown 的值为 0...
    reg add "%RegPath%" /v TouchKeyboardHasEverShown /t REG_DWORD /d 0 /f >nul
    echo 修改完成。
) else (
    echo 未找到 TouchKeyboardHasEverShown 注册表项，可能需要手动检查路径。
)

echo.
echo 请重启计算机或注销当前用户以使更改生效。
pause
exit
