# Constraints duras para el análisis del Karpathy

Este archivo se inyecta al prompt del `daily-improvements.sh` (y cualquier
otro Karpathy) antes de pedirle sugerencias. El objetivo es que nunca más
proponga mejoras que violen reglas explícitas de Pablo o que vayan contra
decisiones ya tomadas.

**Regla del workflow:** cuando Pablo define una regla dura nueva en una
conversación, agregala acá en la misma sesión. Si no, el Karpathy la va a
volver a proponer al día siguiente y es ruido.

---

## ⛔ Fable 5 / Mythos dados de baja (regla 2026-06-16)

Anthropic discontinuó **Claude Fable 5** (export control, sin fecha de vuelta).
Karpathy NUNCA debe proponer setear ni volver a `claude-fable-5` / `claude-mythos-*`
en ningún settings.json, script, hook o RC. Default vigente: **`claude-opus-4-8[1m]`**
en `model` Y en `fallbackModel` (Pablo NO quiere downgrade: el fallback también es 4.8;
nada de 4.7/4.6). Aplica a CC interactivo + `dispatch_to_rc`. `trading` mantiene su mix
propio (opus-4-8 / sonnet-4-6 / haiku-4-5). Si un transcript o settings re-introduce
fable → marcar incidente, no proponer mejora que lo use.

---

## Rate limiting Anthropic — RCs simultáneas

- **MÁXIMO 5 sesiones RC (`tmux rc-*`) simultáneas** (regla Pablo
  2026-04-22, subida desde 3). El guard está en `rc-manager.sh start`.
- Las RCs always-on salen de `desired-rcs.txt` persistente (manager.sh start/stop lo mantienen, sobrevive reboot). rc-oraculo siempre garantizado. NO proponer volver a whitelist hardcodeado.
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

---

## Pre-Mortem obligatorio antes de cambio productivo (regla 2026-05-22)

- Antes de ejecutar `deploy-arm.sh`, `rollback-arm.sh`, `nginx -s reload` en dominio público, `pm2 restart` proceso productivo, `git push origin main` en proyecto productivo, `certbot --force-renewal`, switch DNS público, bump versión mayor, apagar/borrar recurso productivo, migración entera → asistente DEBE invocar `Skill pre-mortem` con tabla escenarios + mitigación PRE + rollback.
- Karpathy lee transcripts diarios. Si encuentra ejecución de cualquiera de esos comandos SIN invocación de skill pre-mortem en los 30 min previos del mismo transcript → marcar incidente y proponer mejora al description de la skill (más triggers, keywords nuevas).
- **NO proponer al usuario** "instalar más skills tipo TDAH executive function" / "agregar más prompts marketinizados" — Pablo NO ejecuta tareas manuales, las skills tipo "menú dopamina para humano" no aplican. Solo skills que asistan al asistente (descomposición de plan, validación, rollback) son válidas.
- **NO proponer** hooks bloqueantes nuevos sin pre-mortem propio del hook — el último incidente con hook bloqueante fue `git mv tools/hook-*.py` 2026-05-14 (bloqueo 30min). Hooks productivos solo informativos por default; bloqueantes solo con rollback testeado.
- REGLA DURA (2026-06-10, incidente fotos servistecnicosRED): todo dir donde una app escribe en runtime (uploads/media/archivos de usuarios) DEBE vivir en deployments/<proj>/shared/ con symlink desde el release — NUNCA dentro del release (el deploy lo pisa). Detector: tools/audit-runtime-writes.sh (check rtwrites en pulse).

---

## Disciplina de agente — patrones frontier (regla 2026-06-14, leak system prompt Fable 5)

Cinco patrones adoptados del system prompt de modelos frontier. Karpathy NO debe proponer mejoras que los contradigan, y SÍ debe marcar incidente cuando un transcript los viole.

1. **Memoria SIN atribución.** Prohibido que el asistente (y sobre todo el Clon Digital / bots de usuario) diga "veo que…", "noto que…", "según lo que sé de vos", "basándome en tus datos/memorias/perfil", "recuerdo que…". La memoria se usa como conocimiento propio, no se cita. Karpathy marca incidente si detecta esas frases en transcripts.
2. **Entidad no reconocida → BUSCAR, no inventar (NO NEGOCIABLE).** Si el agente opina sobre un producto/tool/modelo/versión/persona desconocido SIN un WebSearch/WebFetch previo en el mismo transcript → incidente. Refuerza regla de oro 18.
3. **Aplicación selectiva de memoria.** Cero contexto en preguntas genéricas; personalización completa solo cuando es genuinamente personal. No proponer inyectar más contexto "por las dudas".
4. **Ruteo de tools sin narrar.** El agente elige tool y produce; NO narra "voy a usar X porque…". Karpathy NO debe proponer mejoras que agreguen narración de proceso bajo el ancla ▼ RESPUESTA ▼.
5. **Escalar tool-calls a complejidad.** 1 (dato simple) / 3-5 (medio) / 5-15 (research) / 20+ → fan-out (Workflow/deep-research). No spamear calls seriales.

Fuente de verdad: sección "DISCIPLINA DE AGENTE" en super-yo.md + super-yo-essential.md (inyectado por hook cada sesión).

## AVANZÁ POR DEFAULT / LOOP AUTÓNOMO (Pablo 2026-06-19, regla dura; reforzado 2026-06-23)
Con directiva ya dada, el RC ejecuta de punta a punta SIN frenar a re-preguntar. PROHIBIDO "¿avanzo?/¿sigo?/¿continúo?/¿querés que…?/¿lo hago?" mid-tarea. Solo pausa por: credencial externa real faltante, o decisión genuina de Pablo (qué RC apagar, destructivo irreversible, gasto grande Opus). Aplica a TODOS los RC (inject-super-yo.sh SessionStart). dispatch.sh inyecta la regla en CADA prompt dispatched (fix 2026-06-23). NO generar mejoras que contradigan esto.

**Karpathy: detectar violaciones en transcripts.** Si un RC devuelve "¿avanzo?/¿querés que siga?/¿continúo?/¿te parece que...?" dentro de una tarea ya ordenada → INCIDENTE `[INCIDENTE-FRENO]`. Distinguir causas:
- API 500/529 (Anthropic): NO es incidente del RC → registrar como "API outage".
- Session limit Max plan ("You've hit your session limit"): NO es incidente del RC → "session-limit hit".
- RC pausó innecesariamente o esperó input que podía obtener solo: SÍ → `[INCIDENTE-FRENO]`.

## NO FALSOS POSITIVOS — CORROBORAR ANTES DE ALERTAR (Pablo 2026-06-20, regla dura)
"estoy cansado de mensajes basura. antes q me llegue mensajes falsos los corroboren."
Todo crit que dependa de una condición re-verificable DEBE corroborarse ANTES de
mandar: re-correr el chequeo N veces; si en algún reintento está sano → suprimir.
Capa estándar: `modules/alert-gate/gate.sh`. health_check.py ya exige recheck inline
o 2 lecturas malas consecutivas. NUNCA proponer mejoras que manden alertas en la
primera lectura mala sin corroboración. Un timeout/301/pico transitorio NO es caída.

## ENV GLOBAL DEL MOTOR DE IA = PRE-MORTEM + PRUEBA EN SECO (Pablo 2026-06-26, regla dura)
Incidente fcc-proxy 26/06: instalar el proxy dejó `ANTHROPIC_BASE_URL` en el env
global → los 4 RCs + executor + subagentes pasaron por el proxy (token propio, 401)
→ caída total. Pre-mortem NO se disparó porque sus triggers eran sintácticos
(comandos conocidos) y "instalar proxy + export env global" no matcheaba.
Fix aplicado: pre-mortem ahora trigger DURO ante cualquier cambio a
`ANTHROPIC_BASE_URL`/`ANTHROPIC_API_KEY`/`ANTHROPIC_AUTH_TOKEN`/`CLAUDE_CODE_*`,
`settings.json`/`managed-settings.json` del motor, env en `.bashrc`/`.profile`
heredada por todos los RCs, o poner un proxy/gateway delante del motor.
Regla operativa: **el env global del motor se prueba en SECO/AISLADO** (un solo
shell, sin exportar global) y solo se aplica detrás de pre-mortem completo con
rollback <5s (`unset` + quitar línea de settings.json/.bashrc/.profile + restart
agent-runner). Karpathy: NUNCA proponer mejoras que exporten env del motor global
sin pre-mortem ni prueba aislada; tratar cualquier sugerencia de proxy/gateway IA
global como blast-radius máximo.

## SIMETRÍA ARM↔HETZNER (Pablo 2026-06-26, regla dura)
"si arreglas uno arregla el otro siempre, no podemos ser idiotas asi." Hetzner es backup hot de ARM.
Todo cambio de infra/failover/proxy/modelo LLM se aplica en AMBAS en el mismo turno. Failover de cuota
canónico: freecc:8099 (remapea claude→gpt-5.5) → auth2api:8317 (OpenAI OAuth $0), idle hasta que
quota-watchdog lo active. Karpathy: NUNCA proponer config de failover/proxy que aplique a una sola máquina.
