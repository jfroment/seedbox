# Plex

## Table of content

* [How Plex runs in the seedbox](#how-plex-runs-in-the-seedbox)
* [Access Plex](#access-plex)
* [Publish Plex on plex.yourdomain.com (https, port 443)](#publish-plex-on-plexyourdomaincom-https-port-443)
* [Hardware transcoding](#hardware-transcoding)

## How Plex runs in the seedbox

Plex uses the network of the host (``network_mode: host``) instead of the Docker network of the seedbox. This is what lets Plex see the real IP addresses of your devices, so it can tell local connections from remote ones (in its dashboard and in Tautulli).

The consequence: Plex is not in the Docker network of Traefik, so Traefik cannot reach it with its name like other services. **Plex has no Traefik rule by default**, and ``plex.yourdomain.com`` does not exist unless you publish it yourself (see below).

## Access Plex

Plex listens on the port ``32400`` of your server:

* from your LAN: ``http://<IP of your server>:32400/web``
* from outside: through ``app.plex.tv`` and Plex apps, if *Remote Access* is enabled in Plex settings and the port ``32400`` is forwarded to your server on your router.

## Publish Plex on plex.yourdomain.com (https, port 443)

To reach Plex on ``https://plex.yourdomain.com`` with a certificate, without opening the port ``32400`` on the Internet, publish it with the reverse proxy of Netbird:

1. Install [Netbird](netbird.md) and follow [Publish a service through Netbird](netbird.md#publish-a-service-through-netbird): the target of the service is the peer of your server, port ``32400``. Nothing to do in ``config.yaml``, as Plex has no Traefik rule.
2. In Plex, **disable *Remote Access*** (*Settings* > *Remote Access*). With Remote Access enabled, Plex also publishes its own address (your public IP and the port ``32400``) and your devices use it: it needs NAT rules on your network, and breaks the access through ``plex.yourdomain.com``.

> You can also write your own Traefik rule in ``services/traefik/custom/rules/`` which targets the IP of your server and the port ``32400`` (see [Integration with other services](../configuration.md#integration-with-other-services-custom-traefik-config)). This is not the setup tested with this project.

## Hardware transcoding

See [Plex with Hardware Transcoding](../configuration.md#particular-case-plex-with-hardware-transcoding) in the Configuration Guide.
