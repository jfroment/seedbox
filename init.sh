#!/bin/bash

echo "[$0] Initializing..."

# Create all files from templates (.env, config.yaml, docker-compose.yaml, files of enabled services...)
tools/sync-templates.sh
echo "[$0] Please edit .env file"
echo "[$0] Please also edit the files created in the custom directory of services (see above and documentation)."

echo "[$0] Done."
exit 0