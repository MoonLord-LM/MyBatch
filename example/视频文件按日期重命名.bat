@echo off

:: ����Ƶ�ļ��Ĵ���������ӵ��ļ�����ͷ����������

:: ��������� ffprobe.exe
:: https://github.com/FFmpeg/FFmpeg
:: ffprobe.exe -v quiet -select_streams v -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 + �ļ���



for %%f in (*.mp4) do (
    :: ������ disabledelayedexpansion ��Χ�ڣ����ܻ�ȡ�����İ��� ^ �� ! ���ŵ��ļ���
    set "filename=%%f"
    setlocal enabledelayedexpansion
    echo �ļ��� "!filename!"

    :: ʹ�� ffprobe ��ȡ date ��ǩ
    for /f "delims=" %%x in ('ffprobe.exe -v quiet -select_streams v -show_entries format_tags^=date -of default^=noprint_wrappers^=1:nokey^=1 "!filename!" 2^>^&1') do (
        echo ����ʱ�� "%%x"
        set "filedate=%%x"
    )

    :: ����Ƿ��ȡ��������
    if "!filedate!" == "" (
        echo δ�ҵ�������Ϣ "!filename!"
    ) else (
        :: ����ļ��������ڿ�ͷ��������������
        echo !filename! | findstr /b /c:!filedate! >nul
        if !errorlevel! == 1 (
            echo �ļ����޸�Ϊ "!filedate! !filename!"
            ren "!filename!" "!filedate! !filename!"
        ) else (
            echo �ļ����Ѱ�������
        )
    )

    endlocal
    echo.
)



pause
exit
