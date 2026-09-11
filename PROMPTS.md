# PROMPTS

## Prompt 1

Crea i afegeix a PROMPTS.md un prompt per a definir un arnés d'opencode que serveixi per administrar un servidor debian remot accedint per SSH.

Mitjançant l'arnés s'administrarà un servidor web NGINX, un servidor de DNS Bind9 autoritari d'una zona, i un servidor PureFTPD amb usuaris virtuals en una base de dades MySQL.

Aquest servidor servirà per a allotjar pàgines web estàtiques a diversos clients. Cada client tindrà un subdomini i un usuari virtual de FTP amb el mateix nom per a poder desplegar la seva web

L'arnés permetrà:

* instal·lar en un servidor tot el programari necessari i configurar-lo
* donar d'alta un nou client i que es generi una contrasenya segura
* deshabilitar i tornar a habilitar la web d'un client
* canviar el password d'un client
* canviar el nom d'un client
* esborrar un client, fent una copia de seguretat per si de cas

## Prompt 2

Dissenya i implementa un **arnés d'opencode** per administrar un servidor Debian remot accedint-hi per SSH. L'arnés ha de ser idempotent, segur i fàcil d'estendre.

> **Abast (important):** l'arnés **NO** és una aplicació autònoma, ni una CLI, ni una llibreria independents. És un conjunt de **primitives d'opencode** que viuen dins del projecte (`.opencode/` i `opencode.json`) i que l'agent fa servir per executar les operacions. El resultat ha de ser que, des d'una sessió d'opencode, es puguin invocar les operacions (comandes i skills) i que l'agent les dugui a terme via SSH.

### Composició de l'arnés

* **Agent primari** d'opencode (`.opencode/agent/sysadmin.md`) amb el prompt de sistema: context del servidor, model de dades, convencions i flux de treball.
* **Skills per domini** (`.opencode/skill/<nom>/SKILL.md`), com a mínim: `ssh-connect`, `nginx`, `bind9`, `pureftpd`, `mysql`, `backups` i, opcionalment, `certbot`. Cada skill ha d'incloure les comandes remotes, les comprovacions i els errors típics.
* **Comandes d'opencode** (`.opencode/command/*.md`) per a cada operació, amb `$ARGUMENTS`: `install`, `client-add`, `client-list`, `client-enable`, `client-disable`, `client-passwd`, `client-rename`, `client-delete`, `backup`, `restore` i `doctor`.
* **Regles de permisos** a `opencode.json` (p. ex. `bash` amb `ask`/`deny` per a operacions destructives, `external_directory` restringit) de manera que cap acció perillosa no s'executi sense confirmació.
* Opcionalment, un **plugin** o **servidor MCP** que encapsuli la connexió SSH i la càrrega de configuració.

### Entorn i accés

* L'objectiu és un servidor Debian remot; tota operació es farà via SSH (preferiblement amb claus, mai contrasenyes en text pla).
* La configuració de connexió (host, port, usuari, clau o agent, i paràmetres de sudo) ha de ser externa al codi: fitxer de configuració i/o variables d'entorn. No hi ha d'haver credencials hardcodejades.
* L'arnés s'executa en local i orquestra comandes remotes. Ha de detectar errors de connexió i aturar-se amb missatges clars.

### Programari a administrar

* **NGINX**: servidor web per allotjar webs estàtiques, un `server block` (virtual host) per client.
* **Bind9**: servidor DNS autoritari d'una zona; cal gestionar registres A/CNAME dels subdominis dels clients.
* **PureFTPD**: FTP amb usuaris virtuals emmagatzemats en una base de dades MySQL.
* **MySQL/MariaDB**: base de dades per als usuaris virtuals de PureFTPD.
* **Certbot/Let's Encrypt** (opcional): emissió i renovació de certificats TLS per als subdominis.

### Model de dades

* Cada client té: nom (que serà alhora el subdomini i l'usuari virtual de FTP), contrasenya, estat (actiu/desactivat) i directori arrel de la web.
* El nom del client ha de ser un identificador vàlid (DNS i FTP): minúscules, xifres i guions, sense començar per guió.
* El subdomini del client serà `<client>.<zona_base>` i el seu document root, per exemple `/var/www/<client>/htdocs`.
* L'usuari FTP virtual s'anomena igual que el client i queda tancat (chroot) al seu directori.

### Operacions requerides

1. **Instal·lació i configuració**: instal·lar i configurar tot el programari (NGINX, Bind9, PureFTPD, MySQL) en un servidor net, de manera idempotent. Ha de ser possible executar-ho diverses vegades sense efectes perjudicials.
2. **Alta de client**: crear el directori, el `server block` d'NGINX, el registre DNS, l'usuari virtual de FTP a MySQL i generar una contrasenya segura aleatòria. Retornar la contrasenya generada una sola vegada.
3. **Deshabilitar / habilitar la web d'un client**: deshabilitar o tornar a habilitar el `server block` sense esborrar dades ni l'usuari FTP.
4. **Canviar la contrasenya d'un client**: generar una contrasenya nova (o acceptar-ne una) i actualitzar-la a la base de dades.
5. **Canviar el nom d'un client**: renombrar de forma consistent el subdomini, el `server block`, el directori, el registre DNS i l'usuari FTP, mantenint les dades.
6. **Esborrar un client**: fer una còpia de seguretat prèvia (web + configuració + dades de l'usuari) i després eliminar-lo del sistema.

### Requisits de qualitat

* **Idempotència**: cada operació es pot repetir sense deixar el sistema en estat inconsistent.
* **Seguretat**: contrasenyes generades amb prou entropia; permisos correctes als directoris; cap secret als logs; chroot als usuaris FTP.
* **Tolerància a errors**: validar paràmetres i estat del servidor abans d'actuar; si una operació falla, no deixar configuracions a mitges (o informar clarament de com revertir).
* **Còpies de seguretat**: emmagatzemar-les amb data i hora i poder restaurar un client a partir d'elles.
* **Traçabilitat**: registre (log) de les operacions fetes i del resultat.
* **Proves**: incloure proves o comprovacions posteriors a cada operació (per exemple, resolució DNS, resposta HTTP, login FTP).

### Lliurables

* Estructura de `.opencode/` i d'`opencode.json` (agent, skills, comandes i permisos) amb la tecnologia triada i justificada.
* Fitxer de configuració/inventari d'exemple (host, port, usuari, clau o agent, paràmetres de sudo) i documentació d'ús.
* Implementació de totes les operacions anteriors com a skills i comandes d'opencode.
* Exemples d'invocació (comandes d'opencode) per a cada operació.
* Guia de desplegament i de recuperació davant errors.

## Prompt 3

Implementa dins d'aquest projecte l'**arnés d'opencode** descrit al Prompt 2, seguint exactament les decisions tècniques d'aquest prompt. Crea o modifica **només** fitxers dins `.opencode/`, `opencode.json`, `docs/` i `inventory.env.example`. No crees cap CLI, aplicació ni llibreria independent: són primitives d'opencode que l'agent executa via SSH. En acabar, des d'una sessió d'opencode han de funcionar les comandes `/install`, `/client-add`, `/client-list`, `/client-enable`, `/client-disable`, `/client-passwd`, `/client-rename`, `/client-delete`, `/backup`, `/restore` i `/doctor`.

### 1. Estructura exacta de fitxers

```
.opencode/
  agent/sysadmin.md
  lib/remote.sh
  skill/ssh-connect/SKILL.md
  skill/nginx/SKILL.md
  skill/bind9/SKILL.md
  skill/pureftpd/SKILL.md
  skill/mysql/SKILL.md
  skill/backups/SKILL.md
  skill/certbot/SKILL.md
  command/install.md
  command/client-add.md
  command/client-list.md
  command/client-enable.md
  command/client-disable.md
  command/client-passwd.md
  command/client-rename.md
  command/client-delete.md
  command/backup.md
  command/restore.md
  command/doctor.md
opencode.json
inventory.env.example
docs/README.md
```

### 2. `opencode.json`

Mantén `$schema`, `model`, `enabled_providers` i `provider`. Afegeix:

* `skills.paths: [".opencode/skill"]`
* `agent.sysadmin` apuntant al fitxer (o deixa'l només al fitxer).
* `permission.bash` amb regles, ordre ampli→específic:
  * `"*": "allow"`
  * `"ssh *": "ask"` (tota acció remota requereix confirmació)
  * `"*rm -rf*": "deny"`, `"*client-delete*": "ask"`, `"*DROP*": "ask"`
* `permission.external_directory` restringit al projecte.

### 3. Agent `sysadmin.md`

Frontmatter: `description`, `mode: primary`, `model`, `permission.bash: ask`.
Cos: context del servidor, lectura d'`inventory.env`, convencions SSH, model de dades, flux de treball de cada operació, gestió d'errors, i la regla **cap credencial hardcodejada** i **cap acció destructiva sense confirmació**.

### 4. Convencions tancades

* **Inventari:** `inventory.env` a l'arrel (ja gitignored). Claus: `SSH_HOST`, `SSH_PORT=22`, `SSH_USER`, `SSH_KEY`, `SSH_SUDO=1`, `ZONE_BASE`, `SERVER_IP`, `WEB_ROOT=/var/www`, `BACKUP_DIR=/var/backups/arnes`, `LOG_FILE=/var/log/arnes/operations.log`. Es carrega amb `set -a; . ./inventory.env; set +a`.
* **Wrapper SSH:** `.opencode/lib/remote.sh` amb `remote()` i `remote_upload()`:
  `ssh -i "$SSH_KEY" -p "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "$SSH_USER@$SSH_HOST" "sudo -n bash -lc '<cmd>'"`.
  Tota comanda remota ha d'anar-hi; cap `ssh` ad-hoc.
* **Idempotència:** comprovar existència abans de crear; `mkdir -p`, `ln -sfn`, `CREATE TABLE IF NOT EXISTS`, `INSERT ... ON DUPLICATE KEY UPDATE`.
* **Errors:** `set -euo pipefail`, validar inventari i paràmetres abans d'actuar, aturar-se amb missatge clar.
* **Validació de nom de client:** `^[a-z][a-z0-9-]{1,62}$` (DNS + FTP).
* **Contrasenya:** `openssl rand -base64 24 | tr -d '/+=' | cut -c1-24`; retornar-la **una sola vegada**.
* **Hash FTP:** `openssl passwd -1 -salt "$(openssl rand -hex 4)" "$pass"` (MD5 crypt per `MYSQLCrypt md5`).
* **Traçabilitat:** cada operació afegeix `ISO8601<TAB>operacio<TAB>client<TAB>resultat` a `LOG_FILE` remot.

### 5. Rutes i plantilles tancades

* **NGINX:** `/etc/nginx/sites-available/<client>.conf` + symlink a `sites-enabled/`. Plantilla:
  `server { listen 80; server_name <client>.<zona>; root /var/www/<client>/htdocs; index index.html; location / { try_files $uri $uri/ =404; } }`
  Deshabilitar = esborrar només el symlink; habilitar = recrear-lo. Sempre `nginx -t && systemctl reload nginx`.
* **Bind9:** zona a `/etc/bind/zones/db.<zona>` declarada a `/etc/bind/named.conf.local`:
  `zone "<zona>" { type master; file "/etc/bind/zones/db.<zona>"; };`
  Registre de client: `<client> IN A <SERVER_IP>`. Recarregar amb `named-checkzone <zona> <fitxer>` + `rndc reload <zona>`.
* **Directori web:** `/var/www/<client>/htdocs`, owner `www-data:www-data`, perms `755` (dirs) i `644` (fitxers).
* **Backups:** `/var/backups/arnes/<client>/<client>-<YYYYmmddTHHMMSSZ>.tar.gz` (web + config nginx + registre DNS + fila FTP). `restore` llista i restaura un backup.
* **Certbot (opcional):** `certbot --nginx -d <client>.<zona>`.

### 6. Base de dades MySQL (esquema exacte)

Base `pureftpd`, usuari `pureftpd`:

```sql
CREATE TABLE IF NOT EXISTS users (
  User        VARCHAR(64)  NOT NULL PRIMARY KEY,
  Password    VARCHAR(255) NOT NULL,
  Uid         INT          NOT NULL DEFAULT 2001,
  Gid         INT          NOT NULL DEFAULT 2001,
  Dir         VARCHAR(255) NOT NULL,
  status      ENUM('active','disabled') NOT NULL DEFAULT 'active'
) ENGINE=InnoDB;
```

`/etc/pure-ftpd/db/mysql.conf`: `MYSQLCrypt md5`, `MYSQLGetPW`, `MYSQLGetUID`, `MYSQLGetGID`, `MYSQLGetDir` (només files amb `status='active'`), `MySQLGetQTAFS 0`. Usuaris chroot al seu `Dir`.

### 7. Operacions (comandes)

Cada `.md` amb frontmatter `description`, `agent: sysadmin` i cos amb `$ARGUMENTS`:

* `install` — instal·la i configura NGINX, Bind9, PureFTPD, MySQL; crea base/tabla i `mysql.conf`.
* `client-add <nom>` — valida, crea dir+server block+DNS+usuari FTP, genera i mostra contrasenya.
* `client-list` — llista clients amb estat i ruta.
* `client-enable|client-disable <nom>` — symlink NGINX, sense esborrar dades ni FTP.
* `client-passwd <nom>` — nova contrasenya (o `$2`), actualitza hash a MySQL.
* `client-rename <antic> <nou>` — renombra dir, server block, DNS i usuari FTP de manera consistent.
* `client-delete <nom>` — backup previ obligatori, després elimina.
* `backup <nom>` / `restore <nom> [fitxer]`.
* `doctor` — comprova connexió, serveis, `nginx -t`, `named-checkzone`, connexió MySQL i FTP.

### 8. Proves posteriors a cada operació

`dig +short <client>.<zona> @<SERVER_IP>`, `curl -sI http://<client>.<zona>`, login FTP (`lftp -u <client>,<pass>`), i comprovació de la fila a MySQL.

### 9. Criteris d'acceptació

* opencode arrenca sense errors de configuració.
* Existeixen tots els fitxers de l'apartat 1 amb frontmatter vàlid.
* `/install` és idempotent (dues execucions seguides sense errors).
* Cada operació valida, registra al log i verifica el resultat.
* Cap secret al repositori ni als logs; `inventory.env` no es commit.
* `docs/README.md` documenta instal·lació, inventari i exemples d'invocació.
