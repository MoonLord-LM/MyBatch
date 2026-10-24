@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
set "param2=%~2" & set "param2_path=%~f2" & set "param2_dir=%~dp2" & set "param2_name=%~n2" & set "param2_ext=%~x2" & set "param2_name_ext=%~nx2"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '搜索和清理重复图片，将会清理第 1 个文件夹中的，已经在第 2 个文件夹中存在的内容相似的图片' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入两个文件夹路径' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '也可以选中两个文件夹，拖拽到此脚本上，自动识别处理' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '当两次输入的文件夹路径相同时，则清理该文件夹自身的重复图片，保留体积最大的那一张' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '两张图片的差异评分不高于阈值时，即判定为重复，将重复图片删除到回收站' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '图片特征提取：使用 256*256 的像素采样格，逐格计算全部像素的 R G B 平均值，得到 256*256*3 个字节的特征值' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '差异评分计算方式：计算不同图片的相同位置的采样格的 R G B 值的空间距离，最后计算全部格子的平均值' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '差异评分计算时，会尝试做 8 种变换：旋转 0、90、180、270 度，以及水平、垂直、主对角、副对角镜像，取最小的值' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 jpg jpeg png webp bmp gif tif tiff heic heif avif' -ForegroundColor Green"
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



set "path1=!param1!"
set "path2=!param2!"

:input_path1
    if "!path1!"=="" (
        echo 请输入要清理多余图片的文件夹
        set /p "path1="
        if !errorlevel! neq 0 (
            echo 无输入，退出脚本
            echo.
            exit /b 1
        )
        echo.
    ) else (
        echo 要清理多余图片的文件夹："!path1!"
        echo.
    )
    if "!path1!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_path1
    )
    set "path1=!path1:"=!"
    if "!path1!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_path1
    )
    if "!path1:~-1!"=="\" set "path1=!path1:~0,-1!"
    if not exist "!path1!" (
        echo 错误：路径 1 不存在："!path1!"，请重新输入
        echo.
        set "path1="
        goto input_path1
    )
    if not exist "!path1!\" (
        echo 错误：路径 1 不是文件夹："!path1!"，请重新输入
        echo.
        set "path1="
        goto input_path1
    )

:input_path2
    if "!path2!"=="" (
        echo 请输入作为参考的文件夹，仅用于图片比对
        set /p "path2="
        if !errorlevel! neq 0 (
            echo 无输入，退出脚本
            echo.
            exit /b 1
        )
        echo.
    ) else (
        echo 作为参考的文件夹，仅用于图片比对："!path2!"
        echo.
    )
    if "!path2!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_path2
    )
    set "path2=!path2:"=!"
    if "!path2!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_path2
    )
    if "!path2:~-1!"=="\" set "path2=!path2:~0,-1!"
    if not exist "!path2!" (
        echo 错误：路径 2 不存在："!path2!"，请重新输入
        echo.
        set "path2="
        goto input_path2
    )
    if not exist "!path2!\" (
        echo 错误：路径 2 不是文件夹："!path2!"，请重新输入
        echo.
        set "path2="
        goto input_path2
    )

:input_threshold
    echo 请输入判定为重复图片的差异评分阈值 & REM
    echo 取值范围为 0 到 1，数值越小判定越严格，默认值为 0.025 & REM
    set /p "score_threshold="
    if !errorlevel! neq 0 (
        set "score_threshold=0.025"
    )
    echo.
    set "score_threshold=!score_threshold:"=!"
    if "!score_threshold: =!"=="" (
        set "score_threshold=0.025"
    )
    set "score_threshold_is_valid=0"
    for /f "delims=" %%v in ('
        powershell -NoProfile -Command ^
            "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
            "$n = [double]0;" ^
            "if ([double]::TryParse($env:score_threshold, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$n) -and $n -ge 0 -and $n -le 1) {" ^
            "    Write-Output $n.ToString([System.Globalization.CultureInfo]::InvariantCulture);" ^
            "}"
    ') do (
        set "score_threshold_is_valid=1"
        set "score_threshold=%%v"
    )
    if "!score_threshold_is_valid!"=="0" (
        echo 错误：差异评分阈值不是 0 到 1 之间的数字："!score_threshold!"，请重新输入
        echo.
        set "score_threshold="
        goto input_threshold
    )



echo 清理文件夹："!path1!" & REM
echo 参考文件夹："!path2!" & REM
echo 差异评分阈值："!score_threshold!" & REM
echo.
if /i "!path1!"=="!path2!" (
    echo 提示：两次输入的文件夹相同，将清理该文件夹自身的重复图片
    echo.
)

REM 从自身文件末尾的 -----BEGIN POWERSHELL CODE----- / -----END POWERSHELL CODE----- 之间提取 Powershell 代码
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
    echo 图片比对失败，请检查报错信息
    echo.
    pause
    exit /b 1
)



echo.
pause
exit /b



-----BEGIN POWERSHELL CODE-----
[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;

$gridSize = 256;
$cellCount = $gridSize * $gridSize;
$cellByteCount = $cellCount * 3;
$transformNames = @('原图', '顺时针 90 度', '旋转 180 度', '逆时针 90 度', '水平镜像', '垂直镜像', '主对角镜像', '副对角镜像');

$ffmpegPath = $env:ffmpeg_path;
$dir1 = $env:path1;
$dir2 = $env:path2;
$threshold = [double]::Parse($env:score_threshold, [System.Globalization.CultureInfo]::InvariantCulture);
$selfMode = ($dir1 -eq $dir2);
$extFilter = '^\.(jpg|jpeg|png|webp|bmp|gif|tif|tiff|heic|heif|avif)$';

Add-Type -AssemblyName Microsoft.VisualBasic;

Add-Type -TypeDefinition @'
using System;

public static class ImgDiffKernel
{
    // 8 种等价变换，覆盖 4 个旋转与 2 个镜像的组合
    // 0 原图 1 顺时针 90 度 2 旋转 180 度 3 逆时针 90 度 4 水平镜像 5 垂直镜像 6 主对角镜像 7 副对角镜像
    public const int TransformCount = 8;

    private static int[][] fineMap;

    public static void Init(int gridSize)
    {
        fineMap = BuildMaps(gridSize);
    }

    // 预计算每种变换下，目标格 (x, y) 所对应源数据的字节偏移，避免在比对时反复做坐标换算
    private static int[][] BuildMaps(int n)
    {
        int[][] maps = new int[TransformCount][];
        for (int t = 0; t < TransformCount; t++) {
            int[] map = new int[n * n];
            for (int y = 0; y < n; y++) {
                for (int x = 0; x < n; x++) {
                int sx;
                int sy;
                switch (t) {
                    case 0: sx = x; sy = y; break;
                    case 1: sx = y; sy = n - 1 - x; break;
                    case 2: sx = n - 1 - x; sy = n - 1 - y; break;
                    case 3: sx = n - 1 - y; sy = x; break;
                    case 4: sx = n - 1 - x; sy = y; break;
                    case 5: sx = x; sy = n - 1 - y; break;
                    case 6: sx = y; sy = x; break;
                    default: sx = n - 1 - y; sy = n - 1 - x; break;
                }
                map[y * n + x] = (sy * n + sx) * 3;
                }
            }
            maps[t] = map;
        }
        return maps;
    }

    // 按指定变换逐格累加距离；累加值一旦超过 budget 就提前结束，返回值小于 0 表示超出预算
    private static double FineDistanceTransformed(byte[] a, byte[] b, int t, double budget)
    {
        int[] map = fineMap[t];
        int cellCount = map.Length;
        double sum = 0;
        for (int i = 0; i < cellCount; i++) {
            int j = map[i];
            double dr = (a[i * 3] - b[j]) / 255.0;
            double dg = (a[i * 3 + 1] - b[j + 1]) / 255.0;
            double db = (a[i * 3 + 2] - b[j + 2]) / 255.0;
            sum += Math.Sqrt(dr * dr + dg * dg + db * db);
            if (sum > budget) { return -1; }
        }
        return sum / cellCount;
    }

    // 遍历 8 种变换，每种都按 256*256 逐格完整计算，取最小的差异评分，并给出取得最小值的变换
    public static double MinFineDistance(byte[] a, byte[] b, out int transform)
    {
        double best = -1;
        transform = -1;
        for (int t = 0; t < TransformCount; t++) {
            // 已经算出更小的结果时，用它折算出的距离和作为预算，超出预算的变换不可能是最小值所在
            double budget = (best < 0) ? double.MaxValue : (best * fineMap[t].Length);
            double v = FineDistanceTransformed(a, b, t, budget);
            if (v < 0) { continue; }
            if (best < 0 || v < best) { best = v; transform = t; }
        }
        return best;
    }
}
'@;

[ImgDiffKernel]::Init($gridSize);

$files1 = @(Get-ChildItem -LiteralPath $dir1 -File -Force -Recurse | Where-Object { $_.Extension -match $extFilter } | Sort-Object FullName);
if ($selfMode) {
    # 自比对时按文件体积从大到小处理，保证同一组重复图片中保留体积最大的那一张
    $files1 = @($files1 | Sort-Object -Property @{ Expression = { $_.Length }; Descending = $true }, @{ Expression = { $_.FullName }; Descending = $false });
    $files2 = @();
} else {
    $files2 = @(Get-ChildItem -LiteralPath $dir2 -File -Force -Recurse | Where-Object { $_.Extension -match $extFilter } | Sort-Object FullName);
}

$referenceList = New-Object System.Collections.Generic.List[object];
foreach ($f in $files2) { $referenceList.Add($f) }

Write-Host ('清理文件夹中找到 ' + $files1.Count + ' 个图片文件');
if ($selfMode) {
    Write-Host '两次输入的文件夹相同，将清理该文件夹自身的重复图片';
} else {
    Write-Host ('参考文件夹中找到 ' + $files2.Count + ' 个图片文件');
}
Write-Host '';
if ($files1.Count -eq 0) {
    Write-Host '清理文件夹中没有找到指定格式的图片文件';
    exit 0;
}

# 逐个生成图片特征：缩放到 256*256 的像素采样格，每个格子取原始像素的平均 R G B 值
$entryMap = @{};
$pathList = New-Object System.Collections.Generic.List[string];
foreach ($f in $files1) { if (-not $entryMap.ContainsKey($f.FullName)) { $entryMap[$f.FullName] = $null; $pathList.Add($f.FullName) } }
foreach ($f in $files2) { if (-not $entryMap.ContainsKey($f.FullName)) { $entryMap[$f.FullName] = $null; $pathList.Add($f.FullName) } }

for ($k = 0; $k -lt $pathList.Count; $k++) {
    $p = $pathList[$k];
    Write-Host ('正在生成图片特征：[' + ($k + 1) + '/' + $pathList.Count + ']');
    Write-Host ('"' + $p + '"');
    $psi = New-Object System.Diagnostics.ProcessStartInfo;
    $psi.FileName = $ffmpegPath;
    $psi.Arguments = '-nostdin -v error -y -i "' + $p + '" -vf "format=rgb24,scale=' + $gridSize + ':' + $gridSize + ':flags=area" -pix_fmt rgb24 -f rawvideo -frames:v 1 -';
    $psi.UseShellExecute = $false;
    $psi.CreateNoWindow = $true;
    $psi.RedirectStandardOutput = $true;
    $psi.RedirectStandardError = $true;
    $proc = [System.Diagnostics.Process]::Start($psi);
    $errTask = $proc.StandardError.ReadToEndAsync();
    $fine = New-Object byte[] $cellByteCount;
    $readCount = 0;
    while ($readCount -lt $cellByteCount) {
        $n = $proc.StandardOutput.BaseStream.Read($fine, $readCount, $cellByteCount - $readCount);
        if ($n -le 0) { break }
        $readCount += $n;
    }
    $proc.StandardOutput.BaseStream.Dispose();
    $proc.WaitForExit();
    $exitCode = $proc.ExitCode;
    $null = $errTask.Result;
    $proc.Dispose();
    if ($exitCode -ne 0) {
        Write-Host '图片解析失败，跳过此文件';
        Write-Host '';
        continue;
    }
    if ($readCount -ne $cellByteCount) {
        Write-Host '图片特征长度异常，跳过此文件';
        Write-Host '';
        continue;
    }
    $entryMap[$p] = $fine;
}
Write-Host '';

# 逐对比对：每个格子的 R G B 差值除以 255 作为 XYZ 坐标，取空间距离后求全部格子的平均值
# 每组比对都会遍历 8 种旋转与镜像的等价变换，取其中最小的差异评分
$total = 0;
$duplicate = 0;
$deleted = 0;
$failed = 0;
$parseFailed = 0;
$removedMap = @{};

Write-Host ('开始比对差异评分，评分不高于 ' + $threshold.ToString('F6') + ' 即判定为重复');
Write-Host '';

for ($i = 0; $i -lt $files1.Count; $i++) {
    $f1 = $files1[$i];
    $total++;
    if ($removedMap.ContainsKey($f1.FullName)) { continue }
    $e1 = $entryMap[$f1.FullName];
    if ($null -eq $e1) {
        $parseFailed++;
        Write-Host '跳过，图片解析失败：';
        Write-Host ('"' + $f1.FullName + '"');
        continue;
    }

    $keepFile = $null;
    $dropFile = $null;
    $scoreValue = 0;
    $scoreTransform = 0;
    $nearestFile = $null;
    $nearestValue = -1;
    $nearestTransform = 0;
    for ($j = 0; $j -lt $referenceList.Count; $j++) {
        $f2 = $referenceList[$j];
        if ($f2.FullName -eq $f1.FullName) { continue }
        if ($removedMap.ContainsKey($f2.FullName)) { continue }
        $e2 = $entryMap[$f2.FullName];
        if ($null -eq $e2) { continue }
        $hitTransform = -1;
        $scoreValue = [ImgDiffKernel]::MinFineDistance($e1, $e2, [ref]$hitTransform);
        if ($nearestValue -lt 0 -or $scoreValue -lt $nearestValue) {
            $nearestValue = $scoreValue;
            $nearestFile = $f2;
            $nearestTransform = $hitTransform;
        }
        if ($scoreValue -gt $threshold) { continue }
        $scoreTransform = $hitTransform;
        $keepFile = $f2;
        $dropFile = $f1;
        break;
    }

    if ($null -eq $dropFile) {
        if ($null -eq $nearestFile) {
            Write-Host '无参考图片';
            Write-Host ('保留："' + $f1.FullName + '"');
            Write-Host '';
        } else {
            Write-Host ('差异评分 ' + $nearestValue.ToString('F6') + '（' + $transformNames[$nearestTransform] + '），判定不重复');
            Write-Host ('保留："' + $f1.FullName + '"');
            Write-Host ('最接近："' + $nearestFile.FullName + '"');
            Write-Host '';
        }
        if ($selfMode) { $referenceList.Add($f1) }
        continue;
    }

    $duplicate++;
    Write-Host ('差异评分 ' + $scoreValue.ToString('F6') + '（' + $transformNames[$scoreTransform] + '），判定重复');
    Write-Host ('保留："' + $keepFile.FullName + '"');
    Write-Host ('删除："' + $dropFile.FullName + '"');

    $deleteError = '';
    try {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($dropFile.FullName, 'OnlyErrorDialogs', 'SendToRecycleBin');
    } catch {
        $deleteError = $_.Exception.Message;
    }
    if ($deleteError -ne '') {
        $failed++;
        Write-Host ('删除失败，报错信息：' + $deleteError);
        Write-Host '';
    } elseif (Test-Path -LiteralPath $dropFile.FullName) {
        $failed++;
        Write-Host '删除失败'
        Write-Host '';
    } else {
        $deleted++;
        $removedMap[$dropFile.FullName] = $true;
        Write-Host '已删除到回收站';
        Write-Host '';
    }
}

Write-Host ('处理完成，共计：' + $total + ' 个图片，重复：' + $duplicate + ' 个，删除成功：' + $deleted + ' 个，删除失败：' + $failed + ' 个，解析失败：' + $parseFailed + ' 个');
exit 0;
-----END POWERSHELL CODE-----
