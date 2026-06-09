## WHATSAPP VIA BAILEYS — SALVAGUARDAS ANTI-BANEO META OBLIGATORIAS (2026-05-08) — HISTÓRICO (sustituido por wa-engine)

**TODO proyecto que conecte WhatsApp vía Baileys / whatsapp-web.js / wppconnect / cualquier integración no-oficial DEBE implementar las 6 salvaguardas anti-baneo + bug fixes + Telegram alerts + persistencia + silenciador libsignal.** Sin excepciones.

**Por qué la regla**: Pablo perdió 2+ números entre 5-6 mayo 2026 por QR loop infinito + IP datacenter + signaling continuo a Meta. Cada número perdido = lista de clientes en ese chat perdida + costo de mover a un número nuevo. La regla operativa de Pablo: **"ante la duda, pausar y proteger los números"**.

### Referencia canónica

- `servistecnicosRED/server/wa-client.ts` (TypeScript, multi-tenant) — implementación de referencia v77 (8 mayo 2026)
- `Marinaos/wa-bridge/server.js` (JS plano, single-tenant) — port equivalente

Cualquier proyecto WhatsApp **debe portar el mismo patrón**, adaptando lenguaje pero preservando comportamiento.

### Las 6 salvaguardas (todas obligatorias)

1. **QR timeout 30 min**: si entra estado `qr` y nadie escanea en 30 min → safetyStop, alerta Telegram, NO sigue generando QRs. Loop perpetuo de QR fue uno de los factores del baneo Marinaos 06/05.
2. **Flapping detector**: si > 3 `connection: open` en ventana de 1h → pausa + alerta. Reconexiones repetidas son señal pre-baneo.
3. **Cierres consecutivos sin open**: contador que sube en cada `close` y se resetea en `open`. Si llega a 3 → pausa + alerta. Indica Meta rechazando la sesión.
4. **Keywords sospechosas**: en `lastDisconnect.error.message`, regex `/\b(banned|blocked|forbidden|prohibited|403|405|account[\s-]?suspend)/i` o `statusCode === 403 || 405` → pausa inmediata.
5. **`loggedOut` sin auto-rebind**: cuando llega `DisconnectReason.loggedOut`, NO reabrir la sesión automáticamente (es signaling extra a Meta). Pausar + alerta. Pablo decide si reactivar (desvinculación legítima) o no (posible ban).
6. **Persistencia en disco**: cuando se pausa, escribir `<sessionDir>/.stopped` con `{ reason, at, lastError }`. Al boot del proceso, si existe el marker → cargar estado y NO arrancar el socket. Endpoint `POST /reactivate` que borra el marker y arranca de nuevo (con flag `wipe_auth=true` para casos `logged_out` que requieren credenciales nuevas).

### Bug fixes obligatorios (lección servistecnicos 2026-05-08)

- En `safetyStop`, **antes** de cerrar el socket: `sock.ev.removeAllListeners()`. Sin esto, Baileys sigue disparando events post-stop → más signaling a Meta justo cuando NO queremos.
- Al inicio del handler `connection.update`: `if (this.stopped || this.sock !== sock) return;`. Guard contra eventos rezagados de sockets viejos que ensucian el estado del socket nuevo.

### Notificaciones Telegram (failsafe)

- Token y chat_id: leer de `/home/ubuntu/.secrets/telegram-oraculo.env` (mismo bot que usa Oraculo). NO hardcodear en código ni en docs.
- URL endpoint: `https://api.telegram.org/bot<TOKEN>/sendMessage`
- **Failsafe**: si POST falla (red caída, token revocado), **NO crashear el bridge**. Solo loguear.
- Mensaje incluye: nombre proyecto, razón de pausa, número afectado, instrucción concreta para Pablo (qué reactivar / qué verificar primero).

### Silenciador libsignal (obligatorio)

`libsignal/src/session_record.js` hace `console.info("Closing session:", sessionGigante)` por cada cierre de sesión WA. Sin silenciar, los logs PM2 se llenan a varios MB/h. **Logrotate matando logs grandes mientras pm2 los tiene abiertos puede disparar respawn del daemon** (incidente servistecnicos 06:00 del 2026-05-08).

Solución: módulo `silence-libsignal` que se require **PRIMERO de todo, antes de cargar Baileys**, hace override de `console.info` para descartar mensajes que matchean `/^Closing session:/`.

### Endpoints HTTP obligatorios

- `POST /reactivate` — borra el `.stopped` marker, opcional `{ wipe_auth: true }` para wipe de credenciales (caso `logged_out`)
- `POST /manual-stop` — pausa preventiva manual con nota
- `GET /status` debe incluir: `stopped`, `stoppedReason`, `stoppedAt`, `lastError`, `flapping_open_count`, `consecutive_closes_without_open`

### pm2-logrotate (system-wide)

Aplicar en **TODO ARM** (no solo en proyectos WA), pero crítico para WA:

```bash
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 50M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true
pm2 set pm2-logrotate:rotateInterval '0 2 * * *'
```

### Anti-regresión (regla para Claude futuro)

- Cuando Pablo cree un proyecto nuevo con WhatsApp Baileys/web.js: **PRIMERA tarea** es portar las 6 salvaguardas. NO arrancar producción sin ellas.
- Si encontrás un proyecto WA que no tiene `silence-libsignal`, `.stopped` marker, o `removeAllListeners`: **deuda técnica crítica**, avisar a Pablo y portarlas.
- NUNCA conectar el WhatsApp **personal** de Pablo a Baileys/QR. Solo números descartables o de empresa.
- Si las salvaguardas mismas se rompen (caso real: bridge sin guard `if (stopped...) return;` que sigue disparando QRs post-stop), tratarlo como bug **P0** y arreglar inmediato.

### Lo que NO arregla esto

Las salvaguardas reducen el riesgo, **no lo eliminan**. Para campañas masivas o uso intensivo, el camino seguro sigue siendo **WhatsApp Cloud API oficial** (con plantillas pre-aprobadas) o **BSP (Wati / 360dialog)**. Baileys está OK para:
- Atención al cliente conversacional bajo volumen
- Bot de respuestas a clientes que ya iniciaron contacto
- Casos donde el costo de un ban ocasional es tolerable

**NO está OK** para:
- Mass marketing / broadcasts a contactos sin opt-in
- Volumen alto sostenido (>500 msg/día)
- Números de la línea principal del negocio

---

