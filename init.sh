#!/bin/bash

echo "[$0] Initializing..."
docker network create traefik-network 2>&1 || true
if [[ ! -f .env ]]; then
  cp .env.sample .env
  echo "[$0] Please edit .env file"
fi
echo "[$0] Done."
exit 0