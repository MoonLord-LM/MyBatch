@echo off

if exist "%~dp0changes.patch" (
    echo 脚本所在目录已存在 changes.patch 差异文件，将被覆盖
    pause
    echo.
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
git add .
git diff HEAD --output="%~dp0changes.patch"
echo 已生成 "%~dp0changes.patch" 差异文件
echo.

pause
exit
