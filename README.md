<h1 align="center">Seedbox</h1>
  <p align="center">
    An extensive and hackable collection of containerized services to set up a seedbox and personal media server.
  </p>
<br>

## ✨ Features

* Easy to configure personal media server without needing too much technical skills
* Compatible with multiple systems (Linux servers, desktops, Synology NAS...)
* Automatic HTTPS ceritificates management and renewal
  * Support for HTTP only too if required for your use-case
* Everything is hackable
  * Add your own services
  * Disable the ones you do not want
  * Customize or add your own routing rules to integrate with existing services
  * Tweak any service to your need with an override file, without touching the bundled one
  * Everything you change lives in your own files, ignored by git: updates never conflict with your changes (see [Your files and the files of the project](doc/configuration.md#your-files-and-the-files-of-the-project))
* VPN support with multiple providers
  * Hide the service(s) of your choice behind a VPN tunnel
  * Non mandatory
* Declarative configuration
* Persistent data for your media
* Install & update using the same script
* Start with the [Configuration Guide](doc/configuration.md)

## ⚠️ News

Version 3 is released: a much shorter configuration and all your customizations in your own files, safe from updates. Migration is automatic, but please read [this V3 Migration Guide](doc/UPGRADE_V3.md) as there are breaking changes!

Still on version 1? Upgrade to v2.2.2 first (``git checkout v2.2.2``), with the [V2 Migration Guide](doc/UPGRADE_V2.md).

## 📦 Included Applications

| Application          | Web Interface              | Docker image                                                           | Version (image tag) | Notes               |
-----------------------|----------------------------|------------------------------------------------------------------------|-------------------------|---------------------|
| Plex                 | - (port 32400 of the host) | [linuxserver/plex](https://hub.docker.com/r/linuxserver/plex)          | *latest*                | Media Streaming, see [documentation](doc/apps/plex.md) |
| Deluge               | deluge.yourdomain.com      | [linuxserver/deluge](https://hub.docker.com/r/linuxserver/deluge)      | *latest*                | Torrents downloader |
| Flood               | flood.yourdomain.com      | [jesec/flood](https://hub.docker.com/r/jesec/flood)      | *latest*      | Web client for Deluge (experimental) |
| qBitTorrent | qbittorrent.yourdomain.com          | [hotio/qbittorrent](https://hotio.dev/containers/qbittorrent/)    | *latest* | Torrents downloader + VuTorrent alternative WebUI built-in |
| Sonarr               | sonarr.yourdomain.com      | [linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr)      | *develop*               | TV Shows monitor    |
| Radarr               | radarr.yourdomain.com      | [linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr)      | *develop*                | Movies monitor      |
| Bazarr               | bazarr.yourdomain.com      | [linuxserver/bazarr](https://hub.docker.com/r/linuxserver/bazarr)      | *latest*                | Subtitles monitor   |
| Lidarr               | lidarr.yourdomain.com      | [linuxserver/lidarr](https://hub.docker.com/r/linuxserver/lidarr)      | *develop*               | Music monitor       |
| Calibre | calibre-admin.yourdomain.com | [linuxserver/calibre](https://hub.docker.com/r/linuxserver/calibre)  | *latest* | eBook management |
| Calibre-web | calibre.yourdomain.com | [linuxserver/calibre-web](https://hub.docker.com/r/linuxserver/calibre-web)  | *nightly* | Book management UI |
| Komga               | komga.yourdomain.com      | [gotson/komga](https://hub.docker.com/r/gotson/komga)      | *latest*               | Comic Book Manager       |
| Kavita               | Kavita.yourdomain.com      | [linuxserver/kavita](https://docs.linuxserver.io/images/docker-kavita/)      | *latest*               | Comic Book Manager       |
| Seerr               | seerr.yourdomain.com      | [seerr-team/seerr](https://ghcr.io/seerr-team/seerr)      | *latest*               | Plex content requests       |
| Jackett              | jackett.yourdomain.com     | [linuxserver/jackett](https://hub.docker.com/r/linuxserver/jackett)    | *latest*                | Tracker indexer     |
| FlareSolverr | - | [flaresolverr/flaresolverr](https://ghcr.io/flaresolverr/flaresolverr) | *latest* | Proxy to bypass Cloudflare protection for Jackett / Prowlarr indexers |
| Prowlarr              | prowlarr.yourdomain.com     | [linuxserver/prowlarr](https://hub.docker.com/r/linuxserver/prowlarr)    | *develop*                | Tracker indexer |
| JDownloader          | jdownloader.yourdomain.com | [jlesage/jdownloader-2](https://hub.docker.com/r/jlesage/jdownloader-2)| *latest*                | Direct downloader   |
| Mylar3          | mylar.yourdomain.com | [linuxserver/mylar3](https://lscr.io/linuxserver/mylar3)| *latest*                | Comics manager |
| Tautulli (plexPy)    | tautulli.yourdomain.com    | [linuxserver/tautulli](https://hub.docker.com/r/linuxserver/tautulli)  | *latest*                | Plex stats and admin |
| ntfy | ntfy.yourdomain.com    | [binwiederhier/ntfy](https://hub.docker.com/r/binwiederhier/ntfy)  | *latest*                | Notifications manager |
| Tdarr            | tdarr.yourdomain.com   | [haveagitgat/tdarr](https://hub.docker.com/r/haveagitgat/tdarr)  | *latest*                | Re-encode files |
| NextCloud            | nextcloud.yourdomain.com   | [linuxserver/nextcloud](https://hub.docker.com/r/linuxserver/nextcloud)  | *latest*                | Files management    |
| NextCloud-db (MariaDB) | *not reachable*   | [mariadb](https://hub.docker.com/r/_/mariadb)  | *10*                | DB for Nextcloud    |
| Filebrowser | files.yourdomain.com | [filebrowser/filebrowser](https://hub.docker.com/r/filebrowser/filebrowser)  | *s6*                | Files explorer  |
| Paperless-ngx  | paperless.yourdomain.com | [paperless-ngx/paperless-ngx](https://ghcr.io/paperless-ngx/paperless-ngx) | *latest* | Documents management and archiving (**BETA**) |
| Netdata              | - (port 19999 of the host) | [netdata/netdata](https://hub.docker.com/r/netdata/netdata)            | *latest*                | Server monitoring   |
| Duplicati            | duplicati.yourdomain.com   | [linuxserver/duplicati](https://hub.docker.com/r/linuxserver/duplicati)| *latest*                | Backups             |
| Heimdall            | yourdomain.com   | [linuxserver/heimdall](https://hub.docker.com/r/linuxserver/heimdall)| *latest*                | Main dashboard      |
| Homepage            | homepage.yourdomain.com   | [gethomepage/homepage](https://ghcr.io/gethomepage/homepage)| *latest*                | Main dashboard (alt)     |
| Syncthing         | syncthing.yourdomain.com |  [linuxserver/syncthing](https://hub.docker.com/r/linuxserver/syncthing) | *latest* | P2P files sharing |
| Jellyfin | jellyfin.yourdomain.com | [linuxserver/jellyfin](https://hub.docker.com/r/linuxserver/jellyfin) | *latest* | Media Streaming |
| Actual Budget | budget.yourdomain.com | [actualbudget/actual-server](https://ghcr.io/actualbudget/actual-server) | *latest* | Personal finance |
| Mealie | mealie.yourdomain.com | [mealie-recipes/mealie](https://ghcr.io/mealie-recipes/mealie) | *latest* | Recipes manager |
| Stirling PDF | pdf.yourdomain.com | [stirlingtools/stirling-pdf](https://hub.docker.com/r/stirlingtools/stirling-pdf) | *latest* | PDF tools |
| BentoPDF | bentopdf.yourdomain.com | [alam00000/bentopdf-simple](https://ghcr.io/alam00000/bentopdf-simple) | *latest* | PDF tools |
| Vaultwarden | vault.yourdomain.com | [dani-garcia/vaultwarden](https://ghcr.io/dani-garcia/vaultwarden) | *latest* | Passwords manager |
| VaulTLS | vaultls.yourdomain.com | [7ritn/vaultls](https://ghcr.io/7ritn/vaultls) | *latest* | Client certificates (mTLS) management, see [documentation](doc/apps/vaultls.md) |
| Dockhand | dockhand.yourdomain.com | [fnsys/dockhand](https://hub.docker.com/r/fnsys/dockhand) | *latest* | Container management, see [documentation](doc/apps/dockhand.md) |
| Wireguard | - | [linuxserver/wireguard](https://hub.docker.com/r/linuxserver/wireguard) | *latest* | VPN server |
| Netbird | netbird.yourdomain.com | [netbirdio/netbird-server](https://hub.docker.com/r/netbirdio/netbird-server) | *latest* | Mesh VPN and public reverse proxy with access control (**experimental**, see [documentation](doc/apps/netbird.md)) |
| Traefik | traefik.yourdomain.com | [traefik](https://hub.docker.com/_/traefik) | *latest* | Traefik reverse proxy (access to admin dashboard) |
| Gluetun            | -   | [qdm12/gluetun](https://ghcr.io/qdm12/gluetun)| *latest*                | VPN client             |
| *Any application you want!* | *whatever.yourdomain.com* | *Any image* | *Any tag* | *Any service - See the [Configuration Guide](doc/configuration.md)* |

## 🌐 Traefik

The front-end reverse proxy (Traefik) routes based on the lowest level subdomain (e.g. `deluge.example.com` would route to deluge). Since this is how the router works, it is recommended for you to get a top level domain. If you do not have one, you can edit your domains locally by changing your hosts file or use a browser plugin that changes the host header.

Traefik takes care of valid Let's Encrypt certificates and auto-renewal.

Note: Plex runs on the network of the host and is available directly through the `32400` port, without going through the reverse proxy. See [Plex documentation](doc/apps/plex.md) to publish it on `plex.yourdomain.com`.

You can also add your own Traefik rules to integrate with other services (deployed wihthin docker or somewhere else on your LAN, or even on the Internet).
Check the [Configuration Guide](doc/configuration.md).

## ⚙️ Installation

### Dependencies

- [Docker](https://github.com/docker/docker) >= 20.10
- [Docker Compose](https://docs.docker.com/compose/install/) >= 2.27.2, as a Docker plugin (``docker compose`` command). The old ``docker-compose`` binary is not supported anymore.
- [jq](https://stedolan.github.io/jq/download/) >= 1.5
- [yq](https://github.com/mikefarah/yq/releases) >= 4

### Prepare your host

Before running, create the directories which will hold your data (configuration of the services and media), and give them to your user. For example:

```sh
sudo mkdir -p /data/config /data/torrents && sudo chown -R $USER: /data
./init.sh
```

Edit the ``.env`` file and change the variables as desired. Some services also have their own variables (passwords...) in ``services/<name>/custom/service.env``: the script tells you which ones you have to set.
The variables are all self-explanatory.

### Review the configuration

The configuration lives in the ``config.yaml`` file: list the services you want, and change their default values only if you need to.

All you need to know is located in the [Configuration Guide](doc/configuration.md).

### Running & updating

```sh
./run-seedbox.sh
```

All services and dynamic configuration will be automatically created without further action from your part.

Make sure you install the dependencies and finish configuration before doing this.

Old Docker images pile up after updates. Set ``DOCKER_PRUNE_AFTER_UPDATE=true`` in your ``.env`` to remove unused images and volumes after each run. It is disabled by default because it applies to the whole host: images and volumes which do not belong to the seedbox are removed too.

### Where is my data?

Everything is stored in plain directories of your host, set in your ``.env`` file:

* ``HOST_CONFIG_PATH`` (``/data/config`` by default): the configuration and the data of each service, one directory per service (``/data/config/sonarr``, ``/data/config/Plex``...). This is what you want to back up.
* ``HOST_MEDIA_PATH`` (``/data/torrents`` by default): your media and downloads. It can also be a [NFS share](doc/configuration.md#media-on-nfs-server).

These directories are mounted as they are in the containers: Docker never deletes their content, whatever you do with the containers (``docker compose down``, ``docker volume prune``...). No Docker plugin is needed.

# Configure your apps

- Some indications here (more to come): [Apps Configuration](doc/configuration.md#apps-configuration)
- [TRaSH Guides](https://trash-guides.info/)
