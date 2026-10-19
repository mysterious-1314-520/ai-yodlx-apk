# AI 聚合网关 · Android APK

把 [ai.yodlx.com](https://ai.yodlx.com) 包装成原生 Android 应用，高级液态玻璃（Liquid Glass）风格启动屏 + 沉浸式全屏 WebView。

## 项目结构

```
AiyodlxApk/
├── build.sh                  # 一键构建脚本（需 JDK 17 + Android SDK 34）
├── .gitignore
├── keystore.jks              # 签名密钥（已忽略，勿提交）
├── ic_launcher_512.png       # 应用图标源文件
├── brand-icon/               # 品牌标 / favicon 素材
│   ├── brand-mark.svg        # 液态玻璃品牌标（网页用）
│   ├── favicon.svg / *.png
│   └── ...
├── download/                 # 官网下载页
│   ├── index.html            # 液态玻璃下载页
│   ├── AiyodlxApk.apk        # 待发布的 APK
│   └── favicon*.png
└── src/main/
    ├── AndroidManifest.xml
    ├── assets/splash.html     # 液态玻璃启动屏
    ├── java/com/yodlx/apk/MainActivity.java
    └── res/                   # 图标 / 风格 / 资源
```

## 功能特性

- **液态玻璃启动屏** — `backdrop-filter` 磨砂玻璃卡片 + 流体渐变背景 + 光泽扫光动画
- **沉浸式全屏** — 状态栏 / 导航栏彻底隐藏，四层机制防止被系统重置
- **网站内嵌** — WebView 加载 `ai.yodlx.com`，外部链接唤起浏览器
- **JS 桥接** — 启动屏「进入控制台」按钮通过 `android.goToSite()` 跳转
- **自适应图标** — 方形 + 圆形双版本，5 档密度

## 环境依赖

- JDK 17（Temurin）
- Android SDK 34（`platforms/android-34` + `build-tools/34.0.0`）
- Python 3（Pillow，生成图标用）

## 构建

```bash
./build.sh
# 产物：build/AiyodlxApk.apk
```

构建脚本会自动：编译资源 → 生成 R.java → javac → d8 → aapt 打包 → zipalign → apksigner 签名。

## 签名

使用 `keystore.jks`（debug 风格，别名 `androiddebugkey`，密码 `android`）。生产发布请用正式密钥替换。

## 官网下载页

`download/index.html` — 独立液态玻璃下载页，可直接部署为 APK 下载站。