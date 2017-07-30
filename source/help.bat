@echo off
setlocal enabledelayedexpansion
::
::  更新【help】文件夹中的所有的命令帮助信息
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