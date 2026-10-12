#!/bin/bash

##############################################################################
############################# V2 => V3 MIGRATION #############################
##############################################################################
#
# Called automatically by run-seedbox.sh when an installation coming from v2 is found.
# It can be run several times without risk: only what is still in v2 format is migrated.
# See doc/UPGRADE_V3.md.
#
#   1. Your own services:      services/custom/<file>.yaml  => services/<name>/custom/compose.yaml
#   2. Your own Traefik files: samples/custom-traefik/*     => services/traefik/custom/rules/
#   3. config.yaml: converted to v3 format. Only what differs from the default values of each
#      service is kept, so the result is the same as before.
#   4. .env.custom: split in one file per service  => services/<name>/custom/service.env
#
# Nothing is deleted: previous config.yaml and .env.custom are saved in .seedbox/backup/.

set -e
shopt -s nullglob

cd "$(dirname "$0")/.."
source tools/tools.sh
check_utilities

log() {
  echo "[$0] $@"
}

move() {
  #$1 => source
  #$2 => destination
  if [[ -e $2 ]]; then
    log "⚠️  $2 already exists: $1 was not moved, please check it."
    return 0
  fi
  mkdir -p "$(dirname "$2")"
  mv "$1" "$2"
  log "Moved $1 => $2"
}

trap "rm -f config.v2.json config.v3.tmp" EXIT
now=$(date +%Y%m%d%H%M%S)

config_is_v2=0
if [[ -f config.yaml && $(yq '.services | type' config.yaml) == "!!seq" ]]; then
  config_is_v2=1
  yq -o json config.yaml > config.v2.json
fi

if [[ ${config_is_v2} == 0 && ! -f .env.custom && ! -d services/custom && ! -d samples/custom-traefik ]]; then
  log "Nothing to migrate."
  exit 0
fi

log "***** Migrating to v3... *****"

###################################### Your own services ######################################

# Custom files used in config.yaml: the directory has the name of the service
if [[ ${config_is_v2} == 1 ]]; then
  while read -r json; do
    name=$(echo "$json" | jq -r .name)
    customFile=$(echo "$json" | jq -r .customFile)
    if [[ ${customFile} == custom/* && -f services/${customFile} ]]; then
      move services/${customFile} services/${name}/custom/compose.yaml
    fi
  done < <(jq -c '.services[] | select(.customFile != null)' config.v2.json)
fi
# Other custom files
for f in services/custom/*.yaml services/custom/*.yml; do
  name=$(basename $f); name=${name%.*}
  move $f services/${name}/custom/compose.yaml
done
if [[ -d services/custom ]] && ! rmdir services/custom 2>/dev/null; then
  log "⚠️  services/custom still contains files: move them next to the service which uses them (services/<name>/custom/) and fix their path in its compose.yaml."
fi

#################################### Your own Traefik files ###################################

for f in samples/custom-traefik/*; do
  [[ $(basename $f) == "README.md" ]] && continue
  move $f services/traefik/custom/rules/$(basename $f)
done
[[ -d samples/custom-traefik ]] && rmdir samples/custom-traefik 2>/dev/null || true
[[ -d samples ]] && rmdir samples 2>/dev/null || true

# Generated files are now in .seedbox/generated
if [[ -d services/generated ]]; then
  rm -f services/generated/*.yaml
  rmdir services/generated 2>/dev/null || true
fi

######################################### config.yaml #########################################

if [[ ${config_is_v2} == 1 ]]; then
  while read -r json; do
    name=$(echo "$json" | jq -r .name)

    # "customFile" is now relative to the directory of the service
    customFile=$(echo "$json" | jq -r '.customFile // ""')
    if [[ ${customFile} == custom/* ]]; then
      # Moved above to services/<name>/custom/compose.yaml, which is used by default
      customFile=""
    elif [[ ${customFile} == "plex-hardware-transcoding.yaml" ]]; then
      customFile="compose-hardware-transcoding.yaml"
    elif [[ -n ${customFile} && -f services/${customFile} ]]; then
      move services/${customFile} services/${name}/custom/$(basename ${customFile})
      customFile=$(basename ${customFile})
    fi

    meta=$(get_service_metadata ${name})

    # Keep only what differs from the default values of the service
    jq -n -c --arg name "${name}" --arg customFile "${customFile}" --argjson s "${json}" --argjson meta "${meta}" '
      ($meta.rules // []) as $defaults
      | (if $s.traefik.enabled == false then [] else ($s.traefik.rules // []) end) as $rules
      | [ range(0; $rules | length) as $i
          | ($defaults[$i] // {}) as $d
          | $rules[$i] as $r
          # Parameters with another value than the default one + flags enabled by default which were not set
          | ($r | with_entries(select($d[.key] != .value)))
            + ($d | with_entries(.key as $key | select(.value == true and ($r | has($key) | not)) | .value = false))
        ]
      | until(length == 0 or .[-1] != {}; .[:-1]) as $overrides
      | { ($name): (
          {}
          + (if $s.enabled == false then {enabled: false} else {} end)
          + (if $s.vpn == true then {vpn: true} else {} end)
          + (if $customFile != "" then {customFile: $customFile} else {} end)
          + (if ($rules | length) == 0 and ($defaults | length) > 0 then {traefik: false} else {} end)
          + (if ($overrides | length) > 0 then {rules: $overrides} else {} end)
        ) }' >> config.v3.tmp
  done < <(jq -c '.services[]' config.v2.json)

  mkdir -p .seedbox/backup
  backup=".seedbox/backup/config.v2.${now}.yaml"
  cp config.yaml ${backup}

  {
    echo "# Seedbox configuration (v3). Documentation: doc/configuration.md"
    echo "# Only what differs from the default values of each service is written here."
    echo "# Migrated from v2 format by $0 (previous version: ${backup})."
    jq -s '{services: add}' config.v3.tmp | yq -P
  } > config.yaml

  log "config.yaml converted to v3 format. Previous version saved in ${backup}"
fi

######################################### .env.custom #########################################

# Variables of .env.custom were prefixed by the name of the service: each service now has its own
# file, without prefix
if [[ -f .env.custom ]]; then
  for dir in services/*/; do
    name=$(basename ${dir})
    prefix="${name^^}_"
    if ! grep -q "^${prefix}" .env.custom; then
      continue
    fi
    envFile="services/${name}/custom/service.env"
    if [[ -e ${envFile} ]]; then
      log "⚠️  ${envFile} already exists: variables ${prefix}* of .env.custom were not migrated, please check them."
      continue
    fi
    mkdir -p "$(dirname ${envFile})"
    {
      echo "# Environment variables of ${name}, given to its container."
      echo "# Migrated from .env.custom by $0 (variables ${prefix}*, without the prefix)."
      [[ -f services/${name}/service.sample.env ]] && echo "# Other available variables: see services/${name}/service.sample.env"
      echo
      grep "^${prefix}" .env.custom | sed "s/^${prefix}//"
    } > ${envFile}
    log "Created ${envFile} from variables ${prefix}* of .env.custom"
  done

  # Variables which do not match any service
  pattern=$(for dir in services/*/; do name=$(basename ${dir}); echo -n "${name^^}_|"; done)
  orphans=$(grep -E "^[A-Za-z_]" .env.custom | grep -vE "^(${pattern%|})" | sed 's/=.*//' | tr '\n' ' ' || true)
  if [[ -n ${orphans} ]]; then
    log "⚠️  These variables of .env.custom do not match any service and were not migrated: ${orphans}"
  fi

  mkdir -p .seedbox/backup
  mv .env.custom .seedbox/backup/.env.custom.v2.${now}
  log ".env.custom is not used anymore: moved to .seedbox/backup/.env.custom.v2.${now}"
fi

log "***** Migration done. See doc/UPGRADE_V3.md for details. *****"
