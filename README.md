# 脑力训练 Android Demo

这是一个完全离线的 Flutter 手机演示版。先用反应速度小游戏验证 Android 安装、启动和交互，随后再扩展完整脑力训练合集。

功能：中文首页、Level 1～10 选择、3 秒倒计时、随机等待、5 轮训练、抢跑与超时反馈、成绩页、同等级会话最佳、再练一次、后台暂停与返回确认。无需登录、服务器、网络图片或第三方运行时插件。成绩仅在本次进程中保留，重启后清空。

## 打包和安装

请阅读 [GitHub 打包 APK 教程](docs/GitHub打包APK教程.md)，按其中步骤上传完整源码并下载 APK。你不需要在本机安装 Flutter、Android Studio、Android SDK 或模拟器。

工作流位于 `.github/workflows/android-apk.yml`。推送到 main/master 或手动点击 Run workflow 后，GitHub 将准备 Flutter 3.35.7、Java 17 和 Android 工具链，生成 Android 工程、检查代码、执行测试、打包并验证 APK。生成的 Android 工程只放在 CI 的 `.ci/android_project` 中，不覆盖你的源码。

成功后在 Actions 的 Artifacts 下载 `lightfuture-demo.apk`。构建详情中包含 APK SHA-256、签名与权限记录、依赖锁文件。

手机要求：Android 6.0 或以上，且为 Flutter 支持的 ARM 32 位、ARM 64 位或 x86_64 架构。通用 APK 包含这三种架构，直接安装即可，不需要选择分包。

## 项目结构

```text
.github/workflows/android-apk.yml  GitHub 云端打包流程
lib/main.dart                    App 启动入口
lib/app.dart                     首页、训练页和成绩页
lib/games/reaction_controller.dart 游戏状态、计时、判定及计分
test/                            游戏逻辑与页面流程测试
tool/prepare_android.py          生成并配置 Android 工程
tool/verify_apk.py               验证 APK 身份、签名、最低版本与离线权限
tool/demo-signing/               固定的公开 Demo 测试签名
tool/tests/                     Android 配置脚本测试
docs/GitHub打包APK教程.md         上传、打包、安装和排错步骤
pubspec.yaml                     Flutter 包配置
```

应用标识固定为 `cn.lightfuture.demo`，显示名称为“脑力训练 Demo”。演示版使用随源码提供的公开测试签名，无需配置 Secrets；正式发布时使用私人密钥及独立应用标识。不要删除或重新生成 Demo 的签名文件，否则已安装 Demo 的手机不能直接覆盖更新。

## 验证情况

本地能够运行 Android 配置脚本的 Python 测试。由于没有 Flutter 和 Android SDK，本地尚未运行 Flutter 分析、Flutter 测试或 APK 构建；这些检查已纳入 GitHub Actions。云端构建成功也不替代实际手机的启动、触摸和离线试玩。

首次成功构建后，可以下载 build-details 中的 pubspec.lock，放回仓库根目录并提交，以固定后续的依赖解析结果。Flutter SDK 已在工作流中固定版本。
