@echo off
setlocal enabledelayedexpansion

:: �������������
:: https://github.com/yt-dlp/yt-dlp
:: https://github.com/FFmpeg/FFmpeg
:: https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc


yt-dlp --update
yt-dlp --version

:loop
echo ������ Bilibili ��Ƶ����
set /p "url="

if "!url!"=="" (
    echo ���벻��Ϊ�գ�����������
    goto loop
)

:: ����Ƿ�����Ч��URL
echo "!url!" | findstr /C:"https://www.bilibili.com/" >nul
if !errorlevel! == 1 (
    echo ����Ĳ�����Ч�� Bilibili ���ӣ�����������
    goto loop
)

:: ɾ�� ? �ͺ��������
if "!url!" neq "!url:?=!" (
    for /f "tokens=1 delims=?" %%i in ("!url!") do set "url=%%i"
)

:: ��鲢ȷ�� /video ���������� / ������
echo "!url!" | findstr /C:"https://www.bilibili.com/video/" >nul
if !errorlevel! == 0 (
    if "!url:~-1!" neq "/" (
        set "url=!url!/"
    )
)

:: ����һ���µ������д���ִ����������
echo ���´���������: "!url!"
set command1=yt-dlp.exe ^
 --cookies ""www.bilibili.com_cookies.txt"" ^
 --list-formats ^
 --verbose ^
 ""!url!""
set command2=yt-dlp.exe ^
 --cookies ""www.bilibili.com_cookies.txt"" ^
 --concurrent-fragments 20 ^
 -f ""bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"" ^
 --merge-output-format mp4 ^
 --embed-thumbnail ^
 --embed-metadata ^
 --embed-chapters ^
 --embed-info-json ^
 --verbose ^
 ""!url!""
start "" cmd /c "%command1% & %command2%"
echo.

goto loop
