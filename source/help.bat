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

at cd if rd
cls cmd del dir for rem ren set ver vol
call chcp comp copy date echo exit find goto mode mode path ping popd sort time tree type
assoc color erase ftype label mkdir pause print pushd rmdir shift start subst title xcopy
attrib chkdsk compact convert format prompt rename verify
chkntfs netstat recover replace
certutil endlocal diskcomp diskcopy ipconfig setlocal

) do (

echo echo %%i /? ^^^>"help\%%i.txt" 2^^^>^^^&1 1>>"tmp\help.tmp.bat" && ^
echo %%i /? ^>"help\%%i.txt" 2^>^&1 1>>"tmp\help.tmp.bat"

)
call "tmp\help.tmp.bat"
REM del /q "tmp\help.tmp.bat"
pause
::