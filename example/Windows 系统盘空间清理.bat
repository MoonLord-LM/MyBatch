@echo off


:: Windows 系统休眠保存文件
powercfg -h off


:: Intel Extreme Tuning Utility 日志文件
echo del /F /S /Q "C:\ProgramData\Intel\Intel Extreme Tuning Utility\Logs\*"
del /F /S /Q "C:\ProgramData\Intel\Intel Extreme Tuning Utility\Logs\*" 1>nul 2>nul


: JxBrowser 浏览器控件 dmp 文件
echo del /F /S /Q "%USERPROFILE%\AppData\Local\JxBrowser\*.dmp"
del /F /S /Q "%USERPROFILE%\AppData\Local\JxBrowser\*.dmp" 1>nul 2>nul


: Adobe 媒体缓存文件
echo del /F /S /Q "%USERPROFILE%\AppData\Roaming\Adobe\Common\Media Cache Files\*"
del /F /S /Q "%USERPROFILE%\AppData\Roaming\Adobe\Common\Media Cache Files\*" 1>nul 2>nul


: Squirrel 更新临时文件
for /d %%i in (%USERPROFILE%\AppData\Local\SquirrelTemp\*) do (
    echo rmdir /S /Q ^"%%i^"
    rmdir /S /Q "%%i" 1>nul 2>nul
)
echo del /F /S /Q "%USERPROFILE%\AppData\Local\SquirrelTemp\*"
del /F /S /Q "%USERPROFILE%\AppData\Local\SquirrelTemp\*" 1>nul 2>nul


: JetBrains IntelliJ Idea 更新临时文件
for /d %%i in (%USERPROFILE%\AppData\Local\JetBrains\*) do (
    echo rmdir /S /Q ^"%%i\tmp\patch-update\^"
    rmdir /S /Q "%%i\tmp\patch-update\" 1>nul 2>nul
    echo del /F /S /Q ^"%%i\tmp\*^"
    del /F /S /Q "%%i\tmp\*" 1>nul 2>nul
)


:: Unity Web Player 浏览器插件缓存
for /d %%i in (%USERPROFILE%\AppData\LocalLow\Unity\WebPlayer\Cache\*) do (
    echo rmdir /S /Q ^"%%i^"
    rmdir /S /Q "%%i" 1>nul 2>nul
)
echo del /F /S /Q "%USERPROFILE%\AppData\LocalLow\Unity\WebPlayer\Cache\*"
del /F /S /Q "%USERPROFILE%\AppData\LocalLow\Unity\WebPlayer\Cache\*" 1>nul 2>nul


: pause
exit
