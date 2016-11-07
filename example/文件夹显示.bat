@echo off
if not exist "我的备份.{21EC2020-3AEA-1069-A2DD-08002B30309D}" (
@echo on
echo 本批处理用于显示出隐藏的"我的备份"文件夹
pause
exit
)
attrib -h -s "我的备份.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
ren "我的备份.{21EC2020-3AEA-1069-A2DD-08002B30309D}" "我的备份"
pause