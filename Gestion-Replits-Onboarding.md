# Gestión de Replits — Guía de Onboarding

## Deploy de Replits

Para deployar/republish cualquier Replit después de cambios de código:

```bash
node cli/deploy-repl-hybrid.cjs <nombre-repl>
```

### Ejemplos

```bash
node cli/deploy-repl-hybrid.cjs ISR-web
node cli/deploy-repl-hybrid.cjs Ovidio-botvendedor
node cli/deploy-repl-hybrid.cjs ClaudeClaw
```

### Slugs

El nombre del Repl es el slug de Replit. Los underscores se quitan automáticamente.

| Nombre real | Slug para deploy |
|---|---|
| Ovidio-bot_vendedor | Ovidio-botvendedor |
| ISR-WEB | ISR-web |
| CianboxPropio | Cianbox-Propio |
| ClaudeClaw | ClaudeClaw |

### Cómo funciona deploy-repl-hybrid.cjs

1. Abre Playwright con persistent context y cookies de sesión Replit
2. Navega a `https://replit.com/@pansapablo/<slug>`
3. **Intercepta responses GraphQL** de Replit automáticamente
4. Extrae `hostingDeployment.id` de la response de `getRepl`
5. Envía la mutation `DeploymentSessionDeployBuild` directamente via GraphQL
6. **NUNCA clickea botones de deploy** — todo es via API GraphQL desde dentro del browser

### Reglas

- **SOLO usar `deploy-repl-hybrid.cjs`** — es el único método que funciona.
- NUNCA decir "deploy manual" ni "Pablo debe hacer Republish".
- NUNCA usar `deployRepl()` de `replit-manager.js` — está roto.
- NUNCA usar `deploy-repl.cjs` — tampoco funciona.
- Si falla, reportar el error exacto — NO sugerir deploy manual.

## Crear Replits

Dos formas:
- **WhatsApp/Telegram**: `crear replit NombreProyecto` → crea Repl + configura SSH + responde con URL
- **CLI**: `node create-repl.js NombreProyecto` (modo visual, headless: false)

Ambas usan `replit-manager.js` como módulo compartido.

## Control de ciclo de vida

| Acción | Método | Comando |
|---|---|---|
| Crear | Playwright | `node create-repl.js NombreProyecto` |
| Deploy/Republish | GraphQL (hybrid) | `node cli/deploy-repl-hybrid.cjs <slug>` |
| Reiniciar proceso | SSH | `restartRepl(replName)` |
| Detener proceso | SSH | `stopRepl(replName)` |
| Iniciar proceso | SSH | `runRepl(replName)` |
| Eliminar | Playwright | `deleteRepl(replName)` (requiere confirmación) |

- **Playwright** se usa SOLO para: crear Repls nuevos, eliminar Repls.
- **SSH** se usa para: stop/run/restart de procesos dentro de un Repl.
- **GraphQL (hybrid)** se usa para: deploy/republish.

## Comandos por WhatsApp/Telegram

- `crear replit NombreProyecto`
- `reiniciar replit NombreProyecto`
- `detener replit NombreProyecto`
- `iniciar replit NombreProyecto`
- `eliminar replit NombreProyecto` (pide confirmación)

## Archivos clave

| Archivo | Función |
|---|---|
| `cli/deploy-repl-hybrid.cjs` | Deploy via GraphQL (el único que funciona) |
| `replit-manager.js` | Crear/controlar/eliminar Repls + SSH config |
| `create-repl.js` | CLI wrapper para crear Repls |
| `check-replit-ssh.js` | Verifica SSH config (corre 2AM) |
| `refresh-replit-session.js` | Renueva cookies Replit (corre 1AM) |

## Sesión de Replit

- Las cookies se guardan en `.claudeclaw/local/replit-session.json`
- Se renuevan automáticamente a la 1AM via Task Scheduler
- El browser data persistente está en `.claudeclaw/local/browser-data/`
- Si las cookies expiran, `deploy-repl-hybrid.cjs` falla con 403 — ejecutar `refresh-replit-session.js` manualmente
