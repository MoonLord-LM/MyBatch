@echo off
setlocal enabledelayedexpansion
::
::  ���¡�help���ļ����е����е����������Ϣ
::
del /q "help\*"
::
mkdir "tmp\"
::
echo :: ��ʱ�ű�>"tmp\help.tmp.bat"
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
:: ���� ftp ����������޷�������ļ�
:: ���� change ��Ҫ��һ���������������ϸ����
:: ���� dism ��ҪȨ��������������