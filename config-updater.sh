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

# Check that jq is installed
if ! which jq >/dev/null; then
  echo "[$0] jq does not exist. Install it from here: https://stedolan.github.io/jq/download/"
  echo "[$0] Also, please make sure it is in the PATH."
  exit 1
fi

# Check that yq is installed
if ! which yq >/dev/null; then
  echo "[$0] yq does not exist. Install it from here: https://github.com/mikefarah/yq/releases"
  echo "[$0] Also, please make sure it is in the PATH."
  exit 1
fi

jq -n '{"services": []}' > config.json

while read -r line ; do
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
      echo "[$0] $key => another service detected enabled with vpn..."
      enableVpn="true"
    fi
  fi

  if grep -q "\-hardware-transcoding" <<< $line; then continue; fi

  # Define if Traefik should be enabled on the service
  case $key in
    flaresolverr)
      enableTraefik="false"
      rules=$(jq -n '[]')
      ;;
    *)
      enableTraefik="true"
      # If Traefik enabled => define if http auth Traefik middleware must be set by default
      case $key in
        gluetun|kavita|komga|nextcloud|ombi|overseerr|plex|portainer|tautulli)
          defaultHttpAuth="false"
          ;;
        *)
          defaultHttpAuth="true"
          ;;
      esac
      # Define service default port from bundled config file
      internalPort=$(cat config/ports | { grep $key || true; } | sed -r "s/^${key}: (.*)$/\1/")
      rules=$(jq -n '[
          {
            "host": "'"$key"'",
            "httpAuth": '"${defaultHttpAuth}"',
            "internalPort": '"${internalPort}"',
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

done < services.conf

# If we should enable Plex with hardware transcoding
# if grep -q -E "plex.*transcoding: enable" services.conf; then
#   if grep -q "plex: disable" services.conf; then
#     cat config.json | jq -r 'select(.services[].name=="plex") += {"plexHardwareTranscode":"enable"}' > tmp.json
#     rm -f config.json
#     mv tmp.json config.json
#   fi
# fi

#mv config.json config.bak.json

# Transform json into yaml, easier to manipulate for the user
cat config.json | yq e -P - > config.yaml