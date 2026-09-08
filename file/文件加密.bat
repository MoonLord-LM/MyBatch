@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将单个文件加密为 .enc（AES-256-GCM，OpenSSL libcrypto 引擎，产物与原文件同目录）' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '密码经 PBKDF2-HMAC-SHA256 派生（60 万次）；用 SecureString 读取两次确认，不回显' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '用法：把要加密的文件拖拽到本脚本上即可' -ForegroundColor Green"
echo.



if "!param1!" == "" (
    echo 用法：把要加密的文件拖拽到本脚本上
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
if exist "!param1!\" (
    echo 错误：不支持文件夹，请拖入单个文件
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
    echo 错误：未找到 libcrypto-4-x64.dll
    echo 请安装 OpenSSL-Win64：https://slproweb.com/products/Win32OpenSSL.html
    echo 或安装 Git for Windows（较新版本 mingw64\bin 内含 libcrypto-4-x64.dll）
    echo 也可把该 DLL 复制到本脚本所在文件夹
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



set "output_file=!param1_path!.enc"
echo 输入文件："!param1_path!"
echo 输出文件："!output_file!"
echo.

if exist "!output_file!" (
    echo 输出文件已存在："!output_file!"
    echo 已跳过。如需重新加密，请先删除或移走旧文件
    echo.
    pause
    endlocal & endlocal & exit /b 2
)



REM 文件末尾的 -----BEGIN CSHARP CODE----- / -----END CSHARP CODE----- 之间是引擎 C# 源码，由下方 powershell 从自身文件取出并编译
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$lines = Get-Content -LiteralPath $env:script_path -Encoding utf8;" ^
    "$s = [array]::IndexOf($lines, '-----BEGIN CSHARP CODE-----') + 1;" ^
    "$e = [array]::IndexOf($lines, '-----END CSHARP CODE-----');" ^
    "if ($s -lt 1 -or $e -lt $s) { Write-Host '错误：未找到引擎代码块' -ForegroundColor Red; exit 1 };" ^
    "$cs = ($lines[$s..($e - 1)] -join [Environment]::NewLine);" ^
    "Add-Type -TypeDefinition $cs -Language CSharp;" ^
    "$m = $null;" ^
    "$rc = [AesGcmCli]::LoadLib($env:libcrypto, [ref]$m);" ^
    "if ($rc -ne 0) { Write-Host ('libcrypto 加载失败：' + $m) -ForegroundColor Red; exit 1 };" ^
    "$s1 = Read-Host '请输入加密密码（输入时不显示）' -AsSecureString;" ^
    "$s2 = Read-Host '请再次输入相同密码确认' -AsSecureString;" ^
    "$a = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s1));" ^
    "$b = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s2));" ^
    "if ($a -cne $b) { Write-Host '两次输入的密码不一致，已取消' -ForegroundColor Red; exit 1 };" ^
    "if ([string]::IsNullOrEmpty($a)) { Write-Host '密码不能为空，已取消' -ForegroundColor Red; exit 1 };" ^
    "$pwd = [Text.Encoding]::UTF8.GetBytes($a);" ^
    "Write-Host '正在加密（PBKDF2 需数秒，请稍候）...' -ForegroundColor Yellow;" ^
    "$rc = [AesGcmCli]::EncryptFile($env:param1_path, $env:output_file, $pwd, 600000, [ref]$m);" ^
    "if ($rc -ne 0) { Write-Host ('加密失败：' + $m) -ForegroundColor Red; if (Test-Path $env:output_file) { Remove-Item $env:output_file -Force -ErrorAction SilentlyContinue }; exit 1 };" ^
    "Write-Host '加密完成' -ForegroundColor Green"
if !errorlevel! neq 0 (
    echo 加密失败，请查看上方错误信息
) else (
    for %%f in ("!output_file!") do set "file_size=%%~zf"
    echo 加密成功："!output_file!"，大小：!file_size! 字节
)



echo.
pause
endlocal & endlocal & exit /b



-----BEGIN CSHARP CODE-----
// AesGcmCli.cs - AES-256-GCM via OpenSSL libcrypto DLL (P/Invoke), PBKDF2-HMAC-SHA256 via .NET
// Encrypted file layout (total header 56 bytes + ciphertext):
//   [8B magic "MYAESG01"][4B iterations u32 LE][16B salt][12B iv][16B auth tag][ciphertext]
using System;
using System.IO;
using System.Text;
using System.Security.Cryptography;
using System.Runtime.InteropServices;

public static class AesGcmCli
{
    const int CTRL_GCM_SET_IVLEN = 0x9;
    const int CTRL_GCM_GET_TAG   = 0x10;
    const int CTRL_GCM_SET_TAG   = 0x11;
    const int SALT_LEN = 16, IV_LEN = 12, TAG_LEN = 16, KEY_LEN = 32;
    const int HDR_LEN = 8 + 4 + SALT_LEN + IV_LEN + TAG_LEN;
    const int MIN_ITER = 1000, MAX_ITER = 100000000;

    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
    static extern IntPtr LoadLibrary(string lpFileName);
    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
    static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);

    delegate IntPtr D_CtxNew();
    delegate void   D_CtxFree(IntPtr ctx);
    delegate IntPtr D_Aes256Gcm();
    delegate int    D_Ctrl(IntPtr ctx, int type, int arg, IntPtr ptr);
    delegate int    D_InitEx(IntPtr ctx, IntPtr cipher, IntPtr impl, IntPtr key, IntPtr iv);
    delegate int    D_InitEx2(IntPtr ctx, IntPtr cipher, IntPtr key, IntPtr iv, IntPtr prm);
    delegate int    D_Update(IntPtr ctx, IntPtr outp, ref int outl, IntPtr inp, int inl);
    delegate int    D_Final(IntPtr ctx, IntPtr outp, ref int outl);

    static D_CtxNew   _ctxNew;
    static D_CtxFree  _ctxFree;
    static D_Aes256Gcm _cipher;
    static D_Ctrl     _ctrl;
    static D_InitEx   _initEx;
    static D_InitEx2  _initEx2;
    static D_InitEx   _decInitEx;
    static D_InitEx2  _decInitEx2;
    static D_Update   _update;
    static D_Final    _final;
    static D_Update   _decUpdate;
    static D_Final    _decFinal;

    static string _libPath = "";
    static readonly object _lock = new object();

    static T GetDelegate<T>(IntPtr proc) where T : class
    {
        if (proc == IntPtr.Zero) return null;
        return Marshal.GetDelegateForFunctionPointer(proc, typeof(T)) as T;
    }

    public static int LoadLib(string libPath, out string msg)
    {
        msg = null;
        lock (_lock)
        {
            if (_ctxNew != null && string.Equals(_libPath, libPath, StringComparison.OrdinalIgnoreCase))
                return 0;
            IntPtr h = LoadLibrary(libPath);
            if (h == IntPtr.Zero)
            {
                msg = "无法加载 " + libPath;
                return 1;
            }
            _ctxNew  = GetDelegate<D_CtxNew>(GetProcAddress(h, "EVP_CIPHER_CTX_new"));
            _ctxFree = GetDelegate<D_CtxFree>(GetProcAddress(h, "EVP_CIPHER_CTX_free"));
            _cipher  = GetDelegate<D_Aes256Gcm>(GetProcAddress(h, "EVP_aes_256_gcm"));
            _ctrl    = GetDelegate<D_Ctrl>(GetProcAddress(h, "EVP_CIPHER_CTX_ctrl"));
            _initEx  = GetDelegate<D_InitEx>(GetProcAddress(h, "EVP_EncryptInit_ex"));
            _initEx2 = GetDelegate<D_InitEx2>(GetProcAddress(h, "EVP_EncryptInit_ex2"));
            _decInitEx  = GetDelegate<D_InitEx>(GetProcAddress(h, "EVP_DecryptInit_ex"));
            _decInitEx2 = GetDelegate<D_InitEx2>(GetProcAddress(h, "EVP_DecryptInit_ex2"));
            _update  = GetDelegate<D_Update>(GetProcAddress(h, "EVP_EncryptUpdate"));
            _final   = GetDelegate<D_Final>(GetProcAddress(h, "EVP_EncryptFinal_ex"));
            _decUpdate = GetDelegate<D_Update>(GetProcAddress(h, "EVP_DecryptUpdate"));
            _decFinal  = GetDelegate<D_Final>(GetProcAddress(h, "EVP_DecryptFinal_ex"));

            if (_ctxNew == null || _ctxFree == null || _cipher == null || _ctrl == null || _update == null || _final == null)
            {
                msg = libPath + " 缺少必需的 EVP 函数（版本不兼容）";
                return 1;
            }
            if (_initEx == null && _initEx2 == null)
            {
                msg = libPath + " 缺少 EVP_EncryptInit_ex / _ex2";
                return 1;
            }
            if (_decInitEx == null && _decInitEx2 == null)
            {
                msg = libPath + " 缺少 EVP_DecryptInit_ex / _ex2";
                return 1;
            }
            _libPath = libPath;
            return 0;
        }
    }

    static byte[] Pbkdf2Sha256(byte[] pwd, byte[] salt, int iterations, int keyLen)
    {
        using (var k = new Rfc2898DeriveBytes(pwd, salt, iterations, HashAlgorithmName.SHA256))
            return k.GetBytes(keyLen);
    }

    static IntPtr CopyIn(byte[] data)
    {
        IntPtr p = Marshal.AllocHGlobal(data == null ? 1 : data.Length);
        if (data != null && data.Length > 0)
            Marshal.Copy(data, 0, p, data.Length);
        return p;
    }

    static void ThrowIfNotOk(int r, string what)
    {
        if (r != 1) throw new Exception(what + " 失败 (EVP 返回 " + r + ")");
    }

    static IntPtr NewCtx() { return _ctxNew(); }

    static void StartEncrypt(IntPtr ctx, IntPtr cipher, byte[] key, byte[] iv)
    {
        if (_initEx != null)
        {
            ThrowIfNotOk(_initEx(ctx, cipher, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero), "EncryptInit(cipher)");
            ThrowIfNotOk(_ctrl(ctx, CTRL_GCM_SET_IVLEN, IV_LEN, IntPtr.Zero), "SET_IVLEN");
            IntPtr kp = CopyIn(key), vp = CopyIn(iv);
            try { ThrowIfNotOk(_initEx(ctx, IntPtr.Zero, IntPtr.Zero, kp, vp), "EncryptInit(key/iv)"); }
            finally { Marshal.FreeHGlobal(kp); Marshal.FreeHGlobal(vp); }
        }
        else
        {
            ThrowIfNotOk(_initEx2(ctx, cipher, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero), "EncryptInit2(cipher)");
            ThrowIfNotOk(_ctrl(ctx, CTRL_GCM_SET_IVLEN, IV_LEN, IntPtr.Zero), "SET_IVLEN");
            IntPtr kp = CopyIn(key), vp = CopyIn(iv);
            try { ThrowIfNotOk(_initEx2(ctx, IntPtr.Zero, kp, vp, IntPtr.Zero), "EncryptInit2(key/iv)"); }
            finally { Marshal.FreeHGlobal(kp); Marshal.FreeHGlobal(vp); }
        }
    }

    static void StartDecrypt(IntPtr ctx, IntPtr cipher, byte[] key, byte[] iv)
    {
        if (_decInitEx != null)
        {
            ThrowIfNotOk(_decInitEx(ctx, cipher, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero), "DecryptInit(cipher)");
            ThrowIfNotOk(_ctrl(ctx, CTRL_GCM_SET_IVLEN, IV_LEN, IntPtr.Zero), "SET_IVLEN");
            IntPtr kp = CopyIn(key), vp = CopyIn(iv);
            try { ThrowIfNotOk(_decInitEx(ctx, IntPtr.Zero, IntPtr.Zero, kp, vp), "DecryptInit(key/iv)"); }
            finally { Marshal.FreeHGlobal(kp); Marshal.FreeHGlobal(vp); }
        }
        else
        {
            ThrowIfNotOk(_decInitEx2(ctx, cipher, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero), "DecryptInit2(cipher)");
            ThrowIfNotOk(_ctrl(ctx, CTRL_GCM_SET_IVLEN, IV_LEN, IntPtr.Zero), "SET_IVLEN");
            IntPtr kp = CopyIn(key), vp = CopyIn(iv);
            try { ThrowIfNotOk(_decInitEx2(ctx, IntPtr.Zero, kp, vp, IntPtr.Zero), "DecryptInit2(key/iv)"); }
            finally { Marshal.FreeHGlobal(kp); Marshal.FreeHGlobal(vp); }
        }
    }

    static byte[] GetTag(IntPtr ctx)
    {
        byte[] tag = new byte[TAG_LEN];
        IntPtr p = Marshal.AllocHGlobal(TAG_LEN);
        try
        {
            ThrowIfNotOk(_ctrl(ctx, CTRL_GCM_GET_TAG, TAG_LEN, p), "GET_TAG");
            Marshal.Copy(p, tag, 0, TAG_LEN);
            return tag;
        }
        finally { Marshal.FreeHGlobal(p); }
    }

    static void SetTag(IntPtr ctx, byte[] tag)
    {
        IntPtr p = CopyIn(tag);
        try { ThrowIfNotOk(_ctrl(ctx, CTRL_GCM_SET_TAG, TAG_LEN, p), "SET_TAG"); }
        finally { Marshal.FreeHGlobal(p); }
    }

    public static int EncryptFile(string inPath, string outPath, byte[] pwd, int iterations, out string msg)
    {
        msg = null;
        if (pwd == null || pwd.Length == 0) { msg = "密码为空"; return 1; }
        if (iterations < MIN_ITER || iterations > MAX_ITER) { msg = "迭代次数非法"; return 1; }
        try
        {
            using (FileStream ins = new FileStream(inPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (FileStream outs = new FileStream(outPath, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                byte[] magic = Encoding.ASCII.GetBytes("MYAESG01");
                byte[] salt = new byte[SALT_LEN], iv = new byte[IV_LEN];
                using (var rng = RandomNumberGenerator.Create()) { rng.GetBytes(salt); rng.GetBytes(iv); }

                outs.Write(magic, 0, 8);
                outs.Write(BitConverter.GetBytes((uint)iterations), 0, 4);
                outs.Write(salt, 0, SALT_LEN);
                outs.Write(iv, 0, IV_LEN);
                long tagPos = outs.Position;
                outs.Write(new byte[TAG_LEN], 0, TAG_LEN);

                byte[] key = Pbkdf2Sha256(pwd, salt, iterations, KEY_LEN);
                IntPtr ctx = NewCtx();
                try
                {
                    StartEncrypt(ctx, _cipher(), key, iv);
                    byte[] ib = new byte[1 << 20], ob = new byte[(1 << 20) + 64];
                    IntPtr ip = Marshal.AllocHGlobal(ib.Length), op = Marshal.AllocHGlobal(ob.Length);
                    try
                    {
                        int n;
                        while ((n = ins.Read(ib, 0, ib.Length)) > 0)
                        {
                            Marshal.Copy(ib, 0, ip, n);
                            int ol = 0;
                            ThrowIfNotOk(_update(ctx, op, ref ol, ip, n), "EncryptUpdate");
                            if (ol > 0) { byte[] o = new byte[ol]; Marshal.Copy(op, o, 0, ol); outs.Write(o, 0, ol); }
                        }
                        int fl = 0;
                        ThrowIfNotOk(_final(ctx, op, ref fl), "EncryptFinal");
                        if (fl > 0) { byte[] o = new byte[fl]; Marshal.Copy(op, o, 0, fl); outs.Write(o, 0, fl); }
                    }
                    finally { Marshal.FreeHGlobal(ip); Marshal.FreeHGlobal(op); }

                    byte[] tag = GetTag(ctx);
                    outs.Position = tagPos;
                    outs.Write(tag, 0, TAG_LEN);
                }
                finally { _ctxFree(ctx); }
            }
            return 0;
        }
        catch (Exception ex) { msg = ex.Message; return 1; }
    }

    public static int DecryptFile(string inPath, string outPath, byte[] pwd, out string msg)
    {
        msg = null;
        if (pwd == null || pwd.Length == 0) { msg = "密码为空"; return 1; }
        string tmpOut = null;
        try
        {
            tmpOut = outPath + ".tmp";
            int code = 0;
            using (FileStream ins = new FileStream(inPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (FileStream outs = new FileStream(tmpOut, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                if (ins.Length < HDR_LEN) { msg = "文件太短，不是有效的加密文件"; return 1; }
                byte[] hdr = new byte[HDR_LEN];
                ins.Read(hdr, 0, HDR_LEN);
                string magic = Encoding.ASCII.GetString(hdr, 0, 8);
                if (magic != "MYAESG01") { msg = "文件头不匹配，不是本工具加密的文件"; return 1; }
                uint iterations = BitConverter.ToUInt32(hdr, 8);
                if (iterations < MIN_ITER || iterations > MAX_ITER) { msg = "文件中的迭代次数非法"; return 1; }
                byte[] salt = new byte[SALT_LEN], iv = new byte[IV_LEN], tag = new byte[TAG_LEN];
                Buffer.BlockCopy(hdr, 12, salt, 0, SALT_LEN);
                Buffer.BlockCopy(hdr, 28, iv, 0, IV_LEN);
                Buffer.BlockCopy(hdr, 40, tag, 0, TAG_LEN);

                byte[] key = Pbkdf2Sha256(pwd, salt, (int)iterations, KEY_LEN);
                IntPtr ctx = NewCtx();
                try
                {
                    StartDecrypt(ctx, _cipher(), key, iv);
                    SetTag(ctx, tag);
                    byte[] ib = new byte[1 << 20], ob = new byte[(1 << 20) + 64];
                    IntPtr ip = Marshal.AllocHGlobal(ib.Length), op = Marshal.AllocHGlobal(ob.Length);
                    try
                    {
                        int n;
                        while ((n = ins.Read(ib, 0, ib.Length)) > 0)
                        {
                            Marshal.Copy(ib, 0, ip, n);
                            int ol = 0;
                            ThrowIfNotOk(_decUpdate(ctx, op, ref ol, ip, n), "DecryptUpdate");
                            if (ol > 0) { byte[] o = new byte[ol]; Marshal.Copy(op, o, 0, ol); outs.Write(o, 0, ol); }
                        }
                        int fl = 0;
                        int r = _decFinal(ctx, op, ref fl);
                        if (r != 1)
                        {
                            msg = "认证失败：密码错误或文件被篡改";
                            code = 1;
                        }
                        else if (fl > 0) { byte[] o = new byte[fl]; Marshal.Copy(op, o, 0, fl); outs.Write(o, 0, fl); }
                    }
                    finally { Marshal.FreeHGlobal(ip); Marshal.FreeHGlobal(op); }
                }
                finally { _ctxFree(ctx); }
            }

            if (code != 0)
            {
                File.Delete(tmpOut);
                return code;
            }
            if (File.Exists(outPath)) File.Delete(outPath);
            File.Move(tmpOut, outPath);
            return 0;
        }
        catch (Exception ex)
        {
            try { if (tmpOut != null && File.Exists(tmpOut)) File.Delete(tmpOut); } catch { }
            msg = ex.Message;
            return 1;
        }
    }
}
-----END CSHARP CODE-----
