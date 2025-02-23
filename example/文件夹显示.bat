@echo off
if not exist "我的备份.{21EC2020-3AEA-1069-A2DD-08002B30309D}" (
    echo 本批处理用于显示出隐藏的"我的备份"文件夹
    echo 指定的文件夹不存在！
    pause
    exit
)
attrib -h -s "我的备份.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
ren "我的备份.{21EC2020-3AEA-1069-A2DD-08002B30309D}" "我的备份"
echo 已显示"我的备份"文件夹
pause
exit