# macOS 卸载方式与参数

按安装来源选择方式。所有删除操作先列清单、经用户确认后逐项执行。

| 来源 | 卸载方式 |
| --- | --- |
| 拖拽安装的 .app | 退出进程后 `rm -rf /Applications/App.app`(确认归属);有 pkgutil 收据的补 `pkgutil --forget <pkg>`(改状态) |
| pkg 安装器 | macOS 没有官方反安装:按收据定位 `pkgutil --pkg-info <pkg>`、`pkgutil --files <pkg>` 找出落盘文件逐一删除,最后 `pkgutil --forget` 清收据 |
| brew formula | `brew uninstall <formula>`;先 `brew uses --installed <formula>` 确认无其他包依赖 |
| brew cask | `brew uninstall --cask <app>`;连数据一起清加 `--zap`(仍需按 footprint-macos.md 复核) |
| App Store | 用户在启动台删,或装了 mas 的话 `mas uninstall <id>` |

## 卸载前

```bash
osascript -e 'quit app "AppName"'      # 温和退出
killall <ProcessName> 2>/dev/null      # 强杀(确认无未保存数据)
launchctl bootout gui/$(id -u)/<label> # 停用户域 launchd 任务(改状态)
sudo launchctl bootout system/<label>  # 停系统域(改状态,需确认)
```

## 卸载后的残留清扫清单(对照 footprint-macos.md)

1. `~/Library/Application Support`、`~/Library/Caches`、`~/Library/Preferences`(.plist)、`~/Library/Logs`、`~/Library/Saved Application State`
2. 沙盒:`~/Library/Containers/<bundle-id>`、`~/Library/Group Containers/<group-id>`
3. launchd plist:`/Library/Launch{Agents,Daemons}`、`~/Library/LaunchAgents`(先 bootout 再删文件)
4. `/Library/PrivilegedHelperTools/`、`/Library/Application Support/`(确认共用情况)
5. `defaults delete <domain>` 清 plist 域(改状态)
