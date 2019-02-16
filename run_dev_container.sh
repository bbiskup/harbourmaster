#!/bin/bash

# Run Docker container for development.
# We don't use docker-compose because
# 1) there is only one container, so the benefits are limited
# 2) there is a networking issue with Elixir when starting
#    a container with docker-compose
#      mix local.hex --force
#    gives
#      Could not install Hex because Mix could not download
#      metadata at https://repo.hex.pm/installs/hex-1.x.csv

docker rm -f harbourmaster_dev || true

docker run \
     --rm -ti --detach --privileged \
    -v $PWD:/code \
    -v $PWD/.docker/.config:/root/.config \
    -v $PWD/.docker/.elm:/root/.elm \
    -v $PWD/.docker/.local:/root/.local \
    -v $PWD/.docker/.mix:/root/.mix \
    -v $PWD/.docker/.npm:/root/.npm \
    -v $PWD/.docker/.share:/root/.share \
    -v /usr/bin/docker:/usr/bin/docker \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -p 4000:4000 \
    -p 8000:8000 \
    --name harbourmaster_dev \
    harbourmaster_dev sh

