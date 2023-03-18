#!/bin/bash

set -e

# Load common functions
source config/tools.sh

# Check that required tools are installed
check_utilities

SKIP_PULL=0
DEBUG=0

for i in "$@"; do
  case $i in
    --no-pull)
      SKIP_PULL=1
      ;;
    --debug)
      DEBUG=1
      ;;
    *)
      echo "[$0] ❌ ERROR: unknown parameter \"$i\""
      exit 1
      ;;
  esac
done

cleanup_on_exit() {
  rm -f rules.props *-vpn.props config.json
}
trap cleanup_on_exit EXIT

echo-debug() {
  if [[ ${DEBUG} == "1" ]]; then echo "$@"; fi
}

###############################################################################################
####################################### Load variables ########################################
###############################################################################################

echo "[$0] ***** Checking environment variables and files... *****"

if [[ ! -f .env ]]; then
  echo "[$0] ERROR. \".env\" file not found. Please copy \".env.sample\" and edit its values. Then, re-run this script."
  exit 1
fi

# Create/update http_auth file according to values in .env file
source .env
echo "${HTTP_USER}:${HTTP_PASSWORD}" > traefik/http_auth

## Traefik Certificate Resolver tweaks
rm -f traefik.env && touch traefik.env
if [[ ! -z ${TRAEFIK_CUSTOM_ACME_RESOLVER} ]]; then
  if [[ ! -f .env.custom ]]; then
    echo "[$0] Error. You need to have a .env.custom in order to use TRAEFIK_CUSTOM_ACME_RESOLVER variable."
    exit 1
  fi
  if [[ ${TRAEFIK_CUSTOM_ACME_RESOLVER} == "changeme" ]]; then
    echo "[$0] Error. Wrong value for TRAEFIK_CUSTOM_ACME_RESOLVER variable."
    exit 1
  fi
  yq 'del(.certificatesResolvers.le.acme.httpChallenge)' -i traefik/traefik.yaml
  yq '(.certificatesResolvers.le.acme.dnsChallenge.provider="'${TRAEFIK_CUSTOM_ACME_RESOLVER}'")' -i traefik/traefik.yaml
  sed '/^#/d' .env.custom >> traefik.env
fi

# Docker-compose settings
export COMPOSE_HTTP_TIMEOUT=240

# Retro-compatibility
[[ -z $HOST_CONFIG_PATH ]] && export HOST_CONFIG_PATH="/data/config"
[[ -z $HOST_MEDIA_PATH ]] && export HOST_MEDIA_PATH="/data/torrents"
[[ -z $DOWNLOAD_SUBFOLDER ]] && export DOWNLOAD_SUBFOLDER="deluge"
[[ -z $DOCKER_COMPOSE_BINARY ]] && export DOCKER_COMPOSE_BINARY="docker-compose"

if [[ ! -f config.yaml ]]; then
  echo "[$0] No config.yaml file found. Copying from sample file..."
  cp config.sample.yaml config.yaml
fi

###############################################################################################
###################################### Pre-flight checks ######################################
###############################################################################################

echo "[$0] ***** Checking configuration... *****"

yq eval -o json config.yaml > config.json

if [[ ${CHECK_FOR_OUTDATED_CONFIG} == true ]]; then
  nb_services=$(cat config.json | jq '.services | length')
  nb_services_sample=$(yq eval -o json config.sample.yaml | jq '.services | length')
  if [[ $nb_services_sample -gt $nb_services ]]; then
    echo "[$0] There are more services in the config.sample.yaml than in your config.yaml"
    echo "[$0] You should check config.sample.yaml because it seems there are new services available for you:"
    diff -u config.yaml config.sample.yaml | grep "name:" | grep -E "^\+" | sed "s/+  - name:/-/g" || true
  fi
fi

# Internal function which checks another function's number ($2) and return a boolean instead
check_result_service() {
  #$1 => service
  #$2 => nb to check
  if [[ $2 == 0 ]]; then
    false; return
  elif [[ $2 == 1 ]]; then
    true; return
  else
    echo "[$0] Error. Service \"$1\" is enabled more than once. Check your config.yaml file."
    exit 1
  fi
}

# Check if a service ($1) has been enabled in the config file
is_service_enabled() {
  local nb=$(cat config.json | jq --arg service $1 '[.services[] | select(.name==$service and .enabled==true)] | length')
  check_result_service $1 $nb
}

# Check if a service ($1) has been enabled AND has vpn enabled in the config file
has_vpn_enabled() {
  local nb=$(cat config.json | jq --arg service $1 '[.services[] | select(.name==$service and .enabled==true and .vpn==true)] | length')
  check_result_service $1 $nb
}

# Check if some services have vpn enabled, that gluetun itself is enabled
nb_vpn=$(cat config.json | jq '[.services[] | select(.enabled==true and .vpn==true)] | length')
if [[ ${nb_vpn} -gt 0 ]] && ! is_service_enabled gluetun; then
  echo "[$0] ERROR. ${nb_vpn} VPN-enabled services have been enabled BUT gluetun has not been enabled. Please check your config.yaml file."
  exit 1
fi

# Determine what host Flood should connect to
# => If deluge vpn is enabled => gluetun
# => If deluge vpn is disabled => deluge
if is_service_enabled flood; then
  # Check that if flood is enabled, deluge should also be enabled
  if ! is_service_enabled deluge; then
    echo "[$0] ERROR. Flood is enabled but Deluge is not. Please either enable Deluge or disable Flood as Flood depends on Deluge."
    exit 1
  fi
  # Determine deluge hostname (for flood) based on the VPN status (enabled or not) of deluge
  if has_vpn_enabled deluge; then
    export DELUGE_HOST="gluetun"
  else
    export DELUGE_HOST="deluge"
  fi

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
fi

# Check that if calibre-web is enabled, calibre should also be enabled
if is_service_enabled calibre-web && ! is_service_enabled calibre; then
  echo "[$0] ERROR. Calibre-web is enabled but Calibre is not. Please either enable Calibre or disable Calibre-web as Calibre-web depends on Calibre."
  exit 1
fi

# Apply other arbitrary custom Traefik config files
rm -f $f traefik/custom/custom-*
for f in `find samples/custom-traefik -maxdepth 1 -mindepth 1 -type f | grep -E "\.yml$|\.yaml$" | sort`; do
  echo "[$0] Applying custom Traefik config $f..."
  cp $f traefik/custom/custom-$(basename $f)
done

# Detect Synology devices for Netdata compatibility
if is_service_enabled netdata; then
  if [[ $(uname -a | { grep synology || true; } | wc -l) -eq 1 ]]; then
    export OS_RELEASE_FILEPATH="/etc/VERSION"
  else
    export OS_RELEASE_FILEPATH="/etc/os-release"
  fi
fi

###############################################################################################
####################################### SERVICES PARSING ######################################
###############################################################################################

echo "[$0] ***** Generating configuration... *****"

# Cleanup files before start, in case there was a change we start from scratch at every script execution
rm -f services/generated/*-vpn.yaml

ALL_SERVICES="-f docker-compose.yaml"

# Parse the config.yaml master configuration file
for json in $(yq eval -o json config.yaml | jq -c ".services[]"); do
  name=$(echo $json | jq -r .name)
  enabled=$(echo $json | jq -r .enabled)
  vpn=$(echo $json | jq -r .vpn)

  # Skip disabled services
  if [[ ${enabled} == "false" ]]; then
    echo-debug "[$0] Service $name is disabled. Skipping it."
    continue
  fi

  echo-debug "[$0] ➡️  Parsing service: \"$name\"..."

  # Default docker-compose filename is the service name + .yaml.
  # Take into account explicit filename if specified in config
  customFile=$(echo $json | jq -r .customFile)
  file="$name.yaml"
  if [[ ${customFile} != "null" ]]; then 
    file=${customFile}
  fi
  echo-debug "[$0]    File: \"$file\"..."

  # Append $file to global list of files which will be passed to docker commands
  ALL_SERVICES="${ALL_SERVICES} -f services/${file}"

  # For services with VPN enabled, add a docker-compose "override" file specifying that the service network should
  # go through gluetun (main vpn client service).
  if [[ ${vpn} == "true" ]]; then
    echo "services.${name}.network_mode: service:gluetun" > ${name}-vpn.props
    yq -p=props ${name}-vpn.props > services/generated/${name}-vpn.yaml
    rm -f ${name}-vpn.props
    # Append config/${name}-vpn.yaml to global list of files which will be passed to docker commands
    ALL_SERVICES="${ALL_SERVICES} -f services/generated/${name}-vpn.yaml"
  fi

  ###################################### TRAEFIK RULES ######################################

  # Skip this part for services which have Traefik rules disabled in config
  traefikEnabled=$(echo $json | jq -r .traefik.enabled)
  if [[ ${traefikEnabled} == "false" ]]; then
    echo-debug "[$0]    Traefik is disabled. Skipping rules creation..."
    continue
  fi

  # Loop over all Traefik rules and create the corresponding entries in the generated rules.yaml
  echo-debug "[$0]    Generating Traefik rules..."
  i=0
  for rule in $(echo $json | jq -c .traefik.rules[]); do
    ((i=i+1))
    host=$(echo $rule | jq -r .host)
    internalPort=$(echo $rule | jq -r .internalPort)
    httpAuth=$(echo $rule | jq -r .httpAuth)
    echo-debug "[$0]      Host => ${host}"
    echo-debug "[$0]      Internal Port => ${internalPort}"
    echo-debug "[$0]      Http Authentication => ${httpAuth}"

    # If VPN => Traefik rule should redirect to gluetun container
    backendHost=${name}
    [[ ${vpn} == "true" ]] && backendHost="gluetun"

    # Handle custom scheme (default if non-specified is http)
    internalScheme="http"
    customInternalScheme=$(echo $rule | jq -r .internalScheme)
    [[ ${customInternalScheme} != "null" ]] && internalScheme=${customInternalScheme}

    # Transform the bash syntax into Traefik/go one => anything.${TRAEFIK_DOMAIN} to anything.{{ env "TRAEFIK_DOMAIN" }}
    hostTraefik=$(echo ${host} | sed --regexp-extended 's/^(.*)(\$\{(.*)\})/\1\{\{ env "\3" \}\}/')

    ruleId="${name}-${i}"
    echo 'http.routers.'"${ruleId}"'.rule: Host(`'${hostTraefik}'`)' >> rules.props

    middlewareCount=0
    if [[ ${httpAuth} == "true" ]]; then
      echo "http.routers.${ruleId}.middlewares.${middlewareCount}: common-auth@file" >> rules.props
      ((middlewareCount=middlewareCount+1))
    fi

    traefikService=$(echo $rule | jq -r .service)
    if [[ ${traefikService} != "null" ]]; then
      echo "http.routers.${ruleId}.service: ${traefikService}" >> rules.props
    else
      echo "http.routers.${ruleId}.service: ${ruleId}" >> rules.props
    fi

    # Check if httpOnly flag is enabled
    # If enabled => Specify to use only "insecure" (port 80) entrypoint
    # If not => use all entryPoints (by not specifying any) but force redirection to https
    httpOnly=$(echo $rule | jq -r .httpOnly)
    if [[ ${httpOnly} == true ]]; then
      echo "http.routers.${ruleId}.entryPoints.0: insecure" >> rules.props
    else
      echo "http.routers.${ruleId}.middlewares.${middlewareCount}: redirect-to-https" >> rules.props
      ((middlewareCount=middlewareCount+1))
    fi

    # If the specified service does not contain a "@" => we create it
    # If the service has a @, it means it is defined elsewhere so we do not create it (custom file, @internal...)
    if echo ${traefikService} | grep -vq "@"; then
      echo "http.services.${ruleId}.loadBalancer.servers.0.url: ${internalScheme}://${backendHost}:${internalPort}" >> rules.props
    fi
    
  done
done

# Convert properties files into Traefik-ready YAML and place it in the correct folder loaded by Traefik
mv traefik/custom/dynamic-rules.yaml traefik/custom/dynamic-rules-old.yaml || true
yq -p=props rules.props > traefik/custom/dynamic-rules.yaml
rm -f rules.props

# Post-transformations on the rules file
# sed -i "s/EMPTYMAP/{}/g" traefik/custom/dynamic-rules.yaml
# Add simple quotes around Host rule
sed -i --regexp-extended "s/^(.*: )(Host.*$)/\1'\2'/g" traefik/custom/dynamic-rules.yaml
# Add double quotes around the backend traefik service
sed -i --regexp-extended "s/^(.*url: )(.*$)/\1\"\2\"/g" traefik/custom/dynamic-rules.yaml

rm -f traefik/custom/dynamic-rules-old.yaml

echo-debug "[$0] Here is the list of all files which are going to be processed: ${ALL_SERVICES}"

echo "[$0] ***** Config OK. Launching services... *****"

if [[ "${SKIP_PULL}" != "1" ]]; then
  echo "[$0] ***** Pulling all images... *****"
  ${DOCKER_COMPOSE_BINARY} ${ALL_SERVICES} pull
fi

echo "[$0] ***** Recreating containers if required... *****"
${DOCKER_COMPOSE_BINARY} ${ALL_SERVICES} up -d --remove-orphans
echo "[$0] ***** Done updating containers *****"

echo "[$0] ***** Clean unused images and volumes... *****"
docker image prune -af
docker volume prune  -f

echo "[$0] ***** Done! *****"
exit 0