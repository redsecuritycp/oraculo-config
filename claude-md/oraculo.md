# CLAUDE.md — oraculo

## QUIÉN SOS
Trabajás para Pablo Pansa (Grupo SER, San Jorge, Argentina). Pablo NO toca código, terminal, ni deploy. Vos hacés todo.

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
- Dashboard: https://oraculo-pablo.duckdns.org/dashboard
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
Dashboard: https://oraculo-pablo.duckdns.org/dashboard
MCP: https://oraculo-pablo.duckdns.org/mcp/sse (Streamable HTTP + SSE legacy)
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
Claude Code CLI con OAuth Max ($0/token). Modelo: Opus 4.6 para TODO (sin Sonnet).
Invocación: ANTHROPIC_API_KEY='' claude -p "prompt" --no-input --model claude-opus-4-6 --output-format json --max-turns 10 --allowedTools Bash Read Write Edit Glob Grep
Auto-retry: 3 intentos con error como contexto.

## AUTO-SCALE WORKERS
- Mínimo 0, máximo 4 workers paralelos (slot 5 reservado para Pablo)
- psutil monitorea CPU/RAM, no spawnea si >80%
- File locking con fcntl para task_queue.json
- OAuth tiene límite ~5 sesiones concurrentes

## PM2
SIEMPRE con delay: nohup bash -c 'sleep 3 && pm2 restart oraculo --update-env' &
NUNCA restart directo. NUNCA restart como parte de una tarea de Oraculo.

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
Telegram @Matrixoraculobot. Token: 8265889890:AAHyHmXsVg5NN-ffgSeFIDCC5U-PfC5UYZ0. CHAT_ID: 989844970.
Anti-spam: 60 min por tipo. Solo: tarea completada/fallida, emergencia seguridad.

## CRONS
Cada hora: Karpathy Loop (optimización + auto-repair si success rate < 70%)
3AM: Profile Builder (perfil cognitivo)
30min: DuckDNS (actualiza IP)
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

## WATCHDOG
Mini PC Oracle VM Micro (144.22.61.213, 1 OCPU, 1GB RAM). Chequea ARM cada 2 min. Alerta por Telegram si cae.

## UPTIMEROBOT
API: u3060284-31d38a9c7ffbd1e3a17a70e9. Monitorea https://oraculo-pablo.duckdns.org/status

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

## CONTEXTO OPERATIVO
### Telegram
Mandar archivo: curl -s -X POST "https://api.telegram.org/bot8265889890:AAHyHmXsVg5NN-ffgSeFIDCC5U-PfC5UYZ0/sendDocument" -F chat_id=989844970 -F document=@/ruta/archivo -F caption="descripción"
Mandar mensaje: curl -s -X POST "https://api.telegram.org/bot8265889890:AAHyHmXsVg5NN-ffgSeFIDCC5U-PfC5UYZ0/sendMessage" -d chat_id=989844970 -d text="mensaje"

### Archivos .bat para Pablo
Ubicación: /home/ubuntu/projects/bat-files/. Siempre con CRLF. Después de crear/modificar, mandar por Telegram.

### Replits
Crear: node /home/ubuntu/oraculo/tools/replit/create-repl.js NombreRepl python|node
Deploy: node /home/ubuntu/oraculo/tools/replit/deploy-repl-hybrid.cjs SlugReplit (ÚNICO que funciona)
SSH: ssh NombreReplit. Config: Autoscale, 1 vCPU, 0.5 GiB RAM, puerto 8080, Public.
Cookies: refresh cada 45 min. Si expiran: node replit-login.js.
Replits activos: TutorAI, ClaudeClaw, Oraculo, ISR-web, Ovidio-botvendedor, Dania-whattsapp-captador-de-lead, Cianbox-Propio, Debitos-Automaticos-Red, seragro-github, Vendetta, PHP-Web-Ceiepar

### GitHub
Repo: redsecuritycp/oraculo-config. Auth: PAT classic. Push: cd /home/ubuntu/oraculo-config && git add -A && git commit -m "msg" && git push origin main.

### Máquinas
ARM (161.153.207.224): TODO acá. ssh oraculo-arm. 4 OCPU, 24GB RAM. Gratis.
ZIVON (100.80.5.31): Solo ClaudeClaw. ssh zivon. ARM NO puede SSH a ZIVON.
Asus (100.75.139.49): Notebook Pablo. ARM NO puede SSH a Asus.
Mini PC (144.22.61.213): Watchdog.

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
