@echo off
echo ʹ�� FFmpeg����ʱ���ȡ��Ƶ����ʼʱ����� -ss������ʱ����� -to

if "%~1"=="" (
    echo ����ק�ļ��������ļ�ͼ��������
    pause
    exit
)

set "ffmpeg=S:\Common\DouyuPCClient\Client\8.5.2.2\ffmpeg.exe"
echo "%ffmpeg%" -i "%~1" -c copy -ss "03:29:22" -to "03:30:42" "%~1.clip.mp4"

"%ffmpeg%" -i "%~1" -c copy -ss "03:29:22" -to "03:30:42" "%~1.clip.mp4"

echo ��ȡ��ɣ���鿴���ɵ� mp4 �ļ�
pause
exit
