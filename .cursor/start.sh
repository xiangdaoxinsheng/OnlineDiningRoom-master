#!/usr/bin/env bash
# Per-boot reconciliation: make sure MariaDB is running before Tomcat (the
# "tomcat" terminal) serves the app. Idempotent and returns once DB is ready.
set -euo pipefail

is_ready() { mysql -uroot -p123456 -e "SELECT 1" >/dev/null 2>&1; }

echo "==> Ensuring MariaDB is running"
sudo mkdir -p /run/mysqld
sudo chown mysql:mysql /run/mysqld
if ! is_ready; then
    sudo -b bash -c 'mysqld_safe --datadir=/var/lib/mysql >/tmp/mariadb.log 2>&1'
    for _ in $(seq 1 60); do
        is_ready && break
        sleep 1
    done
fi

if is_ready; then
    echo "==> MariaDB is ready"
else
    echo "!! MariaDB did not become ready" >&2
    exit 1
fi

echo "==> start.sh complete (Tomcat is launched by the 'tomcat' terminal)"
