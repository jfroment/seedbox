#!/bin/bash

# Aliases file to be sourced and used when it might be convenient

alias all-logs="docker ps -q | xargs -P 13 -L 1 docker logs --follow"