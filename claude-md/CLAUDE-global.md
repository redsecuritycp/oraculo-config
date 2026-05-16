# CLAUDE.md — ARM (Global)

Este archivo se lee en TODOS los proyectos de ARM. Contiene lecciones aprendidas que aplican transversalmente.

## DIRECTIVAS COMPARTIDAS
Leer siempre:
- `/home/ubuntu/projects/shared/super-yo.md` — reglas universales de Pablo (onboarding completo, metodología, infraestructura, deploy)

---

## WHATSAPP VIA BAILEYS — SALVAGUARDAS ANTI-BANEO META OBLIGATORIAS (2026-05-08)

**TODO proyecto que conecte WhatsApp vía Baileys / whatsapp-web.js / wppconnect / cualquier integración no-oficial DEBE implementar las 6 salvaguardas anti-baneo + bug fixes + Telegram alerts + persistencia + silenciador libsignal.** Sin excepciones.

**Por qué la regla**: Pablo perdió 2+ números entre 5-6 mayo 2026 por QR loop infinito + IP datacenter + signaling continuo a Meta. Cada número perdido = lista de clientes en ese chat perdida + costo de mover a un número nuevo. La regla operativa de Pablo: **"ante la duda, pausar y proteger los números"**.

### Referencia canónica

- `servistecnicosRED/server/wa-client.ts` (TypeScript, multi-tenant) — implementación de referencia v77 (8 mayo 2026)
- `Marinaos/wa-bridge/server.js` (JS plano, single-tenant) — port equivalente

Cualquier proyecto WhatsApp **debe portar el mismo patrón**, adaptando lenguaje pero preservando comportamiento.

### Las 6 salvaguardas (todas obligatorias)

1. **QR timeout 30 min**: si entra estado `qr` y nadie escanea en 30 min → safetyStop, alerta Telegram, NO sigue generando QRs. Loop perpetuo de QR fue uno de los factores del baneo Marinaos 06/05.
2. **Flapping detector**: si > 3 `connection: open` en ventana de 1h → pausa + alerta. Reconexiones repetidas son señal pre-baneo.
3. **Cierres consecutivos sin open**: contador que sube en cada `close` y se resetea en `open`. Si llega a 3 → pausa + alerta. Indica Meta rechazando la sesión.
4. **Keywords sospechosas**: en `lastDisconnect.error.message`, regex `/\b(banned|blocked|forbidden|prohibited|403|405|account[\s-]?suspend)/i` o `statusCode === 403 || 405` → pausa inmediata.
5. **`loggedOut` sin auto-rebind**: cuando llega `DisconnectReason.loggedOut`, NO reabrir la sesión automáticamente (es signaling extra a Meta). Pausar + alerta. Pablo decide si reactivar (desvinculación legítima) o no (posible ban).
6. **Persistencia en disco**: cuando se pausa, escribir `<sessionDir>/.stopped` con `{ reason, at, lastError }`. Al boot del proceso, si existe el marker → cargar estado y NO arrancar el socket. Endpoint `POST /reactivate` que borra el marker y arranca de nuevo (con flag `wipe_auth=true` para casos `logged_out` que requieren credenciales nuevas).

### Bug fixes obligatorios (lección servistecnicos 2026-05-08)

- En `safetyStop`, **antes** de cerrar el socket: `sock.ev.removeAllListeners()`. Sin esto, Baileys sigue disparando events post-stop → más signaling a Meta justo cuando NO queremos.
- Al inicio del handler `connection.update`: `if (this.stopped || this.sock !== sock) return;`. Guard contra eventos rezagados de sockets viejos que ensucian el estado del socket nuevo.

### Notificaciones Telegram (failsafe)

- Token y chat_id: leer de `/home/ubuntu/.secrets/telegram-oraculo.env` (mismo bot que usa Oraculo). NO hardcodear en código ni en docs.
- URL endpoint: `https://api.telegram.org/bot<TOKEN>/sendMessage`
- **Failsafe**: si POST falla (red caída, token revocado), **NO crashear el bridge**. Solo loguear.
- Mensaje incluye: nombre proyecto, razón de pausa, número afectado, instrucción concreta para Pablo (qué reactivar / qué verificar primero).

### Silenciador libsignal (obligatorio)

`libsignal/src/session_record.js` hace `console.info("Closing session:", sessionGigante)` por cada cierre de sesión WA. Sin silenciar, los logs PM2 se llenan a varios MB/h. **Logrotate matando logs grandes mientras pm2 los tiene abiertos puede disparar respawn del daemon** (incidente servistecnicos 06:00 del 2026-05-08).

Solución: módulo `silence-libsignal` que se require **PRIMERO de todo, antes de cargar Baileys**, hace override de `console.info` para descartar mensajes que matchean `/^Closing session:/`.

### Endpoints HTTP obligatorios

- `POST /reactivate` — borra el `.stopped` marker, opcional `{ wipe_auth: true }` para wipe de credenciales (caso `logged_out`)
- `POST /manual-stop` — pausa preventiva manual con nota
- `GET /status` debe incluir: `stopped`, `stoppedReason`, `stoppedAt`, `lastError`, `flapping_open_count`, `consecutive_closes_without_open`

### pm2-logrotate (system-wide)

Aplicar en **TODO ARM** (no solo en proyectos WA), pero crítico para WA:

```bash
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 50M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true
pm2 set pm2-logrotate:rotateInterval '0 2 * * *'
```

### Anti-regresión (regla para Claude futuro)

- Cuando Pablo cree un proyecto nuevo con WhatsApp Baileys/web.js: **PRIMERA tarea** es portar las 6 salvaguardas. NO arrancar producción sin ellas.
- Si encontrás un proyecto WA que no tiene `silence-libsignal`, `.stopped` marker, o `removeAllListeners`: **deuda técnica crítica**, avisar a Pablo y portarlas.
- NUNCA conectar el WhatsApp **personal** de Pablo a Baileys/QR. Solo números descartables o de empresa.
- Si las salvaguardas mismas se rompen (caso real: bridge sin guard `if (stopped...) return;` que sigue disparando QRs post-stop), tratarlo como bug **P0** y arreglar inmediato.

### Lo que NO arregla esto

Las salvaguardas reducen el riesgo, **no lo eliminan**. Para campañas masivas o uso intensivo, el camino seguro sigue siendo **WhatsApp Cloud API oficial** (con plantillas pre-aprobadas) o **BSP (Wati / 360dialog)**. Baileys está OK para:
- Atención al cliente conversacional bajo volumen
- Bot de respuestas a clientes que ya iniciaron contacto
- Casos donde el costo de un ban ocasional es tolerable

**NO está OK** para:
- Mass marketing / broadcasts a contactos sin opt-in
- Volumen alto sostenido (>500 msg/día)
- Números de la línea principal del negocio

---

## DEPLOY UNIVERSAL CON ROLLBACK — REGLA DURA (2026-05-05)

**TODO proyecto que corra en ARM (existente, nuevo, o migrado) DEBE estar en el sistema de releases versionadas con rollback.** Sin excepciones, salvo las dos infraestructurales (Odoo systemd con `deploy-odoo.sh`, oraculo-tunnel SSH-only).

**Por qué esta regla:** Pablo necesita poder (1) aplicar un cambio y que los usuarios lo vean, (2) si rompe, volver a la versión anterior estable en segundos. Sin releases versionadas, "rollback" = `git revert` + restart manual, lento y riesgoso. Inaceptable.

**Estado al 2026-05-05:** solo 3 proyectos cumplían la regla (tutorai, servistecnicos-red, oraculo). Los 8 restantes corrían PM2 directo del repo, sin releases. Migración en curso este día.

**Cómo se onboardea cualquier proyecto nuevo o que se migra a ARM:**
```bash
bash /home/ubuntu/oraculo/tools/onboard-project.sh <nombre> <tipo> <puerto> <dominio> <source>
# Tipo: node | python | php
# Source: ssh:NombreReplit | local:/ruta | git:url
```
El script crea estructura `deployments/<nombre>/{releases,shared}/`, registra en `registry.json`, configura DuckDNS+Nginx+SSL, y corre el primer deploy. Si todo OK → PM2 apunta a `current` symlink y queda con rollback nativo.

**Flujo operativo después del onboard:**
```bash
deploy-arm.sh <proyecto>          # nuevo cambio → release v(N+1) + symlink swap + health check + auto-rollback si falla
rollback-arm.sh <proyecto>        # vuelve al release anterior en ~5 segundos
rollback-arm.sh <proyecto> v3     # vuelve a un release específico
```

**Excepción Odoo:** el código vive en `/opt/odoo/custom-addons/`, gestión por systemd. Para aplicar cambios usar `bash /home/ubuntu/oraculo/tools/deploy-odoo.sh <modulo>` que hace upgrade del módulo + `systemctl restart odoo`. NO mezclar con deploy-arm.sh.

**Anti-regresión (regla para Claude futuro):**
- Cuando Pablo diga "migrá X a ARM" o "agregá un proyecto nuevo": el primer paso ES `onboard-project.sh`. NUNCA dejar un proyecto corriendo PM2 directo del repo.
- Si encontrás un proyecto en PM2 con cwd fuera de `/home/ubuntu/deployments/<X>/current`: ese proyecto está en deuda técnica. Avisar a Pablo y migrarlo.
- Cualquier cambio en producción (edit + restart) DEBE hacerse via `deploy-arm.sh` para que quede el release versionado. Editar el repo + `pm2 restart` está PROHIBIDO salvo emergencia documentada.

---

## AISLAMIENTO ENTRE PROYECTOS — REGLA DURA (2026-05-05, refinada 2026-05-11)

**Cada RC solo puede MODIFICAR archivos que pertenecen a SU PROPIO proyecto.** Read/Grep/Glob entre proyectos sigue libre — ver sí, tocar no.

La regla NO es "solo el cwd" — un proyecto tiene partes que viven naturalmente fuera del repo (nginx config del dominio, SSL cert, releases ARM, logs, memoria persistente). El hook reconoce todos esos paths como parte del proyecto.

Incidente que disparó la regla original: rc-isr-web editó `/opt/odoo/custom-addons/isr_api_pub/controllers/main.py` — código de Odoo, otro proyecto. Inaceptable.

**Implementación:** hook global `PreToolUse` en `~/.claude/settings.json` → `/home/ubuntu/projects/oraculo/tools/hook-block-cross-project.py`. Aplica automáticamente a todos los RCs presentes y futuros.

**Qué cubre el bloqueo:**
- `Edit`, `Write`, `MultiEdit`, `NotebookEdit` con `file_path` fuera del proyecto → bloqueado.
- `Bash` con `rm`, `mv`, `cp`, `tee`, `sed -i`, `>`, `>>`, `dd`, `chmod`, `chown`, `truncate`, `install`, `mkdir`, `rmdir` apuntando a paths fuera del proyecto → bloqueado.

**Paths que el hook reconoce como "propios" de cada RC** (cwd `/home/ubuntu/projects/<X>`):
1. **El cwd** `/home/ubuntu/projects/<X>/` y todo lo que cuelga.
2. **Scratch** `/tmp/`, `/var/tmp/` (cualquier RC).
3. **Memoria persistente del RC** `~/.claude/projects/-<encoded-cwd>/` (fix 2026-05-11). Cada RC puede escribir su `MEMORY.md` y memorias individuales; sigue bloqueado para tocar la memoria de otros RCs.
4. **Allowlist explícito** `ALLOWED_EXTRA_BY_CWD` (agregada 2026-05-08). Para casos donde el código del proyecto vive físicamente fuera del repo (ej: rc-odoo y `/opt/odoo/custom-addons/`, `/opt/odoo/addons-extra/`, `/home/ubuntu/deployments/odoo.gruposer.com.ar/`).
5. **Paths-sistema auto-derivados del registry** (fix 2026-05-11). El hook resuelve nombre+dominio del proyecto desde `/home/ubuntu/deployments/registry.json` y auto-permite:
   - `/etc/nginx/sites-available/<proj|dominio>[.conf]`
   - `/etc/nginx/sites-enabled/<proj|dominio>[.conf]`
   - `/etc/letsencrypt/{live,archive}/<dominio>/`, `/etc/letsencrypt/renewal/<dominio>.conf`
   - `/var/log/<proj>/`, `/var/log/nginx/<proj|dominio>*`
   - `/home/ubuntu/deployments/<proj>/`
   - `/home/ubuntu/backups/<proj>*`

   El matching de nombre tolera camelCase/kebab/snake/dots (`servistecnicosRED` ↔ `servistecnicos-red`). Sin mantenimiento manual: cuando agregás un proyecto a `registry.json`, el hook ya sabe sus paths-sistema.

**Cómo agregar excepciones nuevas:**
- Si el path encaja en alguno de los 5 patrones de arriba → automático, no hay que tocar nada.
- Si es algo fuera de patrón (rarísimo): editar `ALLOWED_EXTRA_BY_CWD` en el hook. La allowlist es por cwd específico — no se hereda, no se generaliza.

**Excepción única — rc-oraculo:** si el cwd es `/home/ubuntu/projects/oraculo` (o legacy `/home/ubuntu/oraculo`), el hook NO bloquea pero emite un AVISO al asistente. Antes de tocar otro proyecto, oraculo tiene que:
1. Anunciar explícitamente qué proyecto va a modificar y por qué.
2. Pedir confirmación a Pablo (salteable si Pablo delega explícitamente con "tenés permiso" / "encargate vos" / "autorizado" en el mismo mensaje).
3. Recién ahí ejecutar.

**Si necesitás cambiar otro proyecto desde un RC que no es oraculo:** abrí el RC de ese proyecto, o pedile a rc-oraculo (con permiso de Pablo).

---

## ARQUITECTURA MODULAR — REGLA DE ORO (2026-05-12, ratificada 2026-05-14)

**REGLA DE ORO ABSOLUTA — sin excepciones:**

1. **Todo proyecto NUEVO de acá en adelante nace MODULAR** desde el primer commit. NO se acepta crear un proyecto monolítico "para arrancar rápido y modularizar después". Eso es parche, y Pablo NO quiere parches en nada.
2. **Todo feature NUEVO en proyecto existente va como MÓDULO**, incluso si el proyecto sigue siendo monolítico. El monolito viejo se modulariza en paralelo, pero el código nuevo NO se mete adentro.
3. **Para modularizar proyectos legacy** (isr-web, Marinaos, servistecnicos, etc.): preferentemente **Estrategia A — Refactor incremental** (1 módulo por fase, deployable, rollback ready). Si el stack viejo no sirve (ej: frontend Vue 3 nuevo), va **Estrategia B — Strangler** (proyecto nuevo nace en paralelo, va comiéndose features hasta jubilar al viejo).
4. **NUNCA Estrategia C (rewrite big-bang)**. Es donde mueren los proyectos. Si necesitás cambiar todo, A o B en paralelo sin romper, jamás "apago el viejo y prendo el nuevo el mismo día".
5. **NUNCA sacar producción durante la migración**. Si rompe → `rollback-arm.sh <proyecto>` en 5 segundos.

Estas reglas se aplican a **todos los proyectos ARM y cualquier proyecto futuro**. Cada proyecto ARM y cada feature nueva DEBE estructurarse como módulos isolables, no como monolitos crecientes. Los proyectos legacy se modularizan **gradualmente** cuando los toquemos.

### Por qué la regla (Pablo, 12/05/2026)

> "Si modificás un módulo y se daña, solo se daña ese módulo. Si agregás un módulo nuevo, no tocamos el resto."

Pablo perdió tiempo en proyectos-monstruo donde un cambio a un feature rompía otro feature no relacionado. La regla apunta a **aislamiento**: cada feature debe poder romperse, desactivarse, migrarse sin afectar al resto.

### Qué cuenta como "módulo"

Un módulo es una unidad **autosuficiente** con:

1. **Carpeta dedicada** con nombre descriptivo (`session-continuity/`, `gs_cianbox_sync/`, `wa-safeguards/`)
2. **README.md** que explica qué hace, cómo se instala, cómo se desinstala
3. **install.sh / uninstall.sh** (o equivalente del stack: `__manifest__.py` en Odoo, `package.json` en Node)
4. **Código propio** sin tocar otros módulos. Si necesita usar otro módulo, lo declara como **dependencia**, no copia código.
5. **Tests propios** (ideal, no obligatorio para módulos pequeños)
6. **Versionado independiente** (cuando aplique)

### Patrón por stack

| Stack | Estructura módulo | Ejemplo |
|---|---|---|
| Oraculo (bash + python tools) | `oraculo/modules/<nombre>/{install.sh, uninstall.sh, README.md, ...}` | `session-continuity/` |
| Odoo | Custom addon en `/opt/odoo/custom-addons/<nombre>/` con `__manifest__.py`, `models/`, `data/`, `README.md` | `gs_cianbox_sync/`, `gs_wa_notifications/` |
| Node.js (isr-web, marinaos, servistecnicos) | `src/modules/<nombre>/{index.js, routes.js, service.js, model.js, README.md}` | `src/modules/leads/`, `src/modules/vehicles/` |
| Python (oraculo core) | `oraculo/<feature>/{__init__.py, ...}` con import explícito en `main.py` | `oraculo/karpathy/`, `oraculo/clones/` |

### Reglas operativas

1. **Feature nueva = módulo nuevo.** Si dudás:
   - ¿Se puede desactivar sin romper otros features? → módulo nuevo
   - ¿Tiene su propia tabla / cron / endpoint? → módulo nuevo
   - ¿Es un fix dentro de algo existente? → modificar el módulo existente
2. **NO copiar código entre módulos.** Si dos módulos necesitan la misma utilidad → crear un módulo `shared/` o `utils/` que ambos importen.
3. **NO mezclar features en un script.** Un `sync_everything.py` que hace partners + products + invoices = anti-patrón. Tres módulos separados.
4. **Doc al lado del código.** Cada módulo tiene su README con: qué hace, dependencias, cómo se prueba, cómo se desinstala.
5. **Backwards compat al migrar.** Si movés un script a módulo, mantené un wrapper o symlink en la ubicación vieja durante 2-4 semanas, y dejá una entrada en `_deprecated/README.md` que diga dónde se movió.

### Cuándo NO aplica

- Scripts de **un solo archivo** (`< 100 líneas`) que hacen UNA cosa y no tienen dependencias internas. Vivir en `tools/` está bien.
- **Hotfixes** urgentes — primero arreglar, después modularizar si corresponde.
- **Configs / dotfiles** — no necesitan módulo.

### Anti-regresión (regla para Claude futuro)

- Cuando Pablo te pida agregar un feature, **primer paso = decidir si es módulo nuevo o cambio en existente**. Anunciar la decisión en una línea antes de codear.
- Si encontrás un script `tools/<feature>.py` que ya hace 3+ cosas no relacionadas, marcarlo en el reporte de Karpathy como candidato a modularizar.
- Si vas a tocar un addon Odoo / módulo Node existente, leé su README primero (si no tiene, escribilo antes de tocar).
- El módulo **`session-continuity`** (en `oraculo/modules/`) es el **template de referencia**. Si dudás cómo estructurar uno nuevo, mirá ese.

---

## CONTEXTO ENTRE SESIONES — MÓDULO `session-continuity` (2026-05-12)

Persistencia per-turn del estado de sesión: cuando una RC muere de golpe (firmware update, kill -9, crash), la próxima arranca sabiendo en qué se estaba trabajando.

**Ubicación**: `/home/ubuntu/projects/oraculo/modules/session-continuity/`
**Doc completa**: ver `README.md` del módulo.

### Resumen mínimo

Cuatro hooks en `~/.claude/settings.json` invocan los scripts del módulo:

| Hook | Cuándo | Trigger label |
|---|---|---|
| `UserPromptSubmit` | Cada prompt del usuario | `⏳ INTERMEDIO` |
| `PostToolUse` | Tras cada tool use (throttle 30 s) | `🔧 INTERMEDIO` |
| `Stop` | Cierre limpio | `✅ LIMPIO` |
| `SessionStart` | Inicio de nueva sesión | (lee el snapshot e inyecta contexto) |

Archivos escritos: `logs/last-session-summary.txt` (global) + `<CWD>/.claude/last-context.md` (per-proyecto).

### Regla para Claude futuro

- **NO editar los scripts directamente** — están en el módulo, tocá ahí.
- **NO romper la instalación.** Para verificar: `bash /home/ubuntu/projects/oraculo/modules/session-continuity/install.sh --check` → debe decir `✅ instalado`.
- Si Pablo dice "no sabés en qué estábamos" después de un restart de RC, correr el `--check` antes que cualquier otra cosa.

---

## HERRAMIENTAS GLOBALES INSTALADAS (ECC, abril 2026)

Pablo tiene este toolkit cargado en `~/.claude/{skills,agents,commands}/` — disponible en TODOS los proyectos. **Pablo NO va a invocarlas manualmente.** Vos (Claude) tenés que dispararlas vos cuando el contexto matchea.

**Durante el período de prueba (hasta 2026-05-09):** activamente probá CADA skill/agent/command al menos una vez en uso real cuando aparezca un caso aplicable. Si pasan días y todavía no usaste alguna, buscá conscientemente oportunidades de aplicarla en lo que estés haciendo (sin forzar — si no hay caso real, no inventes uno). El objetivo no es "marcar checks" sino conocer en práctica qué hace cada herramienta.

**Auditoría 2026-05-10 9:07 AM** (cron `ecc-audit-reminder.sh`): cuenta invocaciones reales en transcripts de los últimos 10 días y manda Telegram a Pablo con el reporte de USADAS / NO USADAS. **Pablo decide qué borrar** — el script NO borra solo. Cuando responda "borrá X" o "borrá los no usados", recién ahí Claude ejecuta el `rm`.

### Skills (auto-invocables — Claude las dispara cuando matchea el intent)

| Skill | Cuándo usarla (en lo que Pablo te diga) |
|---|---|
| `verification-loop` | Cuando hay que verificar un cambio con evidencia ANTES de decir "listo": "verificá", "está bien?", "anda?", "deployaste?", "probaste?" |
| `terminal-ops` | Cuando hay que ejecutar comandos en repo + mostrar evidencia exacta de qué corrió y qué salió: "corré X", "fijate qué hace", "ver CI", "debug build" |
| `automation-audit-ops` | Cuando Pablo quiere saber qué jobs/hooks/MCP/crons/wrappers están vivos, rotos, redundantes: "auditá los crons", "qué hooks corren", "está duplicado?", "limpieza de jobs" |
| `agent-introspection-debugging` | Cuando un agente/RC/proceso falló raro y hay que debug estructurado: "se colgó", "no anda", "qué pasó con la tarea X", "por qué falló" |
| `autonomous-agent-harness` | Cuando se diseña/ajusta un loop autónomo, cron, scheduled task, agente persistente — relevante para Oraculo, Karpathy Loop, watchdog |

### Skills (Superpowers, obra/superpowers — instaladas 2026-04-30, mismo período de prueba)

| Skill | Cuándo usarla |
|---|---|
| `systematic-debugging` | Ante CUALQUIER bug, fallo de tarea, comportamiento raro: ANTES de proponer fix, hacé root-cause-tracing 4-fase. Coincide con la lección "tareas fallan con 'Unknown error'" — fix sin entender = falla |
| `verification-before-completion` | ANTES de decir "listo", "deployado", "verificado", "anda" — corré evidencia (curl, query, log) y mostrala. Refuerza la regla "deploy = EVIDENCIA" |
| `requesting-code-review` | Tras completar tarea de Oraculo grande / migración / cambio que toca varios archivos, dispatch al subagente `code-reviewer` antes de declarar listo |
| `subagent-driven-development` | Para tareas grandes con múltiples pasos independientes (ej: migrar proyecto, auditar todo, refactor amplio): dispatch un subagente fresh por task con review en 2 etapas (spec compliance + quality) |

### Agentes (invocá con la herramienta Agent o subagent_type)

| Agente | Cuándo lanzarlo |
|---|---|
| `code-explorer` | Para mapear features/módulos en un codebase desconocido — trazá execution paths, arquitectura. Útil al onboarding de un proyecto migrado o repo nuevo |
| `code-reviewer` | Tras completar tarea grande de Oraculo / código nuevo en proyecto: revisa contra plan original + best practices. Lo invoca `requesting-code-review` |
| `silent-failure-hunter` | Después de escribir/editar código Python/JS donde puede haber `try/except` que tragan errores, fallbacks raros, retornos vacíos — Pablo dijo: "tareas fallan con 'Unknown error' sin causa" |
| `harness-optimizer` | Cuando Pablo te pide mejorar Oraculo, ajustar el Karpathy, optimizar agentes, revisar success rate |
| `python-reviewer` | Después de cambios significativos a `.py` (Oraculo, scripts) — antes de commit, revisá calidad/seguridad/PEP8 |

### Commands (Pablo puede tipearlos con `/`, pero también disparalos vos cuando aplique)

| Comando | Disparalo cuando |
|---|---|
| `/quality-gate` | Antes de un push/commit grande: corre lint+typecheck+tests sobre lo modificado |
| `/harness-audit` | Pablo dice "audita todo", "scorecard", "revisá el harness", "está bien Oraculo" |
| `/skill-health` | Pablo pregunta qué skills tiene, cuáles usa, dashboard de uso |
| `/save-session` y `/resume-session` | YA cubierto por `stop-hook-summary.sh` + `session-start-brief.sh`. NO disparar — son redundantes |

### Cómo decidir si disparar una skill o no

- **Disparala** si el intent de Pablo matchea el "Cuándo usarla" de la tabla — incluso si Pablo no la nombra.
- **No la dispares** solo porque está disponible. Cada skill cargada consume contexto. Si la tarea es simple ("apagame esto"), respondé directo sin invocar skills pesadas.
- **Si dudás entre dos**, elegí la más específica.

---

## VIDEOS DE PABLO — auto-procesar links

**Cuando Pablo pegue una URL de YouTube, Instagram, Vimeo, TikTok o Twitch (clips) en el chat, o te pase un path de archivo de video (.mp4, .mov, .mkv, .webm, .avi), corré automáticamente:**

```bash
bash /home/ubuntu/projects/oraculo/tools/video-process.sh "<url|path>"
```

El script:
- Descarga el video (con cookies sincronizadas del Chrome del Mac, anti-bot YouTube cubierto)
- Transcribe el audio con `whisper` → texto
- Extrae frames cada 10 segundos con `ffmpeg`
- Devuelve un directorio `/tmp/video-<hash>/` con `transcript.txt`, `frames/`, `meta.json`

Después, leé los frames como imágenes (tool Read) y la transcripción para responderle a Pablo. Patrones de URL a detectar:
- `youtube.com/watch`, `youtu.be/`, `youtube.com/shorts/`
- `instagram.com/reel`, `instagram.com/p/`, `instagram.com/tv/`
- `vimeo.com/<id>`
- `tiktok.com/@.../video/`
- `twitch.tv/.../clip/`, `clips.twitch.tv/`

**Cookies de YouTube**: viven en `/home/ubuntu/inbox/youtube_cookies.txt`, sincronizadas todas las noches por LaunchAgent del Mac. Si el script avisa "cookies vencidas", decirle a Pablo y él re-loguea en YouTube en su Chrome (la próxima sync nocturna las trae).

Opciones:
```bash
bash /home/ubuntu/projects/oraculo/tools/video-process.sh "<url>" --frames-every 5
bash /home/ubuntu/projects/oraculo/tools/video-process.sh "<url>" --no-frames
```

El script escribe en `/tmp/video-<hash>/`, scratch permitido por el hook anti-cross-project. Cualquier RC puede invocarlo.

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
- **odoo.gruposer.com.ar** → **Argo** (Odoo 18 Community Grupo SER en ARM, 161.153.207.224, systemd `odoo.service`, puerto 8069). Renombrado 2026-05-14: nombre canónico del proyecto = **Argo**. Dominio público se mantiene. Acceso: `/home/ubuntu/projects/argo/` y registry key `argo` (alias del directorio legacy).
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

## NOTIFICAR A PABLO POR EMAIL (cualquier sesión Claude)

Pablo NO está siempre mirando el chat de Claude. Para tareas largas (snapshots, deploys, scrapes) o cuando algo falla y el contexto se pierde, **avisarle por mail** siempre que pase alguno de estos casos:

- **Falla bloqueante**: script muere, login no autentica, integración rota, deploy falla 2 veces seguidas
- **Datos sospechosos**: scraper devolvió 0 productos, precios todos iguales, count drástico vs corrida anterior
- **Tarea larga terminó** (más de 5 min): snapshot listo, deploy ARM completado, migración finalizada

**Cómo:**
```bash
node /home/ubuntu/arm-config/notify-pablo.js "asunto corto" "cuerpo del mensaje"
# Niveles: error / warning / info (default)
node /home/ubuntu/arm-config/notify-pablo.js --json '{"subject":"X","body":"Y","level":"error"}'
# Cuerpo desde stdin para mensajes largos:
echo "stack trace largo" | node /home/ubuntu/arm-config/notify-pablo.js "deploy fallo"
```

Manda a `pansapablo@gmail.com` desde `pansapablo@gruposer.com.ar` (Gmail SMTP). Creds en `/home/ubuntu/.config/notify-creds.json` (chmod 600). Subject queda como `[ARM] asunto`, `[ARM ERROR] asunto`, `[ARM WARN] asunto`.

**Cuándo NO avisar:** cada cambio de archivo, diff trivial, pasos intermedios, builds OK normales — Pablo se molesta con ruido. La regla es: si NO le aviso ahora ¿se entera tarde y pierde tiempo? Si la respuesta es sí, mandar mail.

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

### Migración de Replits a ARM — LECCIÓN CRÍTICA (TutorAI abr 2026 + servistecnicosRED 04/05/2026)

**REGLA DURA NUEVA (servistecnicosRED 04/05/2026):**
Si el `.replit` del Repl tiene `postgresql-XX` en `modules` → **la DB Neon es de Replit**, NO independiente. Replit auto-provisiona Neon atado al ciclo de vida del Repl. Si el Repl muere, la DB se va con él.
- Caso real: `DATABASE_URL=postgresql://...@ep-square-snowflake-...neon.tech` quedó tras la "migración" 20/04 → Repl murió ~04/05 → data productiva de clientes perdida.
- **OBLIGATORIO antes de declarar migrado:** `bash /home/ubuntu/projects/oraculo/tools/migration-verify.sh <proyecto>` debe devolver exit 0. El script falla si la DB es externa sin whitelist.

**Defensas activas (instaladas 04/05/2026):**
- `tools/backup-postgres-daily.sh` — pg_dump diario 02:30 de TODAS las DBs locales, retención 14d local + Drive
- `tools/audit-external-dbs.sh` — diario 05:00. Alerta Telegram si encuentra DB externa no-whitelisted en cualquier proyecto. Cooldown 24h por host.
- `tools/migration-verify.sh <proj>` — checklist 8 puntos. Si falla → NO BORRAR origen.

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
| **Argo** (legacy: odoo.gruposer.com.ar) | https://odoo.gruposer.com.ar | 8069 | systemd `odoo.service` |
| dania-captador | https://dania-captador.duckdns.org | 3002 | PM2 `dania-captador` |
| servistecnicos-red | https://servistecnicos.gruposer.com.ar | 3003 | PM2 `servistecnicos-red` |
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
