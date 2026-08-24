@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，优雅停止后台的屏幕录制' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '通过命名管道发送停止信号，实现 ffmpeg 的优雅退出' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '发送信号后，等待最多约 30 秒，超时则强制结束进程' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '记录录制进程的 PID 文件，保存在当前文件夹下' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '录制生成的 mp4 文件，保存在当前文件夹下' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



set "pipe_name=MyBatchFFmpegScreenRecorder"
set "pid_file=!script_dir!_tmp_屏幕录制.pid"

powershell -NoProfile -Command ^
    "$pipe = [IO.Pipes.NamedPipeClientStream]::new('.', $env:pipe_name, [IO.Pipes.PipeDirection]::Out);" ^
    "try {" ^
    "    $pipe.Connect(2000);" ^
    "    $writer = [IO.StreamWriter]::new($pipe);" ^
    "    $writer.WriteLine('stop');" ^
    "    $writer.Flush();" ^
    "    $writer.Dispose();" ^
    "    $pipe.Dispose();" ^
    "    exit 0;" ^
    "}" ^
    "catch {" ^
    "    exit 1;" ^
    "}"
if !errorlevel! equ 0 (
    echo 已发送停止信号，等待安全写入文件...
    echo.
    if exist "!pid_file!" (
        set /p "rec_pid="< "!pid_file!"
        for /f "usebackq delims=" %%o in (`
            powershell -NoProfile -Command ^
                "[Console]::OutputEncoding = [Text.Encoding]::UTF8;" ^
                "$deadline = (Get-Date).AddSeconds(30);" ^
                "$proc = Get-Process -Id $env:rec_pid -ErrorAction SilentlyContinue;" ^
                "while ($proc -and (Get-Date) -lt $deadline) {" ^
                "    Start-Sleep -Milliseconds 1000;" ^
                "    $proc = Get-Process -Id $env:rec_pid -ErrorAction SilentlyContinue;" ^
                "};" ^
                "if ($proc) {" ^
                "    Stop-Process -Id $env:rec_pid -Force -ErrorAction SilentlyContinue;" ^
                "    Write-Output 'forced';" ^
                "} else {" ^
                "    Write-Output 'graceful';" ^
                "}"
        `) do set "wait_result=%%o"
        if "!wait_result!"=="forced" (
            echo 等待时间已超过 30 秒，强制结束录制进程
        ) else (
            echo 录制已停止，录制进程已退出
        )
        set "file_to_delete=!pid_file!"
        powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:file_to_delete,'OnlyErrorDialogs','SendToRecycleBin')"
        echo 录制状态记录已清除
    ) else (
        echo 录制已停止，录制进程 PID 文件不存在
    )
) else (
    echo 发送停止信号失败
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding = [Text.Encoding]::UTF8;" ^
        "$all = Get-CimInstance Win32_Process;" ^
        "$targets = $all | Where-Object { $_.ProcessId -ne $PID -and ($_.Name -like 'ffmpeg*' -or ($_.Name -eq 'powershell.exe' -and $_.CommandLine -match 'MyBatchFFmpegScreenRecorder')) };" ^
        "if (-not $targets) {" ^
        "    Write-Host '未发现录制相关进程' -ForegroundColor Yellow;" ^
        "} else {" ^
        "    Write-Host '发现疑似录制相关进程：' -ForegroundColor Yellow;" ^
        "    $targets | ForEach-Object {" ^
        "        $cmd = $_.CommandLine;" ^
        "        if ($cmd.Length -gt 160) { $cmd = $cmd.Substring(0, 160) + '...' };" ^
        "        Write-Host ('PID：' + $_.ProcessId + ' 进程：' + $_.Name + ' 启动：' + $_.CreationDate + ' 命令：' + $cmd);" ^
        "    }" ^
        "}"
    if exist "!pid_file!" (
        set "file_to_delete=!pid_file!"
        powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:file_to_delete,'OnlyErrorDialogs','SendToRecycleBin')"
    )
)



echo.
pause
endlocal & endlocal & exit /b
