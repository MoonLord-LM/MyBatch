@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将单个文件，打包转换为 exe 程序' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击生成的 bat 脚本，自动解码解压并打开原文件，如果是 ps1 / bat / py / exe 则自动执行' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '处理方式：把原文件内容，执行压缩，嵌入到自解压的 C# 程序中作为资源，编译出 exe 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '尝试使用 PowerShell 内置的 GZipStream / makecab.exe / 7-Zip 压缩，尽可能压缩到最小' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入要打包转换的文件的路径；也可以拖拽单个文件到此脚本上' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 检查 7-Zip 组件（可选）
if exist "!script_dir!7za.exe" (
    set "seven_zip=!script_dir!7za.exe"
) else if exist "!cd!\7za.exe" (
    set "seven_zip=!cd!\7za.exe"
) else if exist "!script_dir!..\7za.exe" (
    set "seven_zip=!script_dir!..\7za.exe"
) else if exist "..\7za.exe" (
    set "seven_zip=..\7za.exe"
) else if exist "!ProgramFiles!\7-Zip\7z.exe" (
    set "seven_zip=!ProgramFiles!\7-Zip\7z.exe"
) else if exist "!ProgramFiles(x86)!\7-Zip\7z.exe" (
    set "seven_zip=!ProgramFiles(x86)!\7-Zip\7z.exe"
) else (
    set "seven_zip=7z"
)
"!seven_zip!" i >nul 2>&1
if !errorlevel! neq 0 (
    set "seven_zip="
)

REM 检查 7-Zip 自解压模块（可选）
if exist "!script_dir!7zCon.sfx" (
    set "seven_zip_sfx=!script_dir!7zCon.sfx"
) else if exist "!cd!\7zCon.sfx" (
    set "seven_zip_sfx=!cd!\7zCon.sfx"
) else if exist "!script_dir!..\7zCon.sfx" (
    set "seven_zip_sfx=!script_dir!..\7zCon.sfx"
) else if exist "..\7zCon.sfx" (
    set "seven_zip_sfx=..\7zCon.sfx"
) else if exist "!ProgramFiles!\7-Zip\7zCon.sfx" (
    set "seven_zip_sfx=!ProgramFiles!\7-Zip\7zCon.sfx"
) else if exist "!ProgramFiles(x86)!\7-Zip\7zCon.sfx" (
    set "seven_zip_sfx=!ProgramFiles(x86)!\7-Zip\7zCon.sfx"
) else (
    set "seven_zip_sfx="
)



set "input_file=!param1_path!"

:input_file
    if "!input_file!"=="" (
        echo 请输入要打包转换的文件的路径
        set /p "input_file="
        if !errorlevel! neq 0 (
            echo 无输入，退出脚本
            echo.
            exit /b 1
        )
        echo.
    )
    if "!input_file!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_file
    )
    set "input_file=!input_file:"=!"
    if "!input_file!"=="" (
        echo 输入不能为空，请重新输入
        echo.
        goto input_file
    )
    if "!input_file:~-1!"=="\" set "input_file=!input_file:~0,-1!"
    if not exist "!input_file!" (
        echo 错误：路径不存在："!input_file!"，请重新输入
        echo.
        set "input_file="
        goto input_file
    )
    if exist "!input_file!\" (
        echo 错误：不支持文件夹，请输入单个文件
        echo.
        set "input_file="
        goto input_file
    )



echo 开始处理："!input_file!"
echo.

for %%i in ("!input_file!") do (
    setlocal disabledelayedexpansion
    set "file_size=%%~zi"
    set "file_dir=%%~dpi"
    set "base_name=%%~ni"
    set "file_name_ext=%%~nxi"
    setlocal enabledelayedexpansion

    echo 原始大小：%%~zi 字节
    echo.

    REM 计算文件内容的 SHA512 哈希值
    for /f "delims=" %%a in ('powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$sha512 = [System.Security.Cryptography.SHA512]::Create();" ^
        "$fileBytes = [System.IO.File]::ReadAllBytes($env:input_file);" ^
        "Write-Output ([System.BitConverter]::ToString($sha512.ComputeHash($fileBytes)).Replace('-', '').ToLowerInvariant());"') do (
        set "file_sha512=%%a"
    )
    if "!file_sha512!"=="" (
        echo 错误：计算文件内容的 SHA512 哈希值失败："!input_file!"
        echo.
        pause
        exit /b 1
    )

    REM 如果输出文件已存在，则继续追加 .exe 后缀，直到文件名不重复
    set "output_file=!file_dir!!base_name!.exe"
    for /l %%n in (1,1,16) do (
        if exist "!output_file!" set "output_file=!output_file!.exe"
    )
    echo 目标文件："!output_file!"
    echo.



    REM 方式一：压缩为 gzip 格式
    set "temp_gzip=%temp%\MyBatch_%random%_%random%_%random%_%random%.gz"
    if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
    if "!seven_zip!"=="" (
        echo 压缩方式：使用 PowerShell 内置的 GZipStream 压缩
        powershell -NoProfile -Command ^
            "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
            "Add-Type -AssemblyName System.IO.Compression;" ^
            "$rawBytes = [System.IO.File]::ReadAllBytes($env:input_file);" ^
            "$memStream = New-Object System.IO.MemoryStream;" ^
            "$mode = [System.IO.Compression.CompressionMode]::Compress;" ^
            "$gzipStream = New-Object System.IO.Compression.GzipStream($memStream, $mode);" ^
            "$gzipStream.Write($rawBytes, 0, $rawBytes.Length);" ^
            "$gzipStream.Close();" ^
            "$bytes = $memStream.ToArray();" ^
            "$memStream.Close();" ^
            "[System.IO.File]::WriteAllBytes($env:temp_gzip, $bytes);"
        if !errorlevel! neq 0 (
            echo 错误：压缩失败："!input_file!"
            echo.
            if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
            pause
            exit /b 1
        )
    ) else (
        echo 压缩方式：使用 7-Zip 压缩 gzip 格式
        "!seven_zip!" a -tgzip -mx=9 -mmt=on -mtc=off -mtm=off -mta=off -si"!file_name_ext!" "!temp_gzip!" < "!input_file!" >nul
        if !errorlevel! neq 0 (
            echo 错误：压缩失败："!input_file!"
            echo.
            if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
            pause
            exit /b 1
        )
    )
    if not exist "!temp_gzip!" (
        echo 错误：压缩文件生成失败："!temp_gzip!"
        echo.
        pause
        exit /b 1
    )



    REM 方式二：压缩为 cab 格式
    echo 压缩方式：使用 makecab 压缩 cab 格式
    set "temp_cab=%temp%\MyBatch_%random%_%random%_%random%_%random%.cab"
    if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
    makecab /D CompressionType=LZX /D CompressionMemory=21 "!input_file!" "!temp_cab!" >nul
    if !errorlevel! neq 0 (
        echo 错误：压缩失败："!input_file!"
        echo.
        if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
        if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
        pause
        exit /b 1
    )
    if not exist "!temp_cab!" (
        if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
        echo 错误：压缩文件生成失败："!temp_cab!"
        echo.
        pause
        exit /b 1
    )



    REM 方式三：压缩为 7z 格式的自解压 exe
    set "use_7z_exe=0"
    if not "!seven_zip!"=="" (
        if not "!seven_zip_sfx!"=="" (
            set "use_7z_exe=1"
        )
    )
    if "!use_7z_exe!"=="0" (
        echo 缺少 7-Zip 组件或自解压模块，只使用 gzip / cab 方式压缩
        echo.
    )
    if "!use_7z_exe!"=="1" (
        echo 压缩方式：7z 自解压 exe 格式
        set "temp_7z=%temp%\MyBatch_%random%_%random%_%random%_%random%.7z"
        if exist "!temp_7z!" ( del /f /q "!temp_7z!" )
        "!seven_zip!" a -t7z -mx=9 -m0=LZMA2 -md=2048m -mfb=256 -ms=off -mmt=on -mtc=off -mtm=off -mta=off -sccUTF-8 -scsUTF-8 -y "!temp_7z!" "!input_file!" >nul
        if !errorlevel! neq 0 (
            echo 错误：压缩失败："!input_file!"
            echo.
            if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
            if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
            if exist "!temp_7z!" ( del /f /q "!temp_7z!" )
            pause
            exit /b 1
        )
        if not exist "!temp_7z!" (
            echo 错误：压缩文件生成失败："!temp_7z!"
            echo.
            if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
            if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
            pause
            exit /b 1
        )

        set "temp_7z_exe=%temp%\MyBatch_%random%_%random%_%random%_%random%.exe"
        copy /b /y "!seven_zip_sfx!" + "!temp_7z!" "!temp_7z_exe!" >nul
        if !errorlevel! neq 0 (
            echo 错误：制作自解压 exe 失败："!temp_7z_exe!"
            echo.
            if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
            if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
            if exist "!temp_7z!" ( del /f /q "!temp_7z!" )
            if exist "!temp_7z_exe!" ( del /f /q "!temp_7z_exe!" )
            pause
            exit /b 1
        )
        if exist "!temp_7z!" ( del /f /q "!temp_7z!" )
    )



    REM 选择体积最小的压缩包作为内嵌资源
    set "method="
    set "smallest_size="
    set "resource_file="
    for %%j in ("!temp_gzip!") do (
        set "method=gzip" & set "smallest_size=%%~zj" & set "resource_file=!temp_gzip!"
    )
    for %%j in ("!temp_cab!") do (
        if %%~zj lss !smallest_size! (
            set "method=cab" & set "smallest_size=%%~zj" & set "resource_file=!temp_cab!"
        )
    )
    if "!use_7z_exe!"=="1" (
        for %%j in ("!temp_7z_exe!") do (
            if %%~zj lss !smallest_size! (
                set "method=7z" & set "smallest_size=%%~zj" & set "resource_file=!temp_7z_exe!"
            )
        )
    )
    echo 内嵌压缩方式：!method!，压缩后大小：!smallest_size! 字节
    echo.

    REM 提取内嵌的 C# 代码
    set "temp_cs=%temp%\MyBatch_%random%_%random%_%random%_%random%.cs"
    if exist "!temp_cs!" ( del /f /q "!temp_cs!" )
    set "inner_begin_marker=-----BEGIN CSHARP CODE-----"
    set "inner_end_marker=-----END CSHARP CODE-----"
    set "origin_file_name_marker=-----ORIGIN FILE NAME-----"
    set "origin_file_size_marker=-----ORIGIN FILE SIZE-----"
    set "origin_file_sha512_marker=-----ORIGIN FILE SHA512-----"
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "$lines = Get-Content -Encoding UTF8 -LiteralPath $env:script_path;" ^
        "$begin = [array]::IndexOf($lines, $env:inner_begin_marker) + 1;" ^
        "$end = [array]::IndexOf($lines, $env:inner_end_marker);" ^
        "if ($begin -lt 1 -or $end -lt $begin) {" ^
        "    Write-Host '错误：未找到内嵌的 C# 代码块' -ForegroundColor Red;" ^
        "    exit 1;" ^
        "};" ^
        "$code = $lines[$begin..($end - 1)];" ^
        "for ($i = 0; $i -lt $code.Count; $i++) {" ^
        "    $code[$i] = $code[$i].Replace($env:origin_file_name_marker, $env:file_name_ext);" ^
        "    $code[$i] = $code[$i].Replace($env:origin_file_size_marker, $env:file_size);" ^
        "    $code[$i] = $code[$i].Replace($env:origin_file_sha512_marker, $env:file_sha512);" ^
        "};" ^
        "$utf8NoBOM = New-Object System.Text.UTF8Encoding($false);" ^
        "[System.IO.File]::WriteAllLines($env:temp_cs, $code, $utf8NoBOM);"
    if !errorlevel! neq 0 (
        echo 错误：提取内嵌代码失败
        echo.
        if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
        if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
        if exist "!temp_7z!" ( del /f /q "!temp_7z!" )
        if exist "!temp_7z_exe!" ( del /f /q "!temp_7z_exe!" )
        if exist "!temp_cs!" ( del /f /q "!temp_cs!" )
        pause
        exit /b 1
    )
    if not exist "!temp_cs!" (
        echo 错误：提取内嵌代码文件生成失败："!temp_cs!"
        echo.
        if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
        if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
        if exist "!temp_7z!" ( del /f /q "!temp_7z!" )
        if exist "!temp_7z_exe!" ( del /f /q "!temp_7z_exe!" )
        pause
        exit /b 1
    )

    echo 正在编译代码，并嵌入压缩包资源
    echo.
    powershell -NoProfile -Command ^
        "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
        "[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.CSharp');" ^
        "$provider = New-Object Microsoft.CSharp.CSharpCodeProvider;" ^
        "$params = New-Object System.CodeDom.Compiler.CompilerParameters;" ^
        "$params.OutputAssembly = $env:output_file;" ^
        "$params.GenerateExecutable = $true;" ^
        "$params.CompilerOptions = '/target:winexe /optimize';" ^
        "[void]$params.ReferencedAssemblies.Add('System.dll');" ^
        "[void]$params.ReferencedAssemblies.Add('System.Core.dll');" ^
        "[void]$params.ReferencedAssemblies.Add('System.IO.Compression.dll');" ^
        "[void]$params.ReferencedAssemblies.Add('System.Windows.Forms.dll');" ^
        "[void]$params.EmbeddedResources.Add($env:resource_file);" ^
        "$result = $provider.CompileAssemblyFromFile($params, $env:temp_cs);" ^
        "if ($result.Errors.Count -gt 0) {" ^
        "    Write-Host '错误：编译 C# 代码失败：' -ForegroundColor Red;" ^
        "    foreach ($err in $result.Errors) { Write-Host $err.ToString() -ForegroundColor Red };" ^
        "    exit 1;" ^
        "};" ^
        "Write-Host '编译完成' -ForegroundColor Green"
    if !errorlevel! neq 0 (
        echo 错误：生成 exe 失败："!output_file!"
        echo.
        if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
        if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
        if exist "!temp_7z!" ( del /f /q "!temp_7z!" )
        if exist "!temp_7z_exe!" ( del /f /q "!temp_7z_exe!" )
        if exist "!temp_cs!" ( del /f /q "!temp_cs!" )
        if exist "!output_file!" ( del /f /q "!output_file!" )
        pause
        exit /b 1
    )
    if not exist "!output_file!" (
        echo 错误：生成 exe 文件不存在："!output_file!"
        echo.
        if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
        if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
        if exist "!temp_7z!" ( del /f /q "!temp_7z!" )
        if exist "!temp_7z_exe!" ( del /f /q "!temp_7z_exe!" )
        if exist "!temp_cs!" ( del /f /q "!temp_cs!" )
        pause
        exit /b 1
    )

    if exist "!temp_gzip!" ( del /f /q "!temp_gzip!" )
    if exist "!temp_cab!" ( del /f /q "!temp_cab!" )
    if exist "!temp_7z!" ( del /f /q "!temp_7z!" )
    if exist "!temp_7z_exe!" ( del /f /q "!temp_7z_exe!" )
    if exist "!temp_cs!" ( del /f /q "!temp_cs!" )

    for %%j in ("!output_file!") do (
        setlocal disabledelayedexpansion
        set "file_size=%%~zj"
        setlocal enabledelayedexpansion

        echo 最终大小：!file_size! 字节

        endlocal
        endlocal
    )

    endlocal
    endlocal
)



echo.
pause
exit /b



-----BEGIN CSHARP CODE-----
using System;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Diagnostics;
using System.Security.Cryptography;
using System.Windows.Forms;

public static class Program
{
    private static void ShowError(string msg)
    {
        try { MessageBox.Show(msg, originFileName, MessageBoxButtons.OK, MessageBoxIcon.Error); } catch { }
    }

    private static int Main(string[] args)
    {
        string originFileName = "-----ORIGIN FILE NAME-----";
        long originFileSize = long.Parse("-----ORIGIN FILE SIZE-----");
        string originFileSha512 = "-----ORIGIN FILE SHA512-----";

        string tempRoot = Path.Combine(Path.GetTempPath(), "MyBatch", "cache", originFileSize.ToString(), originFileSha512);
        try { if (!Directory.Exists(tempRoot)) Directory.CreateDirectory(tempRoot); } catch { }
        string extracted = Path.Combine(tempRoot, originFileName);

        bool needExtract = true;
        if (File.Exists(extracted))
        {
            try
            {
                FileInfo fi = new FileInfo(extracted);
                if (fi.Length == originFileSize)
                {
                    using (var sha = SHA512.Create())
                    using (var fs = File.OpenRead(extracted))
                    {
                        byte[] h = sha.ComputeHash(fs);
                        string hex = BitConverter.ToString(h).Replace("-", "").ToLowerInvariant();
                        if (string.Equals(hex, originFileSha512, StringComparison.OrdinalIgnoreCase))
                            needExtract = false;
                    }
                }
            }
            catch { }
        }

        if (needExtract)
        {
            var asm = Assembly.GetExecutingAssembly();
            string resName = null;
            foreach (string n in asm.GetManifestResourceNames())
            {
                string ln = n.ToLowerInvariant();
                if (ln.EndsWith(".gz") || ln.EndsWith(".cab") || ln.EndsWith(".exe")) { resName = n; break; }
            }
            if (resName == null)
            {
                ShowError("错误：未找到内嵌的压缩资源");
                return 1;
            }
            string lowerMethod = null;
            if (resName.EndsWith(".gz", StringComparison.OrdinalIgnoreCase)) lowerMethod = "gzip";
            else if (resName.EndsWith(".cab", StringComparison.OrdinalIgnoreCase)) lowerMethod = "cab";
            else if (resName.EndsWith(".exe", StringComparison.OrdinalIgnoreCase)) lowerMethod = "7z";
            if (lowerMethod == null)
            {
                ShowError("错误：未知的内嵌压缩资源格式：" + resName);
                return 1;
            }
            try
            {
                if (lowerMethod == "gzip")
                {
                    using (var stream = asm.GetManifestResourceStream(resName))
                    using (var gzip = new GZipStream(stream, CompressionMode.Decompress))
                    using (var outp = File.Create(extracted))
                    {
                        gzip.CopyTo(outp);
                    }
                    if (!File.Exists(extracted)) { ShowError("错误：gzip 解压失败"); return 1; }
                }
                else if (lowerMethod == "cab")
                {
                    var rnd = new Random();
                    string tempFilePrefix = "MyBatch_" + rnd.Next(0, 32768) + "_" + rnd.Next(0, 32768) + "_" + rnd.Next(0, 32768) + "_" + rnd.Next(0, 32768);
                    string cabPath = Path.Combine(Path.GetTempPath(), tempFilePrefix + ".cab");
                    using (var stream = asm.GetManifestResourceStream(resName))
                    using (var outp = File.Create(cabPath)) { stream.CopyTo(outp); }
                    var cabPsi = new ProcessStartInfo("expand.exe", "\"" + cabPath + "\" \"" + extracted + "\"");
                    cabPsi.UseShellExecute = false;
                    cabPsi.CreateNoWindow = true;
                    cabPsi.WindowStyle = ProcessWindowStyle.Hidden;
                    using (var p = Process.Start(cabPsi)) { if (p != null) p.WaitForExit(); }
                    try { if (File.Exists(cabPath)) File.Delete(cabPath); } catch { }
                    if (!File.Exists(extracted)) { ShowError("错误：cab 解压失败"); return 1; }
                }
                else if (lowerMethod == "7z")
                {
                    var rnd = new Random();
                    string tempFilePrefix = "MyBatch_" + rnd.Next(0, 32768) + "_" + rnd.Next(0, 32768) + "_" + rnd.Next(0, 32768) + "_" + rnd.Next(0, 32768);
                    string sfxPath = Path.Combine(Path.GetTempPath(), tempFilePrefix + ".exe");
                    using (var stream = asm.GetManifestResourceStream(resName))
                    using (var outp = File.Create(sfxPath)) { stream.CopyTo(outp); }
                    var sfxPsi = new ProcessStartInfo(sfxPath, "-o\"" + tempRoot + "\" -y");
                    sfxPsi.UseShellExecute = false;
                    sfxPsi.CreateNoWindow = true;
                    sfxPsi.WindowStyle = ProcessWindowStyle.Hidden;
                    using (var p = Process.Start(sfxPsi)) { if (p != null) p.WaitForExit(); }
                    try { if (File.Exists(sfxPath)) File.Delete(sfxPath); } catch { }
                    if (!File.Exists(extracted)) { ShowError("错误：7z 解压失败"); return 1; }
                }
                else
                {
                    ShowError("错误：未知的内嵌压缩方式：" + lowerMethod);
                    return 1;
                }
            }
            catch (Exception ex)
            {
                ShowError("错误：解压失败：" + ex.Message);
                return 1;
            }
        }

        try
        {
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.WorkingDirectory = tempRoot;
            psi.CreateNoWindow = true;
            string lower = originFileName.ToLowerInvariant();
            string argStr = "";
            for (int i = 0; i < args.Length; i++)
            {
                string a = args[i];
                if (a.IndexOf(' ') >= 0) argStr += " \"" + a + "\"";
                else argStr += " " + a;
            }
            if (lower.EndsWith(".ps1"))
            {
                psi.FileName = "powershell.exe";
                psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + extracted + "\"" + argStr;
            }
            else if (lower.EndsWith(".py"))
            {
                psi.FileName = "python.exe";
                psi.Arguments = "\"" + extracted + "\"" + argStr;
            }
            else if (lower.EndsWith(".bat"))
            {
                psi.FileName = "cmd.exe";
                psi.Arguments = "/s /c \"" + extracted + "\"" + argStr;
            }
            else
            {
                psi.FileName = extracted;
                psi.Arguments = argStr.TrimStart();
                psi.UseShellExecute = true;
            }
            Process p = Process.Start(psi);
            if (p != null)
            {
                p.WaitForExit();
                return p.ExitCode;
            }
            ShowError("错误：无法启动解压出的文件");
            return 1;
        }
        catch (Exception ex)
        {
            ShowError("错误：执行失败：" + ex.Message);
            return 1;
        }
    }
}
-----END CSHARP CODE-----
