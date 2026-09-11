---
description: Deshabilita la web d'un client esborrant només l'enllaç d'NGINX, sense tocar les dades ni l'usuari FTP.
agent: sysadmin
---

Deshabilita la web del client `$ARGUMENTS`. Aquesta operació **no** esborra el
directori web, ni el `server block`, ni l'usuari FTP: només elimina l'enllaç
actiu d'NGINX.

Passos:

1. Carrega l'entorn i comprova la connexió:

   ```bash
   set -a; . ./inventory.env; set +a
   source .opencode/lib/remote.sh
   arnes_check_connection
   ```

2. Valida el nom i comprova que el client existeixi:

   ```bash
   client="$ARGUMENTS"
   arnes_validate_client_name "$client"
   remote "test -f /etc/nginx/sites-available/$client.conf && echo OK || echo MISSING"
   ```

3. Esborra només l'enllaç i recarrega (skill `nginx`):

   ```bash
   remote "rm -f /etc/nginx/sites-enabled/$client.conf"
   remote "nginx -t && systemctl reload nginx"
   ```

4. Verifica que ja no respon i registra:

   ```bash
   remote "test -L /etc/nginx/sites-enabled/$client.conf && echo STILL_ENABLED || echo DISABLED"
   arnes_log "client-disable" "$client" "ok"
   ```
