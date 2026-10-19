# AI 聚合网关 · Android APK

把 [ai.yodlx.com](https://ai.yodlx.com/) 包装成原生 Android 应用，高级液态玻璃（Liquid Glass）风格启动屏 + 沉浸式全屏 WebView。

## 项目信息

| 项 | 值 |
|---|---|
| 包名 | `com.yodlx.apk` |
| 版本 | v1.0.0 (versionCode 1) |
| 最低 API | 21 (Android 5.0) |
| 目标 API | 34 (Android 14) |
| APK 大小 | ~282KB |
| 签名 | debug 风格（`androiddebugkey`） |
| 许可证 | MIT |

## GitHub

https://github.com/mysterious-1314-520/ai-yodlx-apk

## 官网下载页

> ⚠️ **临时预览地址**，依赖后台终端存活，非永久官方站点。
> 下载页源码在 `download/index.html`，需自行部署到正式托管服务（如 Vercel / Netlify / GitHub Pages）作为永久官网。

预览地址（当前有效）：https://8000-bf3c06fa506237c6.monkeycode-ai.online

## 项目结构

```
AiyodlxApk/
├── .gitignore              # 排除 keystore / build / APK
├── LICENSE
├── README.md
├── build.sh                # 一键构建脚本
├── ic_launcher_512.png     # 应用图标源文件
├── keystore.jks            # 签名密钥（已忽略，勿提交）
├── brand-icon/             # 品牌标 + favicon 素材
│   ├── brand-mark.svg      # 液态玻璃品牌标（网页用）
│   ├── brand-mark-dark.svg # 深色背景版
│   ├── brand-{32,64,128,256,512}.png
│   ├── brand-round-*.png   # 圆形版
│   ├── brand-dark-*.png    # 深色背景版
│   ├── favicon.svg / favicon-32.png / favicon-64.png
│   └── apple-touch-icon.png
├── download/               # 官网下载页
│   ├── index.html          # 液态玻璃下载页
│   ├── AiyodlxApk.apk      # 待发布的 APK
│   └── favicon*.png
└── src/main/
    ├── AndroidManifest.xml
    ├── assets/splash.html   # 液态玻璃启动屏
    ├── java/com/yodlx/apk/MainActivity.java
    └── res/
        ├── drawable/       # splash_bg / 自适应图标 XML
        ├── mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/
        │   └── ic_launcher.png / ic_launcher_round.png
        └── values/         # colors / strings / styles
```

## 功能特性

### 液态玻璃启动屏 (`assets/splash.html`)
- `backdrop-filter: blur(30px) saturate(170%)` 磨砂玻璃卡片
- 流体渐变背景 + 3 个缓慢漂移的径向光斑（20s 循环）
- 顶部光泽扫光动画、脉冲玻璃徽标、三点加载、胶囊下载按钮
- 2.4s 后自动跳转 `ai.yodlx.com`，也支持手动点击

### 沉浸式全屏（四层机制）
1. 主题层：`android:windowFullscreen="true"` + `shortEdges` 刘海屏适配
2. 装饰视图标志：`SYSTEM_UI_FLAG_FULLSCREEN` + `HIDE_NAVIGATION` + `IMMERSIVE_STICKY`
3. `WindowInsetsController`（API 23+）：直接 `hide(statusBars | navigationBars)`
4. 五时机重应用：`onCreate` / `onWindowFocusChanged` / `browser.post` / `OnSystemUiVisibilityChangeListener` / `onPageFinished`

### WebView
- 加载 `ai.yodlx.com`，外部链接唤起浏览器
- JS 桥接：启动屏「进入控制台」按钮通过 `android.goToSite()` 跳转
- `singleTask` 启动模式防重复，低内存时自动清理缓存

### 应用图标
- 5 档密度 PNG（mdpi→xxxhdpi）+ 圆形自适应图标 + 512 Play Store
- 源文件：`ic_launcher_512.png`

## 环境依赖

| 组件 | 版本 | 安装方式 |
|------|------|---------|
| JDK | 17 | Temurin / apt install openjdk-17-jdk-headless |
| Android SDK | 34 | sdkmanager platforms;android-34 build-tools;34.0.0 |
| Python | 3 | Pillow（图标生成）、cairosvg（SVG 渲染） |

## 构建

```bash
# 1. 安装工具链
# JDK 17: https://adoptium.net/
# Android SDK: sdkmanager --sdk_root=/opt/android-sdk "platforms;android-34" "build-tools;34.0.0"

# 2. 构建
cd AiyodlxApk && ./build.sh

# 产物: build/AiyodlxApk.apk
```

构建流程：aapt 编译资源 → javac 编译 Java → d8 生成 Dex → aapt 打包 → zipalign 对齐 → apksigner 签名。

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `JAVA_HOME` | 自动探测 | JDK 安装目录 |
| `ANDROID_HOME` | `/opt/android-sdk` | SDK 安装目录 |
| `SDK_VERSION` | `34` | Android API 版本 |
| `BUILD_TOOLS_VERSION` | `34.0.0` | 构建工具版本 |

## 签名

使用 `keystore.jks`，别名 `androiddebugkey`，密码 `android`（debug 风格）。生产发布请用正式密钥替换。

密钥已加入 `.gitignore`，不会被提交到 GitHub。

## 官网下载页

`download/index.html` 是独立的液态玻璃 APK 下载站，可单独部署。已包含 favicon 素材（SVG + PNG + apple-touch-icon）。

## 设计规范

- 启动屏和下载页均采用液态玻璃风格：深色流体渐变背景 + `backdrop-filter` 磨砂 + 半透明描边 + 光泽扫光
- 品牌标为等距立方体三面玻璃设计（对应网站多面体 logo）
- 三端（APK 启动屏 / 官网 / 品牌标）视觉统一