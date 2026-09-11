---
name: mysql
description: Use when creating or querying the pureftpd MySQL/MariaDB database for virtual FTP users, applying the users table schema, inserting/updating clients, changing status or password hashes, or checking the database connection. Covers the exact users table and mysql client commands.
---

# Skill: MySQL/MariaDB

Base de dades dels usuaris virtuals de PureFTPD.

## Esquema exacte

Base `pureftpd`, taula `users`:

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

## Executar SQL remot

```bash
remote "mysql -u pureftpd -p'<password>' pureftpd -e \"...\""
```

> La contrasenya de MySQL **no** s'ha de posar mai a la línia de comandes en
> producció (queda a l'historial i a `ps`). Usa un `~/.my.cnf` remot amb permisos
> `600`, creat per `/install`, i executa `mysql pureftpd -e "..."`.

## Crear l'usuari de base de dades i la taula (idempotent)

```sql
CREATE DATABASE IF NOT EXISTS pureftpd;
CREATE USER IF NOT EXISTS 'pureftpd'@'localhost' IDENTIFIED BY '<password>';
GRANT ALL PRIVILEGES ON pureftpd.* TO 'pureftpd'@'localhost';
FLUSH PRIVILEGES;
```

## Alta o actualització d'un client (idempotent)

```sql
INSERT INTO users (User, Password, Uid, Gid, Dir, status)
VALUES ('<client>', '<hash>', 2001, 2001, '/var/www/<client>/htdocs', 'active')
ON DUPLICATE KEY UPDATE
  Password = VALUES(Password),
  Dir      = VALUES(Dir),
  status   = VALUES(status);
```

## Canvi de contrasenya

```sql
UPDATE users SET Password = '<hash>' WHERE User = '<client>';
```

## Habilitar / deshabilitar

```sql
UPDATE users SET status = 'disabled' WHERE User = '<client>';
UPDATE users SET status = 'active'   WHERE User = '<client>';
```

## Renombrar

```sql
UPDATE users SET User = '<nou>', Dir = '/var/www/<nou>/htdocs' WHERE User = '<antic>';
```

## Esborrar

```sql
DELETE FROM users WHERE User = '<client>';
```

## Comprovacions

```bash
remote "mysql pureftpd -N -e \"SELECT User, Dir, status FROM users;\""
remote "mysql pureftpd -N -e \"SELECT status FROM users WHERE User='<client>';\""
```

## Errors típics

* **Access denied for user 'pureftpd':** credencials o permisos incorrectes.
* **Table 'pureftpd.users' doesn't exist:** falta executar `/install`.
* **Duplicate entry:** usa sempre `INSERT ... ON DUPLICATE KEY UPDATE`.
* **Dir amb propietari incorrecte:** l'usuari FTP ha de poder-hi escriure
  (chroot); revisa `chown`/`chmod` del directori.
