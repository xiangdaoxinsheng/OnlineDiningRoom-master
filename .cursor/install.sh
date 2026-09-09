#!/usr/bin/env bash
# Idempotent repository bootstrap: build the WAR, initialize the database, and
# deploy to Tomcat. Safe to run repeatedly (against fresh or cached state).
set -euo pipefail

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH="$JAVA_HOME/bin:$PATH"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Building WAR with Maven (JDK 8)"
mvn -q -B -DskipTests clean package

echo "==> Ensuring MariaDB is initialized and running"
sudo mkdir -p /run/mysqld
sudo chown -R mysql:mysql /run/mysqld /var/lib/mysql
if [ ! -d /var/lib/mysql/mysql ]; then
    sudo mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi
if ! sudo mysqladmin ping >/dev/null 2>&1; then
    sudo -b bash -c 'mysqld_safe --datadir=/var/lib/mysql >/tmp/mariadb-install.log 2>&1'
    for _ in $(seq 1 60); do
        sudo mysqladmin ping >/dev/null 2>&1 && break
        sleep 1
    done
fi

echo "==> Configuring root credentials and database (matches src/main/resources/jdbc.properties)"
# On a fresh datadir root uses unix_socket auth; after the first run it uses the password.
if sudo mysql -e "SELECT 1" >/dev/null 2>&1; then
    MYSQL_ADMIN=(sudo mysql)
else
    MYSQL_ADMIN=(mysql -uroot -p123456)
fi
"${MYSQL_ADMIN[@]}" <<'SQL'
ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('123456');
CREATE DATABASE IF NOT EXISTS onlinediningroom DEFAULT CHARACTER SET utf8;
FLUSH PRIVILEGES;
SQL

echo "==> Importing schema and seed data if the database is empty"
if ! mysql -uroot -p123456 -e "USE onlinediningroom; SELECT 1 FROM product LIMIT 1;" >/dev/null 2>&1; then
    mysql -uroot -p123456 onlinediningroom < "src/main/resources/mybatis/sql(1).sql"
fi

echo "==> Seeding a known admin account (admin / admin123) for local development"
if ! mysql -uroot -p123456 onlinediningroom -N -e "SELECT 1 FROM user WHERE name='admin' LIMIT 1;" | grep -q 1; then
    mysql -uroot -p123456 onlinediningroom <<'SQL'
INSERT INTO user (name, password, salt, status, address, phone, lasttime)
VALUES ('admin', '97d846f9058cc15a8f4547316ab68b04', 'testsalt123', 1, 'campus', '000', NOW());
INSERT INTO user_role (uid, rid) SELECT id, 1 FROM user WHERE name='admin';
SQL
fi

echo "==> Deploying WAR to Tomcat (ROOT context)"
sudo rm -rf /opt/tomcat9/webapps/ROOT /opt/tomcat9/webapps/ROOT.war
cp target/OnlineDiningRoom.war /opt/tomcat9/webapps/ROOT.war

echo "==> install.sh complete"
