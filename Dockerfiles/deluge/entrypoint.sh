#!/bin/sh

rm -f /config/deluged.pid

mkdir -p /config/deluge

deluged -c /config/deluge -L info -l /config/deluge/deluged.log
deluge-web -c /config/deluge