# FileBrowser Quantum

## Table of content

* [What is it for?](#what-is-it-for)
* [Installation](#installation)
* [Configuration](#configuration)
* [Coming from the previous Filebrowser](#coming-from-the-previous-filebrowser)

## What is it for?

[FileBrowser Quantum](https://github.com/gtsteffaniak/filebrowser) is a web file manager: browse, search, preview, upload, download and share the files of your media directory. It replaces the original [Filebrowser](https://github.com/filebrowser/filebrowser), whose repository is archived. The service keeps the same name in the seedbox: ``filebrowser``.

## Installation

Enable the service in your ``config.yaml``:

```yaml
services:
  filebrowser:
```

Run ``./run-seedbox.sh``: it creates the two files below in ``services/filebrowser/custom/`` and stops, as a password is required. Set ``FILEBROWSER_ADMIN_PASSWORD`` in ``service.env``, run ``./run-seedbox.sh`` again and open ``https://files.<your domain>``. Log in with the user ``admin`` and this password.

| File | Purpose |
|------|---------|
| ``services/filebrowser/custom/service.env`` | Password of the ``admin`` user |
| ``services/filebrowser/custom/config.yaml`` | Configuration of FileBrowser Quantum, mounted in the container |

The Traefik rule has no http authentication (``httpAuth: false``), as FileBrowser Quantum has its own. To keep it on your private networks, add ``internalOnly: true`` to its rule (see the [Configuration Guide](../configuration.md#configyaml-your-choices)).

## Configuration

Everything is in ``services/filebrowser/custom/config.yaml``, created from [config.sample.yaml](../../services/filebrowser/config.sample.yaml). All options are described in [FileBrowser Quantum documentation](https://filebrowserquantum.com/en/docs/getting-started/config/). After a change, restart the container (``docker restart filebrowser``): the file is only read when it starts.

* **Port**: keep ``http.port: 8234``, it is the one used by the Traefik rule and the healthcheck.
* **Directories**: by default, your media directory (the ``torrents`` volume) is available in ``/srv``. To browse another directory, mount it with an override file (see [Customize a bundled service](../configuration.md#customize-a-bundled-service)) and add its path **in the container** to ``server.sources``:

  ```yaml
  # services/filebrowser/custom/compose.override.yaml
  services:
    filebrowser:
      volumes:
        - documents:/documents
  ```

  ```yaml
  # services/filebrowser/custom/config.yaml
  server:
    sources:
      - path: /srv
        config:
          defaultEnabled: true
      - path: /documents
        config:
          defaultEnabled: true
  ```

* **Data**: the database and the cache are in ``$HOST_CONFIG_PATH/filebrowser-quantum``. The container runs with your ``PUID`` and ``PGID``.

## Coming from the previous Filebrowser

FileBrowser Quantum is another application: users, settings and shares of the previous Filebrowser are not migrated. Your files are not affected.

* The previous data stays in ``$HOST_CONFIG_PATH/filebrowser`` (``config`` and ``db``). It is not used anymore: delete it once you do not need it.
* If your ``config.yaml`` has ``httpAuth: true`` on ``filebrowser`` (it was the default before, so the migration from v2 keeps it), remove it if you do not want two authentications in a row.
