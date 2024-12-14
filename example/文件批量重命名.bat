@echo off
setlocal enabledelayedexpansion

REM //������ļ���׺
set "extension=*.mp4,*.wmv,*.mkv,*.avi,*.rar"
echo.>"%tmp%\file_batch_rename.bat"

for /r "%cd%" %%i in (%extension%) do (

    REM //�����ļ���
    set "file_path=%%~i"
    REM echo file_path : !file_path!

    call :filepath_to_filename
    REM echo file_name : !file_name!
    set "new_name=!file_name!"

    call :filepath_to_filedir
    REM echo file_dir : !file_dir!
    set "file_dir=!file_dir!"

    REM //�滻�ַ���

    call :new_name_replace "[4K]"
    call :new_name_replace "[2K]"
    call :new_name_replace "[1080P]"
    call :new_name_replace "[22y.me]"
    call :new_name_replace "[44x.me]"
    call :new_name_replace "[88q.me]"
    call :new_name_replace "[98t.tv]"
    call :new_name_replace "[99u.me]"
    call :new_name_replace "[AVC]"
    call :new_name_replace "[BD1080p]"
    call :new_name_replace "[fbzip.com]"
    call :new_name_replace "[GB]"
    call :new_name_replace "[GM-Team]"
    call :new_name_replace "[HD]"
    call :new_name_replace "[Thz.la]"
    call :new_name_replace "[ThZu.Cc]"
    call :new_name_replace "[����]"

    call :new_name_replace "��ses23.com��"

    call :new_name_replace "(S1)("
    call :new_name_replace "(SOD)("
    call :new_name_replace "(Madonna)("
    call :new_name_replace "(������)("
    call :new_name_replace ")" " "

    call :new_name_replace "0222223.com@"
    call :new_name_replace "0333332.com@"
    call :new_name_replace "1024�˹���-"
    call :new_name_replace "2048���� - big2048.com@"
    call :new_name_replace "HD-"
    call :new_name_replace "activehlj.com@"
    call :new_name_replace "kcf9.com@"
    call :new_name_replace "gg5.co@"
    call :new_name_replace "hdd600.com@"
    call :new_name_replace "hhd600.com@"
    call :new_name_replace "hhd800.com@"
    call :new_name_replace "hjd2048.com-"
    call :new_name_replace "hjd2048.com_"
    call :new_name_replace "jpsao.com-"
    call :new_name_replace "marketingjl.com@"
    call :new_name_replace "PP168.CC-"
    call :new_name_replace "play999.cc-"

    call :new_name_replace "-javbo.net_"
    call :new_name_replace "-kan224.com"
    call :new_name_replace "-1080p"
    call :new_name_replace "-h264"
    call :new_name_replace "-whole"
    call :new_name_replace "-whole1"
    call :new_name_replace "-WMV"
    call :new_name_replace "-www.52iv.net"
    call :new_name_replace "_1080P"
    call :new_name_replace "_HD"
    call :new_name_replace "_hd"
    call :new_name_replace "_hd1"
    call :new_name_replace "_RAW"
    call :new_name_replace "_uncensored"
    call :new_name_replace "-uncensored"
    call :new_name_replace "_UNCENSORED"
    call :new_name_replace "_LEAKED"
    call :new_name_replace "_NOWATERMARK"

    call :new_name_replace "FHD." "."
    call :new_name_replace "hhb." "."
    call :new_name_replace "-C." "."
    call :new_name_replace "-C_X1080X." "."
    call :new_name_replace "-C_60FPS_X1080X." "."
    call :new_name_replace "-C_GG5." "."
    call :new_name_replace "-C_GG5-C_GG5." "."
    call :new_name_replace "-high." "."
    call :new_name_replace "-����Ӱ��." "."
    call :new_name_replace "-4k." "."
    call :new_name_replace "_4K." "."
    call :new_name_replace "_2K." "."
    call :new_name_replace "_full." "."
    call :new_name_replace "_postree." "."
    call :new_name_replace "-nyap2p.com." "."
    call :new_name_replace "_.mkv" ".mkv"
    call :new_name_replace "_.mp4" ".mp4"

    call :new_name_replace ".4K." "."
    call :new_name_replace ".2K." "."
    call :new_name_replace ".1080p." "."
    call :new_name_replace ".1080PԼս������." "."
    call :new_name_replace ".720P." "."
    call :new_name_replace ".HD." "."
    call :new_name_replace ".HD1080p." "."
    call :new_name_replace ".HDx." "."
    call :new_name_replace ".RI." "."
    call :new_name_replace ".H265." "."
    call :new_name_replace ".WEBrip." "."
    call :new_name_replace ".��Ӣ��Ļ." "."
    call :new_name_replace ".HD����������ˮӡ[���µ�Ӱwww.66ys.tv]." "."

    call :new_name_replace "[Dou Luo Da Lu][Douro Mainland][2019]" "���޴�½"

    call :new_name_replace "["
    call :new_name_replace "]"

    REM call :new_name_replace ".." "."

    REM echo new_name : !new_name!

    REM //�������ű�

    if not "!file_name!"=="!new_name!" (
        if exist "!file_dir!\!new_name!" (
            echo !file_name! ---^> !new_name!  --  �ļ��������޷�������
        ) else (
            echo rename "!file_path!" "!new_name!" >>"%tmp%\file_batch_rename.bat"
            echo !file_name! ---^> !new_name!
        )
    )

)

echo.
echo type "%tmp%\file_batch_rename.bat"
type "%tmp%\file_batch_rename.bat"

set "file_path=%tmp%\file_batch_rename.bat"
call :filepath_to_filesize
rem echo file_size : !file_size!
set "file_size=!file_size!"

echo.
if "!file_size!" gtr "2" (
    echo ȷ��Ҫִ���������ű����밴���������. . .
) else (
    echo û����Ҫ���������ļ����밴���������. . .
)
echo.

pause
call "%tmp%\file_batch_rename.bat"
del /F /S /Q "%tmp%\file_batch_rename.bat"
exit

:filepath_to_filename_sample - "���������ļ�·��(file_path)ת��Ϊ�ļ���(file_name)"
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

:filepath_to_filename - "���������ļ�·��(file_path)ת��Ϊ�ļ���(file_name)"
    for %%i in ("%file_path%") do (
        set "file_name=%%~ni%%~xi"
    )
goto :eof

:filepath_to_filedir - "���������ļ�·��(file_path)ת��Ϊ�ļ���·��(file_dir)"
    for %%i in ("%file_path%") do (
        set "file_dir=%%~di%%~pi"
    )
goto :eof

:filepath_to_filesize - "���������ļ�·��(file_path)ת��Ϊ�ļ���С(file_size)"
    for %%i in ("%file_path%") do (
        set "file_size=%%~zi"
    )
goto :eof

:new_name_replace - "���µ��ļ���(new_name)�е��ַ���(����1)�滻Ϊ�ַ���(����2)"
    if not "%~1"=="" (
        set "old_tag=%~1"
        set "new_tag=%~2"
        REM echo old_tag : !old_tag!
        REM echo new_tag : !new_tag!
        call set "new_name=%%new_name:!old_tag!=!new_tag!%%"
    )
goto :eof
