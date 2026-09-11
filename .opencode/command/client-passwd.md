---
description: Canvia la contrasenya de l'usuari FTP d'un client (generada o indicada) i actualitza el hash a MySQL.
agent: sysadmin
---

Canvia la contrasenya de l'usuari FTP del client `$ARGUMENTS`. Si s'indica un
segon argument, s'usa com a contrasenya nova; si no, se'n genera una d'aleatòria
segura.

Passos:

1. Carrega l'entorn i comprova la connexió:

   ```bash
   set -a; . ./inventory.env; set +a
   source .opencode/lib/remote.sh
   arnes_check_connection
   ```

2. Valida el nom i comprova que l'usuari existeixi:

   ```bash
   client="$1"
   arnes_validate_client_name "$client"
   remote "mysql pureftpd -N -e \"SELECT COUNT(*) FROM users WHERE User='$client';\""
   ```

   Si no existeix, atura't.

3. Determina la contrasenya i calcula el hash MD5 crypt:

   ```bash
   if [ -n "${2:-}" ]; then pass="$2"; else pass="$(arnes_gen_password)"; fi
   hash="$(arnes_hash_password "$pass")"
   ```

4. Actualitza el hash a MySQL (skills `mysql` i `pureftpd`):

   ```bash
   remote "mysql pureftpd -e \"UPDATE users SET Password='$hash' WHERE User='$client';\""
   ```

5. Verifica el login FTP amb `lftp` i registra:

   ```bash
   lftp -u "$client","$pass" -e "ls; bye" "ftp://$SERVER_IP" >/dev/null
   arnes_log "client-passwd" "$client" "ok"
   ```

6. Mostra la contrasenya nova **una sola vegada**. No l'escriguis a cap fitxer
   ni al log.
