@echo off
setlocal disabledelayedexpansion
::
::
::
::MyBatch�������
::
::
::
mkdir "tmp"
cls
echo ��������������Test��������������My
call My
echo.
echo.
echo ��������������Test��������������My My
call My My
echo.
echo.
echo ��������������Test��������������My echo aaa bbb ccc "!!!" """""
call My echo aaa bbb ccc "!!!" """""
echo.
echo.
echo ��������������Test��������������My cmd java "-version"
call My cmd java "-version"
echo.
echo.
echo ��������������Test��������������My call hello_world
call My call hello_world
echo.
echo.
echo ��������������Test��������������My call print "����print������ַ���"
call My call print "����print������ַ���"
echo.
echo.
echo ��������������Test��������������My call print_array "a123 b456 c789"
call My call print_array "a123 b456 c789"
echo.
echo.
echo ��������������Test��������������My call is_number "0101"
call My call is_number "0101"
echo.
echo.
echo ��������������Test��������������My call is_number "ABAB"
call My call is_number "ABAB"
echo.
echo.
echo ��������������Test��������������My call to_lower "1A2b3C4d����English"
call My call to_lower "1A2b3C4d����English"
echo.
echo.
echo ��������������Test��������������My call to_upper "1A2b3C4d����English"
call My call to_upper "1A2b3C4d����English"
echo.
echo.
echo ��������������Test��������������My call search_file "%~dp0" "*" "tmp\1.txt"
call My call search_file "%~dp0" "*" "tmp\1.txt"
echo.
echo.
echo ��������������Test��������������My call search_file "F:\Pictures" "*.jpeg" "tmp\2.txt"
call My call search_file "F:\Pictures" "*.jpeg" "tmp\2.txt"
echo.
echo.
echo ��������������Test��������������My call list_file "." "tmp\3.txt"
call My call list_file "." "tmp\3.txt"
echo.
echo.
echo ��������������Test��������������My call list_dir "*" "tmp\4.txt"
call My call list_dir "*" "tmp\4.txt"
echo.
echo.
echo ��������������Test��������������My call list_set "tmp\5.txt"
call My call list_set "tmp\5.txt"
echo.
echo.
echo ��������������Test��������������My call print_file "tmp\4.txt"
call My call print_file "tmp\4.txt"
echo.
echo.
echo ��������������Test��������������My call append_file "����append_file��ӵ��ַ���" "tmp\4.txt"
call My call append_file "����append_file��ӵ��ַ���" "tmp\4.txt"
echo.
echo.
echo ��������������Test��������������My call set_clipboard "����set_clipboard���Ƶ��ַ���"
call My call set_clipboard "����set_clipboard���Ƶ��ַ���"
echo.
echo.
echo ��������������Test��������������My call speak_voice "�±���ֵ����ʲô��"
call My call speak_voice "�±���ֵ����ʲô��"
echo.
echo.
echo ��������������Test��������������My call alert "����JS�ĵ�����"
call My call alert "����JS�ĵ�����"
echo.
echo.
echo ��������������Test��������������My call message_box "����VBS�ĵ�����" "���Ǳ��⣡"
call My call message_box "����VBS�ĵ�����" "���Ǳ��⣡"
echo.
echo.
echo ��������������Test��������������My call popup "����VBS�ĵ�����" "���Ǳ���"
call My call popup "����VBS�ĵ�����" "���Ǳ��⣡"
echo.
echo.
echo ��������������Test��������������My call string_length """""""""""12"
call My call string_length """""""""""12"
echo.
echo.
echo ��������������Test��������������My call string_trim "   aaa bbb ccc   "
call My call string_trim "   aaa bbb ccc   "
echo.
echo.
pause