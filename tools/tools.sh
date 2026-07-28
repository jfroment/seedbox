#!/bin/bash

##############################################################################
############################### UTIL FUNCTIONS ###############################
##############################################################################

check_utilities () {
  echo "[$0] ***** Checking required tools... *****"

  # Check if versions of required tools are correct
  check_version() {
    local tool=$1
    local required_version=$2

    local required_major_version=$(echo $required_version | cut -d'.' -f1)
    local required_minor_version=$(echo $required_version | cut -d'.' -f2)

    local current_version=$($tool --version | grep -oP '\d+\.\d+')
    local current_major_version=$(echo $current_version | cut -d'.' -f1)
    local current_minor_version=$(echo $current_version | cut -d'.' -f2)

    if [[ $current_major_version -lt $required_major_version ]]; then
      echo "[$0] ERROR: $tool version $required_version or higher is required. Current version is $current_version."
      exit 1
    fi

    if [[ $current_major_version -eq $required_major_version && $current_minor_version -lt $required_minor_version ]]; then
      echo "[$0] ERROR: $tool version $required_version or higher is required. Current version is $current_version."
      exit 1
    fi
  }

  # Define required versions for each tool
  declare -A REQUIRED_VERSIONS
  REQUIRED_VERSIONS=( ["docker"]="20.10" [$DOCKER_COMPOSE_BINARY]="2.27" ["yq"]="4.0" ["jq"]="1.5" )

  # Check versions
  echo "[$0] ***** Checking version of required tools... *****"
  for tool in "${!REQUIRED_VERSIONS[@]}"; do
    check_version $tool ${REQUIRED_VERSIONS[$tool]}
  done
}