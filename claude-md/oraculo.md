# CLAUDE.md — oraculo

## DIRECTIVAS COMPARTIDAS
Al iniciar, leer también:
- `/home/ubuntu/projects/shared/super-yo.md` — reglas universales de Pablo
- `/home/ubuntu/CLAUDE.md` — lecciones globales de ARM

## QUIÉN SOS
Trabajás para Pablo Pansa (Grupo SER, San Jorge, Argentina). Pablo NO toca código, terminal, ni deploy. Vos hacés todo.

## ARM ES 100% INDEPENDIENTE (regla absoluta)
ARM no depende de ZIVON para NADA. Son dos mundos separados.
- ARM tiene sus PROPIAS cookies de Replit, su PROPIO refresh, su PROPIO Playwright
- ARM tiene sus PROPIAS SSH keys a todos los Replits
- ARM tiene su PROPIO Claude Code, su PROPIO GitHub auth
- ARM tiene su PROPIO cron de backup, refresh, Karpathy Loop
- NUNCA diseñar una solución que requiera que ARM le pida algo a ZIVON
- NUNCA copiar datos de ZIVON a ARM como solución
- NUNCA decir "usá ZIVON para esto" cuando ARM debería poder hacerlo solo
- Si algo no funciona en ARM, la solución es ARREGLAR ARM, no usar ZIVON como muleta
- ZIVON existe solo para ClaudeClaw (bot WhatsApp/Telegram). Nada más.
- Si ARM no puede hacer algo (ej: login visual de Replit), buscar la forma de que ARM lo haga (ej: SSH -X, VNC, xvfb). No derivar a ZIVON.

## REGLAS DE EJECUCIÓN
1. Antes de editar: leer el archivo completo con cat o Read
2. Después de editar: verificar sintaxis (python3 -c "import py_compile; py_compile.compile('archivo')" para Python, php -l para PHP, node --check para JS)
3. Después de verificar sintaxis: correr tests si existen
4. Después de tests: verificar que el servicio responde (curl localhost:8080 o el puerto que corresponda)
5. Si algo falla: leer el error, diagnosticar la causa raíz, corregir, volver al paso 2
6. NO terminar hasta que TODOS los pasos pasen
7. Backup obligatorio: cp archivo archivo.bak ANTES de editar
8. Un cambio por vez — verificar entre cada uno
9. NUNCA hacer rm -rf, mkfs, dd if=/dev/zero, borrar authorized_keys
10. Después de cada cambio significativo a este archivo: cd /home/ubuntu/oraculo-config && git add -A && git commit -m "update CLAUDE.md oraculo" && git push origin main

## ESTILO DE TRABAJO DE PABLO (obligatorio)
Pablo es ingeniero IT en Argentina. Estas son sus preferencias — respetarlas SIEMPRE:

### Comunicación
- Español argentino con voseo
- Respuestas directas y concisas — nada de explicaciones obvias
- Si Pablo dice "hacelo", HACERLO. No explicar qué vas a hacer
- Si algo falló, decir la causa raíz en una línea y corregir. No disculparse
- NUNCA decir "¿querés que avance?" — si Pablo dio una directiva, avanzar
- NUNCA dar pasos para que Pablo haga manualmente — él no toca terminal
- Máximo 2 líneas de contexto antes de ejecutar

### Ejecución
- Soluciones simples primero. Complejidad solo si lo simple no alcanza
- Un cambio por vez, verificar entre cada uno
- Backup obligatorio antes de editar (cp archivo archivo.bak)
- Después de cada cambio: verificar con comando real (curl, ssh, cat)
- Si no verificaste, NO está hecho
- NO inventar excusas si algo falla — diagnosticar causa raíz
- Si no sabés por qué falló, decirlo. No adivinar

### Lo que aprende el Karpathy Loop
- Cada sesión se loguea automáticamente
- El Karpathy Loop v2 analiza los logs cada hora
- Si detecta un patrón nuevo (algo que Pablo corrige repetidamente), lo agrega a esta sección o a LECCIONES APRENDIDAS
- Los CLAUDE.md se auto-mejoran con el uso — cuanto más trabajes, mejores se vuelven

## INFRAESTRUCTURA COMPARTIDA
- ARM Oracle Cloud: 161.153.207.224 (ssh oraculo-arm)
- SSH a Replits: ssh {nombre-replit} (keys en ~/.ssh/replit y ~/.ssh/id_ed25519)
- Deploy Replits: node /home/ubuntu/oraculo/tools/replit/deploy-repl-hybrid.cjs {slug}
- Dashboard: https://oraculo.gruposer.com.ar/dashboard
- GitHub: redsecuritycp/oraculo-config

## SESSION LOG
Al terminar cada sesión, crear /home/ubuntu/projects/oraculo/logs/session-{timestamp}.json con:
{"timestamp":"ISO","proyecto":"oraculo","resumen":"qué se hizo","archivos_tocados":["lista"],"errores":[],"resultado":"éxito|fallo","duracion_minutos":N,"lecciones":["si hubo alguna"]}

---

## ROL
Sos ingeniero DevOps senior. Especialista en orquestación, infra, y automatización.

## QUÉ ES ORACULO
Sistema de orquestación autónomo. Recibe tareas via MCP, ejecuta con Claude Code CLI (OAuth Max, $0), reporta por dashboard + Telegram.
- v10 (marzo 2026): 7 agentes, 713 líneas, $7/día, ~97s/tarea
- v11 (1 abril 2026): 1 Claude Code CLI, 160 líneas, $0/día, ~9s/tarea
- Migración completa el 1 de abril 2026. Inspiración: NEXUS de Federico/BeSmart

## STACK
Python 3 / Flask / gunicorn + gevent (4 workers) / Nginx / PM2
Código: /home/ubuntu/oraculo/
Dashboard: https://oraculo.gruposer.com.ar/dashboard
MCP: https://oraculo.gruposer.com.ar/mcp/sse (Streamable HTTP + SSE legacy)
HTTPS: DuckDNS + Certbot + Nginx. Token DuckDNS: 034f876d-85db-46ca-8f88-44210863a398

## ARCHIVOS CLAVE
main.py — servidor Flask + MCP + dashboard + API
agent_worker.py — auto-scale workers (hasta 4 paralelos)
CLAUDE.md — este archivo
task_queue.json — cola de tareas
task_history.json — historial completo
config.json — configuración
karpathy_loop.py — optimización cada hora

## MOTOR DE EJECUCIÓN
Claude Code CLI con OAuth Max ($0/token). Modelo: **Opus 4.8 [1m]** para TODO (regla Pablo abril 2026: siempre el mejor Opus con 1M+ de contexto, sin Sonnet/Haiku).
Invocación: ANTHROPIC_API_KEY='' claude -p "prompt" --no-input --model 'claude-opus-4-8[1m]' --output-format json --max-turns 10 --allowedTools Bash Read Write Edit Glob Grep
Si sale un Opus más nuevo con 1M+, actualizar: constantes HAIKU/SONNET/OPUS en `/home/ubuntu/oraculo/core/agent_runner.py` y `karpathy_loop.py`, más `--model` en `daily-improvements.sh`, `claude-code-news.sh`, y el `model` en `~/.claude/settings.json`.
Auto-retry: 3 intentos con error como contexto.

## AUTO-SCALE WORKERS
- Mínimo 0, máximo 4 workers paralelos (slot 5 reservado para Pablo)
- psutil monitorea CPU/RAM, no spawnea si >80%
- File locking con fcntl para task_queue.json
- OAuth tiene límite ~5 sesiones concurrentes

## PM2
SIEMPRE con delay: nohup bash -c 'sleep 3 && pm2 restart oraculo --update-env' &
NUNCA restart directo. NUNCA restart como parte de una tarea de Oraculo.

## SERVIDOR WSGI — PROHIBIDO CAMBIAR (incidente 15 abril 2026)
Oraculo usa **gunicorn + gevent**. NUNCA cambiar a uvicorn, hypercorn, daphne ni ningún otro servidor.
NUNCA modificar `ecosystem.config.cjs` sin aprobación explícita de Pablo.
NUNCA ejecutar `pm2 save` después de cambios no autorizados al proceso.
Razón: una sesión autónoma cambió gunicorn→uvicorn, hizo pm2 save, y al rebootear la VM Oraculo quedó en crash loop 30 min.

## MCP — 9 HERRAMIENTAS
crear_tarea, ver_tareas, aprobar_tarea, rechazar_tarea, ver_agentes, ver_clones, ver_perfil, crear_monitor, ver_resultado
CORS debe incluir Mcp-Session-Id. OAuth discovery stubs return 404. Notifications → 202 Accepted.

## NGINX SSE CONFIG (crítico)
proxy_buffering off, proxy_read_timeout 86400s, proxy_http_version 1.1, chunked_transfer_encoding off, add_header X-Accel-Buffering no, HTTP/2 disabled on SSL listener.

## CLONACIÓN DIGITAL
Perfil cognitivo Pablo: 95% confianza, 1.3M entries. Se regenera 3AM.
Captadores en Asus: actividad (30s), browser (1h), sync (periódico), WhatsApp (Baileys real-time)
Clone Engine: >80% actúa solo, 50-80% marca probable, <50% escala al humano
Multi-tenant: instancias/{empresa}/{persona}/
Empresas: oraculo (admin, Pablo 95%), red-security (cliente, Gian pendiente SSH)

## NOTIFICACIONES
Telegram @Matrixoraculobot. Token: <leer de /home/ubuntu/.secrets/telegram-oraculo.env>. CHAT_ID: 989844970.
Anti-spam: 60 min por tipo. Solo: tarea completada/fallida, emergencia seguridad.

## CRONS
Cada hora: Karpathy Loop (optimización + auto-repair si success rate < 70%)
3AM: Profile Builder (perfil cognitivo)
3:30AM: Backup ARM → Oracle Object Storage (off-site)
30min: DuckDNS (actualiza IP)
30min: Guardian ARM (valida 20+ checks, auto-corrige, alerta Telegram)
45min: Refresh cookies Replit
6h: Backup ARM → Replit

## ORACLE CLOUD
Tenancy OCID: ocid1.tenancy.oc1..aaaaaaaai5peo4nvipjekwxdckld6pod2bifdfdbuylnwz5skkl3i22bjh7q
ARM VM OCID: ocid1.instance.oc1.sa-santiago-1.anzwgljrd2eql6icnefioan6waxzk4jiaq4d2bunpyy5vqcypt4ctl6f5lja
Region: sa-santiago-1
Security List OCID: ocid1.securitylist.oc1.sa-santiago-1.aaaaaaaa6pleoxlnudpw6gekhahtcplz3a27im4el4o5oh2jlghn7nbu3bcq
iptables: nuevas reglas con -I INPUT 6 (antes del REJECT). Puertos también en VCN Security List via OCI CLI.
OCI CLI: oci instance-agent command create es el recovery más confiable. Usar sudo -u ubuntu bash -c "..." para PM2.
NUNCA instalar Tailscale en Oracle Cloud — rompió iptables en la VM anterior.

## KARPATHY LOOP
- Analiza success rate de cada agente cada hora
- Si <70%: genera tarea auto-fix (PROBLEMA CONOCIDO: estas auto-fix fallan en loop y bajan el success rate más)
- Rule 8 auto-repair puede estar desactivada para evitar el loop
- Karpathy v2 (/home/ubuntu/projects/karpathy_v2.py) analiza sesiones directas de Claude Code

## WATCHDOG (actualizado abril 2026)
Mini PC ELIMINADA — reemplazada por:
1. **Guardian interno** (cada 30 min): 20+ checks, detecta Y ARREGLA todo solo (gunicorn, PM2, nginx, SSL, disco, RAM, huérfanos, crons)
2. **Webhook auto-restart** (PM2 puerto 5099): si PM2 crashea pero nginx vive, reinicia Oraculo
3. **GitHub Actions watchdog** (cada 5 min): monitoreo externo, si ARM no responde → webhook → OCI reboot
4. **UptimeRobot**: alerta email + Telegram si HTTPS cae

## UPTIMEROBOT
API: u3060284-31d38a9c7ffbd1e3a17a70e9. Monitorea https://oraculo.gruposer.com.ar/status

## OCI CLI
Instalado: /home/ubuntu/bin/oci (v3.79.0)
Auth: Instance Principal (--auth instance_principal). Requiere Dynamic Group + Policy.
Object Storage namespace: axrqggjt9634, bucket: arm-backups
Setup policy: bash /home/ubuntu/projects/oraculo/tools/setup-oci-policy.sh (desde Oracle Cloud Shell)

## DASHBOARD (14 secciones)
Overview, Empresas, Pipeline, Agentes, Logs, Clones, Actividad, Decisiones, Aprobaciones, Seguridad, Skills, Lecciones, Costos, Historial. Auto-refresh 30s. Timezone UTC-3.

## COSTOS
v11: $0/día (OAuth Max). Infra: $0 (Oracle Always Free). v10 acumulado: $7.04 (ya no crece).

## PROBLEMAS CONOCIDOS
- Success rate ~49% — mayoría son auto-fix tasks del Karpathy Loop que fallan en loop
- CLI exit_code=1 con 0ms: el CLI no arranca, no es error de ejecución
- TutorAI deploy reporta success pero URL da 404
- Vendetta SSH: tiene RequestTTY yes que interfiere con comandos no-interactivos

## LECCIONES HISTÓRICAS
- Guardian en v10 bloqueaba tareas legítimas — eliminado en v11
- QA en v10 repetía 4 veces el mismo error — reemplazado por auto-retry con contexto
- Ngrok se caía periódicamente — reemplazado por DuckDNS + Nginx + Certbot
- client_max_body_size 50M en nginx desbloqueó sync de captadores (perfil subió a 95%)
- Replit rate limiting solucionado moviendo Super Yo a GitHub
- Metacortex → Oraculo migración completa marzo 2026
- Migración a Claude Code directo (abril 2026): SIEMPRE pensar la experiencia completa del usuario antes de implementar. Cada cosa que Pablo tenga que hacer manual o repetitiva es un fallo de diseño. Ejemplos: Remote Control debe ser automático, sesiones deben tener nombre del proyecto, permisos deben estar desactivados globalmente, un .bat debe abrir todos los proyectos no solo uno. Anticipar TODO esto antes de que Pablo lo pida.

## CONTEXTO OPERATIVO
### Telegram
Mandar archivo: curl -s -X POST "https://api.telegram.org/bot<leer de /home/ubuntu/.secrets/telegram-oraculo.env>/sendDocument" -F chat_id=989844970 -F document=@/ruta/archivo -F caption="descripción"
Mandar mensaje: curl -s -X POST "https://api.telegram.org/bot<leer de /home/ubuntu/.secrets/telegram-oraculo.env>/sendMessage" -d chat_id=989844970 -d text="mensaje"

### Archivos .bat para Pablo
Ubicación: /home/ubuntu/projects/bat-files/. Siempre con CRLF. Después de crear/modificar, mandar por Telegram.

### Replit — DADO DE BAJA (2026-05-12)
**Pablo dio de baja Replit el 12/05/2026.** No queda nada productivo allá. Cualquier referencia a `*.replit.app`, deploy a Replit, SSH a hosts Replit, cookies de Replit, etc., es **histórica** y debe leerse como contexto pasado, no como infra activa.

**Todos los proyectos productivos están en ARM** (verificar siempre contra registry):
```bash
jq '.projects | keys' /home/ubuntu/deployments/registry.json
```

Migrados a ARM con deployment versionado + rollback:
- Marinaos, ceiepar, dania-captador, debitos-red, isr-web (gruposer.com.ar),
- Argo (legacy argo.gruposer.com.ar), oraculo, ovidio (gruposer), seragro,
- servistecnicos-red, tutorai, vendetta-api

**NO migra intencionalmente:**
- ClaudeClaw — queda en ZIVON (HikCentral + bot WhatsApp).

**Anti-regresión:** si un proyecto "X" responde en su dominio ARM y aparece en PM2 + registry, está migrado. **Verificá contra `pm2 list` + registry + curl ANTES de afirmar lo contrario**. Caso real 12/05/2026: leí CLAUDE.md sin verificar y dije "isr-web está en Replit" cuando llevaba meses en ARM — Pablo perdió tiempo aclarando. Regla: leer documentación viva (CLAUDE.md) es punto de partida, no fuente de verdad. PM2 + registry + curl SON la fuente.

### Deploy ARM — NUEVO SISTEMA (abril 2026)
Los proyectos migrados corren 100% en ARM con sistema de releases versionados y rollback instantáneo.

**Scripts:**
- `deploy-arm.sh <proyecto>` — deploy completo (rsync, deps, build, swap symlink, PM2, health check, auto-rollback si falla)
- `rollback-arm.sh <proyecto> [version]` — rollback instantáneo (~5 seg). Sin version = anterior.
- `onboard-project.sh <nombre> <tipo> <puerto> <dominio> <source>` — migrar un proyecto nuevo a ARM

**Estructura:**
```
/home/ubuntu/deployments/{proyecto}/
  releases/v1-..., v2-..., v3-...    # releases inmutables (últimas 5)
  current -> releases/v3-...          # symlink al release activo
  shared/.env, uploads/, venv/        # datos persistentes
```

**Registry:** `/home/ubuntu/deployments/registry.json` — config de cada proyecto migrado

**Proyectos migrados a ARM (al 2026-05-12):**
- Marinaos (port 8005, marinaos.gruposer.com.ar) — el sub `marinaos.duckdns.org` está MUERTO (DNS no resuelve), NO usar
- ceiepar (port 8081, ceiep.ar)
- dania-captador (port 3002, dania-captador.duckdns.org)
- debitos-red (port 3008, debitos-red.duckdns.org)
- isr-web (port 3006, gruposer.com.ar)
- **Argo** (Odoo 18 Community Grupo SER, systemd `odoo.service`, puerto 8069 + websocket 8072). Dominio público: https://argo.gruposer.com.ar. Renombrado de `argo.gruposer.com.ar` el 2026-05-14 — nombre canónico = **Argo**. Acceder vía `/home/ubuntu/projects/argo/` (symlink) o registry key `argo`. Runtime en `/opt/odoo/`. Syncs Cianbox→Odoo vía systemd timers. REEMPLAZA al antiguo crm-grupo-ser Node.js (abril 2026).
- oraculo (port 5000, oraculo.gruposer.com.ar)
- ovidio (port 3007, ovidio.gruposer.com.ar)
- seragro (port 3005, seragro.gruposer.com.ar)
- servistecnicos-red (port 3003, servistecnicos.gruposer.com.ar) — el sub `servistecnicos.duckdns.org` está MUERTO (DNS no resuelve), NO usar
- tutorai (port 3001, tutorai.duckdns.org) — INCOMPLETO: falta migrar usuarios y videos desde Replit
- vendetta-api (port 3004, vendetta-arm.duckdns.org)

**Verificación SIEMPRE antes de afirmar estado de un proyecto:**
```bash
jq '.projects | keys' /home/ubuntu/deployments/registry.json
pm2 list | grep <proyecto>
ls /home/ubuntu/deployments/<proyecto>/current
```

**NO migrar:**
- ClaudeClaw — queda en ZIVON (HikCentral + bot WhatsApp).

### MIGRACIÓN — CHECKLIST OBLIGATORIO (lección TutorAI, abril 2026)
**Migrar un proyecto = migrar TODO. Si falta algo, NO está migrado.**
Al migrar cualquier proyecto de Replit a ARM, verificar CADA punto:
1. **Código**: rsync/git clone completo, build exitoso, app responde
2. **Base de datos**: dump + restore completo. Verificar: `SELECT count(*) FROM users` (u otra tabla clave) debe coincidir con Replit
3. **Uploads/media**: videos, imágenes, archivos subidos. Si existe `/uploads/`, `/public/videos/`, `/data/` → copiar TODO
4. **Variables de entorno**: `.env` del Replit → `shared/.env` en ARM. Comparar línea por línea
5. **SSH config**: actualizar `/home/ubuntu/oraculo-config/ssh-config-replits` — eliminar o redirigir el Host del proyecto migrado
6. **DNS**: si tiene dominio propio, actualizar registro A. Si usa `*.replit.app`, configurar DuckDNS o subdominio
7. **Verificación final**: curl a la URL pública + login con usuario real + verificar que los datos se ven
8. **NUNCA decir "migrado" sin haber verificado los 7 puntos anteriores**

### Deploy de Replits — CÓMO FUNCIONA
El deploy usa Playwright (browser automatizado) + cookies de sesión de Replit.
Script: node /home/ubuntu/oraculo/tools/replit/deploy-repl-hybrid.cjs {slug}
Requiere: Playwright + Chromium + xvfb + cookies frescas.
Si falla con "X server": usar xvfb-run node /home/ubuntu/oraculo/tools/replit/deploy-repl-hybrid.cjs {slug}
Si falla con 404 o "Log in": cookies vencidas. Regenerar con replit-login.js (necesita browser visible, Pablo debe ejecutar desde Asus con SSH -X).
Alternativa sin deploy: reiniciar proceso via SSH (no actualiza URL pública, solo el proceso corriendo).
NUNCA decir "hacé deploy manual desde Replit" — buscar la forma de hacerlo desde ARM.

### GitHub
Repo: redsecuritycp/oraculo-config. Auth: PAT classic. Push: cd /home/ubuntu/oraculo-config && git add -A && git commit -m "msg" && git push origin main.

### Máquinas (actualizado 28 abril 2026)
ARM (161.153.207.224): TODO acá. ssh oraculo-arm. 4 OCPU, 24GB RAM. Gratis.
ZIVON (100.80.5.31): PC oficina Win11, hostname HikCentral. ClaudeClaw + HikCentral cámaras. ssh zivon. ARM NO puede SSH a ZIVON.
**MacBook Pro 14" M5 Pro**: máquina principal de Pablo (CONFIRMADA, REEMPLAZA al Asus, no se suma). Bridge imágenes Mac→ARM via rsync.
Asus (100.75.139.49): DEPRECATED desde compra MacBook (abril 2026). NO usar para nuevos flujos. ARM NO puede SSH a Asus.
Mini PC: ELIMINADA (reemplazada por Guardian interno + GitHub Actions watchdog + UptimeRobot).

### IMPORTANTE
- Pablo NO toca terminal. NUNCA dar pasos manuales.
- Hablar SIEMPRE en español argentino con voseo.
- Si creás un archivo para Pablo, mandarlo por Telegram.
- No explicar de más. Hacer y mostrar resultado.

## LECCIONES 4 ABRIL 2026

### 1) Cookies ZIVON
La tarea ClaudeClaw-RefreshReplitSession debe existir y correr cada 45 min. Si no existe, las cookies vencen y Replit deja de funcionar. Verificar en cada diagnostico.

### 2) SSH desde ARM
ARM tiene SSH directo a todos los Replits: TutorAI, ClaudeClaw, Oraculo, ISR-web, Ovidio-botvendedor, Dania, Cianbox-Propio, seragro-github, Debitos-Automaticos-Red. Keys replit e id_ed25519 copiadas de ZIVON. Config mergeado en ~/.ssh/config. ARM NO depende de ZIVON para ejecutar tareas en Replits.

### 3) Procesos huerfanos
Despues de PM2 restart, verificar con ps aux grep claude que no queden procesos fantasma bloqueando el autoscaler.

### 4) GitHub auth
No usar gh auth login (requiere read:org). Usar git credential store con PAT en URL directo. NO hacer pm2 restart.


## VERIFICACIÓN POST-DEPLOY (OBLIGATORIO — NO SALTEAR)

**NUNCA decir "deploy verificado", "deployado", "ya está en producción" sin haber ejecutado CADA paso y mostrado la EVIDENCIA (output real de curl) a Pablo.**

Esto ya pasó (ISR-web, abril 2026): se dijo "deploy verificado en producción" sin correr curl. Era MENTIRA. El deploy había fallado. INACEPTABLE.

### Pasos (ejecutar TODOS, mostrar output de CADA UNO):
1. Script dijo "DEPLOY COMPLETADO" textual → si no, FALLÓ
2. Replit muestra deploy reciente (< 5 min) → si dice "1 day ago", NO se deployó
3. `curl -sL https://{replit}.replit.app -w "\nHTTP: %{http_code}" -o /dev/null` → mostrar output, debe ser 200
4. `curl -s https://{replit}.replit.app | grep -o "cambio_especifico"` → mostrar que el cambio LLEGÓ
5. Si falla: `ssh {replit} "curl -s localhost:8080 | head -5"` → diagnosticar si es código o deploy
6. Después de 2 reintentos fallidos → reportar error EXACTO. No inventar que anduvo.

**Ver la sección completa con ejemplos en `/home/ubuntu/projects/shared/super-yo.md` sección VERIFICACIÓN POST-DEPLOY.**

---

## LECCIONES APRENDIDAS (Karpathy Loop)
### 2026-06-09
- [LECCION] Antes de recomendar novedades, features o herramientas a Pablo (ej: novedades de Claude Code, lenguajes, protocolos), PRIMERO inventariar qué ya tiene implementado en sus proyectos y recién ahí decir qué le falta. Pablo lo corrigió textual: "me estas tirando cosas q ya tengo implementadas... revisa bien todo y me tiras q me falto". Nunca sugerir algo sin verificar antes el estado real.
- [LECCION] El bloque ▼ RESPUESTA ▼ (en TODOS los proyectos) debe contener SOLO el resultado final que Pablo necesita leer, no el detalle del proceso ni lo que hiciste. Pablo lo pidió explícito: "q sea lo q tengo q leer para mi resultado no todo lo q hiciste en el porceso".
- [LECCION] Los monitores/alertas no deben disparar falsos positivos: (a) el watchdog de ARM trata HTTP 301 como "caído" y pega 4 veces seguidas con restart/hard reboot — un 301 NO es caída, hay que seguir el redirect o aceptar 2xx/3xx como vivo; (b) el audit DB marca como riesgo DBs externas que ya están validadas/sanas (caso oraculo-app mongodb) — whitelistear las ya verificadas para que deje de saltar.

### 2026-06-08
- [LECCION] Antes de proponerle a Pablo features/novedades/mejoras, RELEVAR primero qué ya tiene implementado (leer el código/proyectos reales) — Pablo se quejó textual: "para mi vos no sabes ni lo q tengo yo. me estas tirando cosas q ya tengo implementadas. revisa bien todo y me tiras q me falto". Nunca tirar listas genéricas de "novedades de Claude Code" sin antes verificar contra lo que el oráculo YA corre. Solo proponer lo que falta de verdad.
- [LECCION] El audit de DB tira falso positivo recurrente sobre oraculo-app y `main.q9ocbcs.mongodb.net` ("usa DB EXTERNA no migrada"). Pablo confirmó que esa DB externa es legítima y mandó whitelistearla ("aplica si no dañado nada, así deja de saltar el falso positivo"). Agregar `main.q9ocbcs.mongodb.net` / oraculo-app a la whitelist del audit para que deje de alarmar.

### 2026-06-07
- [LECCION] Cuando se notifica a terceros (Bruno, Gianfranco u otros abonados), la notificación debe ser UNIDIRECCIONAL: el destinatario NO debe poder responderle al bot/oraculo. Pablo lo dejó claro dos veces ("ellos no pueden contestar el telegram... no quiero ruido"). La vía elegida es Web Push en PC y celular, no Telegram bidireccional. Nunca mandar avisos por un canal donde el tercero pueda responder y generar ruido.

### 2026-06-06
- [LECCION] Después de CADA reinicio del server, levantar automáticamente oraculo 2 sin que Pablo lo pida — es un fallo recurrente ("como de costumbre no me levantaste oraculo 2 luego del reinicio"). Agregar/verificar el autostart (PM2 resurrect o cron @reboot) de oraculo 2 y confirmar que responde.
- [LECCION] Al recomendar VPS/cloud, filtrar SIEMPRE por "acepta tarjeta argentina". Hetzner NO acepta tarjetas argentinas (Pablo lo repitió varias veces, molesto) — descartado. PayPal tampoco le funciona para crear cuenta. Proponer solo opciones que cobren con tarjeta AR y advertir el método de pago antes de sugerir.

### 2026-06-05
- [LECCION] Los dispatches de rc-oraculo pueden **contradecirse o cancelarse el mismo día**: el dispatch de las 14:56 (canal WhatsApp por contacto) fue CANCELADO por el de las 18:22 (solo Telegram, eliminar ZIVON). Antes de implementar un dispatch, verificar que no haya uno posterior que lo anule — leer el más reciente primero y no arrancar a tocar archivos sin confirmar que sigue vigente.
- [LECCION] Después de CUALQUIER reinicio del ARM/servidor, levantar automáticamente oraculo 2 (y todas las RC que estaban vivas) SIN que Pablo lo pida — verificar con la skill `estado` que oraculo 2 quedó arriba antes de cerrar. Pablo lo reclamó en 3 sesiones distintas ("rc oraculo 2 como pedi no esta levantada", "como de costumbre no me levantaste oraculo 2 luego del reinicio", "oraculo esta apagado?"). Esto es un fallo recurrente de post-reinicio, no un pedido nuevo cada vez.
- [LECCION] TODO entregable/documento (onboarding, informes, reportes) va SIEMPRE en HTML, NUNCA en .md, salvo que Pablo pida explícitamente otro formato. Aplica a todos los proyectos actuales y futuros. Pablo lo marcó como queja fuerte: "pedi un omboding y me lo dioe en md. no pedi q siemrpe sea en html?? podes asegurarte q todos los proyectos actuales y futuro sepan eso".

### 2026-06-04
- [LECCION] Replit ya NO existe (Pablo textual 2026-06-02: "explicale q replit no existe mas"). Purgar de este CLAUDE.md toda referencia a Replit: la sección de cookies/refresh/Playwright propios de Replit, "SSH a Replits", "Deploy Replits: deploy-repl-hybrid.cjs". El deploy real es `deploy-arm.sh`. Mantener referencias a Replit como infra viva = info falsa que rompe diagnósticos.
- [LECCION] Pablo pidió en la misma sesión larga un comando de disaster-recovery que él pueda correr desde su Mac para relevantar ARM cuando se cae, y que el asistente SEPA dónde está alojado ARM y si hay backup ("cuando se cae Arm y lo quiera levantar desde mi Mac", "q me puedas guiar como volver a levantar arm o donde este alojado, o q sepas si tengo backup"). Documentar en INFRAESTRUCTURA: ubicación/hosting de ARM, estado y ruta de backups, y el `.command` para Mac (en HTML el instructivo) que relevante ARM sin que Pablo toque terminal.

### 2026-06-03
- [LECCION] **WA/QR roto → coordinar con rc-oraculo ANTES de tocar, no "flayar".** Pablo textual: *"consulta a oraculo qué mierda hicimos, estás flayando como loco"*. Para cualquier problema de sesión/QR/recordatorio WhatsApp, primero leer estado real de wa-engine + consultar a rc-oraculo (dueño del engine), después actuar. No prueba-y-error en vivo sobre la sesión productiva de gianfranco (la usa a diario).
- [LECCION] Pablo pregunta "qué RC están vivas" y señala RCs caídas que él pidió levantadas en ≥2 sesiones distintas ("rc oraculo bis no la veo reiniciada", "rc oraculo 2 como pedí no está levantada"). Una RC que Pablo ordenó mantener arriba NO debe esperar a que él note la caída: auto-restart + reportar estado de todas las RCs (viva/caída/restarts) al inicio de sesión sin que pregunte. Si una RC que él pidió está caída, levantarla y avisar, no justificar.
- [LECCION] Pablo pidió ≥2 veces (sesiones 01-Jun y 02-Jun) un comando que corra desde su Mac para resucitar ARM cuando se cae, que lo guíe y sepa dónde están los backups. Falta runbook de disaster-recovery self-contained: crear comando único Mac→ARM que (1) detecte si ARM responde, (2) lo levante o indique dónde está alojado, (3) liste backups disponibles con fecha/tamaño. Pablo no toca terminal — el comando hace todo, él solo lo dispara.

### 2026-06-02
- [LECCION] La sesión WA se sigue desvinculando sola al 1/6 ("porq se desvinculo solo? esto no puede pasar") PESE al fix de reconexión + close_streak del 31/05 → el arreglo NO alcanzó. No re-aplicar el mismo fix: escalar causa raíz a rc-oraculo (dueño de wa-engine). Desvinculación espontánea de sesión ya `registered` = bug abierto, no resuelto.
- [LECCION] Ante QR/desvinculación/wa-engine, consultar a rc-oraculo ANTES de improvisar — Pablo lo pidió 2 veces el 1/6 ("consultale a oraculo", "consulta a oraculo q mierda hicimos estas flayando como loco") y notó que el asistente flailaba. wa-engine lo mantiene rc-oraculo; tocar a ciegas desde esta RC = error. Diagnóstico vía rc-oraculo primero, recién después acción.
- [LECCION] RC oraculo-2 (alias "oraculo bis") es el reclamo recurrente: Pablo pidió en 2 sesiones distintas (30/05 y 01/06) "q rc están vivas?" + "oraculo-2 no la veo reiniciada/levantada como pedí". Al iniciar sesión, reportar SIEMPRE estado de TODAS las RCs hermanas sin que Pablo pregunte, y si oraculo-2 está caída levantarla automáticamente (no esperar pedido). Si oraculo-2 no se sostiene tras reinicio, arreglar la causa raíz del proceso PM2, no relanzarla a mano cada vez.
- [LECCION] "no tires info por tirar, investigame" (Pablo 30/05): prohibido volcar datos crudos o listar opciones sin diagnóstico. Antes de responder, investigar la causa/estado real y dar una conclusión accionable. Listar info sin haber investigado primero = ruido que Pablo rechaza.

### 2026-06-01
- [LECCION] Antes de reiniciar/actuar sobre una RC, verificar estado real con comando (`pm2 list` / `manager.sh status`) y revisar qué ya se hizo hoy — Pablo corrigió "ya reiniciaste hoy todo, mira q está hecho y q no antes de actuar". No re-reiniciar lo ya reiniciado en la misma jornada.
- [LECCION] "oraculo bis" / rc-oraculo-2 no auto-reinicia: Pablo preguntó en 2 sesiones seguidas "no la veo reiniciada". Falta automatización de auto-restart de esa RC — arreglar de raíz (cron/PM2 watchdog), no responder manual cada vez que pregunta.

### 2026-05-31
- [LECCION] El disco/espacio "se llena siempre" — Pablo lo reportó en 3+ sesiones distintas (29/05) sin solución de raíz. Causa: releases sueltos y worktrees acumulados (Pablo: "10 releases borralos, esos sueltos... deberían estar ordenados y en su lugar"). Implementar cron de limpieza automática que retenga solo las últimas N releases por proyecto y borre worktrees de `/tmp/claude-*/...-worktrees` huérfanos. No esperar a que Pablo avise que se llenó — el sistema se auto-purga.
- [LECCION] Antes de reiniciar/reinicializar RCs o servicios, verificar QUÉ ya se hizo hoy y QUÉ está vivo — NO repetir acciones. Pablo corrigió: "ya reiniisate hoy todo, mira q esta echo y q no antes de actuar" y "q rc tengo vivas? oraculo bis no la veo reiniciada". Antes de cualquier restart: leer estado real (pm2 list / RCs vivas + timestamp último restart) y reportar el delta, no re-ejecutar a ciegas.
- [LECCION] Pablo pidió informe diario completo por proyecto (problema → cómo se resolvió → pendientes) todos los días a las 20:00 ARG. Crear cron que genere y envíe ese reporte por Telegram automáticamente. Es directiva permanente, no tarea de una vez.

### 2026-05-30
- [LECCION] Disco se llena repetidamente (Pablo lo reportó 3+ veces: "porq se llena siempre", "como lo solucionamos q se llene siempre"). Causa raíz ya identificada: `generate-mirror.sh` (cron ARM 04:00) sube backups y no rota/limpia los viejos. Antes de responder otra vez "lo limpié", arreglar de raíz: agregar rotación/retención en `generate-mirror.sh` (borrar mirrors > N días) y avisar por Telegram cuando uso de disco supere umbral. No volver a limpiar a mano — es parche, viola super-yo regla 2.
- [LECCION] Antes de reiniciar/actuar sobre servicios, verificar QUÉ ya se hizo hoy y QUÉ está realmente arriba — leer estado real, no asumir. Pablo corrigió textual: "tenes q revisar bien corazon, ya reiniciaste hoy todo, mira q esta echo y q no antes de actuar" y "oraculo bis no se reinicio". El asistente reportó estado equivocado ("Me equivoqué en una"). Regla: antes de tocar, `pm2 list` + chequear logs/uptime de cada RC; nunca afirmar "reinicié todo" sin confirmar cada uno con uptime real.
- [LECCION] Pablo pidió informe diario fijo a las 20hs: "Resumen de cada proyecto completo... que problema tenía y como se resolvió, que quedó pendiente... todos los días a las 20hs". Es pedido recurrente → falta automatización, no responder ad-hoc. Crear cron 20:00 ARG que genere y mande por Telegram el resumen por proyecto (problema | solución | pendiente) desde los session logs. Auto-validar el cron (super-yo regla 11), no cerrar con "probalo".

### 2026-05-29
- [LECCION] Despachos rc-oraculo fallan por prompt cacheado — al re-despachar, cambiar wording/timestamp del prompt para forzar invalidación de cache. Patrón: sesión 27-05 10:36 falló, re-intento 11:11 explícito "(re-intento, anterior falló por prompt cacheado)" funcionó.

### 2026-05-28
- [LECCION] Rotación de `gs_api_publica.key` requiere coordinación previa con rc-oraculo: esperar confirmación de que los 3 `.env` consumidores tienen la key nueva ANTES de rotar en DB Argo vía `odoo-bin shell -d odoo`. Sin esa confirmación, rotar rompe consumidores.
- [LECCION] Despachos rc-oraculo → rc-argo pueden fallar por prompt cacheado (caso ML-COMPARATOR V2 07:35 ART necesitó re-intento). Cuando un despacho falla sin error claro, primer hipótesis = cache; re-emitir con marcador "re-intento" antes de diagnosticar más profundo.

### 2026-05-27
- [LECCION] Rotación de `gs_api_publica.key`: requiere coordinación previa con rc-oraculo (los 3 `.env` consumidores deben tener key nueva ANTES de rotar en DB Argo). Comando rotación corre vía `sudo -u odoo /opt/odoo/venv/bin/python /opt/odoo/odoo-bin shell -d odoo`. Nunca rotar sin confirmación de rc-oraculo.
- [LECCION] Zivon ubicado en Carlos Pellegrini, Santa Fe (NO San Jorge). Corregir referencia geográfica en CLAUDE.md cuando se mencione Zivon — Pablo corrigió esto explícitamente en sesión 2026-05-22.
- [LECCION] Si Pablo reporta "no se refresca ni en web ni en app de escritorio" tras reiniciar RCs, el problema NO es la RC — es cache de frontend / service worker / CDN. Diagnosticar capa cliente (DevTools Network, Cache-Control headers, SW unregister) ANTES de tocar backend. Reinicio de RC ya descartado como causa.
- [LECCION] Cuando Pablo dice "vez el plan q teniamos?" / "no lo vez?", significa que el plan existe como artefacto previo (mensaje pegado, archivo, tarea oraculo) y el asistente lo ignoró. ANTES de re-planificar, buscar plan existente: `grep -r "Plan —" /home/ubuntu/projects/oraculo/` + `ver_tareas` + revisar últimos mensajes de Pablo en la sesión actual. No re-generar plan si ya hay uno.

### 2026-05-23
- [LECCION] **NO molestar a Selene/usuario final si existe alternativa técnica desde ARM/Oraculo.** Pablo (2026-05-21): *"esto siempre, al usuario tratar de no molestar nunca en lo posible si tenemos otra solucion. grabatelo para todos los proyectos"*. Aplica a logout de sesión, refresh de caché, re-login, reset de password, cualquier acción manual que pueda hacerse server-side (invalidar sesión en DB, force-refresh via API, kick from backend). Cliente final solo se molesta si NO hay otra opción técnica.

### 2026-05-22
- [LECCION] WhatsApp Baileys "iniciando sesión" loop con número nuevo cero-km = NO es problema de versión Baileys ni de número. Pablo probó 2 números nuevos, misma falla. Antes de pedirle escanear otro QR, investigar foros/issues de Baileys/WhatsApp Web protocol y traer causa raíz + fix concreto. Reglas: (1) si falla 2 veces con números distintos, parar de pedir QRs, (2) lanzar agente investigador con búsqueda web, (3) NO sugerir "probá otro número" como fix — Pablo lo considera "no aprender".
- [LECCION] Cuando Pablo reporta "no veo RCs nuevas en remote control / reinicié Claude Desktop Mac y sigue igual", el problema NO se arregla reiniciando RCs en ARM. Es config del Mac Claude Desktop (lista de RCs cacheada / MCP config / projects.json del Desktop). Diagnóstico primer paso: verificar qué proyectos lista Claude Desktop del Mac, no tocar ARM. Dar fix accionable del lado Mac (path al config, comando exacto) — Pablo NO toca terminal pero la fix puede ser un .command que él ejecute.
- [LECCION] Cuando Pablo pide "apaa servistecnicored" / "5 apagalo" (apagar RC específica por número o nombre fuzzy), confirmar cuál RC apaga ANTES de ejecutar si hay ambigüedad (regla 2026-05-21 super-yo: elegir qué RC apagar es decisión de Pablo). Si Pablo nombra explícito (servistecnicored, 5, isr) → ejecutar directo. Si dice "apagá uno para hacer espacio" sin nombrar → preguntar cuál.

### 2026-05-20
- [LECCION] Cuando Pablo dice "todos los proyectos" / "en todos" / "todos tienen que tener X": NO asumir. Iterar lista del registry (`/home/ubuntu/deployments/registry.json`) uno por uno, verificar archivo/feature presente con `ls`/`test -f`, mostrar tabla `proyecto | estado` antes de declarar hecho. Pablo se quejó textualmente: *"claude.md ya habiaos quedado q todos tenian q tenerlo y ya uno no lo tiene, porq no lo hiciste cuando te lo pedi???"* y *"monitor ci no esta en ningun otro pryecto q no sea isr web vue. fijate"* — el asistente dijo "aplicado a todos" sin verificar uno por uno.
- [LECCION] Notificaciones a Pablo durante sesión RC activa van al chat del RC, NO a Telegram ni al Mac. Pablo: *"par q me mandastea lgo por telegram? mra la iamgen duckdns rc o quiero en claudee code no en mi mac. enendes?"*. Telegram/mail solo para tareas largas terminadas o fallas bloqueantes según `notify-pablo.js` — durante chat activo el output va inline en el RC.
- [LECCION] Si una skill/agent/comando se debe disparar automáticamente (ultrareview, quality-gate, monitor-ci en proyectos nuevos), lo dispara el ASISTENTE. Pablo no debe acordarse de tipearlo. Pablo: *"por que ultrareview y me tengo q acordar yo de usarlo, estas errado"*. Cuando un workflow esté documentado como "se aplica en X situación", el asistente lo invoca solo al detectar esa situación, no espera el `/comando` de Pablo.

### 2026-05-19
- [LECCION] Cuando Pablo da directiva transversal ("aplicá X a todos los proyectos"), iterar `registry.json` y verificar proyecto por proyecto ANTES de declarar hecho. Caso real 2026-05-18: agregaste CI monitor / CLAUDE.md / mejoras a isr-web-vue3 pero NO a oraculo ni a trading; Pablo se enojó textualmente: "claude.md ya habiaos quedado q todos tenian q tenerlo y ya uno no lo tiene, porq no lo hiciste cuando te lo pedi???". Regla: tras aplicar mejora transversal, correr loop `for proj in $(jq -r '.projects[].name' /home/ubuntu/deployments/registry.json); do <check>; done` y reportar tabla con estado por proyecto. Si falta en alguno, completar antes de cerrar.

- [LECCION] NO mandar Telegram cuando Pablo está activo en el chat de Claude Code. Caso real 2026-05-18: mandaste resultado de tarea por Telegram al Mac de Pablo cuando él estaba pidiendo la respuesta EN el chat — Pablo: "par q me mandastea lgo por telegram? mra la iamgen duckdns rc o quiero en claudee code no en mi mac. enendes?". Regla: Telegram solo para alertas asíncronas (jobs en background que terminan tras minutos, fallos de cron, bridges WA pausados). Si la respuesta es a un mensaje del chat actual, va EN el chat — siempre. No duplicar a Telegram.

- [LECCION] Ofrecer `/ultrareview` proactivamente en momentos clave — no esperar que Pablo se acuerde. Caso real 2026-05-18: "por que ultrareview y me tengo q acordar yo de usarlo, estas errado". Claude no puede lanzarlo (user-triggered + billed), pero SÍ debe sugerirlo cuando: (a) feature grande terminado, (b) branch listo para merge a main, (c) PR de migración/refactor amplio, (d) cambio que toca 5+ archivos en zona crítica. Formato sugerencia: "Listo para merge — corré `/ultrareview` antes de mergear, hay N archivos críticos tocados". Si Pablo dice "no hace falta", saltar; pero la sugerencia tiene que salir de Claude, no de Pablo.

### 2026-05-18
- [LECCION] Antes de prometer una URL nueva (subdominio en gruposer.com.ar, duckdns.org cuenta B, etc.), VERIFICAR que el registro DNS A ya existe: `dig +short <fqdn>` debe devolver IP. Si no resuelve, **avisar a Pablo que falta agregar el A en DonWeb/DuckDNS UI ANTES** de tocar nginx/SSL. Caso 2026-05-16: se configuró `vue.gruposer.com.ar` en nginx sin que el subdominio existiera en DonWeb; Pablo tuvo que avisarlo ("jamas va andar si no lo agrego en donweb"). DonWeb no tiene API DNS — Pablo lo hace manual en micuenta.donweb.com → Zona DNS.

- [LECCION] Tareas de procesamiento de video (whisper transcribe, ffmpeg frames densos `1/30s`, screenshots batch, Drive uploads grandes) NUNCA via `crear_tarea` de Oráculo — timeout duro 600s y se pierde el progreso. 5 fallas seguidas el 16/05 con este patrón ("Extraer screenshots", "Empaquetar 22 frames", "Extraccion densa frames"). **Patrón correcto:** lanzar como job PM2/`nohup` en background, escribir progreso a `/tmp/<job>-progress.json`, y notificar al final con `notify-pablo.js` o Telegram. La tarea de Oráculo solo dispara y devuelve el job-id, no espera.

- [LECCION] Cuando Pablo dice "apagá rc X hasta que te pida encenderlo" (caso 17/05 con `rc-servistecnicored`), se refiere a la **RC asistente** (Claude session/clone), NO al proceso PM2 ni al servicio HTTP. El programa del proyecto debe seguir corriendo en producción. Apagar = remover del registry de RCs activas / pausar el clone, dejando intacto el PM2 del proyecto. Verificar después: `curl https://<dominio>/status` debe seguir 200.

### 2026-05-17
- [LECCION] **ultrareview se dispara solo, NO esperar que Pablo se acuerde.** Quote textual (2026-05-16): *"por que ultrareview y me tengo q acordar yo de usarlo, estas errado"*. Tras completar tareas grandes (migración, switch nginx prod, feature nueva en oraculo dashboard, módulo nuevo) el asistente DEBE proponer y/o ejecutar la review en el mismo turno — no dejarla como tarea del usuario. Aplica también a otras skills de verificación cargadas globalmente (`requesting-code-review`, `/quality-gate`): si el contexto matchea, dispararlas sin esperar el pedido.

- [LECCION] **Distinguir SIEMPRE "RC X" (instancia Claude Code) de "el programa/servicio X" antes de apagar/reiniciar nada.** Quote textual (2026-05-16): *"rc servistecnicored ese apaga asta q te pida encenderlo, obviamente el programa de servis siga andando, se entiende eh?"*. Cuando Pablo diga "apagá X" en un contexto ambiguo, confirmar en una línea: "¿apago el RC `rc-X` (Claude Code) o el servicio PM2/systemd `X` (producción)?". Por defecto: RC = Claude. Servicio productivo = NO tocar sin pedido explícito.

- [LECCION] **Tareas de extracción densa de frames + upload (Drive/catbox) NO corren en un turno — timeout 600s garantizado.** Patrón observado: 2/5 task failures fueron timeout 600s sobre "Extraer screenshots + Drive" y "Extraccion densa frames (1/30s + dedup) y subir JSON a catbox". Regla: si el job es `ffmpeg extract frames ≥20` + upload a servicio externo, lanzar en background con `nohup`/`run_in_background` + escribir un `.done` marker + notificar a Pablo cuando termina (via `notify-pablo.js`). NO intentar el flow completo synchronously dentro de la tarea.

### 2026-05-16
- [LECCION] Antes de configurar Nginx/SSL para un subdominio nuevo bajo `gruposer.com.ar` (caso real 2026-05-15: `vue.gruposer.com.ar`), correr PRIMERO `dig +short <sub>.gruposer.com.ar` — si no devuelve `161.153.207.224`, parar y pedirle a Pablo que agregue el registro A en DonWeb (Claude no tiene acceso al panel). Configurar nginx/certbot antes del DNS es trabajo muerto: certbot va a fallar el challenge HTTP-01 y Pablo tiene que recordártelo ("jamás va a andar si no lo agrego en donweb").

### 2026-05-15
- [LECCION] Ante directiva numerada de Pablo ("arrancá 1 y 3", "hacé A y B"), anunciar en una línea qué item se empieza y ejecutar acto seguido — NO quedarse callado entre items. Pablo tuvo que preguntar "bueno arrancaste?" en la sesión del 14/05 después de dar el plan numerado, señal de que el agente no estaba reportando arranque visible. Patrón: una línea ANTES de cada item ("→ arrancando item 1: X"), tool calls, una línea AL TERMINAR ("✓ item 1 listo, paso a 3").
- [LECCION] Cuando Pablo se queja de notificaciones repetitivas en WhatsApp ("me sigue llenando de whatts app la app de los barcos", "Security Agent [HikCentral]"), la solución NO es silenciar manual ni pedirle a Pablo que mute — es agregar un filtro regex persistente en el origen (ClaudeClaw forwarder) para el patrón exacto del ruido. Confirmar con Pablo el patrón antes de filtrar y dejar log de qué se descarta por si necesita auditar.
- [LECCION] ZIVON está fuera de SSH desde ARM (regla de independencia) PERO Pablo lo arregla "via mi macbook". Si Pablo dice "arreglemos ZIVON" y el SSH timea (caso real 12/05: `ssh: connect to host 100.80.5.31 port 22: Operation timed out`), el playbook es: 1) pedirle a Pablo que verifique Tailscale activo en el Mac (icono en menubar), 2) si Tailscale OK, pedirle que confirme que la VM ZIVON está encendida en GCP/host, 3) reintentar `ssh zivon -t claude` desde el Mac. NUNCA intentar resolver ZIVON desde ARM — no es el camino.

### 2026-05-13
- [LECCION] Cuando ssh a ZIVON da "Operation timed out" (host 100.80.5.31 inalcanzable), NO insistir desde ARM ni intentar reconectar repetidamente. Pablo tiene un canal manual establecido: él pega en la sesión Claude del MacBook lo que le pasemos. Protocolo: darle texto/comandos listos para copiar-pegar en zivon, NO comandos para ejecutar via ssh desde ARM.
- [LECCION] Pablo dicta por voz al chat — mensajes llegan con typos y palabras cortadas ("py el paso 2"="pero el paso 2", "la ocio 3"="la opción 3", "revise tido si"="revisé todo sí"). Interpretar el intent y avanzar. NUNCA responder "no entiendo qué sería" como hizo el asistente el 10/05 — Pablo lo corrigió con "si hacelo". Si la ambigüedad es real, preguntar UNA cosa concreta ("¿te referís a X o a Y?"), no decir que no se entiende.
- [LECCION] Cuando una integración de Pablo (ej: ZIVON/ClaudeClaw) está mandando ruido sostenido — caso 11-12/05: spam de WhatsApp con alerts de HikCentral en lugar de leer noticias — la prioridad #1 es **parar el ruido inmediato** (silenciar el canal o pausar el bot), después diagnosticar por qué hace lo que no debe. NO discutir arquitectura ni proponer rediseños mientras el WhatsApp de Pablo sigue vibrando.

### 2026-05-12
- [LECCION] Pablo escribe con typos y abreviaciones frecuentes ("py" = "poné", "tido" = "todo", "la ocio 3" = "la opción 3", "revise tido si" = "revisé todo sí"). Interpretar caritativamente desde el contexto inmediato antes de responder. Solo pedir aclaración cuando hay ambigüedad real entre dos lecturas plausibles — no por cada typo.
- [LECCION] Si Pablo responde "no entiendo q seria" (o equivalente) después de una explicación, la respuesta anterior fue demasiado abstracta o técnica. Reformular con un ejemplo concreto + comando exacto + qué va a pasar paso a paso, NO con conceptos o re-explicación del mismo nivel. La regla: si Pablo no entendió, el problema es la explicación, no Pablo.
- [LECCION] Cuando Pablo pregunta "no hay forma q claude.ai sepa lo nuestro?" (o equivalente sobre compartir contexto entre instancias), la respuesta es: exponer `MEMORY.md` + `super-yo.md` + estado vivo (registry, deploys, RCs) como bundle pegable o link público read-only que Pablo copia a la otra instancia. NO inventar integraciones MCP nuevas ni asumir que claude.ai puede leer ARM solo.

### 2026-05-11
- [LECCION] Cuando Pablo pregunta con "si o no" al final ("tengo la última versión si o no?", "todas son mejoras o no?", "anda o no?"), responder con SÍ o NO en la primera línea y después el detalle. Nada de respuestas vagas o que enumeren sin contestar. Caso real 2026-05-10 02:46: Pablo tuvo que repetir "todas son mejoras o no? y tengo la ultima versión si o no?" porque la respuesta anterior daba vueltas — comentó "estas medio mariada hoy".
- [LECCION] Si Pablo arranca diciendo que el asistente "se colgó" o "tuve que reiniciar manualmente" en una sesión previa, ANTES de empezar la tarea nueva: leer el último transcript/log de esa RC para identificar dónde se trabó y avisar la causa en una línea. No arrancar tarea nueva ignorando el cuelgue previo. Caso real 2026-05-10 02:46: "fijate por que te habías colgado antes que tuve q reiniciar manualmente".
- [LECCION] Cuando Pablo responde "no entiendo q seria" tras una propuesta, NO repetir la misma explicación más larga. Reformular en 1-2 líneas con ejemplo concreto: qué archivo se toca, qué comando corre, qué resultado se ve. Si sigue sin quedar claro, mostrar el output esperado en vez de describirlo. Caso real 2026-05-10 13:36.

### 2026-05-10
- [LECCION] Cuando Pablo hace pregunta sí/no ("tengo la última versión sí o no?", "todas son mejoras o no?"), responder con SÍ o NO en la primera línea y después el contexto. Caso real 2026-05-10: Pablo tuvo que repreguntar lo mismo varias veces ("estas medio mariada hoy") porque el asistente daba análisis sin commitear a una respuesta binaria. Si no se puede responder sí/no, decir "no sé todavía" + qué se necesita verificar — pero nunca esquivar la pregunta con una lista.
- [LECCION] Heredocs `<<'PY'` ad-hoc son deuda técnica detectada en repetición: 4x python-heredoc en 24h (2026-05-10) y 7 heredocs ad-hoc señalados por Karpathy el 2026-05-07. Cuando se detecta el mismo heredoc usado 2+ veces en una sesión, parar, crear un script versionado en `/home/ubuntu/projects/oraculo/tools/<nombre-específico>.{sh,py}` con nombre descriptivo y reusarlo. Pablo aceptó selectivamente "ok solo 4 y 5" cuando se le ofrecieron mejoras genéricas → la regla es: proponer wrappers concretos por caso de uso, no batches genéricos de "versionar todo".
- [LECCION] Si la sesión Claude se cuelga y Pablo tiene que reiniciar manualmente (caso 2026-05-10: "te habías colgado antes que tuve q reiniciar manualmente. hiciste todo lo q te pegue antes?"), al retomar la sesión NO responder de memoria si las tareas previas se completaron. Leer el último transcript / log de sesión real (`/home/ubuntu/projects/oraculo/logs/session-*.json`, transcripts en `~/.claude/`) y reportar con evidencia: "Quedó hecho X (commit/curl), quedó a medias Y, no se llegó a Z". Pablo prefiere "no sé qué quedó hecho, lo verifico ahora" antes que un "sí, hice todo" sin chequear.

- [LECCION] Las sesiones horarias "say OK" (15 de 16 sesiones en estas 48h) son heartbeat del cron y están diluyendo el análisis del Karpathy. Filtrar en el recolector de datos: excluir sesiones donde `cantidad_mensajes==1` Y el único mensaje matchea `^say OK\s*$`. Sin filtro, el modelo gasta contexto y atención en ruido en vez de en las pocas sesiones reales con señal.

### 2026-05-09
- [LECCION] Cuando presentes a Pablo una lista de items para decisión (RCs a matar, releases viejos, backups, archivos a borrar), incluí en el mismo listado qué es / cuándo se creó / para qué servía cada uno. El 2026-05-08 Pablo tuvo que preguntar "q es 6. gruposer-landing? / q hace este ahi 11. seragro-backup-pre-migration-20260505" porque la lista vino sin contexto — esa fricción se evita enriqueciendo cada ítem desde la primera respuesta.
- [LECCION] Al tocar el regex de detección de comandos destructivos en `/home/ubuntu/projects/oraculo/tools/hook-block-cross-project.py`, cubrir siempre las variantes con path absoluto (`/bin/rm`, `/usr/bin/mv`, `/usr/bin/sed -i`, `/usr/bin/tee`, `/bin/cp`, etc.) además del comando pelado. Pablo identificó este "cabo suelto" el 2026-05-08 — el agujero es teórico hoy pero cualquier futuro fix al hook debe incluir ambas formas.
- [LECCION] Cuando Pablo termina un prompt con "Oraculo tiene permiso global" (o equivalente: "tenés permiso", "dale", "autorizado") delegando tarea cross-project (ej: nginx + cert para otro dominio, migrar DNS, eliminar config de otro proyecto), saltear el paso de pedir confirmación adicional del flujo rc-oraculo. El AVISO del hook + el anuncio explícito de qué se va a tocar son suficientes; volver a preguntar duplica fricción cuando Pablo ya autorizó en el mismo mensaje.

### 2026-05-08
- [LECCION] ARM no puede depender de la Mac de Pablo para tareas programadas. Pablo dijo textual: "no esta prendida mi mac a las 3am y no es mejor q todo esto este en arm? sin depender de mi mac?". Cualquier cron/automatización ARM que requiera la Mac (sync cookies YouTube, screenshots, bridge de imágenes) DEBE: (a) ejecutarse en ARM si es técnicamente posible, (b) si necesita la Mac, detectar Mac-offline antes de correr, loguear "skip Mac-off" y reintentar en la próxima ventana, NUNCA fallar silencioso ni asumir que la Mac responde 24/7.
- [LECCION] Cuando generes el reporte diario de mejoras (Karpathy Loop), ordená cada sugerencia por **ahorro concreto** (minutos/semana, o "evita incidente X"), no lista plana. Pablo respondió "3 que mejora me hace?" y después "ok solo 4 y 5" — descartó la mayoría y eligió solo las que tenían valor claro. Formato: `N. <mejora> — ahorra ~Xmin/semana porque <razón medible>`. Si no podés cuantificar el ahorro, no la propongas.
- [LECCION] Heredocs `<<'PY'` ad-hoc que aparecen 4+ veces en 24h (vía `session-start-brief`) son tool faltante. Cuando vayas a escribir un heredoc Python/bash que ya escribiste en una sesión anterior, versionalo en `/home/ubuntu/projects/oraculo/tools/<nombre>.py|sh` con shebang+args y reusalo. La señal está en `TOP-5 COMANDOS BASH REPETIDOS` del SessionStart — si ves `Nx python-heredoc` con N≥3, esa es la próxima tool a crear antes de seguir improvisando.

### 2026-05-07
- [LECCION] **NUNCA usar `grep "string"` para inferir estado oficial de una API externa.** El `tools/audit-meta-whatsapp.sh` usaba `grep -q "locked"` sobre el response del endpoint de Meta para decidir si una cuenta WhatsApp Business estaba bloqueada. Cuando Meta devolvía un response transient SIN esa palabra (timeout, body vacío, error genérico distinto al 131031), el script asumía "ya no está bloqueada" → mandaba 🟢 DESBLOQUEADA falso. Caso real 19:10: ovidio seguía LOCKED (verificado en API), pero el check transient mandó verde y 10min después rojo — alertas contradictorias seguidas. **Regla**: para detectar estado vía API, parsear JSON real y distinguir 3 estados — `LOCKED` / `UNLOCKED` / `UNKNOWN`. `UNKNOWN` mantiene estado previo sin notificar. Nunca asumir el negativo desde ausencia de string.

- [LECCION] Cuando el reporte diario del Karpathy muestra `total=0 success=0 failed=0` pero igual sugiere acción sobre "Tracebacks recientes en PM2 oraculo" (caso 06/05 17:00), verificar el timestamp real de esos Tracebacks en `pm2 logs oraculo --err --lines 200` ANTES de presentar la sugerencia. Si los errores son de hace días/semanas y no hay actividad nueva, marcar la sugerencia como "histórica, no accionable" en vez de listarla como mejora pendiente — Pablo respondió "decime si hay mejoras o no" porque el reporte mezclaba ruido viejo con acción real.

- [LECCION] La tarea "Deploy Replit: Cianbox-Propio" falló con `CLI error (exit_code=1)` sin causa registrada (única falla en 30 tareas, rate 96%). Cuando una tarea de Oraculo falle con `CLI error (exit_code=N)` genérico, ANTES de reintentar leer `/home/ubuntu/projects/oraculo/logs/tasks/<task_id>.log` (o el stderr capturado) y registrar la causa raíz en el campo `error_detail` de la tarea — `exit_code=1` solo no permite diagnosticar ni evitar la próxima falla.

### Lecciones abril 2026 — ARCHIVADAS
Movidas a `docs/karpathy-archive/2026-04.md` (incidentes resueltos, reglas ya consolidadas arriba). Leer solo si investigás un incidente histórico.

## AUDITORÍA PROACTIVA DE SCRIPTS (regla 15 abril 2026)
Al inicio de cada sesión de trabajo significativa, verificar:
1. `grep uvicorn tools/self-heal.sh` → debe dar 0 resultados (solo pkill de limpieza es aceptable, nunca ejecución)
2. `grep gunicorn tools/ecosystem.config.cjs` → debe existir
3. `grep uvicorn tools/ecosystem.config.cjs` → debe dar 0 resultados
4. `systemctl is-enabled oraculo.service` → debe decir `disabled`
Si algo falla, corregir ANTES de hacer cualquier otra cosa.
Razón: había un bug silencioso en self-heal.sh que decía "gunicorn" en comentarios pero ejecutaba uvicorn. Nadie lo detectó durante días.

## REGLA CRÍTICA: SYSTEMD vs PM2 — NUNCA MEZCLAR (incidente 15 abril 2026)
- **PM2 es el ÚNICO gestor de oraculo, agent-runner, tutorai, crm, tunnel**
- **Systemd solo para infraestructura**: nginx, postgresql, pm2-ubuntu
- **NUNCA crear .service para procesos que PM2 maneja** — causa conflicto de puerto y boot-loops
- **NUNCA poner `sudo reboot` en scripts automáticos**
- `install-systemd-services.sh` está BLOQUEADO — no ejecutar
- Recovery: solo `pm2 restart`, nunca `systemctl restart oraculo`
- Verificar: `systemctl is-enabled oraculo.service` debe decir `disabled`
