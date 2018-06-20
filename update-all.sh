#!/bin/bash

echo "Pulling all images..."
docker-compose pull
echo "Recreating containers if required..."
docker-compose up -d
echo "Done."
exit 0