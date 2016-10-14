setlocal disabledelayedexpansion
set debug_function=false
set debug_exception=false
call :main %*
goto :eof
:main
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
:hello_world
if %debug_function%==true (
echo 【Function】hello_world, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
)
echo Hello World
goto :eof
:set
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
:return
if %debug_function%==true (
echo 【Function】return, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
)
set return=%~1
goto :eof
:input
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
:print
if %debug_function%==true (
echo 【Function】print, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
)
if "%~1"=="" (
if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
goto :eof
)
set /p="%~1" <nul
goto :eof
:function_exists
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
:command_exists
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
:confirm_exit
if %debug_function%==true (
echo 【Function】confirm_exit, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
)
if "%~1"=="" (
if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
goto :eof
)
echo %~1 && pause && cmd && exit
goto :eof
:function_require
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
:command_require
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
:print_array
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
set /a n=+1
echo  - %%i
)
setlocal disabledelayedexpansion
echo ————————————————————————————————————————————————
goto :eof
:is_number
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
:to_lower
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
for %%L in (%Lower%) do set to_lower_value=%%L=%%L
setlocal disabledelayedexpansion
call :return %to_lower_value%
goto :eof
:to_upper
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
for %%U in (%Upper%) do set to_upper_value=%%U=%%U
setlocal disabledelayedexpansion
call :return %to_upper_value%
goto :eof
:search_file
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
:list_file
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
)
goto :eof
:list_dir
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
)
goto :eof
:list_set
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
:print_file
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
:append_file
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
:set_clipboard
if %debug_function%==true (
echo 【Function】set_clipboard, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
)
if "%~1"=="" (
if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
goto :eof
)
mshta vbscript:clipboardData.SetData("text","%~1")(window.close)
goto :eof
:speak_voice
if %debug_function%==true (
echo 【Function】speak_voice, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
)
if "%~1"=="" (
if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
goto :eof
)
mshta vbscript:createobject("sapi.spvoice").speak("%~1")(window.close)
goto :eof
:alert
if %debug_function%==true (
echo 【Function】alert, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
)
if "%~1"=="" (
if %debug_exception%==true echo 【——————Exception——————】参数1不应为空
goto :eof
)
mshta javascript:window.execScript("alert('%~1');window.close();","javascript")
goto :eof
:message_box
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
:popup
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
:string_length
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
