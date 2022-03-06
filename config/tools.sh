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