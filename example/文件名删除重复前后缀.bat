@echo off
setlocal enabledelayedexpansion

REM =======================================
REM 分别去掉当前目录下所有 .jpg / .png / .mp4 / .mkv 文件的公共前缀和后缀
REM =======================================

echo 当前目录: '!cd!'

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "Set-Location -LiteralPath '!cd!';" ^
 "function Process-Files([string[]]$patterns) {" ^
 "    if ($patterns.Length -eq 1) {" ^
 "        $files = @(Get-ChildItem -Path . -Filter $patterns[0] -File);" ^
 "    } else {" ^
 "        $files = @(Get-ChildItem -Path .\\* -Include $patterns -File);" ^
 "    }" ^
 "    if ($files.Count -eq 0) { Write-Host ('没有找到 ' + ($patterns -join ',' ) + ' 文件'); return };" ^
 "    Write-Host ('找到 ' + $files.Count + ' 个 ' + ($patterns -join ',' ) + ' 文件');" ^
 "    $names = $files | ForEach-Object { $_.BaseName };" ^
 "    $prefix = $names[0];" ^
 "    foreach ($n in $names) {" ^
 "        while (-not $n.StartsWith($prefix) -and $prefix.Length -gt 0) { $prefix = $prefix.Substring(0, $prefix.Length - 1) }" ^
 "        if ($prefix.Length -eq 0) { break }" ^
 "    }" ^
 "    $suffix = '';" ^
 "    $minLength = ($names | Measure-Object -Property Length -Minimum).Minimum;" ^
 "    for ($i = 1; $i -le $minLength; $i++) {" ^
 "        $currentChar = $names[0][$names[0].Length - $i];" ^
 "        $allMatch = $true;" ^
 "        foreach ($name in $names) { if ($name[$name.Length - $i] -ne $currentChar) { $allMatch = $false; break } }" ^
 "        if (-not $allMatch) { break }" ^
 "        $suffix = $currentChar + $suffix;" ^
 "    }" ^
 "    Write-Host ('公共前缀: \"' + $prefix + '\"');" ^
 "    Write-Host ('公共后缀: \"' + $suffix + '\"');" ^
 "    $coreNames = @();" ^
 "    foreach ($f in $files) {" ^
 "        $core = $f.BaseName;" ^
 "        if ($prefix.Length -gt 0 -and $core.StartsWith($prefix)) { $core = $core.Substring($prefix.Length) }" ^
 "        if ($suffix.Length -gt 0 -and $core.EndsWith($suffix)) { $core = $core.Substring(0, $core.Length - $suffix.Length) }" ^
 "        if ([string]::IsNullOrEmpty($core)) { $core = $f.BaseName }" ^
 "        $coreNames += $core" ^
 "    }" ^
 "    $maxDigits = ($coreNames | ForEach-Object { if ($_ -match '^\d+$') { $_.Length } else { 0 } } | Measure-Object -Maximum).Maximum;" ^
 "    foreach ($f in $files) {" ^
 "        $core = $f.BaseName;" ^
 "        if ($prefix.Length -gt 0 -and $core.StartsWith($prefix)) { $core = $core.Substring($prefix.Length) }" ^
 "        if ($suffix.Length -gt 0 -and $core.EndsWith($suffix)) { $core = $core.Substring(0, $core.Length - $suffix.Length) }" ^
 "        if ([string]::IsNullOrEmpty($core)) { $core = $f.BaseName }" ^
 "        if ($core -match '^\d+$' -and $maxDigits -gt 0) { $core = $core.PadLeft($maxDigits,'0') }" ^
 "        $newName = $core + $f.Extension;" ^
 "        if ($newName -ne $f.Name) {" ^
 "            if (Test-Path -LiteralPath $newName) { Write-Host ('跳过: ' + $f.Name + ' -> ' + $newName + ' (目标已存在)') -ForegroundColor Yellow }" ^
 "            else { try { Rename-Item -LiteralPath $f.FullName -NewName $newName; Write-Host ('重命名: ' + $f.Name + ' -> ' + $newName) -ForegroundColor Green } catch { Write-Host ('错误: 无法重命名 ' + $f.Name + ' -> ' + $newName + ': ' + $_.Exception.Message) -ForegroundColor Red } }" ^
 "        } else { Write-Host ('跳过: ' + $f.Name + ' (无需更改)') -ForegroundColor Gray }" ^
 "    }" ^
 "    Write-Host '处理完成！';" ^
 "}" ^
 "Process-Files '*.jpg';" ^
 "Process-Files '*.png';" ^
 "Process-Files '*.mp4';" ^
 "Process-Files '*.mkv';"

pause
exit
