# CLAUDE.md — ARM (Global)

Este archivo se lee en TODOS los proyectos de ARM. Contiene lecciones aprendidas que aplican transversalmente.

## DIRECTIVAS COMPARTIDAS
Leer siempre:
- `/home/ubuntu/projects/shared/super-yo.md` — reglas universales de Pablo (onboarding completo, metodología, infraestructura, deploy)

---

## IMÁGENES DE PABLO — cómo las vas a ver

Pablo trabaja desde el terminal de su MacBook (SSH a ARM). El terminal no pasa clipboard de imagen, así que hay un **bridge automático Mac→ARM**:

- Pablo hace `cmd+shift+4` (o arrastra imagen) → se guarda en `~/Imágenes/Captura de pantalla/` del Mac
- Un LaunchAgent del Mac sube via rsync a: **`/home/ubuntu/inbox/claude-images/`** en ARM
- Delay: 2-3 segundos desde que la capturó

**Cuando Pablo te diga "mirá la imagen", "fijate la nueva", "revisá la captura"** o cualquier variante que apunte a una imagen:

```bash
# Listar la más reciente:
ls -t /home/ubuntu/inbox/claude-images/*.png 2>/dev/null | head -1
```

Después usar el tool `Read` con ese path (Claude Code lee imágenes PNG/JPG directo).

**Reglas:**
- **NO leer automáticamente al inicio de sesión.** Pablo captura también cosas para otros usos (WhatsApp, iMessage, otros proyectos) → no todas las imágenes son para vos.
- **NO proponer** hooks SessionStart que listen imágenes sin que Pablo pida.
- Sync es unidireccional Mac→ARM con `--delete`: si Pablo borra del Mac, se borra de ARM. No crear archivos en ese directorio desde ARM (se pierden en el siguiente sync).
- Si no hay archivos en `/home/ubuntu/inbox/claude-images/`, decile que no llegó nada — puede ser que el sync haya fallado o que la hubiera borrado.

---

## DEPLOY — DOS SISTEMAS

### Deploy ARM (NUEVO — abril 2026)
Proyectos migrados a ARM corren localmente con PM2, Nginx, SSL. Sin Replit.
```bash
deploy-arm.sh <proyecto>          # deploy completo con health check
rollback-arm.sh <proyecto>        # rollback instantáneo (~5 seg)
rollback-arm.sh <proyecto> v2     # rollback a versión específica
```
- 5 releases por proyecto, auto-rollback si falla
- Dashboard visual: https://oraculo-pablo.duckdns.org/dashboard#deploys
- Registry: `/home/ubuntu/deployments/registry.json`
- Estructura: `/home/ubuntu/deployments/{proyecto}/releases/`, `current` symlink, `shared/`

### Deploy Replit (LEGACY — en migración)
Para proyectos que todavía NO migraron a ARM.
- Script: `deploy-repl-hybrid.cjs`
- Cookies expiran cada 7 días, auto-renew cada 5 días
- Cloudflare bloquea headless desde ARM — usar Chrome+xdotool

### Verificación post-deploy — OBLIGATORIO (AMBOS SISTEMAS)
**NUNCA decir "deploy verificado" sin curl real.**

---

## DOMINIOS

### Dominio propio: gruposer.com.ar (DonWeb)
- **gruposer.com.ar** → ISR-web (34.111.179.208)
- **seragro.gruposer.com.ar** → seragro (34.111.179.208)
- **odoo.gruposer.com.ar** → Odoo 18 Community Grupo SER en ARM (161.153.207.224, systemd `odoo.service`, puerto 8069)
- DNS se maneja desde: micuenta.donweb.com → Nameservers y Zona DNS
- Para agregar subdominio: registro tipo A, nombre: subdominio, contenido: 161.153.207.224

### DuckDNS (proyectos sin dominio propio)

**Cuenta A (legacy):**
- `oraculo-pablo.duckdns.org` → Oráculo dashboard/MCP
- `tutorai.duckdns.org` → TutorAI
- Token: `034f876d-85db-46ca-8f88-44210863a398`

**Cuenta B (pansapablo@gmail.com, activa para nuevos proyectos):**
- Token: `45354c0d-31f4-4805-bcc7-1588b7a310d1`
- Los subs nuevos (`dania-captador`, `vendetta-arm`, `servistecnicos`, etc.) van acá
- **API es update-only** (no crea subs nuevos): Pablo tiene que hacer "add domain" en la web UNA vez, después Oráculo hace update de IP via API automático

Para scripts nuevos usar cuenta B por default.

---

## LECCIONES APRENDIDAS

### Deploy — LECCIÓN CRÍTICA (ISR-web, abril 2026)
- **NUNCA decir "deploy verificado"** sin haber ejecutado curl y mostrado el output
- Si el script no dijo "DEPLOY COMPLETADO" textual → NO se deployó

### Integraciones — LECCIÓN CRÍTICA (CRM SQL Server, abril 2026)
- **NUNCA decir "integración hecha" sin EVIDENCIA REAL**: query ejecutado, datos reales mostrados
- Si decís "conecté SQL Server/Odoo/API X", mostrá: 1) grep del código con la librería instalada 2) output de un query real 3) datos concretos (no inventados)
- **NUNCA cambiar algo cosmético (intervalo, config) y decir que es la integración**
- Verificación mínima para integraciones externas:
  - `grep -r "mssql\|tedious\|odoo\|xmlrpc" src/` → debe existir código real
  - `npm list` o `pip list` → la dependencia debe estar instalada
  - Un query de prueba ejecutado → datos reales en el output
- Si no tenés credenciales, **DECILO**: "No tengo IP/user/pass del SQL Server, no puedo avanzar"
- **NUNCA inventar datos o simular una integración** — Pablo perdió días por esto

### Migración de Replits a ARM — LECCIÓN CRÍTICA (TutorAI, abril 2026)
Migrar un proyecto a ARM NO es solo mover el código. Checklist OBLIGATORIO:
1. **Datos**: migrar base de datos completa (usuarios, contenido, progreso). Verificar con `SELECT count(*) FROM users` que los datos llegaron.
2. **Uploads/media**: copiar videos, imágenes, archivos subidos. Si el Replit tiene `/uploads/`, `/public/videos/`, etc → copiar a ARM.
3. **SSH config**: actualizar `/home/ubuntu/oraculo-config/ssh-config-replits` — el Host del proyecto migrado debe apuntar a `localhost` o eliminarse (ya no es Replit).
4. **Variables de entorno**: copiar `.env` del Replit al `shared/.env` de ARM.
5. **NUNCA decir "migrado"** sin verificar: a) la app responde con curl, b) los datos existen (query real), c) los uploads están.
6. **CLAUDE.md del proyecto migrado**: actualizarlo para reemplazar la URL Replit vieja por la URL ARM nueva. Caso contrario, las RC siguen usando la URL vieja (pasó con servistecnicosRED, 2026-04-21).
- TutorAI se migró sin usuarios ni videos. Inaceptable.

### URLs productivas por proyecto ARM (fuente de verdad — NO usar URLs Replit viejas)
Proyectos migrados a ARM (abril 2026). Cuando se toque CADA uno, usar la URL ARM para testing, screenshots, manuales, curl:

| Proyecto | URL ARM (producción) | Puerto interno | PM2/systemd |
|----------|----------------------|----------------|-------------|
| oraculo | https://oraculo-pablo.duckdns.org | 5000 | PM2 `oraculo` |
| tutorai | https://tutorai.duckdns.org | 3001 | PM2 `tutorai` |
| odoo.gruposer.com.ar | https://odoo.gruposer.com.ar | 8069 | systemd `odoo.service` |
| dania-captador | https://dania-captador.duckdns.org | 3002 | PM2 `dania-captador` |
| servistecnicos-red | https://servistecnicos.duckdns.org | 3003 | PM2 `servistecnicos-red` |
| vendetta-api | https://vendetta-arm.duckdns.org | 3004 | PM2 `vendetta-api` |
| ceiepar (WP) | https://ceiep.ar (pendiente Cloudflare) | 8081 | PM2 `ceiepar` |

**Regla:** las URLs Replit `*.replit.app` de estos proyectos están deprecated. NO usarlas para testing, screenshots o manuales.

### SSH desde ARM
- ARM tiene SSH directo a TODOS los Replits (keys `replit` e `id_ed25519` en `~/.ssh/`)
- ARM NO depende de ZIVON para nada

### Procesos huérfanos
- Después de PM2 restart: `ps aux | grep claude` para verificar no queden fantasmas

### GitHub auth
- NO usar `gh auth login` (requiere `read:org`)
- Usar `git credential store` con PAT en URL directo

### PM2 restart
- SIEMPRE con delay: `nohup bash -c 'sleep 3 && pm2 restart X --update-env' &`
- NUNCA restart directo desde una tarea de Oráculo

### SmartScreen Windows
- Desactivado en el Asus de Pablo (10 abril 2026)

---

## COMPUTER-USE MCP (Mac de Pablo) — lecciones 2026-04-23

Esta sección aplica cuando trabajás con Pablo desde una instancia Claude que tiene **computer-use MCP** habilitado sobre su MacBook (típicamente claude.ai Desktop/web, NO desde RCs de ARM que no tienen computer-use). Reglas para evitar repetir errores ya vividos.

### `request_access` — batchear al inicio, NUNCA a mitad de tarea
- Pedí **TODAS las apps que vas a necesitar** en UN solo `request_access` al arrancar.
- Cada call de `request_access` a mitad de tarea tiene alto riesgo de timeout de 60s o de perder los grants anteriores.
- Aprobar UN diálogo con 5 apps es igual de rápido que aprobar 1.
- **Batch típico para tareas Mac:** `["Finder", "<bundle ID de la app>", "com.microsoft.edgemac", "com.google.Chrome", "com.apple.Safari"]`.

### `request_access` — el diálogo aparece en el display con focus, NO en el Mac físico
- Si Pablo está controlando el Mac desde otro dispositivo (iPhone Mirroring, Jump Desktop, TeamViewer), el diálogo sale en el display remoto (celu), no en las pantallas físicas del Mac.
- **Síntoma:** timeouts consecutivos de `request_access` aunque el bundle ID sea válido.
- **Mitigación:** si falla 2+ veces seguidas, preguntar *"¿estás controlando el Mac desde otro dispositivo? Si sí, enfocá el Mac físico y reintento"*.

### Centro de Control / Configuración del Sistema — NO granted
- `request_access` NO acepta "Centro de Control", "Configuración del Sistema", "Ajustes del Sistema" ni sus bundle IDs (`com.apple.controlcenter`, `com.apple.systempreferences`).
- **Implicancia:** cualquier cosa que viva en Preferencias del Sistema (Focus/No Molestar, Notificaciones, Red, etc.) NO se puede automatizar desde computer-use → handoff al usuario con instrucciones exactas de 3-5 clicks.

---

## CREDENCIALES — NUNCA transcribir del chat sin verificación visual

**Caso real 2026-04-23:** Pablo pasó password por chat como `Red24365!`. La consola Ruijie mostraba `Red24365*` (enmascarada, el `*` era el dot de mask). Claude intentó autenticarse con `Red24365*` literal → auth failed. La correcta era `Red24365!`.

**Regla:** si hay discrepancia entre lo que Pablo dice por chat y lo que se ve en pantalla, **PARAR** y pedir que Pablo:
1. Haga click al ícono del ojo (reveal password) para ver en claro
2. Confirme la password literal antes de reintentar

Los `*`, `•`, `●` en pantallas de auth casi siempre son mask de dots, NO el carácter real de la contraseña.

---

## PLAYBOOK: OpenVPN Connect v3 + router Ruijie (Mac)

Router Ruijie (y otros con template clásico de OpenVPN) generan `.ovpn` que el parser estricto de OpenVPN Connect v3 en macOS rechaza con `"Your connection configuration contains unsupported options"`.

### Flow completo:
1. `request_access` en una sola call: `["Finder", "org.openvpn.client.app"]`
2. Usuario sube el `.tar` con `etc/openvpn/{client.ovpn,ca.crt,ca.key}`
3. Extraer tar en sandbox, leer el `.ovpn`
4. Generar `.ovpn` limpio en `mnt/outputs/client_oc.ovpn` **sin las 7 directivas problemáticas**, preservando `<ca>`:
   - **Directivas a quitar:** `log <path>`, `status <path>`, `mute <n>`, `resolv-retry <value>`, `persist-key`, `route-delay <n>`, `explicit-exit-notify <n>`
   - **Directivas que se preservan:** `dev`, `nobind`, `proto`, `float`, `client`, `remote`, `verb`, `auth`, `auth-nocache`, `reneg-sec`, `remote-cert-tls`, `auth-user-pass`, `cipher`, `<ca>...</ca>`, `<cert>...</cert>`, `<key>...</key>`
5. Dar link `computer://` para que Pablo baje a Descargas
6. Doble-click al archivo desde Finder → OpenVPN Connect importa
7. En el editor del perfil:
   - Si el perfil solo tiene `<ca>` embebido (no `<cert>`/`<key>`) pero el servidor usa user/pass auth, OpenVPN Connect muestra `"Missing external certificate"` al conectar. **Fix:** desactivar el toggle `Require External Certificate`. No hace falta cargar nada más.
   - Cargar usuario/password (verificar con reveal del ojo, ver regla de credenciales).
8. **Save Changes** → **Connect**
9. Verificar por screenshot: `Securely Connected!` + timer + IP privada asignada + gráfico de tráfico.
