@echo off
setlocal enabledelayedexpansion

:: �������������
:: https://github.com/FFmpeg/FFmpeg



:loop
echo �뽫Ҫ�������Ƶ�ļ���ק��������
set /p "url="

if "!url!"=="" (
    echo ���벻��Ϊ�գ�����������
    goto loop
)

:: ����һ���µ������д���
echo ���´����д���: !url!
set command=ffmpeg.exe ^
 -i !url! ^
 -c copy ^
 -movflags +faststart ^
 !url!.new.mp4
start "" cmd /c "%command%"
echo.

goto loop
