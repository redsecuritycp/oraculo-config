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
- **TAMPOCO PROPONER** "RC on-demand para los N proyectos sin RC cuando
  el dashboard detecta actividad" ni "auto-spawn RC al detectar logs
  recientes" — todas violan el techo de 5. Karpathy 2026-05-01 propuso
  esta variante a pesar de la regla; queda explícitamente prohibida.

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

## Alertas Telegram repetitivas — rate-limit obligatorio

**Incidente 2026-04-29:** `self-heal.sh` detectó zombi de RC oraculo por OAuth 403 cada 2 min y mandó la MISMA alerta `🔐 RCs caídas por auth 403` 5 veces seguidas (22:04 → 22:08) sin deduplicar. Pablo lo describió textual: "con una vez estaria. luego me avisas si lo solucionas. sino por ende sé q no se arreglo".

**Regla dura:**
- **CUALQUIER notify de Telegram que pueda dispararse en loop (cron, watchdog, self-heal)** debe tener cooldown por causa+target (típicamente 1h) — implementado con flag file: `/tmp/<scope>-<causa>-<slug>.flag` + check de `stat -c %Y` antes de mandar.
- **Cuando la causa se resuelve** (ej: el target vuelve a estar sano), mandar UNA notify de "✅ recuperado" y borrar el flag.
- **NO proponer** alertas que se mandan cada N min sin cooldown ni notify de "aún caído" recurrentes. Pablo asume que silencio = todavía roto, ruido = nuevo problema.

## RCs idle — NO preguntar si cerrarlas

**Pablo 2026-05-02:** "es inchabola si no lo quiero activo yo mismo pediria
apagarlo, si no lo pido es por quiero q estena andando, no quiero de
ninguno q m joda pero si q anden". El cron `rc-idle-sweep.sh` que
mandaba Telegram con botones "🔴 Cerrar / ✅ Mantener" cada vez que una
RC pasaba 4h sin actividad fue eliminado.

**NO proponer:**
- "Avisar por Telegram cuando RC X lleva N horas idle" (en cualquier framing).
- "Botón inline para cerrar RC desde el celu cuando se detecta idle".
- "Cron de cleanup de RCs no usadas".
- Variantes con notificación + acción del usuario sobre RCs idle.

**SÍ está OK proponer:**
- Auto-revive silencioso de RCs caídas (claude muerto, cloud worktree
  colgado en loop). Notify SOLO si el auto-revive falla.
- Detectores de fallo (auth 403, OOM, loop reconexión) que kill+restart
  sin pedir input al usuario.

## Imágenes Mac→ARM — NO auto-leer al inicio de sesión

- El sync `/home/ubuntu/inbox/claude-images/` recibe capturas del Mac de
  Pablo. Pero Pablo captura también cosas para otros usos (WhatsApp,
  iMessage, otros proyectos). **No todas las imágenes son para Claude.**
- **NO proponer** hooks SessionStart que listen/lean imágenes sin leer
  automáticamente al arrancar sesión.
- **NO proponer** "alertar cuando hay imágenes nuevas hace >N min".
- Regla: Pablo avisa explícitamente ("mirá la imagen", "fijate la nueva",
  etc.) cuando quiere que las leas. Si no dice nada, no tocar el inbox.

## Migraciones masivas Cianbox/Odoo (>1k registros)

- ANTES de full run: validar con muestra `--limit 10 --dry-run`. Si `count_created == 0`, NO seguir.
- Si `failed/processed > 50%` después de 100 registros → ABORTAR (los scripts deben tener auto-abort built-in).
- Si TODOS los fallos tienen el mismo síntoma → bug estructural en builder, NO seguir esperando.
- NO re-lanzar migración sin alinear external_id mapping (`CIAN_P:{id}` en `sale.order.client_order_ref`).
- Caso real (02/05/2026): `migrate_pedidos.py` corrió 84min sobre 54.441 registros con 100% de fallo.
  Estos protocolos previenen ese desperdicio.

## Anti-mentira migración (REGLA 9 super-yo) — agregado 2026-05-21

- **PROHIBIDO** sugerir mejoras al daily-improvements que digan "migrado al N%", "proyecto X listo para apagar el origen", "migration done", sin que la mejora misma traiga el output completo de `bash /home/ubuntu/projects/oraculo/tools/audit-migration.sh <proyecto>`.
- Si Karpathy detecta en transcripts a un agente declarando "migrado/al N%/listo" sin tabla de audit pegada → marcar como **incidente** y proponer fix de proceso, NO felicitar.
- Tabla obligatoria mínima: `tabla | origen | destino | gap | status` con todas las filas. Status `OK`, `PARCIAL`, `FALTA`, `N/A`.
- Status `PARCIAL` o `FALTA` o `N/A` = migración INCOMPLETA. NO apagar origen.
- Audit per-proyecto vive en `/home/ubuntu/projects/oraculo/tools/audits/<proyecto>.sh`. Si no existe → "audit pendiente, no afirmar estado".
- Por qué: Pablo descubrió 2026-05-21 que isr-web-vue3 reportaba 90-100% siendo que faltaba migrar miles de usuarios externos + todo MongoDB legacy + adjuntos. Tercera vez (TutorAI abril, servistecnicosRED mayo).
