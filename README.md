# 屏幕模式切换 · Screen Mode Switcher

一个免费、MIT 开源的 macOS 菜单栏小工具，在「正常模式」和「屏幕常亮」之间切换。

![屏幕模式切换宣传图](assets/banner.png)

## 下载与使用

从 [GitHub Releases](https://github.com/Sad-Salad-12/screen-mode-switcher/releases/latest) 下载 `ScreenModeSwitcher-v2.0.4.zip`，解压后将「屏幕模式切换.app」放入「应用程序」。

- 启动后只驻留在菜单栏，不自动弹窗，也不显示 Dock 图标。
- 单击菜单栏图标，选择「正常模式」或「屏幕常亮」。
- 双击图标，或选择「打开控制面板」，打开完整界面。
- 「登录时自动启动」默认关闭，可以自行开启；macOS 可能要求在系统设置的登录项中批准。
- 切换时通过 macOS 系统授权窗口请求管理员权限。应用不收集、传递或保存你的密码。
- 菜单栏使用系统单色模板图标：深色菜单栏为白色，浅色菜单栏由系统自动适配。
- 菜单栏位置会尽量排在所有系统图标之前。

### 首次打开的安全提示

下载版只有本地 ad-hoc 签名，没有付费开发者签名或 Apple 公证，所以 macOS 可能阻止首次启动。

仅在确认下载来自本仓库、文件未被篡改且你信任源码时，在尝试打开后前往「系统设置 → 隐私与安全性」，为此 App 选择「仍要打开」。请参考 [Apple 的安全说明](https://support.apple.com/en-us/102445)。不要关闭全局 Gatekeeper 或系统完整性保护。

## 模式实际做了什么

**「正常模式」是固定预设，不是自动恢复每位用户安装前的设置。** 如果你有自己的时间偏好，请先在系统设置中记下它们；本版不会备份或自动还原你的自定义配置。

| 设置 | 正常模式 | 屏幕常亮 |
| --- | --- | --- |
| 电池供电：显示器闲置休眠 | 2 分钟 | 禁用闲置显示器休眠 |
| 接电：显示器闲置休眠 | 10 分钟 | 禁用闲置显示器休眠 |
| 电池及接电：系统闲置睡眠 | 1 分钟 | 禁用闲置系统睡眠 |
| 当前用户屏幕保护程序闲置计时 | 5 分钟 | 禁用闲置启动 |

使用系统自带 `pmset` 和 `defaults` 写入这些设置。实际睡眠时机仍取决于 macOS、电源策略和其他进程。
- 设置是持久的。退出或删除 App 不会自动恢复；退出/卸载前可切回正常预设，或在系统设置中手动还原自己的配置。

## License

[MIT](LICENSE) · Copyright © 2026 Sad-Salad-12。

## English summary

A free, MIT-licensed macOS menu bar utility for switching between a fixed normal power preset and an always-on idle display/sleep preset. Single-click for the mode switch; double-click for the control panel. Optional launch at login.

Requires administrator authorization when changing settings. Never handles or stores passwords. Settings persist after quitting. Normal mode does **not** restore a user's previous custom settings. Lid-close behavior, manual locking and password policies are not changed.

The downloadable app is ad-hoc signed, **not Apple-notarized**. Use the source and release checksums to review what you install. Build with `./scripts/build.sh`; run harmless authorization smoke tests with `./scripts/test.sh`. Targets macOS 13+, arm64 and x86_64; currently locally tested on macOS 26.6.2.
