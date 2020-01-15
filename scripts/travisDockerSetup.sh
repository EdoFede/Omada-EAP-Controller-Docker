#!/bin/bash

mkdir -p $HOME/.docker
echo '{ "experimental": "enabled" }' > $HOME/.docker/config.json
echo '####### Docker version #######'
docker version
