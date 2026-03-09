@echo off
chcp 65001 >nul
setlocal

:: 鑾峰彇鎷栧姩鍒? bat 鏂囦欢涓婄殑杈撳叆鏂囦欢璺?緞
set "input_file=%~1"

:: 妫€鏌ユ槸鍚︽彁渚涗簡杈撳叆鏂囦欢
if "%input_file%"=="" (
    echo 璇峰皢瑕佺紪鐮佺殑鏂囦欢鎷栧姩鍒版?鑴氭湰涓?
    pause
    exit /b
)

:: 璁剧疆杈撳嚭鏂囦欢璺?緞锛岄粯璁や负鍘熸枃浠跺悕鍔犱笂 .txt 鍚庣紑
set "output_file=%input_file%.txt"

:: 浣跨敤 certutil 杩涜? Base64 缂栫爜
certutil -encode "%input_file%" "%output_file%" >nul