---
description: Crea una còpia de seguretat d'un client (web, configuració NGINX, registre DNS i dades FTP) amb data i hora.
agent: sysadmin
---

Crea una còpia de seguretat del client `$ARGUMENTS`.

Passos:

1. Carrega l'entorn i comprova la connexió:

   ```bash
   set -a; . ./inventory.env; set +a
   source .opencode/lib/remote.sh
   arnes_check_connection
   ```

2. Valida el nom i comprova que el client existeixi (directori web o fila FTP).

3. Crea el backup seguint la skill `backups`:

   ```
   $BACKUP_DIR/<client>/<client>-<YYYYmmddTHHMMSSZ>.tar.gz
   ```

   amb el contingut `web/`, `nginx.conf`, `dns.txt` i `ftp.sql`.

4. Verifica que l'arxiu s'ha creat i no és buit:

   ```bash
   remote "ls -lh $BACKUP_DIR/$client/"
   remote "tar -tzf $BACKUP_DIR/$client/<fitxer> | head"
   ```

5. Registra l'operació amb `arnes_log "backup" "$client" "ok"` i informa de la
   ruta exacta del backup.
