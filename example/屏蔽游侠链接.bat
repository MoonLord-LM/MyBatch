@echo off

echo ͨ������ͬ���������ļ��У�����ֹ�ƽ����Ϸ�Զ����������������ļ�
set adv_name=�������ŵ�����Ϸ.url

del /F /S /Q %adv_name%
rmdir /S /Q %adv_name%
mkdir %adv_name%
attrib +h +s %adv_name%

exit