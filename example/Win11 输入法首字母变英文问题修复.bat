@echo off

start "" "C:\Program Files\Common Files\microsoft shared\ink\TabTip.exe"
echo �������������̣���ʱ�������



:: ���ע������� TouchKeyboardHasEverShown
set "RegPath=HKEY_CURRENT_USER\Software\Microsoft\InputMethod\Settings\Common"
reg query "%RegPath%" | findstr /i "TouchKeyboardHasEverShown"
reg query "%RegPath%" | findstr /i "TouchKeyboardHasEverShown" >nul 2>&1

if %errorlevel% equ 0 (
    reg add "%RegPath%" /v TouchKeyboardHasEverShown /t REG_DWORD /d 0 /f >nul
    reg query "%RegPath%" | findstr /i "TouchKeyboardHasEverShown"
    echo ������ TouchKeyboardHasEverShown ע���������벻Ҫ�򿪴�ģ����
) else (
    echo δ�ҵ� TouchKeyboardHasEverShown ע������������
)



echo.
pause
exit
