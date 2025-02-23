@echo off
setlocal

:: 获取拖动到 bat 文件上的输入文件路径
set "input_file=%~1"

:: 检查是否提供了输入文件
if "%input_file%"=="" (
    echo 请将要编码的文件拖动到此脚本上
    pause
    exit /b
)
if exist "%input_file%\" (
    echo 请不要将文件夹拖动到此脚本上
    pause
    exit /b
)

:: 获取用户输入的密码并计算其 SHA-256 哈希值作为密钥
set "psCommand=powershell -Command "$p=Read-Host '请输入密码' -AsSecureString; [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p))""
for /f "usebackq delims=" %%p in (`%psCommand%`) do set "password=%%p"

:: 将哈希值转换为字节数组格式（64个十六进制字符）
set key=%key:~0,64%

:: 设置输出文件路径，默认为原文件名加上 .txt 后缀
set "temp_file_1=%input_file%.1"
set "temp_file_2=%input_file%.2"
set "output_file=%input_file%.txt"

:: 使用 PowerShell 执行 01 位反转，以及每个字节与数值 13 异或处理
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

:: 使用 OpenSSL 执行 AES-256-CBC 加密
openssl enc -aes-256-cbc -in "%temp_file_1%" -out "%temp_file_2%" -pbkdf2 -iter 10000000 -pass "pass:%password%"

:: 使用 certutil 进行 Base64 编码
if exist "%output_file%" del "%output_file%"
certutil -encode "%temp_file_2%" "%output_file%"

:: 删除临时处理文件和 PowerShell 脚本
del "%temp_file_1%"
del "%temp_file_2%"


