@echo off
::
::
::
::MyBatch���봦��
::
::
::
setlocal enabledelayedexpansion
echo ���������Ϣ����
del /q "help\*"
set /? >"help\set.txt"
for /? >"help\for.txt"
del /? >"help\del.txt"
dir /? >"help\dir.txt"
tree /? >"help\tree.txt"
goto /? >"help\goto.txt"
call /? >"help\call.txt"
copy /? >"help\copy.txt"
shift /? >"help\shift.txt"
setlocal /? >"help\setlocal.txt"

echo �ļ�����������
del /q "bin\*"
copy /y "My.bat" "bin\My.bat" 1>nul
copy /y "Test.bat" "bin\Test.bat" 1>nul

echo �������������
for /f "usebackq delims=" %%i in ("bin\My.bat") do (
    set line=%%i
    set line=!line:	= !
    set begin1=!line:~0,1!
    for /l %%j in (1,1,256) do (
        if "!begin1!"==" " (
            set line=!line:~1!
            set begin1=!line:~0,1!
        )
    )
    set begin2=!line:~0,2!
    set begin3=!line:~0,3!
    if "!line!"=="set debug_function=true" (
        set line=set debug_function=false
    )
    if "!line!"=="set debug_exception=true" (
        set line=set debug_exception=false
    )
    rem echo !begin1! !begin2! !begin3!
    if not "!begin1!"=="@" (
        if not "!begin2!"=="::" (
            if not "!begin3!"=="rem" (
                echo !line!>>"bin\tmp.bat"
            )
        )
    )
)
copy /y "bin\tmp.bat" "bin\My.bat" 1>nul
del /q "bin\tmp.bat"

echo ������δ�����
for /f "usebackq delims=" %%i in ("bin\My.bat") do (
    set line=%%i
    set line=!line:	= !
    set begin=!line:~0,1!
    set tmp=!line:~0,1!
    set left=!tmp!
	set ok=false
    for /l %%j in (1,1,256) do (
		if "!ok!"=="false" (
			if not "!line:~2,1!"=="-" (
				if not "!line:~1!"=="" (
					set line=!line:~1!
					set tmp=!line:~0,1!
					set left=!left!!tmp!
					rem echo !line! !tmp! !left!
				)
			) else (
				if "!begin!"==":" (
					set ok=true
				) else (
					set line=!line:~1!
					set tmp=!line:~0,1!
					set left=!left!!tmp!
				)
			)
		)
    )
	echo !left!>>"bin\tmp.bat"
)
copy /y "bin\tmp.bat" "bin\My.bat" 1>nul
del /q "bin\tmp.bat"

echo �������δ�����
call "bin\My.bat" call print_file "bin\Test.bat">>"bin\tmp.bat"
copy /y "bin\tmp.bat" "bin\Test.bat" 1>nul
del /q "bin\tmp.bat"

echo ���봦����ɡ���
setlocal disabledelayedexpansion
pause
exit


