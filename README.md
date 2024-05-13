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
  * Tweak any service to your need by using custom file parameter on any service
* VPN support with multiple providers
  * Hide the service(s) of your choice behind a VPN tunnel
  * Non mandatory
* Declarative configuration
* Persistent data for your media
* Install & update using the same script
* Start with the [Configuration Guide](doc/configuration.md)

## ⚠️ News

Version 2 is released, please make sure you read [this V2 Migration Guide](doc/UPGRADE_V2.md) as there are breaking changes!

## 📦 Included Applications

| Application          | Web Interface              | Docker image                                                           | Version (image tag) | Notes               |
-----------------------|----------------------------|------------------------------------------------------------------------|-------------------------|---------------------|
| Plex                 | plex.yourdomain.com        | [linuxserver/plex](https://hub.docker.com/r/linuxserver/plex)          | *latest*                | Media Streaming     |
| Deluge               | deluge.yourdomain.com      | [linuxserver/deluge](https://hub.docker.com/r/linuxserver/deluge)      | *latest*                | Torrents downloader |
| Flood               | flood.yourdomain.com      | [jesec/flood](https://hub.docker.com/r/jesec/flood)      | *latest*      | Web client for Deluge (experimental) |
| qBitTorrent | qbittorrent.yourdomain.com          | [hotio/qbittorrent](cr.hotio.dev/hotio/qbittorrent)    | *latest* | Torrents downloader + VuTorrent alternative WebUI built-in |
| Sonarr               | sonarr.yourdomain.com      | [linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr)      | *develop*               | TV Shows monitor    |
| Radarr               | radarr.yourdomain.com      | [linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr)      | *develop*                | Movies monitor      |
| Bazarr               | bazarr.yourdomain.com      | [linuxserver/bazarr](https://hub.docker.com/r/linuxserver/bazarr)      | *latest*                | Subtitles monitor   |
| Lidarr               | lidarr.yourdomain.com      | [linuxserver/lidarr](https://hub.docker.com/r/linuxserver/lidarr)      | *develop*               | Music monitor       |
| Readarr               | readarr.yourdomain.com      | [linuxserver/readarr](https://hub.docker.com/r/linuxserver/readarr)      | *nightly*               | Ebook and comic monitor       |
| Calibre | calibre-admin.yourdomain.com | [linuxserver/calibre](https://hub.docker.com/r/linuxserver/calibre)  | *latest* | eBook management |
| Calibre-web | calibre.yourdomain.com | [linuxserver/calibre-web](https://hub.docker.com/r/linuxserver/calibre-web)  | *nightly* | Book management UI |
| Komga               | komga.yourdomain.com      | [gotson/komga](https://hub.docker.com/r/gotson/komga)      | *latest*               | Comic Book Manager       |
| Kavita               | Kavita.yourdomain.com      | [linuxserver/kavita](https://docs.linuxserver.io/images/docker-kavita/)      | *latest*               | Comic Book Manager       |
| Ombi               | ombi.yourdomain.com      | [linuxserver/ombi](https://hub.docker.com/r/linuxserver/ombi)      | *latest*               | Plex content requests       |
| Overseerr               | overseerr.yourdomain.com      | [linuxserver/overseerr](https://hub.docker.com/r/linuxserver/overseerr)      | *latest*               | Plex content requests       |
| Jackett              | jackett.yourdomain.com     | [linuxserver/jackett](https://hub.docker.com/r/linuxserver/jackett)    | *latest*                | Tracker indexer     |
| Prowlarr              | prowlarr.yourdomain.com     | [linuxserver/prowlarr](https://hub.docker.com/r/linuxserver/prowlarr)    | *develop*                | Tracker indexer |
| JDownloader          | jdownloader.yourdomain.com | [jlesage/jdownloader-2](https://hub.docker.com/r/jlesage/jdownloader-2)| *latest*                | Direct downloader   |
| Tautulli (plexPy)    | tautulli.yourdomain.com    | [linuxserver/tautulli](https://hub.docker.com/r/linuxserver/tautulli)  | *latest*                | Plex stats and admin |
| ntfy | ntfy.yourdomain.com    | [binwiederhier/ntfy](https://hub.docker.com/r/binwiederhier/ntfy)  | *latest*                | Notifications manager |
| Tdarr            | tdarr.yourdomain.com   | [haveagitgat/tdarr](https://hub.docker.com/r/haveagitgat/tdarr)  | *latest*                | Re-encode files |
| NextCloud            | nextcloud.yourdomain.com   | [linuxserver/nextcloud](https://hub.docker.com/r/linuxserver/nextcloud)  | *latest*                | Files management    |
| NextCloud-db (MariaDB) | *not reachable*   | [mariadb](https://hub.docker.com/r/_/mariadb)  | *10*                | DB for Nextcloud    |
| Filebrowser | files.yourdomain.com | [filebrowser/filebrowser](https://hub.docker.com/r/filebrowser/filebrowser)  | *s6*                | Files explorer  |
| Paperless-ngx  | paperless.yourdomain.com | [paperless-ngx/paperless-ngx](ghcr.io/paperless-ngx/paperless-ngx) | *latest* | Documents management and archiving (**BETA**) |
| Portainer            | portainer.yourdomain.com   | [portainer/portainer](https://hub.docker.com/r/portainer/portainer)    | *latest*                | Container management|
| Netdata              | netdata.yourdomain.com     | [netdata/netdata](https://hub.docker.com/r/netdata/netdata)            | *latest*                | Server monitoring   |
| Duplicati            | duplicati.yourdomain.com   | [linuxserver/duplicati](https://hub.docker.com/r/linuxserver/duplicati)| *latest*                | Backups             |
| Heimdall            | yourdomain.com   | [linuxserver/heimdall](https://hub.docker.com/r/linuxserver/heimdall)| *latest*                | Main dashboard      |
| Homarr            | homarr.yourdomain.com   | [ajnart/homarr](https://ghcr.io/ajnart/homarr)| *latest*                | Main dashboard (alt)     |
| Homepage            | homepage.yourdomain.com   | [gethomepage/homepage](ghcr.io/gethomepage/homepage)| *latest*                | Main dashboard (alt)     |
| Syncthing         | syncthing.yourdomain.com |  [linuxserver/syncthing](https://hub.docker.com/r/linuxserver/syncthing) | *latest* | P2P files sharing |
| Traefik | traefik.yourdomain.com | [traefik](https://hub.docker.com/_/traefik) | *latest* | Traefik reverse proxy (access to admin dashboard) |
| Gluetun            | -   | [qdm12/gluetun](https:/ghcr.io/qdm12/gluetun)| *latest*                | VPN client             |
| *Any application you want!* | *whatever.yourdomain.com* | *Any image* | *Any tag* | *Any service - See the [Configuration Guide](doc/configuration.md)* |

## 🌐 Traefik

The front-end reverse proxy (Traefik - **check [this guide](doc/traefik_v2.md) if you still have the seedbox with Traefik v1**)  routes based on the lowest level subdomain (e.g. `deluge.example.com` would route to deluge). Since this is how the router works, it is recommended for you to get a top level domain. If you do not have one, you can edit your domains locally by changing your hosts file or use a browser plugin that changes the host header.

Traefik takes care of valid Let's Encrypt certificates and auto-renewal.

Note: Plex is also available directly through the `32400` port without going through the reverse proxy.

You can also add your own Traefik rules to integrate with other services (deployed wihthin docker or somewhere else on your LAN, or even on the Internet).
Check the [Configuration Guide](doc/configuration.md).

## ⚙️ Installation

### Dependencies

- [Docker](https://github.com/docker/docker) >= 20.10
- [Docker Compose](https://github.com/docker/compose) >= 2.27.0
- [local-persist Docker plugin](https://github.com/MatchbookLab/local-persist): installed directly on host (not in container). This is a volume plugin that extends the default local driver’s functionality by allowing you specify a mountpoint anywhere on the host, which enables the files to always persist, even if the volume is removed via `docker volume rm`. Use *systemd* install for Ubuntu.
- [jq](https://stedolan.github.io/jq/download/) >= 1.5
- [yq](https://github.com/mikefarah/yq/releases) >= 4

### Prepare your host

Before running, please create the volumes which will be statically mapped to the ones on the host:
For example:

```sh
sudo su -c "mkdir /data && mkdir /data/config && mkdir /data/torrents"
./init.sh
```

Edit the `.env` file and change the variables as desired.
The variables are all self-explanatory.

### Review the configuration

The configuration lives in the ``config.yaml`` file.

All you need to know is located in the [Configuration Guide](doc/configuration.md).

### Running & updating

```sh
./run-seedbox.sh
```

All services and synamic configuration will be automatically created without further action from your part.

Make sure you install the dependencies and finish configuration before doing this.

### Where is my data?

All data is saved in the docker volumes `seedbox_config` or
`seedbox_torrents`.
These volumes are mapped to the `config` and `torrents` folders located in `/data` on the host. You can change these static paths in the docker-compose.yml file.
Thanks to the **local-persist** Docker plugin, the data located in these volumes is persistent, meaning that volumes are not deleted, even when using the ```docker-compose down``` command. It would be a shame to loose everything by running a simple docker command ;-)

# Configure your apps

- Some indications here (more to come): [Apps Configuration](doc/configuration.md#apps-configuration)
- [TRaSH Guides](https://trash-guides.info/)