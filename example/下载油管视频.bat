@echo off
setlocal enabledelayedexpansion

:: �������������
:: https://github.com/yt-dlp/yt-dlp
:: https://github.com/FFmpeg/FFmpeg



:loop
echo ������ YouTube ��Ƶ����
set /p "url="

if "!url!"=="" (
    echo ���벻��Ϊ�գ�����������
    goto loop
)

:: ����Ƿ�����Ч��URL
echo "!url!" | findstr /C:"https://www.youtube.com/watch?v=" >nul
if !errorlevel! == 1 (
    echo ����Ĳ�����Ч�� YouTube ���ӣ�����������
    goto loop
)

:: ����һ���µ������д���ִ����������
echo ���´���������: "!url!"
start "" cmd /c "yt-dlp.exe -f ""bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"" --merge-output-format mp4 --embed-thumbnail --add-metadata ""!url!"""
echo.

goto loop
