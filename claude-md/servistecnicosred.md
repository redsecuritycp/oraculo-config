# CLAUDE.md — servistecnicosred

## QUIÉN SOS
Trabajás para Pablo Pansa (Grupo SER, San Jorge, Argentina). Pablo NO toca código, terminal, ni deploy. Vos hacés todo.

## ARM ES INDEPENDIENTE
ARM no depende de ZIVON. Todo se ejecuta y resuelve en ARM. ZIVON solo existe para ClaudeClaw.

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
10. Después de cada cambio significativo a este archivo: cd /home/ubuntu/oraculo-config && git add -A && git commit -m "update CLAUDE.md servistecnicosred" && git push origin main

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
{"timestamp":"ISO","proyecto":"servistecnicosred","resumen":"qué se hizo","archivos_tocados":["lista"],"errores":[],"resultado":"éxito|fallo","duracion_minutos":N,"lecciones":["si hubo alguna"]}

---

## ROL
Sos desarrollador web full-stack especializado en TypeScript (React + Express + PostgreSQL).

## QUÉ ES SERVISTECNICOSRED
Sistema de gestión de servicios técnicos para Red Security (empresa de seguridad de alarmas de Gian). Permite:
- Crear y hacer seguimiento de solicitudes de servicio de alarmas
- Asignar técnicos (Gian y Gustavo) de forma inteligente con coordinación automática
- Priorizar servicios por urgencia (alta, media, baja, blanco)
- Gestionar calendario de técnicos con horarios laborales (8:00-12:00 y 15:00-19:00, lunes a viernes)
- Sistema de notificaciones con sonido a las 17:30h
- Reportes técnicos completos para facturación
- Archivo de servicios facturados
- Coordinación automática: lunes-jueves 14:30hs para el día siguiente, domingo 16:30hs para lunes

## STACK
- **Frontend**: React (TypeScript), Radix UI (shadcn/ui), Tailwind CSS, TanStack Query, Wouter (routing), React Hook Form + Zod (validación)
- **Backend**: Node.js, Express.js (TypeScript), tsx (dev server)
- **Base de datos**: PostgreSQL (Neon serverless), Drizzle ORM
- **Build**: Vite (frontend), esbuild (backend)
- **Runtime**: Node.js 20

## INFRAESTRUCTURA
- Replit: ssh servistecnicosRED
- URL: https://servistecnicosred--pansapablo.replit.app (nota: devuelve 404, verificar si está deployado)
- Puerto: 5000 (dev) / 80 externo (Autoscale)
- Deploy: node /home/ubuntu/oraculo/tools/replit/deploy-repl-hybrid.cjs servistecnicosRED
- Si el deploy falla: ver instrucciones en /home/ubuntu/projects/oraculo/CLAUDE.md sección Deploy.
- SSH verificado OK desde ARM

## CONTEXTO
- Pertenece a Red Security (empresa de Gian)
- Gian: Tailscale IP 100.68.170.42, SSH roto (fix-ssh-gian.bat listo, Pablo ejecuta en persona)
- Red Security es empresa cliente en Oraculo (instancias/red-security/)
- Instalador cliente: https://oraculo-pablo.duckdns.org/empresa/red-security/setup

## ARCHIVOS CLAVE
- server/index.ts — Entry point, Express app, coordinación automática
- server/routes.ts — API routes
- server/storage.ts — Data access layer
- server/coordination.ts — Algoritmo de coordinación automática de técnicos
- server/coordinator-watchdog.ts — Watchdog de coordinación
- server/notification-scheduler.ts — Scheduler de notificaciones (17:30h)
- server/priority-restore-scheduler.ts — Restauración automática de prioridad blanco
- shared/schema.ts — Schema de DB (Drizzle + Zod)
- client/src/ — Frontend React
- drizzle.config.ts — Config de Drizzle ORM
- vite.config.ts — Config de Vite

## REGLAS CRÍTICAS DEL NEGOCIO
- NUNCA inventar o modificar datos de usuario — solo mostrar datos reales de la DB
- Técnicos: solo Gian y Gustavo (Marcos fue eliminado)
- Gian NO está disponible por defecto, solo Gustavo
- Horario laboral: 8:00-12:00 y 15:00-19:00, lunes a viernes. No fines de semana
- Formato de hora: usar "h" (14:30h), no "hs". Timezone Argentina
- Notificaciones: incluir solo info esencial del cliente (localidad, problema, descripción, tipo alarma, dirección, nombre/apellido con número de cliente)
