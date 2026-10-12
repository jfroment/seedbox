# Services

One directory per service. Full documentation: [Configuration Guide](../doc/configuration.md).

Files of this directory are tracked by git: **never edit them**. Everything which is yours goes in the ``custom`` directory of the service, which is ignored by git:

```
services/
  sonarr/                       # a bundled service
    compose.yaml                #   its docker-compose file
    service.yaml                #   its default values (Traefik rules, required services)
    service.sample.env          #   optional: variables the service needs or supports
    custom/                     #   yours
      compose.override.yaml     #     your changes, merged on top of compose.yaml
      service.env               #     your environment variables for this service
  nginx/                        # a service you add: it only has a custom directory
    custom/
      compose.yaml              #     required: its docker-compose file
      service.env               #     optional: its environment variables
      service.yaml              #     optional: default Traefik rules and required services
      rules.yaml                #     optional: Traefik config file applied when the service is enabled
  traefik/
    traefik.sample.yaml         #   template: your copy is custom/traefik.yaml
    custom/
      traefik.yaml              #     configuration of Traefik itself (with middlewares.yaml and tls.yaml)
      rules/
        homeassistant.yaml      #     Traefik rules for something which is not a seedbox service
    generated-config/           #   generated on each run and mounted in Traefik. Do not edit
```

## Customize a bundled service

Create ``services/<name>/custom/compose.override.yaml`` with only what you want to change.
See [Customize a bundled service](../doc/configuration.md#customize-a-bundled-service).

## Add a service

Create ``services/<name>/custom/compose.yaml`` (docker-compose format, the service must be called ``<name>``), then add ``<name>`` in your ``config.yaml``.
See [Add your own service](../doc/configuration.md#add-your-own-service).

## Add Traefik rules for something which is not a seedbox service

Place a Traefik config file in ``services/traefik/custom/rules/``. All ``.yaml`` files of this directory are applied on each ``run-seedbox.sh`` execution. Rename a file to ``.yaml.disabled`` to disable it.
