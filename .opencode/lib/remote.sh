#!/usr/bin/env bash
#
# .opencode/lib/remote.sh
#
# Llibreria de suport de l'arnés d'opencode per administrar un servidor Debian
# remot via SSH. NO és una aplicació independent ni una CLI: és una col·lecció
# de funcions que l'agent carrega dins d'una shell per executar les operacions
# remotes de manera homogènia i segura.
#
# Ús típic:
#   set -a; . ./inventory.env; set +a
#   source .opencode/lib/remote.sh
#   remote "systemctl status nginx"
#
# Totes les operacions remotes han de passar per `remote()`. No s'han
# d'escriure comandes `ssh` ad-hoc a les skills ni a les comandes.

set -euo pipefail

# ---------------------------------------------------------------------------
# Inventari
# ---------------------------------------------------------------------------

# Carrega inventory.env (per defecte a l'arrel) i valida les claus.
arnes_load_inventory() {
    local inv="${1:-inventory.env}"
    if [[ ! -f "$inv" ]]; then
        echo "ERROR: no s'ha trobat l'inventari '$inv'." >&2
        echo "       Copia inventory.env.example a inventory.env i omple'l." >&2
        return 1
    fi
    set -a
    # shellcheck disable=SC1090
    . "$inv"
    set +a
    arnes_validate_inventory
}

# Comprova que hi hagi les claus obligatòries i aplica els valors per defecte.
arnes_validate_inventory() {
    local missing=0 var
    for var in SSH_HOST SSH_USER ZONE_BASE SERVER_IP; do
        if [[ -z "${!var:-}" ]]; then
            echo "ERROR: la variable '$var' no està definida a l'inventari." >&2
            missing=1
        fi
    done
    [[ "$missing" -eq 0 ]] || return 1
    : "${SSH_PORT:=22}"
    : "${SSH_SUDO:=1}"
    : "${WEB_ROOT:=/var/www}"
    : "${BACKUP_DIR:=/var/backups/arnes}"
    : "${LOG_FILE:=/var/log/arnes/operations.log}"
    export SSH_PORT SSH_SUDO WEB_ROOT BACKUP_DIR LOG_FILE
}

# ---------------------------------------------------------------------------
# Wrapper SSH
# ---------------------------------------------------------------------------

_arnes_ssh_opts() {
    ARNES_SSH_OPTS=(-p "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=accept-new)
    ARNES_SCP_OPTS=(-P "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=accept-new)
    if [[ -n "${SSH_KEY:-}" ]]; then
        ARNES_SSH_OPTS=(-i "$SSH_KEY" "${ARNES_SSH_OPTS[@]}")
        ARNES_SCP_OPTS=(-i "$SSH_KEY" "${ARNES_SCP_OPTS[@]}")
    fi
}

# remote <comanda>
# Executa una comanda al servidor remot. Si SSH_SUDO=1 s'executa amb
# `sudo -n` (no interactiu). Retorna el codi de sortida de la comanda remota.
remote() {
    local cmd="$1"
    local escaped
    escaped="$(printf '%s' "$cmd" | sed "s/'/'\\\\''/g")"
    _arnes_ssh_opts
    if [[ "${SSH_SUDO:-1}" == "1" ]]; then
        ssh "${ARNES_SSH_OPTS[@]}" "$SSH_USER@$SSH_HOST" \
            "sudo -n bash -lc '$escaped'"
    else
        ssh "${ARNES_SSH_OPTS[@]}" "$SSH_USER@$SSH_HOST" \
            "bash -lc '$escaped'"
    fi
}

# remote_upload <fitxer_local> <ruta_remota>
# Puja un fitxer al servidor remot. Per a destinacions propietat de root,
# puja primer a /tmp i després mou amb remote().
remote_upload() {
    local src="$1" dest="$2"
    if [[ ! -f "$src" ]]; then
        echo "ERROR: fitxer local no trobat: $src" >&2
        return 1
    fi
    _arnes_ssh_opts
    scp "${ARNES_SCP_OPTS[@]}" "$src" "$SSH_USER@$SSH_HOST:$dest"
}

# ---------------------------------------------------------------------------
# Validacions i utilitats
# ---------------------------------------------------------------------------

# Comprova la connectivitat SSH i l'accés sudo. Atura-se amb missatge clar.
arnes_check_connection() {
    if ! remote "echo ok" >/dev/null 2>&1; then
        echo "ERROR: no es pot connectar a $SSH_USER@$SSH_HOST:$SSH_PORT via SSH." >&2
        echo "       Comprova l'inventari, la clau SSH i que el servidor sigui accessible." >&2
        return 1
    fi
}

# Valida un nom de client (vàlid com a etiqueta DNS i com a usuari FTP).
arnes_validate_client_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z][a-z0-9-]{1,62}$ ]]; then
        echo "ERROR: nom de client invàlid '$name'." >&2
        echo "       Ha de complir ^[a-z][a-z0-9-]{1,62}$ (minúscules, xifres i guions)." >&2
        return 1
    fi
}

# Genera una contrasenya segura de 24 caràcters.
arnes_gen_password() {
    openssl rand -base64 24 | tr -d '/+=' | cut -c1-24
}

# Calcula el hash MD5 crypt que espera PureFTPD (MYSQLCrypt md5).
arnes_hash_password() {
    local pass="$1"
    openssl passwd -1 -salt "$(openssl rand -hex 4)" "$pass"
}

# arnes_deploy_welcome <client>
# Desplega la pàgina de benvinguda per defecte a
# $WEB_ROOT/<client>/htdocs/index.html (propietat www-data:www-data, 644).
# La plantilla canònica viu a .opencode/templates/welcome.html i s'envia
# codificada en base64 perquè el contingut (cometes, $, accents) no xoqui
# amb l'escapament de remote(). Substitueix els placeholders __CLIENT__ i
# __DOMAIN__ pel nom del client i el seu domini. Idempotent.
arnes_deploy_welcome() {
    local client="$1"
    local tpl
    tpl="$(cd "$(dirname "${BASH_SOURCE[0]}")/../templates" 2>/dev/null && pwd)/welcome.html"
    if [[ ! -f "$tpl" ]]; then
        tpl=".opencode/templates/welcome.html"
    fi
    if [[ ! -f "$tpl" ]]; then
        echo "ERROR: plantilla de benvinguda no trobada ($tpl)." >&2
        return 1
    fi
    local html b64
    html="$(sed -e "s/__CLIENT__/$client/g" -e "s/__DOMAIN__/$client.$ZONE_BASE/g" "$tpl")"
    b64="$(printf '%s' "$html" | base64 -w0)"
    remote "mkdir -p '$WEB_ROOT/$client/htdocs' && printf '%s' '$b64' | base64 -d > '$WEB_ROOT/$client/htdocs/index.html' && chown www-data:www-data '$WEB_ROOT/$client/htdocs/index.html' && chmod 644 '$WEB_ROOT/$client/htdocs/index.html'"
}

# Afegeix una línia de traçabilitat a LOG_FILE al servidor remot.
# Format: ISO8601 <TAB> operacio <TAB> client <TAB> resultat
arnes_log() {
    local op="$1" client="${2:--}" result="${3:--}"
    local ts
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    remote "mkdir -p '$(dirname "$LOG_FILE")' && printf '%s\t%s\t%s\t%s\n' '$ts' '$op' '$client' '$result' >> '$LOG_FILE'"
}
