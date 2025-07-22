@echo off

if not exist "%~dp0changes.patch" (
    echo 脚本所在目录必须有 changes.patch 差异文件
    pause
    exit /b
)

:: 获取拖动到 bat 文件上的输入文件夹路径
set "input_dir=%~1"

if "%input_dir%"=="" (
    echo 请将要处理的 Git 仓库文件夹拖动到此脚本上
    pause
    exit /b
)
if not exist "%input_dir%\" (
    echo 指定的文件夹路径不存在，请不要将单个文件拖动到此脚本上
    pause
    exit /b
)

cd "%input_dir%"
git apply "%~dp0changes.patch"
echo 已导入 "%~dp0changes.patch" 差异文件
echo.

pause
exit
