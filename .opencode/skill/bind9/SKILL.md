---
name: bind9
description: Use when managing the authoritative Bind9 DNS zone for the client subdomains, adding or removing A records, editing /etc/bind/zones/db.<zone> and named.conf.local, validating with named-checkzone and reloading with rndc. Covers zone declaration and DNS checks.
---

# Skill: Bind9

Servidor DNS autoritari de la zona `$ZONE_BASE`. Cada client té un registre A
`<client> IN A $SERVER_IP`.

## Rutes

* Zona: `/etc/bind/zones/db.$ZONE_BASE`
* Declaració: `/etc/bind/named.conf.local`

## Declaració de la zona (idempotent)

```bash
remote "install -d -o bind -g bind -m 775 /etc/bind/zones"
remote "grep -q 'zone \"$ZONE_BASE\"' /etc/bind/named.conf.local || \
  printf 'zone \"%s\" { type master; file \"/etc/bind/zones/db.%s\"; };\n' '$ZONE_BASE' '$ZONE_BASE' >> /etc/bind/named.conf.local"
```

## Fitxer de zona

```bash
remote "test -f /etc/bind/zones/db.$ZONE_BASE || cat > /etc/bind/zones/db.$ZONE_BASE <<'EOF'
\$TTL 3600
@   IN  SOA ns.$ZONE_BASE. admin.$ZONE_BASE. (
        2024010101 ; serial
        7200       ; refresh
        3600       ; retry
        1209600    ; expire
        3600 )     ; minimum
@   IN  NS  ns.$ZONE_BASE.
ns  IN  A   $SERVER_IP
EOF"
```

## Afegir el registre A d'un client (idempotent)

```bash
remote "grep -qE '^<client>[[:space:]]+IN[[:space:]]+A' /etc/bind/zones/db.$ZONE_BASE || \
  echo '<client> IN A $SERVER_IP' >> /etc/bind/zones/db.$ZONE_BASE"
```

## Esborrar / renombrar el registre

```bash
remote "sed -i '/^<client>[[:space:]]\+IN[[:space:]]\+A/d' /etc/bind/zones/db.$ZONE_BASE"
```

Després d'afegir o esborrar registres, incrementa el serial de la SOA i
recarrega.

## Validar i recarregar

```bash
remote "named-checkzone $ZONE_BASE /etc/bind/zones/db.$ZONE_BASE"
remote "rndc reload $ZONE_BASE"
```

## Comprovacions

```bash
dig +short <client>.$ZONE_BASE @$SERVER_IP
dig +short <client>.$ZONE_BASE @$SERVER_IP A
remote "systemctl is-active named || systemctl is-active bind9"
```

## Errors típics

* **named-checkzone failed:** sintaxi de la zona (punt final, parèntesis, serial).
* **rndc: connect failed:** `named` no escolta o `rndc.key` incorrecte.
* **SERVFAIL:** la zona no està declarada o el fitxer no és llegible per `bind`.
* **Resolució incorrecta:** serial de la SOA no incrementat o caché del resolutor.
