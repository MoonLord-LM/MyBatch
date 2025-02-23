@echo off
setlocal

:: 获取拖动�? bat 文件上的输入文件�?��
set "input_file=%~1"

:: 检查是否提供了输入文件
if "%input_file%"=="" (
    echo 请将要编码的文件拖动到�?脚本�?
    pause
    exit /b
)

:: 设置输出文件�?��，默认为原文件名加上 .txt 后缀
set "output_file=%input_file%.txt"

:: 使用 certutil 进�? Base64 编码
certutil -encode "%input_file%" "%output_file%" >nul
