@echo off
if not exist "VTS_01_0.VOB" (
    echo 本批处理用于合并 DVD 中的多个 VOB 视频文件
    echo 文件 VTS_01_0.VOB 不存在！
    pause
    exit
)

set "output_filename=合并.vob"
set "input_filename="VTS_01_0.VOB""
if exist "VTS_01_1.VOB" ( set "input_filename=%input_filename%+"VTS_01_1.VOB"" )
if exist "VTS_01_2.VOB" ( set "input_filename=%input_filename%+"VTS_01_2.VOB"" )
if exist "VTS_01_3.VOB" ( set "input_filename=%input_filename%+"VTS_01_3.VOB"" )
if exist "VTS_01_4.VOB" ( set "input_filename=%input_filename%+"VTS_01_4.VOB"" )
if exist "VTS_01_5.VOB" ( set "input_filename=%input_filename%+"VTS_01_5.VOB"" )
if exist "VTS_01_6.VOB" ( set "input_filename=%input_filename%+"VTS_01_6.VOB"" )
if exist "VTS_01_7.VOB" ( set "input_filename=%input_filename%+"VTS_01_7.VOB"" )
if exist "VTS_01_8.VOB" ( set "input_filename=%input_filename%+"VTS_01_8.VOB"" )
if exist "VTS_01_9.VOB" ( set "input_filename=%input_filename%+"VTS_01_9.VOB"" )
if exist "VTS_01_10.VOB" ( set "input_filename=%input_filename%+"VTS_01_10.VOB"" )
if exist "VTS_01_11.VOB" ( set "input_filename=%input_filename%+"VTS_01_11.VOB"" )
if exist "VTS_01_12.VOB" ( set "input_filename=%input_filename%+"VTS_01_12.VOB"" )
if exist "VTS_01_13.VOB" ( set "input_filename=%input_filename%+"VTS_01_13.VOB"" )
if exist "VTS_01_14.VOB" ( set "input_filename=%input_filename%+"VTS_01_14.VOB"" )
if exist "VTS_01_15.VOB" ( set "input_filename=%input_filename%+"VTS_01_15.VOB"" )

copy /b %input_filename% "%output_filename%"