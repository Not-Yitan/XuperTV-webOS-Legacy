# Xuper TV para TV LG antiguas (webOS 1 a 3)

Variante de la app para televisores LG de 2014 a 2017, con navegador y Node más viejos que los de webOS 4.

**Créditos:** basado en el port de webOS de **CristianDev**, que autorizó su uso y modificación. Proyecto no oficial, sin relación con Xuper TV ni con LG. No incluye contenido audiovisual.

## Qué cambia respecto a la versión normal

| | Versión normal | Esta (legacy) |
|---|---|---|
| Servicio (catálogo y streaming) | Dentro de la TV | **En un PC** de tu red |
| Video H.265 | Directo | **Convertido a H.264** por el PC |
| Id de la app | `com.notyitan.tv` | `com.notyitan.tv.legacy` |

Las TV viejas no tienen el servicio Node necesario ni reproducen H.265, así que la app es solo la interfaz y el PC hace el trabajo pesado. El JavaScript es ES5 (sin `Promise` ni `fetch`), el CSS lleva prefijos `-webkit-` y no usa `gap` en flexbox.

## 1. Servidor (PC en la misma red)

Usa `server/` del repo **XuperTV-Samsung**, en modo TV antigua:

```bash
sudo apt install nodejs ffmpeg
./iniciar-servidor.sh --tv-antigua      # Windows: INICIAR-SERVIDOR-TV-ANTIGUA.bat
curl http://IP_DEL_PC:8910/ping
```

## 2. Crear el instalable

```bash
./crear-ipk.sh http://IP_DEL_PC:8910
```

Genera `com.notyitan.tv.legacy_1.0.0_all.ipk` con la dirección del servidor dentro. Si cambia la IP del PC, vuelve a crearlo. En Windows, ejecútalo desde WSL.

## 3. Instalar en la TV

En la TV, activa **Developer Mode** (app de LG Content Store) y anota la IP y la clave. Luego:

```bash
./instalar-linux.sh IP_DE_LA_TV CLAVE
```

(o `ares-install` si lo tienes instalado).

## Estado

- El `.ipk` se crea correctamente y el servidor convierte H.265 a H.264 (probado: 720p High + AAC).
- **No probado en una TV LG antigua.** No sé qué versión de webOS tendrá la tuya; si falla, pásame el modelo y el error.
- La conversión de video usa bastante CPU del PC: con equipos lentos puede cortarse.
