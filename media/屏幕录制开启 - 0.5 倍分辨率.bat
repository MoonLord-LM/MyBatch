@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，开始后台的屏幕录制，以缩小为 0.5 倍的分辨率，后台录制为 mp4 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '需要停止录制时，运行 “屏幕录制关闭.bat” 即可' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '记录录制进程的 PID 文件，保存在当前文件夹下' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '录制生成的 mp4 文件，保存在当前文件夹下' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 检查 ffmpeg 组件
if exist "!script_dir!ffmpeg.exe" (
    set "ffmpeg_path=!script_dir!ffmpeg.exe"
) else if exist "!cd!\ffmpeg.exe" (
    set "ffmpeg_path=!cd!\ffmpeg.exe"
) else if exist "!script_dir!..\ffmpeg.exe" (
    set "ffmpeg_path=!script_dir!..\ffmpeg.exe"
) else if exist "..\ffmpeg.exe" (
    set "ffmpeg_path=..\ffmpeg.exe"
) else (
    set "ffmpeg_path=ffmpeg"
)
"!ffmpeg_path!" -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 ffmpeg 组件
    echo 请从 https://ffmpeg.org/download.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



set "pipe_name=MyBatchFFmpegScreenRecorder"
set "pid_file=!script_dir!_tmp_屏幕录制.pid"
if exist "!pid_file!" (
    set /p "old_pid="< "!pid_file!"
    tasklist /fi "pid eq !old_pid!" | find /i "!old_pid!" >nul 2>&1
    if !errorlevel! equ 0 (
        echo 检测到已有录制正在进行，请先运行 “屏幕录制关闭.bat” 结束当前录制
        echo.
        pause
        endlocal & endlocal & exit /b 1
    ) else (
        echo 检测到残留的录制记录，对应进程已不存在，执行清理
        set "file_to_delete=!pid_file!"
        powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:file_to_delete,'OnlyErrorDialogs','SendToRecycleBin')"
        echo.
    )
)

REM 获取屏幕分辨率
for /f "usebackq delims=" %%r in (`
    powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "Add-Type -AssemblyName System.Windows.Forms;" ^
    "$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds;" ^
    "Write-Output ('screen_size={0}x{1}' -f $b.Width, $b.Height);"
`) do set "%%r"
echo 屏幕分辨率：!screen_size!

for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-Date -Format 'yyyyMMdd_HHmmss'"`) do set "time_stamp=%%t"
set "output_file=!script_dir!录屏_0.5x_!time_stamp!.mp4"
echo 输出文件："!output_file!"



REM 内嵌的 Powershell 代码块开始
goto :after_powershell_block
    [Console]::OutputEncoding=[Text.Encoding]::UTF8;
    $PID | Out-File -FilePath $env:pid_file -Encoding ascii;
    $pipe = [IO.Pipes.NamedPipeServerStream]::new($env:pipe_name, [IO.Pipes.PipeDirection]::In);
    $psi = [Diagnostics.ProcessStartInfo]::new();
    $psi.FileName = $env:ffmpeg_path;
    $psi.Arguments = '-y -f gdigrab -framerate 30 -draw_mouse 1 -i desktop -vf scale=iw/2:ih/2 -c:v libx264 -crf 18 -preset veryfast -movflags +faststart ' + $env:output_file;
    $psi.UseShellExecute = $false;
    $psi.CreateNoWindow = $true;
    $psi.RedirectStandardInput = $true;
    $psi.RedirectStandardError = $true;
    $p = [Diagnostics.Process]::new();
    $p.StartInfo = $psi;
    $p.Start() | Out-Null;
    $errorLog = $p.StandardError.ReadToEndAsync();
    $pipe.WaitForConnection();
    $command = [IO.StreamReader]::new($pipe).ReadLine();
    if ($command -eq 'stop' -and -not $p.HasExited) {
        $p.StandardInput.WriteLine('q');
        $p.StandardInput.Close();
    }
    $p.WaitForExit();
    if ($p.ExitCode -ne 0) {
        $log = Join-Path (Split-Path -Parent $env:output_file) '_tmp_屏幕录制.log';
        Set-Content -LiteralPath $log -Value $errorLog.Result -Encoding UTF8;
    }
    $pipe.Dispose()
    if (Test-Path $env:pid_file) {
        Add-Type -AssemblyName Microsoft.VisualBasic;
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:pid_file, 'OnlyErrorDialogs', 'SendToRecycleBin');
    }
:after_powershell_block
REM 内嵌的 Powershell 代码块结束



powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$lines = Get-Content -LiteralPath $env:script_path;" ^
    "$a = ($lines | Select-String -Pattern '^goto :after_powershell_block\s*$' | Select-Object -First 1).LineNumber;" ^
    "$b = ($lines | Select-String -Pattern '^:after_powershell_block\s*$' | Select-Object -First 1).LineNumber;" ^
    "$code = ($lines[$a..($b - 1)] -join [Environment]::NewLine);" ^
    "$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code));" ^
    "Start-Process -WindowStyle Hidden -FilePath 'powershell' -ArgumentList @('-NoProfile','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-EncodedCommand',$b64)"
if !errorlevel! neq 0 (
    echo.
    echo 录制进程启动失败
    echo.
    pause
    endlocal & endlocal & exit /b 1
) else (
    echo.
    echo 录制已开始，将在 3 秒后自动关闭本窗口... & REM
)



echo.
timeout /t 3 /nobreak >nul
endlocal & endlocal & exit /b
