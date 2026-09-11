---
name: nginx
description: Use when creating, enabling, disabling or removing an NGINX server block (virtual host) for a client web at /etc/nginx/sites-available/<client>.conf, reloading NGINX, or checking HTTP responses. Covers the static-site template and nginx -t validation.
---

# Skill: NGINX

Servidor web per allotjar les webs estàtiques dels clients. Un `server block`
per client.

## Rutes

* Config: `/etc/nginx/sites-available/<client>.conf`
* Enllaç actiu: `/etc/nginx/sites-enabled/<client>.conf`
* Document root: `$WEB_ROOT/<client>/htdocs` (`/var/www/<client>/htdocs`)

## Plantilla del `server block`

```nginx
server {
    listen 80;
    server_name <client>.<ZONE_BASE>;
    root /var/www/<client>/htdocs;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
```

## Crear o actualitzar (idempotent)

```bash
remote "mkdir -p /etc/nginx/sites-available"
remote "cat > /etc/nginx/sites-available/<client>.conf <<'EOF'
server {
    listen 80;
    server_name <client>.<ZONE_BASE>;
    root $WEB_ROOT/<client>/htdocs;
    index index.html;
    location / { try_files \$uri \$uri/ =404; }
}
EOF"
remote "ln -sfn /etc/nginx/sites-available/<client>.conf /etc/nginx/sites-enabled/<client>.conf"
remote "nginx -t && systemctl reload nginx"
```

> Nota: en executar-ho des de la llibreria, vigila l'escapament de `$uri` perquè
> no s'expandeixi a la shell local.

## Habilitar / deshabilitar

Deshabilitar = esborrar **només** l'enllaç de `sites-enabled`; no toquis la web,
el directori ni l'usuari FTP.

```bash
remote "rm -f /etc/nginx/sites-enabled/<client>.conf && nginx -t && systemctl reload nginx"
```

Habilitar = recrear l'enllaç:

```bash
remote "ln -sfn /etc/nginx/sites-available/<client>.conf /etc/nginx/sites-enabled/<client>.conf && nginx -t && systemctl reload nginx"
```

## Esborrar el `server block` (només en esborrar el client)

```bash
remote "rm -f /etc/nginx/sites-enabled/<client>.conf /etc/nginx/sites-available/<client>.conf && nginx -t && systemctl reload nginx"
```

## Directori web

```bash
remote "install -d -o www-data -g www-data -m 755 $WEB_ROOT/<client>/htdocs"
remote "find $WEB_ROOT/<client> -type d -exec chmod 755 {} +"
remote "find $WEB_ROOT/<client> -type f -exec chmod 644 {} +"
remote "chown -R www-data:www-data $WEB_ROOT/<client>"
```

## Comprovacions

```bash
remote "nginx -t"
remote "systemctl is-active nginx"
remote "ls -l /etc/nginx/sites-enabled/<client>.conf"
curl -sI http://<client>.<ZONE_BASE>
```

## Errors típics

* **nginx: configuration file test failed:** revisa el `server block`; no
  recarreguis si `nginx -t` falla.
* **403 Forbidden:** permisos o propietari incorrectes al document root.
* **404:** `root` o `try_files` mal configurats.
* **default server:** si un `server_name` no coincideix, NGINX cau al server
  per defecte.
