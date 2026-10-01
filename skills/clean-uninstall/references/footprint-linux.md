# Linux 软件痕迹地图

`scripts/inventory.sh` 之外需人工判断的位置。`<kw>` 换成关键词。先判发行版家族(`grep PRETTY_NAME /etc/os-release`),包管理语义差异见 `uninstallers-linux.md`。

## 包管理器归属判定

```bash
command -v apt    && dpkg -l | grep -i '<kw>'
command -v dnf    && dnf list installed | grep -i '<kw>'    # 或 rpm -qa | grep -i
command -v pacman && pacman -Qs '<kw>'
snap list | grep -i '<kw>'; flatpak list | grep -i '<kw>'
```

有包记录 → 走包管理器卸(见 uninstallers-linux.md),不要手删文件;无记录才走下面的手动路径。

## 通用安装位(手动/AppImage/编译安装)

| 位置 | 说明 |
| --- | --- |
| `/opt/<app>` | 第三方大件(chrome、postman 等) |
| `/usr/local/bin`、`/usr/local/share/<app>` | make install 与手动放置 |
| `~/.local/bin`、`~/.local/share/<app>` | 用户级安装(pipx、用户编译) |
| `~/.local/share/applications/*.desktop`、`/usr/share/applications/*.desktop` | 桌面入口,名称 grep `<kw>` |
| AppImage | 单文件放哪删哪,数据仍看下一节 |

## 配置与数据

```bash
ls -d ~/.config/*'<kw>'* ~/.cache/*'<kw>'* ~/.local/share/*'<kw>'* ~/.local/state/*'<kw>'* 2>/dev/null
find ~ -maxdepth 1 -iname '*<kw>*'    # 顶层点目录/dotfile
ls -d /etc/*'<kw>'* 2>/dev/null       # 系统级配置(apt purge 会删,remove 不会)
```

`~` 下的 dotfile(.vimrc 之类)属于用户个人,默认询问,不擅自删。

## 系统登记

```bash
systemctl list-unit-files | grep -i '<kw>'; systemctl --user list-unit-files | grep -i '<kw>'
crontab -l | grep -i '<kw>'; grep -ri '<kw>' /etc/cron.d 2>/dev/null
ls ~/.config/autostart/ | grep -i '<kw>'
```

删除服务属改状态:`systemctl disable --now <svc>` 经确认后执行,再删 unit 文件并 `systemctl daemon-reload`。

## 查不到时(源码安装)

- 回到源码目录 `make uninstall`(需要当时保留的 Makefile/install 清单)。
- 没有卸载入口:按 `find / -name '*<kw>*' 2>/dev/null` 的结果按归属人工判断,逐项确认;`/usr` 下的系统目录要格外保守。
