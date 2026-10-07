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
            ERROR_TaskStartFailed = "任务启动失败: {0}"
            ERROR_TaskStopFailed = "任务停止失败: {0}"
            ERROR_TaskStopTimeout = "停止任务超时: {0}"
            INFO_Started = "任务已启动: {0} (PID {1})"
            INFO_Stopped = "任务已停止: {0}"
            INFO_Exited = "任务已退出: {0} (退出码 {1})"
            INFO_AlreadyRunning = "任务已在运行中: {0}"
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
            LogTaskStart = "———————————— 开始新进程 ————————————————"
            LogTaskEnd = "———————————— 结束进程，退出码 {0} ————————————————"
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
            ERROR_TaskStartFailed = "Failed to start task: {0}"
            ERROR_TaskStopFailed = "Failed to stop task: {0}"
            ERROR_TaskStopTimeout = "Stopping task timed out: {0}"
            INFO_Started = "Task started: {0} (PID {1})"
            INFO_Stopped = "Task stopped: {0}"
            INFO_Exited = "Task exited: {0} (exit code {1})"
            INFO_AlreadyRunning = "Task is already running: {0}"
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
            LogTaskStart = "———————————— Start new process ————————————————"
            LogTaskEnd = "———————————— End process, exit code {0} ————————————————"
        }
    }
    $ui = $uiTextResources[$workingLanguage]
    if (-not $ui) { $ui = $uiTextResources['zh-CN'] }

    # 界面字体，统一用微软雅黑
    $uiFont = [System.Drawing.Font]::new("Microsoft YaHei", 10)

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
            foreach ($item in @($config)) {
                if ($item -isnot [PSCustomObject]) { continue; }

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
            }
            $script:taskConfigList = $newTaskConfigList
            Update-Task-Grid
        } catch {
            System-Log ($ui.INFO_ConfigLoadFailed -f $_.Exception.Message) "Error"
            return $false
        }
        System-Log ($ui.INFO_ConfigLoaded -f $script:taskConfigList.Count) "Success"
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
    # 任务名 → @{ process; status; logViewContent; logFilePath; logFileWriter; logViewTextBox }
    $taskExecutionMap = @{}

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
                if ($taskExecutionMap.ContainsKey([string]$taskName)) {
                    $execution = $taskExecutionMap[[string]$taskName]
                    if ($execution.status) {
                        $statusText = $execution.status
                    }
                    if ($execution.process -and -not $execution.process.HasExited) {
                        $pidText = [string]$execution.process.Id
                    }
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
        if ($taskExecutionMap.ContainsKey([string]$TaskName)) {
            $execution = $taskExecutionMap[[string]$TaskName]
            if ($execution.status) {
                $statusText = $execution.status
            }
            if ($execution.process -and -not $execution.process.HasExited) {
                $pidText = [string]$execution.process.Id
            }
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
                $execution.logViewTextBox.ScrollToCaret()
            }
            finally {
                $execution.logViewTextBox.ResumeLayout()
            }
        } catch {
            Handle-Exception $_
        }
    }

    # 任务日志的异步队列，字段：{ TaskName; Message; Level }
    $script:taskLogAppendQueue = [System.Collections.Concurrent.ConcurrentQueue[hashtable]]::new()

    # 新增任务日志，投递到异步队列
    function Append-Task-Log {
        param([string]$TaskName, [string]$Message, [string]$Level = 'Info')
        $script:taskLogAppendQueue.Enqueue(@{ TaskName = $TaskName; Message = $Message; Level = $Level })
    }

    # 任务日志处理：按顺序处理队列
    function Process-Task-Log-Queue {
        $logItem = $null
        while ($script:taskLogAppendQueue.TryDequeue([ref]$logItem)) {
            Append-Task-Log-Internal -TaskName $logItem.TaskName -Message $logItem.Message -Level $logItem.Level
        }
    }

    # 启动任务（参数 $Task 为任务配置对象，即 $taskConfigList 中的一个元素）
    function Start-Task {
        param([PSCustomObject]$Task)

        if ($null -eq $Task) { return }
        $taskName = [string]$Task.name
        if ($script:taskExecutionMap.ContainsKey($taskName)) {
            $execution = $script:taskExecutionMap[$taskName]
            if ($execution.process -and -not $execution.process.HasExited) {
                System-Log ($ui.INFO_AlreadyRunning -f $taskName) "Warning"
                return
            }
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

        if (-not $script:taskExecutionMap.ContainsKey($taskName)) {
            $script:taskExecutionMap[$taskName] = @{
                process = $null
                status = $ui.StatusNotStarted
                logViewContent = [System.Text.StringBuilder]::new()
                logFilePath = [System.IO.Path]::Combine($myBatchTaskLogsDir, $taskName + ".log")
                logFileWriter = $null
                logViewTextBox = $null
                StandardOutputReader = $null
                StandardErrorReader = $null
                RunspacePool = $null
            }
        }
        $execution = $script:taskExecutionMap[$taskName]
        $execution.process = $process
        $execution.status = $ui.StatusRunning
        if ($execution.logFileWriter) {
            try { $execution.logFileWriter.Dispose() } catch {}
            $execution.logFileWriter = $null
        }
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
        $stdoutReaderPs.AddParameter('Queue', $script:taskLogAppendQueue)
        $stdoutReaderPs.AddParameter('TaskName', $taskName)
        $stdoutReaderPs.AddParameter('Level', 'Info')
        $stdoutReaderPs.BeginInvoke() | Out-Null
        $execution.StandardOutputReader = $stdoutReaderPs
        # 标准错误读取
        $stderrReaderPs = [System.Management.Automation.PowerShell]::Create()
        $stderrReaderPs.RunspacePool = $readerRunspacePool
        $stderrReaderPs.AddScript($readerScript) | Out-Null
        $stderrReaderPs.AddParameter('Reader', $process.StandardError)
        $stderrReaderPs.AddParameter('Queue', $script:taskLogAppendQueue)
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

        if (-not $script:taskExecutionMap.ContainsKey($TaskName)) { return }
        $execution = $script:taskExecutionMap[$TaskName]

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
        if (-not $script:taskExecutionMap.ContainsKey($taskName)) { return }
        $execution = $script:taskExecutionMap[$taskName]
        if (-not $execution.process -or $execution.process.HasExited) {
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
        Append-Task-Log -TaskName $taskName -Message ($ui.LogTaskEnd -f $execution.process.ExitCode)
    }

    # 监视任务状态：如果进程退出，更新状态并释放相关资源
    function Monitor-Task-Status {
        for ($i = 0; $i -lt $script:taskConfigList.Count; $i++) {
            $task = $script:taskConfigList[$i]
            $taskName = [string]$task.name
            if (-not $script:taskExecutionMap.ContainsKey($taskName)) { continue }
            $execution = $script:taskExecutionMap[$taskName]

            if (-not $execution.process) { continue }
            if ($execution.status -eq $ui.StatusRunning) {
                if ($execution.process.HasExited) {
                    if ($execution.process.ExitCode -eq 0) {
                        $execution.status = $ui.StatusExited
                    } else {
                        $execution.status = $ui.StatusExitedError
                    }
                    Release-Task-Resources -TaskName $taskName
                    Update-Task-Grid-Row -TaskName $taskName
                    System-Log ($ui.INFO_Exited -f $taskName, $execution.process.ExitCode) "Warning"
                    Append-Task-Log -TaskName $taskName -Message ($ui.LogTaskEnd -f $execution.process.ExitCode)
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
        foreach ($task in $script:taskConfigList) {
            Start-Task -Task $task
        }
        System-Log $ui.INFO_StartAllDone "Success"
    }

    # 停止全部任务
    function Stop-All-Tasks {
        foreach ($task in $script:taskConfigList) {
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
        param($EventSender, $EventArgs)
        if (-not $script:realExit) {
            $EventArgs.Cancel = $true
            $EventSender.Hide()
            $EventSender.ShowInTaskbar = $false
        }
    })
    # 窗体首次显示事件: 隐藏到托盘 + 自动启动任务
    $mainForm.Add_Shown({
        param($EventSender, $EventArgs)
        $EventSender.Opacity = 0
        $EventSender.Hide()
        $EventSender.Opacity = 1
        $EventSender.ShowInTaskbar = $false
        # 启动全部 autoStart 任务
        for ($i = 0; $i -lt $script:taskConfigList.Count; $i++) {
            $task = $script:taskConfigList[$i]
            $needStart = [bool]$task.autoStart
            if ($needStart) {
                Start-Task -Task $task
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
        param($EventSender, $EventArgs)
        if ($EventArgs.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            if ($mainForm.Visible) {
                $mainForm.Hide()
                $mainForm.ShowInTaskbar = $false
            } else {
                Show-MainWindow
            }
        }
    })
    $trayIcon.Add_MouseDoubleClick({
        param($EventSender, $EventArgs)
        if ($EventArgs.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
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
        param($EventSender, $EventArgs)
        if ($EventArgs.Button -ne [System.Windows.Forms.MouseButtons]::Right) { return }
        # 查找点击的标签页
        for ($i = 0; $i -lt $tabControl.TabPages.Count; $i++) {
            $tabRect = $tabControl.GetTabRect($i)
            if ($tabRect.Contains($EventArgs.Location)) {
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
            if ($script:taskExecutionMap.ContainsKey($taskName)) {
                $script:taskExecutionMap[$taskName].logViewTextBox = $null
            }
        }
        $tabControl.TabPages.Remove($script:rightClickedTab)
        $script:rightClickedTab.Dispose()
        $script:rightClickedTab = $null
    })

    # 任务日志标签页
    # 打开任务日志标签页（已存在则直接切换）
    function Show-Task-Log-Viewer {
        param([string]$TaskName)

        if ([string]::IsNullOrEmpty($TaskName)) { return }
        $logViewTabPageName = "LogPage_" + $TaskName
        # 已存在则直接切换
        $existingLogViewTabPage = $tabControl.TabPages[$logViewTabPageName]
        if ($existingLogViewTabPage) {
            $tabControl.SelectedTab = $existingLogViewTabPage
            return
        }
        # 确保运行时条目存在
        if (-not $script:taskExecutionMap.ContainsKey($TaskName)) {
            $script:taskExecutionMap[$TaskName] = @{
                process = $null
                status = $ui.StatusNotStarted
                logViewContent = [System.Text.StringBuilder]::new()
                logFileWriter = $null
                logFilePath = [System.IO.Path]::Combine($myBatchTaskLogsDir, $TaskName + ".log")
                logViewTextBox = $null
                StandardOutputReader = $null
                StandardErrorReader = $null
                RunspacePool = $null
            }
        }
        $execution = $script:taskExecutionMap[$TaskName]
        # 新建日志标签页
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
        $logViewTextBox.Font = $uiFont
        # 关闭 URL 自动检测，防止日志中的链接被渲染成蓝色下划线导致颜色/字体不一致
        $logViewTextBox.DetectUrls = $false
        $logViewTextBox.Dock = "Fill"
        $logViewTabPage.Controls.Add($logViewTextBox)
        # 日志文本框右键菜单: 复制日志 / 清空日志 / 打开日志文件
        $logViewContextMenu = [System.Windows.Forms.ContextMenuStrip]::new()
        $logViewCopyItem = [System.Windows.Forms.ToolStripMenuItem]::new()
        $logViewCopyItem.Text = $ui.LogCopy
        $logViewClearItem = [System.Windows.Forms.ToolStripMenuItem]::new()
        $logViewClearItem.Text = $ui.LogClear
        $logViewOpenItem = [System.Windows.Forms.ToolStripMenuItem]::new()
        $logViewOpenItem.Text = $ui.LogOpenFile
        $logViewContextMenu.Items.Add($logViewCopyItem) | Out-Null
        $logViewContextMenu.Items.Add($logViewClearItem) | Out-Null
        $logViewContextMenu.Items.Add($logViewOpenItem) | Out-Null
        $logViewTextBox.ContextMenuStrip = $logViewContextMenu
        # 载入历史日志（与追加行统一字体和颜色：微软雅黑 10 / 黑色，防止历史段落继承默认字体导致样式不一致）
        $logViewTextBox.SelectionStart = $logViewTextBox.TextLength
        $logViewTextBox.SelectionLength = 0
        $logViewTextBox.SelectionFont = $logViewTextBox.Font
        $logViewTextBox.SelectionColor = [System.Drawing.Color]::Black
        $logViewTextBox.AppendText($execution.logViewContent.ToString())
        $logViewTextBox.SelectionStart = $logViewTextBox.TextLength
        $logViewTextBox.ScrollToCaret()
        # 右键菜单事件绑定
        $logViewCopyItem.Add_Click({
            if ($logViewTextBox.Text.Length -gt 0) {
                [System.Windows.Forms.Clipboard]::SetText($logViewTextBox.Text)
                System-Log $ui.INFO_LogCopied "Success"
            } else {
                System-Log $ui.INFO_NoLog "Warning"
            }
        })
        $logViewClearItem.Add_Click({
            $logViewTextBox.Clear()
            $execution.logViewContent.Clear() | Out-Null
        })
        $logViewOpenItem.Add_Click({
            if ($execution.logFilePath -and [System.IO.File]::Exists($execution.logFilePath)) {
                Start-Process "notepad.exe" -ArgumentList ('"' + $execution.logFilePath + '"')
            } else {
                System-Log $ui.INFO_NoLog "Warning"
            }
        })
        # 保存引用
        $execution.logViewTextBox = $logViewTextBox
        # 添加到标签栏并选中
        $tabControl.TabPages.Add($logViewTabPage)
        $tabControl.SelectedTab = $logViewTabPage
    }

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
        if ($EditIndex -ge 0 -and $EditIndex -lt $script:taskConfigList.Count) {
            $task = $script:taskConfigList[$EditIndex]
            $originalName = [string]$task.name
            $nameBox.Text = $originalName
            $commandBox.Text = [string]$task.command
            $argumentsBox.Text = [string]$task.arguments
            $workingDirBox.Text = [string]$task.workingDirectory
            $autoStartBox.Checked = [bool]$task.autoStart
        }
        # 确定按钮: 校验并写回任务列表
        $okButton.Add_Click({
            $newName = $nameBox.Text.Trim()
            $newCommand = $commandBox.Text.Trim()
            $newArguments = $argumentsBox.Text.Trim()
            $newWorkingDir = $workingDirBox.Text.Trim()

            # 任务名称：不能为空，且不能包含任何无法作为 Windows 文件名的字符
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

            # 任务名称唯一性检查（修改时允许保持自身名称不变）
            for ($i = 0; $i -lt $script:taskConfigList.Count; $i++) {
                if ($i -eq $EditIndex) { continue }
                if ([string]$script:taskConfigList[$i].name -ieq $newName) {
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
                $script:taskConfigList[$EditIndex] = $newTask
                # 名称变更时，迁移运行时数据并移除旧日志标签页
                if ($originalName -ine $newName -and $script:taskExecutionMap.ContainsKey($originalName)) {
                    $oldRuntime = $script:taskExecutionMap[$originalName]
                    # 移除旧的日志标签页
                    $oldLogViewTabPageName = "LogPage_" + $originalName
                    $oldLogViewTabPage = $tabControl.TabPages[$oldLogViewTabPageName]
                    if ($oldLogViewTabPage) {
                        $tabControl.TabPages.Remove($oldLogViewTabPage)
                        $oldLogViewTabPage.Dispose()
                    }
                    # 迁移运行时数据到新名称
                    $script:taskExecutionMap[$newName] = $oldRuntime
                    $script:taskExecutionMap.Remove($originalName) | Out-Null
                }
            } else {
                $script:taskConfigList += $newTask
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
    # 只允许单行选择
    $dataGridView.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
    $dataGridView.MultiSelect = $false
    # 鼠标按下时自动选中一行（包括左键和右键）
    $dataGridView.Add_CellMouseDown({
        param($EventSender, $EventArgs)
        if ($EventArgs.RowIndex -ge 0) {
            $dataGridView.ClearSelection()
            $dataGridView.Rows[$EventArgs.RowIndex].Selected = $true
            $dataGridView.CurrentCell = $dataGridView.Rows[$EventArgs.RowIndex].Cells[0]
        }
    })
    # 双击行查看任务日志
    $dataGridView.Add_CellDoubleClick({
        $menuViewLogItem.PerformClick()
    })
    $taskListTabPage.Controls.Add($dataGridView)
    $taskGridView = $dataGridView
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
    $menuMoveUpItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuMoveUpItem.Text = $ui.MenuMoveUp
    $menuMoveDownItem = [System.Windows.Forms.ToolStripMenuItem]::new()
    $menuMoveDownItem.Text = $ui.MenuMoveDown
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
        $menuMoveUpItem, $menuMoveDownItem,
        $menuSep1, $menuStartAllItem, $menuStopAllItem,
        $menuSep2, $menuAddItem, $menuEditItem, $menuDeleteItem
    )) {
        $taskContextMenu.Items.Add($item) | Out-Null
    }
    $dataGridView.ContextMenuStrip = $taskContextMenu
    # 右键菜单打开时，根据选中位置启用/禁用上移、下移
    $taskContextMenu.Add_Opening({
        $index = Get-Selected-Task-Index
        $count = $script:taskConfigList.Count
        $menuMoveUpItem.Enabled = ($index -gt 0)
        $menuMoveDownItem.Enabled = ($index -ge 0 -and $index -lt ($count - 1))
    })
    # 右键菜单: 新增任务
    $menuAddItem.Add_Click({ Open-Task-Dialog -EditIndex -1 })
    # 右键菜单: 启动任务
    $menuStartItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        Start-Task -Task $script:taskConfigList[$index]
    })
    # 右键菜单: 停止任务
    $menuStopItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        Stop-Task -Task $script:taskConfigList[$index]
    })
    # 右键菜单: 重启任务
    $menuRestartItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        Restart-Task -Task $script:taskConfigList[$index]
    })
    # 右键菜单: 查看任务日志
    $menuViewLogItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        Show-Task-Log-Viewer -TaskName ([string]$script:taskConfigList[$index].name)
    })
    # 右键菜单: 上移任务
    $menuMoveUpItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        if ($index -le 0) { return }
        $upper = $script:taskConfigList[$index - 1]
        $script:taskConfigList[$index - 1] = $script:taskConfigList[$index]
        $script:taskConfigList[$index] = $upper
        Save-Config
        Update-Task-Grid
        $dataGridView.Rows[$index - 1].Selected = $true
        $dataGridView.CurrentCell = $dataGridView.Rows[$index - 1].Cells[0]
    })
    # 右键菜单: 下移任务
    $menuMoveDownItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        if ($index -ge ($script:taskConfigList.Count - 1)) { return }
        $lower = $script:taskConfigList[$index + 1]
        $script:taskConfigList[$index + 1] = $script:taskConfigList[$index]
        $script:taskConfigList[$index] = $lower
        Save-Config
        Update-Task-Grid
        $dataGridView.Rows[$index + 1].Selected = $true
        $dataGridView.CurrentCell = $dataGridView.Rows[$index + 1].Cells[0]
    })
    # 右键菜单: 修改任务（运行中则先停止，保存后再启动）
    $menuEditItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        $task = $script:taskConfigList[$index]
        $taskName = [string]$task.name
        $isRunning = $false
        if ($script:taskExecutionMap.ContainsKey($taskName)) {
            $execution = $script:taskExecutionMap[$taskName]
            if ($execution.process -and -not $execution.process.HasExited) { $isRunning = $true }
        }
        $needRestart = $false
        if ($isRunning) {
            $confirmResult = [System.Windows.Forms.MessageBox]::Show($ui.ConfirmRestart -f $taskName, $ui.ConfirmTitle, "YesNo", "Question")
            if ($confirmResult -ne [System.Windows.Forms.DialogResult]::Yes) { return }
            Stop-Task -Task $task
            $needRestart = $true
        }
        $result = Open-Task-Dialog -EditIndex $index
        if ($needRestart -and $result -eq [System.Windows.Forms.DialogResult]::OK) {
            # 任务可能在对话框里被改配置，这里重新取一次修改后的任务配置
            Start-Task -Task $script:taskConfigList[$index]
        }
    })
    # 右键菜单: 删除任务
    $menuDeleteItem.Add_Click({
        $index = Get-Selected-Task-Index
        if ($index -lt 0) {
            [System.Windows.Forms.MessageBox]::Show($ui.ERROR_NoSelection, $ui.FormTitle, "OK", "Information") | Out-Null
            return
        }
        $taskName = [string]$script:taskConfigList[$index].name
        $confirmResult = [System.Windows.Forms.MessageBox]::Show($ui.ConfirmDelete -f $taskName, $ui.ConfirmTitle, "YesNo", "Question")
        if ($confirmResult -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        Stop-Task -Task $script:taskConfigList[$index]
        if ($script:taskExecutionMap.ContainsKey($taskName)) {
            $execution = $script:taskExecutionMap[$taskName]
            # 移除对应的日志标签页
            $logViewTabPageName = "LogPage_" + $taskName
            $logViewTabPage = $tabControl.TabPages[$logViewTabPageName]
            if ($logViewTabPage) {
                $tabControl.TabPages.Remove($logViewTabPage)
                $logViewTabPage.Dispose()
            }
            if ($execution.logFileWriter) {
                try { $execution.logFileWriter.Dispose() } catch {}
            }
            $script:taskExecutionMap.Remove($taskName) | Out-Null
        }
        $newTasks = @()
        for ($i = 0; $i -lt $script:taskConfigList.Count; $i++) {
            if ($i -ne $index) { $newTasks += $script:taskConfigList[$i] }
        }
        $script:taskConfigList = $newTasks
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

    # 日志队列处理定时器: 消化后台线程的输出队列
    $taskLogQueueProcessTimer = [System.Windows.Forms.Timer]::new()
    $taskLogQueueProcessTimer.Interval = 200
    $taskLogQueueProcessTimer.Add_Tick({
        Process-Task-Log-Queue
    })
    $taskLogQueueProcessTimer.Start()

    # 界面刷新定时器: 检查进程退出
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
    # 程序启动（首次显示时自动隐藏到托盘）
    [System.Windows.Forms.Application]::Run($mainForm)
    # 主循环结束后清理资源
    $taskLogQueueProcessTimer.Stop()
    $taskLogQueueProcessTimer.Dispose()
    $taskStatusMonitorTimer.Stop()
    $taskStatusMonitorTimer.Dispose()
    Stop-All-Tasks
    # 定时器已停止，最后排空一次队列，保证退出前产生的日志都已落盘
    Process-Task-Log-Queue
    $trayIcon.Visible = $false
    $trayIcon.Dispose()
} catch {
    Handle-Exception $_
    pause
    exit 1
}
