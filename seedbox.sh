#!/bin/bash

run_seedbox() {
  
  SKIP_PULL=0
  
  for i in "$@"; do
    case $i in
      --no-pull)
        SKIP_PULL=1
        ;;
      --prune)
        PRUNE=1
        ;;
      -h|--help)
        echo "[$0] Usage: $0 run [--no-pull|--prune]"
        exit 0
        ;;
    esac
  done

  if [[ "${SKIP_PULL}" != "1" ]]; then
    echo "[$0] ***** Pulling all images... *****"
    ${DOCKER_COMPOSE_BINARY} ${ALL_SERVICES} pull
  fi
  
  echo "[$0] ***** Recreating containers if required... *****"
  ${DOCKER_COMPOSE_BINARY} --env-file ${GLOBAL_ENV_FILE} ${ALL_SERVICES} up -d --remove-orphans
  echo "[$0] ***** Done updating containers *****"
  rm -f .env.concat
  
  echo "[$0] ***** Clean unused images and volumes... *****"
  if [[ "${PRUNE}" == "1" ]]; then
    docker image prune -af
    docker volume prune -f
  fi
  
  echo "[$0] ***** Done! *****"
  exit 0
}

stop_seedbox() {
  
  for i in "$@"; do
    case $i in
      --prune)
        PRUNE=1
        ;;
      -h|--help)
        echo "[$0] Usage: $0 run [--prune]"
        exit 0
        ;;
    esac
  done

  echo "[$0] ***** Stopping containers... *****"
  ${DOCKER_COMPOSE_BINARY} --env-file ${GLOBAL_ENV_FILE} ${ALL_SERVICES} down
  rm -f .env.concat
  
  if [[ "${PRUNE}" == "1" ]]; then
    echo "[$0] ***** Clean unused images and volumes... *****"
    docker image prune -af
    docker volume prune -f
  fi
  
  echo "[$0] ***** Done! *****"
  exit 0
}

DEBUG=0

for i in "$@"; do
  case $i in
    --debug)
      DEBUG=1
      ;;
  esac
done

source prepare-configs.sh

case $1 in
  run)
    run_seedbox
    ;;
  stop)
    stop_seedbox
    ;;
  *)
    echo "[$0] ❌ ERROR: unknown parameter \"$1\""
    echo "[$0] Usage: $0 {run|stop}"
    exit 1
    ;;
esac

