#!/bin/sh

echo "[$0] Loading variables..."
source .env

echo "[$0] Installing nextcloud..."
docker exec -it -u abc -w /config/www/nextcloud \
  nextcloud bash -c " \
    php occ maintenance:install \
      --database \"mysql\" \
      --database-host  \"nextcloud-db\" \
      --database-name \"${MYSQL_DATABASE}\" \
      --database-user \"${MYSQL_USER}\" \
      --database-pass \"${MYSQL_PASSWORD}\" \
      --admin-user \"${NEXTCLOUD_ADMIN_USER}\" \
      --admin-pass \"${NEXTCLOUD_ADMIN_PASSWORD}\" \
      --admin-email \"${ACME_MAIL}\" \
      --data-dir \"/data\" \
  "

echo "[$0] Done."