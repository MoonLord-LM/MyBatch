@echo off

:: ��������� ffprobe.exe
:: https://github.com/FFmpeg/FFmpeg
:: ffprobe.exe -v quiet -select_streams v -show_entries format_tags=comment -of default=noprint_wrappers=1:nokey=1 + �ļ���



:: ��������� comment.txt �ļ�
>"comment.txt" echo.

for %%f in (*.mp4) do (
    :: ������ disabledelayedexpansion ��Χ�ڣ����ܻ�ȡ�����İ��� ^ �� ! ���ŵ��ļ���
    set "filename=%%f"
    setlocal enabledelayedexpansion
    echo �ļ��� "!filename!"

    :: ʹ�� ffprobe ��ȡ comment ��ǩ
    for /f "delims=" %%x in ('ffprobe.exe -v quiet -select_streams v -show_entries format_tags^=comment -of default^=noprint_wrappers^=1:nokey^=1 "!filename!" 2^>^&1') do (
        echo ��ע "%%x"
        echo %%x>>"comment.txt"
    )

    endlocal
    echo.
)



pause
exit