@echo off
setlocal enabledelayedexpansion

:: 依赖的软件如下
:: https://github.com/FFmpeg/FFmpeg



echo 本脚本用于将封面文件 00.jpg 以及视频文件 01.mp4、02.mp4... 最多到 200.mp4 拼接合并为 final.mp4 文件
echo 会尽可能保留原始视频质量，必要的时候进行转码
echo 转码过程使用单线程运行，防止占用过多 CPU 资源
echo.

echo 合并视频时，需要保证每段视频的视频编码、视频帧率、音频编码、音频采样率参数一致，避免音画不一致问题
echo 合并视频时，需要使用 -map_metadata -1 参数，清理掉 QuickTime TC 格式的 Time code 资源，避免音画不一致问题
echo.

set "file_count=0"
set "file_consistent=1"
set "first_video_codec="
set "first_audio_codec="
set "first_video_fps="
set "first_audio_sample_rate="

echo 正在生成文件列表...
echo. > file_list.txt
for /l %%i in (1,1,200) do (
    for %%f in ("%%i.mp4" "0%%i.mp4" "00%%i.mp4") do (
        if exist %%f (
            echo file '%%~f' >> file_list.txt
            set /a "file_count+=1"
            :: 解析参数
            for /f "delims=" %%v in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name -of csv^=p^=0 %%f 2^>^&1') do (
                set "current_video_codec=%%v"
            )
            for /f "delims=" %%a in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name -of csv^=p^=0 %%f 2^>^&1') do (
                set "current_audio_codec=%%a"
            )
            for /f "delims=" %%r in ('ffprobe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of csv^=p^=0 %%f 2^>^&1') do (
                set "current_video_fps=%%r"
            )
            for /f "delims=" %%r in ('ffprobe -v error -select_streams a:0 -show_entries stream^=sample_rate -of csv^=p^=0 %%f 2^>^&1') do (
                set "current_audio_sample_rate=%%r"
            )
            echo 第 !file_count! 个视频，视频编码：!current_video_codec!，帧率: !current_video_fps!，音频编码：!current_audio_codec!，音频采样率: !current_audio_sample_rate!
            :: 对比参数
            if not defined first_video_codec (
                set "first_video_codec=!current_video_codec!"
            )
            if not defined first_audio_codec (
                set "first_audio_codec=!current_audio_codec!"
            )
            if not defined first_video_fps (
                set "first_video_fps=!current_video_fps!"
            )
            if not defined first_audio_sample_rate (
                set "first_audio_sample_rate=!current_audio_sample_rate!"
            )
            if not "!current_video_codec!"=="!first_video_codec!" (
                echo 警告：文件 %%~f 的视频编码 !current_video_codec! 与第一个视频的视频编码 !first_video_codec! 不一致！
                set "file_consistent=0"
            )
            if not "!current_audio_codec!"=="!first_audio_codec!" (
                echo 警告：文件 %%~f 的音频编码 !current_audio_codec! 与第一个视频的音频编码 !first_audio_codec! 不一致！
                set "file_consistent=0"
            )
            if not "!current_video_fps!"=="!first_video_fps!" (
                echo 警告：文件 %%~f 的帧率 !current_video_fps! 与第一个视频的帧率 !first_video_fps! 不一致！
                set "file_consistent=0"
            )
            if not "!current_audio_sample_rate!"=="!first_audio_sample_rate!" (
                echo 警告：文件 %%~f 的音频采样率 !current_audio_sample_rate! 与第一个视频的音频采样率 !first_audio_sample_rate! 不一致！
                set "file_consistent=0"
            )
        )
    )
)

if "!file_count!"=="0" (
    echo 没有找到任何视频文件（01.mp4 到 200.mp4）
    pause
    exit
)

set "target_video_encoder=libx264"
set "target_audio_encoder=aac"

if /i "!first_video_codec!"=="HEVC" (
    set "target_video_encoder=libx265"
) else if /i "!first_video_codec!"=="H265" (
    set "target_video_encoder=libx265"
) else if /i "!first_video_codec!"=="AVC" (
    set "target_video_encoder=libx264"
) else if /i "!first_video_codec!"=="H264" (
    set "target_video_encoder=libx264"
) else (
    echo 警告：未知视频编码 "!first_video_codec!"，使用默认 libx264
    pause
)
if /i "!first_audio_codec!"=="AAC" (
    set "target_audio_encoder=aac"
) else (
    echo 警告：未知音频编码 "!first_audio_codec!"，使用默认 aac
    pause
)

:: 参数不一致进行转码
if "!file_consistent!"=="0" (
    echo.
    echo 分段视频的参数不一致，请选择按 Enter 键开始转码，或者关闭窗口结束运行！
    echo.
    pause
    echo 正在转码视频，目标视频编码：!first_video_codec!，目标帧率: !first_video_fps!，目标音频编码：!first_audio_codec!，目标音频采样率: !first_audio_sample_rate!...

    rem 为了做文件名安全，把 '/' 和 '\' 替换为 '_' 用于临时文件名
    set "suffix_safe=!first_video_fps!_!first_audio_sample_rate!"
    set "suffix_safe=!suffix_safe:/=_!"
    set "suffix_safe=!suffix_safe:\=_!"
    echo. > file_list.txt

    for /l %%i in (1,1,200) do (
        for %%f in ("%%i.mp4" "0%%i.mp4" "00%%i.mp4") do (
            if exist %%f (
                :: 解析参数
                for /f "delims=" %%v in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name -of csv^=p^=0 %%f 2^>^&1') do (
                    set "current_video_codec=%%v"
                )
                for /f "delims=" %%a in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name -of csv^=p^=0 %%f 2^>^&1') do (
                    set "current_audio_codec=%%a"
                )
                for /f "delims=" %%r in ('ffprobe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of csv^=p^=0 %%f 2^>^&1') do (
                    set "current_video_fps=%%r"
                )
                for /f "delims=" %%r in ('ffprobe -v error -select_streams a:0 -show_entries stream^=sample_rate -of csv^=p^=0 %%f 2^>^&1') do (
                    set "current_audio_sample_rate=%%r"
                )
                echo 第 !file_count! 个视频，视频编码：!current_video_codec!，帧率: !current_video_fps!，音频编码：!current_audio_codec!，音频采样率: !current_audio_sample_rate!
                :: 对比参数
                set "temp_file=%%~nf_!suffix_safe!.mp4"
                if not "!current_video_codec!"=="!first_video_codec!" (
                    echo 重新编码视频: %%~f - !temp_file!
                    if not "!current_audio_codec!"=="!first_audio_codec!" (
                        if not exist "!temp_file!" (
                            ffmpeg -i "%%~f" -c:v "!target_video_encoder!" -r "!first_video_fps!" -c:a "!target_audio_encoder!" -ar "!first_audio_sample_rate!" -map_metadata -1 -threads 1 "!temp_file!"
                        )
                    ) else if not "!current_audio_sample_rate!"=="!first_audio_sample_rate!" (
                        if not exist "!temp_file!" (
                            ffmpeg -i "%%~f" -c:v "!target_video_encoder!" -r "!first_video_fps!" -c:a "!target_audio_encoder!" -ar "!first_audio_sample_rate!" -map_metadata -1 -threads 1 "!temp_file!"
                        )
                    ) else (
                        if not exist "!temp_file!" (
                            ffmpeg -i "%%~f" -c:v "!target_video_encoder!" -r "!first_video_fps!" -c:a copy -map_metadata -1 -threads 1 "!temp_file!"
                        )
                    )
                    echo file '!temp_file!' >> file_list.txt
                ) else if not "!current_audio_codec!"=="!first_audio_codec!" (
                    echo 重新编码视频: %%~f - !temp_file!
                    if not "!current_video_fps!"=="!first_video_fps!" (
                        if not exist "!temp_file!" (
                            ffmpeg -i "%%~f" -c:v "!target_video_encoder!" -r "!first_video_fps!" -c:a "!target_audio_encoder!" -ar "!first_audio_sample_rate!" -map_metadata -1 -threads 1 "!temp_file!"
                        )
                    ) else (
                        if not exist "!temp_file!" (
                            ffmpeg -i "%%~f" -c:v copy -c:a "!target_audio_encoder!" -ar "!first_audio_sample_rate!" -map_metadata -1 -threads 1 "!temp_file!"
                        )
                    )
                    echo file '!temp_file!' >> file_list.txt
                ) else if not "!current_video_fps!"=="!first_video_fps!" (
                    echo 重新编码视频: %%~f - !temp_file!
                    if not "!current_audio_sample_rate!"=="!first_audio_sample_rate!" (
                        if not exist "!temp_file!" (
                            ffmpeg -i "%%~f" -c:v "!target_video_encoder!" -r "!first_video_fps!" -c:a "!target_audio_encoder!" -ar "!first_audio_sample_rate!" -map_metadata -1 -threads 1 "!temp_file!"
                        )
                    ) else (
                        if not exist "!temp_file!" (
                            ffmpeg -i "%%~f" -c:v "!target_video_encoder!" -r "!first_video_fps!" -c:a copy -map_metadata -1 -threads 1 "!temp_file!"
                        )
                    )
                    echo file '!temp_file!' >> file_list.txt
                ) else if not "!current_audio_sample_rate!"=="!first_audio_sample_rate!" (
                    echo 重新编码视频: %%~f - !temp_file!
                    if not exist "!temp_file!" (
                        ffmpeg -i "%%~f" -c:v copy -c:a "!target_audio_encoder!" -ar "!first_audio_sample_rate!" -map_metadata -1 -threads 1 "!temp_file!"
                    )
                    echo file '!temp_file!' >> file_list.txt
                ) else (
                    echo file '%%~f' >> file_list.txt
                )
            )
        )
    )
)

echo 正在合并视频...
ffmpeg -f concat -safe 0 -i "file_list.txt" -c copy -threads 1 "merged.mp4"

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
