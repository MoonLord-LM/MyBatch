@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将单个文件加密，生成 enc 后缀的加密文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '加密实现：将用户输入的密码，使用 PBKDF2-HMAC-SHA512 产生密钥，然后进行 AES-256-GCM 加密' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '加密文件会比原始文件大 44 字节' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '选中一个文件，拖拽到此脚本上执行；不支持拖入文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '如果输出 enc 文件已存在，则跳过不处理' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 检查 OpenSSL-Win64 组件
set "libcrypto="
if exist "!script_dir!libcrypto-4-x64.dll" (
    set "libcrypto=!script_dir!libcrypto-4-x64.dll"
) else if exist "!cd!\libcrypto-4-x64.dll" (
    set "libcrypto=!cd!\libcrypto-4-x64.dll"
) else if exist "!script_dir!..\libcrypto-4-x64.dll" (
    set "libcrypto=!script_dir!..\libcrypto-4-x64.dll"
) else if exist "..\libcrypto-4-x64.dll" (
    set "libcrypto=..\libcrypto-4-x64.dll"
) else if exist "!ProgramFiles!\OpenSSL-Win64\bin\libcrypto-4-x64.dll" (
    set "libcrypto=!ProgramFiles!\OpenSSL-Win64\bin\libcrypto-4-x64.dll"
) else if exist "!ProgramFiles!\Git\mingw64\bin\libcrypto-4-x64.dll" (
    set "libcrypto=!ProgramFiles!\Git\mingw64\bin\libcrypto-4-x64.dll"
)
if "!libcrypto!" == "" (
    echo 错误：缺少 OpenSSL-Win64 组件
    echo 请从 https://slproweb.com/products/Win32OpenSSL.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://slproweb.com/products/Win32OpenSSL.html"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



if "!param1!" == "" (
    echo 用法：把要加密的文件，拖拽到本脚本上
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
if exist "!param1!\" (
    echo 错误：不支持拖入文件夹，请拖入单个文件
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
if not exist "!param1_path!" (
    echo 错误：文件不存在："!param1_path!"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



echo 输入文件："!param1_path!"
set "output_file=!param1_path!.enc"
echo 输出文件："!output_file!"
if exist "!output_file!" (
    echo 输出文件已存在："!output_file!"，跳过不处理
    echo 如果需要重新加密，请先移走旧文件
    echo.
    pause
    endlocal & endlocal & exit /b 2
)
echo.

REM 下方 powershell 从自身文件末尾的 -----BEGIN CSHARP CODE----- / -----END CSHARP CODE----- 之间提取 C# 源码，并编译调用
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$lines = Get-Content -LiteralPath $env:script_path -Encoding utf8;" ^
    "$begin = [array]::IndexOf($lines, '-----BEGIN CSHARP CODE-----') + 1;" ^
    "$end = [array]::IndexOf($lines, '-----END CSHARP CODE-----');" ^
    "if ($begin -lt 1 -or $end -lt $begin) {" ^
    "    Write-Host '错误：未找到引擎代码块' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "};" ^
    "$csharpSource = ($lines[$begin..($end - 1)] -join [Environment]::NewLine);" ^
    "Add-Type -TypeDefinition $csharpSource -Language CSharp;" ^
    "$message = $null;" ^
    "$resultCode = [AesGcmCli]::LoadLib($env:libcrypto, [ref]$message);" ^
    "if ($resultCode -ne 0) {" ^
    "    Write-Host ('错误：OpenSSL-Win64 组件加载失败：' + $message) -ForegroundColor Red;" ^
    "    exit 1;" ^
    "};" ^
    "$securePassword = Read-Host '请输入加密密码' -AsSecureString;" ^
    "$passwordText = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword));" ^
    "if ([string]::IsNullOrEmpty($passwordText)) {" ^
    "    Write-Host '错误：密码不能为空' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "};" ^
    "$passwordBytes = [Text.Encoding]::UTF8.GetBytes($passwordText);" ^
    "Write-Host '正在加密，请稍候...';" ^
    "$resultCode = [AesGcmCli]::EncryptFile($env:param1_path, $env:output_file, $passwordBytes, [ref]$message);" ^
    "if ($resultCode -ne 0) {" ^
    "    Write-Host ('错误：加密失败：' + $message) -ForegroundColor Red;" ^
    "    if (Test-Path $env:output_file) { Remove-Item $env:output_file -Force -ErrorAction SilentlyContinue };" ^
    "    exit 1;" ^
    "};" ^
    "Write-Host '加密完成' -ForegroundColor Green"
if !errorlevel! neq 0 (
    echo 加密失败
) else (
    for %%j in ("!output_file!") do (
        setlocal disabledelayedexpansion
        set "file_size=%%~zj"
        setlocal enabledelayedexpansion

        echo 加密成功："!output_file!"，大小：!file_size! 字节

        endlocal
        endlocal
    )
)



echo.
pause
endlocal & endlocal & exit /b



-----BEGIN CSHARP CODE-----

// AES-256-GCM 文件加解密，使用 OpenSSL libcrypto P/Invoke 实现
// 密钥产生算法为 PBKDF2-HMAC-SHA512 + 迭代次数 1000 万
// 生成文件布局为 pbkdf2_salt (16 字节) + aes_gcm_iv (12 字节) + aes_gcm_tag (16 字节) 头部 + 文件内容密文

using System;
using System.IO;
using System.Security.Cryptography;
using System.Runtime.InteropServices;

public static class AesGcmCli
{
    private const int Pbkdf2SaltLength = 16;
    private const int AesGcmIvLength = 12;
    private const int AesGcmTagLength = 16;
    private const int AesGcmKeyLength = 32;
    private const int HeaderLength = Pbkdf2SaltLength + AesGcmIvLength + AesGcmTagLength;

    private const int IterationCount = 10000000;

    // openssl/evp.h 中 EVP_CTRL_GCM_* 宏的取值
    private const int GcmSetIvlLength = 0x9;
    private const int GcmGetTag = 0x10;
    private const int GcmSetTag = 0x11;

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate IntPtr EvpCtxNew();
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate void EvpCtxFree(IntPtr ctx);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate IntPtr EvpAes256Gcm();
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate int EvpCtxCtrl(IntPtr ctx, int cmd, int arg, IntPtr ptr);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate int EvpInit(IntPtr ctx, IntPtr cipher, IntPtr engine, IntPtr key, IntPtr iv);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate int EvpUpdate(IntPtr ctx, IntPtr output, ref int outputLength, IntPtr input, int inputLength);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate int EvpFinal(IntPtr ctx, IntPtr output, ref int outputLength);

    private static EvpCtxNew _ctxNew;
    private static EvpCtxFree _ctxFree;
    private static EvpAes256Gcm _aes256Gcm;
    private static EvpCtxCtrl _ctxCtrl;
    private static string _loadedLibPath = "";
    private static readonly object _loadLock = new object();

    private class EvpOps
    {
        public EvpInit Init;
        public EvpUpdate Update;
        public EvpFinal Final;
    }
    private static EvpOps _encryptOps;
    private static EvpOps _decryptOps;

    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
    private static extern IntPtr LoadLibrary(string path);
    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
    private static extern IntPtr GetProcAddress(IntPtr module, string name);

    private static T LoadFunction<T>(IntPtr module, string name) where T : class
    {
        IntPtr address = GetProcAddress(module, name);
        if (address == IntPtr.Zero) return null;
        return Marshal.GetDelegateForFunctionPointer(address, typeof(T)) as T;
    }

    public static int LoadLib(string libPath, out string msg)
    {
        msg = null;
        lock (_loadLock)
        {
            if (_ctxNew != null && string.Equals(_loadedLibPath, libPath, StringComparison.OrdinalIgnoreCase))
                return 0;

            IntPtr module = LoadLibrary(libPath);
            if (module == IntPtr.Zero) { msg = "无法加载 " + libPath; return 1; }

            _ctxNew = LoadFunction<EvpCtxNew>(module, "EVP_CIPHER_CTX_new");
            _ctxFree = LoadFunction<EvpCtxFree>(module, "EVP_CIPHER_CTX_free");
            _aes256Gcm = LoadFunction<EvpAes256Gcm>(module, "EVP_aes_256_gcm");
            _ctxCtrl = LoadFunction<EvpCtxCtrl>(module, "EVP_CIPHER_CTX_ctrl");

            EvpInit encInit = LoadFunction<EvpInit>(module, "EVP_EncryptInit_ex");
            EvpUpdate encUpdate = LoadFunction<EvpUpdate>(module, "EVP_EncryptUpdate");
            EvpFinal encFinal = LoadFunction<EvpFinal>(module, "EVP_EncryptFinal_ex");
            EvpInit decInit = LoadFunction<EvpInit>(module, "EVP_DecryptInit_ex");
            EvpUpdate decUpdate = LoadFunction<EvpUpdate>(module, "EVP_DecryptUpdate");
            EvpFinal decFinal = LoadFunction<EvpFinal>(module, "EVP_DecryptFinal_ex");

            if (_ctxNew == null || _ctxFree == null || _aes256Gcm == null || _ctxCtrl == null
                || encInit == null || encUpdate == null || encFinal == null
                || decInit == null || decUpdate == null || decFinal == null)
            {
                msg = libPath + " 缺少所需函数";
                return 1;
            }

            _encryptOps = new EvpOps { Init = encInit, Update = encUpdate, Final = encFinal };
            _decryptOps = new EvpOps { Init = decInit, Update = decUpdate, Final = decFinal };
            _loadedLibPath = libPath;
            return 0;
        }
    }

    private static IntPtr CopyToNative(byte[] data)
    {
        IntPtr ptr = Marshal.AllocHGlobal(data.Length);
        Marshal.Copy(data, 0, ptr, data.Length);
        return ptr;
    }

    public static int EncryptFile(string inputPath, string outputPath, byte[] password, out string msg)
    {
        msg = null;
        string tmpPath = outputPath + ".tmp";
        int res;
        try
        {
            if (password == null || password.Length == 0) throw new Exception("密码不能为空");

            byte[] pbkdf2_salt = new byte[Pbkdf2SaltLength];
            byte[] aes_gcm_iv = new byte[AesGcmIvLength];
            using (RandomNumberGenerator rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(pbkdf2_salt);
                rng.GetBytes(aes_gcm_iv);
            }

            using (FileStream input = new FileStream(inputPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (FileStream output = new FileStream(tmpPath, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                output.Write(pbkdf2_salt, 0, pbkdf2_salt.Length);
                output.Write(aes_gcm_iv, 0, aes_gcm_iv.Length);
                long tagPosition = output.Position;
                output.Write(new byte[AesGcmTagLength], 0, AesGcmTagLength); // GCM 标签须等加密结束才能算出，先留空位后回填

                byte[] key;
                using (Rfc2898DeriveBytes kdf = new Rfc2898DeriveBytes(password, pbkdf2_salt, IterationCount, HashAlgorithmName.SHA512))
                {
                    key = kdf.GetBytes(AesGcmKeyLength);
                }

                IntPtr ctx = _ctxNew();
                try
                {
                    IntPtr keyPtr = CopyToNative(key);
                    IntPtr ivPtr = CopyToNative(aes_gcm_iv);
                    try
                    {
                        // OpenSSL 惯例：先 Init 选定算法并指定 GCM 的 IV 长度，再 Init 设置 key/iv
                        if ((res = _encryptOps.Init(ctx, _aes256Gcm(), IntPtr.Zero, IntPtr.Zero, IntPtr.Zero)) != 1)
                            throw new Exception("初始化算法失败（OpenSSL 返回 " + res + "）");
                        if ((res = _ctxCtrl(ctx, GcmSetIvlLength, AesGcmIvLength, IntPtr.Zero)) != 1)
                            throw new Exception("设置 IV 长度失败（OpenSSL 返回 " + res + "）");
                        if ((res = _encryptOps.Init(ctx, IntPtr.Zero, IntPtr.Zero, keyPtr, ivPtr)) != 1)
                            throw new Exception("设置密钥失败（OpenSSL 返回 " + res + "）");
                    }
                    finally
                    {
                        Marshal.FreeHGlobal(keyPtr);
                        Marshal.FreeHGlobal(ivPtr);
                    }

                    int readChunkSize = 1 << 20; // 1 MiB
                    byte[] chunk = new byte[readChunkSize];
                    byte[] outBuffer = new byte[readChunkSize + AesGcmTagLength]; // GCM 输出最多比输入长一个 tag
                    IntPtr chunkPtr = Marshal.AllocHGlobal(chunk.Length);
                    IntPtr outPtr = Marshal.AllocHGlobal(outBuffer.Length);
                    try
                    {
                        int read;
                        while ((read = input.Read(chunk, 0, chunk.Length)) > 0)
                        {
                            Marshal.Copy(chunk, 0, chunkPtr, read);
                            int produced = 0;
                            if ((res = _encryptOps.Update(ctx, outPtr, ref produced, chunkPtr, read)) != 1)
                                throw new Exception("数据处理失败（OpenSSL 返回 " + res + "）");
                            if (produced > 0)
                            {
                                Marshal.Copy(outPtr, outBuffer, 0, produced);
                                output.Write(outBuffer, 0, produced);
                            }
                        }

                        int tailLength = 0;
                        if (_encryptOps.Final(ctx, outPtr, ref tailLength) != 1) throw new Exception("加密收尾失败");
                        if (tailLength > 0)
                        {
                            Marshal.Copy(outPtr, outBuffer, 0, tailLength);
                            output.Write(outBuffer, 0, tailLength);
                        }
                    }
                    finally
                    {
                        Marshal.FreeHGlobal(chunkPtr);
                        Marshal.FreeHGlobal(outPtr);
                    }

                    byte[] aes_gcm_tag = new byte[AesGcmTagLength];
                    IntPtr tagPtr = Marshal.AllocHGlobal(aes_gcm_tag.Length);
                    try
                    {
                        if ((res = _ctxCtrl(ctx, GcmGetTag, aes_gcm_tag.Length, tagPtr)) != 1)
                            throw new Exception("读取认证标签失败（OpenSSL 返回 " + res + "）");
                        Marshal.Copy(tagPtr, aes_gcm_tag, 0, aes_gcm_tag.Length);
                    }
                    finally { Marshal.FreeHGlobal(tagPtr); }

                    output.Position = tagPosition;
                    output.Write(aes_gcm_tag, 0, aes_gcm_tag.Length);
                }
                finally { _ctxFree(ctx); }
            }
            try { if (File.Exists(outputPath)) File.Delete(outputPath); } catch { }
            File.Move(tmpPath, outputPath);
            return 0;
        }
        catch (Exception ex)
        {
            try { if (File.Exists(tmpPath)) File.Delete(tmpPath); } catch { }
            msg = ex.Message;
            return 1;
        }
    }

    public static int DecryptFile(string inputPath, string outputPath, byte[] password, out string msg)
    {
        msg = null;
        string tmpPath = outputPath + ".tmp";
        int res;
        try
        {
            if (password == null || password.Length == 0) throw new Exception("密码不能为空");

            using (FileStream input = new FileStream(inputPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (FileStream output = new FileStream(tmpPath, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                if (input.Length < HeaderLength) throw new Exception("文件太短，不是有效的加密文件");

                byte[] header = new byte[HeaderLength];
                int headerRead = 0;
                while (headerRead < header.Length)
                {
                    int read = input.Read(header, headerRead, header.Length - headerRead);
                    if (read <= 0) throw new Exception("读取文件失败：文件不完整");
                    headerRead += read;
                }
                byte[] pbkdf2_salt = new byte[Pbkdf2SaltLength];
                byte[] aes_gcm_iv = new byte[AesGcmIvLength];
                byte[] aes_gcm_tag = new byte[AesGcmTagLength];
                Buffer.BlockCopy(header, 0, pbkdf2_salt, 0, Pbkdf2SaltLength);
                Buffer.BlockCopy(header, Pbkdf2SaltLength, aes_gcm_iv, 0, AesGcmIvLength);
                Buffer.BlockCopy(header, Pbkdf2SaltLength + AesGcmIvLength, aes_gcm_tag, 0, AesGcmTagLength);

                byte[] key;
                using (Rfc2898DeriveBytes kdf = new Rfc2898DeriveBytes(password, pbkdf2_salt, IterationCount, HashAlgorithmName.SHA512))
                {
                    key = kdf.GetBytes(AesGcmKeyLength);
                }

                IntPtr ctx = _ctxNew();
                try
                {
                    IntPtr keyPtr = CopyToNative(key);
                    IntPtr ivPtr = CopyToNative(aes_gcm_iv);
                    try
                    {
                        if ((res = _decryptOps.Init(ctx, _aes256Gcm(), IntPtr.Zero, IntPtr.Zero, IntPtr.Zero)) != 1)
                            throw new Exception("初始化算法失败（OpenSSL 返回 " + res + "）");
                        if ((res = _ctxCtrl(ctx, GcmSetIvlLength, AesGcmIvLength, IntPtr.Zero)) != 1)
                            throw new Exception("设置 IV 长度失败（OpenSSL 返回 " + res + "）");
                        if ((res = _decryptOps.Init(ctx, IntPtr.Zero, IntPtr.Zero, keyPtr, ivPtr)) != 1)
                            throw new Exception("设置密钥失败（OpenSSL 返回 " + res + "）");
                    }
                    finally
                    {
                        Marshal.FreeHGlobal(keyPtr);
                        Marshal.FreeHGlobal(ivPtr);
                    }

                    IntPtr tagPtr = CopyToNative(aes_gcm_tag);
                    try
                    {
                        if ((res = _ctxCtrl(ctx, GcmSetTag, aes_gcm_tag.Length, tagPtr)) != 1)
                            throw new Exception("写入认证标签失败（OpenSSL 返回 " + res + "）");
                    }
                    finally { Marshal.FreeHGlobal(tagPtr); }

                    int readChunkSize = 1 << 20; // 1 MiB
                    byte[] chunk = new byte[readChunkSize];
                    byte[] outBuffer = new byte[readChunkSize + AesGcmTagLength]; // GCM 输出最多比输入长一个 tag
                    IntPtr chunkPtr = Marshal.AllocHGlobal(chunk.Length);
                    IntPtr outPtr = Marshal.AllocHGlobal(outBuffer.Length);
                    try
                    {
                        int read;
                        while ((read = input.Read(chunk, 0, chunk.Length)) > 0)
                        {
                            Marshal.Copy(chunk, 0, chunkPtr, read);
                            int produced = 0;
                            if ((res = _decryptOps.Update(ctx, outPtr, ref produced, chunkPtr, read)) != 1)
                                throw new Exception("数据处理失败（OpenSSL 返回 " + res + "）");
                            if (produced > 0)
                            {
                                Marshal.Copy(outPtr, outBuffer, 0, produced);
                                output.Write(outBuffer, 0, produced);
                            }
                        }

                        int tailLength = 0;
                        if (_decryptOps.Final(ctx, outPtr, ref tailLength) != 1) throw new Exception("认证失败：密码错误");
                        if (tailLength > 0)
                        {
                            Marshal.Copy(outPtr, outBuffer, 0, tailLength);
                            output.Write(outBuffer, 0, tailLength);
                        }
                    }
                    finally
                    {
                        Marshal.FreeHGlobal(chunkPtr);
                        Marshal.FreeHGlobal(outPtr);
                    }
                }
                finally { _ctxFree(ctx); }
            }
            try { if (File.Exists(outputPath)) File.Delete(outputPath); } catch { }
            File.Move(tmpPath, outputPath);
            return 0;
        }
        catch (Exception ex)
        {
            try { if (File.Exists(tmpPath)) File.Delete(tmpPath); } catch { }
            msg = ex.Message;
            return 1;
        }
    }
}

-----END CSHARP CODE-----
