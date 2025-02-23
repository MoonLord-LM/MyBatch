@echo off

:: MoonLord 2023.07.29  
:: 初始化本地代码仓库  



call :download_moonlord_project "MyBatch"
call :download_moonlord_project "MyJava"
call :download_moonlord_project "MyPages"

pause
exit



:download_moonlord_project
  set "project_url=https://github.com/MoonLord-LM"
  set "project_name=%~1"
  echo download_moonlord_project: "%project_url%/%project_name%.git"
  git clone --progress --branch "master" -v "%project_url%/%project_name%.git" "%cd%\%project_name%-master"
goto :eof
