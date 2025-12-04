@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

echo 开始处理当前目录下的 MP4 和 MOV 文件...
echo ========================================

for %%f in (*.mp4 *.mov) do (
    echo 正在处理: %%f
    ffprobe -v error -show_streams -show_format -print_format json "%%f" > "%%~nf%%~xf.json"
)

echo ========================================
echo 处理完成
echo 所有文件的详细信息，已导出为 JSON 格式，请查看 "原文件名.json" 的文件
echo ========================================

pause
exit
