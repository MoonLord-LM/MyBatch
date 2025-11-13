@echo off
setlocal enabledelayedexpansion

:: 依赖的软件如下
:: https://github.com/FFmpeg/FFmpeg



echo 本脚本用于将封面文件 00.jpg 以及视频文件 01.mp4、02.mp4... 最多到 200.mp4 拼接合并为 final.mp4 文件
echo 会尽可能保留原始视频质量，必要的时候进行转码
echo 转码过程使用单线程运行，防止占用过多 CPU 资源

echo.
echo 正在生成文件列表...
set "file_count=0"
set "first_file_fps="
set "fps_consistent=1"
echo. > file_list.txt
for /l %%i in (1,1,200) do (
    for %%f in ("%%i.mp4" "0%%i.mp4" "00%%i.mp4") do (
        if exist %%f (
            echo file %%~f >> file_list.txt
            set /a "file_count+=1"
            for /f "delims=" %%r in ('ffprobe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of csv^=p^=0 %%f 2^>^&1') do (
                set "current_fps=%%r"
                echo 第 !file_count! 个视频帧率: !current_fps!
            )
            if not defined first_file_fps (
                set "first_file_fps=!current_fps!"
            ) else (
                if not "!current_fps!"=="!first_file_fps!" (
                    echo 警告：文件 %%~f 的帧率 !current_fps! 与第一个视频的帧率 !first_file_fps! 不一致！
                    set "fps_consistent=0"
                )
            )
        )
    )
)

if "!file_count!"=="0" (
    echo 没有找到任何视频文件（01.mp4 到 200.mp4）
    pause
    exit
)

if "!fps_consistent!"=="0" (
    echo.
    echo 帧率不一致，请选择按 Enter 键开始转码，或者关闭窗口结束运行！
    echo.
    pause
    echo 正在转码视频，目标帧率为 !first_file_fps!...
    rem 为了做文件名安全，把 '/' 和 '\' 替换为 '_' 用于临时文件名
    set "fps_safe=!first_file_fps:/=_!"
    set "fps_safe=!fps_safe:\=_!"
    echo. > file_list.txt
    for /l %%i in (1,1,200) do (
        for %%f in ("%%i.mp4" "0%%i.mp4" "00%%i.mp4") do (
            if exist %%f (
                set "temp_file=%%~nf_fps_!fps_safe!.mp4"
                echo 重新编码视频: %%~f - !temp_file!
                if not exist "!temp_file!" (
                    ffmpeg -i "%%~f" -r "!first_file_fps!" -c:v libx264 -c:a copy -threads 1 "!temp_file!"
                )
                echo file '!temp_file!' >> file_list.txt
            )
        )
    )
)

echo 正在合并视频...
ffmpeg -f concat -safe 0 -i "file_list.txt" -c copy -vsync cfr -r 30 -threads 1 "merged.mp4"

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
        ffmpeg -i "merged.mp4" -i "!cover_file!" -map 0 -map 1 -c copy -disposition:v:1 attached_pic -threads 1 "final.mp4"
    ) else (
        echo 封面文件（0.png、0.jpg 等）不存在，不添加封面
        move /Y "merged.mp4" "final.mp4"
    )
    echo 合并完成，已生成 final.mp4 文件
) else (
    echo 合并失败，请检查报错信息
    pause
    exit
)

if exist "merged.mp4" ( del "merged.mp4" )
if exist "file_list.txt" ( del "file_list.txt" )

pause
exit
