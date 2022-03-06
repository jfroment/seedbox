# Seedbox configuration

Almost the whole stack can be configured by using the main configuration item: ``config.yaml``.
Here is what it looks like:

```yaml
# List of all services
services:
  # Name of the service
  - name: traefik
    # Flag indicating if the service will be created
    enabled: true
    # Define traefik behavior for this service
    traefik:
      # Enable or disable Traefik routing. For example, if your service is a DB, disable Traefik.
      enabled: true
      # Routing rules, which will be processed and rendered as Traefik "dynamic configuration" via file provider
      rules:
          # Host to match request. Any environment variable is supported here, as long as there are braces around it.
        - host: traefik.${TRAEFIK_DOMAIN}
          # Traefik service to match (if it is a particular one). Here the "api@internal" service is internal to Traefik (dashboard access).
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
          # Using this flag, sonarr-unsecure.domain.com (for example) will be accesisble ONLY via http protocol
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

Start by creating a files named nginx.yaml in the [services/custom/](services/custom/) directory:

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

...and you're set!

Please note that the ``customFile`` flag **MUST** be relative to the "services" directory, because in some cases, some alternatives yaml files for bundled services are provided in the services directory.
For example, in this repository is provided a custom "plex-hardware-transcoding.yaml" file, with all the necessary adaptations to make Plex run with hardware transcoding enabled. Just add the ``customFile`` field in the ``plex`` service and this file will be used, instead of the default "plex.yaml".

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
Then, make the machine which acts as reverse proxy (and handles certificates) points on every Traefik URL with the correpsonding certificate, or make a wildcard redirection, based on your reverse proxy.

## How does it work?

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
