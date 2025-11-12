@echo off
setlocal enabledelayedexpansion

:: 依赖的软件如下
:: https://github.com/FFmpeg/FFmpeg



echo 本脚本用于将封面文件 00.jpg 以及视频文件 01.mp4、02.mp4... 最多到 200.mp4 合并为 final.mp4 文件

echo 正在生成文件列表...
echo. > file_list.txt
for /l %%i in (1,1,200) do (
    set "num=%%i"
    if exist "%%i.mp4" (
        echo file '%%i.mp4' >> file_list.txt
    ) else (
        if exist "0%%i.mp4" (
            echo file '0%%i.mp4' >> file_list.txt
        ) else (
            if exist "00%%i.mp4" (
                echo file '00%%i.mp4' >> file_list.txt
            )
        )
    )
)

echo 正在合并视频...
ffmpeg -f concat -safe 0 -i "file_list.txt" -c copy "merged.mp4"

if exist "merged.mp4" (
    :: 查找封面文件，优先使用 PNG 格式
    set "cover_file="
    if exist "0.png" (
        set "cover_file=0.png"
    ) else if exist "00.png" (
        set "cover_file=00.png"
    ) else if exist "000.png" (
        set "cover_file=000.png"
    ) else if exist "0.jpg" (
        set "cover_file=0.jpg"
    ) else if exist "00.jpg" (
        set "cover_file=00.jpg"
    ) else if exist "000.jpg" (
        set "cover_file=000.jpg"
    )
    if defined cover_file (
        echo 正在添加封面 [!cover_file!]...
        ffmpeg -i "merged.mp4" -i "!cover_file!" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "final.mp4"
    ) else (
        echo 封面文件（0.png/0.jpg 等）不存在，不添加封面
        move /Y "merged.mp4" "final.mp4"
    )
    echo 合并完成，已生成 final.mp4 文件
) else (
    echo 合并失败，请检查报错信息
)

if exist "merged.mp4" ( del "merged.mp4" )
if exist "file_list.txt" ( del "file_list.txt" )

pause
exit
