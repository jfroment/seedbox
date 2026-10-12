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

The migration is automatic: on the first run, ``run-seedbox.sh`` detects the v2 format and calls ``tools/migrate-v3.sh``. Nothing is deleted: files are moved, and your ``config.yaml`` is saved in ``backup/`` before being converted. After the migration, the generated Traefik rules and the containers are the same as before.

## What the migration does

| Before (v2) | After (v3) | |
|-------------|------------|-|
| ``services/<name>.yaml`` | ``services/<name>/compose.yaml`` | Done by git. Do not edit these files anymore: put your changes in ``services/<name>/custom/compose.override.yaml`` |
| ``services/plex-hardware-transcoding.yaml`` | ``services/plex/compose-hardware-transcoding.yaml`` | ``customFile`` is updated in your ``config.yaml`` |
| ``services/custom/<file>.yaml`` | ``services/<name>/custom/compose.yaml`` | ``<name>`` is the name of the service in ``config.yaml``. ``customFile`` is not needed anymore and is removed |
| ``samples/custom-traefik/*`` | ``services/traefik/custom/rules/*`` | Including your ``.disabled`` files |
| ``traefik/traefik.yaml``, ``traefik/custom/middlewares.yaml``, ``traefik/custom/tls.yaml`` | ``services/traefik/custom/traefik.yaml``, ``middlewares.yaml``, ``tls.yaml`` | Yours now, created from the templates of ``services/traefik/`` |
| ``traefik/`` (mounted in the Traefik container) | ``services/traefik/generated-config/`` | Generated on each run. The old directory is moved to ``backup/`` once Traefik is updated |
| ``samples/docker-compose.sample.nfs.yaml`` | ``docker-compose.nfs.sample.yaml`` | |
| ``services/generated/``, ``env/`` | ``.seedbox/generated/`` | Nothing to do, these files are generated on each run. The old directories are removed |
| ``config.yaml``, list of services with all their parameters | ``config.yaml``, only your changes | Previous version saved in ``backup/config.v2.<date>.yaml`` |
| ``.env.custom``, with variables prefixed by the name of the service | ``services/<name>/custom/service.env``, one file per service, without prefix | ``.env.custom`` is moved to ``backup/.env.custom.v2.<date>`` |

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

The migration creates these files from your ``.env.custom`` (for all services, enabled or not), then moves ``.env.custom`` to ``backup/``. Only the variables are migrated: your comments and commented variables stay in the backup. If some variables have a prefix which does not match any service, the migration lists them: nothing was using them in v2 either.

## After the migration

Everything works without any other action (except if you were using Overseerr, see the first point), but you may want to:

* **Replace Overseerr by Seerr**: Overseerr is not bundled anymore. If ``overseerr`` is in your ``config.yaml``, the script stops because its file does not exist: rename it to ``seerr``. Seerr uses its own directory (``$HOST_CONFIG_PATH/seerr``): see the [Seerr migration guide](https://docs.seerr.dev/migration-guide) to keep your data.
* **Shorten your ``config.yaml``**: if the same parameter is repeated on most services (``internalOnly: true`` for example), set it once in [``defaults``](configuration.md#how-rules-are-merged).
* **Use bundled services instead of yours**: some services were added in v3 (Jellyfin, Immich, Vaultwarden, Mealie...). If you already had your own file for one of them, it is now ``services/<name>/custom/compose.yaml`` and is still the one which is used. Delete it to use the bundled one (compare them first).
* **Turn your modified copies of bundled services into overrides**: same thing if you had a custom file for a bundled service (a modified Duplicati for example). It still works, but you do not get the updates of the bundled file. Keep only your changes in a ``compose.override.yaml`` instead: see [Customize a bundled service](configuration.md#customize-a-bundled-service).
* **Check the paths in your own services**: if the migration says that ``services/custom`` still contains files, they are files used by your services (config files, env files...). They still work where they are, but their place is now next to the service: move them to ``services/<name>/custom/`` and fix the path in its ``compose.yaml``.
* **Look at the new ``service.sample.env`` files**: they list the optional variables of each service.
* **Remove ``CHECK_FOR_OUTDATED_CONFIG``** from your ``.env``: it is not used anymore. You are now warned when a sample file changes, and ``tools/sync-templates.sh diff`` shows what changed.

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

Go back to the previous version with git (``git checkout v2.2.2``), restore your ``config.yaml`` and ``.env.custom`` from ``backup/`` and move your files back from ``services/<name>/custom/`` and ``services/traefik/custom/rules/`` to ``services/custom/`` and ``samples/custom-traefik/``. Then run ``./run-seedbox.sh``.
