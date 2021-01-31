#!/bin/bash

# Create/update http_auth file according to values in .env file
source .env
echo "${HTTP_USER}:${HTTP_PASSWORD}" > traefik/http_auth

# Fetch all YAML files
SERVICES=$(find services2 -name "*.yaml" -mindepth 1 -maxdepth 1 | sed -e 's/^/-f /')
ALL_SERVICES="-f docker-compose.yaml $SERVICES"

echo "[$0] ***** Pulling all images... *****"
docker-compose ${ALL_SERVICES} pull
echo "[$0] ***** Recreating containers if required... *****"
docker-compose ${ALL_SERVICES} up -d --remove-orphans
echo "[$0] ***** Done updating containers *****"
echo "[$0] ***** Clean unused images... *****"
docker image prune -af
echo "[$0] ***** Done! *****"
exit 0