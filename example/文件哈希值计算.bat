@echo off
echo ͨ������certutil����������ļ��Ĺ�ϣֵ
if "%~1"=="" (
echo ����ק�ļ��������ļ�ͼ��������
pause
exit
)
for %%a in ("%~1") do set filename=%%~na
for %%a in ("%~1") do set exname=%%~xa
certutil -hashfile "%~1" MD2 >>"%filename%%exname%.txt"
certutil -hashfile "%~1" MD4 >>"%filename%%exname%.txt"
certutil -hashfile "%~1" MD5 >>"%filename%%exname%.txt"
certutil -hashfile "%~1" SHA1 >>"%filename%%exname%.txt"
certutil -hashfile "%~1" SHA256 >>"%filename%%exname%.txt"
certutil -hashfile "%~1" SHA384 >>"%filename%%exname%.txt"
certutil -hashfile "%~1" SHA512 >>"%filename%%exname%.txt"
echo �ļ��Ĺ�ϣֵ������ɣ���鿴���ɵ�txt�ļ�
pause