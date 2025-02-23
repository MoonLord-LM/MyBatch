@echo off

:: 换行符保持原样
git config --local core.autocrlf false
git config --local core.safecrlf false

:: 文件名大小写敏感
git config --local core.ignorecase false

:: 将 100MB 以上的文件视为大文件
git config --local core.bigFileThreshold 100m

:: 压缩算法级别设置为无压缩
git config --local core.compression 0
git config --local pack.compression 0

:: 文件打包大小限制（如果单个文件大小超出限制，仍然会生成很大的 pack 文件）
git config --local pack.packSizeLimit 2g


:: 查看设置
git config --list --local


pause
exit
