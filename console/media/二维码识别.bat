@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '从图片中识别二维码并解码为文本' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时手动输入图片路径；也可以拖拽单个二维码图片文件到此脚本上' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '对一个图片处理完成后，可继续输入下一个图片' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持 jpg png bmp gif webp tif svg 等常见图片格式' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '小图自动放大后识别，并尝试识别反色二维码' -ForegroundColor Green"
echo.



REM 检查 ZXing.Net 组件
set "zxing_path="
if exist "!script_dir!zxing.dll" (
    set "zxing_path=!script_dir!zxing.dll"
) else if exist "!cd!\zxing.dll" (
    set "zxing_path=!cd!\zxing.dll"
) else if exist "!script_dir!..\zxing.dll" (
    set "zxing_path=!script_dir!..\zxing.dll"
) else if exist "..\zxing.dll" (
    set "zxing_path=..\zxing.dll"
)
if "!zxing_path!" == "" (
    echo 错误：缺少 ZXing.Net 组件 & REM
    echo 请从 https://github.com/micjahn/ZXing.Net/releases 下载，然后把 net4.5 目录下的 zxing.dll 放到脚本所在文件夹 & REM
    "explorer.exe" "https://github.com/micjahn/ZXing.Net/releases"
    echo.
    pause
    exit /b 1
)



set "target=!param1!"
set "inner_begin_marker=-----BEGIN POWERSHELL CODE-----"
set "inner_end_marker=-----END POWERSHELL CODE-----"



:loop

    :input_file
        if "!target!"=="" (
            echo 请输入要识别的二维码图片路径：
            set /p "target="
            if !errorlevel! neq 0 (
                echo 无输入，退出脚本
                echo.
                exit /b 1
            )
            echo.
        ) else (
            echo 要识别的二维码图片："!target!"
            echo.
        )
        if "!target!"=="" (
            echo 输入不能为空，请重新输入
            echo.
            goto input_file
        )
        set "target=!target:"=!"
        if "!target!"=="" (
            echo 输入不能为空，请重新输入
            echo.
            goto input_file
        )
        if "!target:~-1!"=="\" set "target=!target:~0,-1!"
        if not exist "!target!" (
            echo 文件不存在 "!target!"，请重新输入
            echo.
            set "target="
            goto input_file
        )
        if exist "!target!\" (
            echo 不支持文件夹 "!target!"，请重新输入
            echo.
            set "target="
            goto input_file
        )



    for %%i in ("!target!") do set "out_dir=%%~dpi"



    REM 提取并执行内嵌 PowerShell 代码
    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
        "$utf8Strict = [System.Text.Encoding]::GetEncoding(65001, [System.Text.EncoderFallback]::ExceptionFallback, [System.Text.DecoderFallback]::ExceptionFallback);" ^
        "try { $lines = [System.IO.File]::ReadAllLines($env:script_path, $utf8Strict) } catch [System.Text.DecoderFallbackException] {" ^
        "    Write-Host '错误：脚本文件不是 UTF-8 编码' -ForegroundColor Red;" ^
        "    exit 1;" ^
        "};" ^
        "$begin = [array]::IndexOf($lines, $env:inner_begin_marker) + 1;" ^
        "$end = [array]::IndexOf($lines, $env:inner_end_marker);" ^
        "if ($begin -lt 1 -or $end -lt $begin) {" ^
        "    Write-Host '错误：未找到内嵌的 PowerShell 代码块' -ForegroundColor Red;" ^
        "    exit 1;" ^
        "};" ^
        "$code = ($lines[$begin..($end - 1)] -join [System.Environment]::NewLine);" ^
        "Invoke-Expression $code"
    if !errorlevel! neq 0 (
        echo 识别失败，请检查报错信息
        echo.
    )

    echo.
    set "target="

goto loop



echo.
pause
exit /b



-----BEGIN POWERSHELL CODE-----
[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;
$ErrorActionPreference = 'Stop';
try {
    Add-Type -Path $env:zxing_path;
    Add-Type -AssemblyName PresentationCore;
    Add-Type -AssemblyName WindowsBase;

    $reader = [ZXing.BarcodeReader]::new();
    $reader.Options.CharacterSet = 'UTF-8';
    $reader.Options.TryHarder = $true;
    $reader.Options.TryInverted = $true;
    $reader.Options.PossibleFormats = [System.Collections.Generic.List[ZXing.BarcodeFormat]]::new();
    $reader.Options.PossibleFormats.Add([ZXing.BarcodeFormat]::QR_CODE);

    $minSide = 300;

    # 读取图片并解码二维码
    function Read-QrCode([string]$ImagePath) {
        # SVG：按 rect 与 path 重建模块矩阵
        if ([System.IO.Path]::GetExtension($ImagePath) -ieq '.svg') {
            $svgUtf8 = [System.Text.Encoding]::GetEncoding(65001, [System.Text.EncoderFallback]::ExceptionFallback, [System.Text.DecoderFallback]::ExceptionFallback);
            $svgText = [System.IO.File]::ReadAllText($ImagePath, $svgUtf8);
            $viewBox = [regex]::Match($svgText, 'viewBox="0 0 (\d+) (\d+)"');
            if (-not $viewBox.Success) {
                return $null;
            }
            $svgWidth = [int]$viewBox.Groups[1].Value;
            $svgHeight = [int]$viewBox.Groups[2].Value;
            $unit = [int]([System.Math]::Max(1, [System.Math]::Ceiling($minSide / [System.Math]::Min($svgWidth, $svgHeight))));
            $width = $svgWidth * $unit;
            $height = $svgHeight * $unit;
            $pixels = New-Object byte[] ($width * $height * 4);
            $whiteRow = New-Object byte[] ($width * 4);
            for ($i = 0; $i -lt $whiteRow.Length; $i++) {
                $whiteRow[$i] = 255;
            }
            for ($y = 0; $y -lt $height; $y++) {
                [System.Buffer]::BlockCopy($whiteRow, 0, $pixels, $y * $width * 4, $whiteRow.Length);
            }
            $fillBlack = {
                param([int]$areaX, [int]$areaY, [int]$areaWidth, [int]$areaHeight)
                $blackRow = New-Object byte[] ($areaWidth * 4);
                for ($i = 3; $i -lt $blackRow.Length; $i += 4) {
                    $blackRow[$i] = 255;
                }
                for ($py = $areaY; $py -lt ($areaY + $areaHeight); $py++) {
                    [System.Buffer]::BlockCopy($blackRow, 0, $pixels, ($py * $width + $areaX) * 4, $blackRow.Length);
                }
            };
            foreach ($tagMatch in [regex]::Matches($svgText, '<rect\b[^>]*>')) {
                $tag = $tagMatch.Value;
                if ($tag -match 'fill="(?:white|#fff(?:fff)?|rgb\(255\s*,\s*255\s*,\s*255\))"') {
                    continue;
                }
                $xMatch = [regex]::Match($tag, '\bx="(\d+)"');
                $yMatch = [regex]::Match($tag, '\by="(\d+)"');
                $wMatch = [regex]::Match($tag, '\bwidth="(\d+)"');
                $hMatch = [regex]::Match($tag, '\bheight="(\d+)"');
                if (-not ($xMatch.Success -and $yMatch.Success -and $wMatch.Success -and $hMatch.Success)) {
                    continue;
                }
                $rectX = [int]$xMatch.Groups[1].Value * $unit;
                $rectY = [int]$yMatch.Groups[1].Value * $unit;
                $rectWidth = [int]$wMatch.Groups[1].Value * $unit;
                $rectHeight = [int]$hMatch.Groups[1].Value * $unit;
                & $fillBlack $rectX $rectY $rectWidth $rectHeight;
            }
            foreach ($pathMatch in [regex]::Matches($svgText, '<path\b[^>]*>')) {
                $tag = $pathMatch.Value;
                if ($tag -match 'fill="(?:white|#fff(?:fff)?|rgb\(255\s*,\s*255\s*,\s*255\))"') {
                    continue;
                }
                $pathData = [regex]::Match($tag, '\bd="([^"]+)"');
                if (-not $pathData.Success) {
                    continue;
                }
                foreach ($cmd in [regex]::Matches($pathData.Groups[1].Value, 'M(\d+)\s+(\d+)h(\d+)v(\d+)h-\d+z')) {
                    $cmdX = [int]$cmd.Groups[1].Value * $unit;
                    $cmdY = [int]$cmd.Groups[2].Value * $unit;
                    $cmdWidth = [int]$cmd.Groups[3].Value * $unit;
                    $cmdHeight = [int]$cmd.Groups[4].Value * $unit;
                    & $fillBlack $cmdX $cmdY $cmdWidth $cmdHeight;
                }
            }
            $svgResult = $reader.Decode($pixels, $width, $height, [ZXing.RGBLuminanceSource+BitmapFormat]::BGRA32);
            if ($svgResult -eq $null) {
                return $null;
            }
            return $svgResult.Text;
        }
        $stream = [System.IO.File]::OpenRead($ImagePath);
        try {
            $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create($stream, [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat, [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad);
            $frame = $decoder.Frames[0];
            $converted = [System.Windows.Media.Imaging.FormatConvertedBitmap]::new();
            $converted.BeginInit();
            $converted.Source = $frame;
            $converted.DestinationFormat = [System.Windows.Media.PixelFormats]::Bgra32;
            $converted.EndInit();
            $imageSource = $converted;
            $narrowSide = [System.Math]::Min($converted.PixelWidth, $converted.PixelHeight);
            if ($narrowSide -lt $minSide) {
                $scale = [double]$minSide / [double]$narrowSide;
                $scaled = [System.Windows.Media.Imaging.TransformedBitmap]::new();
                $scaled.BeginInit();
                $scaled.Source = $converted;
                $scaled.Transform = [System.Windows.Media.ScaleTransform]::new($scale, $scale);
                $scaled.EndInit();
                $imageSource = $scaled;
            }
            $width = $imageSource.PixelWidth;
            $height = $imageSource.PixelHeight;
            $pixels = New-Object byte[] ($width * $height * 4);
            $imageSource.CopyPixels($pixels, $width * 4, 0);
            $result = $reader.Decode($pixels, $width, $height, [ZXing.RGBLuminanceSource+BitmapFormat]::BGRA32);
            if ($result -eq $null) {
                return $null;
            }
            return $result.Text;
        } finally {
            $stream.Dispose();
        }
    }

    try {
        $text = Read-QrCode -ImagePath $env:target;
    } catch {
        Write-Host ('错误：图片无法读取或格式不受支持："' + $env:target + '"') -ForegroundColor Red;
        exit 1;
    }
    if ([string]::IsNullOrEmpty($text)) {
        Write-Host ('错误：未在图片中识别到二维码，请确认图片清晰、二维码完整："' + $env:target + '"') -ForegroundColor Red;
        exit 3;
    }
    Write-Host ('识别内容：' + $text);
    $name = [System.IO.Path]::GetFileNameWithoutExtension($env:target);
    $txtPath = [System.IO.Path]::Combine($env:out_dir, $name + '_二维码内容.txt');
    [System.IO.File]::WriteAllText($txtPath, $text, [System.Text.UTF8Encoding]::new($false));
    Write-Host ('保存文件："' + $txtPath + '"');
} catch {
    Write-Host ('错误：识别二维码失败：' + $_.Exception.Message) -ForegroundColor Red;
    exit 1;
}
exit 0;
-----END POWERSHELL CODE-----
