@echo off
REM =======================================
REM 去掉当前目录下所有 .jpg 文件的公共前缀和后缀
REM 只保留中间独特部分 + .jpg
REM =======================================

echo 当前目录: '%cd%'

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "try {" ^
 "    Write-Host '开始处理...';" ^
 "    Set-Location -LiteralPath '%cd%';" ^
 "    $files = @(Get-ChildItem -Filter '*.jpg' -File);" ^
 "    if ($files.Count -eq 0) { Write-Host '没有找到 jpg 文件'; exit };" ^
 "    Write-Host ('找到 ' + $files.Count + ' 个 jpg 文件');" ^
 "    " ^
 "    $names = $files | ForEach-Object { $_.BaseName };" ^
 "    Write-Host '文件名示例: ' $names[0];" ^
 "    $prefix = $names[0];" ^
 "    foreach ($n in $names) {" ^
 "        while (-not $n.StartsWith($prefix) -and $prefix.Length -gt 0) {" ^
 "            $prefix = $prefix.Substring(0, $prefix.Length - 1);" ^
 "        }" ^
 "        if ($prefix.Length -eq 0) { break }" ^
 "    }" ^
 "    " ^
 "    $suffix = '';" ^
 "    $minLength = ($names | Measure-Object -Property Length -Minimum).Minimum;" ^
 "    Write-Host ('最短文件名长度: ' + $minLength);" ^
 "    for ($i = 1; $i -le $minLength; $i++) {" ^
 "        $currentChar = $names[0][$names[0].Length - $i];" ^
 "        $allMatch = $true;" ^
 "        foreach ($name in $names) {" ^
 "            if ($name[$name.Length - $i] -ne $currentChar) {" ^
 "                $allMatch = $false;" ^
 "                break;" ^
 "            }" ^
 "        }" ^
 "        if (-not $allMatch) { break }" ^
 "        $suffix = $currentChar + $suffix;" ^
 "    }" ^
 "    " ^
 "    Write-Host ('公共前缀: \"' + $prefix + '\"');" ^
 "    Write-Host ('公共后缀: \"' + $suffix + '\"');" ^
 "    " ^
 "    $coreNames = @();" ^
 "    foreach ($f in $files) {" ^
 "        $core = $f.BaseName;" ^
 "        if ($prefix.Length -gt 0 -and $core.StartsWith($prefix)) { $core = $core.Substring($prefix.Length) }" ^
 "        if ($suffix.Length -gt 0 -and $core.EndsWith($suffix)) { $core = $core.Substring(0, $core.Length - $suffix.Length) }" ^
 "        if ([string]::IsNullOrEmpty($core)) { $core = $f.BaseName }" ^
 "        $coreNames += $core" ^
 "    }" ^
 "    $maxDigits = ($coreNames | ForEach-Object { if ($_ -match '^\d+$') { $_.Length } else { 0 } } | Measure-Object -Maximum).Maximum;" ^
 "    Write-Host ('数字文件名最长长度: ' + $maxDigits);" ^
 "    " ^
 "    foreach ($f in $files) {" ^
 "        $core = $f.BaseName;" ^
 "        if ($prefix.Length -gt 0 -and $core.StartsWith($prefix)) { $core = $core.Substring($prefix.Length) }" ^
 "        if ($suffix.Length -gt 0 -and $core.EndsWith($suffix)) { $core = $core.Substring(0, $core.Length - $suffix.Length) }" ^
 "        if ([string]::IsNullOrEmpty($core)) { $core = $f.BaseName }" ^
 "        " ^
 "        if ($core -match '^\d+$' -and $maxDigits -gt 0) { $core = $core.PadLeft($maxDigits,'0') }" ^
 "        $newName = $core + $f.Extension;" ^
 "        if ($newName -ne $f.Name) {" ^
 "            if (Test-Path -LiteralPath $newName) {" ^
 "                Write-Host ('跳过: ' + $f.Name + ' -> ' + $newName + ' (目标已存在)') -ForegroundColor Yellow;" ^
 "            } else {" ^
 "                try { Rename-Item -LiteralPath $f.FullName -NewName $newName; Write-Host ('重命名: ' + $f.Name + ' -> ' + $newName) -ForegroundColor Green }" ^
 "                catch { Write-Host ('错误: 无法重命名 ' + $f.Name + ' -> ' + $newName + ': ' + $_.Exception.Message) -ForegroundColor Red }" ^
 "            }" ^
 "        } else { Write-Host ('跳过: ' + $f.Name + ' (无需更改)') -ForegroundColor Gray }" ^
 "    }" ^
 "    Write-Host '完成！';" ^
 "} catch {" ^
 "    Write-Host ('发生错误: ' + $_.Exception.Message) -ForegroundColor Red;" ^
 "    Write-Host ('错误位置: ' + $_.InvocationInfo.PositionMessage) -ForegroundColor Red;" ^
 "}"

pause
exit
