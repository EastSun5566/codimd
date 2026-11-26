#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -gt 0 ]]; then
    exec "$@"
fi

pgroot=/data/postgres
export PGHOST=127.0.0.1 PGPORT=5432 PGUSER=hackmd

app_pid=
pg_pid=
staging=
cleanup() {
    trap '' TERM INT
    if [[ -n "$app_pid" ]]; then
        kill -TERM "$app_pid" 2>/dev/null || true
        wait "$app_pid" || true
    fi
    if [[ -n "$pg_pid" ]]; then
        kill -INT "$pg_pid" 2>/dev/null || true
        wait "$pg_pid" || true
    fi
    if [[ -n "$staging" ]]; then
        rm -rf -- "$staging"
    fi
}
trap cleanup EXIT
trap 'exit 0' TERM INT

mkdir -p /data/uploads
if [[ ! -e "$pgroot" ]]; then
    staging=$(mktemp -d /data/.postgres.XXXXXX)
    node -p 'require("node:crypto").randomBytes(32).toString("hex")' > "$staging/password"
    initdb -D "$staging/data" --username="$PGUSER" --auth-local=peer --auth-host=scram-sha-256 --pwfile="$staging/password"
    mv -T "$staging" "$pgroot"
    staging=
fi
export PGPASSWORD CMD_DB_URL
PGPASSWORD=$(cat "$pgroot/password")
CMD_DB_URL="postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/codimd"

if [[ -z "${CMD_SESSION_SECRET:-}" ]]; then
    if [[ ! -s /data/session-secret ]]; then
        staging=$(mktemp /data/.session-secret.XXXXXX)
        node -p 'require("node:crypto").randomBytes(64).toString("hex")' > "$staging"
        mv -T "$staging" /data/session-secret
        staging=
    fi
    export CMD_SESSION_SECRET
    CMD_SESSION_SECRET=$(cat /data/session-secret)
fi

postgres -D "$pgroot/data" -c "listen_addresses=$PGHOST" -c "unix_socket_directories=" -p "$PGPORT" &
pg_pid=$!
for ((attempt = 0; attempt < 60; attempt++)); do
    if pg_isready -q -d postgres; then
        break
    fi
    kill -0 "$pg_pid"
    sleep 1
done
pg_isready -q -d postgres
database_exists=$(psql -XAt -d postgres -c "SELECT 1 FROM pg_database WHERE datname = 'codimd'")
if [[ "$database_exists" != 1 ]]; then
    createdb codimd
fi

codimd-entrypoint &
app_pid=$!
wait -n "$pg_pid" "$app_pid"
