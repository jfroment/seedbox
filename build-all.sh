#!/usr/bin/env bash

# This script builds all the containers locally as an alternative to pulling
# from the docker registry.

cd ${0%/*}

docker build -t kelvinchen/seedbox:base      Dockerfiles/base
docker build -t kelvinchen/seedbox:frontend  Dockerfiles/frontend
docker build -t kelvinchen/seedbox:plex      Dockerfiles/plex
docker build -t kelvinchen/seedbox:rtorrent  Dockerfiles/rtorrent
docker build -t kelvinchen/seedbox:sickrage  Dockerfiles/sickrage
docker build -t kelvinchen/seedbox:syncthing Dockerfiles/syncthing
