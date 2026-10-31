#!/usr/bin/env bash
# Crea el .ipk para TV LG antiguas con la direccion de tu servidor.
# Uso: ./crear-ipk.sh http://IP_DEL_PC:8910
set -euo pipefail
SERVER="${1:?Uso: $0 http://IP_DEL_PC:8910}"
case "$SERVER" in http://*|https://*) ;; *) echo "La direccion debe empezar por http://"; exit 1;; esac
SERVER="${SERVER%/}"
AQUI="$(cd "$(dirname "$0")" && pwd)"
ID=com.notyitan.tv.legacy
VER="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$AQUI/app/appinfo.json" | head -n 1)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

mkdir -p "$W/d/usr/palm/applications/$ID" "$W/d/usr/palm/packages/$ID" "$W/c"
cp -r "$AQUI/app/." "$W/d/usr/palm/applications/$ID/"
sed -i -E "s#devServiceUrl:\"[^\"]*\"#devServiceUrl:\"$SERVER\"#" "$W/d/usr/palm/applications/$ID/config/api.js"
printf '{\n  "id": "%s",\n  "version": "%s",\n  "app": "%s"\n}\n' "$ID" "$VER" "$ID" > "$W/d/usr/palm/packages/$ID/packageinfo.json"
SIZE="$(du -sb "$W/d" | cut -f1)"
cat > "$W/c/control" <<CTL
Package: $ID
Version: $VER
Section: misc
Priority: optional
Architecture: all
Installed-Size: $SIZE
Maintainer: Not-Yitan <nobody@example.com>
Description: Xuper TV para TV LG antiguas (webOS 1 a 3)
webOS-Package-Format-Version: 2
webOS-Packager-Version: x.y.x
CTL
echo 2.0 > "$W/debian-binary"
(cd "$W/d" && tar --owner=0 --group=0 --numeric-owner -czf "$W/data.tar.gz" usr)
(cd "$W/c" && tar --owner=0 --group=0 --numeric-owner -czf "$W/control.tar.gz" control)
OUT="$AQUI/${ID}_${VER}_all.ipk"
rm -f "$OUT"
(cd "$W" && ar rc "$OUT" debian-binary control.tar.gz data.tar.gz)
echo "Creado: $OUT  (servidor: $SERVER)"
