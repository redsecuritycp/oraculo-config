# CLAUDE.md — ARM (Global)

Este archivo se lee en TODOS los proyectos de ARM. Contiene lecciones aprendidas que aplican transversalmente.

---

## ⛔ ZIVON ELIMINADO (2026-06-05) — REGLA DURA, APLICA A TODOS LOS PROYECTOS

**Pablo borró ZIVON el 2026-06-05. NO existe más. NO es una máquina apagada — está eliminada.**

- **NO** intentar `ssh zivon` / `100.80.5.31` / Tailscale a ZIVON. No hay relay por Mac. No hay nada que reactivar.
- **NO** diseñar ninguna solución que dependa de ZIVON (túnel, proxy, SOCKS5, SSH, HikCentral, IP residencial).
- Cualquier doc/CLAUDE.md/memoria que diga "ARM tiene SSH a ZIVON", "ZIVON prendida 24/7", "Pablo es relay vía Mac", "túnel reverso a ZIVON" → **OBSOLETO**, ignorar.

**Lo que ZIVON se llevó:**
- **ClaudeClaw** (bot WhatsApp/Telegram + HikCentral cámaras) — vivía en ZIVON. MUERTO.
- **wa-engine residential tunnel** — el egress de WhatsApp salía por `socks5://127.0.0.1:11080` = túnel reverso desde ZIVON (`WA_PROXY_POOL: "zivon-tunnel"`). Túnel muerto → **WhatsApp de wa-engine PAUSADO** (Marinaos, servistecnicos). Por diseño pausa en vez de banear (sin riesgo de ban), pero **no envía hasta tener IP residencial AR nueva** (4G casero / proxy residencial / otra). Decisión de Pablo pendiente. NO apuntar wa-engine a salida directa (= IP datacenter = ban).
- HikCentral (cámaras Carlos Pellegrini).

**ARM siempre fue 100% independiente de ZIVON para sus tareas** — esto no cambia eso, solo confirma que ZIVON ya no es opción para NADA.

---

## DIRECTIVAS COMPARTIDAS
Leer siempre:
- `/home/ubuntu/projects/shared/super-yo.md` — reglas universales de Pablo (onboarding completo, metodología, infraestructura, deploy)

---

## PROYECTO NUEVO — REGLA DURA DE ARRANQUE (2026-05-20) ⭐

**TODO proyecto nuevo, desde el primer commit, DEBE tener:**

1. **Repo GitHub privado** creado bajo `redsecuritycp/<nombre>` (no quedarse solo con repo local — sin remote no hay CI, no hay backup, no hay history-share).
2. **`.github/workflows/ci.yml` activo y corriendo verde** en la primera push. Templated por `tools/setup-ci-workflow.sh`. Lint del stack que corresponda (Node/Python/Bash/XML) + secrets scan obligatorio.
3. **`modules/` dir** con `README.md` explicando estructura modular obligatoria. Feature nueva = módulo nuevo, NO scripts sueltos en raíz.
4. **`CLAUDE.md`** del proyecto con contenido real (no placeholder).

**Aplicación automática:** `onboard-project.sh` ejecuta los 4 pasos en sección 9.6 del script. Si Claude crea un proyecto sin pasar por onboard, igual debe cumplir los 4 manualmente en el mismo turno.

**Anti-regresión (Claude futuro):**
- Cuando Pablo diga "creá proyecto X", "armá rc-X" o "migrá Y a ARM": el primer paso es onboard + verificar los 4 puntos.
- Si encontrás proyecto en `/home/ubuntu/projects/` sin repo GH, sin CI, sin `modules/`, o sin `CLAUDE.md`: deuda técnica P0, completarlo en el mismo turno.
- Defensa: `tools/audit-claudemd.sh` (CLAUDE.md), `tools/audit-domains.sh` (registry), y onboarding bloquea avance si faltan.

**PAT con scope `workflow` requerido** para push de archivos en `.github/workflows/`. Sin ese scope, push falla con `refusing to allow a Personal Access Token to create or update workflow`. Si pasa, pedir PAT nuevo a Pablo — NO intentar workarounds (deja CI inactivo).

**Por qué la regla:** Pablo (2026-05-20) textual: *"si esto deberia ser de arrancada en cada proyecto, ya deberia ser asi. registralo donde sea pero q se cumpla la puta madre"*. Cada proyecto sin CI activo es deuda técnica que cuesta tiempo después. Sin repo GH = sin backup, sin pair-review, sin ultrareview. Sin modular = monolito que cuesta migrar.

---

## WHATSAPP — REGLA DURA wa-engine (2026-05-19) ⭐ NUEVA REGLA, SOBREESCRIBE LA ANTERIOR

**TODO proyecto que necesite WhatsApp DEBE consumir el módulo `wa-engine` vía HTTP REST. PROHIBIDO importar Baileys (o whatsapp-web.js, wppconnect, OpenWA, etc.) directo en proyecto cliente.** Sin excepciones (salvo Ovidio que usa WhatsApp Cloud API oficial de Meta).

**Por qué:**
1. **Anti-baneo centralizado**: las 6 safeguards + throttle + jitter + typing sim + proxy residencial AR — solo se mantienen en UN lugar (`oraculo/modules/wa-engine/`)
2. **DRY**: una sola implementación, no copy-paste entre 5 proyectos
3. **Observability**: dashboard único `/dashboard` con todas las sesiones
4. **Rotación de IPs**: pool de proxies centralizado (proxy actual: `zivon-tunnel` → IP residencial AR `45.224.55.249` San Jorge via reverse SSH tunnel desde ZIVON)
5. **Lección histórica**: Marinaos perdió 2 números en 5-6 mayo 2026 por baileys directo en cada proyecto sin safeguards completas

### Arquitectura

```
┌──────────────────────────────────────────────┐
│ ARM                                           │
│   oraculo/modules/wa-engine (Node + Baileys) │
│   ├── API REST :7100                          │
│   ├── 6 safeguards + throttle + warming       │
│   └── salida via socks5://127.0.0.1:11080     │
└────────────────┬─────────────────────────────┘
                 │ reverse SSH tunnel
                 ▼
┌──────────────────────────────────────────────┐
│ ZIVON (oficina San Jorge)                     │
│   3proxy SOCKS5 :1080                         │
│   └─→ egress por internet residencial AR      │
│       (45.224.55.249, Summit S.A.)            │
└──────────────────────────────────────────────┘

Proyectos cliente → HTTP REST → wa-engine
```

### Patrón cliente (TODO proyecto que use WA)

```javascript
// PROHIBIDO: import { makeWASocket } from '@whiskeysockets/baileys'
// OBLIGATORIO:
const WA_ENGINE = process.env.WA_ENGINE_URL ?? 'http://localhost:7100'
const API_KEY = process.env.WA_ENGINE_API_KEY

async function sendText(sessionId, to, text) {
  const res = await fetch(`${WA_ENGINE}/sessions/${sessionId}/send-text`, {
    method: 'POST',
    headers: { 'X-Api-Key': API_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ to, text })
  })
  return res.json()
}

async function sendMedia(sessionId, to, type, base64OrUrl, caption) {
  return fetch(`${WA_ENGINE}/sessions/${sessionId}/send-media`, {
    method: 'POST',
    headers: { 'X-Api-Key': API_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ to, type, base64: base64OrUrl, caption })
  }).then(r => r.json())
}
```

### Recibir mensajes (webhooks)

Cada proyecto registra UN webhook en wa-engine:
```bash
curl -X POST http://localhost:7100/webhooks \
  -H "X-Api-Key: $WA_ENGINE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://tu-proyecto.gruposer.com.ar/wa/webhook",
    "events": ["message.received", "session.status"],
    "secret": "tu-secret-hmac"
  }'
```

wa-engine va a hacer POST a tu URL con HMAC SHA256 firma (`X-Webhook-Signature: sha256=...`).

### Onboarding nuevo proyecto WA

1. Pedir a Pablo número WhatsApp + chip físico (o asignar uno descartable)
2. POST `/sessions/<sessionId>/start` → wa-engine devuelve QR (vía endpoint `/sessions/<id>/qr` o webhook `session.qr`)
3. Pablo escanea con celular físico del número
4. Sesión queda vinculada, sale por IP residencial via ZIVON tunnel
5. Proyecto cliente solo consume HTTP REST de wa-engine

### Limitaciones a respetar

- **Warming curve**: número nuevo arranca con 5 msg/día → escala automático con edad (20, 50, 200, 500, 1000)
- **Outbound a contactos sin opt-in = RIESGO** — anti-baneo NO es magia
- **Para campañas masivas / broadcasts**: usar WhatsApp Cloud API oficial de Meta (NO wa-engine). Ej: ovidio-botvendedor
- **Volumen alto sostenido** (>1000 msg/día/número): considerar BSP (Wati, 360dialog) o múltiples sesiones

### Migración proyectos existentes

Orden (riesgo bajo → alto):
1. ✅ Piloto: `servistecnicos-gianfranco` (pausado por safeguards, riesgo cero)
2. Si OK 48h → resto sesiones servistecnicos (admin, bruno)
3. Marinaos
4. ClaudeClaw
5. dania-captador

NO migrar: ovidio (Cloud API), ClaudeClaw (vive en ZIVON, evaluar caso aparte)

### Para Claude futuro — anti-regresión

- **Cuando Pablo pida agregar WhatsApp a un proyecto nuevo**: PRIMERA tarea = leer este README, NO copiar código baileys de otro proyecto.
- **Si encontrás un proyecto importando baileys directo**: deuda técnica P0, refactorizar a usar wa-engine vía HTTP.
- **wa-engine corre en ARM solamente**. Salida a internet pasa por ZIVON tunnel (`socks5://127.0.0.1:11080`). Si ZIVON cae, el tunnel cae, las sesiones se pausan automáticamente. Eso ES el diseño — preferimos pausar a banear.
- **Cualquier cambio al wa-engine se documenta acá Y en `modules/wa-engine/README.md`**.

---

## WHATSAPP VIA BAILEYS (HISTÓRICO — sustituido por wa-engine)
Detalle completo de las 6 salvaguardas anti-baneo: `/home/ubuntu/oraculo-config/claude-md/historical/wa-baileys-salvaguardas.md`. Leer SOLO si tocás código baileys legacy.

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
4. **Allowlist explícito** `ALLOWED_EXTRA_BY_CWD` (agregada 2026-05-08). Para casos donde el código del proyecto vive físicamente fuera del repo (ej: rc-odoo y `/opt/odoo/custom-addons/`, `/opt/odoo/addons-extra/`, `/home/ubuntu/deployments/argo.gruposer.com.ar/`).
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
- **argo.gruposer.com.ar** → **Argo** (Odoo 18 Community Grupo SER en ARM, 161.153.207.224, systemd `odoo.service`, puerto 8069). Renombrado 2026-05-14: nombre canónico del proyecto = **Argo**. Dominio público se mantiene. Acceso: `/home/ubuntu/projects/argo/` y registry key `argo` (alias del directorio legacy).
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
| **Argo** (legacy: argo.gruposer.com.ar) | https://argo.gruposer.com.ar | 8069 | systemd `odoo.service` |
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

## COMPUTER-USE MCP (Mac) — solo aplica en claude.ai Desktop con computer-use, NO en RCs de ARM
Playbook completo: `/home/ubuntu/oraculo-config/claude-md/historical/computer-use-mac.md`

---

## CREDENCIALES — NUNCA transcribir del chat sin verificación visual

**Caso real 2026-04-23:** Pablo pasó password por chat como `Red24365!`. La consola Ruijie mostraba `Red24365*` (enmascarada, el `*` era el dot de mask). Claude intentó autenticarse con `Red24365*` literal → auth failed. La correcta era `Red24365!`.

**Regla:** si hay discrepancia entre lo que Pablo dice por chat y lo que se ve en pantalla, **PARAR** y pedir que Pablo:
1. Haga click al ícono del ojo (reveal password) para ver en claro
2. Confirme la password literal antes de reintentar

Los `*`, `•`, `●` en pantallas de auth casi siempre son mask de dots, NO el carácter real de la contraseña.

---

## PLAYBOOK OpenVPN Connect v3 + Ruijie (Mac)
Flow completo: `/home/ubuntu/oraculo-config/claude-md/historical/openvpn-ruijie-mac.md`. Leer solo si Pablo pide configurar VPN en el Mac.
