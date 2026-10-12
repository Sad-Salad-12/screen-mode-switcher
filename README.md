# 屏幕模式切换 · Screen Mode Switcher

一个免费、MIT 开源的 macOS 菜单栏小工具，在「正常模式」和「屏幕常亮」之间切换。

![屏幕模式切换宣传图](assets/banner.png)

> 上图是 AI 生成的产品宣传插画，不是实际界面截图。项目不在 App Store 上架；下载版未经过 Apple Developer ID 签名或公证。

## 下载与使用

从 [GitHub Releases](https://github.com/Sad-Salad-12/screen-mode-switcher/releases/latest) 下载 `ScreenModeSwitcher-v2.0.4.zip`，解压后将「屏幕模式切换.app」放入「应用程序」。

- 启动后只驻留在菜单栏，不自动弹窗，也不显示 Dock 图标。
- 单击菜单栏图标，选择「正常模式」或「屏幕常亮」。
- 双击图标，或选择「打开控制面板」，打开完整界面。
- 「登录时自动启动」默认关闭，可以自行开启；macOS 可能要求在系统设置的登录项中批准。
- 切换时通过 macOS 系统授权窗口请求管理员权限。应用不收集、传递或保存你的密码。
- 菜单栏使用系统单色模板图标：深色菜单栏为白色，浅色菜单栏由系统自动适配。
- 菜单栏位置只是偏好，不能保证排在所有系统图标之前。

### 首次打开的安全提示

下载版只有本地 ad-hoc 签名，没有付费开发者签名或 Apple 公证，所以 macOS 可能阻止首次启动。

仅在确认下载来自本仓库、文件未被篡改且你信任源码时，在尝试打开后前往「系统设置 → 隐私与安全性」，为此 App 选择「仍要打开」。请参考 [Apple 的安全说明](https://support.apple.com/en-us/102445)。不要关闭全局 Gatekeeper 或系统完整性保护。

每个 Release 附带 `SHA256SUMS.txt`。将它和 ZIP 放在同一目录，可运行：

```sh
shasum -a 256 -c SHA256SUMS.txt
```

校验和用于检查文件是否与 Release 一致，不等于 Apple 公证或恶意软件扫描。

## 模式实际做了什么

**「正常模式」是固定预设，不是自动恢复每位用户安装前的设置。** 如果你有自己的时间偏好，请先在系统设置中记下它们；本版不会备份或自动还原你的自定义配置。

| 设置 | 正常模式 | 屏幕常亮 |
| --- | --- | --- |
| 电池供电：显示器闲置休眠 | 2 分钟 | 禁用闲置显示器休眠 |
| 接电：显示器闲置休眠 | 10 分钟 | 禁用闲置显示器休眠 |
| 电池及接电：系统闲置睡眠 | 1 分钟 | 禁用闲置系统睡眠 |
| 当前用户屏幕保护程序闲置计时 | 5 分钟 | 禁用闲置启动 |

使用系统自带 `pmset` 和 `defaults` 写入这些设置。实际睡眠时机仍取决于 macOS、电源策略和其他进程。

重要边界：

- 设置是持久的。退出或删除 App 不会自动恢复；退出/卸载前可切回正常预设，或在系统设置中手动还原自己的配置。
- 不修改合盖行为、手动锁屏、锁屏密码要求，也不绕过公司/学校的设备管理策略。「屏幕常亮」不等于保证永不锁屏。
- 长时间常亮会增加耗电，可能影响 OLED 屏幕寿命；用完后请切回正常模式。
- 不同 macOS 版本、只有一种电源配置的台式机或受管理设备，可能显示「自定义设置」或校验刷新提示。请在系统设置核对；本版未覆盖全部设备测试。
- 本次开源发行使用独立 Bundle ID。如果已安装旧的本地版，请先退出旧版，避免两个菜单栏实例并存；旧版登录项需单独管理。

## 从源码编译

目标系统：macOS 13 或更新版本；Apple Silicon / Intel。实际本机验证环境为 macOS 26.6.2，其他版本与硬件仍需社区验证。

只需 Apple Command Line Tools，不需要第三方依赖或付费 Developer 账号：

```sh
xcode-select --install
git clone https://github.com/Sad-Salad-12/screen-mode-switcher.git
cd screen-mode-switcher
./scripts/build.sh
```

输出：

- `build/屏幕模式切换.app`
- `build/ScreenModeSwitcher-v2.0.4.zip`
- `build/SHA256SUMS.txt`

默认编译 Universal Binary（`arm64` + `x86_64`），也支持 `./scripts/build.sh arm64` 或 `./scripts/build.sh x86_64`。构建不会安装 App、注册登录项或改变电源设置。

## 测试

```sh
./scripts/test.sh
```

测试使用真实异步 `osascript` 进程，但运行的是无害的延迟/返回值脚本，不请求管理员密码、不写系统设置。覆盖授权脚本语法、菜单跟踪期间延后授权、事件循环响应、重复请求拦截、取消、失败和成功路径。

这些是烟雾测试，不代表每种系统版本上的管理员授权、开机启动和实际电源设置都已经完整验证。GitHub Actions 会自动编译并运行测试。

## 项目结构

```text
src/         Objective-C / AppKit 应用源码
resources/   App 元数据
tests/       授权流程烟雾测试
scripts/     编译、打包和测试脚本
assets/      宣传插画
```

应用自身不包含联网请求、广告、统计或遥测代码。授权与电源设置全部通过 macOS 自带工具完成。

欢迎通过 Issues 报告问题或提交 Pull Request。请提供系统版本、芯片类型、供电状态和可复现步骤；不要上传密码、完整个人设置备份或含隐私的日志。

## License

[MIT](LICENSE) · Copyright © 2026 Sad-Salad-12。

## English summary

A free, MIT-licensed macOS menu bar utility for switching between a fixed normal power preset and an always-on idle display/sleep preset. Single-click for the mode switch; double-click for the control panel. Optional launch at login.

Requires administrator authorization when changing settings. Never handles or stores passwords. Settings persist after quitting. Normal mode does **not** restore a user's previous custom settings. Lid-close behavior, manual locking and password policies are not changed.

The downloadable app is ad-hoc signed, **not Apple-notarized**. Use the source and release checksums to review what you install. Build with `./scripts/build.sh`; run harmless authorization smoke tests with `./scripts/test.sh`. Targets macOS 13+, arm64 and x86_64; currently locally tested on macOS 26.6.2.
