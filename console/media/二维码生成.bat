@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将输入的文本编码为二维码' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '输出同名位图：.1bit.png（1-bit PNG）、.png（8-bit PNG）、.jpg（最佳质量），每模块 8 像素' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '输出同名矢量图 .svg，以及内嵌 1-bit PNG 的 .html 与 .md 文本文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入要生成二维码的文本；不支持拖拽文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '对一个文本处理完成后，可继续输入下一个文本' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持中文、网址与任意文本；采用 UTF-8 编码，纠错等级为最高（H），四周预留 4 模块静区' -ForegroundColor Green"
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



if not "!param1!" == "" (
    echo 错误：不支持拖拽文件，请双击运行后手动输入文本
    echo.
    pause
    exit /b 1
)



set "temp_text=%temp%\MyBatch_%random%_%random%_%random%_%random%.txt"
set "in_file=!temp_text!"
set "out_dir=!cd!"
if "!out_dir:~-1!"=="\" set "out_dir=!out_dir:~0,-1!"
set "ps_file=%temp%\MyBatch_%random%_%random%_%random%_%random%.ps1"
set "inner_begin_marker=-----BEGIN POWERSHELL CODE-----"
set "inner_end_marker=-----END POWERSHELL CODE-----"
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
    "[System.IO.File]::WriteAllText($env:ps_file, $code, [System.Text.UTF8Encoding]::new($true));"
if !errorlevel! neq 0 (
    if exist "!ps_file!" ( del /f /q "!ps_file!" )
    echo 错误：提取内嵌脚本失败 & REM
    echo.
    pause
    exit /b 1
)



:loop

    :input_text
        echo 请输入要生成二维码的文本：
        set /p "qr_text="
        if !errorlevel! neq 0 (
            echo 无输入，退出脚本
            echo.
            if exist "!ps_file!" ( del /f /q "!ps_file!" )
            if exist "!temp_text!" ( del /f /q "!temp_text!" )
            exit /b 1
        )
        echo.
        if "!qr_text!"=="" (
            echo 输入不能为空，请重新输入
            echo.
            goto input_text
        )



    powershell -NoProfile -Command ^
        "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
        "[System.IO.File]::WriteAllText($env:temp_text, $env:qr_text, [System.Text.Encoding]::UTF8)"
    if !errorlevel! neq 0 (
        echo 错误：保存输入文本失败
        echo.
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -File "!ps_file!"
    )

    echo.
    set "qr_text="

goto loop



echo.
pause
exit /b



-----BEGIN POWERSHELL CODE-----
[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;
$ErrorActionPreference = 'Stop';
try {
    Add-Type -Path $env:zxing_path;
    Add-Type -AssemblyName System.Drawing;
    Add-Type -AssemblyName PresentationCore;
    Add-Type -AssemblyName WindowsBase;

    $utf8Strict = [System.Text.Encoding]::GetEncoding(65001, [System.Text.EncoderFallback]::ExceptionFallback, [System.Text.DecoderFallback]::ExceptionFallback);
    try {
        $qrText = [System.IO.File]::ReadAllText($env:in_file, $utf8Strict);
    } catch [System.Text.DecoderFallbackException] {
        Write-Host '错误：文本文件不是 UTF-8 编码' -ForegroundColor Red;
        exit 1;
    }
    if ([string]::IsNullOrWhiteSpace($qrText)) {
        Write-Host '错误：文本为空，无法生成二维码' -ForegroundColor Red;
        exit 1;
    }

    $baseName = $qrText.Trim().Substring(0, [System.Math]::Min(40, $qrText.Trim().Length));
    $baseName = [System.Text.RegularExpressions.Regex]::Replace($baseName, '[<>:"/\\|?*]', '_');
    $baseName = -join ($baseName.ToCharArray() | Where-Object { -not [char]::IsControl($_) });
    $baseName = $baseName.Trim('. ');
    if ([string]::IsNullOrWhiteSpace($baseName)) {
        $baseName = '二维码';
    }

    $options = [ZXing.QrCode.QrCodeEncodingOptions]::new();
    $options.Width = 0;
    $options.Height = 0;
    $options.Margin = 4;
    $options.CharacterSet = 'UTF-8';
    $options.ErrorCorrection = [ZXing.QrCode.Internal.ErrorCorrectionLevel]::H;

    $pngWriter = [ZXing.BarcodeWriter]::new();
    $pngWriter.Format = [ZXing.BarcodeFormat]::QR_CODE;
    $pngWriter.Options = $options;
    $matrix = $pngWriter.Encode($qrText);
    $imageSize = $matrix.Width * 8;
    $options.Width = $imageSize;
    $options.Height = $imageSize;

    # 位图：1-bit PNG、PNG 与 JPG
    $bitmap = $pngWriter.Write($qrText);
    $oneBitPngPath = [System.IO.Path]::Combine($env:out_dir, $baseName + '.1bit.png');
    $sourceStream = [System.IO.MemoryStream]::new();
    try {
        $bitmap.Save($sourceStream, [System.Drawing.Imaging.ImageFormat]::Png);
        $pngBytes = $sourceStream.ToArray();
        $sourceStream.Position = 0;
        $sourceDecoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create($sourceStream, [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat, [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad);
        $oneBitSource = [System.Windows.Media.Imaging.FormatConvertedBitmap]::new();
        $oneBitSource.BeginInit();
        $oneBitSource.Source = $sourceDecoder.Frames[0];
        $oneBitSource.DestinationFormat = [System.Windows.Media.PixelFormats]::BlackWhite;
        $oneBitSource.EndInit();
        $pngEncoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new();
        $pngEncoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($oneBitSource));
        $oneBitStream = [System.IO.File]::Create($oneBitPngPath);
        try {
            $pngEncoder.Save($oneBitStream);
        } finally {
            $oneBitStream.Dispose();
        }
    } finally {
        $sourceStream.Dispose();
    }
    $pngPath = [System.IO.Path]::Combine($env:out_dir, $baseName + '.png');
    [System.IO.File]::WriteAllBytes($pngPath, $pngBytes);

    $jpgPath = [System.IO.Path]::Combine($env:out_dir, $baseName + '.jpg');
    $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1;
    $encoderParams = [System.Drawing.Imaging.EncoderParameters]::new(1);
    $encoderParams.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, [int64]100);
    $bitmap.Save($jpgPath, $jpegCodec, $encoderParams);
    $encoderParams.Dispose();
    $bitmap.Dispose();

    # 矢量图：SVG
    $svgWriter = [ZXing.BarcodeWriterSvg]::new();
    $svgWriter.Format = [ZXing.BarcodeFormat]::QR_CODE;
    $svgWriter.Options = $options;
    $svgImage = $svgWriter.Write($qrText);
    $svgSizeAttr = '<svg width="' + $imageSize + '" height="' + $imageSize + '" ';
    $svgContent = $svgImage.Content.Replace('<svg ', $svgSizeAttr);
    $svgPath = [System.IO.Path]::Combine($env:out_dir, $baseName + '.svg');
    [System.IO.File]::WriteAllText($svgPath, $svgContent, [System.Text.UTF8Encoding]::new($false));

    # 文本文件：HTML 与 Markdown，内嵌 1-bit PNG
    $pngBase64 = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($oneBitPngPath));
    $dataUri = 'data:image/png;base64,' + $pngBase64;
    $htmlPath = [System.IO.Path]::Combine($env:out_dir, $baseName + '.html');
    $mdPath = [System.IO.Path]::Combine($env:out_dir, $baseName + '.md');
    $imgTag = '<body><img src="' + $dataUri + '" alt="二维码"></body>';
    $htmlLines = @(
        '<!DOCTYPE html>',
        '<html lang="zh-CN">',
        '<head><meta charset="UTF-8"><title>二维码</title></head>',
        $imgTag,
        '</html>'
    );
    [System.IO.File]::WriteAllLines($htmlPath, $htmlLines, [System.Text.UTF8Encoding]::new($false));
    [System.IO.File]::WriteAllText($mdPath, '![二维码](' + $dataUri + ')' + [System.Environment]::NewLine, [System.Text.UTF8Encoding]::new($false));

    Write-Host ('保存文件："' + $oneBitPngPath + '"');
    Write-Host ('保存文件："' + $pngPath + '"');
    Write-Host ('保存文件："' + $jpgPath + '"');
    Write-Host ('保存文件："' + $svgPath + '"');
    Write-Host ('保存文件："' + $htmlPath + '"');
    Write-Host ('保存文件："' + $mdPath + '"');
} catch {
    Write-Host ('错误：生成二维码失败：' + $_.Exception.Message) -ForegroundColor Red;
    exit 1;
}
exit 0;
-----END POWERSHELL CODE-----
