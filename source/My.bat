@echo off
setlocal disabledelayedexpansion
set debug_function=true
set debug_exception=true
::
::
::
::��ʾ����::���͡�rem��ע������
::��ʾ����>nul���͡�1>nul������ִ�н������2>nul������ִ�д���
::��ʾ����goto :eof���͡�exit /b 0������������ִ�л���ִ�У���exit���رտ���̨����
::��ʾ����setlocal enabledelayedexpansion���ӳٻ���������չ���ᵼ��̾��!��Ϊ�����ַ���!�����ı�����ֵ�������н��ͣ�ͨ����forһ����
::��ʾ����forѭ���в����޸ĵ��ⲿ������ֵ����Ҫʹ�á�!n!������ʽ���ж�ȡ�������ȡ��Ϊѭ�����ֵ
::��ʾ����>�������ļ����ݣ���>>��׷�����ݵ��ļ�ĩβ
::��ʾ����:main������һ����Ϊmain�ĺ���
::��ʾ��Ҫע�⺯��ǰ������á�goto :eof��������������������ͨ����������������������ļ�ĩβ
::��ʾ����call :main�����ú�����������ͨ����%1���͡�%~1��ȡ����һ�����ݵĲ�������%~1����ɾ����β��˫����
::��ʾ����%*��Ϊȫ���������в������ɶ���9������ͨ����call :main %*�����䴫�ݸ��Ӻ���
::��ʾ����call :main aaa������Ϊ���ô��ݣ���call :main %aaa%������Ϊֵ���ݣ�
::��ʾ����if errorlevel 1���ϸ�����ķ���ֵ���ڵ���1����if %errorlevel%==1���ϸ�����ķ���ֵ����1
::��ʾ����ֵ�Ƚϣ�equ���ڡ�neq�����ڡ�lssС�ڡ�leqС�ڻ���ڡ�gtr���ڡ�geq���ڻ����
::��ʾ�����������͸�ֵ����set /a n=0������set /a n+=1����Ĭ������Ϊȫ�ֱ���
::��ʾ����setlocal�����͡�endlocal������goto :eof��֮��set��ֵ�ᱻ��Ϊ����ʱ����
::��ʾ����if����������䡢��else������Ҫ���������Ÿ���������ᱨ���﷨����ȷ
::��ʾ����for %%i in (1 2 3 4 5) do echo %%i��������������ͱ���
::��ʾ����for /l %%i in (1,1,5) do echo %%i����/l������ʾ��(start,step,end)��Χȡiֵ
::��ʾ����^��Ϊת���ַ������硰echo test^>1.txt��ֻ������ַ���"test>1.txt"
::��ʾ�����ִ��һ�����ʹ�á�%errorlevel%����Ϊ1����ô��������������ĺ���ֱ�Ӽ��ϡ� && echo ���� || echo ����
::��ʾ��ִ�С�cmd����������ȴ����������״̬��ջ��������ӣ����Ҳ�����exit�Ͳ����˳���ǰcmdջ
::��ʾ��ʹ�á�call 1.bat�������������硰2.bat���е��á�1.bat��������ִ�У�ֱ�ӡ�1.bat���������ִ���ꡰ1.bat�����˳�
::��ʾ����%cd%������%~dp0������ǰִ�е���������ļ���·�����������ں����ԡ�\����β����%0������ǰִ�е���������ļ���
::��ʾ����set "aa=%aa:�й�=�л����񹲺͹�%"������˼�����ַ�����aa�����滻���й���Ϊ���л����񹲺͹���
::��ʾ����for /f��ʹ�á�usebackq���������е�file-set�����ۼӲ������ţ����ᱻ��Ϊ���ļ���ͬʱ���ӡ�'���ᱻ��Ϊ���ַ������ӡ�`���ᱻ��Ϊ������
::��ʾ����for /f�У���eol=;�����Էֺſ�ͷ���У���skip=2��������ͷ2�У���delims=, ��ʹ�ö��źͿո�ָ��ַ���
::��ʾ����for /f�У���tokens=1,2*������һ��ƥ�䵽�ķ����%%i���ڶ��������%%j��ʣ��ķ����%%k���Դ�����
::��ʾ���ڼ����ַ������ȵ�ʱ�򣬡�set str=!str:"= !���������š�"���滻Ϊ�ո� ������������﷨����
::��ʾ���ڴ��ݲ�����ʱ��Ҫע�⡰!����"������������������ʱ�򣬻���Ϊת�����������²���ճ�����﷨����ȵ�����
::
::
::
::Begin Here
call :main %*
rem cmd && exit









::Function Definition
goto :eof

:main - "������(void)������void"
    rem for %%i in (%*) do echo %%i
    if %debug_function%==true (
        echo ��Function��main, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
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

:hello_world - "���Hello World(void)������void"
    if %debug_function%==true (
        echo ��Function��hello_world, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    echo Hello World
goto :eof

:set - "���ù�������(public_key)��ֵΪ(public_value)������void"
    if %debug_function%==true (
        echo ��Function��set, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo ��������������Exception������������������2��ӦΪ��
        goto :eof
    )
    set %~1=%~2
goto :eof

:return - "���溯������ֵ(return_value)����������%return%�У�����void"
    if %debug_function%==true (
        echo ��Function��return, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    set return=%~1
goto :eof

:input - "�����ʾ��Ϣ(message_string)����ʾ�û�����һ���ַ���������ֵ%input_value%"
    if %debug_function%==true (
        echo ��Function��input, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    set /p input_value=%~1
    call :return %input_value%
goto :eof

:print - "�����ʾ��Ϣ(message_string)������void"
    if %debug_function%==true (
        echo ��Function��print, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    set /p="%~1" <nul
goto :eof

:function_exists - "�ж��ڲ�����(function_name)�Ƿ���ڣ�����ֵ%function_exists_value%��0�����ڣ�1����"
    if %debug_function%==true (
        echo ��Function��function_exists, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    set /a function_exists_value=1
    call :%~1 1>nul 2>nul
    if %errorlevel%==1 (
        set /a function_exists_value=0
    )
    call :return %function_exists_value% %errorlevel%
goto :eof

:command_exists - "�ж��ⲿ����(command_name)�Ƿ���ڣ�����ֵ%command_exists_value%��0�����ڣ�1����"
    if %debug_function%==true (
        echo ��Function��command_exists, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    set /a command_exists_value=1
    call %~1 1>nul 2>nul
    if %errorlevel%==9009 (
        set /a command_exists_value=0
    )
    call :return %command_exists_value% %errorlevel%
goto :eof

:confirm_exit - "�˳���ǰ�����������һ����ʾ��Ϣ(exit_message)���Լ����밴���������...������void"
    if %debug_function%==true (
        echo ��Function��confirm_exit, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    echo %~1 && pause && cmd && exit
goto :eof

:function_require - "�����ڲ�����(function_name)������ڣ����򱨴��˳�������void"
    if %debug_function%==true (
        echo ��Function��function_require, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    call :function_exists %~1
    if %function_exists_value%==0 (
        call :confirm_exit ��%~1�������ڲ�����
    )
goto :eof

:command_require - "�����ⲿ����(command_name)������ڣ����򱨴��˳�������void"
    if %debug_function%==true (
        echo ��Function��command_require, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    call :command_exists %~1
    if %command_exists_value%==0 (
        call :confirm_exit ��%~1�������ⲿ���Ҳ���ǿ����еĳ�����������ļ�
    )
goto :eof

:print_array - "��ӡ������Ϣ(array_string)������void"
    if %debug_function%==true (
        echo ��Function��print_array, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    echo ������������������������������������������������������������������������������������������������
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
    echo ������������������������������������������������������������������������������������������������
goto :eof

:is_number - "�ж��ַ�������(source_string)�Ƿ�Ϊ0-9�����ֹ��ɣ�����ֵ%is_number_value%��0��1��"
    if %debug_function%==true (
        echo ��Function��is_number, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    set /a is_number_value=1
    echo %~1|findstr /be "[0-9]*" 1>nul 2>nul
    if %errorlevel%==1 (
        set /a is_number_value=0
    )
    call :return %is_number_value% %errorlevel%
goto :eof

:to_lower - "���ַ�������(source_string)�еĴ�д��ĸA-Zת��ΪСдa-z������ֵ%to_lower_value%��Сд���ַ���"
    if %debug_function%==true (
        echo ��Function��to_lower, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    set "Lower=a b c d e f g h i j k l m n o p q r s t u v w x y z"
    set to_lower_value=%~1
    setlocal enabledelayedexpansion
    for %%L in (%Lower%) do set to_lower_value=!to_lower_value:%%L=%%L!
    setlocal disabledelayedexpansion
    call :return %to_lower_value%
goto :eof

:to_upper - "���ַ�������(source_string)�е�Сдa-zת��Ϊ��д��ĸA-Z������ֵ%to_upper_value%����д���ַ���"
    if %debug_function%==true (
        echo ��Function��to_upper, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    set "Upper=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
    set to_upper_value=%~1
    setlocal enabledelayedexpansion
    for %%U in (%Upper%) do set to_upper_value=!to_upper_value:%%U=%%U!
    setlocal disabledelayedexpansion
    call :return %to_upper_value%
goto :eof

:search_file - "����ָ���ļ���·��(path_string)�е�����ָ��ģʽ(pattern_string)���ļ������ļ�����·�����б������浽�ļ�(file_string)�У�����void"
    if %debug_function%==true (
        echo ��Function��search_file, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo ��������������Exception������������������2��ӦΪ��
        goto :eof
    )
    if "%~3"=="" (
        if %debug_exception%==true echo ��������������Exception������������������3��ӦΪ��
        goto :eof
    )
    del "%~3" 1>nul 2>nul
    for /r "%~1" %%i in ("%~2") do (
        echo %%i>>"%~3"
    )
goto :eof

:list_file - "��ȡָ���ļ���·��(path_string��.��ʾ��ǰ·����..��ʾ��һ����·��)�е��ļ����Ƶ��б����ݹ������������浽�ļ�(file_string)�У�����void"
    if %debug_function%==true (
        echo ��Function��list_file, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo ��������������Exception������������������2��ӦΪ��
        goto :eof
    )
    del "%~2" 1>nul 2>nul
    for /f "usebackq delims=" %%i in (`dir "%~1" /b /a-d`) do (
        echo %%i>>"%~2"
        rem echo %%i
        rem echo �ֽڴ�С��%%~zi
        rem echo �޸����ڣ�%%~ti
        rem echo �ļ����ԣ�%%~ai
        rem echo �ļ�������%%~si
        rem echo ��չ���ƣ�%%~xi
        rem echo �ļ�������%%~ni
        rem echo ����·����%%~pi
        rem echo �������ţ�%%~di
        rem echo ����·����%%~fi
        rem echo.
    )
goto :eof

:list_dir - "��ȡָ���ļ���·��(path_string��.��ʾ��ǰ·����..��ʾ��һ����·��)�е��ļ������Ƶ��б����ݹ������������浽�ļ�(file_string)�У�����void"
    if %debug_function%==true (
        echo ��Function��list_dir, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo ��������������Exception������������������2��ӦΪ��
        goto :eof
    )
    del "%~2" 1>nul 2>nul
    for /f "usebackq delims=" %%i in (`dir "%~1" /b /ad`) do (
        echo %%i>>"%~2"
        rem echo %%i
        rem echo �ֽڴ�С��%%~zi
        rem echo �޸����ڣ�%%~ti
        rem echo �ļ����ԣ�%%~ai
        rem echo �ļ�������%%~si
        rem echo ��չ���ƣ�%%~xi
        rem echo �ļ�������%%~ni
        rem echo ����·����%%~pi
        rem echo �������ţ�%%~di
        rem echo ����·����%%~fi
        rem echo.
    )
goto :eof

:list_set - "��ȡ����������ֵ�������浽�ļ�(file_string)�У�����void"
    if %debug_function%==true (
        echo ��Function��list_dir, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    del "%~1" 1>nul 2>nul
    for /f "usebackq tokens=1* delims==" %%i in (`set`) do (
        echo %%i=%%j>>"%~1"
    )
goto :eof

:print_file - "��ӡָ���ļ�(file_string)����Ч���ݣ����Կ��С��ļ�ĩβ�Ļ��з�������void"
    if %debug_function%==true (
        echo ��Function��print_file, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    for /f "usebackq delims=" %%i in ("%~1") do (
        echo %%i
    )
goto :eof

:append_file - "����ַ���(append_string)���ļ�(file_string)��ĩβ������void"
    if %debug_function%==true (
        echo ��Function��append_file, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo ��������������Exception������������������2��ӦΪ��
        goto :eof
    )
    set /p="%~1" <nul >>"%~2"
goto :eof

:set_clipboard - "�����ַ���(copy_string)�������壬����void"
    if %debug_function%==true (
        echo ��Function��set_clipboard, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    mshta vbscript:clipboardData.SetData("text","%~1")(window.close)
goto :eof

:speak_voice - "ʹ��Microsoft Speech API�����ʶ��ַ���(speak_string)������void"
    if %debug_function%==true (
        echo ��Function��speak_voice, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    mshta vbscript:createobject("sapi.spvoice").speak("%~1")(window.close)
goto :eof

:alert - "����JavaScript��ʾ��(alert_string)������void"
    if %debug_function%==true (
        echo ��Function��alert, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    mshta javascript:window.execScript("alert('%~1');window.close();","javascript")
goto :eof

:message_box - "����VisualBasicScript��ʾ����ʾ��Ϣ(message_string)������(title_string)������void"
    if %debug_function%==true (
        echo ��Function��message_box, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo ��������������Exception������������������2��ӦΪ��
        goto :eof
    )
    mshta vbscript:window.execScript("msgbox ""%~1"",64,""%~2"":window.close","vbs")
goto :eof

:popup - "����VisualBasicScript��ʾ����ʾ��Ϣ(message_string)������(title_string)������void"
    if %debug_function%==true (
        echo ��Function��popup, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
        goto :eof
    )
    if "%~2"=="" (
        if %debug_exception%==true echo ��������������Exception������������������2��ӦΪ��
        goto :eof
    )
    mshta vbscript:CreateObject("Wscript.Shell").popup("%~1",7,"%~2",64)(window.close)
goto :eof

:string_length - "��ȡ�ַ�������(source_string)�ĳ��ȣ�����ֵ%string_length_value%���ַ�������"
    if %debug_function%==true (
        echo ��Function��string_length, parameter:%~1,%~2,%~3,%~4,%~5,%~6,%~7,%~8,%~9
    )
    if "%~1"=="" (
        if %debug_exception%==true echo ��������������Exception������������������1��ӦΪ��
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




















