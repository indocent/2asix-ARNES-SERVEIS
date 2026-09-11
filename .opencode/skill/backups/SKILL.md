---
name: backups
description: Use when backing up or restoring a client (static web, NGINX config, DNS record and FTP database row) with tar.gz archives under /var/backups/arnes/<client>/, listing available backups, or enforcing the mandatory backup before client deletion. Covers backup naming and restore.
---

# Skill: còpies de seguretat

Cada client es pot copiar i restaurar. Els backups viuen a
`$BACKUP_DIR/<client>/` (`/var/backups/arnes/<client>/`).

## Nom dels backups

```
/var/backups/arnes/<client>/<client>-<YYYYmmddTHHMMSSZ>.tar.gz
```

El contingut de l'arxiu:

* `web/` — el directori `$WEB_ROOT/<client>`
* `nginx.conf` — `/etc/nginx/sites-available/<client>.conf`
* `dns.txt` — el registre A del client extret de la zona
* `ftp.sql` — la fila de l'usuari a MySQL (`mysqldump` de la fila)

## Crear un backup

```bash
ts="$(date -u +%Y%m%dT%H%M%SZ)"
remote "install -d -m 750 $BACKUP_DIR/<client>"
remote "tmp=\$(mktemp -d) && \
  cp -a $WEB_ROOT/<client> \"\$tmp/web\" 2>/dev/null; \
  cp -a /etc/nginx/sites-available/<client>.conf \"\$tmp/nginx.conf\" 2>/dev/null; \
  grep -E '^<client>[[:space:]]+IN[[:space:]]+A' /etc/bind/zones/db.$ZONE_BASE > \"\$tmp/dns.txt\" 2>/dev/null; \
  mysql pureftpd -e \"SELECT * FROM users WHERE User='<client>';\" > \"\$tmp/ftp.sql\" 2>/dev/null; \
  tar -czf $BACKUP_DIR/<client>/<client>-$ts.tar.gz -C \"\$tmp\" . && rm -rf \"\$tmp\""
```

## Llistar backups

```bash
remote "ls -1t $BACKUP_DIR/<client>/*.tar.gz 2>/dev/null"
```

## Restaurar

Si no s'especifica fitxer, s'usa el més recent. Cal **confirmació** abans de
sobreescriure dades.

```bash
remote "test -f $BACKUP_DIR/<client>/<fitxer>"
remote "tmp=\$(mktemp -d) && tar -xzf $BACKUP_DIR/<client>/<fitxer> -C \"\$tmp\" && \
  rm -rf $WEB_ROOT/<client> && cp -a \"\$tmp/web\" $WEB_ROOT/<client> 2>/dev/null; \
  cp -a \"\$tmp/nginx.conf\" /etc/nginx/sites-available/<client>.conf 2>/dev/null; \
  rm -rf \"\$tmp\""
remote "chown -R www-data:www-data $WEB_ROOT/<client> && nginx -t && systemctl reload nginx"
```

Per restaurar la fila FTP, torna a aplicar `ftp.sql` o recrea-la amb la skill
`mysql` (cal regenerar el hash si no es conserva la contrasenya original).

## Comprovacions

```bash
remote "ls -lh $BACKUP_DIR/<client>/"
curl -sI http://<client>.$ZONE_BASE
dig +short <client>.$ZONE_BASE @$SERVER_IP
```

## Errors típics

* **Backup buit:** el directori web o la config no existien en fer la còpia.
* **Restauració sense espai:** comprova `df -h` al servidor.
* **Permisos incorrectes després de restaurar:** torna a fer `chown`/`chmod`.
* **Sobreescriure dades sense voler:** confirma sempre abans de restaurar.
