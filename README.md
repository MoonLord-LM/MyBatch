# MyBatch
A function library for the Windows Batch.  
  
## [简介]
Windows 批处理函数库，对常用的批处理代码进行了收集整理  

## [示例]
请查看<a href="example\">【example】</a>文件夹中的 ".bat" 文件  

## [说明]
- 默认字符编码：Chinese (GBK)  
- 开发测试环境：Windows 7 + Visual Studio Code  

## [笔记]
01. 使 Visual Studio Code 自动识别批处理中的中文GBK编码：  
    文件-首选项-设置，在 settings.json 中添加一项 "files.autoGuessEncoding": true  
02. 批处理中的注释方法：  
    :: 注释内容  
    rem 注释内容  
    :标签 注释内容  
    goto 标签 注释内容  
    echo 注释内容 〉nul  
    if not exist nul 注释内容  
03. \> 覆盖文件内容，>> 追加内容到文件末尾  
    \>nul 和 1>nul 屏蔽结果输出，2>nul 屏蔽错误输出  
04. goto :eof 和 exit /b 0 结束批处理或函数标签的执行，exit 关闭控制台窗口  
05. :main 定义一个名为main的函数标签  
    要注意函数前后必须用 goto :eof 与其它命令隔开，因此通常将函数定义放在批处理文件末尾  
    call :main aaa %bbb% 调用函数，并传递两个参数，其中 aaa 为引用传递，%bbb% 为值传递  
    函数内部通过 %1 和 %~1 取出外部传递的参数（最多9个），%~1 会删除参数首尾的双引号  
    call :main %* 将当前环境的所有参数 %* 完整传递给子函数  
06. 变量的声明和赋值格式如下，set 默认声明为全局变量  
    set /a n=0  
    set /a n+=1  
    在 setlocal ，和 endlocal (或 goto :eof) 之间 set 的值为临时变量  
07. 检验变量是否定义过：  
    if defined str1 ( echo str已经被定义 ) else ( echo str没有被定义 )  
    要注意 if、条件语句、else 都要和左右的括号以空格隔开，否则会报错，语法不正确
08. if errorlevel 1 上个命令的返回值大于等于1，if %errorlevel%==1 上个命令的返回值等于1  
    数值大小比较需要使用：equ 等于、neq 不等于、lss 小于、leq 小于或等于、gtr 大于、geq 大于或等于  
    如果执行一条命令，使得 %errorlevel% 变为大于1，那么可以在这条命令的后面直接加上 && echo 正常执行 || echo 执行出错  
09. setlocal enabledelayedexpansion 延迟环境变量扩展  
    将叹号 ! 视为特殊字符，两个 ! 包含的变量的值，会动态进行解释，通常与for一起用  
    在for循环中，想要读取变量的值，需要使用 !n! 的形式，否则会由于批处理的预处理，n 始终为循环外的值  
    在for循环中，/L 参数表示以 (start, step, end) 的范围取值  
    在for循环中，%%i 
    输出 0123456789 的代码示例：  
    @echo off
    setlocal enabledelayedexpansion
    for %%i in (0 1 2 3 4 5 6 7 8 9) do echo %%i  
    for /l %%i in (0, 1, 9) do echo %%i  
    for /l %%i in (0, 1, 9) do (set a=%%i && echo !a!)  
10. ^ 为转义字符，例如 echo test^>1.txt 只会输出字符串 test>1.txt  
11. 在批处理中执行 cmd 命令会进入等待输入输出的状态，栈的深度增加，需要调用 exit 才会退出当前cmd栈  
    使用 call 1.bat ，即可在例如 2.bat 中调用 1.bat 并继续执行，直接使用 1.bat，则会在执行完 1.bat 后退出  
12. %cd%、%~dp0 代表当前执行的批处理的文件夹路径，区别在于 %~dp0 以 \ 结尾  
    %0 代表当前执行的批处理的文件名（不包含扩展名，例如 test）
    %~n0%~x0 代表当前执行的批处理的完整文件名（包含扩展名，例如 test.bat）
13. 字符串替换，set "a=%a:b=c%" ，意思是在字符串 a 中替换 b 为 c  
    例如 set str=!str:"= ! ，将引号替换为空格  
14. 命令太长需要换行写时，在行尾以一个空格，和一个 ^ 符号（Shift+6）结束