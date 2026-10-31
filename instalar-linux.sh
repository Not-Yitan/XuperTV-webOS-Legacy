#!/usr/bin/env bash
# Instalador de XuperTV para LG webOS desde Linux (solo necesita ssh y curl).
# Uso: ./instalar-linux.sh IP_DE_LA_TV CLAVE_DEVELOPER_MODE [archivo.ipk]
set -euo pipefail

TV="${1:-}"; PASS="${2:-}"
[ -n "$TV" ] && [ -n "$PASS" ] || { echo "Uso: $0 IP_TV CLAVE [archivo.ipk]"; exit 1; }
AQUI="$(cd "$(dirname "$0")" && pwd)"
IPK="${3:-$(ls "$AQUI"/*.ipk | head -n 1)}"
R=/media/developer/temp
VER="$(ar p "$IPK" control.tar.gz | tar -xzO control 2>/dev/null | sed -n 's/^Version: //p')"
APP="$(ar p "$IPK" control.tar.gz | tar -xzO control 2>/dev/null | sed -n 's/^Package: //p')"
[ -n "$VER" ] && [ -n "$APP" ] || { echo "No pude leer la version o el id del .ipk"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
KEY="$TMP/key"

echo ">> Descargando la llave de la TV (puerto 9991)..."
curl -fsS -m 10 "http://$TV:9991/webos_rsa" -o "$KEY"
chmod 600 "$KEY"
ssh-keygen -p -m PEM -P "$PASS" -N '' -f "$KEY" >/dev/null 2>&1 \
  || { echo "Clave incorrecta (revisa la app Developer Mode)"; exit 1; }

SSH=(ssh -i "$KEY" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no
     -o UserKnownHostsFile=/dev/null -o HostKeyAlgorithms=+ssh-rsa
     -o PubkeyAcceptedAlgorithms=+ssh-rsa -o LogLevel=ERROR -p 9922 "prisoner@$TV")

# La TV no trae scp: se sube con cat por SSH.
echo ">> Subiendo $(basename "$IPK")..."
"${SSH[@]}" "cat > $R/app.ipk" < "$IPK"
printf '{"id":"%s","ipkUrl":"%s/app.ipk","subscribe":true}' "$APP" "$R" | "${SSH[@]}" "cat > $R/xuper-install.json"
printf '{"id":"%s"}' "$APP" | "${SSH[@]}" "cat > $R/xuper-launch.json"

echo ">> Instalando version $VER (puede tardar hasta 2 minutos)..."
"${SSH[@]}" "sh -s" <<REMOTE
APPD=/media/developer/apps/usr/palm/applications/$APP
SVC=/media/developer/apps/usr/palm/services/$APP.service
luna-send-pub -i -f luna://com.webos.appInstallService/dev/install "\$(cat $R/xuper-install.json)" > $R/install.log 2>&1 &
PID=\$!
i=0
while [ \$i -lt 75 ]; do
  V=\$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \$APPD/appinfo.json 2>/dev/null | head -n 1)
  [ "\$V" = "$VER" ] && break
  sleep 2; i=\$((i+1))
done
kill \$PID 2>/dev/null
[ "\$V" = "$VER" ] || { echo "La TV no confirmo la instalacion:"; tail -n 12 $R/install.log; exit 3; }
chmod 755 \$SVC/ffmpeg 2>/dev/null
luna-send-pub -n 1 -f luna://com.webos.applicationManager/launch "\$(cat $R/xuper-launch.json)" >/dev/null 2>&1
rm -f $R/app.ipk
echo "LISTO: version \$V instalada y abierta."
REMOTE
