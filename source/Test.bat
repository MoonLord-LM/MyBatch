@echo off
::
::
::
::MyBatch�������
::
::
::
rem goto :new

echo ��������������Test��������������My
call My
echo.

echo ��������������Test��������������My My
call My My
echo.

echo ��������������Test��������������My echo aaa bbb ccc "!!!" """""
call My echo aaa bbb ccc "!!!" """""
echo.

echo ��������������Test��������������My cmd java -version "!!!"
call My cmd java -version "!!!"
echo.

echo ��������������Test��������������My call hello_world "!!!"
call My call hello_world "!!!"
echo.

echo ��������������Test��������������My call is_number 010 "!!!"
call My call is_number 010 "!!!"
echo.

echo ��������������Test��������������My call is_number "aa!!!"
call My call is_number "aa!!!"
echo.

echo ��������������Test��������������My call print_array "123 456 789"
call My call print_array "123 456 789"
echo.

echo ��������������Test��������������My call to_lower "1A2b3C4d����!!!"
call My call to_lower "1A2b3C4d����!!!"
echo.

echo ��������������Test��������������My call to_upper "1A2b3C4d����!!!"
call My call to_upper "1A2b3C4d����!!!"
echo.

echo ��������������Test��������������My call search_file "%~dp0" "*" "tmp\1.txt"
call My call search_file "%~dp0" "*" "tmp\1.txt"
echo.

echo ��������������Test��������������My call search_file "F:\Pictures" "*.jpeg" "tmp\2.txt"
call My call search_file "F:\Pictures" "*.jpeg" "tmp\2.txt"
echo.

echo ��������������Test��������������My call search_file "tmp" "*" "tmp\3.txt"
call My call search_file "tmp" "*" "tmp\3.txt"
echo.

echo ��������������Test��������������My call print_file "tmp\3.txt"
call My call print_file "tmp\3.txt"
echo.

echo ��������������Test��������������My call list_file "." "tmp\4.txt"
call My call list_file "." "tmp\4.txt"
echo.

echo ��������������Test��������������My call list_dir "*" "tmp\5.txt"
call My call list_dir "*" "tmp\5.txt"
echo.

echo ��������������Test��������������My call list_set "tmp\6.txt"
call My call list_set "tmp\6.txt"
echo.

echo ��������������Test��������������My call append_file "������ӽ������ַ���MoonLord" "tmp\6.txt"
call My call append_file "������ӽ������ַ���MoonLord" "tmp\6.txt"
echo.

echo ��������������Test��������������My call set_clipboard "���Ƶ��ַ���!!!"
call My call set_clipboard "���Ƶ��ַ���!!!"
echo.

echo ��������������Test��������������My call speak_voice "�±���ֵ����ʲô��!!!"
call My call speak_voice "�±���ֵ����ʲô��!!!"
echo.

echo ��������������Test��������������My call alert "����JS�ĵ�����!!!"
call My call alert "����JS�ĵ�����!!!"
echo.

echo ��������������Test��������������My call message_box "����VBS�ĵ�����" "���Ǳ��⣡!!!"
call My call message_box "����VBS�ĵ�����" "���Ǳ��⣡!!!"
echo.

echo ��������������Test��������������My call popup "����VBS�ĵ�����" "���Ǳ��⣡!!!"
call My call popup "����VBS�ĵ�����" "���Ǳ��⣡!!!"
echo.

rem :new
echo ��������������Test��������������My call string_length """""""""""12"
call My call string_length """""""""""12"
echo.

echo ��������������Test��������������My call string_length "!!!!!!!!!!12"
call My call string_length "!!!!!!!!!!12"
echo.

echo ��������������Test��������������My call print "!!!!!!!!!!12"
call My call print "!!!!!!!!!!12"
echo.




