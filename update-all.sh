#!/bin/bash

set -e

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
export COMPOSE_HTTP_TIMEOUT=240

# Retro-compatibility
[[ -z $HOST_CONFIG_PATH ]] && export HOST_CONFIG_PATH="/data/config"
[[ -z $HOST_MEDIA_PATH ]] && export HOST_MEDIA_PATH="/data/torrents"
[[ -z $DOWNLOAD_SUBFOLDER ]] && export DOWNLOAD_SUBFOLDER="deluge"

if [[ ! -f services.conf ]]; then
  echo "[$0] No services.conf file found. Copying from sample file..."
  cp services.conf.sample services.conf
fi

# Alert in case new services have been added (or removed) in sample but active file has not changed
NB_SERVICES_ACTIVE=$(cat services.conf | wc -l)
NB_SERVICES_ORIG=$(cat services.conf.sample | wc -l)
if [[ ${NB_SERVICES_ACTIVE} != ${NB_SERVICES_ORIG} ]]; then
  echo "[$0] Your services.conf file seems outdated. It appears there are new services available, or services that have been removed."
  diff -yt services.conf services.conf.sample || true
  echo ""
fi

# Check if *-vpn services are enabled. If so, check that gluetun is enabled.
if [[ $(cat services.conf | { grep -E ".*vpn: enable" || true; } | wc -l) -ge 1 ]]; then
  if [[ $(cat services.conf | { grep "gluetun: enable" || true; } | wc -l) -eq 0 ]]; then
    echo "[$0] ERROR. A VPN-enabled service has been enabled BUT gluetun has not been enabled. Please check your services.conf file."
    echo "******* Exiting *******"
    exit 1
  fi
fi

# Check if there are no conflict in enabled services (for example, you cannot enable deluge AND deluge-vpn)
for svc in deluge plex jdownloader; do
  if [[ $(cat services.conf | { grep -E "${svc}.*: enable" || true; } | wc -l) -gt 1 ]]; then
    echo "[$0] ERROR. You cannot enable multiple ${svc^} services simultaneously. Please edit this section in your services.conf file:"
    cat services.conf | { grep -E "${svc}.*: enable" || true; }
    echo "******* Exiting *******"
    exit 1
  fi
done

# Determine what host Flood should connect to
# => If deluge-vpn is enabled => gluetun
# => If deluge is enabled => deluge
if [[ $(cat services.conf | { grep -E "flood\: enable" || true; } | wc -l) -eq 1 ]]; then
  if [[ $(cat services.conf | { grep -E "deluge\-vpn\: enable" || true; } | wc -l) -eq 1 ]]; then
    export DELUGE_HOST="gluetun"
  elif [[ $(cat services.conf | { grep -E "deluge\: enable" || true; } | wc -l) -eq 1 ]]; then
    export DELUGE_HOST="deluge"
  fi
fi

# Apply Traefik dynamic files in traefik conf directory if VPN are enabled for some services
for svc in $(cat services.conf | grep "\-vpn: enable" | sed -E "s/(.*)\: enable/\1/g"); do
  if [[ -f samples/traefik-${svc}.yaml ]]; then
    echo "[$0] traefik-$svc.yaml file detected in samples/ directory. Applying into Traefik runtime config directory..."
    cp samples/traefik-${svc}.yaml traefik/custom/dynamic-${svc}.yaml
  else
    echo "[$0] No custom traefik file found in samples/directory for app $svc. Skipping..."
  fi
done

# Apply other arbitrary custom Traefik config files
for f in `find samples/custom-traefik -maxdepth 1 -mindepth 1 -type f | grep -E "\.yml$|\.yaml$" | sort`; do
  echo "[$0] Applying custom Traefik config $f..."
  cp $f traefik/custom/dynamic-$(basename $f)
done

# Detect Synology devices for Netdata compatibility
if [[ $(cat services.conf | { grep -E "netdata\: enable" || true; } | wc -l) -eq 1 ]]; then
  if [[ $(uname -a | { grep synology || true; } | wc -l) -eq 1 ]]; then
    export OS_RELEASE_FILEPATH="/etc/VERSION"
  else
    export OS_RELEASE_FILEPATH="/etc/os-release"
  fi
fi

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
  if ! grep -q "flood" $HOST_CONFIG_PATH/deluge/auth; then
    echo "flood:${FLOOD_PASSWORD}:10" >> $HOST_CONFIG_PATH/deluge/auth
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