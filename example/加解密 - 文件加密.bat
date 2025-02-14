@echo off
setlocal

:: ��ȡ�϶��� bat �ļ��ϵ������ļ�·��
set "input_file=%~1"

:: ����Ƿ��ṩ�������ļ�
if "%input_file%"=="" (
    echo �뽫Ҫ������ļ��϶����˽ű���
    pause
    exit /b
)
if exist "%input_file%\" (
    echo �벻Ҫ���ļ����϶����˽ű���
    pause
    exit /b
)

:: ��ȡ�û���������벢������ SHA-256 ��ϣֵ��Ϊ��Կ
set "psCommand=powershell -Command "$p=Read-Host '����������' -AsSecureString; [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p))""
for /f "usebackq delims=" %%p in (`%psCommand%`) do set "password=%%p"

:: ����ϣֵת��Ϊ�ֽ������ʽ��64��ʮ�������ַ���
set key=%key:~0,64%

:: ��������ļ�·����Ĭ��Ϊԭ�ļ������� .txt ��׺
set "temp_file_1=%input_file%.1"
set "temp_file_2=%input_file%.2"
set "output_file=%input_file%.txt"

:: ʹ�� PowerShell ִ�� 01 λ��ת���Լ�ÿ���ֽ�����ֵ 13 �����
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$inputFile='%input_file%'; $outputFile='%temp_file_1%';" ^
    "$bytes = [System.IO.File]::ReadAllBytes($inputFile);" ^
    "for ($i = 0; $i -lt $bytes.Length; $i++) {" ^
    "    $byte = $bytes[$i];" ^
    "    $newByte = 0;" ^
    "    for ($j = 0; $j -lt 8; $j++) {" ^
    "        $bit = [bool]($byte -band (1 -shl $j));" ^
    "        if (-not $bit) {" ^
    "            $newByte = $newByte -bor (1 -shl $j);" ^
    "        }" ^
    "    }" ^
    "    $bytes[$i] = $newByte;" ^
    "};" ^
    "for ($i = 0; $i -lt $bytes.Length; $i++) {" ^
    "    $bytes[$i] = $bytes[$i] -bxor 13;" ^
    "};" ^
    "[System.IO.File]::WriteAllBytes($outputFile, $bytes);"

:: ʹ�� OpenSSL ִ�� AES-256-CBC ����
openssl enc -aes-256-cbc -in "%temp_file_1%" -out "%temp_file_2%" -pbkdf2 -iter 10000000 -pass "pass:%password%"

:: ʹ�� certutil ���� Base64 ����
if exist "%output_file%" del "%output_file%"
certutil -encode "%temp_file_2%" "%output_file%"

:: ɾ����ʱ�����ļ��� PowerShell �ű�
del "%temp_file_1%"
del "%temp_file_2%"


