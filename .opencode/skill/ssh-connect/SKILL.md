---
name: ssh-connect
description: Use when connecting to the remote Debian server over SSH for the arnés, loading inventory.env and the remote() wrapper from .opencode/lib/remote.sh, or diagnosing SSH/sudo connectivity. Covers key-based auth, host/port/user config and connection checks.
---

# Skill: connexió SSH

Tota operació de l'arnés es fa contra un servidor Debian remot via SSH. La
configuració de connexió **no** és al codi: viu a `inventory.env`.

## Carregar l'entorn

```bash
set -a; . ./inventory.env; set +a
source .opencode/lib/remote.sh
```

Variables: `SSH_HOST`, `SSH_PORT` (22), `SSH_USER`, `SSH_KEY`, `SSH_SUDO` (1),
`ZONE_BASE`, `SERVER_IP`, `WEB_ROOT` (`/var/www`), `BACKUP_DIR`
(`/var/backups/arnes`), `LOG_FILE` (`/var/log/arnes/operations.log`).

## Wrapper `remote()`

Totes les comandes remotes passen per la funció `remote()`:

```bash
remote "systemctl is-active nginx"
remote "ls -la /etc/nginx/sites-enabled"
```

`remote()` executa:

```
ssh -i "$SSH_KEY" -p "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=accept-new "$SSH_USER@$SSH_HOST" \
    "sudo -n bash -lc '<cmd>'"
```

Si `SSH_SUDO=0`, la comanda s'executa sense `sudo`.

## Pujar fitxers

```bash
remote_upload ./fitxer-local.conf /tmp/fitxer.conf
remote "install -m 0644 /tmp/fitxer.conf /etc/nginx/sites-available/foo.conf"
```

Per a destinacions propietat de root, puja sempre a `/tmp` i mou amb `remote()`.

## Comprovacions

```bash
arnes_check_connection                 # echo ok per SSH + sudo
remote "id -un && sudo -n true && echo sudo-ok"
remote "hostnamectl --static 2>/dev/null || hostname"
```

## Errors típics

* **Permission denied (publickey):** clau incorrecta o `SSH_KEY` mal definit.
  Comprova `ls -l "$SSH_KEY"` i `ssh-add -l`.
* **Host key verification failed:** el host ha canviat. Revisa'l abans
  d'acceptar-ne un de nou.
* **sudo: a password is required:** l'usuari no té `NOPASSWD` a sudoers.
  Configura `SSH_SUDO=0` o demana a l'administrador que l'hi afegeixi.
* **Connection timed out:** host, port o xarxa incorrectes.
* Si la connexió falla, **atura l'operació**: no continuïs a cegues.
