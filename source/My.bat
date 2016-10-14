@echo off
setlocal disabledelayedexpansion
set debug_function=true
set debug_exception=true
::
::
::
::提示：“::”和“rem”注释整行
::提示：“>nul”和“1>nul”屏蔽执行结果，“2>nul”屏蔽执行错误
::提示：“goto :eof”和“exit /b 0”结束批处理执行或函数执行，“exit”关闭控制台窗口
::提示：“setlocal enabledelayedexpansion”延迟环境变量扩展，会导致叹号!变为特殊字符，!包含的变量的值会逐句进行解释，通常与for一起用
::提示：在for循环中不断修改的外部变量的值，需要使用“!n!”的形式进行读取，否则读取的为循环外的值
::提示：“>”覆盖文件内容，“>>”追加内容到文件末尾
::提示：“:main”定义一个名为main的函数
::提示：要注意函数前后必须用“goto :eof”与其它命令隔开，因此通常将函数定义放在批处理文件末尾
::提示：“call :main”调用函数，函数中通过“%1”和“%~1”取出第一个传递的参数，“%~1”会删除首尾的双引号
::提示：“%*”为全部的命令行参数，可多于9个，可通过“call :main %*”将其传递给子函数
::提示：“call :main aaa”参数为引用传递，“call :main %aaa%”参数为值传递，
::提示：“if errorlevel 1”上个命令的返回值大于等于1，“if %errorlevel%==1”上个命令的返回值等于1
::提示：数值比较，equ等于、neq不等于、lss小于、leq小于或等于、gtr大于、geq大于或等于
::提示：声明变量和赋值，“set /a n=0”，“set /a n+=1”，默认声明为全局变量
::提示：“setlocal”，和“endlocal”、“goto :eof”之间set的值会被认为是临时变量
::提示：“if”、条件语句、“else”，都要和左右括号隔开，否则会报错，语法不正确
::提示：“for %%i in (1 2 3 4 5) do echo %%i”，数组的声明和遍历
::提示：“for /l %%i in (1,1,5) do echo %%i”，/l参数表示以(start,step,end)范围取i值
::提示：“^”为转义字符，例如“echo test^>1.txt”只会输出字符串"test>1.txt"
::提示：如果执行一条命令，使得“%errorlevel%”变为1，那么可以在这条命令的后面直接加上“ && echo 正常 || echo 出错”
::提示：执行“cmd”命令会进入等待输入输出的状态，栈的深度增加，并且不调用exit就不会退出当前cmd栈
::提示：使用“call 1.bat”，即可在例如“2.bat”中调用“1.bat”并继续执行，直接“1.bat”，则会在执行完“1.bat”后退出
::提示：“%cd%”、“%~dp0”代表当前执行的批处理的文件夹路径，区别在于后者以“\”结尾，“%0”代表当前执行的批处理的文件名
::提示：“set "aa=%aa:中国=中华人民共和国%"”，意思是在字符串“aa”中替换“中国”为“中华人民共和国”
::提示：在for /f中使用“usebackq”，括号中的file-set，无论加不加引号，都会被认为是文件，同时，加“'”会被认为是字符串，加“`”会被认为是命令
::提示：在for /f中，“eol=;”忽略分号开头的行，“skip=2”跳过开头2行，“delims=, ”使用逗号和空格分隔字符串
::提示：在for /f中，“tokens=1,2*”将第一个匹配到的分配给%%i，第二个分配给%%j，剩余的分配给%%k，以此类推
::提示；在计算字符串长度的时候，“set str=!str:"= !”，将引号“"”替换为空格“ ”，避免出现语法错误
::提示：在传递参数的时候，要注意“!”或“"”，尤其是奇数个的时候，会因为转义的问题而导致参数粘连、语法错误等等问题
::
::
::
::Begin Here
call :main %*
rem cmd && exit









::Function Definition
goto :eof

:main - "主函数(void)，返回void"
    rem for %%i in (%*) do echo %%i
    if %debug_function%==true (
        echo 【Function】main, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if not "%~1"=="" (
        if "%~1"=="call" (
            call :function_require %~2
            call :%~2 "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
        ) else if "%~1"=="echo" (
            call %~1 %~2 %~3 %~4 %~5 %~6 %~7 %~8 %~9
        ) else if "%~1"=="cmd" (
            call :command_require %~2
            call %~2 "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
        ) else (
            call :command_require %~1
            call %~1 "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
        )
    )
goto :eof

:hello_world - "输出Hello World(void)，返回void"
    if %debug_function%==true (
        echo 【Function】hello_world, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    echo Hello World
goto :eof

:set - "设置公共变量(public_key)的值为(public_value)，返回void"
    if %debug_function%==true (
        echo 【Function】set, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数2不应为空
        goto :eof
    )
    set %~1=%~2
goto :eof

:return - "保存函数返回值(return_value)到公共变量%return%中，返回void"
    if %debug_function%==true (
        echo 【Function】return, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    set return=%~1
goto :eof

:input - "输出提示信息(message_string)，提示用户输入一个字符串，返回值%input_value%"
    if %debug_function%==true (
        echo 【Function】input, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    set /p input_value=%~1
    call :return %input_value%
goto :eof

:print - "输出提示信息(message_string)，返回void"
    if %debug_function%==true (
        echo 【Function】print, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    set /p="%~1" <nul
goto :eof

:function_exists - "判断内部命令(function_name)是否存在，返回值%function_exists_value%：0不存在，1存在"
    if %debug_function%==true (
        echo 【Function】function_exists, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    set /a function_exists_value=1
    call :%~1 1>nul 2>nul
    if %errorlevel%==1 (
        set /a function_exists_value=0
    )
    call :return %function_exists_value% %errorlevel%
goto :eof

:command_exists - "判断外部命令(command_name)是否存在，返回值%command_exists_value%：0不存在，1存在"
    if %debug_function%==true (
        echo 【Function】command_exists, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    set /a command_exists_value=1
    call %~1 1>nul 2>nul
    if %errorlevel%==9009 (
        set /a command_exists_value=0
    )
    call :return %command_exists_value% %errorlevel%
goto :eof

:confirm_exit - "退出当前批处理，并输出一行提示信息(exit_message)，以及：请按任意键继续...，返回void"
    if %debug_function%==true (
        echo 【Function】confirm_exit, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    echo %~1 && pause && cmd && exit
goto :eof

:function_require - "检验内部命令(function_name)必须存在，否则报错退出，返回void"
    if %debug_function%==true (
        echo 【Function】function_require, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    call :function_exists %~1
    if %function_exists_value%==0 (
        call :confirm_exit 【%~1】不是内部命令
    )
goto :eof

:command_require - "检验外部命令(command_name)必须存在，否则报错退出，返回void"
    if %debug_function%==true (
        echo 【Function】command_require, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    call :command_exists %~1
    if %command_exists_value%==0 (
        call :confirm_exit 【%~1】不是外部命令，也不是可运行的程序或批处理文件
    )
goto :eof

:print_array - "打印数组信息(array_string)，返回void"
    if %debug_function%==true (
        echo 【Function】print_array, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    echo ————————————————————————————————————————————————
    setlocal
    set /a n=0
    setlocal enabledelayedexpansion
    for %%i in (
        %~1
    ) do (
        set /a n=!n!+1
        echo !n! - %%i
    )
    setlocal disabledelayedexpansion
    echo ————————————————————————————————————————————————
goto :eof

:is_number - "判断字符串参数(source_string)是否为0-9的数字构成，返回值%is_number_value%：0否，1是"
    if %debug_function%==true (
        echo 【Function】is_number, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    set /a is_number_value=1
    echo %~1|findstr /be "[0-9]*" 1>nul 2>nul
    if %errorlevel%==1 (
        set /a is_number_value=0
    )
    call :return %is_number_value% %errorlevel%
goto :eof

:to_lower - "将字符串参数(source_string)中的大写字母A-Z转换为小写a-z，返回值%to_lower_value%：小写的字符串"
    if %debug_function%==true (
        echo 【Function】to_lower, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    set "Lower=a b c d e f g h i j k l m n o p q r s t u v w x y z"
    set to_lower_value=%~1
    setlocal enabledelayedexpansion
    for %%L in (%Lower%) do set to_lower_value=!to_lower_value:%%L=%%L!
    setlocal disabledelayedexpansion
    call :return %to_lower_value%
goto :eof

:to_upper - "将字符串参数(source_string)中的小写a-z转换为大写字母A-Z，返回值%to_upper_value%：大写的字符串"
    if %debug_function%==true (
        echo 【Function】to_upper, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    set "Upper=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
    set to_upper_value=%~1
    setlocal enabledelayedexpansion
    for %%U in (%Upper%) do set to_upper_value=!to_upper_value:%%U=%%U!
    setlocal disabledelayedexpansion
    call :return %to_upper_value%
goto :eof

:search_file - "搜索指定文件夹路径(path_string)中的满足指定模式(pattern_string)的文件名的文件完整路径的列表，并保存到文件(file_string)中，返回void"
    if %debug_function%==true (
        echo 【Function】search_file, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数2不应为空
        goto :eof
    )
    if "%~3"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数3不应为空
        goto :eof
    )
    del "%~3" 1>nul 2>nul
    for /r "%~1" %%i in ("%~2") do (
        echo %%i>>"%~3"
    )
goto :eof

:list_file - "获取指定文件夹路径(path_string，.表示当前路径，..表示上一级的路径)中的文件名称的列表，不递归搜索，并保存到文件(file_string)中，返回void"
    if %debug_function%==true (
        echo 【Function】list_file, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数2不应为空
        goto :eof
    )
    del "%~2" 1>nul 2>nul
    for /f "usebackq delims=" %%i in (`dir "%~1" /b /a-d`) do (
        echo %%i>>"%~2"
        rem echo %%i
        rem echo 字节大小：%%~zi
        rem echo 修改日期：%%~ti
        rem echo 文件属性：%%~ai
        rem echo 文件短名：%%~si
        rem echo 扩展名称：%%~xi
        rem echo 文件命名：%%~ni
        rem echo 所在路径：%%~pi
        rem echo 驱动器号：%%~di
        rem echo 完整路径：%%~fi
        rem echo.
    )
goto :eof

:list_dir - "获取指定文件夹路径(path_string，.表示当前路径，..表示上一级的路径)中的文件夹名称的列表，不递归搜索，并保存到文件(file_string)中，返回void"
    if %debug_function%==true (
        echo 【Function】list_dir, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数2不应为空
        goto :eof
    )
    del "%~2" 1>nul 2>nul
    for /f "usebackq delims=" %%i in (`dir "%~1" /b /ad`) do (
        echo %%i>>"%~2"
        rem echo %%i
        rem echo 字节大小：%%~zi
        rem echo 修改日期：%%~ti
        rem echo 文件属性：%%~ai
        rem echo 文件短名：%%~si
        rem echo 扩展名称：%%~xi
        rem echo 文件命名：%%~ni
        rem echo 所在路径：%%~pi
        rem echo 驱动器号：%%~di
        rem echo 完整路径：%%~fi
        rem echo.
    )
goto :eof

:list_set - "获取环境变量的值，并保存到文件(file_string)中，返回void"
    if %debug_function%==true (
        echo 【Function】list_dir, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    del "%~1" 1>nul 2>nul
    for /f "usebackq tokens=1* delims==" %%i in (`set`) do (
        echo %%i=%%j>>"%~1"
    )
goto :eof

:print_file - "打印指定文件(file_string)的有效内容，忽略空行、文件末尾的换行符，返回void"
    if %debug_function%==true (
        echo 【Function】print_file, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    for /f "usebackq delims=" %%i in ("%~1") do (
        echo %%i
    )
goto :eof

:append_file - "添加字符串(append_string)到文件(file_string)的末尾，返回void"
    if %debug_function%==true (
        echo 【Function】append_file, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数2不应为空
        goto :eof
    )
    set /p="%~1" <nul >>"%~2"
goto :eof

:set_clipboard - "复制字符串(copy_string)到剪贴板，返回void"
    if %debug_function%==true (
        echo 【Function】set_clipboard, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    mshta vbscript:clipboardData.SetData("text","%~1")(window.close)
goto :eof

:speak_voice - "使用Microsoft Speech API语音朗读字符串(speak_string)，返回void"
    if %debug_function%==true (
        echo 【Function】speak_voice, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    mshta vbscript:createobject("sapi.spvoice").speak("%~1")(window.close)
goto :eof

:alert - "弹出JavaScript提示框(alert_string)，返回void"
    if %debug_function%==true (
        echo 【Function】alert, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    mshta javascript:window.execScript("alert('%~1');window.close();","javascript")
goto :eof

:message_box - "弹出VisualBasicScript提示框，提示信息(message_string)，标题(title_string)，返回void"
    if %debug_function%==true (
        echo 【Function】message_box, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数2不应为空
        goto :eof
    )
    mshta vbscript:window.execScript("msgbox ""%~1"",64,""%~2"":window.close","vbs")
goto :eof

:popup - "弹出VisualBasicScript提示框，提示信息(message_string)，标题(title_string)，返回void"
    if %debug_function%==true (
        echo 【Function】popup, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数2不应为空
        goto :eof
    )
    mshta vbscript:CreateObject("Wscript.Shell").popup("%~1",7,"%~2",64)(window.close)
goto :eof

:string_length - "获取字符串参数(source_string)的长度，返回值%string_length_value%：字符串长度"
    if %debug_function%==true (
        echo 【Function】string_length, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
        goto :eof
    )
    set /a string_length_value=0
    setlocal
    set str=%~1
    set str=%str:"= %
    :loop
    if not "%str%"=="" (
        set /a string_length_value+=1
        set str=%str:~1%
        goto loop
    )
    call :return %string_length_value%
goto :eof




















