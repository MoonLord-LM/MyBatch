@echo off
set "python_exe=D:\Software\Python38\python.exe"
"%python_exe%" -m http.server --help
"%python_exe%" -m http.server 8080
pause
exit
