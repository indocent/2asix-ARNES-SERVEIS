---
description: Dona d'alta un client nou (directori web, server block NGINX, registre DNS i usuari FTP) i genera una contrasenya segura.
agent: sysadmin
---

Dona d'alta un client nou. El nom és `$ARGUMENTS` i s'usa alhora com a
subdomini i com a usuari virtual de FTP.

Passos:

1. Carrega l'entorn i comprova la connexió:

   ```bash
   set -a; . ./inventory.env; set +a
   source .opencode/lib/remote.sh
   arnes_check_connection
   ```

2. Valida el nom i comprova que no existeixi ja:

   ```bash
   client="$ARGUMENTS"
   arnes_validate_client_name "$client"
   remote "test -e $WEB_ROOT/$client && echo EXISTS || echo FREE"
   remote "mysql pureftpd -N -e \"SELECT COUNT(*) FROM users WHERE User='$client';\""
   ```

   Si ja existeix, atura't i informa'n l'usuari. No sobreescriguis res.

3. Crea el directori web amb els permisos correctes (skill `nginx`).

4. Crea el `server block` `/etc/nginx/sites-available/$client.conf`, enllaça'l
   a `sites-enabled/` i recarrega NGINX amb `nginx -t && systemctl reload nginx`
   (skill `nginx`).

5. Afegeix el registre DNS `<client> IN A $SERVER_IP` a la zona, incrementa el
   serial de la SOA, valida amb `named-checkzone` i recarrega amb
   `rndc reload $ZONE_BASE` (skill `bind9`).

6. Genera la contrasenya i el hash, i crea la fila FTP (skills `mysql` i
   `pureftpd`):

   ```bash
   pass="$(arnes_gen_password)"
   hash="$(arnes_hash_password "$pass")"
   remote "mysql pureftpd -e \"INSERT INTO users (User,Password,Uid,Gid,Dir,status) \
     VALUES ('$client','$hash',2001,2001,'$WEB_ROOT/$client/htdocs','active') \
     ON DUPLICATE KEY UPDATE Password=VALUES(Password), Dir=VALUES(Dir), status=VALUES(status);\""
   ```

7. Verifica el resultat:

   ```bash
   dig +short "$client.$ZONE_BASE" @"$SERVER_IP"
   curl -sI "http://$client.$ZONE_BASE"
   remote "mysql pureftpd -N -e \"SELECT User,status FROM users WHERE User='$client';\""
   ```

8. Registra l'operació amb `arnes_log "client-add" "$client" "ok"`.

9. Mostra la contrasenya generada **una sola vegada** i indica a l'usuari que
   la desi en un lloc segur. No l'escriguis a cap fitxer ni al log.
