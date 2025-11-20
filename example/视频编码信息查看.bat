@echo off
setlocal enabledelayedexpansion

set "last_video_codec1="
set "last_video_codec2="
set "last_video_codec3="
set "last_video_codec4="
set "last_video_codec5="
set "last_video_codec6="
set "last_video_codec7="
set "last_video_codec8="
set "last_video_codec9="
set "last_video_codec10="
set "last_audio_codec1="
set "last_audio_codec2="
set "last_audio_codec3="
set "last_audio_codec4="
set "last_audio_codec5="
set "last_audio_codec6="
set "last_audio_codec7="
set "last_audio_codec8="
set "last_audio_codec9="
set "last_audio_codec10="

echo 检查视频编码格式...
for %%f in ("*.mp4") do (
    if exist %%f (
        for /f "delims=" %%v in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name^,codec_tag_string -of csv^=p^=0 "%%f" 2^>^&1') do (
            set "current_video_codec=%%v"
            if "!last_video_codec1!"=="" (
                echo new_video_codec: !current_video_codec! - %%f
                set "last_video_codec1=!current_video_codec!"
            ) else if not "!current_video_codec!"=="!last_video_codec1!" (
                if "!last_video_codec2!"=="" (
                    echo new_video_codec: !current_video_codec! - %%f
                    set "last_video_codec2=!current_video_codec!"
                ) else if not "!current_video_codec!"=="!last_video_codec2!" (
                    if "!last_video_codec3!"=="" (
                        echo new_video_codec: !current_video_codec! - %%f
                        set "last_video_codec3=!current_video_codec!"
                    ) else if not "!current_video_codec!"=="!last_video_codec3!" (
                        if "!last_video_codec4!"=="" (
                            echo new_video_codec: !current_video_codec! - %%f
                            set "last_video_codec4=!current_video_codec!"
                        ) else if not "!current_video_codec!"=="!last_video_codec4!" (
                            if "!last_video_codec5!"=="" (
                                echo new_video_codec: !current_video_codec! - %%f
                                set "last_video_codec5=!current_video_codec!"
                            ) else if not "!current_video_codec!"=="!last_video_codec5!" (
                                if "!last_video_codec6!"=="" (
                                    echo new_video_codec: !current_video_codec! - %%f
                                    set "last_video_codec6=!current_video_codec!"
                                ) else if not "!current_video_codec!"=="!last_video_codec6!" (
                                    if "!last_video_codec7!"=="" (
                                        echo new_video_codec: !current_video_codec! - %%f
                                        set "last_video_codec7=!current_video_codec!"
                                    ) else if not "!current_video_codec!"=="!last_video_codec7!" (
                                        if "!last_video_codec8!"=="" (
                                            echo new_video_codec: !current_video_codec! - %%f
                                            set "last_video_codec8=!current_video_codec!"
                                        ) else if not "!current_video_codec!"=="!last_video_codec8!" (
                                            if "!last_video_codec9!"=="" (
                                                echo new_video_codec: !current_video_codec! - %%f
                                                set "last_video_codec9=!current_video_codec!"
                                            ) else if not "!current_video_codec!"=="!last_video_codec9!" (
                                                if "!last_video_codec10!"=="" (
                                                    echo new_video_codec: !current_video_codec! - %%f
                                                    set "last_video_codec10=!current_video_codec!"
                                                ) else if not "!current_video_codec!"=="!last_video_codec10!" (
                                                    echo 编码格式已超过 10 种...
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)
echo.

echo 检查音频编码格式...
for %%f in ("*.mp4") do (
    if exist %%f (
        for /f "delims=" %%a in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name^,profile -of csv^=p^=0 "%%f" 2^>^&1') do (
            set "current_audio_codec=%%a"
            if "!last_audio_codec1!"=="" (
                echo new_audio_codec: !current_audio_codec! - %%f
                set "last_audio_codec1=!current_audio_codec!"
            ) else if not "!current_audio_codec!"=="!last_audio_codec1!" (
                if "!last_audio_codec2!"=="" (
                    echo new_audio_codec: !current_audio_codec! - %%f
                    set "last_audio_codec2=!current_audio_codec!"
                ) else if not "!current_audio_codec!"=="!last_audio_codec2!" (
                    if "!last_audio_codec3!"=="" (
                        echo new_audio_codec: !current_audio_codec! - %%f
                        set "last_audio_codec3=!current_audio_codec!"
                    ) else if not "!current_audio_codec!"=="!last_audio_codec3!" (
                        if "!last_audio_codec4!"=="" (
                            echo new_audio_codec: !current_audio_codec! - %%f
                            set "last_audio_codec4=!current_audio_codec!"
                        ) else if not "!current_audio_codec!"=="!last_audio_codec4!" (
                            if "!last_audio_codec5!"=="" (
                                echo new_audio_codec: !current_audio_codec! - %%f
                                set "last_audio_codec5=!current_audio_codec!"
                            ) else if not "!current_audio_codec!"=="!last_audio_codec5!" (
                                if "!last_audio_codec6!"=="" (
                                    echo new_audio_codec: !current_audio_codec! - %%f
                                    set "last_audio_codec6=!current_audio_codec!"
                                ) else if not "!current_audio_codec!"=="!last_audio_codec6!" (
                                    if "!last_audio_codec7!"=="" (
                                        echo new_audio_codec: !current_audio_codec! - %%f
                                        set "last_audio_codec7=!current_audio_codec!"
                                    ) else if not "!current_audio_codec!"=="!last_audio_codec7!" (
                                        if "!last_audio_codec8!"=="" (
                                            echo new_audio_codec: !current_audio_codec! - %%f
                                            set "last_audio_codec8=!current_audio_codec!"
                                        ) else if not "!current_audio_codec!"=="!last_audio_codec8!" (
                                            if "!last_audio_codec9!"=="" (
                                                echo new_audio_codec: !current_audio_codec! - %%f
                                                set "last_audio_codec9=!current_audio_codec!"
                                            ) else if not "!current_audio_codec!"=="!last_audio_codec9!" (
                                                if "!last_audio_codec10!"=="" (
                                                    echo new_audio_codec: !current_audio_codec! - %%f
                                                    set "last_audio_codec10=!current_audio_codec!"
                                                ) else if not "!current_audio_codec!"=="!last_audio_codec10!" (
                                                    echo 编码格式已超过 10 种...
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)
echo.

pause
exit
