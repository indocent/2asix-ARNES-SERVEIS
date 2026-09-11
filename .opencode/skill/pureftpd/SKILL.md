---
name: pureftpd
description: Use when configuring PureFTPD with virtual users stored in MySQL, editing /etc/pure-ftpd/db/mysql.conf (MYSQLCrypt md5, MYSQLGetPW, MYSQLGetUID, MYSQLGetGID, MYSQLGetDir, MySQLGetQTAFS), enabling chroot, reloading the service or testing FTP login. Covers PureFTPD MySQL authentication.
---

# Skill: PureFTPD

Servidor FTP amb usuaris virtuals emmagatzemats a la base de dades MySQL
`pureftpd`. Cada usuari queda tancat (chroot) al seu directori.

## Configuració MySQL

Fitxer `/etc/pure-ftpd/db/mysql.conf`:

```
MYSQLServer     127.0.0.1
MYSQLUser       pureftpd
MYSQLPassword   <password>
MYSQLDatabase   pureftpd
MYSQLCrypt      md5
MYSQLGetPW      SELECT Password FROM users WHERE User='\L' AND status='active'
MYSQLGetUID     SELECT Uid FROM users WHERE User='\L' AND status='active'
MYSQLGetGID     SELECT Gid FROM users WHERE User='\L' AND status='active'
MYSQLGetDir     SELECT Dir FROM users WHERE User='\L' AND status='active'
MySQLGetQTAFS   0
```

> `\L` és el nom de login. Les consultes només retornen files amb
> `status='active'`, de manera que deshabilitar un client n'impedeix el login.
> El fitxer ha de tenir permisos restrictius (`600`, propietari `root`).

## Activar l'autenticació MySQL i el chroot

A `/etc/pure-ftpd/conf/` (Debian):

```bash
remote "printf 'mysql:/etc/pure-ftpd/db/mysql.conf\n' > /etc/pure-ftpd/conf/MySQLConfigFile"
remote "printf 'yes\n' > /etc/pure-ftpd/conf/ChrootEveryone"
remote "printf 'no\n'  > /etc/pure-ftpd/conf/ProhibitDotFilesWrite"
remote "printf 'yes\n' > /etc/pure-ftpd/conf/CreateHomeDir"
```

## Reiniciar

```bash
remote "systemctl restart pure-ftpd"
remote "systemctl is-active pure-ftpd"
```

## Alta d'un client FTP

El directori ha d'existir i pertànyer a `www-data:www-data`:

```bash
remote "install -d -o www-data -g www-data -m 755 $WEB_ROOT/<client>/htdocs"
```

La fila a MySQL es crea des de la skill `mysql` amb el hash MD5 crypt
(`arnes_hash_password`).

## Comprovacions

```bash
# login FTP no interactiu
lftp -u <client>,<password> -e "ls; bye" ftp://$SERVER_IP
# o bé
curl -s --user <client>:<password> ftp://$SERVER_IP/ | head
```

## Errors típics

* **530 Login incorrect:** hash incorrecte (ha de ser MD5 crypt `$1$...`),
  fila inexistent o `status='disabled'`.
* **550 Failed to change directory:** el `Dir` no existeix o no és accessible
  per l'usuari.
* **FTP no arrenca:** `mysql.conf` mal format o MySQL inaccessible.
* **No chroot:** falta `ChrootEveryone yes`.
