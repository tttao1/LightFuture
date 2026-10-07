# 修复 APK 最低 Android 版本校验

GitHub 已完成 APK 编译，随后校验步骤报 APK has an unexpected minimum Android version。

之前工程生成脚本指定 API 23，APK 校验也要求 API 23。Flutter 3.35.7 的最低要求实际为 API 24，构建时会把旧配置迁移到 Flutter 默认值，因此生成的 APK 与错误的校验要求不一致。

现在已将工程生成和校验统一为 API 24，即 Android 7.0。构建报告会记录 APK 实际读取到的最低 API，异常也会显示实际值及期望值。联网权限和固定签名检查继续保留。

依据：[Flutter 3.35 官方版本说明](https://flutter.dev/blog/whats-new-in-flutter-3-35)。之前教程中 Android 6.0 的说明也已改正。本版本不能承诺安装到 Android 6.0 手机。

## 上传更新

修复包 dist/lightfuture-demo-apk-fix.zip 包含：

```text
tool/prepare_android.py
tool/verify_apk.py
tool/tests/test_prepare_android.py
tool/tests/test_verify_apk.py
```

1. 先解压修复包。
2. 在 GitHub 仓库根目录选择 Add file → Upload files，拖入解压后的 tool 文件夹，保留原来的目录层级。或者分别进入 tool 和 tool/tests 目录上传对应文件。
3. 提交到 main 分支，覆盖原文件并新增 test_verify_apk.py；既有的 Demo 签名文件无需改动。
4. Actions 会自动启动新的构建；全部成功后在 Artifacts 下载 lightfuture-demo.apk。

必须同时更新 test_prepare_android.py，否则旧测试还会要求 minSdk = 23，提前使工作流失败。APK 仍需 GitHub 再次验证及实际手机安装确认，不能跳过校验步骤直接当作已验证产物。
