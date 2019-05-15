#!/bin/bash

echo "[$0] ***** Pulling all images... *****"
docker-compose pull
echo "[$0] ***** Recreating containers if required... *****"
docker-compose up -d --remove-orphans
echo "[$0] ***** Done updating containers *****"
echo "[$0] ***** Clean unused images... *****"
docker image prune -af
echo "[$0] ***** Done! *****"
exit 0