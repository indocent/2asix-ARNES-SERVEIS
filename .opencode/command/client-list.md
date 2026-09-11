---
description: Llista els clients amb el seu estat web (NGINX), estat FTP i ruta del directori.
agent: sysadmin
---

Llista tots els clients del servidor amb el seu estat.

Passos:

1. Carrega l'entorn i comprova la connexió:

   ```bash
   set -a; . ./inventory.env; set +a
   source .opencode/lib/remote.sh
   arnes_check_connection
   ```

2. Obtén la llista de clients a partir dels directoris de `$WEB_ROOT`:

   ```bash
   remote "find $WEB_ROOT -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort"
   ```

3. Obtén l'estat FTP de cada client:

   ```bash
   remote "mysql pureftpd -N -e \"SELECT User, status FROM users ORDER BY User;\""
   ```

4. Comprova si el `server block` està habilitat:

   ```bash
   remote "ls -1 /etc/nginx/sites-enabled/ 2>/dev/null"
   ```

5. Presenta una taula amb: **client**, **web** (`enabled`/`disabled`),
   **ftp** (`active`/`disabled`/`absent`) i **ruta**
   (`$WEB_ROOT/<client>/htdocs`).

6. Si `$ARGUMENTS` indica un client concret, mostra'n només el detall.
