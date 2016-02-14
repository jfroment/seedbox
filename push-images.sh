#!/usr/bin/env bash

# Push all images to the docker registry.

docker push kelvinchen/seedbox:base
docker push kelvinchen/seedbox:frontend
docker push kelvinchen/seedbox:plex
docker push kelvinchen/seedbox:rtorrent
docker push kelvinchen/seedbox:sickrage
docker push kelvinchen/seedbox:syncthing
docker push kelvinchen/seedbox:openvpn
