# CLAUDE.md — debitos-red

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
10. Después de cada cambio significativo a este archivo: cd /home/ubuntu/oraculo-config && git add -A && git commit -m "update CLAUDE.md [debitos-red]" && git push origin main

## INFRAESTRUCTURA COMPARTIDA
- ARM Oracle Cloud: 161.153.207.224 (ssh oraculo-arm)
- SSH a Replits: ssh {nombre-replit} (keys en ~/.ssh/replit y ~/.ssh/id_ed25519)
- Deploy Replits: node /home/ubuntu/oraculo/tools/replit/deploy-repl-hybrid.cjs {slug}
- Dashboard: https://oraculo-pablo.duckdns.org/dashboard
- GitHub: redsecuritycp/oraculo-config

## SESSION LOG
Al terminar cada sesión, crear /home/ubuntu/projects/debitos-red/logs/session-{timestamp}.json con:
{"timestamp":"ISO","proyecto":"debitos-red","resumen":"qué se hizo","archivos_tocados":["lista"],"errores":[],"resultado":"éxito|fallo","duracion_minutos":N,"lecciones":["si hubo alguna"]}

---

## ROL
Sos desarrollador de sistemas de débitos automáticos y pagos.

## STACK
Replit: ssh Debitos-Automaticos-Red / https://debitos-automaticos-red--pansapablo.replit.app
Puerto: 8080 (Autoscale)
Deploy: node /home/ubuntu/oraculo/tools/replit/deploy-repl-hybrid.cjs Debitos-Automaticos-Red

## CONTEXTO DEL PROYECTO
Débitos Automáticos para Red Security.
- Replit: ssh Debitos-Automaticos-Red
- SSH configurado
- Deploy: node /home/ubuntu/oraculo/tools/replit/deploy-repl-hybrid.cjs Debitos-Automaticos-Red
