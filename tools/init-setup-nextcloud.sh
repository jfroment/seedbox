#!/bin/bash

# First installation of Nextcloud: to run once, when the "nextcloud" and "mariadb" containers are up
# (both services enabled in config.yaml, then ./run-seedbox.sh).

set -e

cd "$(dirname "$0")/.."
source tools/tools.sh
check_utilities

for f in services/mariadb/custom/service.env services/nextcloud/custom/service.env; do
  if [[ ! -f $f ]]; then
    echo "[$0] ERROR. $f not found. Enable \"mariadb\" and \"nextcloud\" in config.yaml and run ./run-seedbox.sh first."
    exit 1
  fi
done

echo "[$0] Loading variables..."
# Database variables are the ones of mariadb, admin account the one of nextcloud (see their service.env files)
ENV_VARS=$(read_env_files .env services/mariadb/custom/service.env services/nextcloud/custom/service.env)
for var in MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD NEXTCLOUD_ADMIN_USER NEXTCLOUD_ADMIN_PASSWORD ACME_MAIL; do
  printf -v "${var}" '%s' "$(env_value ${var} "${ENV_VARS}")"
  if [[ -z ${!var} ]]; then
    echo "[$0] ERROR. Variable ${var} is not set. Check .env and the service.env files of mariadb and nextcloud."
    exit 1
  fi
done

echo "[$0] Installing nextcloud..."
docker exec -it -u abc -w /config/www/nextcloud \
  nextcloud bash -c " \
    php occ maintenance:install \
      --database \"mysql\" \
      --database-host  \"mariadb\" \
      --database-name \"${MYSQL_DATABASE}\" \
      --database-user \"${MYSQL_USER}\" \
      --database-pass \"${MYSQL_PASSWORD}\" \
      --admin-user \"${NEXTCLOUD_ADMIN_USER}\" \
      --admin-pass \"${NEXTCLOUD_ADMIN_PASSWORD}\" \
      --admin-email \"${ACME_MAIL}\" \
      --data-dir \"/data\" \
  "

echo "[$0] Done."
