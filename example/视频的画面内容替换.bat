@echo off
setlocal enabledelayedexpansion
:: ffmpeg -i 1.mp4 -i 2.mp4 -map 1:v:0 -map 0:a -map 0:2 -map_metadata 0 -c copy -disposition:v:1 attached_pic output.mp4

echo.
echo ������ԭʼ��Ƶ�ļ�·�����������桢��Ƶ�������ȣ�
set /p "video1="

if not exist "!video1!" (
    echo �ļ� "!video1!" �����ڣ�����·�������ԡ�
    pause
    exit /b
)

echo.
echo �����������滻��Ƶ�����ļ�·�����������������Ƶ��
set /p "video2="

if not exist "!video2!" (
    echo �ļ� "!video2!" �����ڣ�����·�������ԡ�
    pause
    exit /b
)

echo.
echo ����ִ����Ƶ�ϳ�������ڶ�����Ƶ����Ƶ�������滻����һ����Ƶ��...

echo ffmpeg -i !video1! -i !video2! -map 1:v:0 -map 0:a -map 0:2 -map_metadata 0 -c copy -disposition:v:1 attached_pic output.mp4
ffmpeg -i !video1! -i !video2! -map 1:v:0 -map 0:a -map 0:2 -map_metadata 0 -c copy -disposition:v:1 attached_pic output.mp4

echo.
echo �ϳ���ɣ������ļ�Ϊ output.mp4
pause
exit
