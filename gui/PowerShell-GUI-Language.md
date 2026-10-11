# Powershell 通过 WinForms 调用系统公共对话框，错误显示英文界面的问题

## 问题概述

Powershell 通过 WinForms 调用系统公共对话框，错误显示英文界面  

问题现象：  
在部分场景中，修改输出编码后，创建系统公共对话框，会在中文环境中，错误显示英文界面  
一旦显示英文界面，后续继续调用系统公共对话框，也只会显示英文界面  

影响范围：  
文件选择框 OpenFileDialog、文件夹选择框 FolderBrowserDialog、文件保存框 SaveFileDialog、颜色选择框 ColorDialog 等  

## 解决方案

检查项 1：  
确保在修改输出编码前，至少调用一次 `Get-Culture` 或 `Get-UICulture` 方法  

检查项 2：  
确保对以下特殊方法，使用 powershell 子进程隔离，避免污染主进程的语言信息：  
`Get-ChildItem`、`Get-CimInstance`、`Get-Content`、`Get-ItemProperty`、`Get-Location`  

## 测试环境

系统版本：Windows 11  
PowerShell 版本：5.1  
语言设置：中文  

使用以下代码检查语言设置，输出均为 `zh-CN`：  

```powershell
[System.Globalization.CultureInfo]::CurrentCulture.Name
[System.Globalization.CultureInfo]::CurrentUICulture.Name
[System.Globalization.CultureInfo]::InstalledUICulture.Name
[System.Threading.Thread]::CurrentThread.CurrentCulture.Name
[System.Threading.Thread]::CurrentThread.CurrentUICulture.Name
pause
```

## 测试用例

加载程序集的 2 种写法：  

```powershell
Add-Type -AssemblyName System.Windows.Forms
using assembly System.Windows.Forms
```

修改输出编码的 2 种写法：  

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001
```

创建文件选择框的 2 种写法：  
```powershell
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

### 正常场景：加载程序集 + 创建文件选择框 ✅

加载程序集 + 创建文件选择框，组合起来一共 4 种写法  
均正常显示中文界面：  

```powershell
Add-Type -AssemblyName System.Windows.Forms
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

```powershell
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
using assembly System.Windows.Forms
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

```powershell
using assembly System.Windows.Forms
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

### 异常场景 1：using assembly 加载程序集 + 修改输出编码 + New-Object 创建文件选择框 ❌

加载程序集 + 修改输出编码 + 创建文件选择框，组合起来一共 8 种写法  
以下 6 种写法会显示中文界面：

```powershell
Add-Type -AssemblyName System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

```powershell
Add-Type -AssemblyName System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
using assembly System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
Add-Type -AssemblyName System.Windows.Forms
chcp 65001
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

```powershell
Add-Type -AssemblyName System.Windows.Forms
chcp 65001
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
using assembly System.Windows.Forms
chcp 65001
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

以下 2 种写法会显示英文界面：

```powershell
using assembly System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

```powershell
using assembly System.Windows.Forms
chcp 65001
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

### 异常场景 1 修复方案：增加 Get-Culture 或 Get-UICulture ✅

在异常场景 1 的修改输出编码的代码前，调用 `Get-Culture` 或 `Get-UICulture`，即可修复：  

```powershell
using assembly System.Windows.Forms
Get-Culture
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

```powershell
using assembly System.Windows.Forms
Get-Culture
chcp 65001
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

```powershell
using assembly System.Windows.Forms
Get-UICulture
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

```powershell
using assembly System.Windows.Forms
Get-UICulture
chcp 65001
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

### 异常场景 2：using assembly 加载程序集 + 修改输出编码 + 调用特殊方法 + new 创建文件选择框 ❌

此场景的特殊方法包含 `Write-Output`、`Write-Host` 等  
以下代码都显示英文界面：  

```powershell
using assembly System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output 'Test'
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
using assembly System.Windows.Forms
chcp 65001
Write-Output 'Test'
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
using assembly System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host 'Test'
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
using assembly System.Windows.Forms
chcp 65001
Write-Host 'Test'
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

### 异常场景 2 修复方案：增加 Get-Culture 或 Get-UICulture ✅

在异常场景 2 的修改输出编码的代码前，调用 `Get-Culture` 或 `Get-UICulture`，即可修复：  

```powershell
using assembly System.Windows.Forms
Get-Culture
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output 'Test'
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
using assembly System.Windows.Forms
Get-UICulture
chcp 65001
Write-Output 'Test'
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
using assembly System.Windows.Forms
Get-UICulture
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host 'Test'
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
using assembly System.Windows.Forms
Get-Culture
chcp 65001
Write-Host 'Test'
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

### 异常场景 3：加载程序集 + 修改输出编码 + 调用特殊方法 + 创建文件选择框 ❌

此场景的特殊方法包含 `Get-ChildItem`、`Get-CimInstance`、`Get-Content`、`Get-ItemProperty`、`Get-Location` 等  
以下代码都显示英文界面：  

```powershell
Add-Type -AssemblyName System.Windows.Forms
Get-Culture
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Get-ChildItem -Path '.' -Filter '*.*' -File
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

```powershell
using assembly System.Windows.Forms
Get-UICulture
chcp 65001
Get-CimInstance Win32_OperatingSystem
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
Add-Type -AssemblyName System.Windows.Forms
Get-Culture
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Get-Content -LiteralPath "$PSCommandPath" -Raw
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

```powershell
using assembly System.Windows.Forms
Get-UICulture
chcp 65001
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
Add-Type -AssemblyName System.Windows.Forms
Get-Culture
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Get-Location
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

### 异常场景 3 修复方案：使用 powershell 子进程隔离 ✅

将此场景的特殊方法，使用 powershell 子进程隔离，即可修复：  

```powershell
Add-Type -AssemblyName System.Windows.Forms
Get-Culture
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$fileItems = powershell -NoProfile -Command '@(Get-ChildItem -Path "." -Filter "*.bat" -File)'
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

```powershell
using assembly System.Windows.Forms
Get-UICulture
chcp 65001
$osInfo = powershell -NoProfile -Command 'Get-CimInstance Win32_OperatingSystem'
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
Add-Type -AssemblyName System.Windows.Forms
Get-Culture
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$content = powershell -NoProfile -Command 'Get-Content -LiteralPath "$PSCommandPath" -Raw'
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```

```powershell
using assembly System.Windows.Forms
Get-UICulture
chcp 65001
$currentVersion = powershell -NoProfile -Command 'Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"'
[System.Windows.Forms.OpenFileDialog]::new().ShowDialog()
```

```powershell
Add-Type -AssemblyName System.Windows.Forms
Get-Culture
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$callDirectory = powershell -NoProfile -Command '(Get-Location).Path'
(New-Object System.Windows.Forms.OpenFileDialog).ShowDialog()
```
