@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion

powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.
powershell -NoProfile -Command "Write-Host '解密 AES-256-GCM 加密的 .enc 文件，还原为原始文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '密钥派生：PBKDF2-HMAC-SHA256（迭代次数从 .enc 文件头读取）' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '需与加密时相同的密码；密码错误或文件被篡改会被 GCM 认证拦截' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '密码用 SecureString 读取两次（不回显、不进入命令行）' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '把 .enc 文件拖拽到本脚本上即可解密；若原文件仍存在则自动跳过，避免覆盖' -ForegroundColor Green"
echo.



if "!param1!" == "" (
    echo 用法：把要解密的 .enc 文件拖拽到本脚本上
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
if exist "!param1!\" (
    echo 错误：不支持文件夹，请拖入 .enc 文件
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
if /i not "!param1_path:~-4!" == ".enc" (
    echo 错误：请拖入以 .enc 结尾的加密文件（当前："!param1_path!"）
    echo.
    pause
    endlocal & endlocal & exit /b 1
)

set "libcrypto="
if exist "!script_dir!libcrypto-4-x64.dll" (
    set "libcrypto=!script_dir!libcrypto-4-x64.dll"
) else if exist "!script_dir!libcrypto-3-x64.dll" (
    set "libcrypto=!script_dir!libcrypto-3-x64.dll"
) else if exist "C:\Program Files\OpenSSL-Win64\bin\libcrypto-4-x64.dll" (
    set "libcrypto=C:\Program Files\OpenSSL-Win64\bin\libcrypto-4-x64.dll"
) else if exist "C:\Program Files\OpenSSL-Win64\bin\libcrypto-3-x64.dll" (
    set "libcrypto=C:\Program Files\OpenSSL-Win64\bin\libcrypto-3-x64.dll"
)
if "!libcrypto!" == "" (
    echo 错误：未找到 libcrypto DLL（libcrypto-4-x64.dll 或 libcrypto-3-x64.dll）
    echo 请安装 OpenSSL-Win64：https://slproweb.com/products/Win32OpenSSL.html
    echo 或安装 Git for Windows（其 mingw64\bin 内含 libcrypto-3-x64.dll）
    echo 也可把对应 libcrypto DLL 复制到本脚本所在文件夹
    echo.
    pause
    endlocal & endlocal & exit /b 1
)

set "output_file=!param1_path:~0,-4!"
if "!output_file!" == "" (
    echo 错误：无法从文件名推导输出路径："!param1_path!"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
echo 输入文件："!param1_path!"
echo 输出文件："!output_file!"
echo.

if exist "!output_file!" (
    echo 输出文件已存在："!output_file!"
    echo 为避免覆盖原文件，已跳过。如需还原请先删除或移走该文件
    echo.
    pause
    endlocal & endlocal & exit /b 2
)

REM 文件末尾的 -----BEGIN CS ENGINE----- / -----END CS ENGINE----- 之间嵌有引擎
REM C# 源码（.codebuddy/tmp/AesGcmCli.cs）的原始代码；运行时由 powershell 读取自身文件并取出编译。
set "FILE_IN=!param1_path!"
set "FILE_OUT=!output_file!"
set "LIBCRYPTO=!libcrypto!"
set "self_path=%~f0"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$lines = Get-Content -LiteralPath $env:self_path -Encoding utf8;" ^
    "$bgn = '-----BEGIN CS ENGINE-----';" ^
    "$end = '-----END CS ENGINE-----';" ^
    "$s = -1;" ^
    "for ($i = 0; $i -lt $lines.Length; $i++) { if ($lines[$i] -eq $bgn) { $s = $i + 1; break } };" ^
    "if ($s -lt 1) { Write-Host '错误：未找到引擎数据块起始标记' -ForegroundColor Red; exit 30 };" ^
    "$e = -1;" ^
    "for ($i = $s; $i -lt $lines.Length; $i++) { if ($lines[$i] -eq $end) { $e = $i; break } };" ^
    "if ($e -lt 0) { Write-Host '错误：未找到引擎数据块结束标记' -ForegroundColor Red; exit 30 };" ^
    "$cs = ($lines[$s..($e - 1)] -join [Environment]::NewLine);" ^
    "Add-Type -TypeDefinition $cs -Language CSharp;" ^
    "$m = $null;" ^
    "$rc = [AesGcmCli]::LoadLib($env:LIBCRYPTO, [ref]$m);" ^
    "if ($rc -ne 0) { Write-Host ('libcrypto 加载失败：' + $m) -ForegroundColor Red; exit $rc };" ^
    "$s1 = Read-Host '请输入解密密码（输入时不显示）' -AsSecureString;" ^
    "$s2 = Read-Host '请再次输入相同密码确认' -AsSecureString;" ^
    "$a = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s1));" ^
    "$b = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s2));" ^
    "if ($a -cne $b) { Write-Host '两次输入的密码不一致，已取消' -ForegroundColor Red; exit 7 };" ^
    "if ([string]::IsNullOrEmpty($a)) { Write-Host '密码不能为空，已取消' -ForegroundColor Red; exit 7 };" ^
    "$pwd = [Text.Encoding]::UTF8.GetBytes($a);" ^
    "Write-Host '正在解密（PBKDF2 需数秒，请稍候）...' -ForegroundColor Yellow;" ^
    "$rc = [AesGcmCli]::DecryptFile($env:FILE_IN, $env:FILE_OUT, $pwd, [ref]$m);" ^
    "if ($rc -ne 0) { Write-Host ('解密失败：' + $m) -ForegroundColor Red; if (Test-Path $env:FILE_OUT) { Remove-Item $env:FILE_OUT -Force -ErrorAction SilentlyContinue }; exit $rc };" ^
    "Write-Host '解密完成' -ForegroundColor Green"
if !errorlevel! equ 0 (
    for %%f in ("!output_file!") do set "file_size=%%~zf"
    echo 解密成功："!output_file!"，大小：!file_size! 字节
) else (
    echo 解密失败，请查看上方错误信息
)

echo.
pause
endlocal & endlocal & exit /b

-----BEGIN CS ENGINE-----
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

    // return codes
    public const int OK = 0;
    public const int BAD_ARGS = 1;
    public const int OPEN_FAIL = 2;
    public const int BAD_FORMAT = 3;
    public const int AUTH_FAIL = 4;
    public const int CRYPTO_ERR = 5;
    public const int LIB_MISSING = 6;

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
                return OK;
            IntPtr h = LoadLibrary(libPath);
            if (h == IntPtr.Zero)
            {
                msg = "无法加载 " + libPath;
                return LIB_MISSING;
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
                return LIB_MISSING;
            }
            if (_initEx == null && _initEx2 == null)
            {
                msg = libPath + " 缺少 EVP_EncryptInit_ex / _ex2";
                return LIB_MISSING;
            }
            if (_decInitEx == null && _decInitEx2 == null)
            {
                msg = libPath + " 缺少 EVP_DecryptInit_ex / _ex2";
                return LIB_MISSING;
            }
            _libPath = libPath;
            return OK;
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
        if (pwd == null || pwd.Length == 0) { msg = "密码为空"; return BAD_ARGS; }
        if (iterations < MIN_ITER || iterations > MAX_ITER) { msg = "迭代次数非法"; return BAD_ARGS; }
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
            return OK;
        }
        catch (Exception ex) { msg = ex.Message; return CRYPTO_ERR; }
    }

    public static int DecryptFile(string inPath, string outPath, byte[] pwd, out string msg)
    {
        msg = null;
        if (pwd == null || pwd.Length == 0) { msg = "密码为空"; return BAD_ARGS; }
        string tmpOut = null;
        try
        {
            tmpOut = outPath + ".tmp";
            int code = OK;
            using (FileStream ins = new FileStream(inPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (FileStream outs = new FileStream(tmpOut, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                if (ins.Length < HDR_LEN) { msg = "文件太短，不是有效的加密文件"; return BAD_FORMAT; }
                byte[] hdr = new byte[HDR_LEN];
                ins.Read(hdr, 0, HDR_LEN);
                string magic = Encoding.ASCII.GetString(hdr, 0, 8);
                if (magic != "MYAESG01") { msg = "文件头不匹配，不是本工具加密的文件"; return BAD_FORMAT; }
                uint iterations = BitConverter.ToUInt32(hdr, 8);
                if (iterations < MIN_ITER || iterations > MAX_ITER) { msg = "文件中的迭代次数非法"; return BAD_FORMAT; }
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
                            code = AUTH_FAIL;
                        }
                        else if (fl > 0) { byte[] o = new byte[fl]; Marshal.Copy(op, o, 0, fl); outs.Write(o, 0, fl); }
                    }
                    finally { Marshal.FreeHGlobal(ip); Marshal.FreeHGlobal(op); }
                }
                finally { _ctxFree(ctx); }
            }

            if (code != OK)
            {
                File.Delete(tmpOut);
                return code;
            }
            if (File.Exists(outPath)) File.Delete(outPath);
            File.Move(tmpOut, outPath);
            return OK;
        }
        catch (Exception ex)
        {
            try { if (tmpOut != null && File.Exists(tmpOut)) File.Delete(tmpOut); } catch { }
            msg = ex.Message;
            return CRYPTO_ERR;
        }
    }
}
-----END CS ENGINE-----
