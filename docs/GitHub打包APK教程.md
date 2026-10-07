# 用 GitHub 打包并安装脑力训练 Demo

这份教程将本地源码上传到 GitHub，由 GitHub Actions 生成 APK，再下载安装到 Android 手机。本机无需安装 Flutter 或任何 Android 开发工具。代码已经提供，首次云端构建和手机运行需要按下面步骤验证。

## 1 准备文件

项目目录是 `D:\pycharm\LightFuture`。需要上传的是源码文件及配置，不是单独的压缩包。

仓库根目录应直接包含：

```text
.github/
  workflows/android-apk.yml
lib/
  main.dart
  app.dart
  games/reaction_controller.dart
test/
tool/
  prepare_android.py
  verify_apk.py
  tests/
  demo-signing/
    demo-keystore.jks
    demo-certificate.der
    README.md
docs/
.gitignore
README.md
analysis_options.yaml
pubspec.yaml
```

`android/` 目录现在没有，是正常情况：工作流用固定版本 Flutter 在云端自动生成，补好名称、签名和离线权限后再构建。不要自行添加空的 Android 工程。

同时提供的 `dist/lightfuture-demo-source.zip` 是方便搬运的源码备份，需要先解压再上传里面的文件；只把 ZIP 上传到 GitHub 不会自动构建。

## 2 创建 GitHub 仓库

1. 登录 [GitHub](https://github.com)，点击右上角 `+` → `New repository`。
2. Repository name 可以填写 `LightFuture`。
3. 选择 Public 或 Private。私人项目可用 Private；Actions 的可用额度以你的账户和仓库设置为准。
4. 如果采用下一节的 Git 命令上传，创建空仓库，不勾选初始化 README、.gitignore 或 License，避免与本地文件产生初次推送冲突。
5. 点击 `Create repository`，复制 HTTPS 地址，例如 `https://github.com/你的用户名/LightFuture.git`。

## 3 上传源码

推荐使用 Git，能完整保留目录及 `.github` 工作流。电脑已检查到 Git。

在 PowerShell 运行下面命令。把远程地址中的用户名和仓库名改成你自己的。首次使用时，user.name 和 user.email 填你的 Git 提交署名，邮箱可用 GitHub 提供的 noreply 邮箱。

```powershell
Set-Location 'D:\pycharm\LightFuture'
git init
git branch -M main
git config user.name '你的提交署名'
git config user.email '你的提交邮箱'
git add .github lib test tool docs .gitignore README.md analysis_options.yaml pubspec.yaml
git status
git commit -m 'Add offline Flutter reaction demo and APK workflow'
git remote add origin https://github.com/你的用户名/LightFuture.git
git push -u origin main
```

`git status` 应显示上述源码与配置，也包括 `tool/demo-signing/demo-keystore.jks` 和 `demo-certificate.der`。这里上传的是特意公开的测试密钥，只适用于 Demo。

推送时按 Git 的登录提示在浏览器授权你的 GitHub 账户。GitHub HTTPS 推送不接受直接输入账户登录密码；若采用个人访问令牌方式，需要有仓库代码及工作流写入权限。不需要将令牌写进源码或教程命令。

如果提示 `remote origin already exists`，运行 `git remote -v` 查看地址；若地址错误，可用 `git remote set-url origin 你的仓库HTTPS地址` 修改。如果远程已经有 README 等提交，不要强制推送，先处理仓库的已有提交或使用下面的网页上传方式。

### 只用网页上传

1. 进入仓库的 Code 页，选择 `Add file` → `Upload files`；空仓库可点击上传现有文件的链接。
2. 拖入 `lib`、`test`、`tool`、`docs` 目录，以及根目录配置和 README。不要拖入整个外层 `LightFuture` 文件夹，否则 pubspec.yaml 会多一层。
3. 完成提交后，再上传 `.github` 目录。
4. 若网页漏掉点开头的目录，使用 `Add file` → `Create new file`，文件名输入 `.github/workflows/android-apk.yml`，完整复制本地同名文件的内容并提交。该文件必须以 `.yml` 结尾，不能是 `.yml.txt`。
5. 在 Code 页确认根目录有 `pubspec.yaml`，并能点开 `.github/workflows/android-apk.yml`。

GitHub 本身不会解压你上传的 ZIP。第一次上传的源码要齐全，尤其不能漏掉 tool 中的两个签名文件。

## 4 运行云端打包

上传到 main/master 时，会自动运行 `Build Android Demo APK`。

手动运行方法：进入仓库 `Actions` → 左侧选择 `Build Android Demo APK` → `Run workflow` → 选择 main → 点击运行。手动入口要求工作流已经存在于默认分支。如果仓库要求启用 Actions，先按页面提示启用。

工作流顺序：

1. 获取源码。
2. 准备 Java 17 和 Flutter 3.35.7。
3. 检查 Android 工程配置脚本。
4. 在云端生成 Android 工程并复制 Demo 源码。
5. 下载 Flutter 依赖、格式化、分析并运行游戏与页面测试。
6. 执行 `flutter build apk --release`，使用工作流编号作为 Android versionCode。
7. 验证最终 APK 的签名、应用标识、Android 最低版本和无 INTERNET 权限。
8. 上传 APK 与构建记录。

打开运行记录可以逐步查看日志。等整次运行显示绿色成功再下载；首次构建要下载工具和依赖，耗时以实际日志为准。此 Demo 不需要自己配置 GitHub Secrets，也不需要改 Actions 权限为读写。

## 5 下载 APK

1. 登录 GitHub，打开 `Actions` 中成功的运行记录。
2. 在该次运行的 Summary 页面下方找到 `Artifacts`。
3. 下载 `lightfuture-demo.apk`。工作流按原文件上传 APK；若浏览器或下载方式提供 ZIP，则先解压，取出 `.apk` 文件。
4. 可选下载 `build-details`，其中包含 APK 校验值、签名和权限检查记录，以及首次构建生成的 `pubspec.lock`。

下载 Artifacts 需要登录并有该仓库的读取权限；本工作流保留文件 14 天。过期后重新执行构建即可。来源：[GitHub 下载构建产物说明](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts)。

你可以在电脑上下载后通过 USB、聊天文件传输或其他常用方式发送给手机，也可以用手机浏览器登录 GitHub 直接下载。不要把源代码 ZIP 当作 APK 安装。

## 6 在手机安装和试玩

本 Demo 设置最低 Android 6.0，并构建包含 ARM 32 位、ARM 64 位、x86_64 的通用 APK。

1. 在手机文件管理器中点击 `lightfuture-demo.apk`。
2. 如果系统提示当前来源不允许安装应用，按手机提示给此次使用的浏览器或文件管理器允许安装此 APK；各品牌设置名称不同。
3. 安装后打开“脑力训练 Demo”。
4. 在首页选择 Level 1，点击“开始训练”。
5. 等待三秒倒计时结束；蓝色时不点，出现绿色“立即点击”后点一次。
6. 完成五轮，确认能看到平均反应时间、得分、成功率和逐轮成绩。

### 建议的手机测试

- 能正常安装，冷启动没有白屏或闪退，中文清晰。
- Level 1 正常完成五轮，结果页能“再练一次”和“返回首页”。
- 在蓝色等待阶段提前点击，应显示“抢跑了”。
- 绿色阶段不点击，应显示“超时了”。
- 连点不会在同一轮重复计分；全部失败时平均反应时间显示“—”，得分为 0。
- 训练中切到其他 App 再回来，应显示暂停；点击继续后重新三秒倒计时，已完成轮次保留。
- 训练中使用系统返回键或左上返回按钮，可以确认退出。
- 尝试 Level 10，响应窗口应比 Level 1 短。
- 开启飞行模式并关闭 Wi-Fi，杀掉 App 后重新打开，再完整训练，验证离线运行。

当前最佳成绩只在本次 App 进程中保留；重启后清空是 Demo 的预期行为。毫秒结果用于本手机上的相对比较，触摸及屏幕刷新会影响读数。

## 7 更新 Demo

修改代码后再次提交到 main，Actions 会重新打包。使用同一仓库和原来的 Demo 签名文件，versionCode 会随新工作流运行递增，通常可直接覆盖安装。

```powershell
Set-Location 'D:\pycharm\LightFuture'
git add lib test tool .github pubspec.yaml analysis_options.yaml
git commit -m 'Update demo'
git push
```

不要每次重新生成测试签名。正式产品会使用独立应用标识与私人发布签名，本 Demo 的公开测试密钥不用于正式发布。来源：[Flutter Android 签名与发布说明](https://docs.flutter.dev/deployment/android)。

首次成功构建后，可将 build-details 的 pubspec.lock 保存到仓库根目录，再 `git add pubspec.lock`、提交并推送，固定以后使用的依赖版本。

## 8 常见问题

| 现象 | 处理方式 |
| --- | --- |
| Actions 没有工作流 | 检查 `.github/workflows/android-apk.yml` 是否存在于默认分支，文件名和目录层级是否正确 |
| 没有自动构建 | 确认提交在 main/master；只修改教程不会触发自动构建，可手动 Run workflow |
| 缺少 pubspec.yaml 或签名文件 | 检查上传层级及 tool/demo-signing 目录，不能只上传 Dart 文件 |
| 构建显示红色失败 | 点开失败的步骤，将错误文本、运行链接或截图发回；不要跳过分析、测试或 APK 验证强行发布 |
| 下载不到 Artifact | 确认已登录、有读取权限、整次构建成功且尚未超过 14 天 |
| 手机打开的是 ZIP | 先解压，安装里面的 APK；源代码压缩包不能安装 |
| 提示与手机不兼容 | 检查 Android 是否达到 6.0；记录手机型号、系统版本及完整安装提示 |
| 更新提示签名冲突或降级 | 确认使用同一份 Demo 签名且下载的是较新的构建；换仓库或重生成签名后可能需卸载旧 Demo 再装 |
| 安装后闪退 | 记录手机型号、Android 版本、安装的构建编号、闪退发生的页面，反馈后继续排查 |

当前完成的是源码和云端构建流程。实际 APK 尚需首次 GitHub 构建成功后生成，手机可运行性由这轮安装测试确认。
