@echo off
echo ʹ�� FFmpeg��ת����Ƶ��ʽ���� flv �� mp4

if "%~1"=="" (
    echo ����ק�ļ��������ļ�ͼ��������
    pause
    exit
)

set "ffmpeg=S:\Common\DouyuPCClient\Client\8.5.3.1\ffmpeg.exe"
echo "%ffmpeg%" -i "%~1" -c copy "%~1.mp4"

"%ffmpeg%" -i "%~1" -c copy "%~1.mp4"

echo ת����ɣ���鿴���ɵ� mp4 �ļ�
pause
exit
