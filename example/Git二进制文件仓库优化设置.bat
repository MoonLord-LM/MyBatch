@echo off

:: Ĭ��ֵ
:: git config core.compression -1
:: git config core.looseCompression -1
:: git config pack.compression -1
:: git config core.bigFileThreshold 512m

:: �Ż�
git config core.compression 0
git config core.looseCompression 0
git config pack.compression 0
git config core.bigFileThreshold 4m

pause
exit
