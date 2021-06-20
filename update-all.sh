#!/bin/bash

SKIP_PULL=0

for i in "$@"; do
  case $i in
    --no-pull)
      SKIP_PULL=1
      ;;
    *)
      echo "[$0] ❌ ERROR: unknown parameter \"$i\""
      exit 1
      ;;
  esac
done

# Create/update http_auth file according to values in .env file
source .env
echo "${HTTP_USER}:${HTTP_PASSWORD}" > traefik/http_auth

# Docker-compose settings
COMPOSE_HTTP_TIMEOUT=240

# Fetch all YAML files
disabled_pattern=""
while read -r line ; do
  disabled_pattern="${disabled_pattern} ! -name $line.yaml"
done < <(grep "disable" services.conf | awk -F : '{print  $1}' )

SERVICES=$(find services -mindepth 1 -maxdepth 1 -name "*.yaml" ${disabled_pattern} | sed -e 's/^/-f /')
ALL_SERVICES="-f docker-compose.yaml $SERVICES"

# Specific instructions for Flood
# User for Deluge daemon RPC has to be created in deluge auth config file
if [[ ! -z ${FLOOD_PASSWORD} && ${FLOOD_AUTOCREATE_USER_IN_DELUGE_DAEMON} == true ]]; then
  if ! grep -q "flood" /data/config/deluge/auth; then
    echo "flood:${FLOOD_PASSWORD}:10" >> /data/config/deluge/auth
  else
    echo "[$0] No need to add user/password for flood as it has already been created."
    echo "[$0] Consider setting FLOOD_AUTOCREATE_USER_IN_DELUGE_DAEMON variable to false in .env file."
  fi
fi

if [[ "${SKIP_PULL}" != "1" ]]; then
  echo "[$0] ***** Pulling all images... *****"
  docker-compose ${ALL_SERVICES} pull
fi

echo "[$0] ***** Recreating containers if required... *****"
docker-compose ${ALL_SERVICES} up -d --remove-orphans
echo "[$0] ***** Done updating containers *****"
echo "[$0] ***** Clean unused images and volumes... *****"
docker image prune -af
docker volume prune  -f
echo "[$0] ***** Done! *****"
exit 0