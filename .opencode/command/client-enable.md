---
description: Torna a habilitar la web d'un client recreant l'enllaç d'NGINX, sense tocar les dades ni l'usuari FTP.
agent: sysadmin
---

Habilita la web del client `$ARGUMENTS`. Aquesta operació **no** esborra ni
modifica dades ni l'usuari FTP: només recrea l'enllaç d'NGINX.

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

   Si no hi ha `server block`, atura't i indica que cal fer `/client-add`.

3. Recrea l'enllaç i recarrega (skill `nginx`):

   ```bash
   remote "ln -sfn /etc/nginx/sites-available/$client.conf /etc/nginx/sites-enabled/$client.conf"
   remote "nginx -t && systemctl reload nginx"
   ```

4. Verifica i registra:

   ```bash
   curl -sI "http://$client.$ZONE_BASE"
   arnes_log "client-enable" "$client" "ok"
   ```
