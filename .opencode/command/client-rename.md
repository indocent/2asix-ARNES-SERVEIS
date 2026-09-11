---
description: Renombra un client de manera consistent (directori web, server block NGINX, registre DNS i usuari FTP), mantenint les dades.
agent: sysadmin
---

Renombra el client `$1` a `$2` de manera consistent, mantenint totes les dades.

Passos:

1. Carrega l'entorn i comprova la connexió:

   ```bash
   set -a; . ./inventory.env; set +a
   source .opencode/lib/remote.sh
   arnes_check_connection
   ```

2. Valida els dos noms i comprova l'estat:

   ```bash
   antic="$1"; nou="$2"
   arnes_validate_client_name "$antic"
   arnes_validate_client_name "$nou"
   remote "test -d $WEB_ROOT/$antic && echo OLD_OK || echo OLD_MISSING"
   remote "test -e $WEB_ROOT/$nou && echo NEW_EXISTS || echo NEW_FREE"
   ```

   Si el client antic no existeix o el nou ja existeix, atura't.

3. Atura temporalment la web per evitar accessos durant el canvi (opcional,
   però recomanat): deshabilita l'enllaç d'NGINX.

4. Renombra el directori web:

   ```bash
   remote "mv $WEB_ROOT/$antic $WEB_ROOT/$nou"
   ```

5. Renombra el `server block` i actualitza'n el `server_name` i el `root`
   (skill `nginx`), i recrea l'enllaç si estava habilitat:

   ```bash
   remote "if [ -f /etc/nginx/sites-available/$antic.conf ]; then \
     mv /etc/nginx/sites-available/$antic.conf /etc/nginx/sites-available/$nou.conf; \
     sed -i 's/$antic\\.$ZONE_BASE/$nou.$ZONE_BASE/g; s#$WEB_ROOT/$antic#$WEB_ROOT/$nou#g' /etc/nginx/sites-available/$nou.conf; \
     fi"
   remote "if [ -L /etc/nginx/sites-enabled/$antic.conf ]; then \
     rm -f /etc/nginx/sites-enabled/$antic.conf; \
     ln -sfn /etc/nginx/sites-available/$nou.conf /etc/nginx/sites-enabled/$nou.conf; fi"
   ```

6. Actualitza el registre DNS (skill `bind9`):

   ```bash
   remote "sed -i '/^$antic[[:space:]]\+IN[[:space:]]\+A/d' /etc/bind/zones/db.$ZONE_BASE"
   remote "echo '$nou IN A $SERVER_IP' >> /etc/bind/zones/db.$ZONE_BASE"
   ```

   Incrementa el serial de la SOA.

7. Actualitza l'usuari FTP a MySQL (skill `mysql`):

   ```bash
   remote "mysql pureftpd -e \"UPDATE users SET User='$nou', Dir='$WEB_ROOT/$nou/htdocs' WHERE User='$antic';\""
   ```

8. Recarrega els serveis i verifica:

   ```bash
   remote "nginx -t && systemctl reload nginx"
   remote "named-checkzone $ZONE_BASE /etc/bind/zones/db.$ZONE_BASE && rndc reload $ZONE_BASE"
   dig +short "$nou.$ZONE_BASE" @"$SERVER_IP"
   curl -sI "http://$nou.$ZONE_BASE"
   remote "mysql pureftpd -N -e \"SELECT User,Dir,status FROM users WHERE User='$nou';\""
   ```

9. Registra l'operació amb `arnes_log "client-rename" "$antic->$nou" "ok"`.
