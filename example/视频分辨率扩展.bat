@echo off
chcp 65001
setlocal enabledelayedexpansion

:: H264 编码（CRF 取值 0-51）
:: AV1 编码（CRF 取值 0-63）

echo.
echo 将视频分辨率扩展为 4K 竖屏 2160x3840 
echo.

:loop
    echo 请将要处理的视频文件拖拽到窗口中：
    set /p "input_file="
    set "input_file=!input_file:"=!"
    if "!input_file!"=="" (
        echo 输入不能为空，请重新输入
        goto loop
    )
    if not exist "!input_file!" (
        echo 文件不存在，请重新输入
        goto loop
    )

    :: H264 编码，较小文件
    ffmpeg -i "!input_file!" ^
        -vf "scale=2160:3840:force_original_aspect_ratio=increase, crop=2160:3840:(iw-2160)/2:(ih-3840)/2, eq=saturation=1.5:contrast=1.2, fps=60" ^
        -c:v libx264 -preset veryslow -crf 32 ^
        -c:a aac -b:a 320k ^
        -movflags +faststart ^
        "output_4k_h264_low.mp4"

    :: H264 编码，通常设置
    ffmpeg -i "!input_file!" ^
        -vf "scale=2160:3840:force_original_aspect_ratio=increase, crop=2160:3840:(iw-2160)/2:(ih-3840)/2, eq=saturation=1.5:contrast=1.2, fps=60" ^
        -c:v libx264 -preset veryslow -crf 16 ^
        -c:a aac -b:a 320k ^
        -movflags +faststart ^
        "output_4k_h264.mp4"

    :: AV1 编码，通常设置
    ffmpeg -i "!input_file!" ^
        -vf "scale=2160:3840:force_original_aspect_ratio=increase, crop=2160:3840:(iw-2160)/2:(ih-3840)/2, eq=saturation=1.5:contrast=1.2, fps=60" ^
        -c:v libsvtav1 -preset 0 -crf 20 ^
        -c:a libopus -b:a 320k ^
        -movflags +faststart ^
        "output_4k_av1.mp4"

    :: AV1 编码，较大文件
    ffmpeg -i "!input_file!" ^
        -vf "scale=2160:3840:force_original_aspect_ratio=increase, crop=2160:3840:(iw-2160)/2:(ih-3840)/2, eq=saturation=1.5:contrast=1.2, fps=60" ^
        -c:v libsvtav1 -preset 0 -crf 10 ^
        -c:a libopus -b:a 320k ^
        -movflags +faststart ^
        "output_4k_av1_high.mp4"

    echo.
goto loop
