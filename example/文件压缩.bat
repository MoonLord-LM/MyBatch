@echo off
setlocal enabledelayedexpansion
if "%~1"=="" (
    echo ����קҪѹ�����ļ����ļ��У������ļ�ͼ��������
    pause
    exit
)

:: https://ss64.com/nt/makecab-directives.html
:: https://msdn.microsoft.com/en-us/library/bb417343.aspx
echo ����ϵͳ�Դ��� makecab.exe ѹ���ļ�

set tmp_file="%windir%\Temp\makecab_directives_%random%.reg"
 >"%tmp_file%" echo ;
>>"%tmp_file%" echo .Option Explicit
>>"%tmp_file%" echo .set Cabinet=ON
>>"%tmp_file%" echo .set CabinetFileCountThreshold=0
>>"%tmp_file%" echo .Set Compress=ON
:: ѹ�����ͣ�MSZIP��LZX
>>"%tmp_file%" echo .set CompressionType=LZX
:: ���� LZX ���͵�ѹ���ȼ���15-21
>>"%tmp_file%" echo .set CompressionMemory=21
>>"%tmp_file%" echo .set FolderFileCountThreshold=0
>>"%tmp_file%" echo .set FolderSizeThreshold=0
>>"%tmp_file%" echo .set InfFileName=NUL
>>"%tmp_file%" echo .set MaxCabinetSize=0
>>"%tmp_file%" echo .set MaxDiskFileCount=0
>>"%tmp_file%" echo .set MaxDiskSize=0
>>"%tmp_file%" echo .set MaxErrors=1
>>"%tmp_file%" echo .set RptFileName=NUL
>>"%tmp_file%" echo .set UniqueFiles=ON
>>"%tmp_file%" echo ;

set "target_path=%~1"
for %%i in ("%target_path%") do (

    set "target_parent_path=%%~dpi"
    >>"%tmp_file%" echo .set DiskDirectoryTemplate="!target_parent_path!"
    echo ����λ�ã�!target_parent_path!

    set "target_attribute=%%~ai"
    >>"%tmp_file%" echo ;
    echo Ŀ�����ԣ�!target_attribute!

    if "!target_attribute:~0,1!"=="d" (
        set "target_name=%%~ni%%~xi"
    ) else (
        set "target_name=%%~ni"
    )
    >>"%tmp_file%" echo .set CabinetNameTemplate="!target_name!.zip"
    echo �������ƣ�!target_name!

    if "!target_attribute:~0,1!"=="d" (
        echo ѹ���ļ��У�"%target_path%"
        call :get_filepath_length !target_parent_path!

        for /f "delims=" %%j in ('dir /o:n /s /b "%target_path%"') do (
            echo �����ļ���"%%j"
            set "tmp_name=%%j"
            set "tmp_parent_path=%%~dpj"
            set "tmp_attribute=%%~aj"
            if "!tmp_attribute:~0,1!"=="-" (
                call >>"%tmp_file%" echo .set DestinationDir="%%tmp_parent_path:~!filepath_length!%%"
                >>"%tmp_file%" echo "!tmp_name!"
            )
        )

    ) else (
        echo ѹ���ļ���"%target_path%"
        >>"%tmp_file%" echo "%target_path%"
    )
)

makecab /F "%tmp_file%" /V3
del /F /S /Q "%tmp_file%"

cd "!target_parent_path!"
copy /B "%windir%\System32\extrac32.exe" + "!target_parent_path!\!target_name!.zip" "!target_parent_path!\!target_name!.exe"

pause
exit

:get_filepath_length - "��ȡָ��·�����ַ�������(filepath)"
    if not "%~1"=="" (
        set "filepath=%~1"
        set "MAX_PATH_LENGTH=260"
        set /a filepath_length=0
        for /l %%i in (0, 1, !MAX_PATH_LENGTH!) do (
            if "!filepath:~%%i,1!"=="" (
                set /a filepath_length=%%i
                goto :eof
            )
        )
    )
goto :eof