@echo off
setlocal enabledelayedexpansion
if "%~1"=="" (
    echo 请拖拽要删除的文件，到本文件图标上运行
    pause
    exit
)

:: UNC 路径格式：\\servername\sharename
:: 使用 UNC 路径不会检测路径中的保留字设备名称等，因此可以删除特殊文件或目录

set "target_file=%~1"
del /F /S /Q "\\?\%target_file%"

pause
exit