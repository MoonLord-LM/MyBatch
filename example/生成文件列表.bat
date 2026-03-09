@echo off
chcp 65001 >nul



tree /f > "%~0.txt"



pause
exit
