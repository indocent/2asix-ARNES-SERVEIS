# 2asix-ARNES-SERVEIS

**Arnés d'opencode** per administrar per SSH un servidor Debian remot que
allotja webs estàtiques de diversos clients.

No és una aplicació, ni una CLI, ni una llibreria: és un conjunt de primitives
d'opencode (agent, skills i comandes) que viuen dins d'`.opencode/` i
`opencode.json`, i que l'agent executa via SSH.

## Què administra

| Servei | Funció |
| --- | --- |
| **NGINX** | Servidor web; un `server block` per client |
| **Bind9** | DNS autoritari de la zona base |
| **PureFTPD** | FTP amb usuaris virtuals a MySQL |
| **MySQL/MariaDB** | Base de dades `pureftpd` amb els usuaris FTP |
| **Certbot** (opcional) | Certificats TLS Let's Encrypt |

Cada client té un subdomini (`<client>.<ZONE_BASE>`) i un usuari FTP del mateix
nom, tancat (chroot) al seu directori web.

## Comandes

`/install`, `/client-add`, `/client-list`, `/client-enable`, `/client-disable`,
`/client-passwd`, `/client-rename`, `/client-delete`, `/backup`, `/restore` i
`/doctor`.

## Posada en marxa

1. Copia la plantilla d'inventari i omple-la (mai la commitis):

   ```bash
   cp inventory.env.example inventory.env
   ```

2. Afegeix el **token d'opencode** (obligatori) a
   `.opencode/keys/opencode-key.txt` i, **opcionalment**, el de **DeepSeek** a
   `.opencode/keys/deepseek-key.txt`. El directori `.opencode/keys/` ignora els
   `*.txt`, així que no es commiten mai:

   ```bash
   printf '%s' '<el-teu-token>' > .opencode/keys/opencode-key.txt
   # Opcional (només si fas servir el proveïdor deepseek):
   printf '%s' '<el-teu-token>' > .opencode/keys/deepseek-key.txt
   ```

3. Reinicia `opencode` perquè carregui la configuració, l'agent i les skills.
4. Des d'una sessió d'opencode, comprova la connexió amb `/doctor` i, en un
   servidor net, executa `/install`.

## Documentació

Guia completa a [`docs/README.md`](docs/README.md): requisits, inventari,
convencions, seguretat i recuperació davant errors.
