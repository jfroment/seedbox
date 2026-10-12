# Seedbox configuration

## Table of content

* [General principles](#general-principles)
* [Configuration structure and parameters](#configuration-structure-and-parameters)
  * [config.yaml: your choices](#configyaml-your-choices)
  * [How rules are merged](#how-rules-are-merged)
  * [Default values of a service (service.yaml)](#default-values-of-a-service-serviceyaml)
* [Your files and the files of the project](#your-files-and-the-files-of-the-project)
  * [Templates](#templates)
* [Environment variables](#environment-variables)
  * [Global variables](#global-variables)
  * [Services variables](#services-variables)
* [Customize a bundled service](#customize-a-bundled-service)
  * [Static IP for a service](#static-ip-for-a-service)
* [Add your own service](#add-your-own-service)
  * [Particular case: Plex with Hardware Transcoding](#particular-case-plex-with-hardware-transcoding)
* [Integration with other services (custom Traefik config)](#integration-with-other-services-custom-traefik-config)
* [Configuration of Traefik itself](#configuration-of-traefik-itself)
* [Disable HTTPS completely](#disable-https-completely)
* [VPN](#vpn)
  * [Default mode - Wireguard custom](#default-mode---wireguard-custom)
  * [Your own mode (VPN provider supported by gluetun)](#your-own-mode-vpn-provider-supported-by-gluetun)
  * [How is VPN handled?](#how-is-vpn-handled)
* [Media on NFS server](#media-on-nfs-server)
* [Make the services communicate with each other](#make-the-services-communicate-with-each-other)
* [How does the configuration work?](#how-does-the-configuration-work)
* [Apps configuration](#apps-configuration)

## General principles

Every service (Plex, Sonarr, Jackett, Nextcloud...) is defined in a dedicated directory in the [services](../services/) directory, which contains its docker-compose file (``compose.yaml``) and, for some of them, other files such as specific Traefik rules (``rules.yaml``).

Each service comes with its own default values (routing rule such as ``sonarr.yourdomain.com``, http authentication, port, other services it needs...), written in its ``service.yaml``.

``config.yaml`` is where you choose which services run, and where you change these default values only if you need to. It is created from ``config.sample.yaml`` (see [Templates and your own files](#your-files-and-the-files-of-the-project)).

Then, all your "sensitive" (or "personal") data configuration (passwords, usernames, domain name, paths on the machine for persistent data...) is located in ``.env`` file.

When running ``./run-seedbox.sh``:

* ``.env`` is loaded
* ``config.yaml`` is parsed and completed with the default values of each service, some checks are performed
* For each service, if enabled, Traefik rules are generated ([see this section](#how-does-the-configuration-work)) dynamically
* docker-compose commands (pull, up...) are executed against all relevant files

## Configuration structure and parameters

> ``config.yaml`` format changed in v3. An existing v2 file is converted automatically on the first run: see the [V3 Migration Guide](UPGRADE_V3.md).

### config.yaml: your choices

A service runs as soon as it is listed in ``config.yaml``. Most of the time, its name is enough:

```yaml
services:
  # Enabled, with all its default values
  sonarr:
  # Listed but not started
  lidarr:
    enabled: false
  # Routed through the VPN. Service "gluetun" must be configured and enabled too.
  deluge:
    vpn: true
  gluetun:
  # Use another docker-compose file of the directory of the service (services/plex/) instead of compose.yaml
  plex:
    customFile: compose-hardware-transcoding.yaml
  # Not exposed through Traefik at all
  tautulli:
    traefik: false
  # Change some parameters of its default Traefik rule
  radarr:
    rules:
      - host: movies.${TRAEFIK_DOMAIN}
        httpAuth: false
```

All parameters of a service:

| Parameter | Default | Description |
|-----------|---------|-------------|
| ``enabled`` | ``true`` | Set to ``false`` to keep the service in the file without running it. |
| ``vpn`` | ``false`` | Route the service through the VPN client (``gluetun``, which must be enabled). See [VPN](#vpn). |
| ``customFile`` | ``compose.yaml`` | docker-compose file to use, relative to the directory of the service. |
| ``traefik`` | ``true`` | Set to ``false`` to disable Traefik routing for this service. |
| ``rules`` | Rules of the service | Traefik rules, see below. |

All parameters of a rule:

| Parameter | Default | Description |
|-----------|---------|-------------|
| ``host`` | | Host to match requests. Any environment variable is supported, as long as there are braces around it: ``sonarr.${TRAEFIK_DOMAIN}``. |
| ``internalPort`` | | Port of the service, inside its container, where requests are sent. |
| ``internalScheme`` | ``http`` | Set to ``https`` for services which only expose https (Nextcloud for example). |
| ``httpAuth`` | ``false`` | Enable http authentication (user and password of your ``.env`` file). |
| ``internalOnly`` | ``false`` | Only accessible from your LAN (private IP addresses). You should have a DNS server which answers to your ``TRAEFIK_DOMAIN`` in your LAN for it to work. |
| ``httpOnly`` | ``false`` | The rule only answers in plain http (port 80), without certificate and without redirection to https. See [Disable HTTPS completely](#disable-https-completely). Cannot be used with ``mtls``. |
| ``mtls`` | ``false`` | Only accessible by devices which own a client certificate you created. See [VaulTLS and client certificates](apps/vaultls.md). |
| ``service`` | | Traefik service to use instead of creating one for the container (example: ``api@internal`` for the Traefik dashboard). |

> Administration tools (Traefik dashboard, Dockhand, VaulTLS) have ``internalOnly: true`` in their default rule, as they give control over your server: they are not published on the Internet unless you write ``internalOnly: false`` yourself. Some services have no default rule at all because they use the network of the host (Plex, Netdata): see [Plex documentation](apps/plex.md).

Parameters are checked: ``run-seedbox.sh`` stops if your ``config.yaml`` contains a parameter which does not exist, so a typo (``interalOnly``...) cannot silently leave a service unprotected. They are described in [config.schema.json](../config.schema.json) (generated by ``tools/generate_schema.py``, to run again when a parameter is added): editors which support YAML schemas (VS Code with the YAML extension for example) use it for completion and validation, thanks to the first line of ``config.sample.yaml`` (``# yaml-language-server: $schema=./config.schema.json``, to copy at the top of your ``config.yaml`` if it is not there).

### How rules are merged

The rules you write in ``config.yaml`` are applied **on top of** the default rules of the service, in the same order: your first rule overrides the first default rule, your second rule the second one, and so on. In each rule, only the parameters you write are changed. If you write more rules than the service has, the additional ones are added.

With the default rule of Sonarr being ``host: sonarr.${TRAEFIK_DOMAIN}``, ``httpAuth: true``, ``internalPort: 8989``:

```yaml
services:
  sonarr:
    rules:
      # First rule: only the authentication is changed. Host and port are still the default ones.
      - httpAuth: false
      # Second rule: Sonarr has only one default rule, so this is a new one and it must be complete.
      - host: tv.${TRAEFIK_DOMAIN}
        internalPort: 8989
        internalOnly: true
```

If you want the same parameter on the rules of all services, use ``defaults`` instead of repeating it. It is applied after the default values of the services, and before what you write for each service:

```yaml
# Everything is only reachable from the LAN...
defaults:
  internalOnly: true

services:
  sonarr:
  radarr:
  # ...except Seerr
  seerr:
    rules:
      - internalOnly: false
```

### Default values of a service (service.yaml)

The default values of a service are in the ``service.yaml`` file of its directory (``services/<name>/service.yaml``):

```yaml
# Services which must be enabled too. The script stops with an error if one is missing.
requires:
  - mariadb
# Default Traefik rules (same parameters as in config.yaml). No rule = service not exposed through Traefik.
rules:
  - host: nextcloud.${TRAEFIK_DOMAIN}
    httpAuth: false
    internalPort: 443
    internalScheme: https
```

This file describes the service itself (which port its image listens on, which other service it needs). **Do not edit it**: like every file of the ``services`` directory, it is updated by ``git pull``. Everything it contains can be overridden in ``config.yaml``, which is the only place where you make your choices.

So, to sum up who does what:

| File | Content | Yours? |
|------|---------|--------|
| ``services/<name>/service.yaml`` | What the service is: default rules, dependencies | No, never edit it |
| ``config.yaml`` | What you want: enabled services, VPN, your changes on rules, ``defaults`` for all services | Yes |
| ``services/<name>/compose.yaml`` | How the container runs: image, volumes, environment... | No, never edit it |
| ``services/<name>/custom/compose.override.yaml`` | Your changes on how the container runs | Yes (see [Customize a bundled service](#customize-a-bundled-service)) |

Some general rules:

* In order to enable VPN (``vpn: true``) on a service, you must configure and enable gluetun service.
* By default, all services match "http://service_name:port" for routing.
* The name of a service in ``config.yaml`` is the name of its directory, and must be the name of the service in its docker-compose file.

## Your files and the files of the project

The rule is simple: **never edit a file tracked by git**. Everything you change is in files which are yours and ignored by git, so ``git pull`` never conflicts with your changes. For services, each directory of [services](../services/) can have a ``custom`` directory, which is yours: you see what you customized just by looking at the tree.

| What you want to do | Where |
|---------------------|-------|
| Choose your services, change their routing rules | ``config.yaml`` |
| Set your domain, paths, http authentication... | ``.env`` (see [Environment variables](#environment-variables)) |
| Set the passwords, keys and other variables of a service | ``services/<name>/custom/service.env`` (see [Environment variables](#environment-variables)) |
| Change how a bundled service runs (image, volumes, ports...) | ``services/<name>/custom/compose.override.yaml`` (see [Customize a bundled service](#customize-a-bundled-service)) |
| Add a service | ``services/<name>/custom/compose.yaml`` (see [Add your own service](#add-your-own-service)) |
| Add Traefik rules for something else | ``services/traefik/custom/rules/`` (see [Integration with other services](#integration-with-other-services-custom-traefik-config)) |
| Change the configuration of Traefik itself | ``services/traefik/custom/traefik.yaml``, ``middlewares.yaml`` and ``tls.yaml`` (see [Configuration of Traefik itself](#configuration-of-traefik-itself)) |

### Templates

Some of your files must exist with values which are specific to you. The project provides them as **templates**, files with ``.sample`` in their name. Your file is a copy of the template, created automatically:

| Template (in git) | Your file (ignored by git) | When the template changes |
|-------------------|----------------------------|---------------------------|
| ``.env.sample``, ``config.sample.yaml``, ``docker-compose.sample.yaml`` | ``.env``, ``config.yaml``, ``docker-compose.yaml`` | Your file is never modified, a warning is shown |
| ``services/<name>/*.sample.*`` (environment variables of the service, configuration files of Traefik or Netbird...) | ``services/<name>/custom/``, same name without ``.sample``. Only created when the service is enabled | Merged |
| ``docker-compose.nfs.sample.yaml`` | None: alternative to ``docker-compose.sample.yaml``, see [Media on NFS server](#media-on-nfs-server) | |

Files are created and updated by ``tools/sync-templates.sh``, which is called on each ``./run-seedbox.sh`` execution. When a "merged" template changes after an update:

* if you never edited your file, it is replaced by the new template
* if you edited it, the changes of the template are merged in your file and your own changes are kept (the previous version of your file is saved in ``.seedbox/backup/``)
* if the changes are in conflict with yours, your file is left untouched and a warning is shown. Do the merge manually, then tell the script it is done.

```sh
# See the state of each file (identical, customized, outdated...)
tools/sync-templates.sh status
# See the changes of the templates which are not applied yet, and your own changes
tools/sync-templates.sh diff
tools/sync-templates.sh diff services/traefik/custom/traefik.yaml
# After a manual merge, mark the changes of the template as applied
tools/sync-templates.sh accept services/traefik/custom/traefik.yaml
```

## Environment variables

Environment variables live in two kinds of files:

| File | Content |
|------|---------|
| ``.env`` | Global variables, common for the whole stack |
| ``services/<name>/custom/service.env`` | Variables of one service, given to its container only |

### Global variables

All variables related to the stack itself live in the ``.env`` file. They concern:

* Traefik configuration (domain name, ACME mail, http-auth credentials...)
* Disk UUID/GUID
* Timezone
* Paths on your system/network and directories to organize your data: each service stores its data in its own directory of ``HOST_CONFIG_PATH``, and media are in ``HOST_MEDIA_PATH``
* Behaviour of the script: ``DOCKER_PRUNE_AFTER_UPDATE=true`` removes unused Docker images and volumes after each run (disabled by default, as it applies to the whole host and not only to the seedbox)

> ``.env`` is read by Docker Compose, and the script asks Docker Compose for the values it needs instead of reading the file on its own: both always see the same values. So the syntax is the one of [Docker Compose env files](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/#env-file-syntax): keep single quotes around values which contain a ``$`` (like ``HTTP_PASSWORD``).

### Services variables

Variables specific for a service are located in two places:

* directly in the docker-compose file of the service (for example the one for [ntfy](../services/ntfy/compose.yaml)) under the ``environment:`` section. They are generic and do not contain sensitive information or customization.
* in **your** ``services/<name>/custom/service.env`` file: passwords, keys, and any variable you want to add or change for this service. Variables are written as the image of the service expects them, without any prefix.

*Example*: you want Sonarr to use the environment variable ``MYKEY`` with the value ``ImAwesome``. Create the file ``services/sonarr/custom/service.env`` with:

```sh
MYKEY=ImAwesome
```

Some services come with a ``service.sample.env`` file (see [Paperless](../services/paperless/service.sample.env) for example), which lists the variables they need or support:

* When you enable the service, your ``custom/service.env`` is created from this sample on the next ``./run-seedbox.sh`` (or ``tools/sync-templates.sh``) execution. Nothing is created for services you do not use.
* Variables with the value ``changeme`` are **required**: the script stops until you set them.
* Commented variables are **optional**: uncomment the ones you want.

> So, when you enable a new service: run ``tools/sync-templates.sh`` to see which files are created for it, edit them, then run ``./run-seedbox.sh``.

## Customize a bundled service

To change how a bundled service runs, do not edit its ``services/<name>/compose.yaml``. Create a ``services/<name>/custom/compose.override.yaml`` file with only what you want to change: it is merged on top of the file of the service (this is the standard [merge of Docker Compose](https://docs.docker.com/reference/compose-file/merge/)).

For example, to use another image tag for Sonarr and give it one more volume, create ``services/sonarr/custom/compose.override.yaml``:

```yaml
services:
  sonarr:
    image: ghcr.io/linuxserver/sonarr:latest
    volumes:
      - /mnt/other-disk:/other-disk
```

What you need to know about the merge:

* Single values (``image``, ``restart``...) are replaced by yours.
* Lists and maps (``volumes``, ``ports``, ``environment``, ``dns``...) are merged: your entries are added to the default ones.
* ``command`` and ``entrypoint`` are replaced as a whole: repeat the default arguments you want to keep.
* To remove a default value, use ``!reset``. To replace a list instead of adding to it, use ``!override``:

```yaml
services:
  seerr:
    # Remove the default dns servers
    dns: !reset []
    # Replace all the default ports
    ports: !override
      - "5056:5055"
```

If you just want to add environment variables to a service, you do not need this: see [Environment variables](#environment-variables).

Other files of your ``services/<name>/custom/`` directory **replace** the bundled file with the same name instead of being merged:

| Your file in ``services/<name>/custom/`` | Effect |
|------------------------------------------|--------|
| ``compose.override.yaml`` | Merged on top of the docker-compose file of the service |
| ``compose.yaml`` | Used instead of the bundled one (you do not get its updates anymore) |
| ``service.yaml`` | Default values used instead of the bundled ones |
| ``service.env`` | Your environment variables for the service, see [Environment variables](#environment-variables) |
| ``rules.yaml`` | Traefik config file used instead of the bundled one |
| Files with the name of a ``*.sample.*`` file of the service | Your copy of this template, see [Templates](#templates) |
| Any other docker-compose file | Can be selected with ``customFile`` in ``config.yaml`` |

Run ``./run-seedbox.sh --debug`` to see which files are used for each service.

### Static IP for a service

Containers get their IP dynamically. If a service needs a static one (for example Traefik when Netbird is used, as Netbird must trust the IP of Traefik), setting ``ipv4_address`` on this service is not enough: while its container is being recreated, its IP is free and another container can take it (``Address already in use`` error).

To avoid this without giving a static IP to every service, restrict the dynamic IPs to a part of the subnet in your ``docker-compose.yaml`` (the block is commented in ``docker-compose.sample.yaml``). The rest of the subnet is then only used by the static IPs you set:

```yaml
networks:
  default:
    name: "traefik-network"
    ipam:
      config:
        - subnet: 172.18.0.0/16
          gateway: 172.18.0.1
          # Dynamic IPs: 172.18.128.0 to 172.18.255.255. Everything below is kept for static IPs
          ip_range: 172.18.128.0/17
```

Then set the static IP, outside of ``ip_range``, in ``services/traefik/custom/compose.override.yaml``:

```yaml
services:
  traefik:
    networks:
      default:
        ipv4_address: 172.18.0.17
```

Docker cannot change the addresses of an existing network: it must be recreated, which stops all your services for a few minutes.

```sh
# Check the subnet of your network first, and use the same in docker-compose.yaml
docker network inspect traefik-network --format '{{json .IPAM.Config}}'
# Stop and remove all containers and the network (your data is not removed), then recreate everything
docker compose -p seedbox down
./run-seedbox.sh
```

## Add your own service

Let's say you want to add a container nginx without interfering or creating conflicts in this git repository. That's possible.

Start by creating the file ``services/nginx/custom/compose.yaml``. The directory is named like your service and, as it is your own service, it only contains a ``custom`` directory:

```yaml
services:
  nginx:
    image: nginx:latest
    container_name: nginx
    restart: unless-stopped
    volumes:
      # Its own data: a directory in the config directory of the seedbox, like bundled services
      - ${HOST_CONFIG_PATH}/nginx:/etc/nginx/conf.d
      # Your media, if it needs them: volumes defined in docker-compose.yaml (torrents, downloads, documents)
      - torrents:/usr/share/nginx/html/media:ro
    # ...
```

All variables of your ``.env`` file can be used. Directories are mounted as they are, and Docker never deletes their content. The ones of the config directory (``HOST_CONFIG_PATH``) which do not exist yet are created by ``run-seedbox.sh``, owned by the user of the containers (``PUID`` and ``PGID`` of your ``.env``).

Then, enable it in your ``config.yaml``:

```yaml
services:
  # ...
  nginx:
    rules:
      - host: nginx.${TRAEFIK_DOMAIN}
        httpAuth: false
        # 80 because official nginx image uses this port
        internalPort: 80
  # ...
```

You can also put the rules in a ``services/nginx/custom/service.yaml`` file, like bundled services do (see [Default values of a service](#default-values-of-a-service-serviceyaml)). Then ``nginx:`` alone is enough in ``config.yaml``:

```yaml
rules:
  - host: nginx.${TRAEFIK_DOMAIN}
    internalPort: 80
```

...and you're set! Just run ``./run-seedbox.sh`` to apply configuration changes.

If your service needs Traefik rules more advanced than what ``config.yaml`` offers, add a Traefik (dynamic) config file named ``rules.yaml`` next to its ``compose.yaml``: it is applied only when the service is enabled.

> If a bundled service has the same name, your ``compose.yaml`` is used instead of the bundled one: see [Customize a bundled service](#customize-a-bundled-service).

### Particular case: Plex with Hardware Transcoding

This project provides an alternative [compose-hardware-transcoding.yaml](../services/plex/compose-hardware-transcoding.yaml) file in the ``plex`` directory, with all the necessary adaptations to make Plex run with hardware transcoding enabled.

Just add the ``customFile: compose-hardware-transcoding.yaml`` field in the ``plex`` service and this file will be used, instead of the default "compose.yaml" (``customFile`` is relative to the directory of the service):

```yaml
services:
  # ...
  plex:
    # Here is the change: by default, without this parameter, the applied file is "compose.yaml"
    customFile: compose-hardware-transcoding.yaml
  # ...
```

Then, run ``./run-seedbox.sh`` to make these changes taken into account and the new container Plex will have hardware transcoding.

> Note that you also have to enable Hardware Transcoding in your Plex Server settings after the container has started.

More about Plex (how to reach it, how to publish it): see [Plex documentation](apps/plex.md).

## Integration with other services (custom Traefik config)

You can also add you own Traefik configuration to integrate with local services on your LAN.
Just put your Traefik configuration file in the [services/traefik/custom/rules/](../services/) directory.
All files will be copied in the Traefik configuration directory on each ``run-seedbox`` execution.
Example:

```yaml
http:
  routers:
    synology-admin:
      rule: 'Host(`synology-admin.{{ env "TRAEFIK_DOMAIN" }}`)'
      middlewares: 
        - common-auth@file
      service: admin
  services:
    synology-admin:
      loadBalancer:
        servers:
          - url: "https://your-nas-hostname-on-your-local-network:5001"
```

## Configuration of Traefik itself

Everything about Traefik is in ``services/traefik/``:

```
services/traefik/
  compose.yaml              # docker-compose file of Traefik
  service.yaml              # default rule (dashboard)
  traefik.sample.yaml       # templates of the configuration of Traefik
  middlewares.sample.yaml
  tls.sample.yaml
  custom/                   # yours
    traefik.yaml            #   static configuration (entrypoints, certificates resolver, logs...)
    middlewares.yaml        #   middlewares used by the rules (http authentication, allowed IPs for "internalOnly"...)
    tls.yaml                #   TLS options
    rules/                  #   your own Traefik config files (see the previous section)
    mtls/                   #   Certificate Authorities of your client certificates (see apps/vaultls.md)
    compose.override.yaml   #   your changes on the container itself (see "Customize a bundled service")
  generated-config/         # generated on each run, mounted in the container. Do not edit
```

``custom/traefik.yaml``, ``custom/middlewares.yaml`` and ``custom/tls.yaml`` are created from the templates and are yours: edit them freely, updates of the templates are merged in them (see [Templates](#templates)).

``generated-config/`` is what Traefik really reads. It is rebuilt on each ``./run-seedbox.sh`` execution from your files, the rules generated from ``config.yaml`` and the ``rules.yaml`` files of enabled services. Never edit it: your changes would be lost.

So after editing one of your files, **run ``./run-seedbox.sh``** (``--no-pull`` makes it faster): restarting the Traefik container is not enough, as it would read the previous generated files. The script restarts Traefik itself when ``traefik.yaml`` has changed; changes in ``middlewares.yaml``, ``tls.yaml`` and rules are applied without restart.

## Disable HTTPS completely

By default, every rule is served in https with a Let's Encrypt certificate, and http requests are redirected to https.

If you want to handle your certificates on a firewall or another reverse proxy somewhere else on your network, set ``httpOnly: true`` on your rules: they are then served in plain http (port 80), no certificate is requested for them and they are not redirected to https. To do it for all services at once, use ``defaults`` in ``config.yaml``:

```yaml
defaults:
  httpOnly: true
```

Then, make the machine which acts as reverse proxy (and handles certificates) points on every Traefik URL with the corresponding certificate, or make a wildcard redirection, based on your reverse proxy.

You can also mix both on the same service, with a second rule (a local unsecured host next to the secured one for example).

> The redirection to https is global (``redirections`` on the ``insecure`` entrypoint of your ``traefik.yaml``) and has by default a higher priority than any rule. As soon as one rule has ``httpOnly: true``, the script lowers this priority in the generated configuration (your file is not modified), so rules win over the redirection. Side effect: your own Traefik rules (``services/traefik/custom/rules/``, Docker labels) which listen on the ``insecure`` entrypoint, or on no specific entrypoint, are served in plain http too instead of being redirected. Set ``entryPoints: [secure]`` on them if you do not want that.

## VPN

In order to hide a service behind a VPN, just enable ``gluetun`` service.

By default, gluetun is in "Wireguard custom" mode, meaning you must have somewhere a Wireguard server running and access to its client configuration. But you can use any provider supported by gluetun. See sections below.

### Default mode - Wireguard custom

* Enable ``gluetun`` service in ``config.yaml``.
* Run ``tools/sync-templates.sh``: it creates ``services/gluetun/custom/service.env``. Edit it and replace the Wireguard variables with your own.
* Enable vpn (``vpn: true``) on any service.
* Run ``./run-seedbox.sh``.
* The service now uses Wireguard. If gluetun is down or if the VPN link is broken, your service won't have any access to Internet.

### Your own mode (VPN provider supported by gluetun)

* Edit your ``services/gluetun/custom/service.env`` file and adapt ``VPN_SERVICE_PROVIDER``, ``VPN_TYPE`` and all required variables based on your provider/configuration, as written in Gluetun documentation. Remove the Wireguard variables you do not need.
* All possible environment variables for Gluetun are documented [here](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers).
* If variables are not enough (ports, volumes...), add a ``services/gluetun/custom/compose.override.yaml``: see [Customize a bundled service](#customize-a-bundled-service).

### How is VPN handled?

Behind the scenes, the ``run-seedbox.sh`` script will mainly add 2 overrides when enabling VPN on a service:

* Adds a file in ``.seedbox/generated/`` which adds a ``network_mode: gluetun`` for your service.
* Specify in Traefik rule that the backend host is gluetun instead of the service directly.

## Media on NFS Server

Media (``torrents``, ``downloads`` and ``documents``) are Docker volumes defined in your ``docker-compose.yaml``, shared by all services which need them. By default they are plain directories of your host (``HOST_MEDIA_PATH`` in ``.env``).

If your media is not on the same machine as your containers, do the following:

* Configure a NFS share on the network.
* Replace your ``docker-compose.yaml`` by a copy of ``docker-compose.nfs.sample.yaml``.
* Specify in ``.env`` the following variables:
  * ``NFS_IP``: the IP of your NFS server
  * ``NFS_MEDIA_VOLUME``: the volume of the share (it must start with ":/").

> Only media can be on a NFS share this way. The configuration of services (``HOST_CONFIG_PATH``) is always a directory of the host.

## Make the services communicate with each other

With docker-compose, all services are in the same Docker network (it is called ``traefik-network`` and is defined [here](../docker-compose.sample.yaml)). Docker provides DNS resolution in the same network based on the name of the services, which act as hostnames.

So, for example, in order to setup Deluge in Sonarr, just add ``http://deluge:8112`` in the Download Clients settings section in Sonarr.

⚠️ If you are trying to contact a container which has ``vpn`` flag enabled, you will have to point your config to ``gluetun`` instead, which acts as relay to contact the service. So if Deluge is behind the VPN, add ``http://gluetun:8112`` in Sonarr instead.

## How does the configuration work?

Behind the scenes, the ``run-seedbox.sh`` script will parse your ``config.yaml`` file and will generate a Traefik dynamic configuration file, which looks like this:

```yaml
http:
  routers:
    deluge-1:
      rule: 'Host(`deluge.{{ env "TRAEFIK_DOMAIN" }}`)'
      entryPoints:
        - secure
      tls:
        certResolver: le
      middlewares:
        - common-auth@file
      service: deluge-1
    sonarr-1:
      rule: 'Host(`sonarr.{{ env "TRAEFIK_DOMAIN" }}`)'
      entryPoints:
        - secure
      tls:
        certResolver: le
      middlewares:
        - common-auth@file
      service: sonarr-1
    sonarr-2:
      # Rule with "httpOnly: true"
      rule: 'Host(`sonarr-unsecure.{{ env "TRAEFIK_DOMAIN" }}`)'
      entryPoints:
        - insecure
      middlewares:
        - common-auth@file
      service: sonarr-2
    nextcloud-1:
      rule: 'Host(`nextcloud.{{ env "TRAEFIK_DOMAIN" }}`)'
      entryPoints:
        - secure
      tls:
        certResolver: le
      service: nextcloud-1
  services:
    deluge-1:
      loadBalancer:
        servers:
            # Gluetun is automatically set by run-seedbox.sh (instead of "deluge") because vpn was enabled on this service
          - url: "http://gluetun:8112"
    sonarr-1:
      loadBalancer:
        servers:
          - url: "http://sonarr:8989"
    sonarr-2:
      loadBalancer:
        servers:
          - url: "http://sonarr:8989"
    nextcloud-1:
      loadBalancer:
        servers:
          - url: "https://nextcloud:443"
```

This file is generated on each ``run-seedbox.sh`` execution in the ``services/traefik/generated-config/`` directory, which is mounted in the Traefik container, so the config dynamically applies. See [Configuration of Traefik itself](#configuration-of-traefik-itself).

# Apps configuration

List of currently available documentation for apps:

- [Deluge + Flood](apps/deluge-flood.md): configuration of Deluge so Flood can connect to it
- [Dockhand](apps/dockhand.md): containers management, and how to give it access to the Docker socket
- [FileBrowser Quantum](apps/filebrowser.md): installation, configuration and what changes from the previous Filebrowser
- [Plex](apps/plex.md): how to reach it (host network) and publish it on ``plex.yourdomain.com``
- [Netbird](apps/netbird.md): private network and public reverse proxy with access control (CrowdSec, certificates...)
- [VaulTLS](apps/vaultls.md): client certificates (mTLS) to restrict a service to your own devices

I also strongly recommend [TRaSH Guides](https://trash-guides.info/) to have a better overview of all *arrs apps configurations.