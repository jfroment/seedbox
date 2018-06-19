# Seedbox
A collection of Dockerfiles and a docker-compose configuration to set up a
seedbox and personal media server.

## Credits
Main credits go to [Kelvin Chen](https://github.com/Kelvin-Chen/seedbox) who started the development of its own seedbox using Docker. Mine was first a fork of Kelvin's one, but I made some serious changes in the code and plan to add even more tools and services that keeping this project as a fork started to have less sense as code diverged.

## Accessing a Service's Web Interface
Go to `x.hostname` where `x` is the service you want to access.
Included services are:
- deluge
- sonarr
- jackett
- plex
- h5ai (service accessible via `explore.hostname`)
- radarr

The front-end reverse proxy (Traefik) routes based on the lowest level subdomain (e.g.
`deluge.example.com` would route to deluge). Since this is how the router
works, it is recommended for you to get a top level domain. If you do not have
one, you can edit your domains locally by changing your hosts file or use a
browser plugin that changes the host header.

Note: Plex is also available directly through the `32400` port without going
through the reverse proxy. You will have to sign in with your plex.tv account
if you do this.

## Dependencies
- [Docker](https://github.com/docker/docker) >= 1.13.0
    + Install guidelines for Ubuntu 16.04: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04
- [Docker Compose](https://github.com/docker/compose) >=v1.10.0
    + Install guidelines for Ubuntu 16.04: https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-16-04
- [local-persist Docker plugin](https://github.com/CWSpear/local-persist): installed directly on host (not in container). This is a volume plugin that extends the default local driver’s functionality by allowing you specify a mountpoint anywhere on the host, which enables the files to always persist, even if the volume is removed via `docker volume rm. Use *systemd* install for Ubuntu 16.04.

Before running, please create the volumes which will be statically mapped to the ones on the host:
```sh
$ sudo su -c "cd /; mkdir data; cd data; mkdir config; mkdir torrents"
```

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
Copy the `.env.sample` file to `.env` and change the variables as desired.
The variables are all self-explanatory.

## PlexPass
More info soon.

## Where is my data?
All data is saved in the docker volumes `seedbox_config` or
`seedbox_torrents`.
These volumes are mapped to the `config` and `torrents` folders located in `/data` on the host. You can change these static paths in the docker-compose.yml file.
Thanks to the **local-persist** Docker plugin, the data located in these volumes is persistent, meaning that volumes are not deleted, even when using the ```docker-compose down``` command. It would be a shame to loose everything by running a simple docker command ;-)
