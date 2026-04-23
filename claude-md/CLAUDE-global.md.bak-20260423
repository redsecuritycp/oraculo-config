# CLAUDE.md — ARM (Global)

Este archivo se lee en TODOS los proyectos de ARM. Contiene lecciones aprendidas que aplican transversalmente.

## DIRECTIVAS COMPARTIDAS
Leer siempre:
- `/home/ubuntu/projects/shared/super-yo.md` — reglas universales de Pablo (onboarding completo, metodología, infraestructura, deploy)

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
- **crm.gruposer.com.ar** → CRM Grupo SER en ARM (161.153.207.224)
- DNS se maneja desde: micuenta.donweb.com → Nameservers y Zona DNS
- Para agregar subdominio: registro tipo A, nombre: subdominio, contenido: 161.153.207.224

### DuckDNS (proyectos sin dominio propio)
- **oraculo-pablo.duckdns.org** → Oráculo dashboard/MCP
- **tutorai.duckdns.org** → TutorAI
- Token: 034f876d-85db-46ca-8f88-44210863a398
- Max 5 subdominios gratis (2/5 usados)

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
