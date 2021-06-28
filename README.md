# Seedbox

A collection of Dockerfiles and a docker-compose configuration to set up a
seedbox and personal media server.

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

The front-end reverse proxy (Traefik - **check the next section if you have already the seedbox with Traefik v1**) routes based on the lowest level subdomain
 (e.g. `deluge.example.com` would route to deluge). Since this is how the router
works, it is recommended for you to get a top level domain. If you do not have
one, you can edit your domains locally by changing your hosts file or use a
browser plugin that changes the host header.

Traefik takes care of valid Let's Encrypt certificates and auto-renewal.

Note: Plex is also available directly through the `32400` port without going
through the reverse proxy.

## September 2020 - Upgrade to Traefik v2 instructions

Before upgrading Traefik to version 2, please check the following:

- In this repo, Traefik v2 upgrade is as seamless as possible (same environment variables than before, out-of-the-box config file...).
- **First, ``git pull`` to grab the latest code.**
- The ``HTTP_PASSWORD`` variable now must be simple-quoted in the .env file. See the updated ``.env.sample`` file (which has also been reorganized)
- Run ``init.sh`` in order to create required Docker objects (network name has changed).
- You can update your acme.json to a Traefik v2-compliant one by doing the following (before launching Traefik v2):

```sh
mkdir -p /tmp/migration
cd /tmp/migration
sudo cp /opt/traefik/acme.json .
sudo chmod 775 /tmp/migration/acme.json
# Do *NOT* forget the --resolver at the end! (le = Let's Encrypt resolver, see traefik/traefik.yml)
docker run --rm -v ${PWD}:/data -w /data containous/traefik-migration-tool acme -i acme.json -o acme2.json --resolver le
mkdir -p /data/config/traefik
sudo cp acme2.json /data/config/traefik/acme.json
sudo chmod 600 /data/config/traefik/acme.json
# When you already have a backup!
sudo rm -rf /opt/traefik /tmp/migration
```

- As from Traefik v2, as Http Authentication is now possible on the Traefik console, the latter is enabled at ``traefik.yourdomain.com``.
- After all this, you can simply do: ``./update-all.sh``! Voilà!

## Dependencies

- [Docker](https://github.com/docker/docker) >= 20.10
- [Docker Compose](https://github.com/docker/compose) >= 1.28.0
- [local-persist Docker plugin](https://github.com/MatchbookLab/local-persist): installed directly on host (not in container). This is a volume plugin that extends the default local driver’s functionality by allowing you specify a mountpoint anywhere on the host, which enables the files to always persist, even if the volume is removed via `docker volume rm`. Use *systemd* install for Ubuntu 16.04.

## Configuration

Before running, please create the volumes which will be statically mapped to the ones on the host:

```sh
sudo su -c "mkdir /data && mkdir /data/config && mkdir /data/torrents"
./init.sh
```

Edit the `.env` file and change the variables as desired.
The variables are all self-explanatory.

**NEW**
You can also disable a service if you do not need it by editing the ``services.conf`` file.
Simply change the "*enable*" key with the "*disable*" one for the service you want to disable.
If you remove a line in this file, it will be considered as "enabled" as all services are enabled by default.

## Running & updating

```sh
./update-all.sh
```

docker-compose should manage all the volumes and network setup for you. If it
does not, verify that your docker and docker-compose version is updated.

Make sure you install the dependencies and finish configuration before doing
this.

## PlexPass

Just set the `VERSION` environment variable to `latest` on the Plex service (enabled by default).
See https://hub.docker.com/r/linuxserver/plex.

## Where is my data?

All data is saved in the docker volumes `seedbox_config` or
`seedbox_torrents`.
These volumes are mapped to the `config` and `torrents` folders located in `/data` on the host. You can change these static paths in the docker-compose.yml file.
Thanks to the **local-persist** Docker plugin, the data located in these volumes is persistent, meaning that volumes are not deleted, even when using the ```docker-compose down``` command. It would be a shame to loose everything by running a simple docker command ;-)
