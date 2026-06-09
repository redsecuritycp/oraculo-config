## PLAYBOOK: OpenVPN Connect v3 + router Ruijie (Mac)

Router Ruijie (y otros con template clásico de OpenVPN) generan `.ovpn` que el parser estricto de OpenVPN Connect v3 en macOS rechaza con `"Your connection configuration contains unsupported options"`.

### Flow completo:
1. `request_access` en una sola call: `["Finder", "org.openvpn.client.app"]`
2. Usuario sube el `.tar` con `etc/openvpn/{client.ovpn,ca.crt,ca.key}`
3. Extraer tar en sandbox, leer el `.ovpn`
4. Generar `.ovpn` limpio en `mnt/outputs/client_oc.ovpn` **sin las 7 directivas problemáticas**, preservando `<ca>`:
   - **Directivas a quitar:** `log <path>`, `status <path>`, `mute <n>`, `resolv-retry <value>`, `persist-key`, `route-delay <n>`, `explicit-exit-notify <n>`
   - **Directivas que se preservan:** `dev`, `nobind`, `proto`, `float`, `client`, `remote`, `verb`, `auth`, `auth-nocache`, `reneg-sec`, `remote-cert-tls`, `auth-user-pass`, `cipher`, `<ca>...</ca>`, `<cert>...</cert>`, `<key>...</key>`
5. Dar link `computer://` para que Pablo baje a Descargas
6. Doble-click al archivo desde Finder → OpenVPN Connect importa
7. En el editor del perfil:
   - Si el perfil solo tiene `<ca>` embebido (no `<cert>`/`<key>`) pero el servidor usa user/pass auth, OpenVPN Connect muestra `"Missing external certificate"` al conectar. **Fix:** desactivar el toggle `Require External Certificate`. No hace falta cargar nada más.
   - Cargar usuario/password (verificar con reveal del ojo, ver regla de credenciales).
8. **Save Changes** → **Connect**
9. Verificar por screenshot: `Securely Connected!` + timer + IP privada asignada + gráfico de tráfico.

