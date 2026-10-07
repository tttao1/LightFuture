# 脑力训练 Android 离线合集

版本 1.0.0，使用 Flutter 与 Dart。现已实现 24 个训练项目，每个项目可选择 Level 1～10。用户已验证原反应速度 Demo 能在手机运行；本次升级扩展了完整训练合集、三页导航和本地记录。

## 已实现的训练

| 能力 | 四个训练项目 |
| --- | --- |
| 记忆力 | 数字记忆、位置记忆、卡片配对、顺序记忆 |
| 注意力 | 舒尔特方格、找不同、目标搜索、颜色干扰 |
| 反应力 | 反应速度、目标闪现、抑制反应、节奏点击 |
| 逻辑能力 | 数字规律、图形规律、条件判断、数字排序 |
| 计算能力 | 心算、连续计算、大小比较、凑数挑战 |
| 空间能力 | 图形旋转、镜像判断、方块拼合、路径规划 |

操作包括数字键盘、记忆后点选、翻牌配对、顺序复现、目标搜索、抑制点击、节奏点击、拖动排序、编辑表达式、拖放拼块和路径滑动。每款游戏独立生成题目、定义判定和难度参数。

## 页面与流程

- 首页：本地日期生成今日推荐、快速开始、六类能力入口、最近玩过。
- 训练：分类筛选、名称搜索、玩法说明、十级难度选择。
- 我的：同游戏同等级最佳成绩、最近 20 次记录、音效与振动开关、清除本机记录。
- 训练流程：说明 → 3 秒倒计时 → 观察／作答 → 正误反馈 → 成绩 → 再练一次或返回。
- 成绩页包含得分、正确率、用时、等级、最佳成绩、评价，以及该游戏独有指标。

普通训练在暂停或切到后台后保留当前操作进度，恢复时先倒计时。反应与节奏类训练重置未完成轮次，已结算轮次保留。所有控制器、定时器和动画在退出时释放。

## 离线与本地保存

无需登录、账号、服务器、网络 API、在线 AI、网络图片、CDN 或 SQLite。图形由 Flutter 绘制，启动图标为原创本地矢量资源。

本地记录由 Dart 序列化为小型 JSON，通过 Android 自带 SharedPreferences 保存，读写在后台线程执行。音效使用 Android 本地 ToneGenerator，触觉反馈使用 Flutter 平台能力。没有新增第三方运行时插件。

设置、上次等级、最近 20 次训练和各等级最佳成绩可在杀进程后恢复。损坏记录会隔离处理，写入失败不会阻止查看当前成绩。Android 自动云备份已关闭，Release APK 的 INTERNET 权限仍在打包时检查。

## 构建与覆盖更新

按 [1.0 升级教程](docs/1.0升级与手机测试.md) 上传完整新版源码。已有 `.github/workflows/android-apk.yml` 仍可使用：推送到 main/master 会检查代码、运行测试、生成 Android 工程、构建 APK，并验证最低版本、权限和固定签名。

工作流固定 Flutter 3.35.7、Java 17 和 Android API 24，手机最低要求 Android 7.0。APK 仍叫 `lightfuture-demo.apk`，应用显示名改为“脑力训练”，版本为 1.0.0。

包名 `cn.lightfuture.demo` 和既有测试签名保持一致，因此同一仓库的新构建可覆盖原 Demo。正式发行时使用私有签名材料；当前签名是此前为覆盖测试提供的公开 Demo 签名。

本机无需安装 Android SDK。Android 目录在 CI 的 `.ci/android_project` 自动生成，`tool/android/MainActivity.kt` 和 `training_icon.xml` 会注入工程，提供本地保存、音效和图标。请随源码上传整个 tool 目录。

## 目录

```text
lib/main.dart                    启动、竖屏设置
lib/app.dart                     中文本地化与应用入口
lib/app/                         主题与颜色
lib/models/                      游戏目录、训练结果
lib/pages/                       首页、训练库、设置、说明、训练、成绩
lib/storage/                     本地记录与设置
lib/games/memory/                记忆题目与交互
lib/games/attention/             搜索、方格、颜色判断
lib/games/reaction/              闪现、抑制、节奏
lib/games/reaction_controller.dart 已手机验证的反应速度核心
lib/games/logic/                 数列、图形、条件、排序
lib/games/calculation/           心算、连续计算、比较、表达式
lib/games/spatial/               旋转、镜像、拼块、路径
lib/games/shared/                统一会话与有类型的题目模型
lib/widgets/                    键盘、图形、反馈、共用界面
test/                           规则、操作、计时、暂停及存储测试
tool/android/                   Android 原生存储、音效与启动图标
tool/prepare_android.py         CI 工程生成
tool/verify_apk.py              APK 签名、权限和版本检查
.github/workflows/              GitHub Actions
```

## 验证与剩余确认

本地使用 Flutter 3.35.7 检查全部游戏的十级题目、手机尺寸下的界面、键盘和拖动替代操作、单次结算、超时、暂停恢复、记录重启恢复，以及原生存储通信协议。构建脚本另有 Python 测试，验证工程注入、签名、权限和 APK 校验。

最新测试记录见 [1.0 验收清单](docs/1.0验收清单.md)。本次完整合集还需在 GitHub 构建新版 APK，并在真实手机验证 24 款游戏、原生音效和持久化。此前确认的真机结果只属于原反应速度 Demo。

源代码压缩包不包含 `.qa` 临时 Flutter SDK、开发缓存或构建目录。历史 Demo 修复说明保留在 docs 中；升级请使用当前的 1.0 教程。
