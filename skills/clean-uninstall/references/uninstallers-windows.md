# 卸载器类型与静默参数

从注册表 `UninstallString` 判断类型(侦察脚本第 1 节),再按下表改造。**保留原参数,只追加静默 flag**;路径带空格整体加引号。

| 类型 | 识别特征 | 静默卸载 |
| --- | --- | --- |
| MSI | 键名是 `{GUID}`,或 UninstallString 含 `msiexec /I{GUID}` | `msiexec /x {GUID} /qn /norestart`(可加 `/L*v "%TEMP%\unins.log"` 留日志) |
| Inno Setup | 卸载器名 `unins000.exe`、`unins001.exe` | `unins000.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART` |
| NSIS | 卸载器名 `uninst.exe`、`Uninstall.exe` | `uninst.exe /S`(S 必须大写) |
| InstallShield | `Setup.exe` + 同目录 `Setup.ini`,或参数含 `-uninst` | 内嵌 MSI 时 `Setup.exe /s /v"/qn"`;纯脚本型需 response file,建议直接交互式卸载 |
| WiX Burn | 单文件 exe 引导器 | `bundle.exe /uninstall -quiet -norestart` |
| MS Store / Appx | 无 UninstallString,`Get-AppxPackage` 有记录 | `Remove-AppxPackage <PackageFullName>` |

## 包管理器优先

能确定来源就用包管理器卸,别去碰 exe:

```powershell
winget uninstall --id <Id> --silent --disable-interactivity
scoop uninstall <app>        # 数据在 ~\scoop\persist\<app>,默认保留
choco uninstall <app> -y
npm rm -g <pkg>
pip uninstall -y <pkg>
```

注意:winget 对非 winget 安装的软件也能找到卸载器,但按 UninstallString 走的还是原安装器的逻辑,残留清扫照做不误。

## 卸载器跑完后的常见残留

- 程序目录本身(Inno/NSIS 只删它注册过的文件)
- `%APPDATA%\`、`%LOCALAPPDATA%\` 下的配置与缓存目录
- `HKCU\Software\<Vendor>` 注册表键
- 自启动:Run 键、Startup 文件夹
- 服务(标记删除,需重启才真正消失)
- 防火墙规则、Defender 排除项
- 右键菜单、文件关联

## 卸载器损坏的兜底

1. 重装同版本覆盖,恢复卸载器后再卸。
2. MSI 注册损坏:微软官方 Program Install and Uninstall Troubleshooter(`MicrosoftProgram_Install_and_Uninstall.meta.diagcab`)。
3. 都失败:按 `footprint-windows.md` 手动清除,报告注明「卸载器不可用,手动清除」。
