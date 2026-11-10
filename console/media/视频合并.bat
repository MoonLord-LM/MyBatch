@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将封面文件 00.jpg 以及视频文件 01.mp4、02.mp4 ... 最多到 999.mp4 拼接合并为 final.mp4 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '也支持拼接 DVD 中的 VTS_01_1.VOB、VTS_01_2.VOB ... 形式的视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动扫描当前文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则递归处理其中所有文件；不支持拖入单个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '会尽可能保留原始视频质量，尽量避免音画不一致问题，必要的时候进行转码' -ForegroundColor Green"
echo.



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
    echo 错误：缺少 ffmpeg 组件 & REM
    echo 请从 https://ffmpeg.org/download.html 下载，然后把 ffmpeg.exe 放到脚本所在文件夹 & REM
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)

REM 检查 ffprobe 组件
if exist "!script_dir!ffprobe.exe" (
    set "ffprobe_path=!script_dir!ffprobe.exe"
) else if exist "!cd!\ffprobe.exe" (
    set "ffprobe_path=!cd!\ffprobe.exe"
) else if exist "!script_dir!..\ffprobe.exe" (
    set "ffprobe_path=!script_dir!..\ffprobe.exe"
) else if exist "..\ffprobe.exe" (
    set "ffprobe_path=..\ffprobe.exe"
) else (
    set "ffprobe_path=ffprobe"
)
"!ffprobe_path!" -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 ffprobe 组件 & REM
    echo 请从 https://ffmpeg.org/download.html 下载，然后把 ffprobe.exe 放到脚本所在文件夹 & REM
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)

REM 检查 MediaInfo 组件
if exist "!script_dir!MediaInfo.exe" (
    set "mediainfo_path=!script_dir!MediaInfo.exe"
) else if exist "!cd!\MediaInfo.exe" (
    set "mediainfo_path=!cd!\MediaInfo.exe"
) else if exist "!script_dir!..\MediaInfo.exe" (
    set "mediainfo_path=!script_dir!..\MediaInfo.exe"
) else if exist "..\MediaInfo.exe" (
    set "mediainfo_path=..\MediaInfo.exe"
) else (
    set "mediainfo_path=MediaInfo"
)
"!mediainfo_path!" --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 MediaInfo 组件 & REM
    echo 请从 https://mediaarea.net/en/MediaInfo 下载，然后把 MediaInfo.exe 放到脚本所在文件夹 & REM
    "explorer.exe" "https://mediaarea.net/en/MediaInfo"
    echo.
    pause
    exit /b 1
)



if "!param1!" == "" (
    echo 开始处理当前文件夹："!cd!"
    set "working_dir=!cd!"
    echo.
) else (
    if "!param1:~-1!"=="\" set "param1=!param1:~0,-1!"
    if not exist "!param1!" (
        echo 错误：路径不存在："!param1!"
        echo.
        pause
        exit /b 1
    )
    if exist "!param1!\" (
        echo 开始处理文件夹："!param1!"
        set "working_dir=!param1!"
        echo.
    ) else (
        echo 错误：不支持拖入单个文件，请拖入文件夹或双击运行
        echo.
        pause
        exit /b 1
    )
)



if not "!working_dir!" == "" (
    REM 从自身文件末尾的 -----BEGIN POWERSHELL CODE----- / -----END POWERSHELL CODE----- 之间提取 PowerShell 代码
    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
        "$lines = Get-Content -Encoding UTF8 -LiteralPath $env:script_path;" ^
        "$begin = [array]::IndexOf($lines, '-----BEGIN POWERSHELL CODE-----') + 1;" ^
        "$end = [array]::IndexOf($lines, '-----END POWERSHELL CODE-----');" ^
        "if ($begin -lt 1 -or $end -lt $begin) {" ^
        "    Write-Host '错误：未找到内嵌的 PowerShell 代码块' -ForegroundColor Red;" ^
        "    exit 1;" ^
        "};" ^
        "$code = $lines[$begin..($end - 1)] -join [System.Environment]::NewLine;" ^
        "Invoke-Expression $code"
    if !errorlevel! neq 0 (
        echo 错误：视频合并失败，请检查报错信息
        echo.
        pause
        exit /b 1
    )
)



echo.
pause
exit /b



-----BEGIN POWERSHELL CODE-----
[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;

$workingDir = $env:working_dir;
$ffmpegPath = $env:ffmpeg_path;
$ffprobePath = $env:ffprobe_path;
$mediainfoPath = $env:mediainfo_path;
$creationTime = [System.DateTimeOffset]::Now.ToString('yyyy-MM-ddTHH:mm:ss.fffffffzzz');
$utf8NoBOM = [System.Text.UTF8Encoding]::new($false);
$tempDir = [System.IO.Path]::GetTempPath();
$concatList = [System.IO.Path]::Combine($tempDir, 'MyBatch_' + [System.Guid]::NewGuid().ToString('N') + '.tmp');
$mergedVideo = [System.IO.Path]::Combine($tempDir, 'MyBatch_' + [System.Guid]::NewGuid().ToString('N') + '.mp4');
$vobList = [System.IO.Path]::Combine($tempDir, 'MyBatch_' + [System.Guid]::NewGuid().ToString('N') + '.tmp');
$finalVideo = [System.IO.Path]::Combine($workingDir, 'final.mp4');

function Format-Arg-String([string[]]$ArgList) {
    $parts = [System.Collections.Generic.List[string]]::new();
    foreach ($arg in $ArgList) {
        if ($arg.IndexOf(' ') -ge 0) { $parts.Add('"' + $arg + '"') } else { $parts.Add($arg) }
    }
    return ($parts -join ' ');
}

function Format-Concat-Line([string]$FilePath) {
    return "file '" + $FilePath.Replace("'", "'\''") + "'";
}

function Invoke-FFmpeg([string[]]$ArgList) {
    Write-Host ('> "' + $ffmpegPath + '" ' + (Format-Arg-String -ArgList $ArgList));
    & $ffmpegPath @ArgList 2>&1 | ForEach-Object { Write-Host ($_) };
    return $LASTEXITCODE;
}

function Get-Tool-Output([string]$ExePath, [string[]]$ArgList) {
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new();
    $startInfo.FileName = $ExePath;
    $startInfo.Arguments = Format-Arg-String -ArgList $ArgList;
    $startInfo.UseShellExecute = $false;
    $startInfo.CreateNoWindow = $true;
    $startInfo.RedirectStandardInput = $true;
    $startInfo.RedirectStandardOutput = $true;
    $startInfo.RedirectStandardError = $true;
    $startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8;
    $startInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8;
    $proc = [System.Diagnostics.Process]::Start($startInfo);
    $proc.StandardInput.Close();
    $stdoutTask = $proc.StandardOutput.ReadToEndAsync();
    $stderrTask = $proc.StandardError.ReadToEndAsync();
    $proc.WaitForExit();
    $result = [pscustomobject]@{ ExitCode = $proc.ExitCode; Text = $stdoutTask.Result; ErrorText = $stderrTask.Result };
    $proc.Dispose();
    return $result;
}

function Get-Clip-Names([int]$Index, [string]$Extension) {
    $n = [string]$Index;
    return [string[]]@(
        ($n + $Extension),
        ('0' + $n + $Extension),
        ('00' + $n + $Extension),
        ('000' + $n + $Extension),
        ('第' + $n + '集' + $Extension),
        ('第0' + $n + '集' + $Extension),
        ('第00' + $n + '集' + $Extension),
        ('第000' + $n + '集' + $Extension)
    );
}

function Wait-Enter-Key {
    [void][System.Console]::ReadLine();
}

function Remove-Temp-Files {
    foreach ($tempFile in @($concatList, $mergedVideo, $vobList)) {
        if ([System.IO.File]::Exists($tempFile)) { [System.IO.File]::Delete($tempFile) }
    }
}

Add-Type -AssemblyName Microsoft.VisualBasic;

try {
    $fileNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase);
    foreach ($entry in [System.IO.Directory]::EnumerateFiles($workingDir)) {
        [void]$fileNames.Add([System.IO.Path]::GetFileName($entry));
    }

    # mkv / ts 转封装为 mp4
    foreach ($ext in @('.mkv', '.ts')) {
        Write-Host ('正在检查和处理 ' + $ext.Substring(1) + ' 格式的视频');
        $hasInput = $false;
        foreach ($name in $fileNames) {
            if ($name.EndsWith($ext, [System.StringComparison]::OrdinalIgnoreCase)) { $hasInput = $true; break }
        }
        if (-not $hasInput) { continue }
        for ($i = 1; $i -le 9999; $i++) {
            foreach ($name in (Get-Clip-Names -Index $i -Extension $ext)) {
                if (-not $fileNames.Contains($name)) { continue; }
                $mp4Name = [System.IO.Path]::ChangeExtension($name, '.mp4');
                if (-not $fileNames.Contains($mp4Name)) {
                    $src = [System.IO.Path]::Combine($workingDir, $name);
                    $dst = [System.IO.Path]::Combine($workingDir, $mp4Name);
                    $code = Invoke-FFmpeg -ArgList @('-i', $src, '-c', 'copy', '-map_metadata', '-1', $dst);
                    if ($code -ne 0) {
                        if ([System.IO.File]::Exists($dst)) { [System.IO.File]::Delete($dst) }
                        throw ('错误：文件 ' + $name + ' 转换为 mp4 失败，请检查报错信息');
                    }
                    [void]$fileNames.Add($mp4Name);
                }
                break;
            }
        }
    }

    # DVD 正片 VOB 按标题拼接为 01.mp4、02.mp4 ...
    Write-Host '正在检查和处理 vob 格式的视频';
    $unsupportedCodecs = @('cook', 'pcm_dvd', 'pcm_s16be', 'pcm_s16le', 'pcm_u16be', 'pcm_u16le', 'pcm_s24be', 'pcm_s24le', 'pcm_u24be', 'pcm_u24le', 'pcm_s32be', 'pcm_s32le', 'pcm_u32be', 'pcm_u32le');
    $vobIndex = 0;
    for ($t = 1; $t -le 99; $t++) {
        $title = $t.ToString('00');
        $vobPaths = [System.Collections.Generic.List[string]]::new();
        for ($p = 1; $p -le 99; $p++) {
            $vobName = 'VTS_' + $title + '_' + $p + '.VOB';
            if ($fileNames.Contains($vobName)) { $vobPaths.Add([System.IO.Path]::Combine($workingDir, $vobName)) }
        }
        if ($vobPaths.Count -eq 0) { continue; }
        $vobIndex++;
        $clipName = $vobIndex.ToString('00') + '.mp4';
        if ($fileNames.Contains($clipName)) { continue; }
        Write-Host ('正在拼接 VTS_' + $title + '_*.VOB 为 ' + $clipName);
        $vobLines = [System.Collections.Generic.List[string]]::new();
        foreach ($vobPath in $vobPaths) { $vobLines.Add((Format-Concat-Line -FilePath $vobPath)) }
        [System.IO.File]::WriteAllLines($vobList, [string[]]$vobLines.ToArray(), $utf8NoBOM);
        $audioProbe = Get-Tool-Output -ExePath $ffprobePath -ArgList @('-v', 'error', '-select_streams', 'a', '-show_entries', 'stream=codec_name', '-of', 'default=noprint_wrappers=1:nokey=1', $vobPaths[0]);
        $audioLines = @($audioProbe.Text.Split([char[]]@([char]10, [char]13), [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' });
        $vobAudioCodec = '';
        if ($audioLines.Count -gt 0) { $vobAudioCodec = $audioLines[$audioLines.Count - 1] }
        $vobOut = [System.IO.Path]::Combine($workingDir, $clipName);
        $ffmpegArgs = [System.Collections.Generic.List[string]]::new();
        $ffmpegArgs.AddRange([string[]]@('-y', '-fflags', '+genpts', '-f', 'concat', '-safe', '0', '-i', $vobList));
        if ($unsupportedCodecs -contains $vobAudioCodec.ToLowerInvariant()) {
            Write-Host ('检测到不支持的音频编码：' + $vobAudioCodec + '，正在转换为 FLAC 格式');
            $ffmpegArgs.AddRange([string[]]@('-c:v', 'copy', '-c:a', 'flac', '-compression_level', '8', '-map_metadata', '-1', $vobOut));
        } else {
            $ffmpegArgs.AddRange([string[]]@('-c', 'copy', '-map_metadata', '-1', $vobOut));
        }
        $code = Invoke-FFmpeg -ArgList $ffmpegArgs.ToArray();
        if ($code -ne 0) {
            if ([System.IO.File]::Exists($vobOut)) { [System.IO.File]::Delete($vobOut) }
            throw ('错误：拼接 VTS_' + $title + '_*.VOB 失败');
        }
        [void]$fileNames.Add($clipName);
    }

    # 序号重名与缺号检查
    Write-Host '正在检查文件的序号';
    $clipNames = [System.Collections.Generic.List[string]]::new();
    $foundIndexes = [System.Collections.Generic.HashSet[int]]::new();
    $minIndex = 0;
    $maxIndex = 0;
    for ($i = 1; $i -le 9999; $i++) {
        $matched = [System.Collections.Generic.List[string]]::new();
        foreach ($name in (Get-Clip-Names -Index $i -Extension '.mp4')) {
            if ($fileNames.Contains($name)) { $matched.Add($name) }
        }
        if ($matched.Count -gt 1) {
            throw ('错误：序号 ' + $i + ' 存在多个命名方式相同的文件：' + ($matched.ToArray() -join ' ') + '，请只保留其中一个文件');
        }
        if ($matched.Count -eq 1) {
            $clipNames.Add($matched[0]);
            [void]$foundIndexes.Add($i);
            if ($minIndex -eq 0) { $minIndex = $i }
            $maxIndex = $i;
        }
    }
    if ($clipNames.Count -eq 0) {
        throw '没有找到任何视频文件，搜索范围为 01.mp4 到 9999.mp4';
    }
    $missingList = [System.Collections.Generic.List[string]]::new();
    for ($i = $minIndex; $i -le $maxIndex; $i++) {
        if (-not $foundIndexes.Contains($i)) { $missingList.Add([string]$i) }
    }
    if ($missingList.Count -gt 0) {
        throw ('错误：视频序号不连续，缺少以下序号：' + ($missingList.ToArray() -join ' ') + '，请补齐缺失的视频文件');
    }

    # MediaInfo 分批一次取回所有文件的 HEVC Tier
    $clipPaths = [System.Collections.Generic.List[string]]::new();
    foreach ($name in $clipNames) { $clipPaths.Add([System.IO.Path]::Combine($workingDir, $name)) }
    $tierText = '';
    $batchSize = 40;
    for ($start = 0; $start -lt $clipPaths.Count; $start += $batchSize) {
        $endIndex = [System.Math]::Min($start + $batchSize - 1, $clipPaths.Count - 1);
        $batchArgs = [System.Collections.Generic.List[string]]::new();
        $batchArgs.Add('--Inform=Video;%Format_Profile%|');
        for ($k = $start; $k -le $endIndex; $k++) { $batchArgs.Add($clipPaths[$k]) }
        $tierProbe = Get-Tool-Output -ExePath $mediainfoPath -ArgList $batchArgs.ToArray();
        $tierText += $tierProbe.Text;
    }
    $tierParts = @($tierText.Replace([string][char]13, '').Replace([string][char]10, '').Split([char]124));

    # 每文件一次 ffprobe，参数解析后立即逐条打印
    Write-Host ('正在检查视频内容');
    $probeList = [System.Collections.Generic.List[object]]::new();
    $videoFileList = [System.Collections.Generic.List[string]]::new();
    $clipIndex = 0;
    $formatGroups = [System.Collections.Generic.Dictionary[string,object]]::new();
    foreach ($name in $clipNames) {
        $videoPath = $clipPaths[$clipIndex];
        $clipIndex++;
        $probe = Get-Tool-Output -ExePath $ffprobePath -ArgList @('-v', 'error', '-show_streams', '-show_format', '-print_format', 'json', $videoPath);
        $info = $null;
        if (-not [string]::IsNullOrWhiteSpace($probe.Text)) {
            try { $info = $probe.Text | ConvertFrom-Json } catch { $info = $null }
        }
        if ($probe.ExitCode -ne 0 -or $null -eq $info -or $null -eq $info.format) {
            Write-Host '';
            Write-Host ('文件 "' + $videoPath + '" 已损坏，无法处理，按 Enter 键显示详细解码错误，或者关闭窗口结束运行');
            Write-Host '';
            Wait-Enter-Key;
            if ($probe.ErrorText) { Write-Host $probe.ErrorText }
            [void](Invoke-FFmpeg -ArgList @('-v', 'error', '-i', $videoPath, '-map', '0', '-f', 'null', '-'));
            throw ('文件 "' + $videoPath + '" 已损坏，无法处理');
        }
        $videoStream = @($info.streams | Where-Object { $_.codec_type -eq 'video' })[0];
        $audioStream = @($info.streams | Where-Object { $_.codec_type -eq 'audio' })[0];
        if ($null -eq $videoStream -or $null -eq $audioStream) {
            throw ('文件 "' + $videoPath + '" 缺少视频流或音频流，无法处理');
        }
        $tier = '';
        if (($clipIndex - 1) -lt $tierParts.Count) { $tier = @($tierParts[$clipIndex - 1] -split '@')[-1] }
        $clip = [pscustomobject]@{
            Name = $name;
            Path = $videoPath;
            VideoWidth = [string]$videoStream.width;
            VideoHeight = [string]$videoStream.height;
            VideoCodec = [string]$videoStream.codec_name;
            VideoCodecTag = [string]$videoStream.codec_tag_string;
            VideoCodecProfile = [string]$videoStream.profile;
            VideoCodecLevel = [string]$videoStream.level;
            VideoFps = [string]$videoStream.r_frame_rate;
            VideoTimeBase = [string]$videoStream.time_base;
            AudioCodec = [string]$audioStream.codec_name;
            AudioCodecProfile = [string]$audioStream.profile;
            AudioSampleRate = [string]$audioStream.sample_rate;
            HasTimeCode = (@($info.streams | Where-Object { $_.codec_tag_string -eq 'tmcd' }).Count -gt 0);
            CodecTier = $tier;
            VideoCodecAll = '';
            AudioCodecAll = '';
            VideoConsistent = $false;
            AudioConsistent = $false;
        };
        $clip.VideoCodecAll = $clip.VideoCodec + ' ' + $clip.VideoCodecTag + ' ' + $clip.VideoCodecProfile + ' ' + $clip.VideoCodecLevel + ' ' + $clip.CodecTier;
        $clip.AudioCodecAll = $clip.AudioCodec + ' ' + $clip.AudioCodecProfile;
        $probeList.Add($clip);
        $videoFileList.Add((Format-Concat-Line -FilePath $videoPath));
        Write-Host ('[' + $clipIndex + '/' + $clipNames.Count + ']：' + $name + '，分辨率：' + $clip.VideoWidth + 'x' + $clip.VideoHeight + '，视频编码：' + $clip.VideoCodecAll + ' ' + $clip.VideoFps + '，音频编码：' + $clip.AudioCodecAll + ' ' + $clip.AudioSampleRate + ' ' + $clip.VideoTimeBase);
        $formatKey = $clip.VideoWidth + 'x' + $clip.VideoHeight + '|' + $clip.VideoCodecAll + '|' + $clip.VideoFps + '|' + $clip.AudioCodecAll + '|' + $clip.AudioSampleRate + '|' + $clip.VideoTimeBase;
        $formatDescription = '分辨率：' + $clip.VideoWidth + 'x' + $clip.VideoHeight + '，视频编码：' + $clip.VideoCodecAll + ' ' + $clip.VideoFps + '，音频编码：' + $clip.AudioCodecAll + ' ' + $clip.AudioSampleRate + ' ' + $clip.VideoTimeBase;
        if ($formatGroups.ContainsKey($formatKey)) {
            $formatGroups[$formatKey].Count++;
        } else {
            $pixels = 0;
            try { $pixels = [int]$clip.VideoWidth * [int]$clip.VideoHeight } catch { }
            $formatGroups[$formatKey] = [pscustomobject]@{
                Key = $formatKey;
                Count = 1;
                Pixels = $pixels;
                Description = $formatDescription;
                Sample = $clip;
            };
        }
    }

    # 按分辨率、数量降序展示所有格式，取第一项作为转码目标
    Write-Host ('正在统计视频格式');
    $sortedGroups = @($formatGroups.Values | Sort-Object -Property @{ Expression = { $_.Pixels }; Descending = $true }, @{ Expression = { $_.Count }; Descending = $true }, @{ Expression = { $_.Key }; Descending = $false });
    Write-Host ('共 ' + $probeList.Count + ' 个视频，' + $sortedGroups.Count + ' 种格式（按分辨率、数量降序，第一项为转码目标）：');
    foreach ($group in $sortedGroups) {
        Write-Host ('[' + $group.Count + '/' + $probeList.Count + '] ' + $group.Description);
    }
    $targetClip = $sortedGroups[0].Sample;

    # 各段视频编码、帧率、音频编码、采样率需一致，避免音画不一致，只转码不一致的视频
    Write-Host ('正在对比视频参数');
    $needTranscode = 0;
    foreach ($clip in $probeList) {
        $videoMatch = $true;
        $audioMatch = $true;
        if ($clip.VideoWidth -ne $targetClip.VideoWidth) { $videoMatch = $false }
        if ($clip.VideoHeight -ne $targetClip.VideoHeight) { $videoMatch = $false }
        if ($clip.VideoCodecAll -ne $targetClip.VideoCodecAll) { $videoMatch = $false }
        if ($clip.AudioCodecAll -ne $targetClip.AudioCodecAll) { $audioMatch = $false }
        if ($clip.VideoFps -ne $targetClip.VideoFps) { $videoMatch = $false }
        if ($clip.AudioSampleRate -ne $targetClip.AudioSampleRate) { $audioMatch = $false }
        if ($clip.VideoTimeBase -ne $targetClip.VideoTimeBase) { $videoMatch = $false }
        $clip.VideoConsistent = $videoMatch;
        $clip.AudioConsistent = $audioMatch;
        if (-not ($videoMatch -and $audioMatch)) { $needTranscode++ }
    }
    $fileConsistent = ($needTranscode -eq 0);
    Write-Host ('与目标格式一致：' + ($probeList.Count - $needTranscode) + '/' + $probeList.Count + '，需要转码：' + $needTranscode + '/' + $probeList.Count);

    # 使用 -map_metadata -1 清理 QuickTime TC 格式的 Time code 资源，避免音画不一致
    Write-Host '正在清理 Time code 资源';
    foreach ($clip in $probeList) {
        if (-not $clip.HasTimeCode) { continue; }
        Write-Host '警告：文件包含 Time code 流，需要进行清理';
        $tmpPath = [System.IO.Path]::Combine($workingDir, [System.IO.Path]::GetFileNameWithoutExtension($clip.Name) + '_tmp.mp4');
        if (-not [System.IO.File]::Exists($tmpPath)) {
            $code = Invoke-FFmpeg -ArgList @('-i', $clip.Path, '-c', 'copy', '-map_metadata', '-1', $tmpPath);
            if ($code -ne 0) {
                if ([System.IO.File]::Exists($tmpPath)) { [System.IO.File]::Delete($tmpPath) }
                throw ('文件 ' + $clip.Name + ' 的 Time code 清理失败，请检查报错信息');
            }
        }
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($clip.Path, 'OnlyErrorDialogs', 'SendToRecycleBin');
        try {
            [System.IO.File]::Move($tmpPath, $clip.Path);
        } catch {
            if ([System.IO.File]::Exists($tmpPath)) { [System.IO.File]::Delete($tmpPath) }
            throw ('错误：文件 ' + $clip.Name + ' 替换失败，原文件已移入回收站，请检查报错信息');
        }
    }

    # 生成文件列表
    Write-Host ('正在生成文件列表');
    [System.IO.File]::WriteAllLines($concatList, [string[]]$videoFileList.ToArray(), $utf8NoBOM);

    # 按目标格式的编码，确定转码参数
    $targetVideoArgs = [System.Collections.Generic.List[string]]::new();
    $targetAudioArgs = [System.Collections.Generic.List[string]]::new();
    $videoCodec = $targetClip.VideoCodec;
    $videoCodecTag = $targetClip.VideoCodecTag;
    $videoCodecProfile = $targetClip.VideoCodecProfile;
    $videoCodecLevel = $targetClip.VideoCodecLevel;
    $videoCodecTier = $targetClip.CodecTier;
    $audioCodec = $targetClip.AudioCodec;
    $audioCodecProfile = $targetClip.AudioCodecProfile;

    if ($videoCodec -ieq 'AV1') {
        $targetVideoArgs.Add('libaom-av1');
        if ($videoCodecTag -ieq 'av01') {
            $targetVideoArgs.AddRange([string[]]@('-tag:v', 'av01'));
        } else {
            Write-Host ('警告：未知 AV1 Tag："' + $videoCodecTag + '"，不指定 Tag'); Write-Host ''; Wait-Enter-Key;
        }
    } elseif ($videoCodec -ieq 'HEVC') {
        $targetVideoArgs.Add('libx265');
        if ($videoCodecTag -ieq 'hev1' -or $videoCodecTag -ieq 'hvc1') {
            $targetVideoArgs.AddRange([string[]]@('-tag:v', $videoCodecTag));
        } else {
            Write-Host ('警告：未知 HEVC Tag："' + $videoCodecTag + '"，不指定 Tag'); Write-Host ''; Wait-Enter-Key;
        }
        $hevcProfileMap = @{ 'Main' = 'main'; 'Main 10' = 'main10'; 'Main 12' = 'main12' };
        if ($hevcProfileMap.ContainsKey($videoCodecProfile)) {
            $targetVideoArgs.AddRange([string[]]@('-profile:v', $hevcProfileMap[$videoCodecProfile]));
        } else {
            Write-Host ('警告：未知 HEVC Profile："' + $videoCodecProfile + '"，不指定 Profile'); Write-Host ''; Wait-Enter-Key;
        }
        $hevcLevelMap = @{ '30' = '10'; '60' = '20'; '63' = '21'; '90' = '30'; '93' = '31'; '120' = '40'; '123' = '41'; '150' = '50'; '153' = '51'; '156' = '52'; '180' = '60'; '183' = '61'; '186' = '62' };
        if ($hevcLevelMap.ContainsKey($videoCodecLevel)) {
            $x265Level = $hevcLevelMap[$videoCodecLevel];
            if ($videoCodecTier -ieq 'Main') {
                $targetVideoArgs.AddRange([string[]]@('-x265-params', ('level-idc=' + $x265Level + ':high-tier=0')));
            } elseif ($videoCodecTier -ieq 'High') {
                $targetVideoArgs.AddRange([string[]]@('-x265-params', ('level-idc=' + $x265Level + ':high-tier=1')));
            } else {
                Write-Host ('警告：未知 HEVC Tier："' + $videoCodecTier + '"，不指定 Tier'); Write-Host ''; Wait-Enter-Key;
                $targetVideoArgs.AddRange([string[]]@('-x265-params', ('level-idc=' + $x265Level)));
            }
        } else {
            Write-Host ('警告：未知 HEVC Level："' + $videoCodecLevel + '"，不指定 Level'); Write-Host ''; Wait-Enter-Key;
        }
    } elseif ($videoCodec -ieq 'H264') {
        $targetVideoArgs.Add('libx264');
        if ($videoCodecTag -ieq 'avc1') {
            $targetVideoArgs.AddRange([string[]]@('-tag:v', 'avc1'));
        } else {
            Write-Host ('警告：未知 H264 Tag："' + $videoCodecTag + '"，不指定 Tag'); Write-Host ''; Wait-Enter-Key;
        }
        $h264ProfileMap = @{ 'Baseline' = 'baseline'; 'Constrained Baseline' = 'baseline'; 'Main' = 'main'; 'High' = 'high'; 'High 10' = 'high10'; 'High 4:2:2' = 'high422'; 'High 4:4:4' = 'high444' };
        if ($h264ProfileMap.ContainsKey($videoCodecProfile)) {
            $targetVideoArgs.AddRange([string[]]@('-profile:v', $h264ProfileMap[$videoCodecProfile]));
        } else {
            Write-Host ('警告：未知 H264 Profile："' + $videoCodecProfile + '"，不指定 Profile'); Write-Host ''; Wait-Enter-Key;
        }
        $h264LevelMap = @{ '10' = '1.0'; '11' = '1.1'; '12' = '1.2'; '13' = '1.3'; '20' = '2.0'; '21' = '2.1'; '22' = '2.2'; '30' = '3.0'; '31' = '3.1'; '32' = '3.2'; '40' = '4.0'; '41' = '4.1'; '42' = '4.2'; '50' = '5.0'; '51' = '5.1'; '52' = '5.2'; '60' = '6.0'; '61' = '6.1'; '62' = '6.2' };
        if ($h264LevelMap.ContainsKey($videoCodecLevel)) {
            $targetVideoArgs.AddRange([string[]]@('-level:v', $h264LevelMap[$videoCodecLevel]));
        } else {
            Write-Host ('警告：未知 H264 Level："' + $videoCodecLevel + '"，不指定 Level'); Write-Host ''; Wait-Enter-Key;
        }
    } elseif ($videoCodec -ieq 'MPEG4') {
        $targetVideoArgs.Add('mpeg4');
        if ($videoCodecTag -ieq 'mp4v') {
            $targetVideoArgs.AddRange([string[]]@('-tag:v', 'mp4v'));
        } else {
            Write-Host ('警告：未知 MPEG4 Tag："' + $videoCodecTag + '"，不指定 Tag'); Write-Host ''; Wait-Enter-Key;
        }
        if ($videoCodecProfile -ieq 'Simple Profile') {
            $targetVideoArgs.AddRange([string[]]@('-profile:v', 'simple'));
        } else {
            Write-Host ('警告：未知 MPEG4 Profile："' + $videoCodecProfile + '"，不指定 Profile'); Write-Host ''; Wait-Enter-Key;
        }
        if ($videoCodecLevel -eq '3') {
            $targetVideoArgs.AddRange([string[]]@('-level', '3'));
        } else {
            Write-Host ('警告：未知 MPEG4 Level："' + $videoCodecLevel + '"，不指定 Level'); Write-Host ''; Wait-Enter-Key;
        }
    } elseif ($videoCodec -ieq 'MPEG2VIDEO') {
        $targetVideoArgs.Add('mpeg2video');
        if ($videoCodecProfile -ieq 'Main') {
            $targetVideoArgs.AddRange([string[]]@('-profile:v', 'main'));
        } elseif ($videoCodecProfile -ieq 'High') {
            $targetVideoArgs.AddRange([string[]]@('-profile:v', 'high'));
        } else {
            Write-Host ('警告：未知 MPEG2 Profile："' + $videoCodecProfile + '"，不指定 Profile'); Write-Host ''; Wait-Enter-Key;
        }
        $mpeg2LevelMap = @{ '10' = 'low'; '8' = 'main'; '6' = 'high1440'; '4' = 'high' };
        if ($mpeg2LevelMap.ContainsKey($videoCodecLevel)) {
            $targetVideoArgs.AddRange([string[]]@('-level:v', $mpeg2LevelMap[$videoCodecLevel]));
        } else {
            Write-Host ('警告：未知 MPEG2 Level："' + $videoCodecLevel + '"，不指定 Level'); Write-Host ''; Wait-Enter-Key;
        }
    } elseif ($videoCodec -ieq 'VP9') {
        $targetVideoArgs.Add('libvpx-vp9');
        if ($videoCodecTag -ieq 'vp09') {
            $targetVideoArgs.AddRange([string[]]@('-tag:v', 'vp09'));
        } else {
            Write-Host ('警告：未知 VP9 Tag："' + $videoCodecTag + '"，不指定 Tag'); Write-Host ''; Wait-Enter-Key;
        }
    } else {
        $targetVideoArgs.Add('libx264');
        Write-Host ('警告：未知视频编码 "' + $videoCodec + '"，使用默认 libx264'); Write-Host ''; Wait-Enter-Key;
    }

    if ($audioCodec -ieq 'AAC') {
        if ($audioCodecProfile -ieq 'LC') {
            $targetAudioArgs.AddRange([string[]]@('aac', '-profile:a', 'aac_low'));
        } elseif ($audioCodecProfile -ieq 'HE-AAC') {
            $targetAudioArgs.AddRange([string[]]@('libfdk_aac', '-profile:a', 'aac_he'));
        } elseif ($audioCodecProfile -ieq 'HE-AACv2') {
            $targetAudioArgs.AddRange([string[]]@('libfdk_aac', '-profile:a', 'aac_he_v2'));
        } else {
            $targetAudioArgs.Add('aac');
            Write-Host ('警告：未知音频编码 "' + $audioCodec + ' ' + $audioCodecProfile + '"，使用默认 aac'); Write-Host ''; Wait-Enter-Key;
        }
    } else {
        $audioEncoderMap = @{ 'MP3' = 'libmp3lame'; 'AC3' = 'ac3'; 'EAC3' = 'eac3'; 'FLAC' = 'flac'; 'MP2' = 'mp2'; 'OPUS' = 'libopus' };
        if ($audioEncoderMap.ContainsKey($audioCodec)) {
            $targetAudioArgs.Add($audioEncoderMap[$audioCodec]);
        } else {
            $targetAudioArgs.Add('aac');
            Write-Host ('警告：未知音频编码 "' + $audioCodec + ' ' + $audioCodecProfile + '"，使用默认 aac'); Write-Host ''; Wait-Enter-Key;
        }
    }

    Write-Host '';
    Write-Host ('目标视频编码参数 ' + ($targetVideoArgs.ToArray() -join ' '));
    Write-Host ('目标音频编码参数 ' + ($targetAudioArgs.ToArray() -join ' '));
    Write-Host '';

    # 参数不一致时按缓存的参数转码，不再重复探测
    if (-not $fileConsistent) {
        $suffixSafe = ($targetClip.VideoFps + '_' + $targetClip.AudioSampleRate).Replace('/', '_').Replace([string][char]92, '_');
        $timeBaseParts = @($targetClip.VideoTimeBase -split '/');
        $targetTimebase = $targetClip.VideoTimeBase;
        if ($timeBaseParts.Count -gt 1 -and -not [string]::IsNullOrEmpty($timeBaseParts[1])) { $targetTimebase = $timeBaseParts[1] }
        $videoFileList.Clear();
        $scaleFilter = 'scale=' + $targetClip.VideoWidth + ':' + $targetClip.VideoHeight + ':force_original_aspect_ratio=increase,crop=' + $targetClip.VideoWidth + ':' + $targetClip.VideoHeight;
        $needVideoTranscode = @($probeList | Where-Object { -not $_.VideoConsistent }).Count -gt 0;

        if ($videoCodec -ieq 'HEVC' -and $needVideoTranscode) {
            Write-Host '';
            Write-Host '存在 H265 视频编码不一致，需要进行全量转码，请选择按 Enter 键开始转码，或者关闭窗口结束运行';
            Write-Host '';
            Wait-Enter-Key;
            Write-Host ('正在转码视频，目标分辨率：' + $targetClip.VideoWidth + 'x' + $targetClip.VideoHeight + '，视频编码：' + $targetClip.VideoCodecAll + ' ' + $targetClip.VideoFps + '，音频编码：' + $targetClip.AudioCodecAll + ' ' + $targetClip.AudioSampleRate + ' ' + $targetClip.VideoTimeBase);
            foreach ($clip in $probeList) {
                $transcoded = [System.IO.Path]::Combine($workingDir, [System.IO.Path]::GetFileNameWithoutExtension($clip.Name) + '_h264_' + $suffixSafe + '.mp4');
                Write-Host ('重新编码视频："' + $clip.Path + '" - "' + $transcoded + '"');
                if (-not [System.IO.File]::Exists($transcoded)) {
                    $ffmpegArgs = [System.Collections.Generic.List[string]]::new();
                    $ffmpegArgs.AddRange([string[]]@('-i', $clip.Path, '-vf', $scaleFilter, '-video_track_timescale', $targetTimebase, '-c:v', 'libx264', '-r', $targetClip.VideoFps, '-c:a'));
                    $ffmpegArgs.AddRange([string[]]$targetAudioArgs.ToArray());
                    $ffmpegArgs.AddRange([string[]]@('-ar', $targetClip.AudioSampleRate, '-map_metadata', '-1', $transcoded));
                    [void](Invoke-FFmpeg -ArgList $ffmpegArgs.ToArray());
                }
                $videoFileList.Add((Format-Concat-Line -FilePath $transcoded));
            }
        } else {
            Write-Host '';
            Write-Host '分段视频的参数不一致，请选择按 Enter 键开始转码，或者关闭窗口结束运行';
            Write-Host '';
            Wait-Enter-Key;
            Write-Host ('正在转码视频，目标分辨率：' + $targetClip.VideoWidth + 'x' + $targetClip.VideoHeight + '，视频编码：' + $targetClip.VideoCodecAll + ' ' + $targetClip.VideoFps + '，音频编码：' + $targetClip.AudioCodecAll + ' ' + $targetClip.AudioSampleRate + ' ' + $targetClip.VideoTimeBase);
            $tempCount = 0;
            foreach ($clip in $probeList) {
                $tempCount++;
                Write-Host ('第 ' + $tempCount + ' 个视频，分辨率：' + $clip.VideoWidth + 'x' + $clip.VideoHeight + '，视频编码：' + $clip.VideoCodecAll + ' ' + $clip.VideoFps + '，音频编码：' + $clip.AudioCodecAll + ' ' + $clip.AudioSampleRate + ' ' + $clip.VideoTimeBase);
                Write-Host '视频信息对比完成';

                $transcoded = [System.IO.Path]::Combine($workingDir, [System.IO.Path]::GetFileNameWithoutExtension($clip.Name) + '_' + $suffixSafe + '.mp4');
                if (-not $clip.VideoConsistent) {
                    Write-Host ('重新编码视频："' + $clip.Path + '" - "' + $transcoded + '"');
                    if (-not [System.IO.File]::Exists($transcoded)) {
                        $ffmpegArgs = [System.Collections.Generic.List[string]]::new();
                        $ffmpegArgs.AddRange([string[]]@('-i', $clip.Path, '-vf', $scaleFilter, '-video_track_timescale', $targetTimebase, '-c:v'));
                        $ffmpegArgs.AddRange([string[]]$targetVideoArgs.ToArray());
                        $ffmpegArgs.AddRange([string[]]@('-r', $targetClip.VideoFps, '-c:a'));
                        if ($clip.AudioConsistent) {
                            $ffmpegArgs.Add('copy');
                        } else {
                            $ffmpegArgs.AddRange([string[]]$targetAudioArgs.ToArray());
                            $ffmpegArgs.AddRange([string[]]@('-ar', $targetClip.AudioSampleRate));
                        }
                        $ffmpegArgs.AddRange([string[]]@('-map_metadata', '-1', $transcoded));
                        [void](Invoke-FFmpeg -ArgList $ffmpegArgs.ToArray());
                    }
                    $videoFileList.Add((Format-Concat-Line -FilePath $transcoded));
                } elseif (-not $clip.AudioConsistent) {
                    Write-Host ('重新编码视频："' + $clip.Path + '" - "' + $transcoded + '"');
                    if (-not [System.IO.File]::Exists($transcoded)) {
                        $ffmpegArgs = [System.Collections.Generic.List[string]]::new();
                        $ffmpegArgs.AddRange([string[]]@('-i', $clip.Path, '-c:v', 'copy', '-c:a'));
                        $ffmpegArgs.AddRange([string[]]$targetAudioArgs.ToArray());
                        $ffmpegArgs.AddRange([string[]]@('-ar', $targetClip.AudioSampleRate, '-map_metadata', '-1', $transcoded));
                        [void](Invoke-FFmpeg -ArgList $ffmpegArgs.ToArray());
                    }
                    $videoFileList.Add((Format-Concat-Line -FilePath $transcoded));
                } else {
                    $videoFileList.Add((Format-Concat-Line -FilePath $clip.Path));
                }
            }
        }
        [System.IO.File]::WriteAllLines($concatList, [string[]]$videoFileList.ToArray(), $utf8NoBOM);
    }

    Write-Host '正在合并视频';
    $code = Invoke-FFmpeg -ArgList @('-y', '-f', 'concat', '-safe', '0', '-i', $concatList, '-c', 'copy', '-metadata', ('creation_time=' + $creationTime), '-movflags', '+faststart', $mergedVideo);
    if ($code -ne 0) { throw '视频合并失败，请检查报错信息' }
    if (-not [System.IO.File]::Exists($mergedVideo)) { throw '合并失败，请检查报错信息' }

    # 兼容 webp 封面
    foreach ($base in @('0', '00', '000', 'cover', '封面', '海报')) {
        $webpName = $base + '.webp';
        $pngName = $base + '.png';
        if (-not $fileNames.Contains($pngName) -and $fileNames.Contains($webpName)) {
            Write-Host ('检测到封面 ' + $webpName + '，正在转换为 ' + $pngName);
            $code = Invoke-FFmpeg -ArgList @('-y', '-i', [System.IO.Path]::Combine($workingDir, $webpName), '-frames:v', '1', '-update', '1', [System.IO.Path]::Combine($workingDir, $pngName));
            if ($code -eq 0) { [void]$fileNames.Add($pngName) }
        }
    }

    # 查找封面，优先 PNG
    $coverFile = '';
    foreach ($candidate in @('0.png', '0.jpg', '0.jpeg', '00.png', '00.jpg', '00.jpeg', '000.png', '000.jpg', '000.jpeg', 'cover.png', 'cover.jpg', 'cover.jpeg', '封面.png', '封面.jpg', '封面.jpeg', '海报.png', '海报.jpg', '海报.jpeg')) {
        if ($fileNames.Contains($candidate)) { $coverFile = [System.IO.Path]::Combine($workingDir, $candidate); break }
    }

    # 无封面时从 DVD 菜单片段提取
    if ($coverFile -eq '') {
        for ($t = 1; $t -le 99; $t++) {
            $menuName = 'VTS_' + $t.ToString('00') + '_0.VOB';
            if (-not $fileNames.Contains($menuName)) { continue; }
            Write-Host ('正在将菜单片段 ' + $menuName + ' 中的画面提取为封面 cover.png');
            $coverPng = [System.IO.Path]::Combine($workingDir, 'cover.png');
            $code = Invoke-FFmpeg -ArgList @('-y', '-i', [System.IO.Path]::Combine($workingDir, $menuName), '-map', '0:v:0', '-frames:v', '1', '-vf', 'scale=iw*sar:ih', '-update', '1', $coverPng);
            if ($code -ne 0) {
                Write-Host ('菜单片段 ' + $menuName + ' 的画面提取失败');
                if ([System.IO.File]::Exists($coverPng)) { [System.IO.File]::Delete($coverPng) }
            } elseif (-not [System.IO.File]::Exists($coverPng)) {
                Write-Host ('菜单片段 ' + $menuName + ' 中没有可提取的画面');
            } else {
                $coverFile = $coverPng;
                break;
            }
        }
    }

    if ($coverFile -ne '') {
        $coverProbe = Get-Tool-Output -ExePath $ffprobePath -ArgList @('-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=codec_name', '-of', 'default=noprint_wrappers=1:nokey=1', $coverFile);
        $coverType = $coverProbe.Text.Trim();
        Write-Host ('封面图片编码：[' + $coverType + ']');
        if ($coverType -ne 'png' -and $coverType -ne 'mjpeg') {
            Write-Host '封面图片只支持 PNG 和 JPG 格式，其他格式则需要转换为 PNG';
            $code = Invoke-FFmpeg -ArgList @('-y', '-i', $coverFile, '-frames:v', '1', '-update', '1', ($coverFile + '.png'));
            if ($code -ne 0) { throw '封面图片格式转换失败，请检查报错信息' }
            $coverFile = $coverFile + '.png';
        }
        Write-Host ('正在添加封面图片 [' + $coverFile + ']');
        $code = Invoke-FFmpeg -ArgList @('-y', '-i', $mergedVideo, '-i', $coverFile, '-map', '0', '-map', '1', '-c', 'copy', '-disposition:v:1', 'attached_pic', '-metadata', ('creation_time=' + $creationTime), '-movflags', '+faststart', $finalVideo);
        if ($code -ne 0) { throw '文件 final.mp4 合并失败，请检查报错信息' }
    } else {
        Write-Host '封面文件，例如 0.png、00.png、000.png、cover.png、封面.png、海报.png 等，都不存在，不添加封面';
        if ([System.IO.File]::Exists($finalVideo)) { [System.IO.File]::Delete($finalVideo) }
        try {
            [System.IO.File]::Move($mergedVideo, $finalVideo);
        } catch {
            [System.IO.File]::Copy($mergedVideo, $finalVideo);
        }
    }
    Write-Host ('合并完成，已生成 ' + $finalVideo + ' 文件');
} catch {
    Write-Host ('错误：' + ($_.Exception.Message -replace '^错误：', '')) -ForegroundColor Red;
    Remove-Temp-Files;
    exit 1;
}

Remove-Temp-Files;
-----END POWERSHELL CODE-----
