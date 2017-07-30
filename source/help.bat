@echo off
setlocal enabledelayedexpansion
::
::  Output the help information in the ��help�� folder
::
del /q "help\*"
::
for %%i in (

del dir for set
call copy goto tree
shift
setlocal

) do (

echo %%i /? ^>"help\%%i.txt" && ^
echo %%i /? ^>"help\%%i.txt" >tmp.bat && ^
call tmp.bat
del /q "tmp.*"

)
::
