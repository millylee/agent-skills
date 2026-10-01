# Windows 软件痕迹地图

`scripts/inventory.ps1` 覆盖不到、或需要人工判断的位置。以下命令全部只读,可直接粘贴执行;`<kw>` 换成软件名关键词,`<Vendor>` 换成发行商名。

## 程序目录

| 位置 | 说明 |
| --- | --- |
| `%ProgramFiles%\`、`%ProgramFiles(x86)%` | 传统安装位 |
| `%LOCALAPPDATA%\Programs\` | per-user 安装器偏爱(VSCode、Chrome 用户级安装) |
| `%ProgramData%\` | 共享数据、服务组件 |
| 桌面、下载、`D:\` 等任意目录 | 便携版/绿色软件就放在这,没有安装记录 |

便携版的确认方式:问用户「放在哪」,或对可疑 exe 看数字签名与同目录 `unins*.exe`。

## 用户数据与配置

```powershell
Get-ChildItem $env:APPDATA, $env:LOCALAPPDATA -Directory | Where-Object Name -like '*<kw>*'
Get-ChildItem $env:USERPROFILE -Directory -Force | Where-Object Name -like '.*<kw>*'   # .xxx 点目录
```

- UWP 应用数据在 `%LOCALAPPDATA%\Packages\<PackageFamilyName>\`
- scoop 应用数据在 `~\scoop\persist\<app>`,卸载默认不删
- 配置删除前先备份:`Compress-Archive <path> "$env:TEMP\uninstall-backup\<app>.zip"`

## 注册表

```powershell
# 软件自己的键(最常见残留)
Get-ChildItem 'HKCU:\Software','HKLM:\SOFTWARE','HKLM:\SOFTWARE\WOW6432Node' |
  Where-Object PSChildName -like '*<kw>*'

# 卸载项(三处,脚本已覆盖,人工复核用)
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall
HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall

# 自启动
HKCU:\Software\Microsoft\Windows\CurrentVersion\Run
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run

# 其他登记
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\   # 应用路径别名
HKCR\*\shellex\ContextMenuHandlers\                          # 右键菜单
HKCR\CLSID\{...}                                             # shellex 指向的 COM 注册
```

注意:右键菜单 shellex 是 CLSID 链——先在 ContextMenuHandlers 找到 CLSID,确认 `HKCR\CLSID\{...}` 的 InprocServer32 路径属于目标软件,两处一起删;只删核实过归属的。

## 系统登记

```powershell
Get-Service | Where-Object { $_.Name -like '*<kw>*' -or $_.DisplayName -like '*<kw>*' }
Get-ScheduledTask | Where-Object TaskName -like '*<kw>*'
netsh advfirewall firewall show rule name=all | Select-String -Context 5 '<kw>'   # 防火墙规则
Get-MpPreference | Select-Object -ExpandProperty ExclusionPath                     # Defender 排除项
```

Defender 排除项最常被忽略:安装器加的目录/进程排除,卸载后应移除(`Remove-MpPreference -ExclusionPath <path>`,这条会改状态,列入清单经确认再执行)。

## 环境与关联

```powershell
[Environment]::GetEnvironmentVariable('Path','Machine') -split ';'
[Environment]::GetEnvironmentVariable('Path','User') -split ';'
Get-ItemProperty 'HKCU:\Environment'   # 用户级环境变量
```

- 默认应用/协议接管:让用户在「设置 → 默认应用」确认,脚本改不稳妥。
- hosts 劫持(部分国产软件爱加解析):查 `C:\Windows\System32\drivers\etc\hosts`。

## UWP / Store 专项

```powershell
Get-AppxPackage *<kw>* | Select-Object Name, PackageFullName, InstallLocation
```

删除属改状态操作,列入清单经确认后:`Remove-AppxPackage <PackageFullName>`(当前用户);要阻止所有新用户获得,再 `Remove-AppxProvisionedPackage -Online -PackageName <pkg>`。

## 查不到时的兜底

- 疑似装过但注册表被清:看 `C:\Windows\Prefetch\<kw>*.pf`(只读)和 `%LOCALAPPDATA%\CrashDumps` 确认曾经运行过。
- 卸载器损坏/报错:先重装同版本覆盖恢复卸载器再卸;MSI 注册坏了用微软官方 Program Install and Uninstall Troubleshooter;都失败才走手动清除,并在报告注明「卸载器不可用,手动清除」。
