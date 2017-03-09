# Seedbox
A collection of Dockerfiles and a docker-compose configuration to set up a
seedbox and personal media server.

## Accessing a Service's Web Interface
Go to `x.hostname` where `x` is the service you want to access.
Included services are:
- rtorrent
- deluge (supposed to replace rtorrent someday, seems to be more compatible with sonarr)
- sonarr
- jackett (included in the sonarr image)
- plex
- h5ai (service accessible via `explore.hostname`)

The front-end reverse proxy routes based on the lowest level subdomain (e.g.
`rtorrent.example.com` would route to rtorrent). Since this is how the router
works, it is recommended for you to get a top level domain. If you do not have
one, you can edit your domains locally by changing your hosts file or use a
browser plugin that changes the host header.

Note: Plex is also available directly through the `32400` port without going
through the reverse proxy. You will have to sign in with your plex.tv account
if you do this.

## Dependencies
- [Docker](https://github.com/docker/docker) >= 1.13.0
- [Docker Compose](https://github.com/docker/compose) >=v1.10.0

## Running
```sh
$ docker-compose pull
$ docker-compose up -d
```
docker-compose should manage all the volumes and network setup for you. If it
does not, verify that your docker and docker-compose version is updated.

Make sure you install the dependencies and finish configuration before doing
this.

You may optionally build the images yourself instead of pulling by running
`./build-all.sh`.

## Configuration
Copy the `config.default` file to `config` and change the variables as desired.
The variables are all self-explanatory.

If you want to enable SSL, you would need to have your certificate and key be
at `/config/frontend/ssl.crt` and `/config/frontend/ssl.key` respectively. The
frontend image includes a command `ssl-gen` to automatically create self signed
certificates for you.

## PlexPass
If you own PlexPass, you can get the docker image to auto-update to the latest
PlexPass version when the container starts up. This is arguably bad docker
practice since containers are supposed to be immutable, but in this case, I
think the convenience outweighs that. All you have to do is set the
`PLEX_EMAIL` and `PLEX_PASSWORD` variables in the config file.

## Where is my data?
All data are saved in the docker volumes `seedbox_config` or
`seedbox_torrents`.
You can also replace these docker volumes with static path if you want to
handle manually where files are stored on your server. You can do this by
editing the volumes settings in the `docker-compose.yml` file.
