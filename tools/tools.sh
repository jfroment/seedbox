#!/bin/bash

##############################################################################
############################### UTIL FUNCTIONS ###############################
##############################################################################

check_utilities () {
  # Check that jq is installed
  if ! which jq >/dev/null; then
    echo "[$0] jq does not exist. Install it from here: https://stedolan.github.io/jq/download/"
    echo "[$0] Please install jq version 1.5 or above."
    echo "[$0] Also, please make sure it is in the PATH."
    exit 1
  fi

  # Check that yq is installed
  if ! which yq >/dev/null; then
    echo "[$0] yq does not exist. Install it from here: https://github.com/mikefarah/yq/releases"
    echo "[$0] Please install yq version 4 or above."
    echo "[$0] Also, please make sure it is in the PATH."
    exit 1
  fi

  # Check that Docker Compose v2 is installed, and recent enough ("config --environment" exists since 2.27.2)
  if ! docker compose version >/dev/null 2>&1 || ! docker compose config --help 2>/dev/null | grep -q -- "--environment"; then
    echo "[$0] Docker Compose v2 (2.27.2 or above) is required, as a Docker plugin (\"docker compose\" command)."
    echo "[$0] Install or update it from here: https://docs.docker.com/compose/install/"
    exit 1
  fi
}

# Print the variables of env files (.env, service.env of a service...) as "NAME=value" lines, as resolved by
# Docker Compose itself. The script never reads these files on its own: it sees exactly the same values as
# Docker Compose and the containers, whatever the syntax used (quotes, comments, special characters...).
# As for Docker Compose, variables of the shell are included and override the ones of the files.
#$@ => env files (the last ones override the first ones)
read_env_files() {
  local args="" f
  for f in "$@"; do
    args="${args} --env-file ${f}"
  done
  docker compose ${args} -f docker-compose.yaml config --environment
}

# Value of a variable in the output of read_env_files (empty if the variable is not defined)
#$1 => name of the variable
#$2 => output of read_env_files
env_value() {
  echo "$2" | sed -n "s/^$1=//p" | head -n 1
}

# Path of a file of a service: the one of its custom directory (services/<name>/custom/) if it exists,
# the bundled one (services/<name>/) otherwise
#$1 => name of the service
#$2 => name of the file
get_service_file() {
  if [[ -f services/$1/custom/$2 ]]; then
    echo "services/$1/custom/$2"
  else
    echo "services/$1/$2"
  fi
}

# Default values of a service ($1), in JSON: content of its service.yaml file
get_service_metadata() {
  local file=$(get_service_file $1 service.yaml)
  if [[ -f ${file} ]]; then
    yq -o json -I=0 '. // {}' "${file}"
  else
    echo "{}"
  fi
}
