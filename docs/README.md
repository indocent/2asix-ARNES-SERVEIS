# Arnés d'opencode per administrar un servidor web remot

Aquest projecte és un **arnés d'opencode**: un conjunt de primitives d'opencode
(agent, skills i comandes) que l'agent executa via SSH per administrar un
servidor Debian remot que allotja webs estàtiques de clients.

No és una aplicació autònoma, ni una CLI, ni una llibreria independent. Tot
viu dins `.opencode/` i `opencode.json`.

## Programari administrat

| Servei | Funció |
| --- | --- |
| **NGINX** | Servidor web; un `server block` per client |
| **Bind9** | DNS autoritari de la zona `$ZONE_BASE` |
| **PureFTPD** | FTP amb usuaris virtuals a MySQL |
| **MySQL/MariaDB** | Base de dades `pureftpd` amb els usuaris FTP |
| **Certbot** (opcional) | Certificats TLS Let's Encrypt |

## Estructura

```
.opencode/
  agent/sysadmin.md          # agent primari
  lib/remote.sh              # wrapper SSH (remote, remote_upload, helpers)
  skill/
    ssh-connect/SKILL.md
    nginx/SKILL.md
    bind9/SKILL.md
    pureftpd/SKILL.md
    mysql/SKILL.md
    backups/SKILL.md
    certbot/SKILL.md
  command/                   # /install, /client-*, /backup, /restore, /doctor
opencode.json                # permisos i skills.paths
inventory.env.example        # plantilla d'inventari
```

## Requisits

* `opencode` instal·lat.
* Accés SSH al servidor remot amb **clau** (mai contrasenyes en text pla) i un
  usuari amb `sudo` (idealment `NOPASSWD`).
* `ssh`, `scp`, `openssl`, `dig` i `curl` a la màquina local.

## Configuració de l'inventari

1. Copia la plantilla:

   ```bash
   cp inventory.env.example inventory.env
   ```

2. Omple `inventory.env` amb les dades reals. **No el commitis mai** (ja és a
   `.gitignore`).

| Variable | Descripció | Per defecte |
| --- | --- | --- |
| `SSH_HOST` | Nom o IP del servidor | — |
| `SSH_PORT` | Port SSH | `22` |
| `SSH_USER` | Usuari SSH amb sudo | — |
| `SSH_KEY` | Clau privada (buit = ssh-agent) | — |
| `SSH_SUDO` | `1` usa `sudo -n`, `0` no | `1` |
| `ZONE_BASE` | Zona DNS base dels clients | — |
| `SERVER_IP` | IP pública del servidor | — |
| `WEB_ROOT` | Arrel dels webs | `/var/www` |
| `BACKUP_DIR` | Directori de backups | `/var/backups/arnes` |
| `LOG_FILE` | Fitxer de traçabilitat | `/var/log/arnes/operations.log` |

## Posada en marxa

1. Reinicia `opencode` perquè carregui `opencode.json`, l'agent i les skills.
2. Des d'una sessió d'opencode, executa:

   ```
   /doctor
   ```

   per comprovar la connexió i l'estat del servidor.
3. En un servidor net, executa:

   ```
   /install
   ```

   És idempotent: es pot repetir sense efectes perjudicials.

## Comandes

| Comanda | Descripció |
| --- | --- |
| `/install` | Instal·la i configura NGINX, Bind9, PureFTPD i MySQL |
| `/client-add <nom>` | Alta de client; genera i mostra la contrasenya **un cop** |
| `/client-list` | Llista clients amb estat web i FTP |
| `/client-enable <nom>` | Recrea l'enllaç d'NGINX (sense tocar dades ni FTP) |
| `/client-disable <nom>` | Elimina només l'enllaç d'NGINX |
| `/client-passwd <nom> [pass]` | Nova contrasenya (generada o indicada) |
| `/client-rename <antic> <nou>` | Renombra directori, NGINX, DNS i FTP |
| `/client-delete <nom>` | Backup obligatori i esborrat del client |
| `/backup <nom>` | Còpia de seguretat d'un client |
| `/restore <nom> [fitxer]` | Restaura un client |
| `/doctor` | Diagnòstic complet |

## Convencions

* **Nom de client:** `^[a-z][a-z0-9-]{1,62}$` (vàlid com a DNS i com a FTP).
* **Subdomini:** `<client>.<ZONE_BASE>`.
* **Document root:** `$WEB_ROOT/<client>/htdocs`.
* **Contrasenyes:** `openssl rand -base64 24 | tr -d '/+=' | cut -c1-24`.
* **Hash FTP:** MD5 crypt (`openssl passwd -1`), compatible amb `MYSQLCrypt md5`.
* **Traçabilitat:** `ISO8601<TAB>operacio<TAB>client<TAB>resultat` a `LOG_FILE`.
* **Backups:** `$BACKUP_DIR/<client>/<client>-<YYYYmmddTHHMMSSZ>.tar.gz`.

## Seguretat

* Cap credencial al repositori ni als logs.
* Totes les comandes remotes passen per `remote()`.
* L'agent `sysadmin` té `permission.bash: ask`: tota acció requereix confirmació.
* Les regles d'`opencode.json` deneguen `rm -rf` i demanen confirmació per a
  esborrats de clients i operacions `DROP`.
* Els usuaris FTP queden tancats (chroot) al seu directori.
* Les contrasenyes generades es mostren una sola vegada i no s'escriuen a disc.

## Recuperació davant errors

* **No hi ha connexió SSH:** comprova `inventory.env`, la clau i que el servidor
  sigui accessible. L'operació s'atura; no continua a cegues.
* **`nginx -t` falla:** no recarreguis; corregeix el `server block`. Pots
  restaurar la configuració des d'un backup.
* **Zona DNS trencada:** valida amb `named-checkzone` abans de recarregar.
* **Operació a mitges:** restaura el client amb `/restore <nom>` a partir del
  backup previ.
* **Perdut l'accés a un client:** `/client-passwd <nom>` per regenerar-ne la
  contrasenya.

## Exemples

```
/client-add acme
# → mostra una contrasenya generada; desa-la!

/client-disable acme
/client-enable acme

/client-rename acme acme-nou
/client-passwd acme-nou

/backup acme-nou
/restore acme-nou

/client-delete acme-nou   # demana confirmació i fa backup previ
```
