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
10. Después de cada cambio significativo a este archivo: cd /home/ubuntu/oraculo-config && git add -A && git commit -m "update CLAUDE.md [oraculo]" && git push origin main

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
Sos ingeniero DevOps senior especializado en orquestación de sistemas.

## STACK
Python 3 / Flask / gunicorn + gevent / Nginx / PM2
Código: /home/ubuntu/oraculo/
Dashboard: https://oraculo-pablo.duckdns.org/dashboard
MCP: https://oraculo-pablo.duckdns.org/mcp/sse

## PM2
PM2 restart SIEMPRE con: nohup bash -c 'sleep 3 && pm2 restart oraculo --update-env' &
NUNCA restart directo sin delay.

## ARCHIVOS CLAVE
main.py — servidor Flask + MCP + dashboard
agent_worker.py — auto-scale workers
CLAUDE.md — este archivo (contexto para Claude Code executor)
task_queue.json — cola de tareas
task_history.json — historial
config.json — configuración

## CONTEXTO DEL PROYECTO
Oraculo es el sistema de orquestación autónomo de Pablo. Recibe tareas via MCP, las ejecuta con Claude Code CLI (OAuth Max, $0), reporta por dashboard + Telegram.
- Migración completa: v10 (7 agentes, $7/día) → v11 (1 Claude Code CLI, $0/día) — 1 abril 2026
- Pipeline anterior de 713 líneas reemplazado por 160 líneas
- Auto-scale: hasta 4 workers paralelos, psutil monitorea CPU/RAM
- Model routing: Opus para critical/high, Sonnet para medium/low
- Auto-retry: 3 intentos con error como contexto
- OAuth: autenticado una vez con claude auth login, permanente
- Karpathy Loop: corre cada hora, auto-repair si success rate < 70%
- Perfil cognitivo Pablo: 95% confianza, 1.3M entries, se regenera 3AM
- Success rate actual: ~60% — las auto-fix tasks fallan en loop (problema conocido)
- NUNCA hacer PM2 restart como parte de una tarea (mata workers)
- PM2 restart siempre con: nohup bash -c 'sleep 3 && pm2 restart oraculo --update-env' &

## LECCIONES HISTÓRICAS
- Guardian en v10 bloqueaba tareas legítimas — eliminado en v11
- QA en v10 repetía 4 veces el mismo error — reemplazado por auto-retry con contexto
- Operator en v10 no podía editar archivos — Claude Code tiene str_replace real
- Ngrok se caía periódicamente — reemplazado por DuckDNS + Nginx + Certbot en ARM
- Tailscale en Oracle Cloud rompió iptables — NUNCA instalar Tailscale en Oracle
- OCI CLI con instance-agent es el recovery más confiable cuando SSH se bloquea
- client_max_body_size 50M en nginx desbloqueó sync de captadores (perfil cognitivo subió a 95%)
