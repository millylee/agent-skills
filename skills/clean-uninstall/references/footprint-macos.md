# macOS 软件痕迹地图

`scripts/inventory.sh` 之外需人工判断的位置。`<kw>` 换成关键词,`<bundle-id>` 换成应用的 bundle identifier。标注「改状态」的命令先列入清单、经确认后再执行。

## App 与安装来源

- App 位置:`/Applications`、`~/Applications` 下的 `.app`。
- 判断来源:`pkgutil --pkg-info <pkg>` 有收据 → pkg 安装器装的;无收据且无 `brew list --cask` 记录 → 拖拽安装。
- bundle id 查法:`osascript -e 'id of app "AppName"'` 或 `mdls -name kMDItemCFBundleIdentifier /Applications/App.app`。Library 下的痕迹大多按 bundle id 归属,先查到它再动手。

## 用户数据(Library 是主战场)

| 位置 | 内容 |
| --- | --- |
| `~/Library/Application Support/<Vendor 或 bundle-id>` | 主数据与配置 |
| `~/Library/Caches/<bundle-id 或 Vendor>` | 缓存 |
| `~/Library/Preferences/<bundle-id>.plist` | 偏好设置(`defaults read <bundle-id>` 查看) |
| `~/Library/Logs/` | 日志 |
| `~/Library/Saved Application State/<bundle-id>.savedState` | 窗口恢复状态 |
| `~/Library/Containers/<bundle-id>`、`~/Library/Group Containers/<group-id>` | 沙盒 App 数据 |
| `~/Library/HTTPStorages`、`~/Library/WebKit`、`~/Library/Cookies` | 网络痕迹,彻底清除才动 |
| `/Library/Application Support/` | 全机共享,**先确认没有其他 App 共用** |

配置删除前先备份:`ditto -ck --sequesterRsrc <path> ~/.cache/uninstall-backup/<app>.zip`。

## 系统登记

```bash
pkgutil --pkgs | grep -i '<kw>'                    # 安装收据
launchctl list | grep -i '<kw>'                    # 在跑的 launchd 任务
ls /Library/LaunchAgents /Library/LaunchDaemons ~/Library/LaunchAgents | grep -i '<kw>'
```

- `/Library/PrivilegedHelperTools/`:提权助手,常见残留(对照 bundle id/公司名)。
- `/Library/Extensions/`:内核扩展,现代 App 很少用,有则单独向用户确认。
- 登录项:脚本覆盖不全,让用户在「系统设置 → 通用 → 登录项」人工核对。

## brew 专项

- 卸 formula 前查依赖:`brew uses --installed <formula>`(有别的包依赖它就只报不删)。
- cask 的彻底清除:`brew uninstall --cask --zap <app>`,zap 会连 cask 定义的数据目录一起删,仍需按本地图复核。
- plist 域残留:`defaults read | grep -i '<kw>'` 兜底;删除用 `defaults delete <domain>`(改状态,经确认)。

## 查不到时

- Spotlight 补搜:`mdfind -name '<kw>'`、`mdfind "kMDItemKind == 'Application'" | grep -i '<kw>'`。
- App 已不在但 Library 有痕迹:多半是被手动拖进废纸篓过的残留,照常按归属清扫。
