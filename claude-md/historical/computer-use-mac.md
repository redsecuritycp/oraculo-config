## COMPUTER-USE MCP (Mac de Pablo) — lecciones 2026-04-23

Esta sección aplica cuando trabajás con Pablo desde una instancia Claude que tiene **computer-use MCP** habilitado sobre su MacBook (típicamente claude.ai Desktop/web, NO desde RCs de ARM que no tienen computer-use). Reglas para evitar repetir errores ya vividos.

### `request_access` — batchear al inicio, NUNCA a mitad de tarea
- Pedí **TODAS las apps que vas a necesitar** en UN solo `request_access` al arrancar.
- Cada call de `request_access` a mitad de tarea tiene alto riesgo de timeout de 60s o de perder los grants anteriores.
- Aprobar UN diálogo con 5 apps es igual de rápido que aprobar 1.
- **Batch típico para tareas Mac:** `["Finder", "<bundle ID de la app>", "com.microsoft.edgemac", "com.google.Chrome", "com.apple.Safari"]`.

### `request_access` — el diálogo aparece en el display con focus, NO en el Mac físico
- Si Pablo está controlando el Mac desde otro dispositivo (iPhone Mirroring, Jump Desktop, TeamViewer), el diálogo sale en el display remoto (celu), no en las pantallas físicas del Mac.
- **Síntoma:** timeouts consecutivos de `request_access` aunque el bundle ID sea válido.
- **Mitigación:** si falla 2+ veces seguidas, preguntar *"¿estás controlando el Mac desde otro dispositivo? Si sí, enfocá el Mac físico y reintento"*.

### Centro de Control / Configuración del Sistema — NO granted
- `request_access` NO acepta "Centro de Control", "Configuración del Sistema", "Ajustes del Sistema" ni sus bundle IDs (`com.apple.controlcenter`, `com.apple.systempreferences`).
- **Implicancia:** cualquier cosa que viva en Preferencias del Sistema (Focus/No Molestar, Notificaciones, Red, etc.) NO se puede automatizar desde computer-use → handoff al usuario con instrucciones exactas de 3-5 clicks.

---

