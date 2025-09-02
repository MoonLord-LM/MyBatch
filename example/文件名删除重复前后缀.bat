@echo off
REM =======================================
REM ȥ����ǰĿ¼������ .jpg �ļ��Ĺ���ǰ׺�ͺ�׺
REM ֻ�����м���ز��� + .jpg
REM =======================================

echo ��ǰĿ¼: '%cd%'

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "try {" ^
 "    Write-Host '��ʼ����...';" ^
 "    Set-Location -LiteralPath '%cd%';" ^
 "    $files = @(Get-ChildItem -Filter '*.jpg' -File);" ^
 "    if ($files.Count -eq 0) { Write-Host 'û���ҵ� jpg �ļ�'; exit };" ^
 "    Write-Host ('�ҵ� ' + $files.Count + ' �� jpg �ļ�');" ^
 "    " ^
 "    $names = $files | ForEach-Object { $_.BaseName };" ^
 "    Write-Host '�ļ���ʾ��: ' $names[0];" ^
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
 "    Write-Host ('����ļ�������: ' + $minLength);" ^
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
 "    Write-Host ('����ǰ׺: \"' + $prefix + '\"');" ^
 "    Write-Host ('������׺: \"' + $suffix + '\"');" ^
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
 "    Write-Host ('�����ļ��������: ' + $maxDigits);" ^
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
 "                Write-Host ('����: ' + $f.Name + ' -> ' + $newName + ' (Ŀ���Ѵ���)') -ForegroundColor Yellow;" ^
 "            } else {" ^
 "                try { Rename-Item -LiteralPath $f.FullName -NewName $newName; Write-Host ('������: ' + $f.Name + ' -> ' + $newName) -ForegroundColor Green }" ^
 "                catch { Write-Host ('����: �޷������� ' + $f.Name + ' -> ' + $newName + ': ' + $_.Exception.Message) -ForegroundColor Red }" ^
 "            }" ^
 "        } else { Write-Host ('����: ' + $f.Name + ' (�������)') -ForegroundColor Gray }" ^
 "    }" ^
 "    Write-Host '��ɣ�';" ^
 "} catch {" ^
 "    Write-Host ('��������: ' + $_.Exception.Message) -ForegroundColor Red;" ^
 "    Write-Host ('����λ��: ' + $_.InvocationInfo.PositionMessage) -ForegroundColor Red;" ^
 "}"

pause
exit
