# Demo 测试签名

demo-keystore.jks 和 demo-certificate.der 是本演示版专用的公开测试签名材料。

- 别名：lightfuture-demo
- keystore 密码与 key 密码：android
- 仅用于应用标识 cn.lightfuture.demo
- 后续构建继续使用这份文件，手机才可以直接覆盖更新。

这些内容可随 Demo 源码上传，无需设置 GitHub Secrets。正式产品使用另一份私人发布密钥和独立应用标识，私人密钥与密码通过 GitHub Secrets 配置，不使用本目录里的公开测试签名。
