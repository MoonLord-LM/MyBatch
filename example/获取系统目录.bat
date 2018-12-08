@echo off

for /f "usebackq tokens=3,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Desktop"`) ^
do set "desktop_dir=%%i"
echo ����·����%desktop_dir%

for /f "usebackq tokens=3,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Personal"`) ^
do set "personal_dir=%%i"
echo �ĵ�·����%personal_dir%

for /f "usebackq tokens=4,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Pictures"`) ^
do set "picture_dir=%%i"
echo ͼƬ·����%picture_dir%

for /f "usebackq tokens=4,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Music"`) ^
do set "music_dir=%%i"
echo ����·����%music_dir%

for /f "usebackq tokens=4,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Video"`) ^
do set "video_dir=%%i"
echo ��Ƶ·����%video_dir%

for /f "usebackq tokens=3,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "{374DE290-123F-4565-9164-39C4925E467B}"`) ^
do set "download_dir=%%i"
echo ����·����%download_dir%

for /f "usebackq tokens=4,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Start Menu"`) ^
do set "start_nemu_dir=%%i %%j"
echo ��ʼ�˵�·����%start_nemu_dir%

for /f "usebackq tokens=3,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Cookies"`) ^
do set "cookies_dir=%%i"
echo Cookies ·����%cookies_dir%

for /f "usebackq tokens=3,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Fonts"`) ^
do set "fonts_dir=%%i"
echo Font ·����%fonts_dir%

for /f "usebackq tokens=3,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Recent"`) ^
do set "recent_dir=%%i"
echo Recent ·����%recent_dir%

for /f "usebackq tokens=3,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "History"`) ^
do set "history_dir=%%i"
echo History ·����%history_dir%

for /f "usebackq tokens=3,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "AppData"`) ^
do set "appdata_roaming_dir=%%i"
echo AppData Roaming ·����%appdata_roaming_dir%

for /f "usebackq tokens=4,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Local AppData"`) ^
do set "appdata_local_dir=%%i"
echo AppData Local ·����%appdata_local_dir%

for /f "usebackq tokens=3,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "{A520A1A4-1780-4FF6-BD18-167343C5AF16}"`) ^
do set "appdata_locallow_dir=%%i"
echo AppData LocalLow ·����%appdata_locallow_dir%

pause
exit