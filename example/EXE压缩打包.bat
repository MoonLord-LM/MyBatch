@echo off
setlocal enabledelayedexpansion
echo EXE压缩打包（必须先安装7-Zip和WinRAR两款压缩软件，并且安装在默认的位置）
if "%~1"=="" (
    echo 请拖拽要压缩打包的EXE文件，到本文件图标上运行
    pause
    exit
)
if not exist "%~1" (
    echo EXE压缩打包失败，文件不存在："%~1"
    pause
    exit
)
set ExeFilePath="%~1"
echo 要压缩打包的文件路径：!ExeFilePath!

set SevenZipSelfExtract="C:\Program Files (x86)\7-Zip\7z.sfx"
set SevenZip="C:\Program Files (x86)\7-Zip\7z.exe"
if not exist !SevenZipSelfExtract! (
    echo 文件不存在：!SevenZipSelfExtract!
    set SevenZipSelfExtract="C:\Program Files\7-Zip\7z.sfx"
    set SevenZip="C:\Program Files\7-Zip\7z.exe"
    if not exist !SevenZipSelfExtract! (
        echo 文件不存在：!SevenZipSelfExtract!
        echo 7-Zip压缩软件未正确安装
        pause
        exit
    )
)
if not exist !SevenZip! (
    echo 文件不存在：!SevenZip!
    echo 7-Zip压缩软件未正确安装
    pause
    exit
)
echo 检测到7-Zip 压缩软件：!SevenZipSelfExtract!

set WinRAR="C:\Program Files\WinRAR\WinRAR.exe"
if not exist !WinRAR! (
    echo 文件不存在：!WinRAR!
    set WinRAR="C:\Program Files (x86)\WinRAR\WinRAR.exe"
    if not exist !WinRAR! (
        echo 文件不存在：!WinRAR!
        echo WinRAR压缩软件未正确安装
        pause
        exit
    )
)
echo 检测到WinRAR压缩软件：!WinRAR!

for /f "usebackq delims=" %%i in (`dir !ExeFilePath! /b /a-d`) do (
    set ExeFileName="%%~ni%%~xi"
    set ExeFileSize="%%~zi"
    set ExeFileDir="%%~di%%~pi"
    set ExeFilePack="%%~di%%~pi%%~ni打包%%~xi"
    echo 要压缩打包的文件名称：!ExeFileName!
    echo 要压缩打包的文件大小：!ExeFileSize!
    echo 要输出打包文件的目录：!ExeFileDir!
    echo 要输出打包文件的路径：!ExeFilePack!
)

echo 正在压缩文件……
set TmpFile="C:\Windows\Temp\EXE_Compress_Pack_Tmp_%random%.tmp"
!SevenZip! a -t7z -mx9 !TmpFile! !ExeFilePath!

echo 正在生成配置……
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

echo 正在打包文件……
copy /b !SevenZipSelfExtract! + !ExeConfig! + !TmpFile! !ExeFilePack!

echo 完成压缩打包，已输出到：!ExeFilePack!
pause
exit