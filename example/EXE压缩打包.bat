@echo off
setlocal enabledelayedexpansion
echo EXEѹ������������Ȱ�װ7-Zip��WinRAR����ѹ����������Ұ�װ��Ĭ�ϵ�λ�ã�
if "%~1"=="" (
    echo ����קҪѹ�������EXE�ļ��������ļ�ͼ��������
    pause
    exit
)
if not exist "%~1" (
    echo EXEѹ�����ʧ�ܣ��ļ������ڣ�"%~1"
    pause
    exit
)
set ExeFilePath="%~1"
echo Ҫѹ��������ļ�·����!ExeFilePath!

set SevenZipSelfExtract="C:\Program Files (x86)\7-Zip\7z.sfx"
set SevenZip="C:\Program Files (x86)\7-Zip\7z.exe"
if not exist !SevenZipSelfExtract! (
    echo �ļ������ڣ�!SevenZipSelfExtract!
    set SevenZipSelfExtract="C:\Program Files\7-Zip\7z.sfx"
    set SevenZip="C:\Program Files\7-Zip\7z.exe"
    if not exist !SevenZipSelfExtract! (
        echo �ļ������ڣ�!SevenZipSelfExtract!
        echo 7-Zipѹ�����δ��ȷ��װ
        pause
        exit
    )
)
if not exist !SevenZip! (
    echo �ļ������ڣ�!SevenZip!
    echo 7-Zipѹ�����δ��ȷ��װ
    pause
    exit
)
echo ��⵽7-Zip ѹ�������!SevenZipSelfExtract!

set WinRAR="C:\Program Files\WinRAR\WinRAR.exe"
if not exist !WinRAR! (
    echo �ļ������ڣ�!WinRAR!
    set WinRAR="C:\Program Files (x86)\WinRAR\WinRAR.exe"
    if not exist !WinRAR! (
        echo �ļ������ڣ�!WinRAR!
        echo WinRARѹ�����δ��ȷ��װ
        pause
        exit
    )
)
echo ��⵽WinRARѹ�������!WinRAR!

for /f "usebackq delims=" %%i in (`dir !ExeFilePath! /b /a-d`) do (
    set ExeFileName="%%~ni%%~xi"
    set ExeFileSize="%%~zi"
    set ExeFileDir="%%~di%%~pi"
    set ExeFilePack="%%~di%%~pi%%~ni���%%~xi"
    echo Ҫѹ��������ļ����ƣ�!ExeFileName!
    echo Ҫѹ��������ļ���С��!ExeFileSize!
    echo Ҫ�������ļ���Ŀ¼��!ExeFileDir!
    echo Ҫ�������ļ���·����!ExeFilePack!
)

echo ����ѹ���ļ�����
set TmpFile="C:\Windows\Temp\EXE_Compress_Pack_Tmp_%random%.tmp"
!SevenZip! a -t7z -mx9 !TmpFile! !ExeFilePath!

echo �����������á���
::   ;!@Install@!UTF-8!
::   RunProgram="Setup.exe"
::   ;!@InstallEnd@!
setlocal disabledelayedexpansion
::
set ExeConfig="C:\Windows\Temp\EXE_Compress_Pack_Config_%random%.txt"
echo ;!@Install@!UTF-8!>%ExeConfig%
echo RunProgram=%ExeFileName%>>%ExeConfig%
echo ;!@InstallEnd@!>>%ExeConfig%
::
setlocal enabledelayedexpansion

echo ���ڴ���ļ�����
copy /b !SevenZipSelfExtract! + !ExeConfig! + !TmpFile! !ExeFilePack!

echo ���ѹ����������������!ExeFilePack!
pause
exit