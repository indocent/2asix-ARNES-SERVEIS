---
description: Restaura un client a partir d'una còpia de seguretat (la més recent o un fitxer concret).
agent: sysadmin
---

Restaura el client `$1` a partir d'un backup. Si s'indica `$2`, s'usa aquell
fitxer; si no, el més recent.

Passos:

1. Carrega l'entorn i comprova la connexió:

   ```bash
   set -a; . ./inventory.env; set +a
   source .opencode/lib/remote.sh
   arnes_check_connection
   ```

2. Valida el nom i llista els backups disponibles:

   ```bash
   client="$1"
   arnes_validate_client_name "$client"
   remote "ls -1t $BACKUP_DIR/$client/*.tar.gz 2>/dev/null"
   ```

   Si no n'hi ha cap, atura't.

3. Determina el fitxer a restaurar (`$2` o el més recent) i comprova que
   existeix:

   ```bash
   remote "test -f $BACKUP_DIR/$client/<fitxer> && echo OK || echo MISSING"
   ```

4. **Demana confirmació** abans de sobreescriure les dades actuals del client.

5. Restaura el directori web, el `server block`, el registre DNS i la fila FTP
   seguint la skill `backups`, i recarrega NGINX i Bind9.

6. Verifica i registra:

   ```bash
   remote "nginx -t && systemctl reload nginx"
   curl -sI "http://$client.$ZONE_BASE"
   dig +short "$client.$ZONE_BASE" @"$SERVER_IP"
   arnes_log "restore" "$client" "ok"
   ```
