# MyBatchTask 批处理任务管理器
#
# 开源地址: https://github.com/MoonLord-LM/MyBatch
#
# 功能：
#     集中管理多个命令行后台任务（如 cloudflared、frpc、openlist 等）
#     以隐藏窗口方式启动，避免每个任务都占用一个黑色控制台窗口
#     启动后默认最小化到桌面右下角托盘图标
#     同一时间只允许运行一个实例
#     通过界面的表格，管理任务的启动、停止、重启、新增、修改、删除，并记录每个任务的输出内容到日志文件中
#
# 目录说明：
#     配置文件：脚本同目录下的 \MyBatchTask\config.json，首次运行自动创建示例配置
#     示例配置:
#     [
#         {
#             "name": "Ping Test",
#             "command": "%SystemRoot%\\System32\\cmd.exe",
#             "arguments": "/s /c \"chcp 65001 >nul && ping github.com\"",
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
#     workingDirectory 工作目录
#     autoStart 管理器启动时是否自动运行
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
    $win32ApiCode =
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
    Add-Type -TypeDefinition $win32ApiCode

    # 禁用自动缩放
    $dpiResult = $false
    try {
        $dpiResult = [DpiHelper]::SetProcessDpiAwarenessContext([DpiContext]::PER_MONITOR_AWARE_V2)
    } catch { }
    if(-not $dpiResult){
        $dpiResult = [DpiHelper]::SetProcessDPIAware()
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
        "arguments": "/s /c \"chcp 65001 >nul && ping github.com\"",
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
        "arguments": "/s /c \"chcp 65001 >nul && ping github.com\"",
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
            MenuMoveUp = "上移"
            MenuMoveDown = "下移"
            MenuEdit = "修改任务"
            MenuDelete = "删除任务"
            MenuStartAll = "全部启动"
            MenuStopAll = "全部停止"
            StatusNotStarted = "未启动"
            StatusRunning = "运行中"
            StatusStopped = "手动结束"
            StatusExited = "正常结束"
            StatusExitedError = "异常结束"
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
            ERROR_NameInvalid = "任务名称包含特殊字符，不能作为 Windows 文件名: {0}"
            ERROR_FieldMissing = "任务配置缺少必填字段，已跳过该任务: {0}"
            ERROR_WorkDirNotFound = "工作目录不存在: {0}"
            ERROR_NoSelection = "请先在列表中选择一个任务"
            ERROR_AlreadyRunning = "程序已经在运行中，请查看桌面右下角的托盘图标"
            ERROR_TaskStartFailed = "任务启动失败: {0}"
            ERROR_TaskStopFailed = "任务停止失败: {0}"
            ERROR_TaskStopTimeout = "停止任务超时: {0}"
            INFO_Started = "任务已启动: {0} (PID {1})"
            INFO_Stopped = "任务已停止: {0}"
            INFO_Exited = "任务已退出: {0} (退出码 {1})"
            INFO_AlreadyRunning = "任务已在运行中: {0}"
            INFO_NotStarted = "任务尚未启动: {0}"
            INFO_AlreadyStopped = "任务已处于停止状态: {0}"
            INFO_Deleted = "任务已删除: {0}"
            INFO_Saved = "配置已保存到 {0}"
            INFO_ConfigLoaded = "已加载 {0} 个任务"
            INFO_ConfigLoadFailed = "配置文件加载失败: {0}"
            INFO_ConfigNotFound = "未找到配置文件: {0}"
            INFO_NameRenamed = "任务名称「{0}」重复，已自动重命名为「{1}」"
            INFO_StartAllDone = "已启动全部任务"
            INFO_StopAllDone = "已停止全部任务"
            INFO_LogCopied = "日志已复制到剪贴板"
            INFO_LogOpened = "已打开日志文件: {0}"
            INFO_NoLog = "当前没有日志内容"
            INFO_TrayHint = "程序已最小化到托盘图标，双击托盘图标可重新打开界面"
            INFO_SystemInfo = "配置文件: [ {0} ]"
            DialogAddTitle = "新增任务"
            DialogEditTitle = "修改任务"
            DialogName = "任务名称:"
            DialogCommand = "命令:"
            DialogArguments = "参数:"
            DialogWorkingDir = "工作目录:"
            DialogStartMode = "启动方式:"
            DialogAutoStart = "管理器启动时自动运行"
            DialogManualStart = "手动执行"
            DialogBrowseCommand = "选择文件"
            DialogBrowseDir = "选择目录"
            DialogBrowseCommandTitle = "选择命令文件"
            DialogBrowseDirTitle = "选择工作目录"
            DialogExeFilter = "可执行文件 (*.exe;*.bat;*.cmd;*.ps1;*.py)|*.exe;*.bat;*.cmd;*.ps1;*.py|所有文件 (*.*)|*.*"
            DialogSave = "保存"
            DialogSaveRestart = "保存并重启任务"
            DialogCancel = "取消"
            FileFilterLog = "日志文件 (*.log)|*.log|所有文件 (*.*)|*.*"
            CloseTab = "关闭标签页"
            LogTaskStart = "———————————— 开始新进程 ————————————————"
            LogTaskEndNormal = "———————————— 正常退出进程 ————————————————"
            LogTaskEndError = "———————————— 异常结束进程，错误码 {0} ————————————————"
            LogTaskStopManual = "———————————— 手动结束进程 ————————————————"
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
            MenuMoveUp = "Move Up"
            MenuMoveDown = "Move Down"
            MenuEdit = "Edit Task"
            MenuDelete = "Delete Task"
            MenuStartAll = "Start All"
            MenuStopAll = "Stop All"
            StatusNotStarted = "Not Started"
            StatusRunning = "Running"
            StatusStopped = "Manual Stop"
            StatusExited = "Exited Normally"
            StatusExitedError = "Abnormal Exit"
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
            ERROR_NameInvalid = "Task name contains special characters and cannot be used as a Windows file name: {0}"
            ERROR_FieldMissing = "Task config is missing required field, task skipped: {0}"
            ERROR_WorkDirNotFound = "Working directory not found: {0}"
            ERROR_NoSelection = "Please select a task from the list first"
            ERROR_AlreadyRunning = "The program is already running. Please check the tray icon in the lower right corner."
            ERROR_TaskStartFailed = "Failed to start task: {0}"
            ERROR_TaskStopFailed = "Failed to stop task: {0}"
            ERROR_TaskStopTimeout = "Stopping task timed out: {0}"
            INFO_Started = "Task started: {0} (PID {1})"
            INFO_Stopped = "Task stopped: {0}"
            INFO_Exited = "Task exited: {0} (exit code {1})"
            INFO_AlreadyRunning = "Task is already running: {0}"
            INFO_NotStarted = "Task has not started: {0}"
            INFO_AlreadyStopped = "Task is already stopped: {0}"
            INFO_Deleted = "Task deleted: {0}"
            INFO_Saved = "Configuration saved to {0}"
            INFO_ConfigLoaded = "Loaded {0} task(s)"
            INFO_ConfigLoadFailed = "Failed to load configuration file: {0}"
            INFO_ConfigNotFound = "Configuration file not found: {0}"
            INFO_NameRenamed = "Task name '{0}' is duplicated and has been renamed to '{1}'"
            INFO_StartAllDone = "All tasks started"
            INFO_StopAllDone = "All tasks stopped"
            INFO_LogCopied = "Log copied to clipboard"
            INFO_LogOpened = "Log file opened: {0}"
            INFO_NoLog = "No log content"
            INFO_TrayHint = "The program is minimized to the tray icon. Double-click the tray icon to reopen the window."
            INFO_SystemInfo = "Config file: [ {0} ]"
            DialogAddTitle = "Add Task"
            DialogEditTitle = "Edit Task"
            DialogName = "Task Name:"
            DialogCommand = "Command:"
            DialogArguments = "Arguments:"
            DialogWorkingDir = "Working Directory:"
            DialogStartMode = "Start Mode:"
            DialogAutoStart = "Auto start when the manager starts"
            DialogManualStart = "Manual"
            DialogBrowseCommand = "Browse"
            DialogBrowseDir = "Browse"
            DialogBrowseCommandTitle = "Select Command File"
            DialogBrowseDirTitle = "Select Working Directory"
            DialogExeFilter = "Executable files (*.exe;*.bat;*.cmd;*.ps1;*.py)|*.exe;*.bat;*.cmd;*.ps1;*.py|All files (*.*)|*.*"
            DialogSave = "Save"
            DialogSaveRestart = "Save and Restart Task"
            DialogCancel = "Cancel"
            FileFilterLog = "Log files (*.log)|*.log|All files (*.*)|*.*"
            CloseTab = "Close Tab"
            LogTaskStart = "———————————— Start new process ————————————————"
            LogTaskEndNormal = "———————————— Process finished normally ————————————————"
            LogTaskEndError = "———————————— Process exited abnormally, error code {0} ————————————————"
            LogTaskStopManual = "———————————— Manual stop process ————————————————"
        }
    }
    $ui = $uiTextResources[$workingLanguage]

    # 单实例保护：已经有实例在运行时，直接提示后退出
    $appMutexCreatedNew = $false
    $script:appMutex = [System.Threading.Mutex]::new($false, 'Local\MyBatchTask_SingleInstance', [ref]$appMutexCreatedNew)
    if (-not $appMutexCreatedNew) {
        $script:appMutex.Dispose()
        $script:appMutex = $null
        [System.Windows.Forms.MessageBox]::Show($ui.ERROR_AlreadyRunning, $ui.FormTitle, 'OK', 'Warning') | Out-Null
        exit 1
    }
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
        param($TextBox, $Text, $Color)

        try {
            if ($null -eq $TextBox -or $TextBox.IsDisposed) {
                return
            }
            $TextBox.SuspendLayout()
            try {
                $TextBox.SelectionStart = $TextBox.TextLength
                $TextBox.SelectionLength = 0
                $TextBox.SelectionFont = $TextBox.Font
                $TextBox.SelectionColor = $Color
                $TextBox.AppendText($Text)
                $TextBox.SelectionStart = $TextBox.TextLength
                $TextBox.ScrollToCaret()
            }
            finally {
                $TextBox.ResumeLayout()
            }
        } catch {
            Handle-Exception $_
        }
    }
    $systemLogInternalAction = [Action[System.Windows.Forms.RichTextBox, string, System.Drawing.Color]]{
        param($TextBox, $Text, $Color)

        System-Log-Internal $TextBox $Text $Color
    }
    function System-Log {
        param([string]$Message = '', [string]$Level = 'Info')

        $logLine = "[{0}] {1}`r`n" -f $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
        $lockTaken = $false
        try {
            [System.Threading.Monitor]::Enter($systemLogFileLock, [ref]$lockTaken)
            [System.IO.File]::AppendAllText($myBatchTaskSystemLogFile, $logLine, $workingEncoding)
        } catch {
            Handle-Exception $_
        } finally {
            if ($lockTaken) {
                [System.Threading.Monitor]::Exit($systemLogFileLock)
            }
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
    # JSON 数组，每个元素的字段：name，command，arguments，workingDirectory，autoStart
    $taskConfigList = @()

    # 保存任务列表到配置文件
    function Save-Config {
        $objects = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($task in $taskConfigList) {
            $objects.Add([PSCustomObject]@{
                name = [string]$task.name
                command = [string]$task.command
                arguments = [string]$task.arguments
                workingDirectory = [string]$task.workingDirectory
                autoStart = [bool]$task.autoStart
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
            $seenNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            $newTaskConfigList = @()
            $configItemCount = 0
            $configChanged = $false
            foreach ($item in @($config)) {
                if ($item -isnot [PSCustomObject]) { continue; }
                $configItemCount += 1
                $itemOriginalJson = ConvertTo-Json -InputObject $item -Depth 10 -Compress

                # 任务名称：不能为空，不能包含任何无法作为 Windows 文件名的字符，不能重复
                if ($item.PSObject.Properties.Match('name').Count -eq 0) {
                    System-Log ($ui.ERROR_FieldMissing -f 'name') "Warning"
                    continue
                }
                $taskName = [string]$item.name
                if (-not $taskName) {
                    System-Log ($ui.ERROR_NameEmpty) "Warning"
                    continue
                }
                $taskName = $taskName.Trim()
                if (-not $taskName) {
                    System-Log ($ui.ERROR_NameEmpty) "Warning"
                    continue
                }
                $invalidFileNameChars = [System.IO.Path]::GetInvalidFileNameChars()
                if ($taskName.IndexOfAny($invalidFileNameChars) -ge 0) {
                    System-Log ($ui.ERROR_NameInvalid -f $taskName) "Warning"
                    continue
                }
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
                $item.name = $taskName
                $seenNames.Add($taskName) | Out-Null

                # 命令：不能为空
                if ($item.PSObject.Properties.Match('command').Count -eq 0) {
                    System-Log ($ui.ERROR_FieldMissing -f 'command') "Warning"
                    continue
                }
                $commandValue = [string]$item.command
                if (-not $commandValue) {
                    System-Log ($ui.ERROR_CommandEmpty) "Warning"
                    continue
                }
                $commandValue = $commandValue.Trim()
                if (-not $commandValue) {
                    System-Log ($ui.ERROR_CommandEmpty) "Warning"
                    continue
                }
                $item.command = $commandValue

                # 参数：不能为 $null
                if ($item.PSObject.Properties.Match('arguments').Count -eq 0) {
                    System-Log ($ui.ERROR_FieldMissing -f 'arguments') "Warning"
                    continue
                }
                if ($null -eq $item.arguments) {
                    System-Log ($ui.ERROR_FieldMissing -f 'arguments') "Warning"
                    continue
                }
                $argumentsValue = [string]$item.arguments
                $argumentsValue = $argumentsValue.Trim()
                $item.arguments = $argumentsValue

                # 工作目录：不能为 $null
                if ($item.PSObject.Properties.Match('workingDirectory').Count -eq 0) {
                    System-Log ($ui.ERROR_FieldMissing -f 'workingDirectory') "Warning"
                    continue
                }
                if ($null -eq $item.workingDirectory) {
                    System-Log ($ui.ERROR_FieldMissing -f 'workingDirectory') "Warning"
                    continue
                }
                $workingDirectoryValue = [string]$item.workingDirectory
                $workingDirectoryValue = $workingDirectoryValue.Trim()
                $item.workingDirectory = $workingDirectoryValue

                # 是否自动启动：不能为 $null
                if ($item.PSObject.Properties.Match('autoStart').Count -eq 0) {
                    System-Log ($ui.ERROR_FieldMissing -f 'autoStart') "Warning"
                    continue
                }
                if ($null -eq $item.autoStart) {
                    System-Log ($ui.ERROR_FieldMissing -f 'autoStart') "Warning"
                    continue
                }
                $autoStartValue = [bool]$item.autoStart
                $item.autoStart = $autoStartValue

                $newTaskConfigList += $item
                if ((ConvertTo-Json -InputObject $item -Depth 10 -Compress) -cne $itemOriginalJson) {
                    $configChanged = $true
                }
            }
            $script:taskConfigList = $newTaskConfigList
            Update-Task-Grid
            if ($configChanged -or $newTaskConfigList.Count -ne $configItemCount) {
                Save-Config
            }
        } catch {
            System-Log ($ui.INFO_ConfigLoadFailed -f $_.Exception.Message) "Error"
            return $false
        }
        System-Log ($ui.INFO_ConfigLoaded -f $taskConfigList.Count) "Success"
        return $true
    }

    # 任务列表展示表格
    $taskGridView = $null

    # 获取任务列表展示表格当前选中的行，对应的序号
    function Get-Selected-Task-Index {
        if ($taskGridView.SelectedRows.Count -eq 0) { return -1 }
        return $taskGridView.SelectedRows[0].Index
    }

    # 任务运行实例列表
    $taskExecutionMap = @{}

    # 获取任务的运行实例，不存在时自动创建
    function Get-Task-Execution {
        param([string]$TaskName)

        if (-not $taskExecutionMap.ContainsKey($TaskName)) {
            $taskExecutionMap[$TaskName] = @{
                process = $null
                status = $ui.StatusNotStarted
                logViewContent = [System.Text.StringBuilder]::new()
                logFilePath = [System.IO.Path]::Combine($myBatchTaskLogsDir, $TaskName + ".log")
                logFileWriter = $null
                logViewTextBox = $null
                StandardOutputReader = $null
                StandardErrorReader = $null
                RunspacePool = $null
            }
        }
        return $taskExecutionMap[$TaskName]
    }

    # 刷新任务列表展示表格，刷新全部
    function Update-Task-Grid {
        if ($null -eq $taskGridView -or $taskGridView.IsDisposed) {
            return
        }

        $taskGridView.SuspendLayout()
        try {
            $taskGridView.Rows.Clear()
            for ($i = 0; $i -lt $taskConfigList.Count; $i++) {
                $task = $taskConfigList[$i]
                $taskName = $task.name

                $statusText = $ui.StatusNotStarted
                $pidText = ""
                $execution = Get-Task-Execution -TaskName ([string]$taskName)
                if ($execution.status) {
                    $statusText = $execution.status
                }
                if ($execution.process -and -not $execution.process.HasExited) {
                    $pidText = [string]$execution.process.Id
                }

                $taskGridView.Rows.Add($statusText, $pidText, [string]$task.name, [string]$task.command, [string]$task.arguments, [string]$task.workingDirectory) | Out-Null
            }
        }
        finally {
            $taskGridView.ResumeLayout()
        }
    }

    # 刷新任务列表展示表格，只刷新指定任务名的行
    function Update-Task-Grid-Row {
        param([string]$TaskName)

        $index = -1
        for ($i = 0; $i -lt $taskConfigList.Count; $i++) {
            if ([string]$taskConfigList[$i].name -eq $TaskName) {
                $index = $i
                break
            }
        }
        if ($index -lt 0 -or $index -ge $taskGridView.Rows.Count) {
            return
        }

        # 直接用入参 $TaskName 查运行时条目（PowerShell 变量名不区分大小写，这里不能再用同名局部变量覆盖入参）
        $statusText = $ui.StatusNotStarted
        $pidText = ""
        $execution = Get-Task-Execution -TaskName $TaskName
        if ($execution.status) {
            $statusText = $execution.status
        }
        if ($execution.process -and -not $execution.process.HasExited) {
            $pidText = [string]$execution.process.Id
        }

        $taskGridView.Rows[$index].Cells[0].Value = $statusText
        $taskGridView.Rows[$index].Cells[1].Value = $pidText
    }

    # 新增任务日志：刷新内存缓存 + 日志文件 + 日志展示框，按 Level 决定颜色
    function Append-Task-Log-Internal {
        param([string]$TaskName, [string]$Message, [string]$Level = 'Info')

        if (-not $taskExecutionMap.ContainsKey($TaskName)) { return }

        $logLine = "[{0}] {1}" -f $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message

        $execution = $taskExecutionMap[$TaskName]
        $execution.logViewContent.AppendLine($logLine) | Out-Null

        try {
            if ($execution.logFileWriter) {
                $execution.logFileWriter.WriteLine($logLine)
            } elseif ($execution.logFilePath) {
                [System.IO.File]::AppendAllText($execution.logFilePath, $logLine + "`r`n", $workingEncoding)
            }
        } catch {
            Handle-Exception $_
        }

        try {
            if ($null -eq $execution.logViewTextBox -or $execution.logViewTextBox.IsDisposed) {
                return
            }
            $execution.logViewTextBox.SuspendLayout()
            try {
                $execution.logViewTextBox.SelectionStart = $execution.logViewTextBox.TextLength
                $execution.logViewTextBox.SelectionLength = 0
                $execution.logViewTextBox.SelectionFont = $execution.logViewTextBox.Font
                $lineColor = if ($Level -eq 'Info') { [System.Drawing.Color]::Black } else { [System.Drawing.Color]::Red }
                $execution.logViewTextBox.SelectionColor = $lineColor
                $execution.logViewTextBox.AppendText($logLine + "`r`n")
                $execution.logViewTextBox.SelectionStart = $execution.logViewTextBox.TextLength
                $execution.logViewTextBox.ScrollToCaret()
            }
            finally {
                $execution.logViewTextBox.ResumeLayout()
            }
        } catch {
            Handle-Exception $_
        }
    }

    # 清空任务日志：清空内存缓存 + 日志展示框
    function Clear-Task-Log-Internal {
        param([string]$TaskName)

        if (-not $taskExecutionMap.ContainsKey($TaskName)) { return }

        $execution = $taskExecutionMap[$TaskName]
        $execution.logViewContent.Clear() | Out-Null

        try {
            if ($null -eq $execution.logViewTextBox -or $execution.logViewTextBox.IsDisposed) {
                return
            }
            $execution.logViewTextBox.Clear()
        } catch {
            Handle-Exception $_
        }
    }

    # 任务日志的异步队列，字段：{ TaskName; Message; Level }
    $taskLogAppendQueue = [System.Collections.Concurrent.ConcurrentQueue[hashtable]]::new()

    # 新增任务日志，投递到异步队列
    function Append-Task-Log {
        param([string]$TaskName, [string]$Message, [string]$Level = 'Info')
        $taskLogAppendQueue.Enqueue(@{ TaskName = $TaskName; Message = $Message; Level = $Level })
    }

    # 任务日志处理：按顺序处理队列
    function Process-Task-Log-Queue {
        $logItem = $null
        while ($taskLogAppendQueue.TryDequeue([ref]$logItem)) {
            Append-Task-Log-Internal -TaskName $logItem.TaskName -Message $logItem.Message -Level $logItem.Level
        }
    }

    # 启动任务（参数 $Task 为任务配置对象，即 $taskConfigList 中的一个元素）
    function Start-Task {
        param([PSCustomObject]$Task)

        if ($null -eq $Task) { return }
        $taskName = [string]$Task.name
        $execution = Get-Task-Execution -TaskName $taskName
        if ($execution.process -and -not $execution.process.HasExited) {
            System-Log ($ui.INFO_AlreadyRunning -f $taskName) "Warning"
            return
        }
        if ($execution.process) {
            Release-Task-Resources -TaskName $taskName
        }

        $commandText = [System.Environment]::ExpandEnvironmentVariables([string]$Task.command)
        $argumentText = [System.Environment]::ExpandEnvironmentVariables([string]$Task.arguments)
        $workingDirText = [System.Environment]::ExpandEnvironmentVariables([string]$Task.workingDirectory)

        # 把命令解析为真实文件路径
        $resolvedCommand = $commandText
        if (-not [System.IO.File]::Exists($resolvedCommand)) {
            $resolvedItem = Get-Command $commandText -ErrorAction SilentlyContinue
            if ($resolvedItem -and $resolvedItem.Source) {
                $resolvedCommand = [string]$resolvedItem.Source
            }
        }

        $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = $resolvedCommand
        $startInfo.Arguments = $argumentText

        # 根据文件扩展名，选择合适的启动方式，支持 .bat/.cmd/.ps1/.py 后缀
        $commandExtension = [System.IO.Path]::GetExtension($resolvedCommand).ToLower()
        if ($commandExtension -eq ".bat" -or $commandExtension -eq ".cmd") {
            $startInfo.FileName = $env:ComSpec
            $startInfo.Arguments = '/s /c ""' + $resolvedCommand + '" ' + $argumentText + '"'
        } elseif ($commandExtension -eq ".ps1") {
            $powerShellExe = 'powershell.exe'
            $resolvedPowerShell = Get-Command $powerShellExe -ErrorAction SilentlyContinue
            if ($resolvedPowerShell -and $resolvedPowerShell.Source) {
                $powerShellExe = [string]$resolvedPowerShell.Source
            }
            $startInfo.FileName = $powerShellExe
            $startInfo.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $resolvedCommand + '" ' + $argumentText
        } elseif ($commandExtension -eq ".py") {
            $pythonExe = 'python.exe'
            $resolvedPython = Get-Command $pythonExe -ErrorAction SilentlyContinue
            if ($resolvedPython -and $resolvedPython.Source) {
                $pythonExe = [string]$resolvedPython.Source
            }
            $startInfo.FileName = $pythonExe
            $startInfo.Arguments = '"' + $resolvedCommand + '" ' + $argumentText
        }

        # 工作目录为空时，自动取命令文件的父目录
        if ([string]::IsNullOrEmpty($workingDirText)) {
            $workingDirText = [System.IO.Path]::GetDirectoryName($resolvedCommand)
        }
        if (-not [System.IO.Directory]::Exists($workingDirText)) {
            System-Log ($ui.ERROR_WorkDirNotFound -f $workingDirText) "Error"
            return
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

        $execution.process = $process
        $execution.status = $ui.StatusRunning
        try {
            $logFileStream = [System.IO.File]::Open($execution.logFilePath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
            $execution.logFileWriter = [System.IO.StreamWriter]::new($logFileStream, $workingEncoding)
            $execution.logFileWriter.AutoFlush = $true
        } catch {
            Handle-Exception $_
        }

        $readerScript = {
            param($Reader, $Queue, $TaskName, $Level)
            try {
                while ($true) {
                    $line = $Reader.ReadLine()
                    if ($null -eq $line) { break }
                    $Queue.Enqueue(@{ TaskName = $TaskName; Message = $line; Level = $Level })
                }
            } catch {}
        }

        $readerRunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(2, 2)
        $readerRunspacePool.Open()
        # 标准输出读取
        $stdoutReaderPs = [System.Management.Automation.PowerShell]::Create()
        $stdoutReaderPs.RunspacePool = $readerRunspacePool
        $stdoutReaderPs.AddScript($readerScript) | Out-Null
        $stdoutReaderPs.AddParameter('Reader', $process.StandardOutput)
        $stdoutReaderPs.AddParameter('Queue', $taskLogAppendQueue)
        $stdoutReaderPs.AddParameter('TaskName', $taskName)
        $stdoutReaderPs.AddParameter('Level', 'Info')
        $stdoutReaderPs.BeginInvoke() | Out-Null
        $execution.StandardOutputReader = $stdoutReaderPs
        # 标准错误读取
        $stderrReaderPs = [System.Management.Automation.PowerShell]::Create()
        $stderrReaderPs.RunspacePool = $readerRunspacePool
        $stderrReaderPs.AddScript($readerScript) | Out-Null
        $stderrReaderPs.AddParameter('Reader', $process.StandardError)
        $stderrReaderPs.AddParameter('Queue', $taskLogAppendQueue)
        $stderrReaderPs.AddParameter('TaskName', $taskName)
        $stderrReaderPs.AddParameter('Level', 'Error')
        $stderrReaderPs.BeginInvoke() | Out-Null
        $execution.StandardErrorReader = $stderrReaderPs
        $execution.RunspacePool = $readerRunspacePool

        Append-Task-Log -TaskName $taskName -Message $ui.LogTaskStart
        Update-Task-Grid-Row -TaskName $taskName
        System-Log ($ui.INFO_Started -f $taskName, $process.Id) "Success"
    }

    # 释放任务的运行资源
    function Release-Task-Resources {
        param([string]$TaskName)

        if (-not $taskExecutionMap.ContainsKey($TaskName)) { return }
        $execution = $taskExecutionMap[$TaskName]

        if ($execution.logFileWriter) {
            try { $execution.logFileWriter.Dispose() } catch {}
        }
        foreach ($taskReader in @($execution.StandardOutputReader, $execution.StandardErrorReader)) {
            if ($null -eq $taskReader) { continue }
            try { $taskReader.Stop() } catch {}
            try { $taskReader.Dispose() } catch {}
        }
        if ($execution.RunspacePool) {
            try { $execution.RunspacePool.Close() } catch {}
            try { $execution.RunspacePool.Dispose() } catch {}
        }

        $execution.logFileWriter = $null
        $execution.StandardOutputReader = $null
        $execution.StandardErrorReader = $null
        $execution.RunspacePool = $null
    }

    # 停止任务（参数 $Task 为任务配置对象，即 $taskConfigList 中的一个元素）
    function Stop-Task {
        param([PSCustomObject]$Task)

        if ($null -eq $Task) { return }
        $taskName = [string]$Task.name
        $execution = Get-Task-Execution -TaskName $taskName
        if (-not $execution.process) {
            System-Log ($ui.INFO_NotStarted -f $taskName) "Warning"
            return
        }
        if ($execution.process.HasExited) {
            System-Log ($ui.INFO_AlreadyStopped -f $taskName) "Warning"
            return
        }

        try {
            $killInfo = [System.Diagnostics.ProcessStartInfo]::new()
            $killInfo.FileName = "taskkill.exe"
            $killInfo.Arguments = "/pid $($execution.process.Id) /t /f"
            $killInfo.UseShellExecute = $false
            $killInfo.CreateNoWindow = $true
            $killProcess = [System.Diagnostics.Process]::Start($killInfo)
            if ($killProcess.WaitForExit(10000)) {
                if ($killProcess.ExitCode -ne 0) {
                    if ($execution.process.HasExited) {
                        System-Log ($ui.INFO_AlreadyStopped -f $taskName) "Warning"
                    } else {
                        System-Log ($ui.ERROR_TaskStopFailed -f $taskName) "Error"
                        return
                    }
                }
            } else {
                System-Log ($ui.ERROR_TaskStopTimeout -f $taskName) "Warning"
            }
        } catch {
            System-Log ($ui.ERROR_TaskStopFailed -f $_.Exception.Message) "Error"
        } finally {
            if ($killProcess) { $killProcess.Dispose() }
        }
        if (-not $execution.process.WaitForExit(5000)) {
            System-Log ($ui.ERROR_TaskStopTimeout -f $taskName) "Warning"
            return
        }

        $execution.status = $ui.StatusStopped
        Release-Task-Resources -TaskName $taskName
        Update-Task-Grid-Row -TaskName $taskName
        System-Log ($ui.INFO_Stopped -f $taskName) "Info"
        Append-Task-Log -TaskName $taskName -Message $ui.LogTaskStopManual
    }

    # 监视任务状态：如果进程退出，更新状态并释放相关资源
    function Monitor-Task-Status {
        for ($i = 0; $i -lt $taskConfigList.Count; $i++) {
            $task = $taskConfigList[$i]
            $taskName = [string]$task.name
            $execution = Get-Task-Execution -TaskName $taskName

            if (-not $execution.process) { continue }
            if ($execution.status -eq $ui.StatusRunning) {
                if ($execution.process.HasExited) {
                    if ($execution.process.ExitCode -eq 0) {
                        $execution.status = $ui.StatusExited
                        $taskEndMessage = ($ui.LogTaskEndNormal -f $execution.process.ExitCode)
                    } else {
                        $execution.status = $ui.StatusExitedError
                        $taskEndMessage = ($ui.LogTaskEndError -f $execution.process.ExitCode)
                    }
                    Release-Task-Resources -TaskName $taskName
                    Update-Task-Grid-Row -TaskName $taskName
                    System-Log ($ui.INFO_Exited -f $taskName, $execution.process.ExitCode) "Warning"
                    Append-Task-Log -TaskName $taskName -Message $taskEndMessage
                }
            }
        }
    }

    # 重启任务
    function Restart-Task {
        param([PSCustomObject]$Task)
        Stop-Task -Task $Task
        Start-Task -Task $Task
    }

    # 启动全部任务
    function Start-All-Tasks {
        foreach ($task in $taskConfigList) {
            Start-Task -Task $task
        }
        System-Log $ui.INFO_StartAllDone "Success"
    }

    # 停止全部任务
    function Stop-All-Tasks {
        foreach ($task in $taskConfigList) {
            Stop-Task -Task $task
        }
        System-Log $ui.INFO_StopAllDone "Info"
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
    $mainForm.Font = [System.Drawing.Font]::new("Microsoft YaHei", 10)
    $mainForm.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
    $mainForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    $mainForm.Opacity = 0
    $mainForm.ShowInTaskbar = $false

    # 启用双缓冲减少闪烁
    Enable-Double-Buffered $mainForm | Out-Null

    # 主窗口首次显示: 隐藏到托盘 + 自动启动任务
    $mainForm.Add_Shown({
        param($EventSender, $EventArgs)
        $EventSender.Hide()
        for ($i = 0; $i -lt $taskConfigList.Count; $i++) {
            $task = $taskConfigList[$i]
            $needStart = [bool]$task.autoStart
            if ($needStart) {
                Start-Task -Task $task
            }
        }
    })

    # 从托盘图标点击，显示主窗口
    function Show-Main-Window {
        $mainForm.Opacity = 1
        $mainForm.ShowInTaskbar = $true
        $mainForm.Show()
        $mainForm.WindowState = [System.Windows.Forms.FormWindowState]::Normal
        $mainForm.Activate()
    }

    # 从托盘图标点击，隐藏主窗口
    function Hide-Main-Window {
        $mainForm.Opacity = 0
        $mainForm.ShowInTaskbar = $false
        $mainForm.Hide()
    }

    # 是否真正退出程序，默认 $false，只隐藏主窗口
    $mainFormRealExit = $false

    # 主窗口关闭事件
    $mainForm.Add_FormClosing({
        param($EventSender, $EventArgs)
        if (-not $mainFormRealExit) {
            $EventArgs.Cancel = $true
            $EventSender.Opacity = 0
            $EventSender.ShowInTaskbar = $false
            $EventSender.Hide()
        }
    })

    # 绘制图标 Bitmap，使用蓝色圆形 + 白色 M 字样
    $trayBitmap = [System.Drawing.Bitmap]::new(32, 32)
    $trayGraphics = [System.Drawing.Graphics]::FromImage($trayBitmap)
    $trayGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $trayGraphics.Clear([System.Drawing.Color]::Transparent)
    $trayBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(91, 155, 213))
    $trayGraphics.FillEllipse($trayBrush, 1, 1, 30, 30)
    $trayFont = [System.Drawing.Font]::new($mainForm.Font.FontFamily, 15, [System.Drawing.FontStyle]::Bold)
    $trayFormat = [System.Drawing.StringFormat]::new()
    $trayFormat.Alignment = [System.Drawing.StringAlignment]::Center
    $trayFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
    $trayRect = [System.Drawing.RectangleF]::new(0, 2, 32, 28)
    $trayGraphics.DrawString("M", $trayFont, [System.Drawing.Brushes]::White, $trayRect, $trayFormat)
    try { $trayBrush.Dispose() } catch { }
    try { $trayFont.Dispose() } catch { }
    try { $trayFormat.Dispose() } catch { }
    try { $trayRect.Dispose() } catch { }
    try { $trayGraphics.Dispose() } catch { }

    # 托盘图标和主窗口图标
    $appWindowIcon = [System.Drawing.Icon]::FromHandle($trayBitmap.GetHicon())
    $trayIcon = [System.Windows.Forms.NotifyIcon]::new()
    $trayIcon.Icon = $appWindowIcon
    $trayIcon.Text = $ui.FormTitle
    $trayIcon.Visible = $true
    $mainForm.Icon = $appWindowIcon.Clone()

    # 托盘图标：单击切换主窗口的显示/隐藏
    $trayIcon.Add_MouseClick({
        param($EventSender, $EventArgs)
        if ($EventArgs.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            if ($mainForm.Visible) {
                Hide-Main-Window
            } else {
                Show-Main-Window
            }
        }
    })

    # 托盘图标：双击显示主窗口
    $trayIcon.Add_MouseDoubleClick({
        param($EventSender, $EventArgs)
        if ($EventArgs.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            Show-Main-Window
        }
    })

    # 托盘图标右键菜单：显示主界面 / 全部启动 / 全部停止 / 退出
    $trayShowItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $trayShowItem.Text = $ui.TrayShow
    $trayShowItem.Add_Click({ Show-Main-Window })
    $trayStartAllItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $trayStartAllItem.Text = $ui.TrayStartAll
    $trayStartAllItem.Add_Click({ Start-All-Tasks })
    $trayStopAllItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $trayStopAllItem.Text = $ui.TrayStopAll
    $trayStopAllItem.Add_Click({ Stop-All-Tasks })
    $trayExitItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $trayExitItem.Text = $ui.TrayExit
    $trayExitItem.Add_Click({
        $confirmResult = [System.Windows.Forms.MessageBox]::Show($ui.ConfirmExit, $ui.ConfirmTitle, "YesNo", "Question")
        if ($confirmResult -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        $script:mainFormRealExit = $true
        try { $trayIcon.Visible = $false } catch { }
        try { $trayIcon.Dispose() } catch { }
        try { $mainForm.Close() } catch { }
    })
    $trayMenu = [System.Windows.Forms.ContextMenuStrip]::new()
    foreach ($item in @($trayShowItem, $trayStartAllItem, $trayStopAllItem, $trayExitItem)) {
        $trayMenu.Items.Add($item) | Out-Null
    }
    $trayIcon.ContextMenuStrip = $trayMenu

    # 标签页容器
    $tabControl = [System.Windows.Forms.TabControl]::new()
    $tabControl.Dock = "Fill"
    $tabControl.Padding = [System.Drawing.Point]::new(20, 10)
    $tabControl.Font = $mainForm.Font
    $mainForm.Controls.Add($tabControl)

    # 当前的标签页
    $tabControlCurrentTab = $null

    # 标签页右键菜单：关闭标签页
    $tabContextMenu = [System.Windows.Forms.ContextMenuStrip]::new()
    $closeTabMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $closeTabMenuItem.Text = $ui.CloseTab
    $closeTabMenuItem.Add_Click({
        if (-not $tabControlCurrentTab -or $tabControlCurrentTab.IsDisposed) { return }
        $tabName = $tabControlCurrentTab.Name
        if ($tabName.StartsWith("LogPage_")) {
            $taskName = $tabName.Substring(8)
            if ($taskExecutionMap.ContainsKey($taskName)) {
                $script:taskExecutionMap[$taskName].logViewTextBox = $null
            }
        }
        $tabControl.TabPages.Remove($tabControlCurrentTab)
        $tabControlCurrentTab.Dispose()
        $script:tabControlCurrentTab = $null
    })
    $tabContextMenu.Items.Add($closeTabMenuItem) | Out-Null
    $tabControl.ContextMenuStrip = $tabContextMenu

    # 标签页右键点击后，根据点击位置，查找并记录当前的标签页
    $tabControl.Add_MouseDown({
        param($EventSender, $EventArgs)
        if ($EventArgs.Button -ne [System.Windows.Forms.MouseButtons]::Right) { return }
        $script:tabControlCurrentTab = $null
        for ($i = 0; $i -lt $tabControl.TabPages.Count; $i++) {
            $tabRect = $tabControl.GetTabRect($i)
            if ($tabRect.Contains($EventArgs.Location)) {
                $script:tabControlCurrentTab = $tabControl.TabPages[$i]
                # 前两个固定标签页不可关闭
                $closeTabMenuItem.Enabled = ($i -ge 2)
                return
            }
        }
        $closeTabMenuItem.Enabled = $false
    })

    # 打开任务日志标签页，不存在时创建，已存在则直接切换
    function Show-Task-Log-Viewer {
        param([string]$TaskName)

        $logViewTabPageName = "LogPage_" + $TaskName
        $existingLogViewTabPage = $tabControl.TabPages[$logViewTabPageName]
        if ($existingLogViewTabPage) {
            $tabControl.SelectedTab = $existingLogViewTabPage
            return
        }

        $execution = Get-Task-Execution -TaskName $TaskName
        $logViewTabPage = [System.Windows.Forms.TabPage]::new()
        $logViewTabPage.Name = $logViewTabPageName
        $logViewTabPage.Text = $TaskName
        $logViewTabPage.BackColor = [System.Drawing.Color]::White

        # 日志文本框
        $logViewTextBox = [System.Windows.Forms.RichTextBox]::new()
        $logViewTextBox.ReadOnly = $true
        $logViewTextBox.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
        $logViewTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
        $logViewTextBox.BackColor = [System.Drawing.Color]::White
        $logViewTextBox.WordWrap = $false
        $logViewTextBox.Font = $mainForm.Font
        $logViewTextBox.DetectUrls = $false
        $logViewTextBox.Dock = "Fill"
        $logViewTabPage.Controls.Add($logViewTextBox)

        # 日志文本框右键菜单: 复制日志 / 清空日志 / 打开日志文件
        $logViewContextMenu = [System.Windows.Forms.ContextMenuStrip]::new()
        $logViewCopyItem = [System.Windows.Forms.ToolStripMenuItem]::new()
        $logViewCopyItem.Text = $ui.LogCopy
        $logViewCopyItem.Tag = @{ taskName = $TaskName }
        $logViewCopyItem.Add_Click({
            param($MenuItem, $EventArgs)
            $logViewTextBox = (Get-Task-Execution -TaskName ([string]$MenuItem.Tag.taskName)).logViewTextBox
            if ($null -eq $logViewTextBox -or $logViewTextBox.IsDisposed) {
                System-Log $ui.INFO_NoLog "Warning"
                return
            }
            if ($logViewTextBox.Text.Length -gt 0) {
                [System.Windows.Forms.Clipboard]::SetText($logViewTextBox.Text)
                System-Log $ui.INFO_LogCopied "Success"
            } else {
                System-Log $ui.INFO_NoLog "Warning"
            }
        })
        $logViewClearItem = [System.Windows.Forms.ToolStripMenuItem]::new()
        $logViewClearItem.Text = $ui.LogClear
        $logViewClearItem.Tag = @{ taskName = $TaskName }
        $logViewClearItem.Add_Click({
            param($MenuItem, $EventArgs)
            Clear-Task-Log-Internal -TaskName ([string]$MenuItem.Tag.taskName)
        })
        $logViewOpenItem = [System.Windows.Forms.ToolStripMenuItem]::new()
        $logViewOpenItem.Text = $ui.LogOpenFile
        $logViewOpenItem.Tag = @{ taskName = $TaskName }
        $logViewOpenItem.Add_Click({
            param($MenuItem, $EventArgs)
            $execution = Get-Task-Execution -TaskName ([string]$MenuItem.Tag.taskName)
            if ($execution.logFilePath -and [System.IO.File]::Exists($execution.logFilePath)) {
                Start-Process "explorer.exe" -ArgumentList ('/select,"' + $execution.logFilePath + '"')
                System-Log ($ui.INFO_LogOpened -f $execution.logFilePath) "Success"
            } else {
                System-Log $ui.INFO_NoLog "Warning"
            }
        })
        $logViewContextMenu.Items.Add($logViewCopyItem) | Out-Null
        $logViewContextMenu.Items.Add($logViewClearItem) | Out-Null
        $logViewContextMenu.Items.Add($logViewOpenItem) | Out-Null
        $logViewTextBox.ContextMenuStrip = $logViewContextMenu

        # 载入历史日志
        $logViewTextBox.SelectionStart = $logViewTextBox.TextLength
        $logViewTextBox.SelectionLength = 0
        $logViewTextBox.SelectionFont = $logViewTextBox.Font
        $logViewTextBox.SelectionColor = [System.Drawing.Color]::Black
        $logViewTextBox.AppendText($execution.logViewContent.ToString())
        $logViewTextBox.SelectionStart = $logViewTextBox.TextLength
        $logViewTextBox.ScrollToCaret()

        $execution.logViewTextBox = $logViewTextBox
        $tabControl.TabPages.Add($logViewTabPage)
        $tabControl.SelectedTab = $logViewTabPage
    }

    # 新增/修改任务的对话框，指定 $TaskName 参数时修改，不指定参数时新增，返回 DialogResult
    function Edit-Task-Dialog {
        param([string]$TaskName = '')

        $editIndex = -1
        if ($TaskName) {
            for ($i = 0; $i -lt $taskConfigList.Count; $i++) {
                if ([string]$taskConfigList[$i].name -eq $TaskName) {
                    $editIndex = $i
                    break
                }
            }
        }

        # 如果修改的任务正在运行，保存后要重启任务
        $willRestart = $false
        if ($editIndex -ge 0) {
            $editExecution = Get-Task-Execution -TaskName $TaskName
            if ($editExecution.process -and -not $editExecution.process.HasExited) {
                $willRestart = $true
            }
        }

        # 对话框窗体
        $dialogForm = [System.Windows.Forms.Form]::new()
        $dialogForm.Text = if ($editIndex -ge 0) { $ui.DialogEditTitle } else { $ui.DialogAddTitle }
        $dialogForm.Size = [System.Drawing.Size]::new(750, 550)
        $dialogForm.FormBorderStyle = "FixedDialog"
        $dialogForm.StartPosition = "CenterParent"
        $dialogForm.MaximizeBox = $false
        $dialogForm.MinimizeBox = $false
        $dialogForm.ShowInTaskbar = $false
        $dialogForm.Font = $mainForm.Font
        $dialogForm.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
        $dialogForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
        function New-Dialog-Label {
            param([string]$Text, [int]$Top)
            $label = [System.Windows.Forms.Label]::new()
            $label.Text = $Text
            $label.Location = [System.Drawing.Point]::new(36, $Top + 4)
            $label.Size = [System.Drawing.Size]::new(100, 28)
            $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
            $dialogForm.Controls.Add($label)
        }
        function New-Dialog-TextBox {
            param([int]$Top)
            $textBox = [System.Windows.Forms.TextBox]::new()
            $textBox.Location = [System.Drawing.Point]::new(146, $Top)
            $textBox.Size = [System.Drawing.Size]::new(428, 30)
            $textBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
            $dialogForm.Controls.Add($textBox)
            return $textBox
        }
        # 任务名称
        New-Dialog-Label $ui.DialogName 36
        $nameBox = New-Dialog-TextBox 36
        # 任务命令
        New-Dialog-Label $ui.DialogCommand 96
        $commandBox = New-Dialog-TextBox 96
        $browseCommandButton = [System.Windows.Forms.Button]::new()
        $browseCommandButton.Text = $ui.DialogBrowseCommand
        $browseCommandButton.Location = [System.Drawing.Point]::new(584, 92)
        $browseCommandButton.Size = [System.Drawing.Size]::new(120, 42)
        $browseCommandButton.FlatStyle = "Flat"
        $browseCommandButton.BackColor = [System.Drawing.Color]::FromArgb(241, 243, 245)
        $browseCommandButton.ForeColor = [System.Drawing.Color]::Black
        $browseCommandButton.FlatAppearance.BorderSize = 0
        $browseCommandButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(226, 228, 230)
        $browseCommandButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(206, 208, 210)
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
        $dialogForm.Controls.Add($browseCommandButton)
        # 任务参数
        New-Dialog-Label $ui.DialogArguments 156
        $argumentsBox = New-Dialog-TextBox 156
        # 任务工作目录
        New-Dialog-Label $ui.DialogWorkingDir 216
        $workingDirBox = New-Dialog-TextBox 216
        $browseDirButton = [System.Windows.Forms.Button]::new()
        $browseDirButton.Text = $ui.DialogBrowseDir
        $browseDirButton.Location = [System.Drawing.Point]::new(584, 212)
        $browseDirButton.Size = [System.Drawing.Size]::new(120, 42)
        $browseDirButton.FlatStyle = "Flat"
        $browseDirButton.BackColor = [System.Drawing.Color]::FromArgb(241, 243, 245)
        $browseDirButton.ForeColor = [System.Drawing.Color]::Black
        $browseDirButton.FlatAppearance.BorderSize = 0
        $browseDirButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(226, 228, 230)
        $browseDirButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(206, 208, 210)
        $browseDirButton.Add_Click({
            $folderDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
            $folderDialog.Description = $ui.DialogBrowseDirTitle
            $folderDialog.SelectedPath = $workingDirectory
            if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $workingDirBox.Text = $folderDialog.SelectedPath
            }
        })
        $dialogForm.Controls.Add($browseDirButton)
        # 任务启动方式：radio 单选，管理器启动时自动运行 / 手动执行
        New-Dialog-Label $ui.DialogStartMode 276
        $autoStartRadioButton = [System.Windows.Forms.RadioButton]::new()
        $autoStartRadioButton.Text = $ui.DialogAutoStart
        $autoStartRadioButton.Location = [System.Drawing.Point]::new(146, 280)
        $autoStartRadioButton.Size = [System.Drawing.Size]::new(240, 28)
        $autoStartRadioButton.Checked = $true
        $dialogForm.Controls.Add($autoStartRadioButton)
        $manualStartRadioButton = [System.Windows.Forms.RadioButton]::new()
        $manualStartRadioButton.Text = $ui.DialogManualStart
        $manualStartRadioButton.Location = [System.Drawing.Point]::new(420, 280)
        $manualStartRadioButton.Size = [System.Drawing.Size]::new(240, 28)
        $dialogForm.Controls.Add($manualStartRadioButton)

        # 修改模式时填充原始值
        $originalName = ""
        if ($editIndex -ge 0) {
            $task = $taskConfigList[$editIndex]
            $originalName = [string]$task.name
            $nameBox.Text = $originalName
            $commandBox.Text = [string]$task.command
            $argumentsBox.Text = [string]$task.arguments
            $workingDirBox.Text = [string]$task.workingDirectory
            $autoStartRadioButton.Checked = [bool]$task.autoStart
            $manualStartRadioButton.Checked = -not [bool]$task.autoStart
        }

        # 确定按钮
        $okButton = [System.Windows.Forms.Button]::new()
        $okButton.Text = if ($willRestart) { $ui.DialogSaveRestart } else { $ui.DialogSave }
        $okButton.Location = [System.Drawing.Point]::new(190, 400)
        $okButton.Size = [System.Drawing.Size]::new(180, 46)
        $okButton.FlatStyle = "Flat"
        $okButton.BackColor = [System.Drawing.Color]::FromArgb(91, 155, 213)
        $okButton.ForeColor = [System.Drawing.Color]::White
        $okButton.FlatAppearance.BorderSize = 0
        $okButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(71, 135, 193)
        $okButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(51, 115, 173)
        $okButton.Add_Click({
            $newName = $nameBox.Text.Trim()
            $newCommand = $commandBox.Text.Trim()
            $newArguments = $argumentsBox.Text.Trim()
            $newWorkingDir = $workingDirBox.Text.Trim()

            # 任务名称：不能为空，不能包含任何无法作为 Windows 文件名的字符，不能重复
            $invalidFileNameChars = [System.IO.Path]::GetInvalidFileNameChars()
            if (-not $newName) {
                [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NameEmpty, $ui.FormTitle, "OK", "Warning") | Out-Null
                return
            }
            if ($newName.IndexOfAny($invalidFileNameChars) -ge 0) {
                [System.Windows.Forms.MessageBox]::Show(($ui.ERROR_NameInvalid -f $newName), $ui.FormTitle, "OK", "Warning") | Out-Null
                return
            }
            if (-not $newCommand) {
                [System.Windows.Forms.MessageBox]::Show($ui.ERROR_CommandEmpty, $ui.FormTitle, "OK", "Warning") | Out-Null
                return
            }
            for ($i = 0; $i -lt $taskConfigList.Count; $i++) {
                if ($i -eq $editIndex) { continue }
                if ([string]$taskConfigList[$i].name -ieq $newName) {
                    [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NameDuplicated -f $newName, $ui.FormTitle, "OK", "Warning") | Out-Null
                    return
                }
            }

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

            $newTask = [PSCustomObject]@{
                name = $newName
                command = $newCommand
                arguments = $newArguments
                workingDirectory = $newWorkingDir
                autoStart = $autoStartRadioButton.Checked
            }
            if ($editIndex -ge 0) {
                $script:taskConfigList[$editIndex] = $newTask
                if ($originalName -ine $newName -and $taskExecutionMap.ContainsKey($originalName)) {
                    $oldRuntime = $taskExecutionMap[$originalName]
                    # 移除旧的日志标签页
                    $oldLogViewTabPageName = "LogPage_" + $originalName
                    $oldLogViewTabPage = $tabControl.TabPages[$oldLogViewTabPageName]
                    if ($oldLogViewTabPage) {
                        $tabControl.TabPages.Remove($oldLogViewTabPage)
                        $oldLogViewTabPage.Dispose()
                    }
                    # 迁移运行时数据到新名称，日志文件同步改名
                    $newLogFilePath = [System.IO.Path]::Combine($myBatchTaskLogsDir, $newName + '.log')
                    if ($oldRuntime.logFilePath -and $oldRuntime.logFilePath -ne $newLogFilePath) {
                        $logWriterWasOpen = ($null -ne $oldRuntime.logFileWriter)
                        if ($logWriterWasOpen) {
                            try { $oldRuntime.logFileWriter.Dispose() } catch { }
                            $oldRuntime.logFileWriter = $null
                        }
                        if ([System.IO.File]::Exists($oldRuntime.logFilePath)) {
                            try {
                                [System.IO.File]::Move($oldRuntime.logFilePath, $newLogFilePath)
                            } catch { }
                        }
                        $oldRuntime.logFilePath = $newLogFilePath
                        if ($logWriterWasOpen) {
                            try {
                                $newLogFileStream = [System.IO.File]::Open($newLogFilePath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
                                $oldRuntime.logFileWriter = [System.IO.StreamWriter]::new($newLogFileStream, $workingEncoding)
                                $oldRuntime.logFileWriter.AutoFlush = $true
                            } catch { }
                        }
                    }
                    $script:taskExecutionMap[$newName] = $oldRuntime
                    $taskExecutionMap.Remove($originalName) | Out-Null
                }
            } else {
                $script:taskConfigList += $newTask
            }

            Save-Config
            Update-Task-Grid
            if ($willRestart) {
                Restart-Task -Task $script:taskConfigList[$editIndex]
            }
            $dialogForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $dialogForm.Close()
        })
        $dialogForm.Controls.Add($okButton)
        $dialogForm.AcceptButton = $okButton

        # 取消按钮
        $cancelButton = [System.Windows.Forms.Button]::new()
        $cancelButton.Text = $ui.DialogCancel
        $cancelButton.Location = [System.Drawing.Point]::new(384, 400)
        $cancelButton.Size = [System.Drawing.Size]::new(180, 46)
        $cancelButton.FlatStyle = "Flat"
        $cancelButton.BackColor = [System.Drawing.Color]::FromArgb(241, 243, 245)
        $cancelButton.ForeColor = [System.Drawing.Color]::Black
        $cancelButton.FlatAppearance.BorderSize = 0
        $cancelButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(226, 228, 230)
        $cancelButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(206, 208, 210)
        $cancelButton.Add_Click({
            $dialogForm.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $dialogForm.Close()
        })
        $dialogForm.Controls.Add($cancelButton)
        $dialogForm.CancelButton = $cancelButton

        $result = $dialogForm.ShowDialog($mainForm)
        $dialogForm.Dispose()
        return $result
    }

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
    $dataGridView.ColumnHeadersDefaultCellStyle.Font = [System.Drawing.Font]::new($mainForm.Font, [System.Drawing.FontStyle]::Bold)
    $dataGridView.ColumnHeadersHeight = 40
    $dataGridView.RowTemplate.Height = 32
    $dataGridView.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(241, 243, 245)
    $dataGridView.DefaultCellStyle.Font = $mainForm.Font
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
    $dataGridView.Columns[0].Width = 175
    $dataGridView.Columns[0].MinimumWidth = $dataGridView.Columns[0].Width / 2
    $dataGridView.Columns[1].Width = 125
    $dataGridView.Columns[1].MinimumWidth = $dataGridView.Columns[1].Width / 2
    $dataGridView.Columns[2].Width = 200
    $dataGridView.Columns[2].MinimumWidth = $dataGridView.Columns[2].Width / 2
    $dataGridView.Columns[3].Width = 400
    $dataGridView.Columns[3].MinimumWidth = $dataGridView.Columns[3].Width / 2
    $dataGridView.Columns[4].Width = 400
    $dataGridView.Columns[4].MinimumWidth = $dataGridView.Columns[4].Width / 2
    $dataGridView.Columns[5].Width = 300
    $dataGridView.Columns[5].MinimumWidth = $dataGridView.Columns[5].Width / 2
    $dataGridView.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
    $dataGridView.MultiSelect = $false
    $dataGridView.Add_CellMouseDown({
        param($EventSender, $EventArgs)
        if ($EventArgs.RowIndex -ge 0) {
            $dataGridView.ClearSelection()
            $dataGridView.Rows[$EventArgs.RowIndex].Selected = $true
            $dataGridView.CurrentCell = $dataGridView.Rows[$EventArgs.RowIndex].Cells[0]
        }
    })
    # 双击行查看任务日志（直接调用，不经过右键菜单，避免菜单项禁用时失效）
    $dataGridView.Add_CellDoubleClick({
        param($EventSender, $EventArgs)
        if ($EventArgs.RowIndex -lt 0 -or $EventArgs.RowIndex -ge $taskConfigList.Count) { return }
        Show-Task-Log-Viewer -TaskName ([string]$taskConfigList[$EventArgs.RowIndex].name)
    })
    $taskListTabPage.Controls.Add($dataGridView)
    $taskGridView = $dataGridView

    # 任务列表的右键菜单: 启动任务 / 停止任务 / 重启任务 / 查看日志 / 上移 / 下移 / 启动所有 / 停止所有 / 新增 / 编辑 / 删除
    $taskContextMenu = [System.Windows.Forms.ContextMenuStrip]::new()
    $menuStartItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuStartItem.Text = $ui.MenuStart
    $menuStartItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        Start-Task -Task $taskConfigList[$index]
    })
    $menuStopItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuStopItem.Text = $ui.MenuStop
    $menuStopItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        Stop-Task -Task $taskConfigList[$index]
    })
    $menuRestartItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuRestartItem.Text = $ui.MenuRestart
    $menuRestartItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        Restart-Task -Task $taskConfigList[$index]
    })
    $menuViewLogItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuViewLogItem.Text = $ui.MenuViewLog
    $menuViewLogItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        Show-Task-Log-Viewer -TaskName ([string]$taskConfigList[$index].name)
    })
    $menuMoveUpItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuMoveUpItem.Text = $ui.MenuMoveUp
    $menuMoveUpItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        if ($index -le 0) { return }
        $upper = $taskConfigList[$index - 1]
        $script:taskConfigList[$index - 1] = $script:taskConfigList[$index]
        $script:taskConfigList[$index] = $upper
        Save-Config
        Update-Task-Grid
        $dataGridView.Rows[$index - 1].Selected = $true
        $dataGridView.CurrentCell = $dataGridView.Rows[$index - 1].Cells[0]
    })
    $menuMoveDownItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuMoveDownItem.Text = $ui.MenuMoveDown
    $menuMoveDownItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        if ($index -ge ($taskConfigList.Count - 1)) { return }
        $lower = $taskConfigList[$index + 1]
        $script:taskConfigList[$index + 1] = $script:taskConfigList[$index]
        $script:taskConfigList[$index] = $lower
        Save-Config
        Update-Task-Grid
        $dataGridView.Rows[$index + 1].Selected = $true
        $dataGridView.CurrentCell = $dataGridView.Rows[$index + 1].Cells[0]
    })
    $menuSep1 = [System.Windows.Forms.ToolStripSeparator]::new()
    $menuStartAllItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuStartAllItem.Text = $ui.MenuStartAll
    $menuStartAllItem.Add_Click({ Start-All-Tasks })
    $menuStopAllItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuStopAllItem.Text = $ui.MenuStopAll
    $menuStopAllItem.Add_Click({ Stop-All-Tasks })
    $menuSep2 = [System.Windows.Forms.ToolStripSeparator]::new()
    $menuAddItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuAddItem.Text = $ui.MenuAdd
    $menuAddItem.Add_Click({ Edit-Task-Dialog -TaskName '' })
    $menuEditItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuEditItem.Text = $ui.MenuEdit
    $menuEditItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        $task = $taskConfigList[$index]
        $taskName = [string]$task.name
        $execution = Get-Task-Execution -TaskName $taskName
        if ($execution.process -and -not $execution.process.HasExited) {
            $confirmResult = [System.Windows.Forms.MessageBox]::Show($ui.ConfirmRestart -f $taskName, $ui.ConfirmTitle, "YesNo", "Question")
            if ($confirmResult -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        }
        Edit-Task-Dialog -TaskName $taskName | Out-Null
    })
    $menuDeleteItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuDeleteItem.Text = $ui.MenuDelete
    $menuDeleteItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        $taskName = [string]$taskConfigList[$index].name
        $confirmResult = [System.Windows.Forms.MessageBox]::Show($ui.ConfirmDelete -f $taskName, $ui.ConfirmTitle, "YesNo", "Question")
        if ($confirmResult -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        Stop-Task -Task $taskConfigList[$index]
        if ($taskExecutionMap.ContainsKey($taskName)) {
            $logViewTabPageName = "LogPage_" + $taskName
            $logViewTabPage = $tabControl.TabPages[$logViewTabPageName]
            if ($logViewTabPage) {
                $tabControl.TabPages.Remove($logViewTabPage)
                $logViewTabPage.Dispose()
            }
            $taskExecutionMap.Remove($taskName) | Out-Null
        }
        $newTasks = @()
        for ($i = 0; $i -lt $taskConfigList.Count; $i++) {
            if ($i -ne $index) { $newTasks += $taskConfigList[$i] }
        }
        $script:taskConfigList = $newTasks
        Save-Config
        Update-Task-Grid
        System-Log ($ui.INFO_Deleted -f $taskName) "Info"
    })
    foreach ($item in @(
        $menuStartItem, $menuStopItem, $menuRestartItem, $menuViewLogItem,
        $menuMoveUpItem, $menuMoveDownItem,
        $menuSep1, $menuStartAllItem, $menuStopAllItem,
        $menuSep2, $menuAddItem, $menuEditItem, $menuDeleteItem
    )) {
        $taskContextMenu.Items.Add($item) | Out-Null
    }
    $taskContextMenu.Add_Opening({
        $index = Get-Selected-Task-Index
        $count = $taskConfigList.Count
        $hasSelection = ($index -ge 0)
        $selectedIsRunning = $false
        if ($hasSelection) {
            $selectedExecution = Get-Task-Execution -TaskName ([string]$taskConfigList[$index].name)
            if ($selectedExecution.process -and -not $selectedExecution.process.HasExited) {
                $selectedIsRunning = $true
            }
        }
        $runningCount = 0
        foreach ($task in $taskConfigList) {
            $taskExecution = Get-Task-Execution -TaskName ([string]$task.name)
            if ($taskExecution.process -and -not $taskExecution.process.HasExited) {
                $runningCount += 1
            }
        }
        $menuStartItem.Enabled = ($hasSelection -and -not $selectedIsRunning)
        $menuStopItem.Enabled = ($hasSelection -and $selectedIsRunning)
        $menuRestartItem.Enabled = ($hasSelection)
        $menuViewLogItem.Enabled = $hasSelection
        $menuEditItem.Enabled = $hasSelection
        $menuDeleteItem.Enabled = $hasSelection
        $menuMoveUpItem.Enabled = ($index -gt 0)
        $menuMoveDownItem.Enabled = ($index -ge 0 -and $index -lt ($count - 1))
        $menuStartAllItem.Enabled = ($count -gt 0)
        $menuStopAllItem.Enabled = ($count -gt 0)
    })
    $dataGridView.ContextMenuStrip = $taskContextMenu

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
    $logTextBox.Font = $mainForm.Font
    $logTextBox.DetectUrls = $false
    $logTextBox.WordWrap = $false
    $logTextBox.Dock = "Fill"
    $logTabPage.Controls.Add($logTextBox)
    $systemLogTextBox = $logTextBox

    # 系统日志的右键菜单：复制日志 / 清空日志
    $copyLogMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $copyLogMenuItem.Text = $ui.LogCopy
    $copyLogMenuItem.Add_Click({
        if ($logTextBox.Text.Length -gt 0) {
            [System.Windows.Forms.Clipboard]::SetText($logTextBox.Text)
            System-Log $ui.INFO_LogCopied "Success"
        } else {
            System-Log $ui.INFO_NoLog "Warning"
        }
    })
    $clearLogMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $clearLogMenuItem.Text = $ui.LogClear
    $clearLogMenuItem.Add_Click({
        $logTextBox.Clear()
    })
    $logTextBox.ContextMenuStrip = [System.Windows.Forms.ContextMenuStrip]::new()
    $logTextBox.ContextMenuStrip.Items.Add($copyLogMenuItem) | Out-Null
    $logTextBox.ContextMenuStrip.Items.Add($clearLogMenuItem) | Out-Null

    # 日志队列处理定时器
    $taskLogQueueProcessTimer = [System.Windows.Forms.Timer]::new()
    $taskLogQueueProcessTimer.Interval = 200
    $taskLogQueueProcessTimer.Add_Tick({
        Process-Task-Log-Queue
    })
    $taskLogQueueProcessTimer.Start()

    # 任务状态刷新定时器
    $taskStatusMonitorTimer = [System.Windows.Forms.Timer]::new()
    $taskStatusMonitorTimer.Interval = 500
    $taskStatusMonitorTimer.Add_Tick({
        Monitor-Task-Status
    })
    $taskStatusMonitorTimer.Start()
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

    # 程序启动
    [System.Windows.Forms.Application]::Run($mainForm)

    # 结束后清理资源
    try { $trayIcon.Visible = $false } catch { }
    try { $trayIcon.Dispose() } catch { }
    try { $mainForm.Hide() } catch { }
    try { $mainForm.Close() } catch { }

    # 停止任务，并确保日志处理完成
    Stop-All-Tasks
    try { $taskLogQueueProcessTimer.Stop() } catch { }
    try { $taskLogQueueProcessTimer.Dispose() } catch { }
    try { $taskStatusMonitorTimer.Stop() } catch { }
    try { $taskStatusMonitorTimer.Dispose() } catch { }
    Process-Task-Log-Queue

    # 释放单实例互斥量
    try { if ($script:appMutex) { $script:appMutex.Dispose() } } catch { }
} catch {
    Handle-Exception $_
    pause
    exit 1
}
