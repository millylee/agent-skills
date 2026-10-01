---
name: clean-uninstall
description: Fully uninstall software without leftovers on Windows, macOS, and Linux. Detects how an app was installed (installer, MSI, winget, scoop, chocolatey, Store, brew, apt/dnf/pacman/zypper, snap, flatpak, npm/pip, portable) and where, inventories every footprint (directories, registry/defaults, services and daemons, scheduled tasks, launchd, autostart, firewall, Defender exclusions), decides what to delete vs keep, then runs the official uninstaller and sweeps remains. Use whenever the user wants to uninstall, remove, or completely clean an application — even if they only say "卸载 xx"、"把 xx 清干净" or ask whether it is safe to delete an app folder.
---

# 干净卸载软件(Windows / macOS / Linux)

三步原则:**先盘点、再确认、后动手**;动手时**先官方卸载器、后手动清扫**。
最大的风险不是删不干净,而是误删共享组件或其他软件的东西。宁可残留,不可误删。

## 第 0 步:识别平台

`uname -s`:Darwin → macOS;Linux → Linux;MINGW*/MSYS* → Windows。按平台选择工具与参考:

| 平台 | 侦察脚本 | 痕迹参考 | 卸载器参考 |
| --- | --- | --- | --- |
| Windows | `scripts/inventory.ps1` | `references/footprint-windows.md` | `references/uninstallers-windows.md` |
| macOS | `scripts/inventory.sh`(自动识别) | `references/footprint-macos.md` | `references/uninstallers-macos.md` |
| Linux | `scripts/inventory.sh`(自动识别) | `references/footprint-linux.md` | `references/uninstallers-linux.md` |

## 第 1 步:侦察(只读)

```powershell
# Windows
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-dir>/scripts/inventory.ps1 -Name <关键词>
```
```bash
# macOS / Linux(bash 3.2+ 即可,无需安装依赖)
bash <skill-dir>/scripts/inventory.sh <关键词>
```

两个脚本都只读、不改任何状态,输出分段文本:安装记录(注册表卸载项/Appx/winget/scoop/choco/npm/pip 或 pkgutil/brew/dpkg/rpm/pacman/snap/flatpak/npm/pip/cargo)、进程、服务与守护、自启动、常见目录命中、PATH 等。

- 输出为空 ≠ 没装过:便携版/绿色软件/手动编译没有安装记录,按对应 `footprint-*.md` 人工补查。
- Windows 禁止用 `Get-CimInstance Win32_Product` 或 `wmic product` 查 MSI:每次枚举都会触发 MSI 自修复。

## 第 2 步:出具卸载清单,等用户确认

先问清意图:**只是卸载,还是连配置和个人数据一起清?**这决定清扫范围(卸载后要不要重装回来是关键判据)。

把盘点结果整理成一张表,逐项给处置建议:

| 类别 | 典型条目 | 处置 |
| --- | --- | --- |
| 卸载器会处理 | 主程序、快捷方式/桌面入口 | 标注即可,无需手动 |
| 需手动清扫 | 残留目录、配置键、自启动、服务/守护、防火墙规则 | 卸载器跑完后逐项删 |
| 默认保留 | 共享运行库与系统组件、许可证、可能复用的用户数据 | 不动,报告里说明原因 |
| 询问用户 | 配置与个人数据 | 重装→保留;彻底清除→先备份再删 |

「默认保留」的平台示例:Windows 的 VC++ Redist / .NET / WebView2;macOS 的系统框架、`/Library/Application Support` 下可能多 App 共用的目录、Xcode CLT;Linux 的 glibc、发行版基础包、内核模块。

危险信号,发现即停下向用户确认:名称相近的其他软件的目录或配置、多软件共享的目录、系统组件、驱动/内核扩展。

## 第 3 步:执行

顺序不可颠倒:

1. **结束进程、停止服务/守护**:`Stop-Process`/`Stop-Service`,`launchctl bootout`,`systemctl disable --now`。文件被占用是残留的最常见原因。
2. **跑官方卸载器**:包管理器来源一律用包管理器(`winget uninstall --silent`、`brew uninstall --cask`、`apt purge`、`dnf remove`、`pacman -Rns`、`snap remove`、`flatpak uninstall`)。exe 安装包的静默参数查 `references/uninstallers-windows.md`,从注册表 `UninstallString` 改造,不要凭空猜。注意 purge/remove/-Rns 在各发行版的「连不连配置」语义差异,查 `references/uninstallers-linux.md`。
3. **清扫残留**:对照第 2 步清单逐项删,每删一项前核对归属;删配置前先备份到 `%TEMP%\uninstall-backup\<app>\` 或 `~/.cache/uninstall-backup/<app>/`。
4. **收尾**:发现文件被占用或要求重启,记入报告,提示重启后复扫一次。

## 第 4 步:验证与报告

复跑盘点脚本确认关键条目已消失。输出四栏报告:

- **已删除**:逐项列出
- **已保留**:逐项列出 + 原因(共享组件 / 用户要求 / 不确定)
- **需重启**:被占用文件、`PendingFileRenameOperations`、标记删除的服务
- **手动步骤**:脚本删不了、需要用户自己操作的

不确定的条目宁可保留并写进报告,不要顺手删。

## 红线

- 共享运行库与系统组件(VC++ Redist、.NET、WebView2、系统框架、glibc、发行版基础包、驱动/内核扩展)永不卸载。
- 不用通配符或文件名匹配批量删除,只删核实过归属的路径与配置。
- 先跑卸载器再清扫(卸载器需要自身文件);先备份再删配置。
- 侦察只读(用脚本),删除逐项执行;禁止递归删除来路不明的目录。
