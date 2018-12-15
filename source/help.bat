@echo off
setlocal enabledelayedexpansion
::
::  更新【help】文件夹中的所有的命令帮助信息
::
del /q "help\*"
::
mkdir "tmp\"
::
echo :: 临时脚本>"tmp\help.tmp.bat"
::
for %%i in (

at cd fc if rd
arp cls cmd del dir for ftp net rem ren set ver vol
call chcp clip comp copy date echo exit find goto mode mode path ping popd sort time tree type wmic
assoc cacls color erase fltmc ftype label mkdir pause print pushd rmdir shift start subst title xcopy
attrib change chkdsk choice cipher defrag doskey expand format fsutil getmac icacls makecab prompt rename verify
bcdboot bcdedit certreq chkntfs compact convert findstr netstat recover replace
certutil endlocal diskcomp diskcopy forfiles gpresult gpupdate hostname ipconfig setlocal tracert
eventcreate

) do (

echo echo %%i /? ^^^>"help\%%i.txt" 2^^^>^^^&1 1>>"tmp\help.tmp.bat" && ^
echo %%i /? ^>"help\%%i.txt" 2^>^&1 1>>"tmp\help.tmp.bat"

)
call "tmp\help.tmp.bat"
REM del /q "tmp\help.tmp.bat"
pause

:: TODO
:: 例如 ftp 的命令帮助无法输出到文件
:: 例如 change 需要多一个参数才能输出详细帮助
:: 例如 dism 需要权限提升才能运行