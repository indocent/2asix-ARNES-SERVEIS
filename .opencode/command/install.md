---
description: Instal·la i configura NGINX, Bind9, PureFTPD i MySQL/MariaDB al servidor remot de manera idempotent.
agent: sysadmin
---

Instal·la i configura tot el programari de l'arnés al servidor remot. Aquesta
operació ha de ser **idempotent**: executar-la diverses vegades no ha de tenir
efectes perjudicials ni errors.

Paràmetres addicionals (opcionals): `$ARGUMENTS` (si s'indica `--no-certbot`,
no instal·lis certbot).

Segueix aquests passos:

1. Carrega l'entorn i comprova la connexió:

   ```bash
   set -a; . ./inventory.env; set +a
   source .opencode/lib/remote.sh
   arnes_check_connection
   ```

2. Instal·la els paquets (idempotent):

   ```bash
   remote "export DEBIAN_FRONTEND=noninteractive && \
     apt-get update && \
     apt-get install -y nginx bind9 bind9utils bind9-dnsutils \
       pure-ftpd pure-ftpd-mysql mysql-server openssl lftp"
   ```

3. Prepara directoris i permisos:

   ```bash
   remote "install -d -m 755 $WEB_ROOT"
   remote "install -d -m 750 $BACKUP_DIR"
   remote "install -d -m 755 $(dirname "$LOG_FILE")"
   ```

4. Crea la base de dades, l'usuari i la taula `users` (consulta la skill
   `mysql`). Genera una contrasenya aleatòria per a l'usuari `pureftpd` i
   desa-la a `/etc/pure-ftpd/db/mysql.conf` amb permisos `600`. **No** la
   mostris als logs.

5. Configura `/etc/pure-ftpd/db/mysql.conf` i els fitxers de `/etc/pure-ftpd/conf/`
   segons la skill `pureftpd` (`MYSQLCrypt md5`, `MYSQLGetPW`, `MYSQLGetUID`,
   `MYSQLGetGID`, `MYSQLGetDir` amb `status='active'`, `MySQLGetQTAFS 0`,
   `ChrootEveryone yes`).

6. Crea la zona DNS de `$ZONE_BASE` i la seva declaració a
   `/etc/bind/named.conf.local` segons la skill `bind9`. Valida amb
   `named-checkzone` i recarrega.

7. Crea la configuració base d'NGINX si cal i assegura't que el servei
   arrenca.

8. Habilita i arrenca els serveis:

   ```bash
   remote "systemctl enable --now nginx"
   remote "systemctl enable --now named 2>/dev/null || systemctl enable --now bind9"
   remote "systemctl enable --now mysql 2>/dev/null || systemctl enable --now mariadb"
   remote "systemctl enable --now pure-ftpd"
   ```

9. Comprova-ho tot: `nginx -t`, `named-checkzone $ZONE_BASE ...`, connexió a
   MySQL, i `systemctl is-active` dels serveis.

10. Registra l'operació amb `arnes_log "install" "-" "ok"`.

Si una comprovació prèvia falla, atura't amb un missatge clar i no deixis
serveis a mitges.
