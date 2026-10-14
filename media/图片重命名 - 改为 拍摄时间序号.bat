@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将带 EXIF 拍摄时间的图片，先按拍摄时间重命名，再按时间顺序改为数字序号' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '按文件的总数量，分别使用 1-9 / 01-99 / 001-999 作为新的文件名，预留 0 / 00 / 000 给封面图使用' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的图片文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个图片文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 jpg jpeg png webp bmp gif tif tiff heic heif avif' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '没有 EXIF 拍摄时间的图片，不纳入数字序号编号' -ForegroundColor Green"
echo.



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
    set "mediainfo_path=mediainfo"
)
"!mediainfo_path!" --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 MediaInfo 组件
    echo 请从 https://mediaarea.net/en/MediaInfo 下载，然后放到脚本所在文件夹
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
        echo 开始处理文件："!param1!"
        set "file_dir=!param1_dir!"
        set "base_name=!param1_name!"
        set "file_ext=!param1_ext!"

        REM 检查图片是否带有 EXIF 拍摄时间（Recorded_Date / Encoded_Date）
        set "creation_time="
        for /f "delims=" %%x in ('
            powershell -NoProfile -Command ^
                "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                "& $env:mediainfo_path '--Output=General;%%Recorded_Date%%' $env:param1 2>$null"
        ') do (
            set "creation_time=%%x"
            echo 图片 Recorded_Date 标记："!creation_time!"
        )
        if "!creation_time!"=="" (
            for /f "delims=" %%x in ('
                powershell -NoProfile -Command ^
                    "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                    "& $env:mediainfo_path '--Output=General;%%Encoded_Date%%' $env:param1 2>$null"
            ') do (
                set "creation_time=%%x"
                echo 图片 Encoded_Date 标记："!creation_time!"
            )
        )
        set "exif_time="
        if not "!creation_time!"=="" (
            for /f "delims=" %%t in ('
                powershell -NoProfile -Command ^
                    "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                    "& {param($Time) try {" ^
                    "    $s = $Time -replace '(\d{4}):(\d{2}):(\d{2})', '$1-$2-$3';" ^
                    "    $dt = [DateTime]::Parse($s, [System.Globalization.CultureInfo]::InvariantCulture);" ^
                    "    Write-Output $dt.ToString('yyyyMMdd_HHmmss_fff')" ^
                    "} catch {} } -Time $env:creation_time" 2^>nul
            ') do (
                set "exif_time=%%t"
            )
        )

        if "!exif_time!"=="" (
            echo 未找到 EXIF 拍摄时间，跳过此文件
        ) else (
            echo 图片 EXIF 拍摄时间："!exif_time!"
            for /f "delims=" %%l in ('
                powershell -NoProfile -Command ^
                    "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                    "$env:file_ext.ToLower()"
            ') do (
                set "lower_file_ext=%%l"
            )
            set "new_name=IMG_!exif_time!!lower_file_ext!"
            echo 目标文件名："!new_name!"
            if /i "!param1!"=="!file_dir!!new_name!" (
                echo 文件名已符合规范，无需处理
            ) else if exist "!file_dir!!new_name!" (
                echo 目标文件已存在，跳过此文件
            ) else (
                ren "!param1!" "!new_name!"
                if !errorlevel! equ 0 (
                    echo 按拍摄时间重命名成功
                ) else (
                    echo 按拍摄时间重命名失败
                )
            )

            REM 将刚重命名为拍摄时间的单个文件，改为数字序号 1
            set "rename_scope=file"
            set "rename_file=!file_dir!!new_name!"
            REM 从自身文件末尾的 -----BEGIN POWERSHELL CODE----- / -----END POWERSHELL CODE----- 之间提取 Powershell 代码
            powershell -NoProfile -Command ^
                "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                "$lines = Get-Content -Encoding UTF8 -LiteralPath $env:script_path;" ^
                "$begin = [array]::IndexOf($lines, '-----BEGIN POWERSHELL CODE-----') + 1;" ^
                "$end = [array]::IndexOf($lines, '-----END POWERSHELL CODE-----');" ^
                "if ($begin -lt 1 -or $end -lt $begin) { Write-Host '错误：未找到内嵌的 PowerShell 代码块' -ForegroundColor Red; exit 1 };" ^
                "$code = $lines[$begin..($end - 1)] -join [System.Environment]::NewLine;" ^
                "Invoke-Expression $code"
            if !errorlevel! neq 0 (
                echo 改为数字序号失败，请检查报错信息
                echo.
                pause
                exit /b 1
            )
            echo 改为数字序号成功
        )
    )
)



if not "!working_dir!" == "" (
    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "no_exif=0"
    set /a "already_ok=0"
    set /a "name_conflict=0"
    set /a "rename_failed=0"
    set /a "total2=0"
    set /a "succeeded2=0"
    set /a "already_ok2=0"
    set /a "name_conflict2=0"
    set /a "rename_failed2=0"
    set "file_path=!working_dir!"
    set "ext_filter=\.(jpg|jpeg|png|webp|bmp|gif|tif|tiff|heic|heif|avif)$"
    for /f "delims=" %%f in ('
        powershell -NoProfile -Command ^
            "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
            "Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse |" ^
            "    Where-Object { $_.Extension -match $env:ext_filter } |" ^
            "    ForEach-Object { $_.FullName }"
    ') do (
        setlocal disabledelayedexpansion
        set "img_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        echo 处理文件："!img_file!"

        REM 检查图片是否带有 EXIF 拍摄时间（Recorded_Date / Encoded_Date）
        set "creation_time="
        for /f "delims=" %%x in ('
            powershell -NoProfile -Command ^
                "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                "& $env:mediainfo_path '--Output=General;%%Recorded_Date%%' $env:img_file 2>$null"
        ') do (
            set "creation_time=%%x"
            echo 图片 Recorded_Date 标记："!creation_time!"
        )
        if "!creation_time!"=="" (
            for /f "delims=" %%x in ('
                powershell -NoProfile -Command ^
                    "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                    "& $env:mediainfo_path '--Output=General;%%Encoded_Date%%' $env:img_file 2>$null"
            ') do (
                set "creation_time=%%x"
                echo 图片 Encoded_Date 标记："!creation_time!"
            )
        )
        set "exif_time="
        if not "!creation_time!"=="" (
            for /f "delims=" %%t in ('
                powershell -NoProfile -Command ^
                    "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                    "& {param($Time) try {" ^
                    "    $s = $Time -replace '(\d{4}):(\d{2}):(\d{2})', '$1-$2-$3';" ^
                    "    $dt = [DateTime]::Parse($s, [System.Globalization.CultureInfo]::InvariantCulture);" ^
                    "    Write-Output $dt.ToString('yyyyMMdd_HHmmss_fff')" ^
                    "} catch {} } -Time $env:creation_time" 2^>nul
            ') do (
                set "exif_time=%%t"
            )
        )

        if "!exif_time!"=="" (
            echo set /a "no_exif+=1">>"!temp_set!"
            echo 未找到 EXIF 拍摄时间，跳过此文件
        ) else (
            echo 图片 EXIF 拍摄时间："!exif_time!"
            for /f "delims=" %%l in ('
                powershell -NoProfile -Command ^
                    "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                    "$env:file_ext.ToLower()"
            ') do (
                set "lower_file_ext=%%l"
            )
            set "new_name=IMG_!exif_time!!lower_file_ext!"
            echo 目标文件名："!new_name!"
            if /i "!img_file!"=="!file_dir!!new_name!" (
                echo set /a "already_ok+=1">>"!temp_set!"
                echo 文件名已符合规范，无需处理
            ) else if exist "!file_dir!!new_name!" (
                echo set /a "name_conflict+=1">>"!temp_set!"
                echo 目标文件已存在，跳过此文件
            ) else (
                ren "!img_file!" "!new_name!"
                if !errorlevel! equ 0 (
                    echo set /a "succeeded+=1">>"!temp_set!"
                    echo 重命名成功
                ) else (
                    echo set /a "rename_failed+=1">>"!temp_set!"
                    echo 重命名失败
                )
            )
        )
        echo set /a "total+=1">>"!temp_set!"
        echo.

        endlocal
        endlocal
    )

    REM 按拍摄时间顺序，将 IMG_ 开头的图片在每个文件夹内改为数字序号
    set "rename_scope=dir"
    set "rename_root=!working_dir!"
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
        echo 重编号失败，请检查报错信息
        echo.
        if exist "!temp_set!" ( del /f /q "!temp_set!" )
        pause
        exit /b 1
    )
    echo.

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    echo 批量处理完成
    set /a "ok_total=succeeded+already_ok"
    set /a "fail_total=no_exif+name_conflict+rename_failed"
    echo 按拍摄时间重命名，共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个 & REM
    echo 其中，重命名成功 !succeeded! 个，已符合规范 !already_ok! 个，已存在同名文件 !name_conflict! 个，无 EXIF 时间跳过 !no_exif! 个，重命名失败 !rename_failed! 个
    echo.
    set /a "ok2_total=succeeded2+already_ok2"
    set /a "fail2_total=name_conflict2+rename_failed2"
    echo 改为数字序号，共计：!total2! 个，成功：!ok2_total! 个，失败：!fail2_total! 个 & REM
    echo 其中，重命名成功 !succeeded2! 个，已为数字序号跳过 !already_ok2! 个，目标已存在 !name_conflict2! 个，重命名失败 !rename_failed2! 个
)



echo.
pause
exit /b



-----BEGIN POWERSHELL CODE-----
[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;
$extFilter = '^\.(jpg|jpeg|png|webp|bmp|gif|tif|tiff|heic|heif|avif)$';
$hasTemp = [bool]$env:temp_set -and (Test-Path -LiteralPath $env:temp_set);
function Report($line) { if ($hasTemp) { Add-Content -LiteralPath $env:temp_set -Encoding UTF8 -Value $line } }
function Count($name, $n) { Report ('set /a ' + $name + '+=' + $n) }

if ($env:rename_scope -eq 'file') {
    $f = Get-Item -LiteralPath $env:rename_file -ErrorAction SilentlyContinue;
    if (-not $f) { Write-Host '未找到待编号的文件'; exit 0 }
    $newName = '1' + $f.Extension;
    if ($newName -eq $f.Name) {
        Write-Host ('跳过，已为数字序号："' + $f.Name + '"');
    } elseif (Test-Path -LiteralPath (Join-Path $f.DirectoryName $newName)) {
        Write-Host ('跳过，目标已存在："' + $f.Name + '" -> "' + $newName + '"');
    } else {
        try {
            Rename-Item -LiteralPath $f.FullName -NewName $newName;
            Write-Host ('重命名成功："' + $f.Name + '" -> "' + $newName + '"');
        } catch {
            Write-Host ('重命名失败："' + $f.Name + '" -> "' + $newName + '"，报错信息：' + $_.Exception.Message);
        }
    }
    exit 0;
}

$dirs = @(Get-Item -LiteralPath $env:rename_root) + @(Get-ChildItem -LiteralPath $env:rename_root -Directory -Recurse);
foreach ($d in $dirs) {
    $files = @(Get-ChildItem -LiteralPath $d.FullName -File -Force | Where-Object { $_.Name -like 'IMG_*' -and $_.Extension -match $extFilter } | Sort-Object Name);
    $count = $files.Count;
    if ($count -eq 0) { continue }
    $width = $count.ToString().Length;
    $idx = 1;
    foreach ($f in $files) {
        $newName = $idx.ToString().PadLeft($width, '0') + $f.Extension;
        $idx++;
        if ($newName -eq $f.Name) {
            Count 'already_ok2' 1;
            Write-Host ('跳过，已为数字序号："' + $f.Name + '"');
        } elseif (Test-Path -LiteralPath (Join-Path $d.FullName $newName)) {
            Count 'name_conflict2' 1;
            Write-Host ('跳过，目标已存在："' + $f.Name + '" -> "' + $newName + '"');
        } else {
            try {
                Rename-Item -LiteralPath $f.FullName -NewName $newName;
                Count 'succeeded2' 1;
                Write-Host ('重命名成功："' + $f.Name + '" -> "' + $newName + '"');
            } catch {
                Count 'rename_failed2' 1;
                Write-Host ('重命名失败："' + $f.Name + '" -> "' + $newName + '"，报错信息：' + $_.Exception.Message);
            }
        }
        Count 'total2' 1;
    }
}
exit 0;
-----END POWERSHELL CODE-----
