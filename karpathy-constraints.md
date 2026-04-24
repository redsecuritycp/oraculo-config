# Constraints duras para el análisis del Karpathy

Este archivo se inyecta al prompt del `daily-improvements.sh` (y cualquier
otro Karpathy) antes de pedirle sugerencias. El objetivo es que nunca más
proponga mejoras que violen reglas explícitas de Pablo o que vayan contra
decisiones ya tomadas.

**Regla del workflow:** cuando Pablo define una regla dura nueva en una
conversación, agregala acá en la misma sesión. Si no, el Karpathy la va a
volver a proponer al día siguiente y es ruido.

---

## Rate limiting Anthropic — RCs simultáneas

- **MÁXIMO 5 sesiones RC (`tmux rc-*`) simultáneas** (regla Pablo
  2026-04-22, subida desde 3). El guard está en `rc-manager.sh start`.
- La whitelist persistente (auto-revive por rc-manager) es solo `oraculo`.
  Las demás se levantan on-demand desde la pestaña "Proyectos" del
  dashboard o con `rc-manager.sh start <nombre>`.
- **NO proponer**: "auto-levantar todos los RC al boot", "arrancar una RC
  por proyecto automáticamente", ni variantes que pasen de 5 simultáneas.
- **NO proponer bajar el límite a 2-3** — Pablo ya pidió explícitamente 5.
  Sugerencias tipo "detectar RCs idle y cerrarlas para bajar a 2-3" violan
  esta regla.

## WSGI — NO tocar gunicorn

- Oráculo usa **gunicorn + gevent** en `ecosystem.config.cjs`.
- **NO proponer** migrar a uvicorn, hypercorn, daphne ni cambiar el WSGI.
- Incidente 15 abril 2026: un cambio autónomo gunicorn→uvicorn causó
  crash loop 30 min post-reboot. Cerrado para siempre.

## PM2 restart — SOLO con nohup + sleep

- **NUNCA proponer** `pm2 restart <name>` ni `pm2 stop <name>` directo.
- Hay un hook (`hook-block-dangerous.py`) que los bloquea y alerta a
  Pablo por Telegram.
- Forma única permitida:
  `nohup bash -c 'sleep 3 && pm2 restart <name> --update-env' &`
- **NO proponer** crons ni mejoras que hagan `pm2 restart` directo
  (ej: "reinicio automático cada 24h"). El restart va siempre con el
  wrapper.

## Systemd vs PM2 — no mezclar

- PM2 es el ÚNICO gestor de oraculo, agent-runner, tutorai, etc.
- Systemd solo para infra (nginx, postgres, pm2-ubuntu, odoo, syncs).
- **NO proponer** crear `.service` systemd para procesos que PM2 maneja.
- **NO proponer** `sudo reboot` en scripts automáticos.

## Replit — en migración, no es dependencia

- **NO proponer** soluciones que dependan de Replit.
- Todo lo nuevo va a ARM. Los Replits existentes son legacy en
  migración (ver CLAUDE.md para la lista).
- ClaudeClaw es la única excepción (vive en ZIVON, no migrar).
- **Para tutorai específicamente**: Replit 100% descontinuado. Ni
  siquiera como backup. Pablo dijo textual (2026-04-20): "replit no
  lo quiero ni para backup. no lo uso mas en este proyecto entendes".

## Tareas MCP — legacy, 0 tareas/día es lo normal

- El sistema de `task_queue` y `task_history` es legacy v10/v11.
- Desde la migración a Claude Code CLI directo vía RC sessions (abril
  2026), Pablo trabaja SIN crear tareas MCP — usa Claude Code
  interactivo (tmux RC, desde Claude Desktop o dashboard).
- **Última tarea MCP: 2026-04-15**. Es esperado.
- **NO proponer** "alertar si 24h sin tareas" ni similar. Es el nuevo
  normal.
- Si el workflow cambia de vuelta (Pablo vuelve a crear tareas MCP),
  reconsiderar.

## Features ya implementadas — no proponer de nuevo

- **"Botón lanzar RC on-demand en cada card de proyecto"**: ✅ ya existe
  en la pestaña **Proyectos** del dashboard (`/dashboard#projects`) desde
  2026-04-19. Cada card tiene botón **▶ Prender RC** o **⏹ Apagar**
  según estado. **NO proponer de nuevo.**
- **"Pestaña RC ARM separada"**: rechazada por redundancia, unificada
  en Proyectos 2026-04-20. NO proponer.

## APIs externas — gratis primero, sin preguntar

- Cuando una feature necesite un API externo (noticias, datos,
  geocoding, etc), **SIEMPRE proponer/usar una opción gratuita
  primero** que no requiera tarjeta de crédito.
- **NO proponer** APIs pagas (NewsAPI paid tier, OpenAI pricing,
  etc) como primera opción.
- **NO proponer** "Pablo tiene que crear cuenta y obtener API key" —
  si la API requiere account, investigar alternativas que no lo
  requieran o resolver solo (Pablo no toca setup).
- Pablo dijo textual (2026-04-20): "api podes buscar alguna gratis y
  q puedas encargarte sola".

## Pasos manuales a Pablo — prohibidos

- **NO proponer** cualquier mejora que implique "Pablo tiene que entrar
  a X y tocar Y" (ni en terminal, ni en Replit, ni en Windows, ni en
  GitHub web UI, ni en ningún lugar).
- Toda mejora debe ser 100% automatizable desde ARM.

## Karpathy Loop auto-fix — está medio desactivado

- `karpathy_loop.py` tiene auto-fix tasks cuando success rate < 70% que
  fallan en loop y ensucian las métricas.
- **NO proponer** "agregar más auto-fix tasks" ni "bajar el threshold".
- Si proponés tocar el Karpathy Loop, tiene que ser para ARREGLAR el
  loop de fallos, no para ampliarlo.

## Modelos Claude — siempre el mejor Opus con 1M+

- Default = el Opus más capaz con contexto 1M+. Hoy es
  `claude-opus-4-7[1m]`.
- **NO proponer** bajar a Sonnet/Haiku "para ahorrar costos" — usamos
  OAuth Max ($0/token). El costo NO es un factor.

## Credenciales / PINs / secretos — NUNCA en CLAUDE.md ni archivos de git

**Incidente 2026-04-24:** el Karpathy detectó que Pablo pidió credenciales 2 veces ("me decis usuarios") y decidió guardarlas para no re-pedir. Las escribió **textual** en `servistecnicosRED/CLAUDE.md` (repo git): `user/Red24365*`, `admin/P@ssw0rd0216!`, PINs de Bruno/Gian/Marcos. Además duplicó la lección 3 veces en el mismo archivo. El repo es privado pero cualquier colaborador con acceso las veía.

**Regla dura:**
- **NUNCA escribir credenciales, passwords, PINs, tokens, API keys, private keys o secretos en un CLAUDE.md** ni en ningún archivo que entre a git.
- **Antes de escribir una lección con algún dato sensible**, verificar si el archivo destino está git-ignored: `git check-ignore <archivo>`. Si no lo está → NO escribir el secreto ahí.
- Patrón correcto: guardar el secreto en un archivo git-ignored (ej: `.secrets.md`, `.env`, `shared/secrets.md` chmod 600) y en el CLAUDE.md solo dejar la **referencia al path** ("credenciales en `.secrets.md`, leer de ahí").
- **NO proponer** "guardar credenciales en CLAUDE.md", "documentar passwords en docs/", ni variantes.

## Lecciones duplicadas — deduplicar antes de escribir

**Mismo incidente 2026-04-24:** la misma lección de credenciales apareció 3 veces en el mismo CLAUDE.md (del 2026-04-21, 22 y 24) con formatos distintos. El Karpathy no verificó si la lección ya existía.

**Regla:** antes de agregar una `[LECCION]` nueva a un CLAUDE.md de proyecto, `grep` por las keywords principales de la lección en el archivo destino. Si ya hay una lección similar (mismo tema, mismas keywords), **actualizar la existente** en vez de agregar una duplicada. No importa si es una fecha más nueva — la historia de fechas es menos importante que la cantidad de duplicación.

## Imágenes Mac→ARM — NO auto-leer al inicio de sesión

- El sync `/home/ubuntu/inbox/claude-images/` recibe capturas del Mac de
  Pablo. Pero Pablo captura también cosas para otros usos (WhatsApp,
  iMessage, otros proyectos). **No todas las imágenes son para Claude.**
- **NO proponer** hooks SessionStart que listen/lean imágenes sin leer
  automáticamente al arrancar sesión.
- **NO proponer** "alertar cuando hay imágenes nuevas hace >N min".
- Regla: Pablo avisa explícitamente ("mirá la imagen", "fijate la nueva",
  etc.) cuando quiere que las leas. Si no dice nada, no tocar el inbox.
