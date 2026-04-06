# CLAUDE.md — claudeclaw

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
10. Después de cada cambio significativo a este archivo: cd /home/ubuntu/oraculo-config && git add -A && git commit -m "update CLAUDE.md claudeclaw" && git push origin main

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
{"timestamp":"ISO","proyecto":"claudeclaw","resumen":"qué se hizo","archivos_tocados":["lista"],"errores":[],"resultado":"éxito|fallo","duracion_minutos":N,"lecciones":["si hubo alguna"]}

---

## ROL
Sos ingeniero de software especializado en bots de mensajería y automatización.

## QUÉ ES CLAUDECLAW
Bot de WhatsApp/Telegram que corre SOLO en ZIVON como servicio PM2. Componente separado de Oraculo.

## STACK
Node.js en ZIVON (C:\Users\pansa\OneDrive\claudeclaw\)
WhatsApp: Baileys (SIM separada de Pablo personal — NO ve mensajes personales de Pablo)
Telegram: polling
API HTTP: puerto 3847 en ZIVON

## PM2 EN ZIVON
claudeclaw — bot principal
security-agent — monitoreo seguridad (procesos 60s, conexiones 120s, logins 300s, servicios 300s, firewall 600s, disco 1800s, archivos 1800s, antivirus 3600s)
client-monitor — monitoreo clientes remotos

## SECRETS
Servidor: https://claude-claw.replit.app/secrets (header X-Secret-Key)
Secrets: Telegram, Gemini, OpenAI, ElevenLabs, Groq, Tailscale

## SCHEDULER
Parser de scheduling reescrito abril 2026. Acepta español argentino natural:
"domingo 10 am", "mañana 8", "viernes 15hs", "lunes 8:30", "hoy 10", "en 30 minutos"
Si el parser no entiende, el modelo de IA procesa el mensaje y puede mandarlo al toque o alucinar datos.

## COOKIES REPLIT
refresh-replit-cookies.js: cada 45 min, liviano (fetch HTTP, <1s, ~30MB)
refresh-replit-session.js: fallback emergencia (Playwright, ~20s, ~200MB)
Si sesión muere: node replit-login.js en ZIVON con escritorio visible.

## GMAIL OAUTH
Tokens: google-calendar-tokens.json. Scopes: Calendar + Gmail.readonly + Gmail.modify
Si invalid_grant: node cli/calendar-auth.js en ZIVON via RDP (callback localhost:3851)

## DEPLOY
Script: node cli/deploy-repl-hybrid.cjs ClaudeClaw
Apunta al botón verde "✦ Republish" (y=92), NO al del header (y=6)
main.py DEBE tener load_dotenv('.env.local') al startup (Cloud Run no lee .env sin esto)

## TASK SCHEDULER EN ZIVON
PM2-ClaudeClaw: onlogon (startup)
RefreshReplitSession: cada 45 min (refresh-replit-cookies.js)
ReplitSSHCheck: 2:00 AM
ReplitSSHAlert: 7:00 AM
SecurityCheck: 7:30 AM
BackupDrive: cada 1h
OAuthRefresh: cada 2h

## CONTACTOS
Pablo, Marquitos, Gian, Gerencia, Mario Pansa, Ovidio (bot — BOTS_IGNORE)

## DATOS TÉCNICOS
PM2 watch deshabilitado (inestable con OneDrive)
conflict-check.js + .edits.json: previene ediciones simultáneas OneDrive (ventana 5 min)
Backup retention: 72 backups horarios (72h)
conversaciones.json: 50 msgs por usuario, 7 días retención, synced OneDrive
Heartbeat WhatsApp cada 5 minutos
Macro poll silenciado (BIEmpresas Replit caído, no crítico)
Security Agent whitelist: OpenWebUI, ReconnectMCP

## IMPORTANTE
ClaudeClaw corre en ZIVON, no en ARM. ARM NO puede SSH a ZIVON (no tiene Tailscale).
Para trabajar en ClaudeClaw desde Claude Code en ARM, avisarle a Pablo que use el zivon.bat.
