@echo off
:: ����ע���·��
set "RegPath=HKEY_CURRENT_USER\Software\Microsoft\InputMethod\Settings\Common"

:: ��鵱ǰע������Ƿ����
reg query "%RegPath%" | findstr /i "TouchKeyboardHasEverShown"
reg query "%RegPath%" | findstr /i "TouchKeyboardHasEverShown" >nul 2>&1

if %errorlevel% equ 0 (
    echo �����޸� TouchKeyboardHasEverShown ��ֵΪ 0...
    reg add "%RegPath%" /v TouchKeyboardHasEverShown /t REG_DWORD /d 0 /f >nul
    echo �޸���ɡ�
) else (
    echo δ�ҵ� TouchKeyboardHasEverShown ע����������Ҫ�ֶ����·����
)

echo.
echo �������������ע����ǰ�û���ʹ������Ч��
pause
exit
