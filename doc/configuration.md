# Seedbox configuration

## Table of content

* [General principles](#general-principles)
* [Configuration structure and parameters](#configuration-structure-and-parameters)
* [Environment variables](#environment-variables)
* [Add your own service](#add-your-own-service)
  * [Particular case: Plex with Hardware Transcoding](#particular-case-plex-with-hardware-transcoding)
* [Integration with other services (custom Traefik config)](#integration-with-other-services-custom-traefik-config)
* [Disable HTTPS completely](#disable-https-completely)
* [VPN](#vpn)
  * [Default mode - Wireguard custom](#default-mode---wireguard-custom)
  * [Your own mode (VPN provider supported by gluetun)](#your-own-mode-vpn-provider-supported-by-gluetun)
  * [How is VPN handled?](#how-is-vpn-handled)
* [Make the services communicate with each other](#make-the-services-communicate-with-each-other)
* [How does the configuration work?](#how-does-the-configuration-work)
* [Apps configuration](#apps-configuration)

## General principles

Every service (Plex, Sonarr, Jackett, Nextcloud...) is defined in a dedicated file (in docker-compose format) in the [services](../services/) directory.

All your configuration such as:

* Which services must be enabled
* What docker-compose file they are using if a a particular one must be applied instead of the default one (which is the one with the same name as the service)
* Routing rules (example: ``sonarr.yourdomain.com`` for Sonarr)
* If http authentication must be enabled (example: *enable* for Sonarr, *disable* for Nextcloud has it has built-in authentication)
* Some other parameters (see below)

... is located in ``config.yaml``. If you are starting fresh, copy ``config.sample.yaml`` into ``config.yaml``. If you don't, on the first run, ``./run-seedbox.sh`` will copy the sample file for you.

Then, all your "sensitive" (or "personal") data configuration (passwords, usernames, domain name, paths on the machine for persistent data...) is located in ``.env`` file.

When running ``./run-seedbox.sh``:

* ``.env`` is loaded
* ``config.yaml`` is parsed, some checks are performed
* For each service, if enabled, Traefik rules are generated ([see this section](#how-does-the-configuration-work)) dynamically
* docker-compose commands (pull, up...) are executed against all relevant files

## Configuration structure and parameters

Almost the whole stack can be configured by using the main configuration item: ``config.yaml``.
Here is what it looks like:

```yaml
# List of all services
services:
  # Name of the service
  - name: traefik
    # Flag indicating if the service will be created or not
    enabled: true
    # Define traefik (reverse proxy) behavior for this service
    traefik:
      # Enable or disable Traefik routing. For example, if your service is a DB, disable Traefik.
      enabled: true
      # Routing rules, which will be processed and rendered as Traefik "dynamic configuration" via file provider
      rules:
          # Host to match request. Any environment variable is supported here, as long as there are braces around it.
        - host: traefik.${TRAEFIK_DOMAIN}
          # Traefik service to match (if it is a particular one). Here the "api@internal" service is internal to Traefik (dashboard access). If not specified, a "traefik service" with the same name as the docker service will be created.
          service: api@internal
          # Enable http authentication
          httpAuth: true
  # Another service
  - name: deluge
    enabled: true
    # Enable VPN (default to false). Service "gluetun" must be configured and enabled (with proper variables set in .env) to be able to use vpn mode on any service.
    vpn: true
    traefik:
      enabled: true
      rules:
        - host: deluge.${TRAEFIK_DOMAIN}
          # No service is defined here => a traefik service named "deluge" will be created automatically
          httpAuth: true
          # Internal container port on which we want to bind the Traefik routing
          internalPort: 8112
  # Another service
  - name: flaresolverr
    enabled: true
    # Do not use VPN (same as nothing as false is default)
    vpn: false
    traefik:
      # This service is not reachable directly (no UI). So Traefik is disabled and rules are an empty array.
      enabled: false
      # Optional, won't be evaluated as Traefik is disabled
      rules: []
  # Another service with 2 Traefik rules
  - name: sonarr
    enabled: true
    vpn: false
    traefik:
      enabled: true
      rules:
          # First "regular" routing rule
        - host: sonarr.${TRAEFIK_DOMAIN}
          httpAuth: true
          internalPort: 8989
          # Another rule which bypasses certificate generation using Let's Encrypt (ACME challenge).
        - host: sonarr-unsecure.${TRAEFIK_DOMAIN}
          httpAuth: true
          internalPort: 8989
          # Using this flag, sonarr-unsecure.domain.com (for example) will be accessible ONLY via http protocol
          httpOnly: true
  # Another service with backend using https
  - name: nextcloud
    enabled: false
    vpn: false
    traefik:
      enabled: true
      rules:
        - host: nextcloud.${TRAEFIK_DOMAIN}
          httpAuth: false
          internalPort: 443
          # Specify that the routing will be on https://nextcloud:443 (internally), while by default services expose only http.
          # Nextcloud is known to be an exception and exposes only port 443 with SSL
          internalScheme: https
```

The provided ``config.sample.yaml`` is good enough to get started and will be used if no ``config.yaml`` is found.

Some general rules:

* In order to enable VPN (``vpn: true``) on a service, you must configure and enable gluetun service.
* By default, all services match "http://service_name:port" for routing.
* By default, when ``httpOnly`` is false or not set, service will be accessible from both http and https, but a redirection will be created from http to https.
  * And when ``httpOnly`` is set to true, the service will be accessible ONLY via http, bypassing certificate generation. It is useful when you do not want Traefik to handle certificates for this service.

## Environment variables

Also, do not forget to edit your ``.env`` file, which is where all the data which will be sent to containers (passwords, tokens, uid for disk permission...) lives.

## Add your own service

Let's say you want to add a container nginx without interfering or creating conflicts in this git repository. That's possible.

Start by creating a file named nginx.yaml in the [services/custom/](services/custom/) directory:

```yaml
services:
  nginx:
    image: nginx:latest
    container_name: nginx
    restart: always
    # ...
```

Then, enable it in your ``config.yaml``:

```yaml
services:
  # ...
  - name: nginx
    enabled: true
    vpn: false
    # Specify the path to your custom docker-compose file, relative to the "services" directory
    customFile: custom/nginx.yaml
    traefik:
      enabled: true
      rules:
        - host: nginx.${TRAEFIK_DOMAIN}
          httpAuth: false
          # 80 because official nginx image uses this port
          internalPort: 80
  # ...
```

...and you're set! Just run ``./run-seedbox.sh`` to apply configuration changes.

> Please note that the ``customFile`` flag **MUST** be relative to the "services" directory, because in some cases, some alternatives yaml files for bundled services are provided in the services directory. See the next section for more details.

### Particular case: Plex with Hardware Transcoding

This project provides a custom [plex-hardware-transcoding.yaml](../services/plex-hardware-transcoding.yaml) file, with all the necessary adaptations to make Plex run with hardware transcoding enabled.

Just add the ``customFile: plex-hardware-transcoding.yaml`` field in the ``plex`` service and this file will be used, instead of the default "plex.yaml":

```yaml
services:
  # ...
  - name: plex
    enabled: true
    vpn: false
    # Here is the change: by default, without this flag, the applied file was "plex.yaml"
    customFile: plex-hardware-transcoding.yaml
    traefik:
      enabled: true
      rules:
        - host: plex.${TRAEFIK_DOMAIN}
          httpAuth: false
          internalPort: 32400
  # ...
```

Then, run ``./run-seedbox.sh`` to make these changes taken into account and the new container Plex will have hardware transcoding.

> Note that you also have to enable Hardware Transcoding in your Plex Server settings after the container has started.

## Integration with other services (custom Traefik config)

You can also add you own Traefik configuration to integrate with local services on your LAN.
Just put your Traefik configuration file in the [samples/custom-traefik/](../samples/custom-traefik/) directory.
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

## Disable HTTPS completely

If you want to handle your certificates on a firewall or another reverse proxy somewhere else on your network, it is now possible.
You just have to set ``httpOnly: true`` on all your services in ``config.yaml``.
Then, make the machine which acts as reverse proxy (and handles certificates) points on every Traefik URL with the corresponding certificate, or make a wildcard redirection, based on your reverse proxy.

## VPN

In order to hide a service behind a VPN, just enable ``gluetun`` service.

By default, the file used is [gluetun.yaml](../services/gluetun.yaml), which is in "Wireguard custom" mode, meaning you must have somewhere a Wireguard server running and access to its client configuration. But you can add your own config to match your requirements. See sections below.

### Default mode - Wireguard custom

* Edit the ``.env`` file and replace the Wireguard variables with your own (take them in ``.env.sample``).
* Enable ``gluetun`` service.
* Enable vpn (``vpn: true``) on any service.
* Run ``./run-seedbox.sh``.
* The service now uses Wireguard. If gluetun is down or if the VPN link is broken, your service won't have any access to Internet.

### Your own mode (VPN provider supported by gluetun)

* Create a ``gluetun-custom.yaml`` in the [services/custom/](../services/custom/) directory. You can duplicate [this one](../services/gluetun.yaml) to avoid starting from scratch.
* Adapt it to your needs (variables, mode...) according to your provider.
  * Add all variables you may need (used in your custom yaml file) in your ``.env`` file (replacing the wireguard ones).
* Edit your ``config.yaml`` and add ``customFile: custom/gluetun-custom.yaml`` in the ``gluetun`` section.
* Enable vpn (``vpn: true``) on any service.
* Run ``./run-seedbox.sh``.
* The service now uses your VPN by tunneling via gluetun container. If gluetun is down or if the VPN link is broken, your service won't have any access to Internet.

### How is VPN handled?

Behind the scenes, the ``run-seedbox.sh`` script will mainly add 2 overrides when enabling VPN on a service:

* Adds a file in [services/generated/](../services/generated/) which adds a ``network_mode: gluetun`` for your service.
* Specify in Traefik rule that the backend host is gluetun instead of the service directly.

## Make the services communicate with each other

With docker-compose, all services are in the same Docker network (it is called ``traefik-network`` and is defined [here](../docker-compose.yaml)). Docker provides DNS resolution in the same network based on the name of the services, which act as hostnames.

So, for example, in order to setup Deluge in Sonarr, just add ``http://deluge:8112`` in the Download Clients settings section in Sonarr.

⚠️ If you are trying to contact a container which has ``vpn`` flag enabled, you will have to point your config to ``gluetun`` instead, which acts as relay to contact the service. So if Deluge is behind the VPN, add ``http://gluetun:8112`` in Sonarr instead.

## How does the configuration work?

Behind the scenes, the ``run-seedbox.sh`` script will parse your ``config.yaml`` file and will generate a Traefik dynamic configuration file, which looks like this:

```yaml
http:
  routers:
    deluge-1:
      rule: 'Host(`deluge.{{ env "TRAEFIK_DOMAIN" }}`)'
      middlewares:
        - common-auth@file
        - redirect-to-https
      service: deluge-1
    sonarr-1:
      rule: 'Host(`sonarr.{{ env "TRAEFIK_DOMAIN" }}`)'
      middlewares:
        - common-auth@file
        - redirect-to-https
      service: sonarr-1
    sonarr-2:
      rule: 'Host(`sonarr-unsecure.{{ env "TRAEFIK_DOMAIN" }}`)'
      middlewares:
        - common-auth@file
      service: sonarr-2
      entryPoints:
        - insecure
    nextcloud:
      rule: 'Host(`nextcloud.{{ env "TRAEFIK_DOMAIN" }}`)'
      middlewares:
        - redirect-to-https
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

This file will be automatically placed in [traefik/custom/](../traefik/custom/) directory (mounted by Traefik container) so the config will dynamically apply. This file is updated on each ``run-seedbox.sh`` execution.

# Apps configuration

List of currently available documentation for apps:

- [Deluge + Flood](apps/deluge-flood.md)

I also strongly recommend [TRaSH Guides](https://trash-guides.info/) to have a better overview of all *arrs apps configurations.