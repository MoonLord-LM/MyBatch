@echo off

echo ��� BeyondCompare 4 ������������ʾ��Ϣ��
echo.
echo ������������������������������������������������������������������������������������
echo �� ����                                                                         ��
echo �� �����Ȩ��Կ�ѱ�������1822-9597 Ҫ�˽����ϸ�ڣ���ϵ sales@scootersoftware.com ��
echo ������������������������������������������������������������������������������������
echo.

for /f "usebackq tokens=3,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "AppData"`) ^
do set "appdata_roaming_dir=%%i"
echo AppData Roaming ·����%appdata_roaming_dir%

set "bc_session_file=%appdata_roaming_dir%\Scooter Software\Beyond Compare 4\BCSessions.xml"
echo ��ȡ�ļ���%bc_session_file%

for /f usebackq^ tokens^=1^,2^,*^ delims^=^" %%i in ("%bc_session_file%") do (
    REM echo %%i
    REM echo %%j
    REM echo %%k
    if "%%i"=="<BCSessions Flags=" (
        set "bc_Flags=%%j"
        echo Flags: %%j
    )
)
if "%bc_Flags%"=="" (
    echo.
    echo Flags ��ֵΪ�գ������޸�
    echo.
    goto :final
)

set "bc_state_file=%appdata_roaming_dir%\Scooter Software\Beyond Compare 4\BCState.xml"
echo ��ȡ�ļ���%bc_state_file%

for /f usebackq^ tokens^=1^,2^,*^ delims^=^" %%i in ("%bc_state_file%") do (
    REM echo %%i
    REM echo %%j
    REM echo %%k
    for /f "tokens=*" %%i in ("%%i") do (
        REM echo %%i
        if "%%i"=="<CheckID Value=" (
            set "bc_CheckID=%%j"
            echo CheckID: %%j
        )
    )
)
if "%bc_CheckID%"=="" (
    echo.
    echo CheckID ��ֵΪ�գ������޸�
    echo.
    goto :final
)

echo.
if "%bc_Flags%" neq "%bc_CheckID%" (
    echo �޸����� CheckID Ϊ��%bc_Flags%
    echo "%bc_state_file%.bak"
    type nul>"%bc_state_file%.bak"
    for /f "usebackq tokens=* delims=" %%i in ("%bc_state_file%") do (
        REM echo %%i
        set "line_saved=%%i"
        set "line=%%i"
        setlocal enabledelayedexpansion
        if "!line!" neq "" (
            call set "line=!line:%bc_CheckID%=%bc_Flags%!"
            REM echo !line!
            if "!line!" neq "!line_saved!" (
                REM echo !line_saved!
                echo "!line_saved!" | findstr "^!" 1>nul 2>nul
                if !errorlevel! neq 0 (
                    echo !line!
                )
            )
        )
        echo !line!>>"%bc_state_file%.bak"
        endlocal
    )
    copy /Y "%bc_state_file%.bak" "%bc_state_file%"
) else (
    echo CheckID �� Flags ��ֵ��ȣ������޸�
)
echo.

:final
pause
exit