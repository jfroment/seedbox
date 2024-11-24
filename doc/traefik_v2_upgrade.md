# September 2020 - Upgrade to Traefik v2 instructions

> This guide is useful if you already are using the seedbox but did not update before September 2020.

Before upgrading Traefik to version 2, please check the following:

- In this repo, Traefik v2 upgrade is as seamless as possible (same environment variables than before, out-of-the-box config file...).
- **First, ``git pull`` to grab the latest code.**
- The ``HTTP_PASSWORD`` variable now must be simple-quoted in the .env file. See the updated ``.env.sample`` file (which has also been reorganized)
- Run ``init.sh`` in order to create required Docker objects (network name has changed).
- You can update your acme.json to a Traefik v2-compliant one by doing the following (before launching Traefik v2):

```sh
mkdir -p /tmp/migration
cd /tmp/migration
sudo cp /opt/traefik/acme.json .
sudo chmod 775 /tmp/migration/acme.json
# Do *NOT* forget the --resolver at the end! (le = Let's Encrypt resolver, see traefik/traefik.yml)
docker run --rm -v ${PWD}:/data -w /data containous/traefik-migration-tool acme -i acme.json -o acme2.json --resolver le
mkdir -p /data/config/traefik
sudo cp acme2.json /data/config/traefik/acme.json
sudo chmod 600 /data/config/traefik/acme.json
# When you already have a backup!
sudo rm -rf /opt/traefik /tmp/migration
```

- As from Traefik v2, as Http Authentication is now possible on the Traefik console, the latter is enabled at ``traefik.yourdomain.com``.
- After all this, you can simply do: ``./update-all.sh``! Voilà!
