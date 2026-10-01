#!/usr/bin/env bash
# Read-only footprint inventory for macOS and Linux. Collects evidence, changes
# nothing on the system.
#
# Compatible with macOS stock bash 3.2: no associative arrays, no ${var,,}.
# Usage: bash inventory.sh <keyword>
# Windows users: run inventory.ps1 instead (this script refuses MINGW/MSYS).

set -u

NAME="${1:-}"
[ -z "$NAME" ] && { echo "Usage: bash inventory.sh <keyword>"; exit 2; }

case "$(uname -s)" in
    Darwin) OS="mac" ;;
    Linux)  OS="linux" ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "Windows detected: use scripts/inventory.ps1 instead."
        exit 3 ;;
    *)
        echo "Unsupported platform: $(uname -s)"
        exit 3 ;;
esac

section() { printf '\n===== %s =====\n' "$1"; }
have()    { command -v "$1" >/dev/null 2>&1; }

section "System"
uname -srm
if [ "$OS" = "mac" ]; then
    sw_vers 2>/dev/null
else
    [ -r /etc/os-release ] && grep -E '^(PRETTY_NAME|ID|VERSION_ID)=' /etc/os-release
fi

# --- 1. Package records ------------------------------------------------------
section "1. Package records"
if [ "$OS" = "mac" ]; then
    echo "-- pkgutil receipts --"
    pkgutil --pkgs 2>/dev/null | grep -i -- "$NAME" || echo '(none)'
    if have brew; then
        echo "-- brew formulae --"
        brew list --formula 2>/dev/null | grep -i -- "$NAME" || echo '(none)'
        echo "-- brew casks --"
        brew list --cask 2>/dev/null | grep -i -- "$NAME" || echo '(none)'
    else
        echo "-- brew: not found --"
    fi
else
    PM=0
    if have dpkg; then
        echo "-- dpkg --"
        dpkg -l 2>/dev/null | grep -i -- "$NAME" || echo '(none)'
        PM=1
    fi
    if have rpm; then
        echo "-- rpm --"
        rpm -qa 2>/dev/null | grep -i -- "$NAME" | sort || echo '(none)'
        PM=1
    fi
    if have pacman; then
        echo "-- pacman --"
        pacman -Qs "$NAME" 2>/dev/null || echo '(none)'
        PM=1
    fi
    if have snap; then
        echo "-- snap --"
        snap list 2>/dev/null | grep -i -- "$NAME" || echo '(none)'
        PM=1
    fi
    if have flatpak; then
        echo "-- flatpak --"
        flatpak list 2>/dev/null | grep -i -- "$NAME" || echo '(none)'
        PM=1
    fi
    [ "$PM" -eq 0 ] && echo '(no system package manager found)'
fi
if have npm; then
    echo "-- npm global --"
    npm ls -g --depth=0 2>/dev/null | grep -i -- "$NAME" || echo '(no match)'
fi
if have pip || have pip3; then
    echo "-- pip --"
    PIP="$(command -v pip || command -v pip3)"
    "$PIP" list 2>/dev/null | grep -i -- "$NAME" || echo '(no match)'
fi
if have cargo; then
    echo "-- cargo --"
    cargo install --list 2>/dev/null | grep -i -- "$NAME" || echo '(no match)'
fi

# --- 2. Install locations ----------------------------------------------------
section "2. Install locations"
if [ "$OS" = "mac" ]; then
    FOUND=$(find /Applications "$HOME/Applications" -maxdepth 1 -iname "*$NAME*" 2>/dev/null | head -50)
else
    FOUND=$(find /opt /usr/local "$HOME/.local" -maxdepth 2 -iname "*$NAME*" 2>/dev/null | head -50)
    find /usr/share/applications "$HOME/.local/share/applications" -maxdepth 1 -iname '*.desktop' \
        -exec grep -il -- "$NAME" {} + 2>/dev/null
fi
if [ -n "$FOUND" ]; then printf '%s\n' "$FOUND"; else echo '(none)'; fi

# --- 3. Running processes ----------------------------------------------------
section "3. Running processes"
ps aux | grep -i -- "$NAME" | grep -v -e grep -e inventory.sh || echo '(none)'

# --- 4. Services, daemons, autostart -----------------------------------------
section "4. Services, daemons, autostart"
if [ "$OS" = "mac" ]; then
    launchctl list 2>/dev/null | grep -i -- "$NAME" || echo '(launchd: none)'
    for d in /Library/LaunchAgents /Library/LaunchDaemons "$HOME/Library/LaunchAgents"; do
        ls -d "$d"/*"$NAME"* 2>/dev/null
    done
    if have brew; then
        echo "-- brew services --"
        brew services list 2>/dev/null | grep -i -- "$NAME" || echo '(none)'
    fi
else
    if have systemctl; then
        echo "-- system units --"
        systemctl list-units --all --type=service 2>/dev/null | grep -i -- "$NAME" || echo '(none)'
        echo "-- user units --"
        systemctl --user list-units --all --type=service 2>/dev/null | grep -i -- "$NAME" || echo '(none)'
        echo "-- unit files --"
        systemctl list-unit-files 2>/dev/null | grep -i -- "$NAME" || echo '(none)'
    fi
    echo "-- cron --"
    crontab -l 2>/dev/null | grep -i -- "$NAME" || echo '(none)'
    [ -d /etc/cron.d ] && grep -ril -- "$NAME" /etc/cron.d 2>/dev/null
    ls "$HOME"/.config/autostart/*"$NAME"* 2>/dev/null
    grep -il -- "$NAME" "$HOME"/.config/autostart/*.desktop 2>/dev/null
fi

# --- 5. Directory hits ---------------------------------------------------------
section "5. Directory hits (common locations)"
if [ "$OS" = "mac" ]; then
    ROOTS="$HOME/Library/Application Support|$HOME/Library/Caches|$HOME/Library/Preferences|$HOME/Library/Logs|$HOME/Library/Saved Application State|$HOME/Library/Containers|$HOME/Library/Group Containers|/Library/Application Support"
else
    ROOTS="$HOME/.config|$HOME/.cache|$HOME/.local/share|$HOME/.local/state|/etc"
fi
TMP="$(mktemp)"
IFS='|'
for d in $ROOTS; do
    find "$d" -maxdepth 1 -iname "*$NAME*" 2>/dev/null >> "$TMP"
done
unset IFS
find "$HOME" -maxdepth 1 -iname "*$NAME*" 2>/dev/null >> "$TMP"
sort -u "$TMP" > "${TMP}.sorted"
if [ -s "${TMP}.sorted" ]; then
    cat "${TMP}.sorted"
else
    echo '(none)'
fi
rm -f "$TMP" "${TMP}.sorted"

# --- 6. PATH entries -------------------------------------------------------------
section "6. PATH entries mentioning it"
printf '%s\n' "$PATH" | tr ':' '\n' | grep -i -- "$NAME" || echo '(none)'

# --- 7. defaults domains (macOS only) ---------------------------------------------
if [ "$OS" = "mac" ]; then
    section "7. defaults domains"
    defaults domains 2>/dev/null | tr ',' '\n' | grep -i -- "$NAME" || echo '(none)'
fi

section "Inventory complete (read-only, nothing was changed)"
