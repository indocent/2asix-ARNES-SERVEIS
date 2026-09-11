---
name: certbot
description: Use when issuing, renewing or removing Let's Encrypt TLS certificates for a client subdomain with certbot --nginx, or when checking certificate expiry. Optional hardening for the arnés NGINX sites.
---

# Skill: Certbot / Let's Encrypt (opcional)

Emissió i renovació de certificats TLS per als subdominis dels clients.

## Requisits previs

* El registre DNS del client ja resol a `$SERVER_IP` (skill `bind9`).
* El `server block` d'NGINX del client existeix i respon per HTTP.
* El port 80 és accessible des d'Internet.

## Emetre un certificat

```bash
remote "certbot --nginx -d <client>.$ZONE_BASE --non-interactive --agree-tos \
  --redirect -m admin@$ZONE_BASE"
```

`--redirect` afegeix la redirecció HTTP→HTTPS al `server block`.

## Renovar

```bash
remote "certbot renew --quiet"
remote "systemctl list-timers | grep certbot"
```

La renovació automàtica la gestiona el temporitzador de systemd que instal·la el
paquet `certbot`.

## Comprovar

```bash
remote "certbot certificates"
curl -sI https://<client>.$ZONE_BASE
echo | openssl s_client -connect $SERVER_IP:443 -servername <client>.$ZONE_BASE 2>/dev/null | openssl x509 -noout -dates
```

## Errors típics

* **Challenge failed:** el DNS encara no resol o el port 80 no és accessible.
* **Too many requests:** límit de Let's Encrypt; espera o usa l'entorn de staging
  (`--test-cert`).
* **No renewals were attempted:** revisa `/etc/letsencrypt/renewal/`.
