#!/bin/bash

echo "[$0] Initializing..."

# Create docker network
docker network create traefik-network 2>&1 || true

echo "Installing local-persist docker driver... (will prompt for password for sudo access)"
sudo tools/local-persist.sh

# Copy env file
if [[ ! -f .env ]]; then
  cp .env.sample .env
  echo "[$0] Please edit .env file"
fi

# Copy custom env file
if [[ ! -f .env.custom ]]; then
  cp .env.custom.sample .env.custom
  echo "[$0] Please edit .env.custom file if you want more customization (see documentation)."
fi

# Copy sample docker compose file
if [[ ! -f docker-compose.yaml ]]; then
  cp docker-compose.sample.yaml docker-compose.yaml
fi

echo "[$0] Done."
exit 0