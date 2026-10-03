# MyBatch
[![self-check](https://github.com/MoonLord-LM/MyBatch/actions/workflows/self-check.yml/badge.svg)](https://github.com/MoonLord-LM/MyBatch/actions/workflows/self-check.yml)

A collection of commonly used Windows Batch scripts  

一些常用的 Windows 批处理脚本集合  

## [目录结构]

```
MyBatch/
├── file/
│   ├── 文件 ed2k 链接生成.bat
│   ├── 文件编码 - 01 反转.bat
│   ├── 文件编码 - PEM 格式.bat
│   ├── 文件哈希值生成 - RHash 版.bat
│   ├── 文件哈希值生成.bat
│   ├── 文件加密.bat
│   ├── 文件解码 - PEM 格式.bat
│   ├── 文件解密.bat
│   ├── 文件列表生成 - csv 格式.bat
│   ├── 文件列表生成 - json 格式.bat
│   ├── 文件列表生成 - txt 格式.bat
│   ├── 文件名列表生成 - csv 格式.bat
│   ├── 文件名列表生成 - json 格式.bat
│   ├── 文件名列表生成 - txt 格式.bat
│   ├── 文件名删除重复前后缀.bat
│   ├── 文件压缩 - 7z 加密存储.bat
│   ├── 文件压缩 - 7z 加密最佳.bat
│   ├── 文件压缩 - zip 存储.bat
│   ├── 文件压缩 - zip 最佳.bat
│   ├── 文件重复清理 - 仅比对大小.bat
│   ├── 文件重复清理 - 快速版.bat
│   ├── 文件重复清理.bat
│   └── 文件自动解压.bat
├── media/
│   ├── 屏幕录制关闭.bat
│   ├── 屏幕录制开启 - 0.5 倍分辨率.bat
│   ├── 屏幕录制开启 - 完整分辨率.bat
│   ├── 屏幕延时录制开启 - 0.5 倍分辨率.bat
│   ├── 屏幕延时录制开启 - 完整分辨率.bat
│   ├── 视频编码查看.bat
│   ├── 视频编码转换为 av1 - 画质优先.bat
│   ├── 视频编码转换为 av1 - 速度优先.bat
│   ├── 视频编码转换为 h264.bat
│   ├── 视频编码转换为 h265.bat
│   ├── 视频的画面内容替换.bat
│   ├── 视频的声音内容替换.bat
│   ├── 视频的音画内容替换.bat
│   ├── 视频分辨率扩大为2倍 - 动漫 AI 版.bat
│   ├── 视频分辨率扩大为2倍.bat
│   ├── 视频分辨率扩大为3倍 - 动漫 AI 版.bat
│   ├── 视频分辨率扩大为4倍 - 动漫 AI 版.bat
│   ├── 视频分辨率扩大为4倍 - 通用 AI 版.bat
│   ├── 视频分辨率缩小为0.5倍.bat
│   ├── 视频封面导出.bat
│   ├── 视频封面检查.bat
│   ├── 视频封面嵌入.bat
│   ├── 视频封面移除.bat
│   ├── 视频格式封装为 mkv.bat
│   ├── 视频格式封装为 mp4.bat
│   ├── 视频合并.bat
│   ├── 视频画面截取.bat
│   ├── 视频降噪.bat
│   ├── 视频切片截取.bat
│   ├── 视频详细参数导出.bat
│   ├── 视频音频导出.bat
│   ├── 视频帧率扩大为2倍 - 通用 AI 版.bat
│   ├── 视频帧率扩大为3倍 - 通用 AI 版.bat
│   ├── 视频帧率扩大为4倍 - 通用 AI 版.bat
│   ├── 视频重命名 - 改为 VID + 生成时间.bat
│   ├── 视频重命名 - 改为 mmexport + 保存时间.bat
│   ├── 视频重命名 - 添加生成日期前缀.bat
│   ├── 视频字幕导出.bat
│   ├── 视频字幕嵌入.bat
│   ├── 视频字幕移除.bat
│   ├── 图片分辨率扩大为2倍 - 动漫 AI 版.bat
│   ├── 图片分辨率扩大为3倍 - 动漫 AI 版.bat
│   ├── 图片分辨率扩大为4倍 - 动漫 AI 版.bat
│   ├── 图片分辨率扩大为4倍 - 通用 AI 版.bat
│   ├── 图片详细参数导出.bat
│   ├── 图片修改时间与命名检查.bat
│   ├── 图片修改时间与命名刷新一致.bat
│   ├── 图片重命名 - 改为 IMG + 拍摄时间.bat
│   ├── 图片重命名 - 改为 IMG + 修改时间.bat
│   ├── 图片重命名 - 改为 mmexport + 保存时间.bat
│   ├── 图片重命名 - 改为 QQ截图 + 修改时间.bat
│   ├── 图片重命名 - 改为 Screenshot + 截屏时间.bat
│   ├── 音频封面导出.bat
│   ├── 音频封面嵌入.bat
│   └── 音频封面移除.bat
├── server/
│   ├── 内网穿透 CloudFlare.bat
│   ├── 内网穿透 Frp.bat
│   └── 文件服务器 OpenList.bat
├── system/
│   ├── 局域网机器扫描.bat
│   ├── 垃圾文件清理.bat
│   ├── 清理浏览器的组织管理策略.bat
│   ├── 显示器关闭.bat
│   └── 显示器开启.bat
├── example/               # 零散示例代码
├── LLM.md                 # 提示信息
├── README.md              # 工程说明
└── self-check.bat         # 自检脚本
```
