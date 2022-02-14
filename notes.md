# Nextcloud-db has moved

Since commit e4ede925a8ce09b177206f30487a889da9e10334, nextcloud-db directory (mapped on /var/lib/mysql) has moved from
``/data/nextcloud-db`` to ``$HOST_CONFIG_PATH/nextcloud-db`` (*/data/config/nextcloud-db by default*).

To ensure a smooth transition, you will have to move the directory nextcloud-db into the correct new location, then run some commands to fix the schema:

```sh
mv /data/nextcloud-db/ /data/config/
./update-all.sh
source .env
docker exec -it nextcloud-db mysql_upgrade -u root -p${MYSQL_ROOT_PASSWORD}
docker restart nextcloud nextcloud-db
```

Ensure everything runs nicely by looking at nextcloud-db and nextcloud logs, and by accessing your Nextcloud web UI.
