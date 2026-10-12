# Dockhand

## Table of content

* [What is it for?](#what-is-it-for)
* [Installation](#installation)
* [Access to the Docker socket](#access-to-the-docker-socket)
* [Restrict the access](#restrict-the-access)
* [Troubleshooting](#troubleshooting)

## What is it for?

[Dockhand](https://hub.docker.com/r/fnsys/dockhand) is a web interface to manage the containers of your server: state, logs, restart, images, volumes... It is an alternative to Portainer.

To do so, it uses the Docker socket of the host (``/var/run/docker.sock``), which is mounted in its container. Its data is stored in ``$HOST_CONFIG_PATH/dockhand``.

## Installation

Dockhand is disabled in the sample configuration. Enable it in your ``config.yaml``:

```yaml
services:
  dockhand:
```

Then give it access to the Docker socket (next section), run ``./run-seedbox.sh`` and open ``https://dockhand.<your domain>``.

## Access to the Docker socket

The container runs with your ``PUID`` and ``PGID`` (see ``.env``). On most systems, the Docker socket can only be used by ``root`` and by the members of the ``docker`` group, so Dockhand cannot read it unless its container is added to this group.

The id of this group is not the same on every machine, which is why it is not set in the bundled file. Get the one of your host:

```sh
stat -c '%g' /var/run/docker.sock
```

Then add it to the container with an override file, ``services/dockhand/custom/compose.override.yaml`` (replace ``978`` by your value):

```yaml
services:
  dockhand:
    group_add:
      - "978"
```

Run ``./run-seedbox.sh`` to apply it. This file is yours (ignored by git): see [Customize a bundled service](../configuration.md#customize-a-bundled-service).

> You do not need this file if your ``PGID`` already is the id of the group which owns the socket.

## Restrict the access

Whoever can use Dockhand controls Docker, so the whole server. Its default rule has no http authentication, as Dockhand has its own: do not leave it reachable from the Internet without thinking about it. The simplest way is to keep it on your private networks:

```yaml
services:
  dockhand:
    rules:
      - internalOnly: true
```

You can also require a client certificate (``mtls: true``, see [VaulTLS and client certificates](vaultls.md)) or add the http authentication of the seedbox on top (``httpAuth: true``). All parameters are described in the [Configuration Guide](../configuration.md#configyaml-your-choices).

## Troubleshooting

| Problem | What to check |
|---------|---------------|
| Dockhand shows no container, or ``permission denied`` on ``/var/run/docker.sock`` in ``docker logs dockhand`` | The container is not in the group which owns the socket: see [Access to the Docker socket](#access-to-the-docker-socket). Check the result with ``docker exec dockhand id``. |
| It worked, then stopped after a system or Docker update | The id of the ``docker`` group may have changed: run the ``stat`` command again and update your override file. |
