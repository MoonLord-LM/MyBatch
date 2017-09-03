@echo off
echo 通过调用certutil命令，来计算文件的哈希值
if "%~1"=="" (
echo 请拖拽文件，到本文件图标上运行
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
echo 文件的哈希值计算完成，请查看生成的txt文件
pause