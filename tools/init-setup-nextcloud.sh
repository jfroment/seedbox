#!/bin/sh

echo "[$0] Loading variables..."
source .env

echo "[$0] Installing nextcloud..."
docker exec -it -u abc -w /config/www/nextcloud \
  nextcloud bash -c " \
    php occ maintenance:install \
      --database \"mysql\" \
      --database-host \"${MYSQL_DATABASE}\" \
      --database-name \"nextcloud-db\" \
      --database-user \"${MYSQL_USER}\" \
      --database-pass \"${MYSQL_PASSWORD}\" \
      --admin-user \"${NEXTCLOUD_ADMIN_USER}\" \
      --admin-pass \"${NEXTCLOUD_ADMIN_PASSWORD}\" \
      --admin-email \"${ACME_MAIL}\" \
      --data-dir \"/data\" \
  "

echo "[$0] Done."