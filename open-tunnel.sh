#!/bin/bash

source tunnel-options.sh

if [[ -z $username ]]; then
  username=$USER
fi

echo "[$0] Connecting and fetching IP..."
echo "[$0] Username: $username"
echo "[$0] Host: $hostname"

ip=$(ssh -t ${username}@${hostname} "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${container}")

echo "[$0] IP found: $ip"
echo "[$0] Openning tunnel..."

open http://localhost:$port && ssh -L $port:$ip:$port ${username}@${hostname}

echo "[$0] Tunnel closed."

exit 0
