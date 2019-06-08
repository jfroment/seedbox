#!/bin/bash

# Aliases file to be sourced and used when it might be convenient

alias all-logs="docker ps -q | xargs -P 10 -L 1 docker logs --follow"


exit 0