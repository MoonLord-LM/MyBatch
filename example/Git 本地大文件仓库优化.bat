@echo off

:: ���з�����ԭ��
git config --local core.autocrlf false
git config --local core.safecrlf false

:: �ļ�����Сд����
git config --local core.ignorecase false

:: �� 100MB ���ϵ��ļ���Ϊ���ļ�
git config --local core.bigFileThreshold 100m

:: ѹ���㷨��������Ϊ��ѹ��
git config --local core.compression 0
git config --local pack.compression 0

:: �ļ������С���ƣ���������ļ���С�������ƣ���Ȼ�����ɺܴ�� pack �ļ���
git config --local pack.packSizeLimit 2g


:: �鿴����
git config --list --local


pause
exit
