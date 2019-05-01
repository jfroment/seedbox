#!/bin/bash

echo "[$0] Initializing..."
sudo mkdir /opt/traefik
sudo touch /opt/traefik/acme.json && sudo chmod 600 /opt/traefik/acme.json
cp .env.sample .env
echo "[$0] Please edit .env file"
exit 0