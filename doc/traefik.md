# Traefik configuration

## Table of content

* [Use custom ACME provider](#use-custom-acme-provider)

## Use custom ACME provider

In order to use something else than the default HTTP challenge, you can set the variable ``TRAEFIK_CUSTOM_ACME_RESOLVER`` to the provider you want to use ([list of provider codes is here](https://doc.traefik.io/traefik/https/acme/#providers)) (e.g. ``cloudflare``) in your ``.env``.

Then, configure the required environment variables (listed in the above referenced list) in ``.env.custom`` file.
For example, with Cloudflare you should *at least* set both ``CF_API_EMAIL`` and ``CF_API_KEY``.

Then, the usual:

```sh
./run-seedbox.sh
```
