#!/usr/bin/env bash
# Install or update the IP Region plasmoid for the current user.
set -euo pipefail
cd "$(dirname "$0")"
ID=org.kde.plasma.ipregion
if [ -d "$HOME/.local/share/plasma/plasmoids/$ID" ]; then
    kpackagetool6 -t Plasma/Applet -u .
else
    kpackagetool6 -t Plasma/Applet -i .
fi
systemctl --user restart plasma-plasmashell || true
echo "OK: правый клик по панели -> Добавить виджеты -> IP Region"
