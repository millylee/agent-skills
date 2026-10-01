# Linux 卸载命令与「彻底清除」语义

包管理器装的走包管理器;各家族 purge/remove 语义不同,别默认「卸载=连配置删」。

| 家族 | 卸载 | 连配置一起 | 清孤儿依赖 |
| --- | --- | --- | --- |
| Debian/Ubuntu | `apt remove <pkg>` | `apt purge <pkg>` | `apt autoremove` |
| Fedora/RHEL | `dnf remove <pkg>` | remove 已含配置 | `dnf autoremove` |
| Arch | `pacman -R <pkg>` | `pacman -Rns <pkg>` | `-Rs`/`-Rns` 自带 |
| openSUSE | `zypper remove <pkg>` | — | `zypper remove -u <pkg>` |
| snap | `snap remove <app>`(加 `--purge` 连数据) | `--purge` | — |
| flatpak | `flatpak uninstall <id>`;`flatpak uninstall --unused` 清孤儿运行时 | 数据在 `~/.var/app/<id>` 手动删 | `--unused` |

## 其他来源

- `pip uninstall -y <pkg>`;pipx 用 `pipx uninstall <pkg>`;用户级 pip 装在 `~/.local`,卸完看 `~/.local/bin` 残留入口。
- `npm rm -g <pkg>`、`cargo uninstall <pkg>`。
- 源码 make install:回源码目录 `make uninstall`;没有入口就按 footprint-linux.md 人工清。
- AppImage:删单文件即可。

## systemd 服务

```bash
systemctl disable --now <svc>.service   # 停止+去自启(改状态,经确认)
rm <unit 文件路径>                       # 按盘点清单定位
systemctl daemon-reload
systemctl reset-failed
```

用户级服务用 `systemctl --user` 同样流程。

## 卸载后残留高发位

- `~/.config/<app>`、`~/.cache/<app>`、`~/.local/share/<app>`、`~/.local/state/<app>`
- `~/.crash`/core dump、旧日志 `/var/log/<app>*`
- `~/.local/share/applications/*.desktop` 桌面入口
- `/etc/<app>`(remove 不删,purge 才删)
