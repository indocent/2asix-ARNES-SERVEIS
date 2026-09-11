---
description: Comprova la salut de l'arnés: connexió SSH, serveis, nginx -t, named-checkzone, connexió MySQL i FTP.
agent: sysadmin
---

Executa un diagnòstic complet de l'arnés i informa de l'estat de cada component.

Passos:

1. Carrega l'entorn:

   ```bash
   set -a; . ./inventory.env; set +a
   source .opencode/lib/remote.sh
   ```

2. **Connexió SSH i sudo:**

   ```bash
   arnes_check_connection && echo "SSH: OK"
   remote "sudo -n true && echo 'sudo: OK'"
   ```

3. **Serveis:**

   ```bash
   remote "systemctl is-active nginx named bind9 mysql mariadb pure-ftpd 2>&1"
   ```

4. **NGINX:**

   ```bash
   remote "nginx -t"
   ```

5. **Bind9:**

   ```bash
   remote "named-checkzone $ZONE_BASE /etc/bind/zones/db.$ZONE_BASE"
   remote "rndc status 2>&1 | head"
   ```

6. **MySQL:**

   ```bash
   remote "mysql pureftpd -N -e \"SELECT COUNT(*) AS usuaris FROM users;\""
   remote "mysql pureftpd -N -e \"SELECT COUNT(*) FROM users WHERE status='active';\""
   ```

7. **FTP:**

   ```bash
   remote "ss -ltnp 2>/dev/null | grep ':21 ' || netstat -ltnp 2>/dev/null | grep ':21 '"
   ```

8. **Espai en disc i permisos clau:**

   ```bash
   remote "df -h /"
   remote "ls -ld $WEB_ROOT $BACKUP_DIR $(dirname "$LOG_FILE") 2>&1"
   ```

9. Presenta un resum clar amb `OK`/`FAIL` per a cada comprovació i, per a cada
   `FAIL`, una indicació de com arreglar-ho. Registra el resultat global amb
   `arnes_log "doctor" "-" "ok"` o `"fail"`.
