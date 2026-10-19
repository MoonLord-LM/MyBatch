# MyBatch
[![self-check](https://github.com/MoonLord-LM/MyBatch/actions/workflows/self-check.yml/badge.svg)](https://github.com/MoonLord-LM/MyBatch/actions/workflows/self-check.yml)

A collection of commonly used Windows Batch scripts  

一些常用的 Windows 批处理脚本集合  

## [功能分类]

| 目录 | 功能分类 | 说明 |
| --- | --- | --- |
| [gui](https://github.com/MoonLord-LM/MyBatch/tree/master/gui) | [窗体程序](#窗体程序) | 控制台任务批量管理 |
| [console/file](https://github.com/MoonLord-LM/MyBatch/tree/master/console/file) | [文件处理](#文件处理) | 压缩解压、加密解密、打包、去重、生成列表等 |
| [console/media](https://github.com/MoonLord-LM/MyBatch/tree/master/console/media) | [多媒体工具](#多媒体工具) | 视频合并、切片、转码、AI 放大插帧、封面管理、字幕管理、批量重命名等 |
| [console/server](https://github.com/MoonLord-LM/MyBatch/tree/master/console/server) | [网络服务](#网络服务) | 内网穿透、本地文件服务器等 |
| [console/system](https://github.com/MoonLord-LM/MyBatch/tree/master/console/system) | [系统优化](#系统优化) | 垃圾清理、缓存清理等 |

## [脚本清单]

### 窗体程序

| 脚本 / 文件 | 说明 |
| --- | --- |
| [MyBatchTask 任务管理.ps1](https://github.com/MoonLord-LM/MyBatch/blob/master/gui/MyBatchTask%20任务管理.ps1) | 图形化任务 / 进程管理工具 |
| [精简 ps1 代码.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/gui/精简%20ps1%20代码.bat) | 压缩精简 PowerShell 脚本体积（去空白 / 注释） |

### 文件处理

| 脚本 | 说明 |
| --- | --- |
| [文件 ed2k 链接生成.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件%20ed2k%20链接生成.bat) | 为文件生成 eD2k 电驴下载链接 |
| [文件编码 - 01 反转.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件编码%20-%2001%20反转.bat) | 对文件做 0/1 位反转的轻量编码 / 混淆 |
| [文件编码 - PEM 格式.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件编码%20-%20PEM%20格式.bat) | 把任意文件编码为 PEM 文本格式（Base64 + 头尾） |
| [文件打包为 bat 格式.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件打包为%20bat%20格式.bat) | 把文件打包进单个 .bat，运行时还原为原文件 |
| [文件打包为 cli-exe 格式.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件打包为%20cli-exe%20格式.bat) | 打包为命令行 exe（带图标） |
| [文件打包为 cli-exe 格式 - 无图标版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件打包为%20cli-exe%20格式%20-%20无图标版.bat) | 打包为命令行 exe（无图标） |
| [文件打包为 gui-exe 格式.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件打包为%20gui-exe%20格式.bat) | 打包为带图形界面的 exe |
| [文件打包为 gui-exe 格式 - 无图标版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件打包为%20gui-exe%20格式%20-%20无图标版.bat) | 打包为带图形界面的 exe（无图标） |
| [文件哈希值生成 - RHash 版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件哈希值生成%20-%20RHash%20版.bat) | 用 RHash 计算文件多算法哈希值 |
| [文件哈希值生成.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件哈希值生成.bat) | 计算文件的哈希值 |
| [文件加解密 - 加密.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件加解密%20-%20加密.bat) | 加密文件 |
| [文件加解密 - 解密.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件加解密%20-%20解密.bat) | 解密文件 |
| [文件加密压缩 - 7z 存储.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件加密压缩%20-%207z%20存储.bat) | 加密压缩为 7z（仅存储不压缩） |
| [文件加密压缩 - 7z 最佳.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件加密压缩%20-%207z%20最佳.bat) | 加密压缩为 7z（最佳压缩率） |
| [文件夹显示.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件夹显示.bat) | 取消文件夹隐藏属性，使其可见 |
| [文件夹隐藏.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件夹隐藏.bat) | 设置文件夹为隐藏属性 |
| [文件解码 - PEM 格式.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件解码%20-%20PEM%20格式.bat) | 把 PEM 文本解码还原为原文件 |
| [文件列表生成 - csv 格式.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件列表生成%20-%20csv%20格式.bat) | 导出目录下文件清单（CSV，含大小 / 时间） |
| [文件列表生成 - json 格式.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件列表生成%20-%20json%20格式.bat) | 导出目录下文件清单（JSON） |
| [文件列表生成 - txt 格式.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件列表生成%20-%20txt%20格式.bat) | 导出目录下文件清单（TXT） |
| [文件名列表生成 - csv 格式.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件名列表生成%20-%20csv%20格式.bat) | 仅导出文件名字列表（CSV） |
| [文件名列表生成 - json 格式.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件名列表生成%20-%20json%20格式.bat) | 仅导出文件名字列表（JSON） |
| [文件名列表生成 - txt 格式.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件名列表生成%20-%20txt%20格式.bat) | 仅导出文件名字列表（TXT） |
| [文件名删除重复前后缀.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件名删除重复前后缀.bat) | 批量去除文件名中重复的相同前后缀 |
| [文件压缩 - 7z 存储.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件压缩%20-%207z%20存储.bat) | 压缩为 7z（仅存储不压缩） |
| [文件压缩 - 7z 最佳.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件压缩%20-%207z%20最佳.bat) | 压缩为 7z（最佳压缩率） |
| [文件压缩 - exe 存储.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件压缩%20-%20exe%20存储.bat) | 压缩为自解压 exe（存储） |
| [文件压缩 - exe 最佳.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件压缩%20-%20exe%20最佳.bat) | 压缩为自解压 exe（最佳） |
| [文件压缩 - zip 存储.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件压缩%20-%20zip%20存储.bat) | 压缩为 zip（存储） |
| [文件压缩 - zip 最佳.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件压缩%20-%20zip%20最佳.bat) | 压缩为 zip（最佳） |
| [文件重复清理 - 仅比对大小.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件重复清理%20-%20仅比对大小.bat) | 仅按文件大小比对去重清理 |
| [文件重复清理 - 快速版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件重复清理%20-%20快速版.bat) | 按大小 + 快速哈希去重清理 |
| [文件重复清理.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件重复清理.bat) | 按完整哈希去重清理重复文件 |
| [文件自动解压.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/file/文件自动解压.bat) | 识别格式并自动解压压缩包 |

### 多媒体工具

| 脚本 | 说明 |
| --- | --- |
| [屏幕录制关闭.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/屏幕录制关闭.bat) | 关闭系统屏幕录制 |
| [屏幕录制开启 - 0.5 倍分辨率.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/屏幕录制开启%20-%200.5%20倍分辨率.bat) | 开启屏幕录制（输出 0.5 倍分辨率） |
| [屏幕录制开启 - 完整分辨率.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/屏幕录制开启%20-%20完整分辨率.bat) | 开启屏幕录制（输出完整分辨率） |
| [屏幕延时录制开启 - 0.5 倍分辨率.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/屏幕延时录制开启%20-%200.5%20倍分辨率.bat) | 延时后开始屏幕录制（0.5 倍分辨率） |
| [屏幕延时录制开启 - 完整分辨率.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/屏幕延时录制开启%20-%20完整分辨率.bat) | 延时后开始屏幕录制（完整分辨率） |
| [视频编码查看.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频编码查看.bat) | 查看视频的编码格式信息 |
| [视频编码转换为 av1 - 画质优先.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频编码转换为%20av1%20-%20画质优先.bat) | 转码为 AV1（画质优先） |
| [视频编码转换为 av1 - 速度优先.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频编码转换为%20av1%20-%20速度优先.bat) | 转码为 AV1（速度优先） |
| [视频编码转换为 h264.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频编码转换为%20h264.bat) | 转码为 H.264 |
| [视频编码转换为 h265.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频编码转换为%20h265.bat) | 转码为 H.265 / HEVC |
| [视频的画面内容替换.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频的画面内容替换.bat) | 替换视频画面内容 |
| [视频的声音内容替换.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频的声音内容替换.bat) | 替换视频音轨 |
| [视频的音画内容替换.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频的音画内容替换.bat) | 同时替换画面与音轨 |
| [视频分辨率扩大为2倍 - 动漫 AI 版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频分辨率扩大为2倍%20-%20动漫%20AI%20版.bat) | AI 超分放大视频至 2 倍（动漫模型） |
| [视频分辨率扩大为2倍.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频分辨率扩大为2倍.bat) | 放大视频分辨率至 2 倍 |
| [视频分辨率扩大为3倍 - 动漫 AI 版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频分辨率扩大为3倍%20-%20动漫%20AI%20版.bat) | AI 超分放大视频至 3 倍（动漫模型） |
| [视频分辨率扩大为4倍 - 动漫 AI 版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频分辨率扩大为4倍%20-%20动漫%20AI%20版.bat) | AI 超分放大视频至 4 倍（动漫模型） |
| [视频分辨率扩大为4倍 - 通用 AI 版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频分辨率扩大为4倍%20-%20通用%20AI%20版.bat) | AI 超分放大视频至 4 倍（通用模型） |
| [视频分辨率缩小为0.5倍.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频分辨率缩小为0.5倍.bat) | 缩小视频分辨率至 0.5 倍 |
| [视频封面导出.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频封面导出.bat) | 提取视频封面图 |
| [视频封面检查.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频封面检查.bat) | 检查视频是否含封面 |
| [视频封面嵌入.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频封面嵌入.bat) | 嵌入封面到视频 |
| [视频封面移除.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频封面移除.bat) | 移除视频封面 |
| [视频格式封装为 mkv.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频格式封装为%20mkv.bat) | 封装为 MKV 容器（不重编码） |
| [视频格式封装为 mp4.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频格式封装为%20mp4.bat) | 封装为 MP4 容器（不重编码） |
| [视频合并.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频合并.bat) | 合并多个视频片段 |
| [视频画面截取.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频画面截取.bat) | 截取视频某一帧画面 |
| [视频降噪.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频降噪.bat) | 对视频降噪处理 |
| [视频切片截取.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频切片截取.bat) | 按时间段切片截取视频片段 |
| [视频详细参数导出.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频详细参数导出.bat) | 导出视频详细参数信息 |
| [视频音频导出.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频音频导出.bat) | 提取视频中的音频 |
| [视频帧率扩大为2倍 - 通用 AI 版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频帧率扩大为2倍%20-%20通用%20AI%20版.bat) | AI 插帧把帧率提高至 2 倍 |
| [视频帧率扩大为3倍 - 通用 AI 版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频帧率扩大为3倍%20-%20通用%20AI%20版.bat) | AI 插帧把帧率提高至 3 倍 |
| [视频帧率扩大为4倍 - 通用 AI 版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频帧率扩大为4倍%20-%20通用%20AI%20版.bat) | AI 插帧把帧率提高至 4 倍 |
| [视频重命名 - 改为 VID + 生成时间.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频重命名%20-%20改为%20VID%20+%20生成时间.bat) | 按 VID + 生成时间规则重命名视频 |
| [视频重命名 - 改为 mmexport + 保存时间.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频重命名%20-%20改为%20mmexport%20+%20保存时间.bat) | 按微信导出规则重命名视频 |
| [视频重命名 - 添加生成日期前缀.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频重命名%20-%20添加生成日期前缀.bat) | 为视频名添加生成日期前缀 |
| [视频字幕导出.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频字幕导出.bat) | 提取视频字幕 |
| [视频字幕嵌入.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频字幕嵌入.bat) | 嵌入字幕到视频 |
| [视频字幕移除.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/视频字幕移除.bat) | 移除视频字幕 |
| [图片分辨率扩大为2倍 - 动漫 AI 版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片分辨率扩大为2倍%20-%20动漫%20AI%20版.bat) | AI 超分放大图片至 2 倍（动漫模型） |
| [图片分辨率扩大为3倍 - 动漫 AI 版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片分辨率扩大为3倍%20-%20动漫%20AI%20版.bat) | AI 超分放大图片至 3 倍（动漫模型） |
| [图片分辨率扩大为4倍 - 动漫 AI 版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片分辨率扩大为4倍%20-%20动漫%20AI%20版.bat) | AI 超分放大图片至 4 倍（动漫模型） |
| [图片分辨率扩大为4倍 - 通用 AI 版.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片分辨率扩大为4倍%20-%20通用%20AI%20版.bat) | AI 超分放大图片至 4 倍（通用模型） |
| [图片详细参数导出.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片详细参数导出.bat) | 导出图片详细参数信息 |
| [图片修改时间与命名检查.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片修改时间与命名检查.bat) | 检查图片修改时间与文件名是否一致 |
| [图片修改时间与命名刷新一致.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片修改时间与命名刷新一致.bat) | 把图片修改时间刷新为与文件名一致 |
| [图片重命名 - 改为 IMG + 拍摄时间.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片重命名%20-%20改为%20IMG%20+%20拍摄时间.bat) | 按 IMG + 拍摄时间重命名图片 |
| [图片重命名 - 改为 IMG + 修改时间.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片重命名%20-%20改为%20IMG%20+%20修改时间.bat) | 按 IMG + 修改时间重命名图片 |
| [图片重命名 - 改为 mmexport + 保存时间.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片重命名%20-%20改为%20mmexport%20+%20保存时间.bat) | 按微信导出规则重命名图片 |
| [图片重命名 - 改为 QQ截图 + 修改时间.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片重命名%20-%20改为%20QQ截图%20+%20修改时间.bat) | 按 QQ 截图规则重命名图片 |
| [图片重命名 - 改为 Screenshot + 截屏时间.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片重命名%20-%20改为%20Screenshot%20+%20截屏时间.bat) | 按 Screenshot 规则重命名图片 |
| [图片重命名 - 改为 拍摄时间序号.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/图片重命名%20-%20改为%20拍摄时间序号.bat) | 按拍摄时间 + 序号重命名图片 |
| [音频封面导出.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/音频封面导出.bat) | 提取音频封面图 |
| [音频封面嵌入.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/音频封面嵌入.bat) | 嵌入封面到音频 |
| [音频封面移除.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/media/音频封面移除.bat) | 移除音频封面 |

### 网络服务

| 脚本 | 说明 |
| --- | --- |
| [内网穿透 CloudFlare.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/server/内网穿透%20CloudFlare.bat) | 通过 CloudFlare 建立内网穿透隧道 |
| [内网穿透 Frp.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/server/内网穿透%20Frp.bat) | 通过 Frp 建立内网穿透 |
| [文件服务器 OpenList.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/server/文件服务器%20OpenList.bat) | 启动 OpenList 文件服务器 |

### 系统优化

| 脚本 | 说明 |
| --- | --- |
| [打开虚拟应用列表.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/system/打开虚拟应用列表.bat) | 打开 Windows 虚拟应用列表 |
| [打开自启动文件夹 - 当前用户.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/system/打开自启动文件夹%20-%20当前用户.bat) | 打开当前用户的启动文件夹 |
| [打开自启动文件夹 - 所有用户.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/system/打开自启动文件夹%20-%20所有用户.bat) | 打开所有用户的启动文件夹 |
| [局域网机器扫描.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/system/局域网机器扫描.bat) | 扫描局域网内存活的主机 |
| [垃圾文件清理.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/system/垃圾文件清理.bat) | 清理系统垃圾文件 |
| [清理浏览器的组织管理策略.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/system/清理浏览器的组织管理策略.bat) | 清除浏览器被组策略锁定的管理项 |
| [图标缓存清理.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/system/图标缓存清理.bat) | 重建 / 清理图标缓存 |
| [显示器关闭.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/system/显示器关闭.bat) | 关闭显示器进入节能状态 |
| [显示器开启.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/system/显示器开启.bat) | 唤醒 / 开启显示器 |
| [重启桌面进程.bat](https://github.com/MoonLord-LM/MyBatch/blob/master/console/system/重启桌面进程.bat) | 重启 Windows 资源管理器（explorer） |

## [工程结构]

```
MyBatch/
├── gui/             # 窗体程序
├── console/
│   ├── file/        # 文件处理
│   ├── media/       # 多媒体工具
│   ├── server/      # 网络服务
│   └── system/      # 系统优化
├── example/         # 零散示例脚本
├── LLM.md           # 提示信息
├── README.md        # 工程说明
└── self-check.bat   # 自检脚本
```
