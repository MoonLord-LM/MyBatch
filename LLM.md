# Prompt for LLM

This file is the prompt content for the LLM.  
Before making any operations, we must first load this file as basic instructions.  
Before making any operations, we must first review the README.md file to understand the entire project.  
Before making any operations, we must first review the coding standards in this file and follow them strictly.  
You can call the `self-check.bat` script, which implements local Git configuration, as well as self-checking and fixing the format of Bat type files.  
When calling PowerShell commands such as Get-Content, Set-Content, and Add-Content, explicitly add -Encoding utf8 to prevent garbled text.  
When reading and writing files, always use the latest version as the standard, no need to care about Git version management, the code has GitHub to fall back on, and will not be lost.  
When recording time, call PowerShell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'" to get accurate time.  
After completing operations, check common batch encoding issues, such as handling of special symbols.  
After completing operations, ensure that the .bat scripts have correct logic.  
After completing operations, ensure that the .md documentation files have accurate content and consistent translation.  
When there are no explicit instructions, perform a complete self-review of this project and only provide review results or modification suggestions.  
After each self-review, evaluate the status (✅/⚠️/⛔), summarize the conclusion in no more than 30 words, translate it into Chinese and English, and record it in the corresponding check result section of this file.  
Sort the self-check result entries by time in descending order, and keep only the latest entry for each LLM.  

## Coding Standards

All text files in the entire project, including code, configurations, and documentation, must strictly use UTF-8 without BOM encoding with \r\n line endings.  

For .md files, prioritize the Chinese text as the source of truth. If there is English content, it must be consistent with the Chinese.  
For .md files, ensure that ordinary single-line text ends with 2 spaces to achieve a line break effect.  

For batch scripts, code readability is prioritized over performance optimization; use simple, easy-to-understand code to implement functionality and reduce comments.  
For batch scripts, the code style (e.g., spacing, logging) should refer to existing code to maintain consistency as much as possible.  
If temporary files need to be generated, use a path like `%temp%\\MyBatch_%random%_%random%_%random%_%random%.tmp` to prevent conflicts, and clean it up before the script ends.  
Try to avoid using English parentheses ( ) or Chinese parentheses （） in echo commands to prevent interference.  
To check if the previous command succeeded/failed, use the `if errorlevel 0/1` syntax, which is more concise; do not use the `%errorlevel%` variable.  
If the script is run as administrator from the right-click menu, it will switch to the system directory by default, but usually the script does not want to change the relative path; refer to the example code for handling.  
When a script exits normally, use `exit /b` to exit; when it exits with an error, use `exit /b 1` to exit.

Example code:
```
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: This line is a comment, used to mark the source or summarize the entire file



if /i "%cd%"=="%SystemRoot%\System32" (
    echo Use "Run as administrator" from right-click menu, switching to script directory & echo.
    cd /d "%~dp0"
)

echo This is the main body of the code
echo Note the fixed 4 lines of code at the beginning and the fixed 3 lines at the end
echo The beginning, summary comment, code body, and end are separated by 3 blank lines
echo A blank line is always reserved at the end of the file



echo.
pause
exit /b

```

## Issues That Can Be Ignored

None  

## Self Check Result

| LLM Version | Time UTC+8 | Status | Conclusion |
| -- | -- | -- | -- |
| DeepSeek Chat | 2026-03-09 07:32:40 | ✅ | Checked and fixed encoding standards for all .bat files, ensuring UTF-8 without BOM and CRLF line endings. |

# LLM 提示

本文档是给 LLM 使用的提示信息。  
在做任何操作前，需要先加载本文档作为基础指令。  
在做任何操作前，需要先查看 README.md 文件，理解整个工程。  
在做任何操作前，需要先查看本文档约定的编码规范，严格按规范执行。  
可以调用 `self-check.bat` 脚本，其中实现了本地的 Git 配置，以及 Bat 类型文件的格式的自检和修复。  
在调用 PowerShell 的 Get-Content、Set-Content、Add-Content 等命令时，必须显式添加 -Encoding utf8 参数，防止乱码。  
在读写文件时，始终以最新版本为准，不需要关心 Git 版本管理，代码有 GitHub 兜底，不会丢失。  
在记录时间时，调用 PowerShell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'" 获取准确的时间。  
做完操作之后，检查批处理常见编码问题，例如特殊符号处理。  
做完操作之后，注意检查 .bat 脚本逻辑是否正确。  
做完操作之后，注意检查 .md 说明文件是否内容准确，且翻译一致。  
当没有明确指令时，对本工程做完整的自检审查，给出审查结果或修改建议。  
每次自检审查后，评估状态（✅/⚠️/⛔），将结论简单概括不超过 30 字，翻译为对应语言，然后记录到本文件的自检结果对应位置。  
自检结果的条目按时间倒序排列，并且每个 LLM 只记录最新的一条。  

## 编码规范

整个工程的代码、配置、说明等各种文本文件，严格使用 UTF-8 without BOM 编码，\r\n 换行。  

处理 .md 文件时，优先以中文为准，如果有英文内容，需与中文保持一致。  
处理 .md 文件时，要保证普通单行文本的结尾要有 2 个空格，以实现换行效果。  

对于批处理脚本，代码易读优先于性能优化，优先使用简单易懂的代码实现功能，减少注释。  
批处理脚本的代码风格（如空格、日志等）参考现有代码，尽量保持一致。  
如果需要生成临时文件，使用 `%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp` 这样的路径防止冲突，并且在脚本结束前做清理。  
尽量避免在 echo 命令中，使用英文的括号 ( ) 或中文的括号（）符号，避免干扰。  
判断上一条命令是否成功/失败，用 if errorlevel 0/1 的写法，比较简洁，不要用 %errorlevel% 变量。  
脚本如果用右键的"以管理员权限运行"，默认会切换到系统目录，而通常脚本并不想改变相对路径，参照示例代码处理。  
脚本正常结束时，使用 exit /b 退出，异常结束时，使用 exit /b 1 退出。  

示例代码：
```
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 这一行是注释，对整个文件进行出处标注或者总结说明



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的"以管理员权限运行"，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

echo 这里是代码正文
echo 注意开头的固定 4 行代码和结尾的固定 3 行代码
echo 开头、总结注释、代码主体、结尾，中间固定隔开 3 行
echo 文件末尾固定保留 1 个空行



echo.
pause
exit /b

```

## 可忽略问题

无  

## 自检结果

| LLM 版本 | 时间 UTC+8 | 状态 | 结论 |
| -- | -- | -- | -- |
| DeepSeek Chat | 2026-03-09 07:32:40 | ✅ | 检查并修复了所有.bat文件的编码规范，确保UTF-8 without BOM和CRLF换行。 |
