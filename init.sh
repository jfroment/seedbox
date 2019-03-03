#!/bin/bash

sudo touch /opt/traefik/acme.json && sudo chmod 600 /opt/traefik/acme.json
cp .env.sample .env
cp tunnel-options.sh.sample tunnel-options.sh
echo "Please edit .env file and tunnel-options.sh"
exit 0