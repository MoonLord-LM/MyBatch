@echo off
setlocal disabledelayedexpansion
set debug_function=true
set debug_exception=true
::
::
::
::Begin Here
call :main %*
:: Jump to main function









::Function Definition
goto :eof

:main - "主函数(void)，返回void"
    :: for %%i in (%*) do echo %%i
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

:print_array - "打印引号包括起来的字符串数组的详细信息(array_string)，返回void"
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

:search_file - "搜索指定文件夹路径(path_string，.表示当前路径，..表示上一级的路径)中的满足指定模式(pattern_string)的文件名的文件完整路径的列表，并保存到文件(file_string)中，返回void"
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
        :: echo %%i
        :: echo 字节大小：%%~zi
        :: echo 修改日期：%%~ti
        :: echo 文件属性：%%~ai
        :: echo 所在目录：%%~pi
        :: echo 文件名称：%%~ni
        :: echo 扩展名称：%%~xi
        :: echo 完整路径：%%~fi
        :: echo 驱动器号：%%~di
        :: echo 文件短名：%%~si
        :: echo.
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
        :: echo %%i
        :: echo 字节大小：%%~zi
        :: echo 修改日期：%%~ti
        :: echo 目录属性：%%~ai
        :: echo 父级目录：%%~pi
        :: echo 目录名称：%%~ni
        :: echo 扩展名称：%%~xi
        :: echo 完整路径：%%~fi
        :: echo 驱动器号：%%~di
        :: echo 目录短名：%%~si
        :: echo.
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

:append_file - "添加字符串(append_string)到文件(file_string)的末尾（不换行），返回void"
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
    :: 替换引号为空格
    set str=%str:"= %
    :loop
    if not "%str%"=="" (
        set /a string_length_value+=1
        set str=%str:~1%
        goto loop
    )
    call :return %string_length_value%
goto :eof