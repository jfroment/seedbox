# Upgrade to V3

V3 changes how the project is organized, to make it easier to customize and to update:

* **You never edit a file tracked by git anymore.** Your changes on bundled services are in override files, and the configuration files you have to fill are copies of templates (``*.sample.*``), in which updates are merged automatically.
* **One directory per service**, containing everything about it, including its default routing rules (``service.yaml``).
* **A much shorter ``config.yaml``**, where you only write what differs from the default values.
* **No more ``.env.custom``**: each service has its own environment file, without prefix on variables.
* **One ``custom`` directory in each service** for everything which is yours: you see your customizations directly in the tree.

## TL;DR

```sh
# If git pull fails because you edited files tracked by git: see "If git pull fails" below
git pull
./run-seedbox.sh
```

> ⚠️ Run ``./run-seedbox.sh`` right after ``git pull``: the configuration files that your running Traefik reads are moved by the update, so your services may not be reachable between the two commands.

The migration is automatic: on the first run, ``run-seedbox.sh`` detects the v2 format and calls ``tools/migrate-v3.sh``. Nothing is deleted: files are moved, and your ``config.yaml`` is saved in ``.seedbox/backup/`` before being converted. After the migration, the generated Traefik rules and the containers are the same as before.

## What the migration does

| Before (v2) | After (v3) | |
|-------------|------------|-|
| ``services/<name>.yaml`` | ``services/<name>/compose.yaml`` | Done by git. Do not edit these files anymore: put your changes in ``services/<name>/custom/compose.override.yaml`` |
| ``services/plex-hardware-transcoding.yaml`` | ``services/plex/compose-hardware-transcoding.yaml`` | ``customFile`` is updated in your ``config.yaml`` |
| ``services/custom/<file>.yaml`` | ``services/<name>/custom/compose.yaml`` | ``<name>`` is the name of the service in ``config.yaml``. ``customFile`` is not needed anymore and is removed |
| ``samples/custom-traefik/*`` | ``services/traefik/custom/rules/*`` | Including your ``.disabled`` files |
| ``traefik/traefik.yaml``, ``traefik/custom/middlewares.yaml``, ``traefik/custom/tls.yaml`` | ``services/traefik/custom/traefik.yaml``, ``middlewares.yaml``, ``tls.yaml`` | Yours now, created from the templates of ``services/traefik/`` |
| ``traefik/`` (mounted in the Traefik container) | ``services/traefik/generated-config/`` | Generated on each run. The old directory is moved to ``.seedbox/backup/`` once Traefik is updated |
| ``samples/docker-compose.sample.nfs.yaml`` | ``docker-compose.nfs.sample.yaml`` | |
| ``services/generated/``, ``env/`` | ``.seedbox/generated/`` | Nothing to do, these files are generated on each run. The old directories are removed |
| ``config.yaml``, list of services with all their parameters | ``config.yaml``, only your changes | Previous version saved in ``.seedbox/backup/config.v2.<date>.yaml`` |
| ``.env.custom``, with variables prefixed by the name of the service | ``services/<name>/custom/service.env``, one file per service, without prefix | ``.env.custom`` is moved to ``.seedbox/backup/.env.custom.v2.<date>`` |

### config.yaml

Before, every service had all its parameters in your ``config.yaml``:

```yaml
services:
  - name: sonarr
    enabled: true
    vpn: false
    traefik:
      enabled: true
      rules:
        - host: sonarr.${TRAEFIK_DOMAIN}
          httpAuth: false
          internalPort: 8989
  - name: deluge
    enabled: true
    vpn: true
    traefik:
      enabled: true
      rules:
        - host: deluge.${TRAEFIK_DOMAIN}
          httpAuth: true
          internalPort: 8112
  - name: lidarr
    enabled: false
    # ...
```

Now, the default values (host, port, authentication...) are in the ``service.yaml`` file of each service, and the migration only keeps what you changed:

```yaml
services:
  sonarr:
    rules:
      - httpAuth: false
  deluge:
    vpn: true
  lidarr:
    enabled: false
```

How each parameter is converted:

| v2 | v3 |
|----|----|
| ``enabled: true`` | Nothing: a listed service is enabled |
| ``enabled: false`` | ``enabled: false`` |
| ``vpn: true`` | ``vpn: true`` |
| ``customFile: custom/xxx.yaml`` | Removed (the file is moved to ``services/<name>/custom/compose.yaml``) |
| ``traefik.enabled: false`` | ``traefik: false`` (nothing if the service has no default rule) |
| ``traefik.rules`` | ``rules``, with only the parameters which differ from the default rule of the service. Rules of your own services are kept as they are |

The complete description of the new format is in the [Configuration Guide](configuration.md#configuration-structure-and-parameters).

### .env.custom

Before, variables of all services were in ``.env.custom``, prefixed by the name of the service:

```sh
PAPERLESS_PAPERLESS_SECRET_KEY=mykey
PAPERLESS_PAPERLESS_OCR_LANGUAGE=eng,fra
GLUETUN_VPN_SERVICE_PROVIDER=custom
```

Now, each service has its own file, and variables are written as the image expects them:

```sh
# services/paperless/custom/service.env
PAPERLESS_SECRET_KEY=mykey
PAPERLESS_OCR_LANGUAGE=eng,fra
```

```sh
# services/gluetun/custom/service.env
VPN_SERVICE_PROVIDER=custom
```

The migration creates these files from your ``.env.custom`` (for all services, enabled or not), then moves ``.env.custom`` to ``.seedbox/backup/``. Only the variables are migrated: your comments and commented variables stay in the backup. If some variables have a prefix which does not match any service, the migration lists them: nothing was using them in v2 either.

## After the migration

Everything works without any other action, except for the first points (removed services, Docker Compose, cleaning). Then you may want to:

* **Removed services**: Overseerr, Readarr, Ombi, Homarr and Portainer are not bundled anymore (see the [changelog](../CHANGELOG.md)). If one of them is enabled in your ``config.yaml``, the script stops because its file does not exist anymore. Either remove it from your ``config.yaml``, or keep it as your own service: its rules are already in your ``config.yaml``, you just need its docker-compose file back, from the previous version.

  ```sh
  # Example with Portainer (same thing with readarr, ombi, homarr or overseerr)
  mkdir -p services/portainer/custom
  git show v2.2.2:services/portainer.yaml > services/portainer/custom/compose.yaml
  ```

  It is now a service of yours, like any other one: see [Add your own service](configuration.md#add-your-own-service). The suggested replacements are Seerr for Overseerr and Ombi (rename ``overseerr`` to ``seerr`` in your ``config.yaml``; Seerr uses its own directory, ``$HOST_CONFIG_PATH/seerr``: see the [Seerr migration guide](https://docs.seerr.dev/migration-guide) to keep your data), Dockhand for Portainer (see [its documentation](apps/dockhand.md)) and Homepage or Heimdall for Homarr.
* **Filebrowser** is replaced by FileBrowser Quantum, under the same service name. If it is enabled, the script stops and asks you to set the password of its ``admin`` user in ``services/filebrowser/custom/service.env``. Users and settings of the previous Filebrowser are not migrated: see [its documentation](apps/filebrowser.md#coming-from-the-previous-filebrowser).
* **Docker Compose v2**: version 2.27.2 or above is required. ``DOCKER_COMPOSE_BINARY`` is not used anymore, remove it from your ``.env``. The script always uses ``docker compose``, the old ``docker-compose`` binary is not supported.
* **Name of the Docker Compose project**: it was the name of the directory of the seedbox, it is now always ``seedbox``, so the directory can be renamed or moved. If your directory has another name, the script tells you so and asks before going on: all containers are removed and created again in the new project (containers only, your data is not affected). To avoid it, keep the previous name with ``COMPOSE_PROJECT_NAME=<name of your directory>`` in your ``.env``.
* **local-persist plugin** is not needed by the seedbox anymore. Nothing to do for bundled services; for your own files, see [local-persist plugin](#local-persist-plugin).
* **Cleaning of unused images and volumes** is not automatic anymore: set ``DOCKER_PRUNE_AFTER_UPDATE=true`` in your ``.env`` to get the previous behaviour back.
* **Shorten your ``config.yaml``**: if the same parameter is repeated on most services (``internalOnly: true`` for example), set it once in [``defaults``](configuration.md#how-rules-are-merged).
* **Use bundled services instead of yours**: some services were added in v3 (Jellyfin, Vaultwarden, Mealie...). If you already had your own file for one of them, it is now ``services/<name>/custom/compose.yaml`` and is still the one which is used. Delete it to use the bundled one (compare them first).
* **Turn your modified copies of bundled services into overrides**: same thing if you had a custom file for a bundled service (a modified Duplicati for example). It still works, but you do not get the updates of the bundled file. Keep only your changes in a ``compose.override.yaml`` instead: see [Customize a bundled service](configuration.md#customize-a-bundled-service).
* **Check the paths in your own services**: if the migration says that ``services/custom`` still contains files, they are files used by your services (config files, env files...). They still work where they are, but their place is now next to the service: move them to ``services/<name>/custom/`` and fix the path in its ``compose.yaml``.
* **Look at the new ``service.sample.env`` files**: they list the optional variables of each service.
* **Remove ``CHECK_FOR_OUTDATED_CONFIG``** from your ``.env``: it is not used anymore. You are now warned when a sample file changes, and ``tools/sync-templates.sh diff`` shows what changed.

## local-persist plugin

The seedbox does not use the [local-persist](https://github.com/MatchbookLab/local-persist) Docker plugin anymore. Bundled services now mount the directories of ``HOST_CONFIG_PATH`` directly, at the same place as before: **your data does not move and there is nothing to migrate**. Docker never deletes the content of a directory mounted this way, whatever you do with containers and volumes.

The plugin is not removed from your machine by the upgrade, because some of your own files may still use it:

* your ``docker-compose.yaml``, for media volumes (``torrents``, ``downloads``, ``documents``)
* your own services and override files (``services/<name>/custom/``)

They still work as long as the plugin is installed, and ``run-seedbox.sh`` lists them on each run. To get rid of the plugin:

1. In your ``docker-compose.yaml``, replace the ``volumes`` section by the one of [docker-compose.sample.yaml](../docker-compose.sample.yaml) (or of ``docker-compose.nfs.sample.yaml`` if your media are on a NFS share). The ``config`` volume is not used by bundled services anymore: only keep it if your own services use it.

   ```yaml
   volumes:
     torrents:
       driver_opts:
         type: none
         o: bind
         device: $HOST_MEDIA_PATH
     # ...same thing for downloads and documents
   ```

2. In your own files, mount the directory itself instead of a volume:

   ```yaml
   services:
     myservice:
       volumes:
         # Before: "- configmyservice:/config", with a "configmyservice" volume using the local-persist driver
         - ${HOST_CONFIG_PATH}/myservice:/config
   ```

3. Run ``./run-seedbox.sh``. For each media volume, Docker Compose asks ``Volume "seedbox_torrents" exists but doesn't match configuration in compose file. Recreate (data will be lost)?``. Answer ``y``: despite the message, only the Docker volume (a pointer to your directory) is created again, and the plugin never deletes the content of the directory. If you answer ``n``, the previous volume is kept and still needs the plugin.
4. Remove the volumes which are not used anymore (their content stays on your disk), then uninstall the plugin once the list is empty:

   ```sh
   docker volume ls --filter driver=local-persist
   docker volume rm <name> [<name>...]

   # Installation made by the init script of the seedbox (systemd)
   sudo systemctl disable --now docker-volume-local-persist
   sudo rm /etc/systemd/system/docker-volume-local-persist.service /usr/bin/docker-volume-local-persist
   sudo systemctl daemon-reload
   ```

## If git pull fails

If you edited files which were tracked by git in v2 (a service in ``services/``, ``traefik/traefik.yaml``, ``traefik/custom/middlewares.yaml``...), ``git pull`` refuses to overwrite them. Keep your changes aside, then put them back in files which are yours:

```sh
# Save your changes and get back to the original files
git diff > my-changes.patch
git checkout .
git pull
# Create your files from the templates
tools/sync-templates.sh
# Report your changes by hand (see below)
cat my-changes.patch
./run-seedbox.sh
```

| Your changes were in | Put them in |
|----------------------|-------------|
| ``services/<name>.yaml`` | ``services/<name>/custom/compose.override.yaml``, with only what you changed: see [Customize a bundled service](configuration.md#customize-a-bundled-service) |
| ``traefik/traefik.yaml``, ``traefik/custom/middlewares.yaml``, ``traefik/custom/tls.yaml`` | ``services/traefik/custom/traefik.yaml``, ``middlewares.yaml``, ``tls.yaml``: they are yours now |

> In v2, ``traefik/traefik.yaml`` was modified by ``run-seedbox.sh`` when ``TRAEFIK_CUSTOM_ACME_RESOLVER`` is set: you will have this change (``dnsChallenge``) in your patch even if you never edited the file. Ignore it: it is now applied on the generated file only.

## Rollback

Go back to the previous version with git (``git checkout v2.2.2``), restore your ``config.yaml`` and ``.env.custom`` from ``.seedbox/backup/`` and move your files back from ``services/<name>/custom/`` and ``services/traefik/custom/rules/`` to ``services/custom/`` and ``samples/custom-traefik/``. Then run ``./run-seedbox.sh``.
