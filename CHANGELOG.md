# v2.2 (The Flame 🔥)

## What's new?

### New services 💫

* ``qBittorrent``: [Torrends downloader](https://github.com/qbittorrent/qBittorrent)
  * Use of ``hotio`` build ([documentation here](https://hotio.dev/containers/qbittorrent/)) with VueTorrent and native VPN support (for those who want to avoid gluetun configuration)
  * Use of qBittorrent is recommended over Deluge as the project is more active and its alternative UI setup is easier (no separate container).
* ``Filebrowser``: [Lightweight filebrowser](https://github.com/filebrowser/filebrowser)
* ``Homarr``: [Dashboard](https://github.com/ajnart/homarr)
* ``Homepage``: [Dashboard](https://github.com/gethomepage/homepage) (fix #54)
* ``Mylar``: [Comic Book downloader](https://github.com/mylar3/mylar3)
* ``ntfy``: [Push notifications for your services](https://github.com/binwiederhier/ntfy)
* ``Paperless-ngx``: [Documents management](https://github.com/paperless-ngx/paperless-ngx)

### New features ✨

* Set app-specific environment variables in a dedicated files to load them only for the targeted application.
  See [the documentation](doc/configuration.md#environment-variables) for more details on how it works.
  **Now every app customization is possible**.
* Support Traefik Custom ACME resolver (Cloudflare, OVH, you-name-it...)
  See the [corresponding documentation](doc/traefik.md) to use it.
* Support remote NFS storage for media. Just replace your ``docker-compose.yaml`` by the one in the [samples](samples/docker-compose.sample.nfs.yaml) directory (keep the same ``docker-compose.yaml`` filename). See the [configuration guide section](doc/configuration.md#media-on-nfs-server) to configure properly.

## Bugfixes and improvements ⚙️

* **Gluetun (vpn)**
  * Use ghcr.io image
  * Add ``/dev/net/tun`` mount to container
  * Use non-depracated environment variables
* **Kavita (ebook library management)**
  * Use LinuxServer image and adapt accordingly. Update should be seamless.
* **Overseerr**
  * Use public dns to workaround network issues
* **Plex**
  * Remove useless port bindings as ``network_mode`` is ``host`` for Plex.
* Cleanup old files, refactoring
* Add ``local-persist driver`` installation in init script. It contains a fix which is not (yes) published on the Github official repository.
* Fix ``komga`` default port in config.yaml sample file.
* Docker compose supported version is now at least ``2.27.0``.
* Fix #43: fix warning for jq and output format.
* Refactor ``run-seedbox.sh`` script (use of functions, move code around, tiny fixes...)
* Due to newly added app-specific environment variables, gluetun VPN config and install mode has been refined. Please see the [documentation](doc/configuration.md#vpn) for specific details.

## ⚠️ Config changes ⚠️

### Nextcloud and DB

MariaDB is now a separate service, and nextcloud is still dependant on it.
In order to enable ``mariadb`` service, either refer to ``config.sample.yaml`` or add the following to your ``config.yaml`` file:

```yaml
# [...]
  - name: mariadb
    enabled: true
    vpn: false
    traefik:
      enabled: false
      rules: []
# [...]
```

### Variables

Due to the refactoring of the app-specific variables (by using ``.env.custom`` file), some old variables present  in ``.env`` must be moved to ``.env.custom`` and prefixed with the service name.

> The ``run-seedbox.sh`` script will detect obsolete configuration in .env and will notify yo and stop to prevent config errors.

If the following variables are present (not commented not absent) in your ``.env`` file, copy it in the new ``.env.custom`` file (either copy the value by using the placeholder already in place in the new file or overriding completely the file).

| Variable in **.env**  | Variable in **.env.custom** |
|---|---|
| Variables starting by ``MYSQL_`` | Add prefix ``MARIADB_`` |
| Variables starting by ``NEXTCLOUD_``| Add **another** ``NEXTCLOUD_`` prefix |
| Variables starting by ``PAPERLESS_`` | Add **another** ``PAPERLESS_`` prefix |
| Variables starting by ``PORTAINER_``| Add **another** ``PORTAINER_`` prefix |
| Variable named ``FLOOD_PASSWORD`` | ``FLOOD_FLOOD_PASSWORD`` |
| Variable named ``CALIBRE_PASSWORD`` | ``CALIBRE_CALIBRE_PASSWORD`` |
| Variable named ``WIREGUARD_ENDPOINT`` | ``GLUETUN_VPN_ENDPOINT_IP`` |
| Variable named ``WIREGUARD_PORT`` | ``GLUETUN_VPN_ENDPOINT_PORT`` |
| Variable named ``WIREGUARD_PUBLIC_KEY`` | ``GLUETUN_WIREGUARD_PUBLIC_KEY`` |
| Variable named ``WIREGUARD_PRIVATE_KEY`` | ``GLUETUN_WIREGUARD_PRIVATE_KEY`` |
| Variable named ``WIREGUARD_PRESHARED_KEY`` | ``GLUETUN_WIREGUARD_PRESHARED_KEY`` |
| Variable named ``WIREGUARD_ADDRESS`` | ``GLUETUN_WIREGUARD_ADDRESSES`` (**plural!**) |

# v2.1 (The Pearl ⚪)

## What's new?
- Plex is now in host network mode. You can safely ignore warnings when Plex image is updated. With host mode, you'll be able to distinct local vs remote connections to Plex in Tautulli (and in Plex dashboard) if your server is at home.
- New services available: [Calibre](https://github.com/linuxserver/docker-calibre) + [Calibre-web](https://github.com/linuxserver/docker-calibre-web) added. They are disabled by default.

## Fixes

- Fix typo in gluetun PGID variable
- Documentation wording edits (thanks again @tromcho)
- Fix #24: now you can add .torrent files in deluge again
- Fix #37: Portainer port + explanation for password generation in .env.sample file
- Fix #32: Now you can specify which ``docker compose`` binary to use. Useful when using ``docker-compose`` binary, even for v2. Defaults to "docker-compose" for retro-compatibility purposes. Please check [.env.sample](.env.sample).
- Fix #20: New documentation in [doc/apps/deluge-flood.md](doc/apps/deluge-flood.md) to explain how deluge must be configured for Flood to work.
- Remove Traefik pilot token, as the feature has been removed from Traefik itself.

# v2.0 (The Swan 🦢)

**Seedbox version 2 is here!** 🔥

Since there are some breaking changes and a configuration structure migration, a major version was mandatory.

## What's new?

* **Configuration change to new YAML format**
  * Run ``config-updater.sh`` to migrate your old services.conf to the new config.yaml format.
  * ⚠️ ``jq`` (v1.5+) and ``yq`` (v4+) are now requirements
  * Easier feature switches
  * If a service is missing, it won't be enabled by default like before. The config is now more declarative.
  * Traefik routing rules are now dynamically generated in a file in Traefik config directory, so no more Docker labels. They became hard to maintain due to all possibilities caused by VPN support or custom files for example.
  * New config syntax documented in the [Configuration Guide](doc/configuration.md#configuration-structure-and-parameters).
* **VPN support**
  * With ``gluetun`` service, you can now place any service behind a VPN.
  * Default gluetun configuration is Wireguard "custom" mode, but see below...
  * More details in the [VPN section of the Configuration Guide](doc/configuration.md#vpn).
* **Support custom services and docker-compose yaml files**
  * Place a docker-compose yaml file in ``services/custom/`` directory, add a service in your config.yaml specifying a ``customFile``, and you are set.
  * Support Plex hardware transcoding using a custom-file, already available in the ``services`` directory (just specify a ``customFile`` on plex service - see [config.sample.yaml](config.sample.yaml)).
  * More details in the [Configuration Guide](doc/configuration.md#add-your-own-service).
* **Support arbitrary Traefik rules**
  * Place a Traefik YAML in ``samples/custom-traefik/`` directory, it will be copied in the Traefik configuration folder.
  * Ideal to forward traffic to other services which do not belong to this seedbox.
  * More details in [this section of the Configuration Guide](doc/configuration.md#integration-with-other-services-custom-traefik-config)
* **Disable certificates for some domains**
  * Using the flag ``httpOnly: true`` on a service, access any service in unsecure mode, delegating certificates management on a higher level (reverse proxy, firewall...). More details in the [Configuration Guide](doc/configuration.md#disable-https-completely).
* **Multiple hosts for any services**
  * The new config structure allows for more customization, for example you can now have many routes on the same service. Let's say, a local unsecured route + a secured one for remote access. Or anything you want.
* **More customization**
  * Such as http authentication which is no more hardcoded but configurable for each service.
  * Configurable paths on host for persistent data
* **New services**
  * ``Gluetun``: [VPN client (see above)](https://github.com/qdm12/gluetun)
  * ``Heimdall``: [Dashboard](https://github.com/linuxserver/Heimdall)
  * ``Readarr``: [Ebook and comic monitor](https://github.com/Readarr/Readarr)
  * ``Komga``: [Comic Book Manager](https://github.com/gotson/komga)
  * ``Kavita``: [Comic / Book Manager](https://github.com/Kareadita/Kavita)
  * ``Syncthing``: [P2P files synchronization](https://github.com/linuxserver/docker-syncthing)
* ⚠️ Docker compose v2.2+ is now required

And also:

* ``update-all.sh`` is now called ``run-seedbox.sh`` but its purpose is the same.
* More checks in ``run-seedbox.sh``. For example, throws an error if Flood is enabled but not Deluge, or if VPN is enabled on a service but the VPN client is not.
* You can now specify where your data lives on your host through new environments variables (see [.env.sample](.env.sample)).
  * This change is backward-compatible as the ``run-seedbox.sh`` script will default to the old "/data/torrents" and "/data/config" paths if these variables are not set.
* ``networks:`` section is now aligned with the new docker compose syntax
* ⚠️ Nextcloud-db has moved. It is now in ``/data/config`` (or somewhere else if you set the new variables for host paths) (see below how to mitigate the errors). [See the dedicated section below](#nextcloud-db-has-moved).
* Disable Traefik access logs
* New flag ``--debug`` for ``run-seedbox.sh`` to see what is happening during configuration parsing.
* Releases are named after LOST mythology. I exhausted all the characters of Person of Interest, so that's time for a change. Only geeks will get it, I know.

## Some reading about configuration

📖 Do not forget to read the [Configuration Guide](doc/configuration.md).

## How to migrate

```sh
./config-updater.sh
# Check the content of your .env file (in comparison with .env.sample which brings new variables)
# Also, check your generated config.yaml and read the config documentation (in doc/configuration.md)
./run-seedbox.sh
```

When everything runs smoothly, you can delete your old configuration file which is now useless:

```sh
rm -f services.conf
```

> ⚠️ Also, please make sure you have read the next section about Nextcloud Database location.

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

# v1.5 (Carl Elias)

## Changes

- **Prowlarr is set to develop branch**

## Fixes and improvements

- Fix docker-compose timeout variable
- JDownloader now always restarts (align behavior with all services)
- Tiny improvements on Nextcloud
  - Fix startup command
  - New script *update-nextcloud.sh* to update to latest sources and perform Nextcloud upgrades

# v1.4 (Jocelyn Carter)

## New

- **Add Ombi** (disabled by default)
- **Add Overseer**
- **Add Prowlarr** (alternative to Jackett with *arr softwares indexers auto-sync) (*still in alpha*)
- **Add Flood UI** for Deluge (connects directly to Deluge daemon). It is still experimental. Beware of new environment variables in **.env.sample**, used to set password for Deluge RPC connection and (optional) auto-creation of the Deluge "flood" daemon user.
A ``sudo chown -R ${PUID}:${PGUID} /data/config/flood`` should be done if permissions are not correctly set when starting flood (see its logs).
- services.conf file is now per-user, so in this repository there is only the sample file now. Existing services.conf files will be retained, so there should be no impact for users. A warning is now displayed if there is a new service in services.conf.sample to alert users about a configuration "drift" between their file and the "upstream" one.

## Improvements

- Add ``--no-pull`` flag to ``update-all.sh`` script, which skips the pull step. Useful when configuring/debugging/recreating containers.
- Netdata tag is now "**stable**", and Docker socket is mounted as read-only.

# v1.3 (Samantha Groves)

## New

- Sonarr and Lidarr are now on tag *develop*
- Tdarr is now v2 only, all configuration has moved and no procedure to migrate v1 config exist.

## Improvements

- Fix Nextcloud init script
- Fix typos

# v1.2 (Lionel Fusco)

## New

- Use ghcr.io as registry when possible to limit DockerHub rate limits
- Add FlareSolverr to bypass Cloudflare protection with some Jackett indexers
- Possibility to disable each service separately. See README.md

## Improvements

- Netdata: enable new metrics by mapping more host volumes
- Split docker-compose.yml into separate YAML files. Now easier to use, hack and maintain.
- Explicit tag on Tdarr, as v2 is out and migration is not done yet.

## Warning

- Docker-compose 1.28+ is now required.
- After upgrading, all containers will be recreated. No data will be lost. It is due to the new file structure.

# v1.1 (Sameen Shaw)

Maintenance release with the following changes:

- Added [Tdarr](https://github.com/HaveAGitGat/Tdarr) service
- Nextcloud now uses Linuxserver.io image, and has its own database (MariaDB).
- Radarr updated to V3 (channel is now develop)
- Traefik rules and labels a bit simplified (entrypoint declaration is now global for example)

# v1.0 (Harold Finch)

After Traefik 2 update, here's the first milestone.

Initial changelog:
- Traefik v2 with configuration through environment only (config files work out-of-the-box)
- Automatic Let's Encrypt certificates creation and renewal. Launch it and forget it!
- Persistent storage (by using ``local-persist`` docker plugin)
  - For media/downloads
  - For configuration files (easier to backup)
- Shared HTTP authentication for services which have no build-in login enabled by default
- Traefik console enabled and secured by default
- Global HTTP to HTTPS redirection
- Permissions mapping by the use of GID/UID environment variables in containers
- Easy to install: see README.md
- Easy to update
  - ``git pull``
  - ``./update-all.sh``
- All is hackable
