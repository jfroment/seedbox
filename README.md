# Seedbox

A collection of Dockerfiles and a docker-compose configuration to set up a
seedbox and personal media server.

⚠️ Version 2 is released, please make sure you read [this V2 Migration Guide](doc/UPGRADE_V2.md) as there are breaking changes!

## Included Applications

| Application          | Web Interface              | Docker image                                                           | Version (image tag) | Notes               |
-----------------------|----------------------------|------------------------------------------------------------------------|-------------------------|---------------------|
| Plex                 | plex.yourdomain.com        | [linuxserver/plex](https://hub.docker.com/r/linuxserver/plex)          | *latest*                | Media Streaming     |
| Deluge               | deluge.yourdomain.com      | [linuxserver/deluge](https://hub.docker.com/r/linuxserver/deluge)      | *latest*                | Torrents downloader |
| Flood               | flood.yourdomain.com      | [jesec/flood](https://hub.docker.com/r/jesec/flood)      | *latest*      | Web client for Deluge (experimental) |
| Sonarr               | sonarr.yourdomain.com      | [linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr)      | *develop*               | TV Shows monitor    |
| Radarr               | radarr.yourdomain.com      | [linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr)      | *develop*                | Movies monitor      |
| Bazarr               | bazarr.yourdomain.com      | [linuxserver/bazarr](https://hub.docker.com/r/linuxserver/bazarr)      | *latest*                | Subtitles monitor   |
| Lidarr               | lidarr.yourdomain.com      | [linuxserver/lidarr](https://hub.docker.com/r/linuxserver/lidarr)      | *develop*               | Music monitor       |
| Readarr               | readarr.yourdomain.com      | [linuxserver/readarr](https://hub.docker.com/r/linuxserver/readarr)      | *nightly*               | Ebook and comic monitor       |
| Komga               | komga.yourdomain.com      | [gotson/komga](https://hub.docker.com/r/gotson/komga)      | *latest*               | Comic Book Manager       |
| Kavita               | Kavita.yourdomain.com      | [gotson/komga](https://hub.docker.com/r/gotson/komga)      | *latest*               | Comic Book Manager       |
| Ombi               | ombi.yourdomain.com      | [linuxserver/ombi](https://hub.docker.com/r/linuxserver/ombi)      | *latest*               | Plex content requests       |
| Overseerr               | overseerr.yourdomain.com      | [linuxserver/overseerr](https://hub.docker.com/r/linuxserver/overseerr)      | *latest*               | Plex content requests       |
| Jackett              | jackett.yourdomain.com     | [linuxserver/jackett](https://hub.docker.com/r/linuxserver/jackett)    | *latest*                | Tracker indexer     |
| Prowlarr              | prowlarr.yourdomain.com     | [linuxserver/prowlarr](https://hub.docker.com/r/linuxserver/prowlarr)    | *develop*                | Tracker indexer |
| JDownloader          | jdownloader.yourdomain.com | [jlesage/jdownloader-2](https://hub.docker.com/r/jlesage/jdownloader-2)| *latest*                | Direct downloader   |
| Tautulli (plexPy)    | tautulli.yourdomain.com    | [linuxserver/tautulli](https://hub.docker.com/r/linuxserver/tautulli)  | *latest*                | Plex stats and admin|
| Tdarr            | tdarr.yourdomain.com   | [haveagitgat/tdarr](https://hub.docker.com/r/haveagitgat/tdarr)  | *latest*                | Re-encode files |
| NextCloud            | nextcloud.yourdomain.com   | [linuxserver/nextcloud](https://hub.docker.com/r/linuxserver/nextcloud)  | *latest*                | Files management    |
| NextCloud-db (MariaDB) | not reachable   | [mariadb](https://hub.docker.com/r/_/mariadb)  | *10*                | DB for Nextcloud    |
| Portainer            | portainer.yourdomain.com   | [portainer/portainer](https://hub.docker.com/r/portainer/portainer)    | *latest*                | Container management|
| Netdata              | netdata.yourdomain.com     | [netdata/netdata](https://hub.docker.com/r/netdata/netdata)            | *latest*                | Server monitoring   |
| Duplicati            | duplicati.yourdomain.com   | [linuxserver/duplicati](https://hub.docker.com/r/linuxserver/duplicati)| *latest*                | Backups             |
| Heimdall            | yourdomain.com   | [linuxserver/heimdall](https://hub.docker.com/r/linuxserver/heimdall)| *latest*                | Main dashboard      |
| Gluetun            | -   | [qmcgaw/gluetun](https://hub.docker.com/r/qmcgaw/gluetun)| *latest*                | VPN client             |

The front-end reverse proxy (Traefik - **check [this guide](doc/traefik_v2.md) if you still have the seedbox with Traefik v1**)  routes based on the lowest level subdomain (e.g. `deluge.example.com` would route to deluge). Since this is how the router works, it is recommended for you to get a top level domain. If you do not have one, you can edit your domains locally by changing your hosts file or use a browser plugin that changes the host header.

Traefik takes care of valid Let's Encrypt certificates and auto-renewal.

Note: Plex is also available directly through the `32400` port without going through the reverse proxy.

## Dependencies

- [Docker](https://github.com/docker/docker) >= 20.10
- [Docker Compose](https://github.com/docker/compose) >= 2.2
- [local-persist Docker plugin](https://github.com/MatchbookLab/local-persist): installed directly on host (not in container). This is a volume plugin that extends the default local driver’s functionality by allowing you specify a mountpoint anywhere on the host, which enables the files to always persist, even if the volume is removed via `docker volume rm`. Use *systemd* install for Ubuntu.
- [jq](https://stedolan.github.io/jq/download/) >= 1.5
- [yq](https://github.com/mikefarah/yq/releases) > 4

## Set up for the first time

Before running, please create the volumes which will be statically mapped to the ones on the host:
For example:

```sh
sudo su -c "mkdir /data && mkdir /data/config && mkdir /data/torrents"
./init.sh
```

Edit the `.env` file and change the variables as desired.
The variables are all self-explanatory.

## Configuration

The configuration lives in the ``config.yaml`` file.

All you need to know is located in the [Configuration Guide](doc/configuration.md).

## Running & updating

```sh
./run-seedbox.sh
```

All services and synamic configuration will be automatically created without further action from your part.

Make sure you install the dependencies and finish configuration before doing this.

## PlexPass

Just set the `VERSION` environment variable to `latest` on the Plex service (enabled by default).
See [this link](https://hub.docker.com/r/linuxserver/plex).

## Where is my data?

All data is saved in the docker volumes `seedbox_config` or
`seedbox_torrents`.
These volumes are mapped to the `config` and `torrents` folders located in `/data` on the host. You can change these static paths in the docker-compose.yml file.
Thanks to the **local-persist** Docker plugin, the data located in these volumes is persistent, meaning that volumes are not deleted, even when using the ```docker-compose down``` command. It would be a shame to loose everything by running a simple docker command ;-)
