#!/bin/bash
set -e
################################################################################
###                      ===  config-updater.sh  ===                         ###
### Script which takes as input the old format config file (services.conf)   ###
### and transforms it in the new format in yaml, using jq and yq             ###
################################################################################

cleanup_on_exit() {
  rm -f tmp.json config.json
}
trap cleanup_on_exit EXIT

# Load common functions
source config/tools.sh

# Check that required tools are installed
check_utilities

if [[ ! -f services.conf ]]; then
  echo "[$0] ERROR. Could nof find services.conf. Exiting."
  exit 1
fi

jq -n '{"services": []}' > config.json

# First, add Traefik as it was not explicitely set by default in old config file (services.conf)
if ! grep -q "traefik" services.conf; then
  jq -r '.services[.services| length] |= . + 
    {
      "name": "traefik",
      "enabled": true,
      "traefik": {
        "enabled": true,
        "rules": [
          {
            "host": "traefik.'$(echo '${TRAEFIK_DOMAIN}')'",
            "service": "api@internal",
            "httpAuth": true,
          }
        ]
      }
    }' config.json > tmp.json
  rm -f config.json
  mv tmp.json config.json
fi

cat services.conf | while read line || [[ -n $line ]]; do
  key=$(echo $line | sed -r "s/^(.*):.*$/\1/")
  enabled="true"
  if grep -q "disable" <<< $line; then
    enabled="false"
  fi

  # Compatibility for services.conf already on dev (with temporary syntax -vpn)
  if grep -q "\-vpn" <<< $line; then continue; fi

  enableVpn="false"
  # If this service is disabled AND another one in the file is enabled with VPN mode, keep that information
  if grep -q "$key-vpn: enable" services.conf; then
    if [[ enabled="false" ]]; then
      #echo "[$0] $key => another service detected enabled with vpn..."
      enableVpn="true"
      enabled="true"
    fi
  fi

  if grep -q "\-hardware-transcoding" <<< $line; then continue; fi

  # Define if Traefik should be enabled on the service
  case $key in
    flaresolverr|gluetun)
      enableTraefik="false"
      rules=$(jq -n '[]')
      ;;
    *)
      enableTraefik="true"
      # If Traefik enabled => define if http auth Traefik middleware must be set by default
      case $key in
        kavita|komga|nextcloud|ombi|overseerr|plex|portainer|tautulli)
          defaultHttpAuth="false"
          ;;
        *)
          defaultHttpAuth="true"
          ;;
      esac
      # Define scheme // For nextcloud, scheme must be https
      internalScheme="http"
      [[ $key == "nextcloud" ]] && internalScheme="https"
      
      # Define service default port from bundled config file
      internalPort=$(cat config/ports | { grep $key || true; } | sed -r "s/^${key}: (.*)$/\1/")
      rules=$(jq -n '[
          {
            "host": "'"$key"'.'$(echo '${TRAEFIK_DOMAIN}')'",
            "httpAuth": '"${defaultHttpAuth}"',
            "internalPort": '"${internalPort}"',
            "internalScheme": "'"${internalScheme}"'"
          }
        ]')
      ;;
  esac

  jq -r --argjson RULES "$rules" '.services[.services| length] |= . + 
    {
      "name": "'"$key"'",
      "enabled": '"${enabled}"',
      "vpn": '"${enableVpn}"',
      "traefik": {
        "enabled": '"${enableTraefik}"',
        "rules": $RULES
      }
    }' config.json > tmp.json
  rm -f config.json
  mv tmp.json config.json

done

# Transform json into yaml, easier to manipulate for the user
cat config.json | yq e -P - > config.yaml