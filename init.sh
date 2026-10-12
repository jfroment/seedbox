#!/bin/bash

echo "[$0] Initializing..."

# Create docker network
docker network create traefik-network 2>&1 || true

echo "Installing local-persist docker driver... (will prompt for password for sudo access)"
sudo tools/local-persist.sh

# Create all files from templates (.env, config.yaml, docker-compose.yaml, files of enabled services...)
tools/sync-templates.sh
echo "[$0] Please edit .env file"
echo "[$0] Please also edit the files created in the custom directory of services (see above and documentation)."

echo "[$0] Done."
exit 0