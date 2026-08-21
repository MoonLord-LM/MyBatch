@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将封面文件 00.jpg 以及视频文件 01.mp4、02.mp4 ... 最多到 999.mp4 拼接合并为 final.mp4 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动扫描当前文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则递归处理其中所有文件；不支持拖入单个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '会尽可能保留原始视频质量，必要的时候进行转码' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '转码过程使用单线程运行，防止占用过多 CPU 资源' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '合并视频时，需要保证每段视频的视频编码、视频帧率、音频编码、音频采样率参数一致，避免音画不一致问题' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '合并视频时，需要使用 -map_metadata -1 参数，清理掉 QuickTime TC 格式的 Time code 资源，避免音画不一致问题' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "%~dp0"
)

REM 优先使用脚本所在文件夹中的 ffmpeg 和 ffprobe 组件
set "ffmpeg_path=ffmpeg"
if exist "%~dp0ffmpeg.exe" (
    set "ffmpeg_path=%~dp0ffmpeg.exe"
) else if exist "!cd!\ffmpeg.exe" (
    set "ffmpeg_path=!cd!\ffmpeg.exe"
)
!ffmpeg_path! -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 ffmpeg 组件
    echo 请从 https://ffmpeg.org/download.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)
set "ffprobe_path=ffprobe"
if exist "%~dp0ffprobe.exe" (
    set "ffprobe_path=%~dp0ffprobe.exe"
) else if exist "!cd!\ffprobe.exe" (
    set "ffprobe_path=!cd!\ffprobe.exe"
)
!ffprobe_path! -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 ffprobe 组件
    echo 请从 https://ffmpeg.org/download.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)

REM 优先使用脚本所在文件夹中的 MediaInfo 组件
set "mediainfo_path=mediainfo"
if exist "%~dp0MediaInfo.exe" (
    set "mediainfo_path=%~dp0MediaInfo.exe"
) else if exist "!cd!\MediaInfo.exe" (
    set "mediainfo_path=!cd!\MediaInfo.exe"
)
!mediainfo_path! --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 MediaInfo 组件
    echo 请从 https://mediaarea.net/en/MediaInfo 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://mediaarea.net/en/MediaInfo"
    echo.
    pause
    exit /b 1
)



if "%~1" == "" (
    set "work_dir=!cd!"
    echo 开始处理当前文件夹："!work_dir!"
    echo.
) else (
    setlocal disabledelayedexpansion
    set "video_path=%~1"
    setlocal enabledelayedexpansion
    if "!video_path:~-1!"=="\" set "video_path=!video_path:~0,-1!"

    if not exist "!video_path!" (
        echo 错误：文件不存在："!video_path!"
        echo.
        pause
        exit /b 1
    )

    if exist "!video_path!\" (
        set "work_dir=!video_path!"
        echo 开始处理文件夹："!video_path!"
        echo.
    ) else (
        echo 错误：请拖入文件夹，不支持拖入文件
        echo.
        pause
        exit /b 1
    )

    endlocal
    endlocal
)



set "file_count=0"
set "file_consistent=1"
set "first_video_width="
set "first_video_height="
set "first_video_codec="
set "first_video_codec_tag="
set "first_video_codec_profile="
set "first_video_codec_level="
set "first_video_codec_tier="
set "first_audio_codec="
set "first_audio_codec_profile="
set "first_video_fps="
set "first_audio_sample_rate="
set "first_video_time_base="

echo 正在检查和处理 mkv 格式的视频
for /l %%i in (1,1,999) do (
    for %%f in ("!work_dir!\%%i.mkv" "!work_dir!\0%%i.mkv" "!work_dir!\00%%i.mkv" "!work_dir!\第%%i集.mkv" "!work_dir!\第0%%i集.mkv" "!work_dir!\第00%%i集.mkv") do (
        if exist "%%~f" (
            set "temp_file=%%~dpnf.mp4"
            if not exist "!temp_file!" (
                "!ffmpeg_path!" -i "%%~f" -c copy -map_metadata -1 -threads 1 "!temp_file!"
            )
        )
    )
)

echo 正在检查和处理 ts 格式的视频
for /l %%i in (1,1,999) do (
    for %%f in ("!work_dir!\%%i.ts" "!work_dir!\0%%i.ts" "!work_dir!\00%%i.ts" "!work_dir!\第%%i集.ts" "!work_dir!\第0%%i集.ts" "!work_dir!\第00%%i集.ts") do (
        if exist "%%~f" (
            set "temp_file=%%~dpnf.mp4"
            if not exist "!temp_file!" (
                "!ffmpeg_path!" -i "%%~f" -c copy -map_metadata -1 -threads 1 "!temp_file!"
            )
        )
    )
)

echo 正在检查文件的序号
set "min_i=0"
set "max_i=0"
for /l %%i in (1,1,999) do (
    set "name_count=0"
    set "name_list="
    for %%f in ("!work_dir!\%%i.mp4" "!work_dir!\0%%i.mp4" "!work_dir!\00%%i.mp4" "!work_dir!\第%%i集.mp4" "!work_dir!\第0%%i集.mp4" "!work_dir!\第00%%i集.mp4") do (
        if exist "%%~f" (
            set /a "name_count+=1"
            if "!name_list!"=="" (
                set "name_list=%%~nxf"
            ) else (
                set "name_list=!name_list! %%~nxf"
            )
        )
    )
    if !name_count! gtr 1 (
        echo 错误：序号 %%i 存在多个命名方式相同的文件：!name_list!，请只保留其中一个文件
        echo.
        pause
        exit /b 1
    )
    if !name_count! gtr 0 (
        if "!min_i!"=="0" set "min_i=%%i"
        set "max_i=%%i"
    )
)
set "missing_list="
for /l %%i in (!min_i!,1,!max_i!) do (
    set "name_count=0"
    for %%f in ("!work_dir!\%%i.mp4" "!work_dir!\0%%i.mp4" "!work_dir!\00%%i.mp4" "!work_dir!\第%%i集.mp4" "!work_dir!\第0%%i集.mp4" "!work_dir!\第00%%i集.mp4") do (
        if exist "%%~f" set /a "name_count+=1"
    )
    if !name_count! equ 0 (
        if "!missing_list!"=="" (
            set "missing_list=%%i"
        ) else (
            set "missing_list=!missing_list! %%i"
        )
    )
)
if not "!missing_list!"=="" (
    echo 错误：视频序号不连续，缺少以下序号：!missing_list!，请补齐缺失的视频文件
    echo.
    pause
    exit /b 1
)

echo 正在清理 Time code 资源
for /l %%i in (1,1,999) do (
    for %%f in ("!work_dir!\%%i.mp4" "!work_dir!\0%%i.mp4" "!work_dir!\00%%i.mp4" "!work_dir!\第%%i集.mp4" "!work_dir!\第0%%i集.mp4" "!work_dir!\第00%%i集.mp4") do (
        if exist "%%~f" (
            "!ffmpeg_path!" -v error -i "%%~f" -map 0 -f null - 2>nul
            if !errorlevel! neq 0 (
                echo.
                echo 文件 "%%~f" 已损坏，无法处理，按 Enter 键显示详细解码错误，或者关闭窗口结束运行
                pause
                "!ffmpeg_path!" -v error -i "%%~f" -map 0 -f null -
                pause
                exit /b 1
            )

            for /f "delims=" %%d in ('call "!ffprobe_path!" -v error -select_streams d -show_entries stream^=codec_tag_string -of csv^=p^=0 "%%~f" 2^>nul') do (
                if "%%d"=="tmcd" (
                    echo 警告：文件包含 Time code 流，需要进行清理
                    set "temp_file=%%~dpnf_tmp.mp4"
                    if not exist "!temp_file!" (
                        "!ffmpeg_path!" -i "%%~f" -c copy -map_metadata -1 -threads 1 "!temp_file!"
                    )
                    del /f /q "%%~f"
                    ren "!temp_file!" "%%~nxf"
                )
            )
        )
    )
)

echo 正在生成文件列表
type nul > "!work_dir!\file_list.txt"
for /l %%i in (1,1,999) do (
    for %%f in ("!work_dir!\%%i.mp4" "!work_dir!\0%%i.mp4" "!work_dir!\00%%i.mp4" "!work_dir!\第%%i集.mp4" "!work_dir!\第0%%i集.mp4" "!work_dir!\第00%%i集.mp4") do (
        if exist "%%~f" (
            echo file '%%~f' >> "!work_dir!\file_list.txt"
            set /a "file_count+=1"
            REM 解析参数
            for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=width -of csv^=p^=0 "%%~f" 2^>^&1') do (
                set "current_video_width=%%v"
            )
            for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=height -of csv^=p^=0 "%%~f" 2^>^&1') do (
                set "current_video_height=%%v"
            )
            for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=codec_name -of csv^=p^=0 "%%~f" 2^>^&1') do (
                set "current_video_codec=%%v"
            )
            for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=codec_tag_string -of csv^=p^=0 "%%~f" 2^>^&1') do (
                set "current_video_codec_tag=%%v"
            )
            for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=profile -of csv^=p^=0 "%%~f" 2^>^&1') do (
                set "current_video_codec_profile=%%v"
            )
            for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=level -of csv^=p^=0 "%%~f" 2^>^&1') do (
                set "current_video_codec_level=%%v"
            )
            REM "!mediainfo_path!" 用于获取视频编码的 Tier 信息
            for /f "tokens=*" %%v in ('call "!mediainfo_path!" --Inform^="Video;%%Format_Profile%%" "%%~f" 2^>^&1') do (
                set "temp_profile=%%v"
                set "temp_profile=!temp_profile:*@=!"
                set "temp_profile=!temp_profile:*@=!"
                set "current_video_codec_tier=!temp_profile!"
            )
            for /f "delims=" %%a in ('call "!ffprobe_path!" -v error -select_streams a:0 -show_entries stream^=codec_name -of csv^=p^=0 "%%~f" 2^>^&1') do (
                set "current_audio_codec=%%a"
            )
            for /f "delims=" %%a in ('call "!ffprobe_path!" -v error -select_streams a:0 -show_entries stream^=profile -of csv^=p^=0 "%%~f" 2^>^&1') do (
                set "current_audio_codec_profile=%%a"
            )
            for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of csv^=p^=0 "%%~f" 2^>^&1') do (
                set "current_video_fps=%%v"
            )
            for /f "delims=" %%a in ('call "!ffprobe_path!" -v error -select_streams a:0 -show_entries stream^=sample_rate -of csv^=p^=0 "%%~f" 2^>^&1') do (
                set "current_audio_sample_rate=%%a"
            )
            for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=time_base -of csv^=p^=0 "%%~f" 2^>^&1') do (
                set "current_video_time_base=%%v"
            )
            set "current_video_codec_all=!current_video_codec! !current_video_codec_tag! !current_video_codec_profile! !current_video_codec_level! !current_video_codec_tier!"
            set "current_audio_codec_all=!current_audio_codec! !current_audio_codec_profile!"
            echo 第 !file_count! 个视频，分辨率：!current_video_width!x!current_video_height!，视频编码：!current_video_codec_all!，帧率：!current_video_fps!，音频编码：!current_audio_codec_all!，音频采样率：!current_audio_sample_rate!，视频时间基准：!current_video_time_base!

            REM 对比参数
            if "!first_video_width!"=="" ( set "first_video_width=!current_video_width!" )
            if "!first_video_height!"=="" ( set "first_video_height=!current_video_height!" )
            if "!first_video_codec!"=="" ( set "first_video_codec=!current_video_codec!" )
            if "!first_video_codec_tag!"=="" ( set "first_video_codec_tag=!current_video_codec_tag!" )
            if "!first_video_codec_profile!"=="" ( set "first_video_codec_profile=!current_video_codec_profile!" )
            if "!first_video_codec_level!"=="" ( set "first_video_codec_level=!current_video_codec_level!" )
            if "!first_video_codec_tier!"=="" ( set "first_video_codec_tier=!current_video_codec_tier!" )
            if "!first_audio_codec!"=="" ( set "first_audio_codec=!current_audio_codec!" )
            if "!first_audio_codec_profile!"=="" ( set "first_audio_codec_profile=!current_audio_codec_profile!" )
            if "!first_video_fps!"=="" ( set "first_video_fps=!current_video_fps!" )
            if "!first_audio_sample_rate!"=="" ( set "first_audio_sample_rate=!current_audio_sample_rate!" )
            if "!first_video_time_base!"=="" ( set "first_video_time_base=!current_video_time_base!" )

            if "!first_video_codec_all!"=="" ( set "first_video_codec_all=!current_video_codec_all!" )
            if "!first_audio_codec_all!"=="" ( set "first_audio_codec_all=!current_audio_codec_all!" )

            if not "!current_video_width!"=="!first_video_width!" (
                echo 警告：文件 %%~f 的视频分辨率宽度 !current_video_width! 与第一个视频的分辨率宽度 !first_video_width! 不一致
                set "file_consistent=0"
            )
            if not "!current_video_height!"=="!first_video_height!" (
                echo 警告：文件 %%~f 的视频分辨率高度 !current_video_height! 与第一个视频的视频分辨率高度 !first_video_height! 不一致
                set "file_consistent=0"
            )
            if not "!current_video_codec_all!"=="!first_video_codec_all!" (
                echo 警告：文件 %%~f 的视频编码 !current_video_codec_all! 与第一个视频的视频编码 !first_video_codec_all! 不一致
                set "file_consistent=0"
            )
            if not "!current_audio_codec_all!"=="!first_audio_codec_all!" (
                echo 警告：文件 %%~f 的音频编码 !current_audio_codec_all! 与第一个视频的音频编码 !first_audio_codec_all! 不一致
                set "file_consistent=0"
            )
            if not "!current_video_fps!"=="!first_video_fps!" (
                echo 警告：文件 %%~f 的帧率 !current_video_fps! 与第一个视频的帧率 !first_video_fps! 不一致
                set "file_consistent=0"
            )
            if not "!current_audio_sample_rate!"=="!first_audio_sample_rate!" (
                echo 警告：文件 %%~f 的音频采样率 !current_audio_sample_rate! 与第一个视频的音频采样率 !first_audio_sample_rate! 不一致
                set "file_consistent=0"
            )
            if not "!current_video_time_base!"=="!first_video_time_base!" (
                echo 警告：文件 %%~f 的视频时间基准 !current_video_time_base! 与第一个视频的视频时间基准 !first_video_time_base! 不一致
                set "file_consistent=0"
            )
        )
    )
)

if "!file_count!"=="0" (
    echo 没有找到任何视频文件（01.mp4 到 999.mp4）
    if exist "!work_dir!\file_list.txt" ( del /f /q "!work_dir!\file_list.txt" )
    pause
    exit /b 1
)

set "file_count=0"
set "target_video_encoder=libx264"
set "target_audio_encoder=aac"

if /i "!first_video_codec!"=="AV1" ( set "target_video_encoder=libaom-av1"
) else if /i "!first_video_codec!"=="HEVC" ( set "target_video_encoder=libx265"
) else if /i "!first_video_codec!"=="H264" ( set "target_video_encoder=libx264"
) else if /i "!first_video_codec!"=="MPEG4" ( set "target_video_encoder=mpeg4"
) else if /i "!first_video_codec!"=="VP9" ( set "target_video_encoder=libvpx-vp9"
) else if /i "!first_video_codec!"=="VP8" ( set "target_video_encoder=libvpx"
) else (
    echo 警告：未知视频编码 "!first_video_codec!"，使用默认 libx264
    pause
)

if /i "!first_video_codec_tag!"=="av01" ( set "target_video_encoder=!target_video_encoder! -tag:v av01"
) else if /i "!first_video_codec_tag!"=="hvc1" ( set "target_video_encoder=!target_video_encoder! -tag:v hvc1"
) else if /i "!first_video_codec_tag!"=="hev1" ( set "target_video_encoder=!target_video_encoder! -tag:v hev1"
) else if /i "!first_video_codec_tag!"=="avc1" ( set "target_video_encoder=!target_video_encoder! -tag:v avc1"
) else if /i "!first_video_codec_tag!"=="mp4v" ( set "target_video_encoder=!target_video_encoder! -tag:v mp4v"
) else if /i "!first_video_codec_tag!"=="vp09" ( set "target_video_encoder=!target_video_encoder! -tag:v vp09"
) else (
    echo 警告：未知视频编码 "!first_video_codec_tag!"，不使用 Tag
    pause
)

if /i "!first_video_codec_profile!"=="Main" ( set "target_video_encoder=!target_video_encoder! -profile:v main"
) else if /i "!first_video_codec_profile!"=="High" ( set "target_video_encoder=!target_video_encoder! -profile:v high"
) else if /i "!first_video_codec_profile!"=="Baseline" ( set "target_video_encoder=!target_video_encoder! -profile:v baseline"
) else if /i "!first_video_codec_profile!"=="Simple Profile" ( set "target_video_encoder=!target_video_encoder! -profile:v simple"
) else (
    echo 警告：未知视频编码 "!first_video_codec_profile!"，使用默认 libx264
    pause
)

REM H.264 (AVC) Level 对应关系 x10
REM H.265 (HEVC) Level 对应关系 x30
if /i "!first_video_codec!"=="H264" (
    if /i "!first_video_codec_level!"=="10" ( set "target_video_encoder=!target_video_encoder! -level:v 1.0"
    ) else if /i "!first_video_codec_level!"=="13" ( set "target_video_encoder=!target_video_encoder! -level:v 1.3"
    ) else if /i "!first_video_codec_level!"=="20" ( set "target_video_encoder=!target_video_encoder! -level:v 2.0"
    ) else if /i "!first_video_codec_level!"=="30" ( set "target_video_encoder=!target_video_encoder! -level:v 3.0"
    ) else if /i "!first_video_codec_level!"=="31" ( set "target_video_encoder=!target_video_encoder! -level:v 3.1"
    ) else if /i "!first_video_codec_level!"=="32" ( set "target_video_encoder=!target_video_encoder! -level:v 3.2"
    ) else if /i "!first_video_codec_level!"=="40" ( set "target_video_encoder=!target_video_encoder! -level:v 4.0"
    ) else if /i "!first_video_codec_level!"=="41" ( set "target_video_encoder=!target_video_encoder! -level:v 4.1"
    ) else if /i "!first_video_codec_level!"=="42" ( set "target_video_encoder=!target_video_encoder! -level:v 4.2"
    ) else if /i "!first_video_codec_level!"=="50" ( set "target_video_encoder=!target_video_encoder! -level:v 5.0"
    ) else if /i "!first_video_codec_level!"=="51" ( set "target_video_encoder=!target_video_encoder! -level:v 5.1"
    ) else if /i "!first_video_codec_level!"=="52" ( set "target_video_encoder=!target_video_encoder! -level:v 5.2"
    ) else (
        echo 警告：未知视频编码 "!first_video_codec_level!"，不使用 Level
        pause
    )
) else if /i "!first_video_codec!"=="HEVC" (
    set "x265_level="
    if /i "!first_video_codec_level!"=="30" ( set "x265_level=10"
    ) else if /i "!first_video_codec_level!"=="60" ( set "x265_level=20"
    ) else if /i "!first_video_codec_level!"=="63" ( set "x265_level=21"
    ) else if /i "!first_video_codec_level!"=="90" ( set "x265_level=30"
    ) else if /i "!first_video_codec_level!"=="93" ( set "x265_level=31"
    ) else if /i "!first_video_codec_level!"=="120" ( set "x265_level=40"
    ) else if /i "!first_video_codec_level!"=="123" ( set "x265_level=41"
    ) else if /i "!first_video_codec_level!"=="150" ( set "x265_level=50"
    ) else if /i "!first_video_codec_level!"=="153" ( set "x265_level=51"
    ) else if /i "!first_video_codec_level!"=="156" ( set "x265_level=52"
    ) else (
        echo 警告：未知视频编码 "!first_video_codec_level!"，不使用 Level
        pause
    )
    if not "!x265_level!"=="" (
        if /i "!first_video_codec_tier!"=="Main" ( set "target_video_encoder=!target_video_encoder! -x265-params ^"level-idc=!x265_level!:high-tier=0^""
        ) else if /i "!first_video_codec_tier!"=="High" ( set "target_video_encoder=!target_video_encoder! -x265-params ^"level-idc=!x265_level!:high-tier=1^""
        ) else (
            echo 警告：未知视频编码 "!first_video_codec_tier!"，不使用 Tier
            pause
            set "target_video_encoder=!target_video_encoder! -x265-params ^"level-idc=!x265_level!^""
        )
    ) else (
        echo 警告：未知视频编码 "!first_video_codec_tier!"，不使用 Tier
        pause
    )
) else if /i "!first_video_codec!"=="MPEG4" (
    if /i "!first_video_codec_level!"=="3" ( set "target_video_encoder=!target_video_encoder! -level 3"
    ) else (
        echo 警告：未知视频编码 "!first_video_codec_level!"，不使用 Level
        pause
    )
) else (
    echo 警告：未知视频编码 "!first_video_codec_level!"，不使用 Level
    pause
)

if /i "!first_audio_codec_all!"=="AAC LC" ( set "target_audio_encoder=aac -profile:a aac_low"
) else if /i "!first_audio_codec_all!"=="AAC HE-AAC" ( set "target_audio_encoder=libfdk_aac -profile:a aac_he"
) else if /i "!first_audio_codec_all!"=="AAC HE-AACv2" ( set "target_audio_encoder=libfdk_aac -profile:a aac_he_v2"
) else if /i "!first_audio_codec_all!"=="MP3 UNKNOWN" ( set "target_audio_encoder=libmp3lame"
) else if /i "!first_audio_codec_all!"=="AC3 UNKNOWN" ( set "target_audio_encoder=ac3"
) else if /i "!first_audio_codec_all!"=="EAC3 UNKNOWN" ( set "target_audio_encoder=eac3"
) else (
    echo 警告：未知音频编码 "!first_audio_codec!"，使用默认 aac
    pause
)

echo.
echo 当前视频编码参数 !target_video_encoder!
echo 当前音频编码参数 !target_audio_encoder!
echo.

REM 为了做文件名安全，把 '/' 和 '\' 替换为 '_' 用于临时文件名
set "suffix_safe=!first_video_fps!_!first_audio_sample_rate!"
set "suffix_safe=!suffix_safe:/=_!"
set "suffix_safe=!suffix_safe:\=_!"

REM 参数不一致进行转码
if "!file_consistent!"=="0" (

    if /i "!first_video_codec!"=="HEVC" (
        echo.
        echo H265 编码较为复杂，直接拼接容易出现音画不同步问题，可以尝试进行全量的重新编码
        echo.
        echo 请选择按 Enter 键开始转码，或者关闭窗口结束运行
        echo.
        pause
        echo 正在转码视频，目标分辨率：!first_video_width!x!first_video_height!，视频编码：!first_video_codec_all!，目标帧率：!first_video_fps!，目标音频编码：!first_audio_codec_all!，目标音频采样率：!first_audio_sample_rate!，目标视频时间基准：!first_video_time_base!

        type nul > "!work_dir!\file_list.txt"
        for /l %%i in (1,1,999) do (
            for %%f in ("!work_dir!\%%i.mp4" "!work_dir!\0%%i.mp4" "!work_dir!\00%%i.mp4" "!work_dir!\第%%i集.mp4" "!work_dir!\第0%%i集.mp4" "!work_dir!\第00%%i集.mp4") do (
                if exist "%%~f" (
                    set "temp_file=%%~dpnf_h264_!suffix_safe!.mp4"
                    REM 从 "1/1000" 中提取分母 "1000" 作为 timescale；格式异常时回退原值
                    for /f "tokens=2 delims=/" %%t in ("!first_video_time_base!") do set "target_timebase=%%t"
                    if "!target_timebase!"=="" set "target_timebase=!first_video_time_base!"
                    echo 重新编码视频："%%~f" - "!temp_file!"
                    if not exist "!temp_file!" (
                        "!ffmpeg_path!" -i "%%~f" ^
                            -vf "scale=!first_video_width!:!first_video_height!:force_original_aspect_ratio=increase,crop=!first_video_width!:!first_video_height!" ^
                            -video_track_timescale "!target_timebase!" ^
                            -c:v "libx264" -r "!first_video_fps!" ^
                            -c:a "aac" -ar "!first_audio_sample_rate!" ^
                            -map_metadata -1 -threads 1 "!temp_file!"
                    )
                    echo file '!temp_file!' >> "!work_dir!\file_list.txt"
                )
            )
        )
    ) else (
        echo.
        echo 分段视频的参数不一致，请选择按 Enter 键开始转码，或者关闭窗口结束运行
        echo.
        pause
        echo 正在转码视频，目标分辨率：!first_video_width!x!first_video_height!，视频编码：!first_video_codec_all!，目标帧率：!first_video_fps!，目标音频编码：!first_audio_codec_all!，目标音频采样率：!first_audio_sample_rate!，目标视频时间基准：!first_video_time_base!

        type nul > "!work_dir!\file_list.txt"
        for /l %%i in (1,1,999) do (
            for %%f in ("!work_dir!\%%i.mp4" "!work_dir!\0%%i.mp4" "!work_dir!\00%%i.mp4" "!work_dir!\第%%i集.mp4" "!work_dir!\第0%%i集.mp4" "!work_dir!\第00%%i集.mp4") do (
                if exist "%%~f" (
                    set /a "file_count+=1"
                    REM 解析参数
                    for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=width -of csv^=p^=0 "%%~f" 2^>^&1') do (
                        set "current_video_width=%%v"
                    )
                    for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=height -of csv^=p^=0 "%%~f" 2^>^&1') do (
                        set "current_video_height=%%v"
                    )
                    for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=codec_name -of csv^=p^=0 "%%~f" 2^>^&1') do (
                        set "current_video_codec=%%v"
                    )
                    for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=codec_tag_string -of csv^=p^=0 "%%~f" 2^>^&1') do (
                        set "current_video_codec_tag=%%v"
                    )
                    for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=profile -of csv^=p^=0 "%%~f" 2^>^&1') do (
                        set "current_video_codec_profile=%%v"
                    )
                    for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=level -of csv^=p^=0 "%%~f" 2^>^&1') do (
                        set "current_video_codec_level=%%v"
                    )
                    REM "!mediainfo_path!" 用于获取视频编码的 Tier 信息
                    for /f "tokens=*" %%v in ('call "!mediainfo_path!" --Inform^="Video;%%Format_Profile%%" "%%~f" 2^>^&1') do (
                        set "temp_profile=%%v"
                        set "temp_profile=!temp_profile:*@=!"
                        set "temp_profile=!temp_profile:*@=!"
                        set "current_video_codec_tier=!temp_profile!"
                    )
                    for /f "delims=" %%a in ('call "!ffprobe_path!" -v error -select_streams a:0 -show_entries stream^=codec_name -of csv^=p^=0 "%%~f" 2^>^&1') do (
                        set "current_audio_codec=%%a"
                    )
                    for /f "delims=" %%a in ('call "!ffprobe_path!" -v error -select_streams a:0 -show_entries stream^=profile -of csv^=p^=0 "%%~f" 2^>^&1') do (
                        set "current_audio_codec_profile=%%a"
                    )
                    for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of csv^=p^=0 "%%~f" 2^>^&1') do (
                        set "current_video_fps=%%v"
                    )
                    for /f "delims=" %%a in ('call "!ffprobe_path!" -v error -select_streams a:0 -show_entries stream^=sample_rate -of csv^=p^=0 "%%~f" 2^>^&1') do (
                        set "current_audio_sample_rate=%%a"
                    )
                    for /f "delims=" %%v in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=time_base -of csv^=p^=0 "%%~f" 2^>^&1') do (
                        set "current_video_time_base=%%v"
                    )
                    set "current_video_codec_all=!current_video_codec! !current_video_codec_tag! !current_video_codec_profile! !current_video_codec_level! !current_video_codec_tier!"
                    set "current_audio_codec_all=!current_audio_codec! !current_audio_codec_profile!"
                    echo 第 !file_count! 个视频，分辨率：!current_video_width!x!current_video_height!，视频编码：!current_video_codec_all!，帧率：!current_video_fps!，音频编码：!current_audio_codec_all!，音频采样率：!current_audio_sample_rate!，视频时间基准：!current_video_time_base!
                    REM 对比参数
                    set "temp_file=%%~dpnf_!suffix_safe!.mp4"
                    set "video_consistent=1"
                    set "audio_consistent=1"
                    if not "!current_video_width!"=="!first_video_width!" (
                        set "video_consistent=0"
                        echo 警告：文件 %%~f 的视频分辨率宽度 !current_video_width! 与第一个视频的视频分辨率宽度 !first_video_width! 不一致
                    )
                    if not "!current_video_height!"=="!first_video_height!" (
                        set "video_consistent=0"
                        echo 警告：文件 %%~f 的视频分辨率高度 !current_video_height! 与第一个视频的视频分辨率高度 !first_video_height! 不一致
                    )
                    if not "!current_video_codec_all!"=="!first_video_codec_all!" (
                        set "video_consistent=0"
                        echo 警告：文件 %%~f 的视频编码 !current_video_codec_all! 与第一个视频的视频编码 !first_video_codec_all! 不一致
                    )
                    if not "!current_video_fps!"=="!first_video_fps!" (
                        set "video_consistent=0"
                        echo 警告：文件 %%~f 的帧率 !current_video_fps! 与第一个视频的帧率 !first_video_fps! 不一致
                    )
                    if not "!current_video_time_base!"=="!first_video_time_base!" (
                        set "video_consistent=0"
                        echo 警告：文件 %%~f 的视频时间基准 !current_video_time_base! 与第一个视频的视频时间基准 !first_video_time_base! 不一致
                    )
                    if not "!current_audio_codec_all!"=="!first_audio_codec_all!" (
                        set "audio_consistent=0"
                        echo 警告：文件 %%~f 的音频编码 !current_audio_codec_all! 与第一个视频的音频编码 !first_audio_codec_all! 不一致
                    )
                    if not "!current_audio_sample_rate!"=="!first_audio_sample_rate!" (
                        set "audio_consistent=0"
                        echo 警告：文件 %%~f 的音频采样率 !current_audio_sample_rate! 与第一个视频的音频采样率 !first_audio_sample_rate! 不一致
                    )
                    echo 视频信息对比完成

                    REM 从 "1/1000" 中提取分母 "1000" 作为 timescale；格式异常时回退原值
                    for /f "tokens=2 delims=/" %%t in ("!first_video_time_base!") do set "target_timebase=%%t"
                    if "!target_timebase!"=="" set "target_timebase=!first_video_time_base!"
                    if not "!video_consistent!"=="1" (
                        echo 重新编码视频："%%~f" - "!temp_file!"
                        if not "!audio_consistent!"=="1" (
                            if not exist "!temp_file!" (
                                "!ffmpeg_path!" -i "%%~f" ^
                                    -vf "scale=!first_video_width!:!first_video_height!:force_original_aspect_ratio=increase,crop=!first_video_width!:!first_video_height!" ^
                                    -video_track_timescale "!target_timebase!" ^
                                    -c:v !target_video_encoder! -r "!first_video_fps!" ^
                                    -c:a !target_audio_encoder! -ar "!first_audio_sample_rate!" ^
                                    -map_metadata -1 -threads 1 "!temp_file!"
                            )
                        ) else (
                            if not exist "!temp_file!" (
                                "!ffmpeg_path!" -i "%%~f" ^
                                    -vf "scale=!first_video_width!:!first_video_height!:force_original_aspect_ratio=increase,crop=!first_video_width!:!first_video_height!" ^
                                    -video_track_timescale "!target_timebase!" ^
                                    -c:v !target_video_encoder! -r "!first_video_fps!" ^
                                    -c:a copy ^
                                    -map_metadata -1 -threads 1 "!temp_file!"
                            )
                        )
                        echo file '!temp_file!' >> "!work_dir!\file_list.txt"
                    ) else if not "!audio_consistent!"=="1" (
                        echo 重新编码视频："%%~f" - "!temp_file!"
                        if not exist "!temp_file!" (
                            "!ffmpeg_path!" -i "%%~f" ^
                                -c:v copy ^
                                -c:a !target_audio_encoder! -ar "!first_audio_sample_rate!" ^
                                -map_metadata -1 -threads 1 "!temp_file!"
                        )
                        echo file '!temp_file!' >> "!work_dir!\file_list.txt"
                    ) else (
                        echo file '%%~f' >> "!work_dir!\file_list.txt"
                    )
                )
            )
        )
    )
)

echo 正在合并视频
"!ffmpeg_path!" -y -f concat -safe 0 -i "!work_dir!\file_list.txt" -c copy -threads 1 "!work_dir!\merged.mp4"
if !errorlevel! neq 0 (
    echo.
    echo 文件 merged.mp4 合并失败，请检查报错信息
    pause
    exit /b 1
)

if exist "!work_dir!\merged.mp4" (
    REM 兼容 webp 封面，自动转为 PNG 格式
    if not exist "!work_dir!\0.png" (
        if exist "!work_dir!\0.webp" (
            echo 检测到封面 0.webp，正在转换为 0.png
            "!ffmpeg_path!" -y -i "!work_dir!\0.webp" "!work_dir!\0.png"
        )
    )
    if not exist "!work_dir!\00.png" (
        if exist "!work_dir!\00.webp" (
            echo 检测到封面 00.webp，正在转换为 00.png
            "!ffmpeg_path!" -y -i "!work_dir!\00.webp" "!work_dir!\00.png"
        )
    )
    if not exist "!work_dir!\000.png" (
        if exist "!work_dir!\000.webp" (
            echo 检测到封面 000.webp，正在转换为 000.png
            "!ffmpeg_path!" -y -i "!work_dir!\000.webp" "!work_dir!\000.png"
        )
    )
    if not exist "!work_dir!\cover.png" (
        if exist "!work_dir!\cover.webp" (
            echo 检测到封面 cover.webp，正在转换为 cover.png
            "!ffmpeg_path!" -y -i "!work_dir!\cover.webp" "!work_dir!\cover.png"
        )
    )

    REM 查找封面文件，优先使用 PNG 格式
    set "cover_file="
    if exist "!work_dir!\0.png" (
        set "cover_file=!work_dir!\0.png"
    ) else if exist "!work_dir!\00.png" (
        set "cover_file=!work_dir!\00.png"
    ) else if exist "!work_dir!\000.png" (
        set "cover_file=!work_dir!\000.png"
    ) else if exist "!work_dir!\0.jpg" (
        set "cover_file=!work_dir!\0.jpg"
    ) else if exist "!work_dir!\00.jpg" (
        set "cover_file=!work_dir!\00.jpg"
    ) else if exist "!work_dir!\000.jpg" (
        set "cover_file=!work_dir!\000.jpg"
    ) else if exist "!work_dir!\cover.png" (
        set "cover_file=!work_dir!\cover.png"
    ) else if exist "!work_dir!\cover.jpg" (
        set "cover_file=!work_dir!\cover.jpg"
    )
    if not "!cover_file!"=="" (
        for /f "delims=" %%p in ('call "!ffprobe_path!" -v error -select_streams v:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!cover_file!"') do (
            set "cover_file_type=%%p"
            echo 封面图片编码：[!cover_file_type!]
        )

        if not "!cover_file_type!"=="png" (
            if not "!cover_file_type!"=="mjpeg" (
                echo 封面图片只支持 PNG 和 JPG 格式，其他格式则需要转换为 PNG
                "!ffmpeg_path!" -y -i "!cover_file!" -frames:v 1 "!cover_file!.png"
                if !errorlevel! neq 0 (
                    echo.
                    echo 封面图片格式转换失败，请检查报错信息
                    pause
                    exit /b 1
                )
                set "cover_file=!cover_file!.png"
            )
        )

        echo 正在添加封面图片 [!cover_file!]
        "!ffmpeg_path!" -y -i "!work_dir!\merged.mp4" -i "!cover_file!" -map 0 -map 1 -c copy -disposition:v:1 attached_pic -threads 1 "!work_dir!\final.mp4"
        if !errorlevel! neq 0 (
            echo.
            echo 文件 final.mp4 合并失败，请检查报错信息
            pause
            exit /b 1
        )
    ) else (
        echo 封面文件（0.png、0.jpg、cover.png 等）不存在，不添加封面
        move /y "!work_dir!\merged.mp4" "!work_dir!\final.mp4"
    )
    echo 合并完成，已生成 !work_dir!\final.mp4 文件
) else (
    echo 合并失败，请检查报错信息
    pause
    exit /b 1
)

if exist "!work_dir!\merged.mp4" ( del /f /q "!work_dir!\merged.mp4" )
if exist "!work_dir!\file_list.txt" ( del /f /q "!work_dir!\file_list.txt" )



echo.
pause
exit /b
