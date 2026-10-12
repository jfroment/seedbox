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
