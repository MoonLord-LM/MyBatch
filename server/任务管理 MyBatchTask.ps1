# MyBatchTask 批处理任务管理器
#
# 开源地址: https://github.com/MoonLord-LM/MyBatch
#
# 功能：
#     集中管理多个命令行后台任务（如 cloudflared、frpc、openlist 等）
#     以隐藏窗口方式启动，避免每个任务都占用一个黑色控制台窗口
#     启动后默认最小化到桌面右下角托盘图标
#     通过界面的表格，管理任务的启动、停止、重启、新增、修改、删除，并记录每个任务的输出内容到日志文件中
#
# 目录说明：
#     配置文件：脚本同目录下的 \MyBatchTask\config.json，首次运行自动创建示例配置
#     示例配置:
#     [
#         {
#             "name": "Ping Test",
#             "command": "%SystemRoot%\\System32\\cmd.exe",
#             "arguments": "/c \"chcp 65001 >nul && ping github.com\"",
#             "workingDirectory": "%SystemRoot%\\System32",
#             "autoStart": true
#         }
#     ]
#     日志目录：脚本同目录下的 \MyBatchTask\logs 目录，按任务名自动创建对应的 [任务名称.log] 文件
#
# 配置文件说明：
#     name 任务名称（唯一）
#     command 命令或脚本路径
#     arguments 参数
#     workingDirectory 工作目录（默认为脚本目录）
#     autoStart 管理器启动时自动运行（默认 true）
#     command / arguments / workingDirectory 三个字段都支持 %SystemRoot% 这类环境变量，运行时自动展开
#
# 运行方式：
#     powershell -NoProfile -ExecutionPolicy Bypass -File "任务管理 MyBatchTask.ps1"
#
# 代码结构：
#     1: 通用基础设置
#     2: 程序全局设置
#     3: 功能实现
#     4: 窗体界面绘制
#     5: 程序启动



# ———————————————————————————————— 1: 通用基础设置 ————————————————————————————————

# 异常处理
function Handle-Exception {
    param([Parameter(Mandatory=$true)][System.Management.Automation.ErrorRecord]$ErrorRecord)
    ""
    "[ Error ] Message: $($ErrorRecord.Exception.Message)"
    if ($ErrorRecord.InvocationInfo) {
        "[ Error ] Line: $($ErrorRecord.InvocationInfo.ScriptLineNumber)"
        if ($ErrorRecord.InvocationInfo.Line) {
            "[ Error ] Code: $($ErrorRecord.InvocationInfo.Line.Trim())"
        }
    }
    ""
}

try {
    # 设置字符编码 UTF-8
    $defaultOutputEncoding = [System.Console]::OutputEncoding.EncodingName
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $currentOutputEncoding = [System.Console]::OutputEncoding.EncodingName
    $workingEncoding = New-Object System.Text.UTF8Encoding($false)
    "[ Debug ] defaultOutputEncoding = $defaultOutputEncoding"
    "[ Debug ] currentOutputEncoding = $currentOutputEncoding"
    "[ Debug ] workingEncoding = $workingEncoding"

    # 获取环境信息，使用单独进程隔离 Get-CimInstance 对语言的影响
    $windowsVersion = powershell -NoProfile -Command {
        $windowsOSInfo = Get-CimInstance Win32_OperatingSystem
        $windowsCurrentVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $windowsVersion = "$($windowsOSInfo.Caption) $($windowsCurrentVersion.DisplayVersion)"
        return $windowsVersion
    }
    $powerShellVersion = "$($PSVersionTable.PSVersion.ToString()) $($PSVersionTable.PSEdition)"
    $machineName = [System.Net.Dns]::GetHostName()
    $userName = [Environment]::UserName
    "[ Debug ] windowsVersion = $windowsVersion"
    "[ Debug ] powerShellVersion = $powerShellVersion"
    "[ Debug ] machineName = $machineName"
    "[ Debug ] userName = $userName"

    # 加载 Win32 API 函数
    $Win32APICode =
@'
    using System;
    using System.Runtime.InteropServices;
    public static class DpiHelper {
        [DllImport("user32.dll")]
        public static extern bool SetProcessDPIAware();
        [DllImport("user32.dll")]
        public static extern bool SetProcessDpiAwarenessContext(IntPtr value);
    }
    public static class DpiContext {
        public static readonly IntPtr UNAWARE = (IntPtr)(-1);
        public static readonly IntPtr SYSTEM_AWARE = (IntPtr)(-2);
        public static readonly IntPtr PER_MONITOR_AWARE = (IntPtr)(-3);
        public static readonly IntPtr PER_MONITOR_AWARE_V2 = (IntPtr)(-4);
    }
'@
    Add-Type -TypeDefinition $Win32APICode

    # 禁用自动缩放
    $result = $false
    try {
        $result = [DpiHelper]::SetProcessDpiAwarenessContext([DpiContext]::PER_MONITOR_AWARE_V2)
    } catch { }
    if(-not $result){
        $result = [DpiHelper]::SetProcessDPIAware()
    }

    # 设置更现代的窗口样式
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

    # 对指定的控件启用双缓冲，减少界面闪烁
    function Enable-Double-Buffered {
        param([Parameter(Mandatory=$true)][System.Windows.Forms.Control]$Control)

        $doubleBufferedBindingFlags = [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance
        $doubleBufferedProperty = [System.Windows.Forms.Control].GetProperty("DoubleBuffered", $doubleBufferedBindingFlags)
        $doubleBufferedProperty.SetValue($Control, $true)
        return $doubleBufferedProperty.GetValue($Control)
    }

    # 分析合适的显示语言
    $currentCulture = [System.Globalization.CultureInfo]::CurrentCulture.Name
    $currentUICulture = [System.Globalization.CultureInfo]::CurrentUICulture.Name
    $installedUICulture = [System.Globalization.CultureInfo]::InstalledUICulture.Name
    $currentThreadCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture.Name
    $currentThreadUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture.Name
    $workingLanguage = 'en-US'
    $zhCNCount = 0
    $enUSCount = 0
    if ($currentCulture -eq 'zh-CN') { $zhCNCount += 1 } else { $enUSCount += 1 }
    if ($currentUICulture -eq 'zh-CN') { $zhCNCount += 1 } else { $enUSCount += 1 }
    if ($installedUICulture -eq 'zh-CN') { $zhCNCount += 1 } else { $enUSCount += 1 }
    if ($currentThreadCulture -eq 'zh-CN') { $zhCNCount += 1 } else { $enUSCount += 1 }
    if ($currentThreadUICulture -eq 'zh-CN') { $zhCNCount += 1 } else { $enUSCount += 1 }
    if ($zhCNCount -ge $enUSCount) {
        $workingLanguage = 'zh-CN'
    } else {
        $workingLanguage = 'en-US'
    }
    "[ Debug ] currentCulture = $currentCulture"
    "[ Debug ] currentUICulture = $currentUICulture"
    "[ Debug ] installedUICulture = $installedUICulture"
    "[ Debug ] currentThreadCulture = $currentThreadCulture"
    "[ Debug ] currentThreadUICulture = $currentThreadUICulture"
    "[ Debug ] workingLanguage = $workingLanguage"

    # 分析合适的工作目录
    $currentDirectory = [System.IO.Directory]::GetCurrentDirectory()
    $callDirectory = (Get-Location).Path
    $scriptDirectory = $PSScriptRoot
    $systemDirectory = [System.Environment]::SystemDirectory
    $userDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
    $tempDirectory = [System.IO.Path]::GetTempPath()
    $workingDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
    foreach ($dir in @($currentDirectory, $callDirectory, $scriptDirectory)) {
        if ($dir) {
            if ($dir -ine $systemDirectory) {
                if ($dir -ine $userDirectory) {
                    if ($dir -ine $tempDirectory) {
                        $workingDirectory = $dir
                        break
                    }
                }
            }
        }
    }
    "[ Debug ] currentDirectory = $currentDirectory"
    "[ Debug ] callDirectory = $callDirectory"
    "[ Debug ] scriptDirectory = $scriptDirectory"
    "[ Debug ] systemDirectory = $systemDirectory"
    "[ Debug ] userDirectory = $userDirectory"
    "[ Debug ] tempDirectory = $tempDirectory"
    "[ Debug ] workingDirectory = $workingDirectory"
} catch {
    Handle-Exception $_
    pause
    exit 1
}



# ———————————————————————————————— 2: 程序全局设置 ————————————————————————————————

try {
    # 数据目录：/MyBatchTask
    $myBatchTaskDir = [System.IO.Path]::Combine($workingDirectory, "MyBatchTask")
    if (-not [System.IO.Directory]::Exists($myBatchTaskDir)) {
        [System.IO.Directory]::CreateDirectory($myBatchTaskDir) | Out-Null
    }

    # 日志目录：/MyBatchTask/logs
    $myBatchTaskLogsDir = [System.IO.Path]::Combine($myBatchTaskDir, "logs")
    if (-not [System.IO.Directory]::Exists($myBatchTaskLogsDir)) {
        [System.IO.Directory]::CreateDirectory($myBatchTaskLogsDir) | Out-Null
    }

    # 系统日志：/MyBatchTask/logs
    $myBatchTaskSystemLogFile = [System.IO.Path]::Combine($myBatchTaskLogsDir, "system.log")
    if (-not [System.IO.File]::Exists($myBatchTaskSystemLogFile)) {
        [System.IO.File]::WriteAllText($myBatchTaskSystemLogFile, "", $workingEncoding)
    }

    # 配置文件：/MyBatchTask/config.json
    $myBatchTaskConfigFile = [System.IO.Path]::Combine($myBatchTaskDir, "config.json")
    $defaultJsonConfig = @{
        'zh-CN' =
@'
[
    {
        "name": "Ping 测试",
        "command": "%SystemRoot%\\System32\\cmd.exe",
        "arguments": "/c \"chcp 65001 >nul && ping github.com\"",
        "workingDirectory": "%SystemRoot%\\System32",
        "autoStart": true
    }
]
'@
        'en-US' =
@'
[
    {
        "name": "Ping Test",
        "command": "%SystemRoot%\\System32\\cmd.exe",
        "arguments": "/c \"chcp 65001 >nul && ping github.com\"",
        "workingDirectory": "%SystemRoot%\\System32",
        "autoStart": true
    }
]
'@
    }
    if (-not [System.IO.File]::Exists($myBatchTaskConfigFile)) {
        [System.IO.File]::WriteAllText($myBatchTaskConfigFile, $defaultJsonConfig[$workingLanguage], $workingEncoding)
    }

    # 界面文本，包含中文和英文
    $uiTextResources = @{
        'zh-CN' = @{
            FormTitle = "MyBatchTask 批处理任务管理器"
            ColumnStatus = "状态"
            ColumnPid = "PID"
            ColumnName = "任务名称"
            ColumnCommand = "命令"
            ColumnArguments = "参数"
            ColumnWorkingDir = "工作目录"
            TabTaskList = "任务列表"
            TabRunLog = "系统日志"
            AddButton = "新增"
            EditButton = "修改"
            DeleteButton = "删除"
            StartButton = "启动"
            StopButton = "停止"
            RestartButton = "重启"
            StartAllButton = "全部启动"
            StopAllButton = "全部停止"
            ViewLogButton = "查看日志"
            OpenLogsButton = "打开日志目录"
            TrayShow = "显示主界面"
            TrayStartAll = "全部启动"
            TrayStopAll = "全部停止"
            TrayExit = "退出"
            MenuAdd = "新增任务"
            MenuStart = "启动"
            MenuStop = "停止"
            MenuRestart = "重启"
            MenuViewLog = "查看日志"
            MenuEdit = "修改任务"
            MenuDelete = "删除任务"
            MenuStartAll = "全部启动"
            MenuStopAll = "全部停止"
            StatusRunning = "运行中"
            StatusStopped = "已停止"
            StatusExited = "已退出"
            StatusExitedError = "异常退出"
            StatusStarting = "启动中"
            LogCopy = "复制日志"
            LogClear = "清空日志"
            LogOpenFile = "打开日志文件"
            LogViewerTitle = "任务日志 - {0}"
            ConfirmTitle = "确认"
            ConfirmDelete = "确定删除任务「{0}」吗？"
            ConfirmExit = "退出将停止所有运行中的任务，是否继续？"
            ConfirmRestart = "任务「{0}」正在运行，修改后将自动重启，是否继续？"
            ERROR_CommandEmpty = "命令不能为空"
            ERROR_CommandNotFound = "命令文件不存在: {0}"
            ERROR_NameEmpty = "任务名称不能为空"
            ERROR_NameDuplicated = "任务名称已存在: {0}"
            ERROR_WorkDirNotFound = "工作目录不存在: {0}"
            ERROR_NoSelection = "请先在列表中选择一个任务"
            ERROR_TaskStartFailed = "任务启动失败: {0}"
            INFO_Started = "任务已启动: {0} (PID {1})"
            INFO_Stopped = "任务已停止: {0}"
            INFO_Exited = "任务已退出: {0} (退出码 {1})"
            INFO_AlreadyRunning = "任务已在运行中: {0}"
            INFO_Deleted = "任务已删除: {0}"
            INFO_Saved = "配置已保存到 {0}"
            INFO_ConfigLoaded = "已加载 {0} 个任务"
            INFO_ConfigLoadFailed = "配置文件加载失败: {0}"
            INFO_ConfigNotFound = "未找到配置文件: {0}"
            INFO_NameRenamed = "任务名称「{0}」重复，已自动重命名为「{1}」"
            INFO_StartAllDone = "已启动全部任务"
            INFO_StopAllDone = "已停止全部任务"
            INFO_LogCopied = "日志已复制到剪贴板"
            INFO_NoLog = "当前没有日志内容"
            INFO_TrayHint = "程序已最小化到托盘图标，双击托盘图标可重新打开界面"
            INFO_SystemInfo = "配置文件: [ {0} ]"
            DialogAddTitle = "新增任务"
            DialogEditTitle = "修改任务"
            DialogName = "任务名称:"
            DialogCommand = "命令:"
            DialogArguments = "参数:"
            DialogWorkingDir = "工作目录:"
            DialogAutoStart = "管理器启动时自动运行"
            DialogBrowseCommand = "选择命令"
            DialogBrowseDir = "选择目录"
            DialogBrowseCommandTitle = "选择命令文件"
            DialogBrowseDirTitle = "选择工作目录"
            DialogExeFilter = "可执行文件 (*.exe;*.bat;*.cmd;*.ps1;*.py)|*.exe;*.bat;*.cmd;*.ps1;*.py|所有文件 (*.*)|*.*"
            DialogOk = "确定"
            DialogCancel = "取消"
            FileFilterLog = "日志文件 (*.log)|*.log|所有文件 (*.*)|*.*"
            CloseTab = "关闭标签页"
            LogProcessHeader = "[{0}] ———————————— 开始新进程 ————————————————"
            LogProcessFooter = "[{0}] ———————————— 结束进程，退出码 {1} ————————————————"
        }
        'en-US' = @{
            FormTitle = "MyBatchTask Batch Task Manager"
            ColumnStatus = "Status"
            ColumnPid = "PID"
            ColumnName = "Task Name"
            ColumnCommand = "Command"
            ColumnArguments = "Arguments"
            ColumnWorkingDir = "Working Directory"
            TabTaskList = "Task List"
            TabRunLog = "System Log"
            AddButton = "Add"
            EditButton = "Edit"
            DeleteButton = "Delete"
            StartButton = "Start"
            StopButton = "Stop"
            RestartButton = "Restart"
            StartAllButton = "Start All"
            StopAllButton = "Stop All"
            ViewLogButton = "View Log"
            OpenLogsButton = "Open Logs Folder"
            TrayShow = "Show Main Window"
            TrayStartAll = "Start All"
            TrayStopAll = "Stop All"
            TrayExit = "Exit"
            MenuAdd = "Add Task"
            MenuStart = "Start"
            MenuStop = "Stop"
            MenuRestart = "Restart"
            MenuViewLog = "View Log"
            MenuEdit = "Edit Task"
            MenuDelete = "Delete Task"
            MenuStartAll = "Start All"
            MenuStopAll = "Stop All"
            StatusRunning = "Running"
            StatusStopped = "Stopped"
            StatusExited = "Exited"
            StatusExitedError = "Abnormal Exit"
            StatusStarting = "Starting"
            LogCopy = "Copy Log"
            LogClear = "Clear Log"
            LogOpenFile = "Open Log File"
            LogViewerTitle = "Task Log - {0}"
            ConfirmTitle = "Confirm"
            ConfirmDelete = "Delete task '{0}'?"
            ConfirmExit = "Exit will stop all running tasks. Continue?"
            ConfirmRestart = "Task '{0}' is running and will be restarted after editing. Continue?"
            ERROR_CommandEmpty = "Command must not be empty"
            ERROR_CommandNotFound = "Command file not found: {0}"
            ERROR_NameEmpty = "Task name must not be empty"
            ERROR_NameDuplicated = "Task name already exists: {0}"
            ERROR_WorkDirNotFound = "Working directory not found: {0}"
            ERROR_NoSelection = "Please select a task from the list first"
            ERROR_TaskStartFailed = "Failed to start task: {0}"
            INFO_Started = "Task started: {0} (PID {1})"
            INFO_Stopped = "Task stopped: {0}"
            INFO_Exited = "Task exited: {0} (exit code {1})"
            INFO_AlreadyRunning = "Task is already running: {0}"
            INFO_Deleted = "Task deleted: {0}"
            INFO_Saved = "Configuration saved to {0}"
            INFO_ConfigLoaded = "Loaded {0} task(s)"
            INFO_ConfigLoadFailed = "Failed to load configuration file: {0}"
            INFO_ConfigNotFound = "Configuration file not found: {0}"
            INFO_NameRenamed = "Task name '{0}' is duplicated and has been renamed to '{1}'"
            INFO_StartAllDone = "All tasks started"
            INFO_StopAllDone = "All tasks stopped"
            INFO_LogCopied = "Log copied to clipboard"
            INFO_NoLog = "No log content"
            INFO_TrayHint = "The program is minimized to the tray icon. Double-click the tray icon to reopen the window."
            INFO_SystemInfo = "Config file: [ {0} ]"
            DialogAddTitle = "Add Task"
            DialogEditTitle = "Edit Task"
            DialogName = "Task Name:"
            DialogCommand = "Command:"
            DialogArguments = "Arguments:"
            DialogWorkingDir = "Working Directory:"
            DialogAutoStart = "Auto start when the manager starts"
            DialogBrowseCommand = "Browse"
            DialogBrowseDir = "Browse"
            DialogBrowseCommandTitle = "Select Command File"
            DialogBrowseDirTitle = "Select Working Directory"
            DialogExeFilter = "Executable files (*.exe;*.bat;*.cmd;*.ps1;*.py)|*.exe;*.bat;*.cmd;*.ps1;*.py|All files (*.*)|*.*"
            DialogOk = "OK"
            DialogCancel = "Cancel"
            FileFilterLog = "Log files (*.log)|*.log|All files (*.*)|*.*"
            CloseTab = "Close Tab"
            LogProcessHeader = "[{0}] ———————————— Start new process ————————————————"
            LogProcessFooter = "[{0}] ———————————— End process, exit code {1} ————————————————"
        }
    }
    $ui = $uiTextResources[$workingLanguage]
    if (-not $ui) { $ui = $uiTextResources['zh-CN'] }

    # 界面字体，统一用微软雅黑
    $uiFont = [System.Drawing.Font]::new("Microsoft YaHei", 10)

    # 后台线程输出的异步日志队列
    $script:outputQueue = [System.Collections.Concurrent.ConcurrentQueue[hashtable]]::new()
    # 是否真正退出程序（区分「隐藏到托盘」和「关闭程序」）
    $script:realExit = $false
    # 标签栏右键点击的标签页
    $script:rightClickedTab = $null
} catch {
    Handle-Exception $_
    pause
    exit 1
}



# ———————————————————————————————— 3: 功能实现 ————————————————————————————————

try {
    # 记录系统日志
    # 使用 System-Log 函数：首先记录到文件 $myBatchTaskSystemLogFile 中，再尝试展示到 $systemLogTextBox 中
    $systemLogFileLock = [object]::new()
    $systemLogTextBox = $null
    $systemLogColorMap = @{
        Info     = [System.Drawing.Color]::Black
        Success  = [System.Drawing.Color]::Green
        Warning  = [System.Drawing.Color]::DarkOrange
        Error    = [System.Drawing.Color]::Red
        Progress = [System.Drawing.Color]::Blue
        Debug    = [System.Drawing.Color]::Gray
    }
    function System-Log-Internal {
        param($txtBox, $text, $color)

        try {
            if ($null -eq $txtBox -or $txtBox.IsDisposed) {
                return
            }
            $txtBox.SuspendLayout()
            try {
                $txtBox.SelectionStart = $txtBox.TextLength
                $txtBox.SelectionLength = 0
                $txtBox.SelectionColor = $color
                $txtBox.AppendText($text)
                $txtBox.ScrollToCaret()
            }
            finally {
                $txtBox.ResumeLayout()
            }
        } catch {
            Handle-Exception $_
        }
    }
    $systemLogInternalAction = [Action[System.Windows.Forms.RichTextBox, string, System.Drawing.Color]]{
        param($txtBox, $text, $color)

        System-Log-Internal $txtBox $text $color
    }
    function System-Log {
        param([string]$Message = '', [string]$Level = 'Info')

        $logLine = "[{0}] {1}`r`n" -f $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
        try {
            $lockTaken = $false
            try {
                [System.Threading.Monitor]::Enter($systemLogFileLock, [ref]$lockTaken)
                [System.IO.File]::AppendAllText($myBatchTaskSystemLogFile, $logLine, $workingEncoding)
            } finally {
                if ($lockTaken) {
                    [System.Threading.Monitor]::Exit($systemLogFileLock)
                }
            }
        } catch {
            Handle-Exception $_
        }

        if ($null -eq $systemLogTextBox -or $systemLogTextBox.IsDisposed) {
            return
        }

        $logColor = if ($systemLogColorMap.ContainsKey($Level)) {
            $systemLogColorMap[$Level]
        } else {
            [System.Drawing.Color]::Black
        }

        if ($systemLogTextBox.IsHandleCreated -and $systemLogTextBox.InvokeRequired) {
            try {
                $systemLogTextBox.BeginInvoke($systemLogInternalAction, $systemLogTextBox, $logLine, $logColor) | Out-Null
            } catch {
                Handle-Exception $_
            }
            return
        }
        System-Log-Internal $systemLogTextBox $logLine $logColor
    }

    # 任务配置列表
    # 有序数组，元素为 PSCustomObject，字段：name，command，arguments，workingDirectory，autoStart
    $tasks = @()

    # 保存任务列表到配置文件
    function Save-Config {
        $objects = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($task in $script:tasks) {
            $autoStart = $true
            if ($task.PSObject.Properties.Match('autoStart').Count -gt 0 -and $null -ne $task.autoStart) {
                $autoStart = [bool]$task.autoStart
            }

            $workingDirectoryConfig = Split-Path -Path ([string]$task.command) -Parent
            if ($task.PSObject.Properties.Match('workingDirectory').Count -gt 0 -and $task.workingDirectory) {
                $workingDirectoryConfig = [string]$task.workingDirectory
            }

            $objects.Add([PSCustomObject]@{
                name = [string]$task.name
                command = [string]$task.command
                arguments = [string]$task.arguments
                workingDirectory = $workingDirectoryConfig
                autoStart = $autoStart
            })
        }
        $json = ConvertTo-Json -InputObject @($objects) -Depth 100
        [System.IO.File]::WriteAllText($myBatchTaskConfigFile, $json, $workingEncoding)
        System-Log ($ui.INFO_Saved -f $myBatchTaskConfigFile) "Debug"
    }

    # 从配置文件加载任务列表
    function Load-Config {
        if (-not [System.IO.File]::Exists($myBatchTaskConfigFile)) {
            System-Log ($ui.INFO_ConfigNotFound -f $myBatchTaskConfigFile) "Warning"
            return $false
        }

        try {
            $config = Get-Content -Path $myBatchTaskConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $configItems = @($config)
            $script:tasks = @()
            $seenNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($item in $configItems) {
                if ($item -isnot [PSCustomObject]) { continue; }
                if ($item.PSObject.Properties.Match('name').Count -eq 0) { continue; }
                if ($item.PSObject.Properties.Match('command').Count -eq 0) { continue; }
                if (-not $item.name -or -not $item.command) { continue; }

                # 配置任务重名时，自动重命名：原任务名 + 数字
                $taskName = [string]$item.name
                if ($seenNames.Contains($taskName)) {
                    $baseName = $taskName
                    $nameSuffix = 2
                    while ($seenNames.Contains($baseName + $nameSuffix)) {
                        $nameSuffix += 1
                    }
                    $taskName = $baseName + $nameSuffix
                    $item.name = $taskName
                    System-Log ($ui.INFO_NameRenamed -f $baseName, $taskName) "Warning"
                }
                $seenNames.Add($taskName) | Out-Null
                $script:tasks += $item
            }
            Update-Task-Grid
        } catch {
            System-Log ($ui.INFO_ConfigLoadFailed -f $_.Exception.Message) "Error"
            return $false
        }
        System-Log ($ui.INFO_ConfigLoaded -f $script:tasks.Count) "Success"
        return $true
    }

    # 任务运行实例列表
    # 任务名 → @{ Process; Status; ExitCode; LogBuilder; Writer; ViewerBox }
    $executions = @{}

    # 任务列表表格
    $taskGridView = $null

    # 刷新界面展示的任务列表表格
    function Update-Task-Grid {
        if ($null -eq $taskGridView -or $taskGridView.IsDisposed) {
            return
        }

        $taskGridView.SuspendLayout()
        try {
            $taskGridView.Rows.Clear()
            for ($i = 0; $i -lt $tasks.Count; $i++) {
                $task = $tasks[$i]
                $taskName = $task.name

                $statusText = $ui.StatusStopped
                $pidText = ""
                if ($executions.ContainsKey([string]$taskName)) {
                    $execution = $executions[[string]$taskName]
                    if ($execution.Status) {
                        $statusText = $execution.Status
                    }
                    if ($execution.Process -and -not $execution.Process.HasExited) {
                        $pidText = [string]$execution.Process.Id
                    }
                }

                $taskGridView.Rows.Add($statusText, $pidText, [string]$task.name, [string]$task.command, [string]$task.arguments, [string]$task.workingDirectory) | Out-Null
            }
        }
        finally {
            $taskGridView.ResumeLayout()
        }
    }

    # 刷新界面展示的任务列表表格的指定行
    function Update-Task-Row {
        param([int]$Index)

        if ($Index -lt 0 -or $Index -ge $taskGridView.Rows.Count) {
            return
        }

        $task = $tasks[$Index]
        $taskName = $task.name

        $statusText = $ui.StatusStopped
        $pidText = ""
        if ($executions.ContainsKey([string]$taskName)) {
            $execution = $executions[[string]$taskName]
            if ($execution.Status) {
                $statusText = $execution.Status
            }
            if ($execution.Process -and -not $execution.Process.HasExited) {
                $pidText = [string]$execution.Process.Id
            }
        }

        $taskGridView.Rows[$Index].Cells[0].Value = $statusText
        $taskGridView.Rows[$Index].Cells[1].Value = $pidText
    }

    # 获取任务列表当前选中的行，对应的任务序号
    function Get-Selected-Task-Index {
        if ($taskGridView.SelectedRows.Count -eq 0) { return -1 }
        return $taskGridView.SelectedRows[0].Index
    }

    # 获取任务列表当前选中的行，对应的任务配置
    function Get-Selected-Task {
        $index = Get-Selected-Task-Index
        if ($index -lt 0 -or $index -ge $tasks.Count) { return $null }
        return $tasks[$index]
    }

    # 任务输出收集
    # 每个任务的输出读取线程使用独立的 Runspace 池（启动时创建，停止时关闭）
    # 停止并释放任务的输出读取线程
    function Stop-Task-Readers {
        param($execution)
        if ($null -eq $execution) { return }
        foreach ($item in @($execution.StandardOutputReader, $execution.StandardErrorReader)) {
            if ($null -eq $item) { continue }
            try {
                $item.Stop()
                $item.Dispose()
            } catch {}
        }
        $execution.StandardOutputReader = $null
        $execution.StandardErrorReader = $null
        if ($execution.RunspacePool) {
            try { $execution.RunspacePool.Close() } catch {}
            try { $execution.RunspacePool.Dispose() } catch {}
            $execution.RunspacePool = $null
        }
    }
    # 获取任务日志文件的写入器（懒创建，追加模式 UTF-8 无 BOM）
    function Get-Task-Writer {
        param([string]$TaskName)
        $execution = $script:executions[$TaskName]
        if ($execution.Writer -and -not $execution.Writer.BaseStream.CanWrite) {
            $execution.Writer = $null
        }
        if ($null -eq $execution.Writer) {
            $safeName = ($TaskName -replace '[:/\\|?*<>" ]', '_')
            $logFilePath = [System.IO.Path]::Combine($myBatchTaskLogsDir, $safeName + ".log")
            # 允许其他程序以共享读取方式打开日志文件（如记事本实时查看）
            $fileStream = [System.IO.File]::Open($logFilePath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
            $streamWriter = [System.IO.StreamWriter]::new($fileStream, $workingEncoding)
            $streamWriter.AutoFlush = $true
            $execution.Writer = $streamWriter
            $execution.LogFile = $logFilePath
        }
        return $execution.Writer
    }
    # 追加一条任务输出（内存缓冲 + 日志文件 + 日志窗口）
    function Append-Task-Output {
        param([string]$TaskName, [string]$Line, [bool]$IsError)
        if (-not $script:executions.ContainsKey($TaskName)) { return }
        $execution = $script:executions[$TaskName]
        $logLine = "[{0}] {1}" -f $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Line
        # 内存缓冲，超过 256KB 时丢弃前一半，避免无限增长
        $execution.LogBuilder.AppendLine($logLine) | Out-Null
        if ($execution.LogBuilder.Length -gt 262144) {
            # 裁剪终点对齐到下一个换行符，只删除完整行；避免按 UTF-16 代码单元硬切
            # 时落在代理对（emoji、生僻字等）中间，导致缓冲区开头出现乱码。
            # 注：StringBuilder 在 .NET Framework 下没有 IndexOf，故先用 ToString() 快照查找
            $trimLength = 131072
            $nlIndex = $execution.LogBuilder.ToString().IndexOf("`n", $trimLength)
            if ($nlIndex -ge 0) {
                $trimLength = $nlIndex + 1  # 连同换行符一起删除，不残留孤立 \r
            } else {
                $trimLength = $execution.LogBuilder.Length
            }
            $execution.LogBuilder.Remove(0, $trimLength) | Out-Null
        }
        # 日志文件
        try {
            $writer = Get-Task-Writer -TaskName $TaskName
            $writer.WriteLine($logLine)
        } catch {}
        # 任务日志标签页
        if ($execution.ViewerBox -and -not $execution.ViewerBox.IsDisposed) {
            $execution.ViewerBox.SelectionStart = $execution.ViewerBox.TextLength
            $execution.ViewerBox.SelectionLength = 0
            $execution.ViewerBox.SelectionFont = $execution.ViewerBox.Font
            $lineColor = if ($IsError) { [System.Drawing.Color]::FromArgb(180, 40, 40) } else { [System.Drawing.Color]::Black }
            $execution.ViewerBox.SelectionColor = $lineColor
            $execution.ViewerBox.AppendText($logLine + "`r`n")
            $execution.ViewerBox.ScrollToCaret()
        }
    }
    # 追加一条任务进程标记（开始/结束标记行，与普通输出行统一的时间戳前缀；同步到内存缓冲 + 日志文件 + 日志标签页）
    function Append-Task-Meta {
        param([string]$TaskName, [string]$Line)
        if (-not $script:executions.ContainsKey($TaskName)) { return }
        $execution = $script:executions[$TaskName]
        # 内存缓冲
        $execution.LogBuilder.AppendLine($Line) | Out-Null
        # 日志文件
        try {
            $writer = Get-Task-Writer -TaskName $TaskName
            $writer.WriteLine($Line)
        } catch {}
        # 任务日志标签页
        if ($execution.ViewerBox -and -not $execution.ViewerBox.IsDisposed) {
            $execution.ViewerBox.SelectionStart = $execution.ViewerBox.TextLength
            $execution.ViewerBox.SelectionLength = 0
            $execution.ViewerBox.SelectionFont = $execution.ViewerBox.Font
            $execution.ViewerBox.SelectionColor = [System.Drawing.Color]::Black
            $execution.ViewerBox.AppendText($Line + "`r`n")
            $execution.ViewerBox.ScrollToCaret()
        }
    }
    # 记录任务结束标记（结束时间 + 退出码），随后补两个空行，与下一轮执行的日志分隔
    function Write-Task-Exit-Log {
        param([string]$TaskName)
        if (-not $script:executions.ContainsKey($TaskName)) { return }
        $execution = $script:executions[$TaskName]
        $exitCode = $execution.ExitCode
        if ($null -eq $exitCode -and $execution.Process -and $execution.Process.HasExited) {
            $exitCode = $execution.Process.ExitCode
        }
        $exitCodeText = if ($null -eq $exitCode) { "N/A" } else { $exitCode }
        $footerLine = $ui.LogProcessFooter -f $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $exitCodeText
        Append-Task-Meta -TaskName $TaskName -Line $footerLine
        Append-Task-Meta -TaskName $TaskName -Line ""
        Append-Task-Meta -TaskName $TaskName -Line ""
    }

    # 任务进程管理
    # 启动任务
    function Start-Task {
        param([int]$Index)
        if ($Index -lt 0 -or $Index -ge $script:tasks.Count) { return }
        $task = $script:tasks[$Index]
        $taskName = [string]$task.name
        if ($script:executions.ContainsKey($taskName)) {
            $execution = $script:executions[$taskName]
            if ($execution.Process -and -not $execution.Process.HasExited) {
                System-Log ($ui.INFO_AlreadyRunning -f $taskName) "Warning"
                return
            }
        }
        # 展开环境变量
        $commandText = [System.Environment]::ExpandEnvironmentVariables([string]$task.command)
        $argumentText = ""
        if ($task.PSObject.Properties.Match('arguments').Count -gt 0 -and $task.arguments) {
            $argumentText = [System.Environment]::ExpandEnvironmentVariables([string]$task.arguments)
        }
        $workingDirText = $workingDirectory
        if ($task.PSObject.Properties.Match('workingDirectory').Count -gt 0 -and $task.workingDirectory) {
            $workingDirText = [System.Environment]::ExpandEnvironmentVariables([string]$task.workingDirectory)
        }
        if (-not [System.IO.Directory]::Exists($workingDirText)) {
            System-Log ($ui.ERROR_WorkDirNotFound -f $workingDirText) "Error"
            return
        }
        # 构建进程启动信息，隐藏窗口并重定向输出
        $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
        # UseShellExecute = false 走 CreateProcess，只能启动可执行文件，
        # .ps1 / .py 这类脚本必须自动拼接解释器，否则报「指定的可执行文件不是此操作系统平台的有效应用程序」
        # 命令可能是 PATH 中的裸名称，先用 Get-Command 取真实路径，再按扩展名判断
        $resolvedCommand = $commandText
        if (-not [System.IO.File]::Exists($resolvedCommand)) {
            $resolvedItem = Get-Command $commandText -ErrorAction SilentlyContinue
            if ($resolvedItem -and $resolvedItem.Source) {
                $resolvedCommand = [string]$resolvedItem.Source
            }
        }
        $commandExtension = [System.IO.Path]::GetExtension($resolvedCommand).ToLower()
        if ($commandExtension -eq ".bat" -or $commandExtension -eq ".cmd") {
            # 批处理脚本通过 cmd /s /c 启动；命令整体要再包一层引号，
            # 因为 /s 会剥掉最外层引号，只包一层时含空格的路径会被截断成不存在的命令
            $startInfo.FileName = $env:ComSpec
            $startInfo.Arguments = '/s /c ""' + $resolvedCommand + '" ' + $argumentText + '"'
        } elseif ($commandExtension -eq ".ps1") {
            # PowerShell 脚本通过 powershell -File 启动
            $powerShellExe = 'powershell.exe'
            if ($PSVersionTable.PSEdition -eq 'Core') {
                $powerShellExe = 'pwsh.exe'
            }
            $resolvedPowerShell = Get-Command $powerShellExe -ErrorAction SilentlyContinue
            if ($resolvedPowerShell -and $resolvedPowerShell.Source) {
                $powerShellExe = [string]$resolvedPowerShell.Source
            }
            $startInfo.FileName = $powerShellExe
            $startInfo.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $resolvedCommand + '" ' + $argumentText
        } elseif ($commandExtension -eq ".py") {
            # Python 脚本通过 python.exe 启动，找不到解释器时退回裸名称，由进程启动失败统一报错
            $pythonExe = 'python.exe'
            foreach ($candidate in @('python.exe', 'python3.exe')) {
                $resolvedPython = Get-Command $candidate -ErrorAction SilentlyContinue
                if ($resolvedPython -and $resolvedPython.Source) {
                    $pythonExe = [string]$resolvedPython.Source
                    break
                }
            }
            $startInfo.FileName = $pythonExe
            $startInfo.Arguments = '"' + $resolvedCommand + '" ' + $argumentText
        } else {
            $startInfo.FileName = $resolvedCommand
            $startInfo.Arguments = $argumentText
        }
        $startInfo.WorkingDirectory = $workingDirText
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.StandardOutputEncoding = $workingEncoding
        $startInfo.StandardErrorEncoding = $workingEncoding
        try {
            $process = [System.Diagnostics.Process]::new()
            $process.StartInfo = $startInfo
            if (-not $process.Start()) {
                throw ($ui.ERROR_TaskStartFailed -f $taskName)
            }
        } catch {
            System-Log ($ui.ERROR_TaskStartFailed -f $_.Exception.Message) "Error"
            return
        }
        # 用独立线程的读取循环收集输出，入队后由定时器统一刷新界面
        $readerScript = {
            param($reader, $queue, $name, $isError)
            try {
                while ($true) {
                    $line = $reader.ReadLine()
                    if ($null -eq $line) { break }
                    $queue.Enqueue(@{ TaskName = $name; Line = $line; IsError = $isError })
                }
            } catch {}
        }
        $newReader = {
            param($Reader, $IsError, $RunspacePool)
            $readerPs = [System.Management.Automation.PowerShell]::Create()
            $readerPs.RunspacePool = $RunspacePool
            $readerPs.AddScript($readerScript) | Out-Null
            $readerPs.AddParameter('reader', $Reader)
            $readerPs.AddParameter('queue', $script:outputQueue)
            $readerPs.AddParameter('name', $taskName)
            $readerPs.AddParameter('isError', $IsError)
            $readerPs.BeginInvoke() | Out-Null
            return $readerPs
        }
        # 初始化运行时状态
        $logBuilder = [System.Text.StringBuilder]::new()
        $headerLine = $ui.LogProcessHeader -f $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        if (-not $script:executions.ContainsKey($taskName)) {
            $script:executions[$taskName] = @{
                Process = $null
                Status = ""
                ExitCode = $null
                LogBuilder = $logBuilder
                Writer = $null
                LogFile = ""
                ViewerBox = $null
                StandardOutputReader = $null
                StandardErrorReader = $null
                RunspacePool = $null
            }
        }
        $execution = $script:executions[$taskName]
        $execution.Process = $process
        $execution.Status = $ui.StatusRunning
        $execution.ExitCode = $null
        $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(2, 2)
        $runspacePool.Open()
        $execution.RunspacePool = $runspacePool
        $execution.StandardOutputReader = & $newReader $process.StandardOutput $false $runspacePool
        $execution.StandardErrorReader = & $newReader $process.StandardError $true $runspacePool
        Append-Task-Meta -TaskName $taskName -Line $headerLine
        Update-Task-Row -Index $Index
        System-Log ($ui.INFO_Started -f $taskName, $process.Id) "Success"
    }
    # 停止任务（taskkill 结束整个进程树）
    function Stop-Task {
        param([int]$Index)
        if ($Index -lt 0 -or $Index -ge $script:tasks.Count) { return }
        $task = $script:tasks[$Index]
        $taskName = [string]$task.name
        if (-not $script:executions.ContainsKey($taskName)) { return }
        $execution = $script:executions[$taskName]
        if (-not $execution.Process -or $execution.Process.HasExited) { return }
        try {
            $killInfo = [System.Diagnostics.ProcessStartInfo]::new()
            $killInfo.FileName = "taskkill.exe"
            $killInfo.Arguments = "/PID $($execution.Process.Id) /T /F"
            $killInfo.UseShellExecute = $false
            $killInfo.CreateNoWindow = $true
            $killProcess = [System.Diagnostics.Process]::Start($killInfo)
            $killProcess.WaitForExit(10000) | Out-Null
            $killProcess.Dispose()
        } catch {
            try { $execution.Process.Kill() } catch {}
        }
        if (-not $execution.Process.HasExited) {
            $execution.Process.WaitForExit(500) | Out-Null
        }
        if ($execution.Status -eq $ui.StatusRunning) {
            $execution.Status = $ui.StatusStopped
        }
        Write-Task-Exit-Log -TaskName $taskName
        Stop-Task-Readers -execution $execution
        if ($execution.Writer) {
            try { $execution.Writer.Dispose() } catch {}
            $execution.Writer = $null
        }
        Update-Task-Row -Index $Index
        System-Log ($ui.INFO_Stopped -f $taskName) "Info"
    }
    # 重启任务
    function Restart-Task {
        param([int]$Index)
        Stop-Task -Index $Index
        Start-Task -Index $Index
    }
    # 全部启动
    function Start-All-Tasks {
        for ($i = 0; $i -lt $script:tasks.Count; $i++) {
            Start-Task -Index $i
        }
        System-Log $ui.INFO_StartAllDone "Success"
    }
    # 全部停止
    function Stop-All-Tasks {
        for ($i = 0; $i -lt $script:tasks.Count; $i++) {
            Stop-Task -Index $i
        }
        System-Log $ui.INFO_StopAllDone "Info"
    }

    # 任务日志标签页
    # 打开任务日志标签页（已存在则直接切换）
    function Show-Task-Log-Viewer {
        $task = Get-Selected-Task
        if ($null -eq $task) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        $taskName = [string]$task.name
        $logPageName = "LogPage_" + $taskName
        # 已存在则直接切换
        $existingPage = $tabControl.TabPages[$logPageName]
        if ($existingPage) {
            $tabControl.SelectedTab = $existingPage
            return
        }
        # 确保运行时条目存在
        if (-not $script:executions.ContainsKey($taskName)) {
            $script:executions[$taskName] = @{
                Process = $null
                Status = ""
                ExitCode = $null
                LogBuilder = [System.Text.StringBuilder]::new()
                Writer = $null
                LogFile = ""
                ViewerBox = $null
                StandardOutputReader = $null
                StandardErrorReader = $null
                RunspacePool = $null
            }
        }
        $execution = $script:executions[$taskName]
        # 新建日志标签页
        $logPage = [System.Windows.Forms.TabPage]::new()
        $logPage.Name = $logPageName
        $logPage.Text = $taskName
        $logPage.BackColor = [System.Drawing.Color]::White
        # 日志文本框
        $viewerTextBox = [System.Windows.Forms.RichTextBox]::new()
        $viewerTextBox.ReadOnly = $true
        $viewerTextBox.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
        $viewerTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
        $viewerTextBox.BackColor = [System.Drawing.Color]::White
        $viewerTextBox.WordWrap = $false
        $viewerTextBox.Font = $uiFont
        # 关闭 URL 自动检测，防止日志中的链接被渲染成蓝色下划线导致颜色/字体不一致
        $viewerTextBox.DetectUrls = $false
        $viewerTextBox.Dock = "Fill"
        $logPage.Controls.Add($viewerTextBox)
        # 日志文本框右键菜单: 复制日志 / 清空日志 / 打开日志文件
        $viewerContextMenu = [System.Windows.Forms.ContextMenuStrip]::new()
        $viewerCopyItem = [System.Windows.Forms.ToolStripMenuItem]::new()
        $viewerCopyItem.Text = $ui.LogCopy
        $viewerClearItem = [System.Windows.Forms.ToolStripMenuItem]::new()
        $viewerClearItem.Text = $ui.LogClear
        $viewerOpenItem = [System.Windows.Forms.ToolStripMenuItem]::new()
        $viewerOpenItem.Text = $ui.LogOpenFile
        $viewerContextMenu.Items.Add($viewerCopyItem) | Out-Null
        $viewerContextMenu.Items.Add($viewerClearItem) | Out-Null
        $viewerContextMenu.Items.Add($viewerOpenItem) | Out-Null
        $viewerTextBox.ContextMenuStrip = $viewerContextMenu
        # 载入历史日志（与追加行统一字体和颜色：微软雅黑 10 / 黑色，防止历史段落继承默认字体导致样式不一致）
        $viewerTextBox.SelectionStart = $viewerTextBox.TextLength
        $viewerTextBox.SelectionLength = 0
        $viewerTextBox.SelectionFont = $viewerTextBox.Font
        $viewerTextBox.SelectionColor = [System.Drawing.Color]::Black
        $viewerTextBox.AppendText($execution.LogBuilder.ToString())
        $viewerTextBox.SelectionStart = $viewerTextBox.TextLength
        $viewerTextBox.ScrollToCaret()
        # 右键菜单事件绑定
        $viewerCopyItem.Add_Click({
            if ($viewerTextBox.Text.Length -gt 0) {
                [System.Windows.Forms.Clipboard]::SetText($viewerTextBox.Text)
                System-Log $ui.INFO_LogCopied "Success"
            } else {
                System-Log $ui.INFO_NoLog "Warning"
            }
        })
        $viewerClearItem.Add_Click({
            $viewerTextBox.Clear()
            $execution.LogBuilder.Clear() | Out-Null
        })
        $viewerOpenItem.Add_Click({
            if ($execution.LogFile -and [System.IO.File]::Exists($execution.LogFile)) {
                Start-Process "notepad.exe" -ArgumentList ('"' + $execution.LogFile + '"')
            } else {
                System-Log $ui.INFO_NoLog "Warning"
            }
        })
        # 保存引用
        $execution.ViewerBox = $viewerTextBox
        # 添加到标签栏并选中
        $tabControl.TabPages.Add($logPage)
        $tabControl.SelectedTab = $logPage
    }

    # 界面刷新定时器: 消化输出队列 + 检查进程退出
    $refreshTimer = [System.Windows.Forms.Timer]::new()
    $refreshTimer.Interval = 500
    $refreshTimer.Add_Tick({
        # 消化后台线程的输出队列
        $logItem = $null
        while ($script:outputQueue.TryDequeue([ref]$logItem)) {
            Append-Task-Output -TaskName $logItem.TaskName -Line $logItem.Line -IsError $logItem.IsError
        }
        # 检查进程退出状态
        for ($i = 0; $i -lt $script:tasks.Count; $i++) {
            $task = $script:tasks[$i]
            $taskName = [string]$task.name
            if (-not $script:executions.ContainsKey($taskName)) { continue }
            $execution = $script:executions[$taskName]
            if ($execution.Process -and $execution.Process.HasExited) {
                if ($execution.Status -eq $ui.StatusRunning) {
                    if ($execution.Process.ExitCode -eq 0) {
                        $execution.Status = $ui.StatusExited
                    } else {
                        $execution.Status = $ui.StatusExitedError
                    }
                    System-Log ($ui.INFO_Exited -f $taskName, $execution.Process.ExitCode) "Warning"
                    Write-Task-Exit-Log -TaskName $taskName
                }
                Stop-Task-Readers -execution $execution
                if ($execution.Writer) {
                    try { $execution.Writer.Dispose() } catch {}
                    $execution.Writer = $null
                }
                Update-Task-Row -Index $i
            }
        }
    })
    $refreshTimer.Start()

    # 任务编辑对话框
    # 打开新增/修改任务的对话框，返回 DialogResult
    function Open-Task-Dialog {
        param([int]$EditIndex = -1)
        # 对话框窗体
        $dialogForm = [System.Windows.Forms.Form]::new()
        if ($EditIndex -ge 0) {
            $dialogForm.Text = $ui.DialogEditTitle
        } else {
            $dialogForm.Text = $ui.DialogAddTitle
        }
        $dialogForm.Size = [System.Drawing.Size]::new(750, 550)
        $dialogForm.FormBorderStyle = "FixedDialog"
        $dialogForm.StartPosition = "CenterParent"
        $dialogForm.MaximizeBox = $false
        $dialogForm.MinimizeBox = $false
        $dialogForm.Font = $uiFont
        $dialogForm.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
        $dialogForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
        function New-Dialog-Label {
            param([string]$Text, [int]$Y)
            $label = [System.Windows.Forms.Label]::new()
            $label.Text = $Text
            $label.Location = [System.Drawing.Point]::new(36, $Y + 4)
            $label.Size = [System.Drawing.Size]::new(100, 28)
            $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
            $dialogForm.Controls.Add($label)
        }
        function New-Dialog-TextBox {
            param([int]$Y)
            $textBox = [System.Windows.Forms.TextBox]::new()
            $textBox.Location = [System.Drawing.Point]::new(146, $Y)
            $textBox.Size = [System.Drawing.Size]::new(428, 30)
            $textBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
            $dialogForm.Controls.Add($textBox)
            return $textBox
        }
        # 任务名称
        New-Dialog-Label $ui.DialogName 36
        $nameBox = New-Dialog-TextBox 36
        # 命令
        New-Dialog-Label $ui.DialogCommand 96
        $commandBox = New-Dialog-TextBox 96
        $browseCommandButton = [System.Windows.Forms.Button]::new()
        $browseCommandButton.Text = $ui.DialogBrowseCommand
        $browseCommandButton.Location = [System.Drawing.Point]::new(584, 95)
        $browseCommandButton.Size = [System.Drawing.Size]::new(130, 32)
        $browseCommandButton.FlatStyle = "Flat"
        $browseCommandButton.BackColor = [System.Drawing.Color]::FromArgb(241, 243, 245)
        $browseCommandButton.ForeColor = [System.Drawing.Color]::Black
        $browseCommandButton.FlatAppearance.BorderSize = 0
        $browseCommandButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(226, 228, 230)
        $browseCommandButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(206, 208, 210)
        $dialogForm.Controls.Add($browseCommandButton)
        # 参数
        New-Dialog-Label $ui.DialogArguments 156
        $argumentsBox = New-Dialog-TextBox 156
        # 工作目录
        New-Dialog-Label $ui.DialogWorkingDir 216
        $workingDirBox = New-Dialog-TextBox 216
        $browseDirButton = [System.Windows.Forms.Button]::new()
        $browseDirButton.Text = $ui.DialogBrowseDir
        $browseDirButton.Location = [System.Drawing.Point]::new(584, 215)
        $browseDirButton.Size = [System.Drawing.Size]::new(130, 32)
        $browseDirButton.FlatStyle = "Flat"
        $browseDirButton.BackColor = [System.Drawing.Color]::FromArgb(241, 243, 245)
        $browseDirButton.ForeColor = [System.Drawing.Color]::Black
        $browseDirButton.FlatAppearance.BorderSize = 0
        $browseDirButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(226, 228, 230)
        $browseDirButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(206, 208, 210)
        $dialogForm.Controls.Add($browseDirButton)
        # 自动启动
        $autoStartBox = [System.Windows.Forms.CheckBox]::new()
        $autoStartBox.Text = $ui.DialogAutoStart
        $autoStartBox.Location = [System.Drawing.Point]::new(146, 276)
        $autoStartBox.Size = [System.Drawing.Size]::new(400, 28)
        $autoStartBox.Checked = $true
        $dialogForm.Controls.Add($autoStartBox)
        # 确定和取消按钮
        $okButton = [System.Windows.Forms.Button]::new()
        $okButton.Text = $ui.DialogOk
        $okButton.Location = [System.Drawing.Point]::new(444, 478)
        $okButton.Size = [System.Drawing.Size]::new(130, 36)
        $okButton.FlatStyle = "Flat"
        $okButton.BackColor = [System.Drawing.Color]::FromArgb(91, 155, 213)
        $okButton.ForeColor = [System.Drawing.Color]::White
        $okButton.FlatAppearance.BorderSize = 0
        $okButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(71, 135, 193)
        $okButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(51, 115, 173)
        $dialogForm.Controls.Add($okButton)
        $cancelButton = [System.Windows.Forms.Button]::new()
        $cancelButton.Text = $ui.DialogCancel
        $cancelButton.Location = [System.Drawing.Point]::new(584, 478)
        $cancelButton.Size = [System.Drawing.Size]::new(130, 36)
        $cancelButton.FlatStyle = "Flat"
        $cancelButton.BackColor = [System.Drawing.Color]::FromArgb(241, 243, 245)
        $cancelButton.ForeColor = [System.Drawing.Color]::Black
        $cancelButton.FlatAppearance.BorderSize = 0
        $cancelButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(226, 228, 230)
        $cancelButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(206, 208, 210)
        $dialogForm.Controls.Add($cancelButton)
        $dialogForm.AcceptButton = $okButton
        $dialogForm.CancelButton = $cancelButton
        # 选择命令文件
        $browseCommandButton.Add_Click({
            $fileDialog = [System.Windows.Forms.OpenFileDialog]::new()
            $fileDialog.Filter = $ui.DialogExeFilter
            $fileDialog.Title = $ui.DialogBrowseCommandTitle
            $fileDialog.InitialDirectory = $workingDirectory
            if ($fileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $commandBox.Text = $fileDialog.FileName
                if (-not $workingDirBox.Text) {
                    $workingDirBox.Text = Split-Path -Parent $fileDialog.FileName
                }
            }
        })
        # 选择工作目录
        $browseDirButton.Add_Click({
            $folderDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
            $folderDialog.Description = $ui.DialogBrowseDirTitle
            $folderDialog.SelectedPath = $workingDirectory
            if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $workingDirBox.Text = $folderDialog.SelectedPath
            }
        })
        # 修改模式时填充原始值
        $originalName = ""
        if ($EditIndex -ge 0 -and $EditIndex -lt $script:tasks.Count) {
            $task = $script:tasks[$EditIndex]
            $originalName = [string]$task.name
            $nameBox.Text = $originalName
            $commandBox.Text = [string]$task.command
            if ($task.PSObject.Properties.Match('arguments').Count -gt 0) {
                $argumentsBox.Text = [string]$task.arguments
            }
            if ($task.PSObject.Properties.Match('workingDirectory').Count -gt 0) {
                $workingDirBox.Text = [string]$task.workingDirectory
            }
            if ($task.PSObject.Properties.Match('autoStart').Count -gt 0) {
                $autoStartBox.Checked = [bool]$task.autoStart
            }
        }
        # 确定按钮: 校验并写回任务列表
        $okButton.Add_Click({
            $newName = $nameBox.Text.Trim()
            $newCommand = $commandBox.Text.Trim()
            $newArguments = $argumentsBox.Text.Trim()
            $newWorkingDir = $workingDirBox.Text.Trim()
            if (-not $newName) {
                [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NameEmpty, $ui.FormTitle, "OK", "Warning") | Out-Null
                return
            }
            if (-not $newCommand) {
                [System.Windows.Forms.MessageBox]::Show($ui.ERROR_CommandEmpty, $ui.FormTitle, "OK", "Warning") | Out-Null
                return
            }
            # 任务名称唯一性检查（修改时允许保持自身名称不变）
            for ($i = 0; $i -lt $script:tasks.Count; $i++) {
                if ($i -eq $EditIndex) { continue }
                if ([string]$script:tasks[$i].name -ieq $newName) {
                    [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NameDuplicated -f $newName, $ui.FormTitle, "OK", "Warning") | Out-Null
                    return
                }
            }
            # 命令和工作目录的存在性检查（支持环境变量，允许 relauncher 类命令行）
            $expandedCommand = [System.Environment]::ExpandEnvironmentVariables($newCommand)
            if ($expandedCommand -and -not [System.IO.File]::Exists($expandedCommand) -and -not (Get-Command $expandedCommand -ErrorAction SilentlyContinue)) {
                $confirmResult = [System.Windows.Forms.MessageBox]::Show($ui.ERROR_CommandNotFound -f $expandedCommand, $ui.FormTitle, "YesNo", "Warning")
                if ($confirmResult -ne [System.Windows.Forms.DialogResult]::Yes) {
                    return
                }
            }
            if ($newWorkingDir) {
                $expandedDir = [System.Environment]::ExpandEnvironmentVariables($newWorkingDir)
                if (-not [System.IO.Directory]::Exists($expandedDir)) {
                    [System.Windows.Forms.MessageBox]::Show($ui.ERROR_WorkDirNotFound -f $expandedDir, $ui.FormTitle, "OK", "Warning") | Out-Null
                    return
                }
            }
            # 构建新的任务配置对象
            $newTask = [PSCustomObject]@{
                name = $newName
                command = $newCommand
                arguments = $newArguments
                workingDirectory = $newWorkingDir
                autoStart = $autoStartBox.Checked
            }
            if ($EditIndex -ge 0) {
                # 修改任务: 替换配置
                $script:tasks[$EditIndex] = $newTask
                # 名称变更时，迁移运行时数据并移除旧日志标签页
                if ($originalName -ine $newName -and $script:executions.ContainsKey($originalName)) {
                    $oldRuntime = $script:executions[$originalName]
                    # 移除旧的日志标签页
                    $oldPageName = "LogPage_" + $originalName
                    $oldPage = $tabControl.TabPages[$oldPageName]
                    if ($oldPage) {
                        $tabControl.TabPages.Remove($oldPage)
                        $oldPage.Dispose()
                    }
                    # 迁移运行时数据到新名称
                    $script:executions[$newName] = $oldRuntime
                    $script:executions.Remove($originalName) | Out-Null
                }
            } else {
                $script:tasks += $newTask
            }
            Save-Config
            Update-Task-Grid
            $dialogForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $dialogForm.Close()
        })
        $cancelButton.Add_Click({
            $dialogForm.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $dialogForm.Close()
        })
        $result = $dialogForm.ShowDialog($mainForm)
        $dialogForm.Dispose()
        return $result
    }
} catch {
    Handle-Exception $_
    pause
    exit 1
}



# ———————————————————————————————— 4: 窗体界面绘制 ————————————————————————————————

try {
    # 主窗口
    $mainForm = [System.Windows.Forms.Form]::new()
    $mainForm.Text = $ui.FormTitle
    $mainForm.Size = [System.Drawing.Size]::new(1650, 950)
    $mainForm.MinimumSize = [System.Drawing.Size]::new(850, 650)
    $mainForm.StartPosition = "CenterScreen"
    $mainForm.Font = $uiFont
    $mainForm.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
    $mainForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    # 启用双缓冲减少闪烁
    Enable-Double-Buffered $mainForm | Out-Null
    # 显示主窗口（从托盘恢复时使用）
    function Show-MainWindow {
        $mainForm.Show()
        $mainForm.WindowState = [System.Windows.Forms.FormWindowState]::Normal
        $mainForm.ShowInTaskbar = $true
        $mainForm.Activate()
    }
    # 窗体关闭事件: 默认隐藏到托盘，真正退出时才关闭
    $mainForm.Add_FormClosing({
        param($eventSender, $event)
        if (-not $script:realExit) {
            $event.Cancel = $true
            $eventSender.Hide()
            $eventSender.ShowInTaskbar = $false
        }
    })
    # 窗体首次显示事件: 隐藏到托盘 + 自动启动任务
    $mainForm.Add_Shown({
        param($eventSender, $event)
        $eventSender.Opacity = 0
        $eventSender.Hide()
        $eventSender.Opacity = 1
        $eventSender.ShowInTaskbar = $false
        # 启动全部 autoStart 任务
        for ($i = 0; $i -lt $script:tasks.Count; $i++) {
            $task = $script:tasks[$i]
            $needStart = $true
            if ($task.PSObject.Properties.Match('autoStart').Count -gt 0 -and $null -ne $task.autoStart) {
                $needStart = [bool]$task.autoStart
            }
            if ($needStart) {
                Start-Task -Index $i
            }
        }
    })

    # 托盘图标与托盘菜单
    # 绘制托盘图标（蓝色圆形 + 白色 M 字样）
    $trayBitmap = [System.Drawing.Bitmap]::new(32, 32)
    $trayGraphics = [System.Drawing.Graphics]::FromImage($trayBitmap)
    $trayGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $trayGraphics.Clear([System.Drawing.Color]::Transparent)
    $trayBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(91, 155, 213))
    $trayGraphics.FillEllipse($trayBrush, 1, 1, 30, 30)
    $trayFont = [System.Drawing.Font]::new("Microsoft YaHei", 15, [System.Drawing.FontStyle]::Bold)
    $trayFormat = [System.Drawing.StringFormat]::new()
    $trayFormat.Alignment = [System.Drawing.StringAlignment]::Center
    $trayFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
    $trayRect = [System.Drawing.RectangleF]::new(0, 2, 32, 28)
    $trayGraphics.DrawString("M", $trayFont, [System.Drawing.Brushes]::White, $trayRect, $trayFormat)
    $trayGraphics.Dispose()
    $trayIcon = [System.Windows.Forms.NotifyIcon]::new()
    # 蓝色圆形 + 白色 M 图标同时用于托盘和主窗口（clone 避免共享句柄时一方 Dispose 影响另一方）
    $appWindowIcon = [System.Drawing.Icon]::FromHandle($trayBitmap.GetHicon())
    $trayIcon.Icon = $appWindowIcon
    $mainForm.Icon = $appWindowIcon.Clone()
    $trayIcon.Text = $ui.FormTitle
    $trayIcon.Visible = $true
    # 托盘图标的右键菜单
    $trayMenu = [System.Windows.Forms.ContextMenuStrip]::new()
    $trayShowItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $trayShowItem.Text = $ui.TrayShow
    $trayStartAllItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $trayStartAllItem.Text = $ui.TrayStartAll
    $trayStopAllItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $trayStopAllItem.Text = $ui.TrayStopAll
    $trayExitItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $trayExitItem.Text = $ui.TrayExit
    foreach ($item in @($trayShowItem, $trayStartAllItem, $trayStopAllItem, $trayExitItem)) {
        $trayMenu.Items.Add($item) | Out-Null
    }
    $trayIcon.ContextMenuStrip = $trayMenu
    # 托盘图标: 单击切换显示/隐藏，双击显示
    $trayIcon.Add_MouseClick({
        param($eventSender, $event)
        if ($event.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            if ($mainForm.Visible) {
                $mainForm.Hide()
                $mainForm.ShowInTaskbar = $false
            } else {
                Show-MainWindow
            }
        }
    })
    $trayIcon.Add_MouseDoubleClick({
        param($eventSender, $event)
        if ($event.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            Show-MainWindow
        }
    })
    # 托盘菜单: 显示主界面 / 全部启动 / 全部停止 / 退出
    $trayShowItem.Add_Click({
        Show-MainWindow
    })
    $trayStartAllItem.Add_Click({ Start-All-Tasks })
    $trayStopAllItem.Add_Click({ Stop-All-Tasks })
    $trayExitItem.Add_Click({
        $confirmResult = [System.Windows.Forms.MessageBox]::Show($ui.ConfirmExit, $ui.ConfirmTitle, "YesNo", "Question")
        if ($confirmResult -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        $script:realExit = $true
        Stop-All-Tasks
        $trayIcon.Visible = $false
        $mainForm.Close()
    })

    # 标签页容器（充满整个窗口，浏览器式布局）
    $tabControl = [System.Windows.Forms.TabControl]::new()
    $tabControl.Dock = "Fill"
    $tabControl.Padding = [System.Drawing.Point]::new(20, 3)
    $tabControl.Font = $uiFont
    $mainForm.Controls.Add($tabControl)
    # 标签页右键菜单（关闭标签页）
    $tabContextMenu = [System.Windows.Forms.ContextMenuStrip]::new()
    $closeTabMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $closeTabMenuItem.Text = $ui.CloseTab
    $tabContextMenu.Items.Add($closeTabMenuItem) | Out-Null
    $tabControl.ContextMenuStrip = $tabContextMenu
    # 右键按下时记录点击的标签页
    $tabControl.Add_MouseDown({
        param($sender, $e)
        if ($e.Button -ne [System.Windows.Forms.MouseButtons]::Right) { return }
        # 查找点击的标签页
        for ($i = 0; $i -lt $tabControl.TabPages.Count; $i++) {
            $tabRect = $tabControl.GetTabRect($i)
            if ($tabRect.Contains($e.Location)) {
                $script:rightClickedTab = $tabControl.TabPages[$i]
                # 前两个固定标签页不可关闭
                $closeTabMenuItem.Enabled = ($i -ge 2)
                break
            }
        }
    })
    # 关闭标签页
    $closeTabMenuItem.Add_Click({
        if (-not $script:rightClickedTab -or $script:rightClickedTab.IsDisposed) { return }
        $tabName = $script:rightClickedTab.Name
        # 如果是任务日志页，清理运行时引用
        if ($tabName.StartsWith("LogPage_")) {
            $taskName = $tabName.Substring(8)
            if ($script:executions.ContainsKey($taskName)) {
                $script:executions[$taskName].ViewerBox = $null
            }
        }
        $tabControl.TabPages.Remove($script:rightClickedTab)
        $script:rightClickedTab.Dispose()
        $script:rightClickedTab = $null
    })

    # 任务列表标签页
    $taskListTabPage = [System.Windows.Forms.TabPage]::new()
    $taskListTabPage.Text = $ui.TabTaskList
    $taskListTabPage.BackColor = [System.Drawing.Color]::White
    $tabControl.Controls.Add($taskListTabPage)
    # 任务信息显示表格
    $dataGridView = [System.Windows.Forms.DataGridView]::new()
    $dataGridView.ReadOnly = $true
    $dataGridView.AllowUserToAddRows = $false
    $dataGridView.AllowUserToDeleteRows = $false
    $dataGridView.AllowUserToResizeRows = $false
    $dataGridView.RowHeadersVisible = $false
    $dataGridView.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
    $dataGridView.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $dataGridView.BackgroundColor = [System.Drawing.Color]::White
    $dataGridView.GridColor = [System.Drawing.Color]::FromArgb(226, 228, 230)
    $dataGridView.CellBorderStyle = [System.Windows.Forms.DataGridViewCellBorderStyle]::SingleHorizontal
    $dataGridView.EnableHeadersVisualStyles = $false
    $dataGridView.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(91, 155, 213)
    $dataGridView.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $dataGridView.ColumnHeadersDefaultCellStyle.Font = [System.Drawing.Font]::new($uiFont, [System.Drawing.FontStyle]::Bold)
    $dataGridView.ColumnHeadersHeight = 40
    $dataGridView.RowTemplate.Height = 32
    $dataGridView.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(241, 243, 245)
    # 单元格字体显式指定（默认依赖窗体字体继承，显式赋值可避免环境差异导致表格与其它控件字体不一致）
    $dataGridView.DefaultCellStyle.Font = $uiFont
    $dataGridView.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(231, 240, 255)
    $dataGridView.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::Black
    $dataGridView.Dock = "Fill"
    $dataGridView.ColumnCount = 6
    $dataGridView.Columns[0].Name = $ui.ColumnStatus
    $dataGridView.Columns[1].Name = $ui.ColumnPid
    $dataGridView.Columns[2].Name = $ui.ColumnName
    $dataGridView.Columns[3].Name = $ui.ColumnCommand
    $dataGridView.Columns[4].Name = $ui.ColumnArguments
    $dataGridView.Columns[5].Name = $ui.ColumnWorkingDir
    $dataGridView.Columns[0].Width = 200
    $dataGridView.Columns[0].MinimumWidth = $dataGridView.Columns[0].Width / 2
    $dataGridView.Columns[1].Width = 100
    $dataGridView.Columns[1].MinimumWidth = $dataGridView.Columns[1].Width / 2
    $dataGridView.Columns[2].Width = 200
    $dataGridView.Columns[2].MinimumWidth = $dataGridView.Columns[2].Width / 2
    $dataGridView.Columns[3].Width = 400
    $dataGridView.Columns[3].MinimumWidth = $dataGridView.Columns[3].Width / 2
    $dataGridView.Columns[4].Width = 400
    $dataGridView.Columns[4].MinimumWidth = $dataGridView.Columns[4].Width / 2
    $dataGridView.Columns[5].Width = 300
    $dataGridView.Columns[5].MinimumWidth = $dataGridView.Columns[5].Width / 2
    # 只允许单行选择
    $dataGridView.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
    $dataGridView.MultiSelect = $false
    # 鼠标按下时自动选中一行（包括左键和右键）
    $dataGridView.Add_CellMouseDown({
        param($eventSender, $event)
        if ($event.RowIndex -ge 0) {
            $dataGridView.ClearSelection()
            $dataGridView.Rows[$event.RowIndex].Selected = $true
            $dataGridView.CurrentCell = $dataGridView.Rows[$event.RowIndex].Cells[0]
        }
    })
    # 双击行查看任务日志
    $dataGridView.Add_CellDoubleClick({
        Show-Task-Log-Viewer
    })
    $taskListTabPage.Controls.Add($dataGridView)
    # 任务表格创建完成，交给全局变量供 Update-Task-Grid / Update-Task-Row 等函数使用
    $script:taskGridView = $dataGridView
    # 任务列表的右键菜单
    $taskContextMenu = [System.Windows.Forms.ContextMenuStrip]::new()
    $menuStartItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuStartItem.Text = $ui.MenuStart
    $menuStopItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuStopItem.Text = $ui.MenuStop
    $menuRestartItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuRestartItem.Text = $ui.MenuRestart
    $menuViewLogItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuViewLogItem.Text = $ui.MenuViewLog
    $menuSep1 = [System.Windows.Forms.ToolStripSeparator]::new()
    $menuStartAllItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuStartAllItem.Text = $ui.MenuStartAll
    $menuStopAllItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuStopAllItem.Text = $ui.MenuStopAll
    $menuSep2 = [System.Windows.Forms.ToolStripSeparator]::new()
    $menuAddItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuAddItem.Text = $ui.MenuAdd
    $menuEditItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuEditItem.Text = $ui.MenuEdit
    $menuDeleteItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuDeleteItem.Text = $ui.MenuDelete
    foreach ($item in @(
        $menuStartItem, $menuStopItem, $menuRestartItem, $menuViewLogItem,
        $menuSep1, $menuStartAllItem, $menuStopAllItem,
        $menuSep2, $menuAddItem, $menuEditItem, $menuDeleteItem
    )) {
        $taskContextMenu.Items.Add($item) | Out-Null
    }
    $dataGridView.ContextMenuStrip = $taskContextMenu
    # 右键菜单: 新增任务
    $menuAddItem.Add_Click({ Open-Task-Dialog -EditIndex -1 })
    # 右键菜单: 启动任务
    $menuStartItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        Start-Task -Index $index
    })
    # 右键菜单: 停止任务
    $menuStopItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        Stop-Task -Index $index
    })
    # 右键菜单: 重启任务
    $menuRestartItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        Restart-Task -Index $index
    })
    # 右键菜单: 查看任务日志
    $menuViewLogItem.Add_Click({ Show-Task-Log-Viewer })
    # 右键菜单: 修改任务（运行中则先停止，保存后再启动）
    $menuEditItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        $taskName = [string]$script:tasks[$index].name
        $isRunning = $false
        if ($script:executions.ContainsKey($taskName)) {
            $execution = $script:executions[$taskName]
            if ($execution.Process -and -not $execution.Process.HasExited) { $isRunning = $true }
        }
        $needRestart = $false
        if ($isRunning) {
            $confirmResult = [System.Windows.Forms.MessageBox]::Show($ui.ConfirmRestart -f $taskName, $ui.ConfirmTitle, "YesNo", "Question")
            if ($confirmResult -ne [System.Windows.Forms.DialogResult]::Yes) { return }
            Stop-Task -Index $index
            $needRestart = $true
        }
        $result = Open-Task-Dialog -EditIndex $index
        if ($needRestart -and $result -eq [System.Windows.Forms.DialogResult]::OK) {
            Start-Task -Index $index
        }
    })
    # 右键菜单: 删除任务
    $menuDeleteItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        $taskName = [string]$script:tasks[$index].name
        $confirmResult = [System.Windows.Forms.MessageBox]::Show($ui.ConfirmDelete -f $taskName, $ui.ConfirmTitle, "YesNo", "Question")
        if ($confirmResult -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        Stop-Task -Index $index
        if ($script:executions.ContainsKey($taskName)) {
            $execution = $script:executions[$taskName]
            # 移除对应的日志标签页
            $logPageName = "LogPage_" + $taskName
            $logPage = $tabControl.TabPages[$logPageName]
            if ($logPage) {
                $tabControl.TabPages.Remove($logPage)
                $logPage.Dispose()
            }
            if ($execution.Writer) {
                try { $execution.Writer.Dispose() } catch {}
            }
            $script:executions.Remove($taskName) | Out-Null
        }
        $newTasks = @()
        for ($i = 0; $i -lt $script:tasks.Count; $i++) {
            if ($i -ne $index) { $newTasks += $script:tasks[$i] }
        }
        $script:tasks = $newTasks
        Save-Config
        Update-Task-Grid
        System-Log ($ui.INFO_Deleted -f $taskName) "Info"
    })
    # 右键菜单: 全部启动 / 全部停止
    $menuStartAllItem.Add_Click({ Start-All-Tasks })
    $menuStopAllItem.Add_Click({ Stop-All-Tasks })

    # 系统日志标签页
    $logTabPage = [System.Windows.Forms.TabPage]::new()
    $logTabPage.Text = $ui.TabRunLog
    $logTabPage.BackColor = [System.Drawing.Color]::White
    $tabControl.Controls.Add($logTabPage)
    # 全局系统日志显示区域
    $logTextBox = [System.Windows.Forms.RichTextBox]::new()
    $logTextBox.ReadOnly = $true
    $logTextBox.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
    $logTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $logTextBox.BackColor = [System.Drawing.Color]::White
    # 系统日志与全局字体统一使用微软雅黑
    $logTextBox.Font = $uiFont
    # 关闭 URL 自动检测，防止日志中的链接被渲染成蓝色下划线导致颜色/字体不一致
    $logTextBox.DetectUrls = $false
    $logTextBox.WordWrap = $false
    $logTextBox.Dock = "Fill"
    $logTabPage.Controls.Add($logTextBox)
    # 系统日志展示控件交给 System-Log 使用
    $script:systemLogTextBox = $logTextBox
    # 系统日志的右键菜单
    $copyLogMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $copyLogMenuItem.Text = $ui.LogCopy
    $clearLogMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $clearLogMenuItem.Text = $ui.LogClear
    $logTextBox.ContextMenuStrip = [System.Windows.Forms.ContextMenuStrip]::new()
    $logTextBox.ContextMenuStrip.Items.Add($copyLogMenuItem) | Out-Null
    $logTextBox.ContextMenuStrip.Items.Add($clearLogMenuItem) | Out-Null
    # 右键菜单: 复制日志
    $copyLogMenuItem.Add_Click({
        if ($logTextBox.Text.Length -gt 0) {
            [System.Windows.Forms.Clipboard]::SetText($logTextBox.Text)
            System-Log $ui.INFO_LogCopied "Success"
        } else {
            System-Log $ui.INFO_NoLog "Warning"
        }
    })
    # 右键菜单: 清空日志
    $clearLogMenuItem.Add_Click({
        $logTextBox.Clear()
    })
} catch {
    Handle-Exception $_
    pause
    exit 1
}



# ———————————————————————————————— 5: 程序启动 ————————————————————————————————

try {
    # 加载配置文件
    System-Log ($ui.INFO_SystemInfo -f $myBatchTaskConfigFile) "Info"
    Load-Config | Out-Null
    # 程序启动（首次显示时自动隐藏到托盘）
    [System.Windows.Forms.Application]::Run($mainForm)
    # 主循环结束后清理资源
    $refreshTimer.Stop()
    $refreshTimer.Dispose()
    Stop-All-Tasks
    $trayIcon.Visible = $false
    $trayIcon.Dispose()
} catch {
    Handle-Exception $_
    pause
    exit 1
}
