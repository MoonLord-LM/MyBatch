@echo off
setlocal enabledelayedexpansion

REM //������ļ���׺
set "extension=*.mp4,*.wmv,*.mkv,*.avi"
echo.>"%windir%\Temp\file_batch_rename.bat"

for /r "%cd%" %%i in (%extension%) do (

    REM //�����ļ���
    set file_path=%%~i
    call :filepath_to_filename
    REM echo file_name : !file_name!

    REM //�滻�ַ���
    set "new_name=!file_name!"

    call :new_name_replace "[Thz.la]"
    call :new_name_replace "[ThZu.Cc]"
    call :new_name_replace "[44x.me]"
    call :new_name_replace "[HD]"

    call :new_name_replace "(S1)("
    call :new_name_replace "(������)("
    call :new_name_replace ")" " "

    call :new_name_replace "hjd2048.com-"
    call :new_name_replace "-javbo.net_"
    call :new_name_replace "-kan224.com"
    call :new_name_replace "-1080p"
    call :new_name_replace "-h264"

    call :new_name_replace "FHD." "."
    call :new_name_replace "hhb." "."
    call :new_name_replace "-C." "."
    call :new_name_replace "-high." "."
    call :new_name_replace "_HD." "."
    call :new_name_replace "_hd." "."
    call :new_name_replace "_postree." "."

    call :new_name_replace ".HD." "."
    call :new_name_replace ".HDx." "."

    REM echo new_name : !new_name!

    REM //�������ű�
    if not "!file_name!"=="!new_name!" (
        echo rename "!file_path!" "!new_name!" >>"%windir%\Temp\file_batch_rename.bat"
        echo !file_name! ---^> !new_name!
    )
)

echo.
echo type "%windir%\Temp\file_batch_rename.bat"
type "%windir%\Temp\file_batch_rename.bat"
echo.
echo ��ȷ���������ű����밴���������ִ��. . .
echo.
pause
call "%windir%\Temp\file_batch_rename.bat"
exit

:filepath_to_filename - "���������ļ�·��(file_path)ת��Ϊ�ļ���(file_name)"
    set /a tmp_offset=1
    :loop
    call set "tmp_mark=%%file_path:~-!tmp_offset!,1%%%"
    REM echo tmp_mark : !tmp_mark!
    if not "!tmp_mark!"=="" (
        if not "!tmp_mark!" == "\" (
            set /a tmp_offset+=1
            goto loop
        )
    )
    set /a tmp_offset-=1
    call set "file_name=%%file_path:~-!tmp_offset!%%%"
goto :eof

:new_name_replace - "���µ��ļ���(new_name)�е��ַ���(����1)�滻Ϊ�ַ���(����2)"
    if not "%~1"=="" (
        set "old_tag=%~1"
        set "new_tag=%~2"
        call set "new_name=%%new_name:!old_tag!=!new_tag!%%"
    )
goto :eof