@echo off

start "" "C:\Program Files\Common Files\microsoft shared\ink\TabTip.exe"
echo 已启动触摸键盘，临时解决问题



:: 检查注册表配置 TouchKeyboardHasEverShown
set "RegPath=HKEY_CURRENT_USER\Software\Microsoft\InputMethod\Settings\Common"
reg query "%RegPath%" | findstr /i "TouchKeyboardHasEverShown"
reg query "%RegPath%" | findstr /i "TouchKeyboardHasEverShown" >nul 2>&1

if %errorlevel% equ 0 (
    reg add "%RegPath%" /v TouchKeyboardHasEverShown /t REG_DWORD /d 0 /f >nul
    reg query "%RegPath%" | findstr /i "TouchKeyboardHasEverShown"
    echo 已重置 TouchKeyboardHasEverShown 注册表项，后续请不要打开触模键盘
) else (
    echo 未找到 TouchKeyboardHasEverShown 注册表项，无需重置
)



echo.
pause
exit
