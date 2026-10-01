#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only footprint inventory for a Windows application. Collects evidence,
  changes nothing on the system.
.PARAMETER Name
  Keyword to match (case-insensitive, wildcard-implied), e.g. "obs", "vscode".
.NOTES
  Output is plain-text sections; use it to build the uninstall checklist.
  Never use Get-CimInstance Win32_Product / wmic product here: every query
  triggers MSI self-repair.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name
)

$ErrorActionPreference = 'SilentlyContinue'
$like = "*" + $Name + "*"

function Section {
    param([string]$Title)
    Write-Output ''
    Write-Output ("===== " + $Title + " =====")
}

Section "System"
Write-Output ("OS       : " + [System.Environment]::OSVersion.VersionString)
Write-Output ("PS       : " + $PSVersionTable.PSVersion.ToString())
Write-Output ("64-bit   : " + [System.Environment]::Is64BitOperatingSystem)

# --- 1. Uninstall registry entries ------------------------------------------
Section "1. Uninstall registry entries (HKLM 64/32, HKCU)"
$uninstPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$apps = Get-ItemProperty -Path $uninstPaths |
    Where-Object { $_.DisplayName -and ($_.DisplayName -like $like -or $_.Publisher -like $like) }
if ($apps) {
    foreach ($a in $apps) {
        Write-Output ("Name        : " + $a.DisplayName)
        Write-Output ("Version     : " + $a.DisplayVersion)
        Write-Output ("Publisher   : " + $a.Publisher)
        Write-Output ("InstallLoc  : " + $a.InstallLocation)
        Write-Output ("Uninstall   : " + $a.UninstallString)
        Write-Output ("Key         : " + $a.PSChildName)
        Write-Output ''
    }
} else { Write-Output '(none)' }

# --- 2. Store / Appx packages ------------------------------------------------
Section "2. Store / Appx packages"
$appx = Get-AppxPackage | Where-Object { $_.Name -like $like }
if ($appx) {
    foreach ($p in $appx) {
        Write-Output ("Name        : " + $p.Name)
        Write-Output ("FullName    : " + $p.PackageFullName)
        Write-Output ("InstallLoc  : " + $p.InstallLocation)
        Write-Output ''
    }
} else { Write-Output '(none)' }

# --- 3. Package managers ------------------------------------------------------
Section "3. Package managers"
if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
    Write-Output '-- winget --'
    $w = winget list $Name --disable-interactivity --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and $w) { ($w | Out-String).Trim() } else { Write-Output '(no match)' }
} else { Write-Output '-- winget: not found --' }

Write-Output ''
if (Test-Path "$env:USERPROFILE\scoop\apps") {
    Write-Output '-- scoop (apps dir) --'
    $scoopApps = Get-ChildItem "$env:USERPROFILE\scoop\apps" -Directory |
        Where-Object { $_.Name -ne 'scoop' -and ($_.Name -like $like -or $_.Name -like ("." + $Name)) }
    if ($scoopApps) { $scoopApps | ForEach-Object { Write-Output $_.Name } } else { Write-Output '(no match)' }
} else { Write-Output '-- scoop: not found --' }

Write-Output ''
if (Test-Path 'C:\ProgramData\chocolatey\lib') {
    Write-Output '-- chocolatey (lib dir) --'
    $choco = Get-ChildItem 'C:\ProgramData\chocolatey\lib' -Directory | Where-Object { $_.Name -like $like }
    if ($choco) { $choco | ForEach-Object { Write-Output $_.Name } } else { Write-Output '(no match)' }
} else { Write-Output '-- chocolatey: not found --' }

Write-Output ''
if (Get-Command npm.cmd -ErrorAction SilentlyContinue) {
    Write-Output '-- npm global --'
    $npmOut = npm ls -g --depth=0 2>$null | Select-String -SimpleMatch $Name
    if ($npmOut) { ($npmOut | Out-String).Trim() } else { Write-Output '(no match)' }
} else { Write-Output '-- npm: not found --' }

Write-Output ''
if (Get-Command pip.exe -ErrorAction SilentlyContinue) {
    Write-Output '-- pip --'
    $pipOut = pip list 2>$null | Select-String -Pattern $Name
    if ($pipOut) { ($pipOut | Out-String).Trim() } else { Write-Output '(no match)' }
} else { Write-Output '-- pip: not found --' }

# --- 4. Running processes ------------------------------------------------------
Section "4. Running processes"
$procs = Get-Process | Where-Object { $_.Name -like $like -or ($_.Path -and $_.Path -like $like) }
if ($procs) {
    ($procs | Select-Object Id, Name, Path | Format-Table -AutoSize | Out-String -Width 300).TrimEnd()
} else { Write-Output '(none)' }

# --- 5. Services ----------------------------------------------------------------
Section "5. Services"
$svcs = Get-CimInstance Win32_Service |
    Where-Object { $_.Name -like $like -or $_.DisplayName -like $like -or $_.PathName -like $like }
if ($svcs) {
    ($svcs | Select-Object Name, DisplayName, State, StartMode, PathName | Format-List | Out-String -Width 300).TrimEnd()
} else { Write-Output '(none)' }

# --- 6. Scheduled tasks ----------------------------------------------------------
Section "6. Scheduled tasks"
$kw = $Name
$tasks = Get-ScheduledTask | Where-Object {
    $_.TaskName -like $like -or
    (($_.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -match [regex]::Escape($kw))
}
if ($tasks) {
    ($tasks | Select-Object TaskPath, TaskName, State | Format-Table -AutoSize | Out-String -Width 300).TrimEnd()
} else { Write-Output '(none)' }

# --- 7. Autostart -----------------------------------------------------------------
Section "7. Autostart (Run keys + Startup folders)"
$auto = @()
$runKeys = @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
)
foreach ($rk in $runKeys) {
    if (Test-Path $rk) {
        $props = Get-ItemProperty -Path $rk
        foreach ($p in $props.PSObject.Properties) {
            if ($p.Name -notlike 'PS*' -and ($p.Name -like $like -or $p.Value -like $like)) {
                $auto += ("[" + $rk + "] " + $p.Name + " = " + $p.Value)
            }
        }
    }
}
$startupDirs = @(
    ($env:APPDATA + '\Microsoft\Windows\Start Menu\Programs\Startup'),
    ($env:ProgramData + '\Microsoft\Windows\Start Menu\Programs\StartUp')
)
foreach ($sd in $startupDirs) {
    Get-ChildItem $sd -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like $like } |
        ForEach-Object { $auto += ("[" + $sd + "] " + $_.Name) }
}
if ($auto) { $auto | ForEach-Object { Write-Output $_ } } else { Write-Output '(none)' }

# --- 8. Directory hits --------------------------------------------------------------
Section "8. Directory hits (common locations)"
$dirRoots = @(
    $env:ProgramFiles,
    ${env:ProgramFiles(x86)},
    ($env:LOCALAPPDATA + '\Programs'),
    $env:LOCALAPPDATA,
    $env:APPDATA,
    $env:ProgramData,
    $env:USERPROFILE
)
$seen = @{}
foreach ($root in $dirRoots) {
    if ($root -and (Test-Path $root)) {
        Get-ChildItem $root -Directory -Force |
            Where-Object { $_.Name -like $like -or $_.Name -like ("." + $Name + "*") } |
            ForEach-Object { $seen[$_.FullName] = $true }
    }
}
if ($seen.Count -gt 0) { $seen.Keys | Sort-Object | ForEach-Object { Write-Output $_ } } else { Write-Output '(none)' }

# --- 9. PATH entries ------------------------------------------------------------------
Section "9. PATH entries mentioning it"
$mPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
$uPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$pathHits = (($mPath + ';' + $uPath) -split ';') |
    Where-Object { $_ -and $_ -like $like } | Select-Object -Unique
if ($pathHits) { $pathHits | ForEach-Object { Write-Output $_ } } else { Write-Output '(none)' }

# --- 10. Defender exclusions ------------------------------------------------------------
Section "10. Defender exclusions"
$mp = Get-MpPreference
if ($mp) {
    $ex = @()
    $ex += $mp.ExclusionPath
    $ex += $mp.ExclusionProcess
    $exHits = $ex | Where-Object { $_ -like $like } | Select-Object -Unique
    if ($exHits) { $exHits | ForEach-Object { Write-Output $_ } } else { Write-Output '(none)' }
} else { Write-Output '(Defender cmdlets unavailable)' }

# --- 11. Firewall rules -------------------------------------------------------------------
Section "11. Firewall rules"
$fw = Get-NetFirewallRule | Where-Object { $_.DisplayName -like $like -or $_.Name -like $like }
if ($fw) {
    $fw | ForEach-Object {
        Write-Output ($_.DisplayName + "  [" + $_.Direction + "/" + $_.Action + "/Enabled=" + $_.Enabled + "]")
    }
} else { Write-Output '(none)' }

Section "Inventory complete (read-only, nothing was changed)"
