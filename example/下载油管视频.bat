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

:: ɾ�� & �ͺ��������
if "!url!" neq "!url:&=!" (
    for /f "tokens=1 delims=&" %%i in ("!url!") do set "url=%%i"
)

:: ����һ���µ������д���ִ����������
echo ���´���������: "!url!"
set command=yt-dlp.exe ^
 --cookies ""cookies.txt"" ^
 --concurrent-fragments 100 ^
 -f ""bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"" ^
 --merge-output-format mp4 ^
 --embed-subs ^
 --embed-thumbnail ^
 --embed-metadata ^
 --embed-chapters ^
 --embed-info-json ^
 ""!url!""
start "" cmd /c "%command%"
echo.

goto loop
