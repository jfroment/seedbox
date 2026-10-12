#!/bin/bash

set -e

# Always work from the directory of the seedbox, wherever the script is called from (cron, absolute path...)
cd "$(dirname "$0")"

# Load common functions
source tools/tools.sh

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
  rm -f rules.props *-vpn.props *-envfile.props config.json config.user.json config.services.tmp
  rm -f .seedbox/generated/*.tmp
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

if [[ ! -f docker-compose.yaml ]]; then
  echo "[$0] ERROR. \"docker-compose.yaml\" file not found. Please copy \"docker-compose.sample.yaml\" and edit its values if you need customization. Then, re-run this script."
  exit 1
fi

# Migrate the installation if it comes from v2 (config.yaml in v2 format, .env.custom file...)
if [[ -f .env.custom || ( -f config.yaml && $(yq '.services | type' config.yaml) == "!!seq" ) ]]; then
  tools/migrate-v3.sh
fi

# Create or update all files based on templates (config.yaml, services, traefik...)
tools/sync-templates.sh

# Traefik config directory (mounted in the Traefik container) is generated on each execution: static config,
# http authentication file and dynamic config files (your own ones + generated rules of all services).
# It is built aside, then applied at once at the end to avoid Traefik reloading a partial config.
TRAEFIK_CONFIG_DIR="services/traefik/generated-config"
TRAEFIK_BUILD_DIR=".seedbox/traefik-config"
rm -rf .seedbox/traefik-config
mkdir -p ${TRAEFIK_BUILD_DIR}/dynamic
cp services/traefik/custom/traefik.yaml ${TRAEFIK_BUILD_DIR}/traefik.yaml
cp services/traefik/custom/middlewares.yaml services/traefik/custom/tls.yaml ${TRAEFIK_BUILD_DIR}/dynamic/

# Load the variables of .env used by this script. They are read by Docker Compose itself (see read_env_files in
# tools/tools.sh), so the script and the containers always see the same values.
ENV_VARS=$(read_env_files .env)
for var in HTTP_USER HTTP_PASSWORD TRAEFIK_CUSTOM_ACME_RESOLVER HOST_CONFIG_PATH HOST_MEDIA_PATH DOWNLOAD_SUBFOLDER PUID PGID \
           FLOOD_AUTOCREATE_USER_IN_DELUGE_DAEMON DOCKER_PRUNE_AFTER_UPDATE COMPOSE_PROJECT_NAME; do
  printf -v "${var}" '%s' "$(env_value ${var} "${ENV_VARS}")"
done

# Name of the Docker Compose project: always the same, whatever the name of the directory of the seedbox
[[ -z $COMPOSE_PROJECT_NAME ]] && COMPOSE_PROJECT_NAME="seedbox"
export COMPOSE_PROJECT_NAME

# Create http_auth file according to values in .env file
echo "${HTTP_USER}:${HTTP_PASSWORD}" > ${TRAEFIK_BUILD_DIR}/http_auth

# Cleanup generated files before start, in case there was a change we start from scratch at every script execution
mkdir -p .seedbox/generated
rm -f .seedbox/generated/*-vpn.yaml
rm -f .seedbox/generated/*-envfile.yaml

## Traefik Certificate Resolver tweaks
if [[ ! -z ${TRAEFIK_CUSTOM_ACME_RESOLVER} ]]; then
  if [[ ${TRAEFIK_CUSTOM_ACME_RESOLVER} == "changeme" ]]; then
    echo "[$0] Error. Wrong value for TRAEFIK_CUSTOM_ACME_RESOLVER variable."
    exit 1
  fi
  yq 'del(.certificatesResolvers.le.acme.httpChallenge)' -i ${TRAEFIK_BUILD_DIR}/traefik.yaml
  yq '(.certificatesResolvers.le.acme.dnsChallenge.provider="'${TRAEFIK_CUSTOM_ACME_RESOLVER}'")' -i ${TRAEFIK_BUILD_DIR}/traefik.yaml
fi

# Default values
[[ -z $HOST_CONFIG_PATH ]] && export HOST_CONFIG_PATH="/data/config"
[[ -z $HOST_MEDIA_PATH ]] && export HOST_MEDIA_PATH="/data/torrents"
[[ -z $DOWNLOAD_SUBFOLDER ]] && export DOWNLOAD_SUBFOLDER="deluge"

###############################################################################################
###################################### Pre-flight checks ######################################
###############################################################################################

echo "[$0] ***** Checking configuration... *****"

# Build the complete configuration (config.json): for each service, default values come from the service.yaml
# file of its directory, then config.yaml overrides them.
yq eval -o json config.yaml > config.user.json

# Check that config.yaml only uses known parameters (they are described in config.schema.json): a typo in a
# parameter like "internalOnly" would otherwise be silently ignored
unknown=$(jq -r --slurpfile schema config.schema.json '
  $schema[0] as $s
  | ($s.properties | keys) as $top
  | ($s."$defs".service.properties | keys) as $service
  | ($s."$defs".rule.properties | keys) as $rule
  | (. // {}) as $config
  | ($config | keys[] | select(. as $k | $top | index($k) | not) | "\"\(.)\" at the top level"),
    ($config.defaults // {} | keys[] | select(. as $k | $rule | index($k) | not) | "\"\(.)\" in \"defaults\""),
    ($config.services // {} | to_entries[] | .key as $name | (.value // {}) as $v
      | if ($v | type) != "object" then "service \"\($name)\": its parameters must be a map"
        else
          ($v | keys[] | select(. as $k | $service | index($k) | not) | "\"\(.)\" in service \"\($name)\""),
          ($v.rules // [] | if type != "array" then "service \"\($name)\": \"rules\" must be a list"
            else (.[] | select(type == "object") | keys[] | select(. as $k | $rule | index($k) | not) | "\"\(.)\" in a rule of service \"\($name)\"") end)
        end)' config.user.json)
if [[ -n ${unknown} ]]; then
  echo "[$0] ERROR. Unknown parameters in your config.yaml file (typo?):"
  echo "${unknown}" | sed "s#^#[$0]   - #"
  echo "[$0] See doc/configuration.md#configuration-structure-and-parameters for the list of parameters."
  exit 1
fi
defaults=$(jq -c '.defaults // {}' config.user.json)
: > config.services.tmp
for name in $(jq -r '.services // {} | keys_unsorted[]' config.user.json); do
  user=$(jq -c --arg name "${name}" '.services[$name] // {}' config.user.json)

  # Each service lives in its own directory. Default docker-compose filename is compose.yaml.
  # Take into account explicit filename (in the same directory) if specified in config
  file=$(get_service_file ${name} $(echo "${user}" | jq -r '.customFile // "compose.yaml"'))
  meta=$(get_service_metadata ${name})

  # Traefik rules: default rules of the service, then "defaults" of config.yaml, then rules of the service
  # in config.yaml (the first one overrides the first default one, and so on)
  jq -n -c --arg name "${name}" --arg file "${file}" --argjson user "${user}" --argjson meta "${meta}" --argjson defaults "${defaults}" '
    ($meta.rules // []) as $metaRules
    | ($user.rules // []) as $userRules
    | [ range(0; [($metaRules | length), ($userRules | length)] | max) as $i
        | ($metaRules[$i] // {}) + $defaults + ($userRules[$i] // {}) ] as $rules
    | {
        name: $name,
        file: $file,
        enabled: ($user.enabled != false),
        vpn: ($user.vpn == true),
        requires: ($meta.requires // []),
        traefik: { enabled: ($user.traefik != false and ($rules | length) > 0), rules: $rules }
      }' >> config.services.tmp
done
jq -s '{services: .}' config.services.tmp > config.json
rm -f config.user.json config.services.tmp

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

# Check that services required by enabled services (see "requires" in their service.yaml) are enabled too
for json in $(jq -c '.services[] | select(.enabled==true)' config.json); do
  name=$(echo $json | jq -r .name)
  for required in $(echo $json | jq -r '.requires[]'); do
    if ! is_service_enabled ${required}; then
      echo "[$0] ERROR. \"${name}\" is enabled but \"${required}\" is not. Please either enable \"${required}\" or disable \"${name}\" as it depends on it."
      exit 1
    fi
  done
done

# Determine what host Flood should connect to
# => If deluge vpn is enabled => gluetun
# => If deluge vpn is disabled => deluge
if is_service_enabled flood; then
  if has_vpn_enabled deluge; then
    export DELUGE_HOST="gluetun"
  else
    export DELUGE_HOST="deluge"
  fi
fi

# Apply other arbitrary custom Traefik config files
# (Traefik config files which belong to a service are applied below, when parsing services)
if [[ -d services/traefik/custom/rules ]]; then
  for f in `find services/traefik/custom/rules -maxdepth 1 -mindepth 1 -type f | grep -E "\.yml$|\.yaml$" | sort`; do
    echo "[$0] Applying custom Traefik config $f..."
    cp $f ${TRAEFIK_BUILD_DIR}/dynamic/custom-$(basename $f)
  done
fi

###############################################################################################
####################################### SERVICES PARSING ######################################
###############################################################################################

echo "[$0] ***** Generating configuration... *****"

ALL_SERVICES="-f docker-compose.yaml"

GLOBAL_ENV_FILE=".env"

# Parse the config.yaml master configuration file
for json in $(jq -c ".services[]" config.json); do
  name=$(echo $json | jq -r .name)
  enabled=$(echo $json | jq -r .enabled)
  vpn=$(echo $json | jq -r .vpn)

  # Skip disabled services
  if [[ ${enabled} == "false" ]]; then
    echo-debug "[$0] Service $name is disabled. Skipping it."
    continue
  fi

  echo-debug "[$0] ➡️  Parsing service: \"$name\"..."

  file=$(echo $json | jq -r .file)
  echo-debug "[$0]    File: \"$file\"..."
  if [[ ! -f ${file} ]]; then
    echo "[$0] ERROR. File \"${file}\" not found for service \"${name}\". Please check your config.yaml file (\"customFile\" is relative to the directory of the service)."
    echo "[$0] If this service was removed from the seedbox (see CHANGELOG.md), remove it from your config.yaml or keep it as your own service: see doc/configuration.md#add-your-own-service"
    exit 1
  fi

  # Append $file to global list of files which will be passed to docker commands
  ALL_SERVICES="${ALL_SERVICES} -f ${file}"

  # Your own changes on the service (services/<name>/custom/compose.override.yaml) are merged on top of its file
  if [[ -f services/${name}/custom/compose.override.yaml ]]; then
    echo-debug "[$0]    Override: \"services/${name}/custom/compose.override.yaml\"..."
    ALL_SERVICES="${ALL_SERVICES} -f services/${name}/custom/compose.override.yaml"
  fi

  # Apply the Traefik dynamic config file of the service (rules.yaml) if it has one
  traefikFile=$(get_service_file ${name} rules.yaml)
  if [[ -f ${traefikFile} ]]; then
    echo-debug "[$0]    Applying Traefik config ${traefikFile}..."
    cp ${traefikFile} ${TRAEFIK_BUILD_DIR}/dynamic/service-${name}.yaml
  fi

  # For services with VPN enabled, add a docker-compose "override" file specifying that the service network should
  # go through gluetun (main vpn client service).
  if [[ ${vpn} == "true" ]]; then
    echo "services.${name}.network_mode: service:gluetun" > ${name}-vpn.props
    yq -p=props ${name}-vpn.props -o yaml > .seedbox/generated/${name}-vpn.yaml
    rm -f ${name}-vpn.props
    # Append config/${name}-vpn.yaml to global list of files which will be passed to docker commands
    ALL_SERVICES="${ALL_SERVICES} -f .seedbox/generated/${name}-vpn.yaml"
  fi

  # For services with their own environment variables (services/<name>/custom/service.env),
  # add a docker-compose override file in order to load them
  envFile=$(get_service_file ${name} service.env)
  if [[ -f ${envFile} ]]; then
    # Values of the sample file must have been changed
    if grep -q "^[^#]*=changeme" ${envFile}; then
      echo "[$0] ERROR. Some variables of service \"${name}\" still have the value \"changeme\". Please edit ${envFile}, then re-run this script."
      exit 1
    fi
    echo "services.${name}.env_file.0: ./${envFile}" > ${name}-envfile.props
    yq -p=props ${name}-envfile.props -o yaml > .seedbox/generated/${name}-envfile.yaml
    rm -f ${name}-envfile.props
    # Append the override file to global list of files which will be passed to docker commands
    ALL_SERVICES="${ALL_SERVICES} -f .seedbox/generated/${name}-envfile.yaml"
  fi

  # If we are on flood service AND autoconfig for flood password is set to true:
  # Check that the environment file of flood exists and variable defined
  # Do the deluge autoconfig - we already checked that deluge is enabled at this point
  if [[ ${name} == "flood" && ${FLOOD_AUTOCREATE_USER_IN_DELUGE_DAEMON} == true ]]; then
    # Specific instructions for Flood
    if [[ ! -f ${envFile} ]]; then
      echo "ERROR. You set variable \"FLOOD_AUTOCREATE_USER_IN_DELUGE_DAEMON\" to true but you did not specify \"FLOOD_PASSWORD\" in services/flood/custom/service.env."
      exit 1
    fi
    FLOOD_PASSWORD=$(env_value FLOOD_PASSWORD "$(read_env_files ${envFile})")
    # User for Deluge daemon RPC has to be created in deluge auth config file
    if [[ ! -z ${FLOOD_PASSWORD} ]]; then
      DELUGE_CONFIG_FILE="$HOST_CONFIG_PATH/deluge/auth"
      if [[ -r $DELUGE_CONFIG_FILE && -w $DELUGE_CONFIG_FILE ]]; then
        if ! grep -q "flood" ${DELUGE_CONFIG_FILE}; then
          echo "flood:${FLOOD_PASSWORD}:10" >> ${DELUGE_CONFIG_FILE}
        else
          echo "[$0] No need to add user/password for flood as it has already been created."
          echo "[$0] Consider setting FLOOD_AUTOCREATE_USER_IN_DELUGE_DAEMON variable to false in .env file."
        fi
      else
        echo "[$0] It seems you do not have permission to read or write to ${DELUGE_CONFIG_FILE} ."
        echo "[$0] Prompting for sudo password..."
        sudo bash <<EOF
if ! grep -q "flood" ${DELUGE_CONFIG_FILE}; then
  echo "flood:${FLOOD_PASSWORD}:10" >> ${DELUGE_CONFIG_FILE}
else
  echo "[$0] No need to add user/password for flood as it has already been created."
  echo "[$0] Consider setting FLOOD_AUTOCREATE_USER_IN_DELUGE_DAEMON variable to false in .env file."
fi
EOF
      fi
    else
      echo "ERROR. \"FLOOD_PASSWORD\" variable seems not defined but flood service still has variables defined. Please add the missing variable."
      exit 1
    fi
  fi


  ###### For services which have "command" field with environment variables ######
  var_in_cmd_detected="0"
  if [[ $(yq ".services.${name}.command[]" ${file} | { grep "\\$.*\}" || true; } | wc -l) -gt 0 ]]; then
    var_in_cmd_detected="1"
    echo-debug "[$0] Service ${name} has a command with environment variables..."
    # Extract variable names to test them
    yq ".services.${name}.command[]" ${file} | { grep "\\$.*\}" || true; } | sed -n -e 's/.*${\(\w\+\)}.*/\1/p' > .seedbox/generated/${name}-cmd.env.1.tmp
    # Check if these variables are defined in .env or in the environment file of the service (if it exists)
    if [[ -f ${envFile} ]]; then
      knownVars=$(read_env_files .env ${envFile})
    else
      knownVars=${ENV_VARS}
    fi
    while read p; do
      # If the command references a variable which is not known, throw an error
      if ! echo "${knownVars}" | grep -q "^${p}="; then
        echo "ERROR. Variable \"$p\" is referenced in \"command\" for service ${name} (file $file) but this variable is not defined in .env (or in ${envFile}). Please correct it or add a variable which will be used."
        exit 1
      fi
    done < .seedbox/generated/${name}-cmd.env.1.tmp
    rm -f .seedbox/generated/*.tmp
  fi

  # Handle case for command in a single line, not in array
  if [[ $(yq ".services.${name}.command" ${file} | { grep "\\$.*\}" || true; } | wc -l) -gt 0 ]]; then
    var_in_cmd_detected="1"
  fi

  # Workaround for now
  if [[ "${var_in_cmd_detected}" == "1" ]]; then
    # Only concat .env.concat with ${envFile} if it exists
    if [[ -f ${envFile} ]]; then
      cat ${GLOBAL_ENV_FILE} ${envFile} >> .env.concat.tmp
      rm -f .env.concat
      mv .env.concat.tmp .env.concat
      export GLOBAL_ENV_FILE=".env.concat"
    fi
    var_in_cmd_detected="0"
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
    internalOnly=$(echo $rule | jq -r .internalOnly)
    mtls=$(echo $rule | jq -r .mtls)
    httpOnly=$(echo $rule | jq -r .httpOnly)
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
    if [[ ${httpOnly} == "true" ]]; then
      # httpOnly flag: the rule only uses the "insecure" (port 80) entrypoint, without certificate
      if [[ ${mtls} == "true" ]]; then
        echo "[$0] ERROR. Rule \"${host}\" of service \"${name}\" has both \"httpOnly\" and \"mtls\": a client certificate cannot be required without https."
        exit 1
      fi
      echo 'http.routers.'"${ruleId}"'.entryPoints.0: insecure' >> rules.props
      HTTP_ONLY_RULES=1
    else
      echo 'http.routers.'"${ruleId}"'.entryPoints.0: secure' >> rules.props
      echo 'http.routers.'"${ruleId}"'.tls.certResolver: le' >> rules.props
      # Require a client certificate (mTLS): see "mtls" TLS option generated below
      if [[ ${mtls} == "true" ]]; then
        echo "http.routers.${ruleId}.tls.options: mtls@file" >> rules.props
      fi
    fi

    middlewareCount=0
    if [[ ${httpAuth} == "true" ]]; then
      echo "http.routers.${ruleId}.middlewares.${middlewareCount}: common-auth@file" >> rules.props
      ((middlewareCount=middlewareCount+1))
    fi

    if [[ ${internalOnly} == "true" ]]; then
      echo "http.routers.${ruleId}.middlewares.${middlewareCount}: internal-only@file" >> rules.props
      ((middlewareCount=middlewareCount+1))
    fi

    traefikService=$(echo $rule | jq -r .service)
    if [[ ${traefikService} != "null" ]]; then
      echo "http.routers.${ruleId}.service: ${traefikService}" >> rules.props
    else
      echo "http.routers.${ruleId}.service: ${ruleId}" >> rules.props
    fi

    # If the specified service does not contain a "@" => we create it
    # If the service has a @, it means it is defined elsewhere so we do not create it (custom file, @internal...)
    if echo ${traefikService} | grep -vq "@"; then
      echo "http.services.${ruleId}.loadBalancer.servers.0.url: ${internalScheme}://${backendHost}:${internalPort}" >> rules.props
    fi
    
  done
done

# The global redirection to https (see "redirections" in your traefik.yaml) has by default a higher priority than
# any rule: when some rules have the httpOnly flag, its priority is lowered so these rules are not redirected
if [[ ${HTTP_ONLY_RULES} == "1" && $(yq '.entryPoints.insecure.http.redirections.entryPoint | (. != null and .priority == null)' ${TRAEFIK_BUILD_DIR}/traefik.yaml) == "true" ]]; then
  yq -i '.entryPoints.insecure.http.redirections.entryPoint.priority = 1' ${TRAEFIK_BUILD_DIR}/traefik.yaml
fi

# Convert properties files into Traefik-ready YAML
yq -p=props rules.props -o yaml > ${TRAEFIK_BUILD_DIR}/dynamic/dynamic-rules.yaml
rm -f rules.props

# Post-transformations on the rules file
# Add simple quotes around Host rule
sed -i --regexp-extended "s/^(.*: )(Host.*$)/\1'\2'/g" ${TRAEFIK_BUILD_DIR}/dynamic/dynamic-rules.yaml
# Add double quotes around the backend traefik service
sed -i --regexp-extended "s/^(.*url: )(.*$)/\1\"\2\"/g" ${TRAEFIK_BUILD_DIR}/dynamic/dynamic-rules.yaml

# Client certificates (mTLS): the "mtls" TLS option requires a certificate signed by one of your Certificate
# Authorities. They are the files of services/traefik/custom/mtls/, and the one of VaulTLS if it is enabled.
mkdir -p ${TRAEFIK_BUILD_DIR}/mtls
if [[ -d services/traefik/custom/mtls ]]; then
  for f in `find services/traefik/custom/mtls -maxdepth 1 -mindepth 1 -type f | sort`; do
    cp $f ${TRAEFIK_BUILD_DIR}/mtls/
  done
fi
if is_service_enabled vaultls; then
  # Only the current Certificate Authority of VaulTLS (ca-tls.cert), not the previous ones it may keep (ca-<id>.pem):
  # replacing the Certificate Authority is the way to revoke certificates
  for f in ${HOST_CONFIG_PATH}/vaultls/ca/ca-tls.cert ${HOST_CONFIG_PATH}/vaultls/ca/ca.cert; do
    if [[ -r $f ]]; then
      cp $f ${TRAEFIK_BUILD_DIR}/mtls/vaultls-ca.cert
      break
    fi
  done
fi
if [[ -n $(ls ${TRAEFIK_BUILD_DIR}/mtls) ]]; then
  # Same settings as your default TLS option, plus the mandatory client certificate
  caFiles=$(ls ${TRAEFIK_BUILD_DIR}/mtls | sed 's#^#/etc/traefik/mtls/#' | jq -R . | jq -s -c .)
  {
    # Traefik only reloads this file when its content changes: the checksum makes it change with the certificates
    echo "# Generated. Certificate Authorities checksum: $(cat ${TRAEFIK_BUILD_DIR}/mtls/* | sha256sum | cut -d' ' -f1)"
    yq '{"tls": {"options": {"mtls": ((.tls.options.default // {}) * {"clientAuth": {"caFiles": '"${caFiles}"', "clientAuthType": "RequireAndVerifyClientCert"}})}}}' services/traefik/custom/tls.yaml
  } > ${TRAEFIK_BUILD_DIR}/dynamic/mtls.yaml
elif grep -rlq "mtls@file" ${TRAEFIK_BUILD_DIR}/dynamic; then
  # Never apply a rule which was supposed to be protected by a client certificate without this protection
  echo "[$0] ERROR. Some Traefik rules require a client certificate (mtls) but no Certificate Authority was found:"
  grep -rl "mtls@file" ${TRAEFIK_BUILD_DIR}/dynamic | sed "s#${TRAEFIK_BUILD_DIR}/dynamic/#[$0]   - #"
  echo "[$0] Place the certificate of your Certificate Authority in services/traefik/custom/mtls/ (see doc/apps/vaultls.md)."
  exit 1
fi

# Apply the generated Traefik config: replace files, then remove the ones which do not exist anymore
mkdir -p ${TRAEFIK_CONFIG_DIR}/dynamic ${TRAEFIK_CONFIG_DIR}/mtls
# Dynamic config is reloaded by Traefik on the fly, but static config (traefik.yaml) is only read when it starts
TRAEFIK_RESTART_REQUIRED=0
if [[ -f ${TRAEFIK_CONFIG_DIR}/traefik.yaml ]] && ! cmp -s ${TRAEFIK_BUILD_DIR}/traefik.yaml ${TRAEFIK_CONFIG_DIR}/traefik.yaml; then
  TRAEFIK_RESTART_REQUIRED=1
fi
cp ${TRAEFIK_BUILD_DIR}/traefik.yaml ${TRAEFIK_BUILD_DIR}/http_auth ${TRAEFIK_CONFIG_DIR}/
# Certificate Authorities first: the dynamic config refers to them
for dir in mtls dynamic; do
  for f in `find ${TRAEFIK_BUILD_DIR}/${dir} -maxdepth 1 -mindepth 1 -type f`; do
    cp $f ${TRAEFIK_CONFIG_DIR}/${dir}/
  done
done
for dir in dynamic mtls; do
  for f in `find ${TRAEFIK_CONFIG_DIR}/${dir} -maxdepth 1 -mindepth 1 -type f`; do
    if [[ ! -f ${TRAEFIK_BUILD_DIR}/${dir}/$(basename $f) ]]; then
      rm -f $f
    fi
  done
done

echo-debug "[$0] Here is the list of all files which are going to be processed: ${ALL_SERVICES}"

# Create a directory which does not exist yet, owned by the user of the containers (PUID and PGID of .env)
create_data_dir() {
  #$1 => directory
  local dir=$1 top=$1
  [[ -e ${dir} ]] && return 0
  # First directory which has to be created (the parents of $1 may be missing too)
  while [[ ! -e $(dirname ${top}) ]]; do
    top=$(dirname ${top})
  done
  mkdir -p ${dir} 2>/dev/null || return 1
  echo "[$0] Created directory ${dir}"
  if [[ -n ${PUID} && -n ${PGID} && "$(id -u):$(id -g)" != "${PUID}:${PGID}" ]]; then
    # Another user than the one running this script: only root can do it (sudo is used if it does not ask for a password)
    if ! chown -R ${PUID}:${PGID} ${top} 2>/dev/null && ! sudo -n chown -R ${PUID}:${PGID} ${top} 2>/dev/null; then
      DIRS_TO_CHOWN="${DIRS_TO_CHOWN} ${top}"
    fi
  fi
}

resolvedConfig=$(docker compose --env-file ${GLOBAL_ENV_FILE} ${ALL_SERVICES} config --format json)

# Directories of services in the config directory: Docker would create the missing ones as root, and services
# which do not run as root could not write in them
for dir in $(echo "${resolvedConfig}" | jq -r --arg config "${HOST_CONFIG_PATH%/}/" '[.services[].volumes[]? | select(.type == "bind") | .source | select(startswith($config))] | unique | .[]'); do
  if ! create_data_dir ${dir}; then
    echo "[$0] ⚠️  Directory ${dir} does not exist and cannot be created by your user: Docker will create it, owned by root."
  fi
done

# Media volumes which are plain directories of the host (see docker-compose.yaml): Docker does not create them
for dir in $(echo "${resolvedConfig}" | jq -r '.volumes // {} | .[] | select(.driver_opts.o == "bind") | .driver_opts.device'); do
  if ! create_data_dir ${dir}; then
    echo "[$0] ERROR. Directory \"${dir}\" does not exist and cannot be created. Create it (sudo mkdir -p ${dir}) and give it to your user, then re-run this script."
    exit 1
  fi
done

if [[ -n ${DIRS_TO_CHOWN} ]]; then
  echo "[$0] ⚠️  These new directories could not be given to the user of the containers (PUID and PGID of your .env). Services which do not run as root cannot write in them until you run:"
  echo "[$0]      sudo chown -R ${PUID}:${PGID}${DIRS_TO_CHOWN}"
fi

# local-persist Docker plugin is not used by the seedbox anymore. Your own files may still use it.
if grep -lq "local-persist" docker-compose.yaml services/*/custom/*.yaml 2>/dev/null; then
  echo "[$0] ℹ️  Some of your files still use volumes of the local-persist Docker plugin, which is not needed by the seedbox anymore:"
  grep -l "local-persist" docker-compose.yaml services/*/custom/*.yaml 2>/dev/null | sed "s#^#[$0]      #"
  echo "[$0]    They still work as long as the plugin is installed. To get rid of it: doc/UPGRADE_V3.md#local-persist-plugin"
fi

# Before v3, the name of the Docker Compose project was the name of the directory of the seedbox. If the existing
# containers of this directory belong to another project, Docker Compose cannot update them: they must be
# removed first (containers only, not their data), then they are created again in the new project.
previousProjects=$(docker ps -a --filter "label=com.docker.compose.project.working_dir=$(pwd)" --format '{{.Label "com.docker.compose.project"}}' | sort -u | { grep -vx "${COMPOSE_PROJECT_NAME}" || true; })
if [[ -n ${previousProjects} ]]; then
  echo "[$0] ⚠️  The containers of this seedbox belong to the Docker Compose project \"$(echo ${previousProjects})\", but the project is now \"${COMPOSE_PROJECT_NAME}\"."
  echo "[$0]    To continue, all these containers are stopped and removed, then created again by this script."
  echo "[$0]    Your data is not affected, but services are unavailable in the meantime."
  echo "[$0]    To keep the previous name instead, answer \"n\" and add COMPOSE_PROJECT_NAME=$(echo ${previousProjects} | cut -d' ' -f1) in your .env file."
  if [[ ! -t 0 ]]; then
    echo "[$0] ERROR. Not in an interactive terminal: run this script by hand to answer."
    exit 1
  fi
  read -r -p "[$0] Continue? [Y/n] " answer
  if [[ ! "${answer:-y}" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "[$0] Aborted. Your containers have not been changed."
    exit 1
  fi
  for project in ${previousProjects}; do
    docker compose -p ${project} down --remove-orphans
  done
fi

echo "[$0] ***** Config OK. Launching services... *****"

if [[ "${SKIP_PULL}" != "1" ]]; then
  echo "[$0] ***** Pulling all images... *****"
  docker compose ${ALL_SERVICES} pull
fi

echo "[$0] ***** Recreating containers if required... *****"
docker compose --env-file ${GLOBAL_ENV_FILE} ${ALL_SERVICES} up -d --remove-orphans
if [[ ${TRAEFIK_RESTART_REQUIRED} == "1" ]] && is_service_enabled traefik; then
  echo "[$0] Traefik static configuration has changed: restarting Traefik..."
  docker restart traefik
fi
echo "[$0] ***** Done updating containers *****"

# Environment files of services were generated in env/ in v2: they are now in .seedbox/generated/
if [[ -d env ]]; then
  rm -f env/*.env env/*.tmp
  rmdir env 2>/dev/null || true
fi

# Traefik config directory of v2 is not used anymore now that Traefik container has been updated
if [[ -d traefik ]]; then
  mkdir -p .seedbox/backup
  mv traefik .seedbox/backup/traefik.v2.$(date +%Y%m%d%H%M%S)
  echo "[$0] Old Traefik config directory (traefik/) is not used anymore: moved to .seedbox/backup/"
fi
rm -f .env.concat

# Remember which version of the seedbox is installed here (to know where future migrations start from)
if [[ "$(cat .seedbox/version 2>/dev/null)" != "$(cat VERSION)" ]]; then
  echo "[$0] Seedbox version: $(cat .seedbox/version 2>/dev/null || echo "unknown") => $(cat VERSION)"
  cp VERSION .seedbox/version
fi

# Opt-in, as it applies to the whole host: images and volumes which do not belong to the seedbox are removed too
if [[ ${DOCKER_PRUNE_AFTER_UPDATE} == "true" ]]; then
  echo "[$0] ***** Clean unused images and volumes... *****"
  docker image prune -af
  docker volume prune  -f
fi

echo "[$0] ***** Done! *****"
exit 0