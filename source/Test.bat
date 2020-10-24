@echo off
setlocal disabledelayedexpansion
::
::
::
::MyBatch代码测试
::
::
::
mkdir "tmp"
cls
echo 【——————Test——————】My
call My
echo.
echo.
echo 【——————Test——————】My My
call My My
echo.
echo.
echo 【——————Test——————】My echo aaa bbb ccc "!!!" """""
call My echo aaa bbb ccc "!!!" """""
echo.
echo.
echo 【——————Test——————】My cmd java "-version"
call My cmd java "-version"
echo.
echo.
echo 【——————Test——————】My call hello_world
call My call hello_world
echo.
echo.
echo 【——————Test——————】My call print "这是print输出的字符串"
call My call print "这是print输出的字符串"
echo.
echo.
echo 【——————Test——————】My call print_array "a123 b456 c789"
call My call print_array "a123 b456 c789"
echo.
echo.
echo 【——————Test——————】My call is_number "0101"
call My call is_number "0101"
echo.
echo.
echo 【——————Test——————】My call is_number "ABAB"
call My call is_number "ABAB"
echo.
echo.
echo 【——————Test——————】My call to_lower "1A2b3C4d中文English"
call My call to_lower "1A2b3C4d中文English"
echo.
echo.
echo 【——————Test——————】My call to_upper "1A2b3C4d中文English"
call My call to_upper "1A2b3C4d中文English"
echo.
echo.
echo 【——————Test——————】My call search_file "%~dp0" "*" "tmp\1.txt"
call My call search_file "%~dp0" "*" "tmp\1.txt"
echo.
echo.
echo 【——————Test——————】My call search_file "F:\Pictures" "*.jpeg" "tmp\2.txt"
call My call search_file "F:\Pictures" "*.jpeg" "tmp\2.txt"
echo.
echo.
echo 【——————Test——————】My call list_file "." "tmp\3.txt"
call My call list_file "." "tmp\3.txt"
echo.
echo.
echo 【——————Test——————】My call list_dir "*" "tmp\4.txt"
call My call list_dir "*" "tmp\4.txt"
echo.
echo.
echo 【——————Test——————】My call list_set "tmp\5.txt"
call My call list_set "tmp\5.txt"
echo.
echo.
echo 【——————Test——————】My call print_file "tmp\4.txt"
call My call print_file "tmp\4.txt"
echo.
echo.
echo 【——————Test——————】My call append_file "这是append_file添加的字符串" "tmp\4.txt"
call My call append_file "这是append_file添加的字符串" "tmp\4.txt"
echo.
echo.
echo 【——————Test——————】My call set_clipboard "这是set_clipboard复制的字符串"
call My call set_clipboard "这是set_clipboard复制的字符串"
echo.
echo.
echo 【——————Test——————】My call speak_voice "月饼价值观是什么？"
call My call speak_voice "月饼价值观是什么？"
echo.
echo.
echo 【——————Test——————】My call alert "这是JS的弹出框！"
call My call alert "这是JS的弹出框！"
echo.
echo.
echo 【——————Test——————】My call message_box "这是VBS的弹出框！" "这是标题！"
call My call message_box "这是VBS的弹出框！" "这是标题！"
echo.
echo.
echo 【——————Test——————】My call popup "这是VBS的弹出框！" "这是标题"
call My call popup "这是VBS的弹出框！" "这是标题！"
echo.
echo.
echo 【——————Test——————】My call string_length """""""""""12"
call My call string_length """""""""""12"
echo.
echo.
echo 【——————Test——————】My call string_trim "   aaa bbb ccc   "
call My call string_trim "   aaa bbb ccc   "
echo.
echo.
pause