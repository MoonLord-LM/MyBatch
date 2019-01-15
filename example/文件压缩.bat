@echo off
setlocal enabledelayedexpansion
if "%~1"=="" (
    echo 请拖拽要压缩的文件或文件夹，到本文件图标上运行
    pause
    exit
)

:: https://ss64.com/nt/makecab-directives.html
:: https://msdn.microsoft.com/en-us/library/bb417343.aspx
echo 调用系统自带的 makecab.exe 压缩文件

set tmp_file="%windir%\Temp\makecab_directives_%random%.reg"
 >"%tmp_file%" echo ;
>>"%tmp_file%" echo .Option Explicit
>>"%tmp_file%" echo .set Cabinet=ON
>>"%tmp_file%" echo .set CabinetFileCountThreshold=0
>>"%tmp_file%" echo .Set Compress=ON
:: 压缩类型：MSZIP、LZX
>>"%tmp_file%" echo .set CompressionType=LZX
:: 用于 LZX 类型的压缩等级：15-21
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
    echo 保存位置：!target_parent_path!

    set "target_attribute=%%~ai"
    >>"%tmp_file%" echo ;
    echo 目标属性：!target_attribute!

    if "!target_attribute:~0,1!"=="d" (
        set "target_name=%%~ni%%~xi"
    ) else (
        set "target_name=%%~ni"
    )
    >>"%tmp_file%" echo .set CabinetNameTemplate="!target_name!.zip"
    echo 保存名称：!target_name!

    if "!target_attribute:~0,1!"=="d" (
        echo 压缩文件夹："%target_path%"
        call :get_filepath_length !target_parent_path!

        for /f "delims=" %%j in ('dir /o:n /s /b "%target_path%"') do (
            echo 处理文件："%%j"
            set "tmp_name=%%j"
            set "tmp_parent_path=%%~dpj"
            set "tmp_attribute=%%~aj"
            if "!tmp_attribute:~0,1!"=="-" (
                call >>"%tmp_file%" echo .set DestinationDir="%%tmp_parent_path:~!filepath_length!%%"
                >>"%tmp_file%" echo "!tmp_name!"
            )
        )

    ) else (
        echo 压缩文件："%target_path%"
        >>"%tmp_file%" echo "%target_path%"
    )
)

makecab /F "%tmp_file%" /V3
del /F /S /Q "%tmp_file%"

cd "!target_parent_path!"
copy /B "%windir%\System32\extrac32.exe" + "!target_parent_path!\!target_name!.zip" "!target_parent_path!\!target_name!.exe"

pause
exit

:get_filepath_length - "获取指定路径的字符串长度(filepath)"
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