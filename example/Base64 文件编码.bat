@echo off
setlocal

:: 获取拖动到 bat 文件上的输入文件路径
set "input_file=%~1"

:: 检查是否提供了输入文件
if "%input_file%"=="" (
    echo 请将要编码的文件拖动到此脚本上
    pause
    exit /b
)

:: 设置输出文件路径，默认为原文件名加上 .txt 后缀
set "output_file=%input_file%.txt"

:: 使用 certutil 进行 Base64 编码
certutil -encode "%input_file%" "%output_file%" >nul
