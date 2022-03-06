# Upgrade to V2

Seedbox version 2 is here!
Since there are some breaking changes and a configuration structure migration, a major version was mandatory.

> These releases notes are still a work-in-progress as V2 is not fully tested and finalized yet.

## What's new?

* Configuration change to new YAML format
  * Run ``config-updater.sh`` to migrate your old services.conf to the new config.yaml format.
  * jq (v1.5+) and yq (v4+) are now requirements
  * Easier feature switches
  * If a service is missing, it won't be enabled by default like before. The config is now more declarative.
  * Traefik routing rules are now dynamically generated in a file in Traefik config directory, so no more Docker labels. They became hard to maintain due to all possibilities caused by VPN support or custom files for example.
* VPN support
  * With ``gluetun`` service, you can now place any service behind a VPN.
  * Default gluetun configuration is Wireguard "custom" mode, but see below...
* Support custom services and docker-compose yaml files
  * Place a docker-compose.yaml file in ``services/custom/`` directory, add a service in your config.yaml specifying a ``customFile``, and you are set.
  * Support Plex hardware transcoding using a custom-file, already available in the ``services`` directory (just specify a customFile on plex service - see [config.sample.yaml](config.sample.yaml)).
* Support arbitrary Traefik rules
  * Place a Traefik YAML in ``samples/custom-traefik/`` directory, it will be copied in the Traefik configuration folder.
  * Ideal to forward traffic to other services which do not belong to this seedbox.
* New services:
  * ``Gluetun``: [VPN client (see above)](https://github.com/qdm12/gluetun)
  * ``Heimdall``: [Dashboard](https://github.com/linuxserver/Heimdall)
  * ``Readarr``: [Ebook and comic monitor](https://github.com/Readarr/Readarr)
  * ``Komga``: [Comic Book Manager](https://github.com/gotson/komga)
  * ``Kavita``: [Comic / Book Manager](https://github.com/Kareadita/Kavita)

And also:

* ``update-all.sh`` is now called ``run-seedbox.sh`` but its purpose is the same.
* More checks in ``run-seedbox.sh``. For example, throws an error if Flood is enabled but not Deluge, or if VPN is enabled on a service but the VPN client is not.
* You can now specify where your data lives on your host through new environments variables (see [.env.sample](.env.sample)).
  * This change is backward-compatible as the run-seedbox.sh script will default to the old "/data/torrents" and "/data/config" paths if these variables are not set.
* ``networks:`` section is now aligned with the new docker compose syntax
* Nextcloud-db has moved. It is now in /data/config (see below how to mitigate the errors).
* Disable Traefik access logs

## How to migrate

```sh
./config-updater.sh
# Check the content of your .env file (in comparison with .env.sample which brings new variables)
./run-seedbox.sh
```

When everything runs smoothly, you can delete your old configuration file:

```sh
rm -f services.conf
```

> Also, please make sure you have read the next section about Nextcloud Database location.

## Nextcloud-db has moved

Since commit e4ede925a8ce09b177206f30487a889da9e10334, nextcloud-db directory (mapped on /var/lib/mysql) has moved from
``/data/nextcloud-db`` to ``$HOST_CONFIG_PATH/nextcloud-db`` (*/data/config/nextcloud-db by default*).

To ensure a smooth transition, you will have to move the directory nextcloud-db into the correct new location, then run some commands to fix the schema:

```sh
mv /data/nextcloud-db/ /data/config/
./run-seedbox.sh
source .env
docker exec -it nextcloud-db mysql_upgrade -u root -p${MYSQL_ROOT_PASSWORD}
docker restart nextcloud nextcloud-db
```

Ensure everything runs nicely by looking at nextcloud-db and nextcloud logs, and by accessing your Nextcloud web UI.
