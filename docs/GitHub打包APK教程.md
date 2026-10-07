# 用 GitHub 打包脑力训练 APK

本项目现为 1.0.0 离线训练合集，包含 24 个项目与十级难度。如果已有 Demo 仓库，请直接阅读 [升级与手机测试](1.0升级与手机测试.md)，覆盖上传新版源码。

## 创建或使用仓库

项目位于 D:\pycharm\LightFuture。GitHub 仓库根目录应直接包含 lib、test、tool、docs、pubspec.yaml、pubspec.lock、analysis_options.yaml、README.md 和 .github/workflows/android-apk.yml。

Android 工程由 CI 自动生成，不需要本地 android 目录。源码 ZIP 必须先解压；只将 ZIP 上传到仓库不会运行构建。

## 网页上传

1. 在 GitHub 新建 LightFuture 仓库，或打开已有仓库的 Code 页面。
2. 使用 Add file → Upload files，将解压后的 lib、test、tool、docs 和根目录配置上传到仓库根目录。
3. 确保 tool/android/MainActivity.kt、tool/android/training_icon.xml、tool/demo-signing 中的 jks 和 der 文件都存在。
4. 上传 .github 目录。若提示隐藏，使用 Add file → Create new file，名称填写 `.github/workflows/android-apk.yml`，完整复制本地同名文件的内容。
5. 提交到 main 分支。不要多嵌套一层 LightFuture，也不要形成 tool/tool、lib/lib 目录。

## Git 命令上传

新建空仓库后，在 PowerShell 中执行，远程地址和提交署名改成自己的：

```powershell
Set-Location 'D:\pycharm\LightFuture'
git init
git branch -M main
git config user.name '你的提交署名'
git config user.email '你的提交邮箱'
git add .github lib test tool docs .gitignore README.md analysis_options.yaml pubspec.yaml pubspec.lock
git commit -m 'Add offline brain training collection'
git remote add origin https://github.com/你的用户名/LightFuture.git
git push -u origin main
```

已有仓库只需要 git add、git commit、git push，不要重复添加远程。遇到远程已有提交时先处理合并，不要强制覆盖。HTTPS 推送按 Git 的登录提示在浏览器授权，或使用具备仓库与工作流写入权限的访问令牌，不直接输入 GitHub 登录密码。

## 云端构建

推送 main/master 会触发 Build Android Demo APK，名字沿用已验证的工作流。也可在 Actions 中选择它，点击 Run workflow 手动构建。

流程包括 Python 工程检查、生成 Android 工程、Flutter 依赖解析、代码分析、Flutter 测试、Release APK 编译，以及签名、API 24 和无 INTERNET 权限的最终 APK 校验。

安装工具和下载依赖只发生在 GitHub 构建阶段。手机上的 App 完全离线。当前不需要配置 GitHub Secrets。

## 下载和安装

1. 等整次构建绿色成功。
2. 打开该次运行 Summary 的 Artifacts。
3. 下载 lightfuture-demo.apk；若下载为 ZIP，先解压得到 APK。
4. 将 APK 传到手机，按手机提示允许此次文件来源安装应用。
5. 直接覆盖原 Demo，安装后显示“脑力训练”。最低 Android 7.0。

Artifacts 下载需要登录并有仓库读取权限，本工作流保留 14 天。参考：[GitHub 下载产物说明](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts)。

build-details 附件包含 APK 校验值、版本／签名／权限记录和依赖锁文件。构建失败时提供红色步骤里的完整错误文本，而不是只提供 exit code 1。

## 发布到 Releases

从 Actions 下载成功的 APK，再进入 Releases → Draft a new release，创建 v1.0.0 标签，选择对应构建的提交，填写标题与更新内容，附上 APK，再 Publish release。参考：[GitHub Release 管理](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)。

## 常见问题

| 现象 | 处理 |
| --- | --- |
| 找不到工作流 | 检查 .github/workflows/android-apk.yml 是否在默认分支 |
| 缺少原生保存或图标文件 | 上传完整 tool/android 目录 |
| 签名文件缺失 | 保留原 tool/demo-signing 文件，不重新生成 |
| 更新提示签名冲突或降级 | 核对签名未变化，下载的是同仓库较新的构建 |
| 只更新 Dart 后手机记录不能恢复 | 需要同时更新 tool 中的原生代码和工程生成脚本 |
| 安装不兼容 | Android 必须达到 7.0，并支持 APK 包含的架构 |
| 软件闪退或游戏异常 | 记录手机型号、Android 版本、构建编号、游戏名称和等级、操作步骤，反馈具体错误 |
