@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将 enc 后缀的加密文件解密，还原为原始文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '用户输入的密码，使用 PBKDF2-HMAC-SHA512 产生密钥，然后进行 AES-256-GCM 解密' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '选中一个文件，拖拽到此脚本上执行；不支持拖入文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '如果原始文件已存在，则跳过不处理' -ForegroundColor Green"
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
    echo 用法：把要解密的 .enc 文件，拖拽到本脚本上
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
if exist "!param1!\" (
    echo 错误：不支持拖入文件夹，请拖入单个 .enc 文件
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
if /i not "!param1_path:~-4!" == ".enc" (
    echo 错误：请拖入以 .enc 后缀的加密文件
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
set "output_file=!param1_path:~0,-4!"
echo 输出文件："!output_file!"
if "!output_file!" == "" (
    echo 错误：无法确定输出路径
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
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
    "$securePassword1 = Read-Host '请输入解密密码' -AsSecureString;" ^
    "$passwordText1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword1));" ^
    "if ([string]::IsNullOrEmpty($passwordText1)) {" ^
    "    Write-Host '错误：密码不能为空' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "};" ^
    "$passwordBytes = [Text.Encoding]::UTF8.GetBytes($passwordText1);" ^
    "Write-Host '正在解密，请稍候...';" ^
    "$resultCode = [AesGcmCli]::DecryptFile($env:param1_path, $env:output_file, $passwordBytes, [ref]$message);" ^
    "if ($resultCode -ne 0) {" ^
    "    Write-Host ('解密失败：' + $message) -ForegroundColor Red;" ^
    "    if (Test-Path $env:output_file) { Remove-Item $env:output_file -Force -ErrorAction SilentlyContinue };" ^
    "    exit 1;" ^
    "};" ^
    "Write-Host '解密完成' -ForegroundColor Green"
if !errorlevel! neq 0 (
    echo 解密失败
) else (
    for %%j in ("!output_file!") do (
        setlocal disabledelayedexpansion
        set "file_size=%%~zj"
        setlocal enabledelayedexpansion

        echo 解密成功："!output_file!"，大小：!file_size! 字节

        endlocal
        endlocal
    )
)



echo.
pause
endlocal & endlocal & exit /b



-----BEGIN CSHARP CODE-----
// AesGcmCli.cs - AES-256-GCM 文件加解密（经 OpenSSL libcrypto P/Invoke 实现）
// 文件布局：salt(16) + iv(12) + tag(16) 头部，其后为密文；不含任何文件标识
// 密钥派生：PBKDF2-HMAC-SHA512，迭代固定 1000 万（写死在源码，不写入文件）
using System;
using System.IO;
using System.Security.Cryptography;
using System.Runtime.InteropServices;

public static class AesGcmCli
{
    private const int SaltLength = 16;
    private const int IvLength = 12;
    private const int TagLength = 16;
    private const int KeyLength = 32;
    private const int HeaderLength = SaltLength + IvLength + TagLength;

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

            EvpOps encrypt = LoadOps(module, "EVP_EncryptInit_ex", "EVP_EncryptUpdate", "EVP_EncryptFinal_ex");
            EvpOps decrypt = LoadOps(module, "EVP_DecryptInit_ex", "EVP_DecryptUpdate", "EVP_DecryptFinal_ex");

            if (_ctxNew == null || _ctxFree == null || _aes256Gcm == null || _ctxCtrl == null
                || encrypt == null || decrypt == null)
            {
                msg = libPath + " 版本不兼容：缺少所需函数（需要 OpenSSL 1.1.1 及以上，推荐 3.x）";
                return 1;
            }

            _encryptOps = encrypt;
            _decryptOps = decrypt;
            _loadedLibPath = libPath;
            return 0;
        }
    }

    private static EvpOps LoadOps(IntPtr module, string initName, string updateName, string finalName)
    {
        EvpInit init = LoadFunction<EvpInit>(module, initName);
        EvpUpdate update = LoadFunction<EvpUpdate>(module, updateName);
        EvpFinal final = LoadFunction<EvpFinal>(module, finalName);
        if (init == null || update == null || final == null) return null;

        EvpOps ops = new EvpOps();
        ops.Init = init;
        ops.Update = update;
        ops.Final = final;
        return ops;
    }

    private static void CheckOk(int resultCode, string action)
    {
        if (resultCode != 1) throw new Exception(action + "（OpenSSL 返回 " + resultCode + "）");
    }

    private static IntPtr CopyToNative(byte[] data)
    {
        IntPtr ptr = Marshal.AllocHGlobal(data.Length);
        Marshal.Copy(data, 0, ptr, data.Length);
        return ptr;
    }

    private static void FreeNative(IntPtr ptr) { Marshal.FreeHGlobal(ptr); }

    private static void ReadFully(Stream input, byte[] buffer)
    {
        int total = 0;
        while (total < buffer.Length)
        {
            int read = input.Read(buffer, total, buffer.Length - total);
            if (read <= 0) throw new Exception("读取文件失败：文件不完整");
            total += read;
        }
    }

    private static void DeleteIfExists(string path)
    {
        try { if (File.Exists(path)) File.Delete(path); } catch { }
    }

    private static byte[] DeriveKey(byte[] password, byte[] salt)
    {
        using (Rfc2898DeriveBytes kdf = new Rfc2898DeriveBytes(password, salt, IterationCount, HashAlgorithmName.SHA512))
        {
            return kdf.GetBytes(KeyLength);
        }
    }

    // OpenSSL 惯例：先 Init 选定算法并指定 GCM 的 IV 长度，再 Init 设置 key/iv
    private static IntPtr BeginCipher(EvpOps ops, byte[] key, byte[] iv)
    {
        IntPtr ctx = _ctxNew();
        try
        {
            IntPtr keyPtr = CopyToNative(key);
            IntPtr ivPtr = CopyToNative(iv);
            try
            {
                CheckOk(ops.Init(ctx, _aes256Gcm(), IntPtr.Zero, IntPtr.Zero, IntPtr.Zero), "初始化算法失败");
                CheckOk(_ctxCtrl(ctx, GcmSetIvlLength, IvLength, IntPtr.Zero), "设置 IV 长度失败");
                CheckOk(ops.Init(ctx, IntPtr.Zero, IntPtr.Zero, keyPtr, ivPtr), "设置密钥失败");
            }
            finally
            {
                FreeNative(keyPtr);
                FreeNative(ivPtr);
            }
            return ctx;
        }
        catch
        {
            _ctxFree(ctx);
            throw;
        }
    }

    private static int ProcessStream(EvpOps ops, IntPtr ctx, Stream input, Stream output)
    {
        int readChunkSize = 1 << 20; // 1 MiB
        byte[] chunk = new byte[readChunkSize];
        byte[] outBuffer = new byte[readChunkSize + TagLength]; // GCM 输出最多比输入长一个 tag
        IntPtr chunkPtr = Marshal.AllocHGlobal(chunk.Length);
        IntPtr outPtr = Marshal.AllocHGlobal(outBuffer.Length);
        try
        {
            int read;
            while ((read = input.Read(chunk, 0, chunk.Length)) > 0)
            {
                Marshal.Copy(chunk, 0, chunkPtr, read);
                int produced = 0;
                CheckOk(ops.Update(ctx, outPtr, ref produced, chunkPtr, read), "数据处理失败");
                if (produced > 0)
                {
                    Marshal.Copy(outPtr, outBuffer, 0, produced);
                    output.Write(outBuffer, 0, produced);
                }
            }

            int tailLength = 0;
            int result = ops.Final(ctx, outPtr, ref tailLength);
            if (result == 1 && tailLength > 0)
            {
                Marshal.Copy(outPtr, outBuffer, 0, tailLength);
                output.Write(outBuffer, 0, tailLength);
            }
            return result;
        }
        finally
        {
            FreeNative(chunkPtr);
            FreeNative(outPtr);
        }
    }

    private static byte[] GetTag(IntPtr ctx)
    {
        byte[] tag = new byte[TagLength];
        IntPtr tagPtr = Marshal.AllocHGlobal(tag.Length);
        try
        {
            CheckOk(_ctxCtrl(ctx, GcmGetTag, tag.Length, tagPtr), "读取认证标签失败");
            Marshal.Copy(tagPtr, tag, 0, tag.Length);
            return tag;
        }
        finally { FreeNative(tagPtr); }
    }

    private static void SetTag(IntPtr ctx, byte[] tag)
    {
        IntPtr tagPtr = CopyToNative(tag);
        try { CheckOk(_ctxCtrl(ctx, GcmSetTag, tag.Length, tagPtr), "写入认证标签失败"); }
        finally { FreeNative(tagPtr); }
    }

    public static int EncryptFile(string inputPath, string outputPath, byte[] password, out string msg)
    {
        msg = null;
        string tmpPath = outputPath + ".tmp";
        try
        {
            if (password == null || password.Length == 0) throw new Exception("密码不能为空");

            byte[] salt = new byte[SaltLength];
            byte[] iv = new byte[IvLength];
            using (RandomNumberGenerator rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(salt);
                rng.GetBytes(iv);
            }

            using (FileStream input = new FileStream(inputPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (FileStream output = new FileStream(tmpPath, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                output.Write(salt, 0, salt.Length);
                output.Write(iv, 0, iv.Length);
                long tagPosition = output.Position;
                output.Write(new byte[TagLength], 0, TagLength); // GCM 标签须等加密结束才能算出，先留空位后回填

                byte[] key = DeriveKey(password, salt);
                IntPtr ctx = BeginCipher(_encryptOps, key, iv);
                try
                {
                    if (ProcessStream(_encryptOps, ctx, input, output) != 1) throw new Exception("加密收尾失败");
                    byte[] tag = GetTag(ctx);
                    output.Position = tagPosition;
                    output.Write(tag, 0, tag.Length);
                }
                finally { _ctxFree(ctx); }
            }
            DeleteIfExists(outputPath);
            File.Move(tmpPath, outputPath);
            return 0;
        }
        catch (Exception ex)
        {
            DeleteIfExists(tmpPath);
            msg = ex.Message;
            return 1;
        }
    }

    public static int DecryptFile(string inputPath, string outputPath, byte[] password, out string msg)
    {
        msg = null;
        string tmpPath = outputPath + ".tmp";
        try
        {
            if (password == null || password.Length == 0) throw new Exception("密码不能为空");

            using (FileStream input = new FileStream(inputPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (FileStream output = new FileStream(tmpPath, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                if (input.Length < HeaderLength) throw new Exception("文件太短，不是有效的加密文件");

                byte[] header = new byte[HeaderLength];
                ReadFully(input, header);
                byte[] salt = new byte[SaltLength];
                byte[] iv = new byte[IvLength];
                byte[] tag = new byte[TagLength];
                Buffer.BlockCopy(header, 0, salt, 0, SaltLength);
                Buffer.BlockCopy(header, SaltLength, iv, 0, IvLength);
                Buffer.BlockCopy(header, SaltLength + IvLength, tag, 0, TagLength);

                byte[] key = DeriveKey(password, salt);
                IntPtr ctx = BeginCipher(_decryptOps, key, iv);
                try
                {
                    SetTag(ctx, tag);
                    if (ProcessStream(_decryptOps, ctx, input, output) != 1) throw new Exception("认证失败：密码错误或文件被篡改");
                }
                finally { _ctxFree(ctx); }
            }
            DeleteIfExists(outputPath);
            File.Move(tmpPath, outputPath);
            return 0;
        }
        catch (Exception ex)
        {
            DeleteIfExists(tmpPath);
            msg = ex.Message;
            return 1;
        }
    }
}
-----END CSHARP CODE-----
