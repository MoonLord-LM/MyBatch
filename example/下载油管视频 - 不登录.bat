@echo off
setlocal enabledelayedexpansion

:: ֧��������Ƶ���ӵ������أ��������������Ƶ���ӵ� txt �ļ�·����������
:: �������������
:: https://github.com/yt-dlp/yt-dlp
:: https://github.com/FFmpeg/FFmpeg



call :init
goto :main_loop


:init
    yt-dlp --update
    yt-dlp --rm-cache-dir
exit /b


:download_video
    set "url=%~1"
    
    :: ɾ�� & �ͺ��������
    if "!url!" neq "!url:&=!" (
        for /f "tokens=1 delims=&" %%i in ("!url!") do set "url=%%i"
    )

    echo ���´���������: "!url!"
    set command1=yt-dlp.exe ^
     --list-formats ^
     --verbose ^
     "!url!"
    set command2=yt-dlp.exe ^
     --concurrent-fragments 20 ^
     -f ""bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"" ^
     --merge-output-format mp4 ^
     --embed-subs ^
     --embed-thumbnail ^
     --embed-metadata ^
     --embed-chapters ^
     --embed-info-json ^
     --verbose ^
     "!url!"
    start "" cmd /c "%command1% & %command2%"
    timeout /t 30
exit /b


:download_video_list
    set "file_path=%~1"

    :: ������������������Ч��������
    set /a total_count=0
    for /f "usebackq tokens=*" %%a in ("!file_path!") do (
        set "line=%%a"
        :: ɾ��ǰ��հ�
        set "line=!line: =!"
        if not "!line!"=="" (
            set /a total_count+=1
        )
    )

    :: ��ʼ����ǰ����
    set /a current_count=0
    for /f "usebackq tokens=*" %%a in ("!file_path!") do (
        set "line=%%a"
        :: ɾ��ǰ��հ�
        set "line=!line: =!"
        if not "!line!"=="" (
            set /a current_count+=1
            echo ���ڴ���� !current_count!/%total_count% ������...
            call :download_video "!line!"
        )
    )
exit /b


:main_loop
    echo ������ YouTube ��Ƶ���ӻ������Ƶ���ӵ� txt �ļ�·��
    set /p "input="

    if "!input!"=="" (
        echo ���벻��Ϊ�գ�����������
        goto main_loop
    )

    :: ɾ�����������
    set "input=!input:"=!"

    :: ����Ƿ�����Ч���ļ�·��
    if exist "!input!" (
        call :download_video_list "!input!"
    ) else (
        :: ��������ļ�·��������ΪURL
        echo "!input!" | findstr /C:"https://www.youtube.com/watch?v=" >nul
        if !errorlevel! == 1 (
            echo ����Ĳ�����Ч�� YouTube ���ӣ�����������
            goto main_loop
        )
        call :download_video "!input!"
    )
goto main_loop


