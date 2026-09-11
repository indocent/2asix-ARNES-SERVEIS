---
description: Esborra un client fent una còpia de seguretat prèvia obligatòria de la web, la configuració i les dades FTP.
agent: sysadmin
---

Esborra el client `$ARGUMENTS` del sistema. **És una operació destructiva:** cal
una còpia de seguretat prèvia obligatòria i confirmació explícita de l'usuari.

Passos:

1. Carrega l'entorn i comprova la connexió:

   ```bash
   set -a; . ./inventory.env; set +a
   source .opencode/lib/remote.sh
   arnes_check_connection
   ```

2. Valida el nom i comprova que existeixi:

   ```bash
   client="$ARGUMENTS"
   arnes_validate_client_name "$client"
   remote "test -d $WEB_ROOT/$client && echo OK || echo MISSING"
   ```

3. **Demana confirmació explícita** a l'usuari abans de continuar. Mostra el
   que s'esborrarà: directori web, `server block`, registre DNS i usuari FTP.

4. Fes la còpia de seguretat **obligatòria** seguint la skill `backups`
   (`/var/backups/arnes/<client>/<client>-<YYYYmmddTHHMMSSZ>.tar.gz`). Si el
   backup falla, atura't i no esborris res.

5. Elimina el `server block` i l'enllaç, i recarrega NGINX (skill `nginx`).

6. Elimina el registre DNS, incrementa el serial i recarrega Bind9 (skill
   `bind9`).

7. Elimina l'usuari FTP de MySQL (skill `mysql`):

   ```bash
   remote "mysql pureftpd -e \"DELETE FROM users WHERE User='$client';\""
   ```

8. Elimina el directori web:

   ```bash
   remote "rm -rf $WEB_ROOT/$client"
   ```

9. Verifica que ja no queda res i registra:

   ```bash
   remote "test -e $WEB_ROOT/$client && echo STILL_THERE || echo REMOVED"
   dig +short "$client.$ZONE_BASE" @"$SERVER_IP"
   arnes_log "client-delete" "$client" "ok"
   ```

10. Informa de la ruta del backup creat.
