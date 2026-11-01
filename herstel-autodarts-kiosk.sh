#!/usr/bin/env bash
# Herstel voor Ubuntu NUCs waarop Chromium na een update Autodarts Play blokkeert.
set -Eeuo pipefail

fail() { printf 'FOUT: %s\n' "$*" >&2; exit 1; }
say() { printf '\n==> %s\n' "$*"; }

[[ ${EUID} -eq 0 ]] || fail 'Start dit bestand met: sudo bash herstel-autodarts-kiosk.sh'
[[ -n ${SUDO_USER:-} && ${SUDO_USER} != root ]] || fail 'Start vanuit de normale Autodarts-gebruiker met sudo.'
[[ $(dpkg --print-architecture) == amd64 ]] || fail 'Dit herstel is alleen bedoeld voor Ubuntu op een x86-64 NUC.'
[[ -f /etc/os-release ]] || fail 'Ubuntu is niet herkend.'
. /etc/os-release
[[ ${ID:-} == ubuntu ]] || fail 'Dit herstel is alleen getest voor Ubuntu.'

target_user=$SUDO_USER
target_home=$(getent passwd "$target_user" | cut -d: -f6)
[[ -n $target_home && -d $target_home ]] || fail 'De thuismap van de gebruiker ontbreekt.'
[[ -x /usr/bin/apt-get ]] || fail 'apt-get ontbreekt.'

say 'Google Chrome downloaden en installeren'
tmpdir=$(mktemp -d)
trap 'rm -rf -- "$tmpdir"' EXIT
apt-get update -qq
apt-get install -y curl ca-certificates
curl --fail --location --show-error --silent --retry 3 \
  https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
  -o "$tmpdir/google-chrome-stable.deb"
[[ $(dpkg-deb -f "$tmpdir/google-chrome-stable.deb" Package) == google-chrome-stable ]] || fail 'Het gedownloade pakket is geen Google Chrome Stable.'
[[ $(dpkg-deb -f "$tmpdir/google-chrome-stable.deb" Architecture) == amd64 ]] || fail 'Verkeerde pakketarchitectuur.'
apt-get install -y "$tmpdir/google-chrome-stable.deb"
command -v google-chrome-stable >/dev/null || fail 'Google Chrome is niet geïnstalleerd.'

say 'Bestaande Autodarts-browserstart veilig bewaren'
stamp=$(date +%Y%m%d-%H%M%S)
backup_dir="$target_home/autodarts-kiosk-backup-$stamp"
install -d -m 700 -o "$target_user" -g "$(id -gn "$target_user")" "$backup_dir"
autostart_dir="$target_home/.config/autostart"
install -d -m 755 -o "$target_user" -g "$(id -gn "$target_user")" "$autostart_dir"

# Schakel alleen autostartbestanden uit die duidelijk Autodarts Play openen.
shopt -s nullglob
for entry in "$autostart_dir"/*.desktop; do
  if grep -Eiq '^Name=.*autodarts|^Exec=.*(play\.autodarts\.(com|io)|start-autodarts-browser)' "$entry"; then
    mv -- "$entry" "$backup_dir/$(basename "$entry")"
  fi
done

launcher=/usr/local/bin/start-autodarts-browser.sh
if [[ -e $launcher ]]; then
  cp -a -- "$launcher" "$backup_dir/start-autodarts-browser.sh"
fi

say 'Autodarts-kiosk instellen'
cat > "$launcher" <<'LAUNCHER'
#!/usr/bin/env bash
set -u
url=https://play.autodarts.com

# Geef het netwerk en de lokale Autodarts-service tijd om op te komen.
for (( i=0; i<60; i++ )); do
  if curl --fail --silent --show-error --head --max-time 5 "$url" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

exec /usr/bin/google-chrome-stable \
  --password-store=basic \
  --no-first-run \
  --no-default-browser-check \
  --disable-session-crashed-bubble \
  --kiosk "$url"
LAUNCHER
chmod 755 "$launcher"

cat > "$autostart_dir/autodarts-kiosk.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Autodarts Play Kiosk
Comment=Start Autodarts Play schermvullend
Exec=/usr/local/bin/start-autodarts-browser.sh
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP
chown "$target_user:$(id -gn "$target_user")" "$autostart_dir/autodarts-kiosk.desktop"
chmod 644 "$autostart_dir/autodarts-kiosk.desktop"

if systemctl list-unit-files autodarts.service --no-legend 2>/dev/null | grep -q '^autodarts.service'; then
  systemctl enable --now autodarts.service
  say 'Autodarts-service staat aan'
fi

say 'Klaar'
printf 'Chrome: %s\n' "$(google-chrome-stable --version)"
printf 'Back-up: %s\n' "$backup_dir"
printf 'Herstart de NUC om de kiosk te controleren. De eerste keer kan aanmelden bij Autodarts Play nodig zijn.\n'
printf 'De bestaande board_id, api_key, camera-instellingen en browserprofielen zijn niet gewijzigd.\n'
