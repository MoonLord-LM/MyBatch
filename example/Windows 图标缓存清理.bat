@echo off

:: �ر� Windows ��ǳ��� Explorer
taskkill /f /im explorer.exe

:: �����ļ�ͼ�껺��
attrib -h -s -r "%userprofile%\AppData\Local\IconCache.db"
del /f "%userprofile%\AppData\Local\IconCache.db"

attrib /s /d -h -s -r "%userprofile%\AppData\Local\Microsoft\Windows\Explorer\*.db"
del /f "%userprofile%\AppData\Local\Microsoft\Windows\Explorer\*.db"

:: ����ϵͳ����ͼ�껺��
echo y | reg delete "HKEY_CLASSES_ROOT\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify" /v IconStreams
echo y | reg delete "HKEY_CLASSES_ROOT\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify" /v PastIconsStream

:: ���� Windows ��ǳ��� Explorer
start explorer

pause
exit
