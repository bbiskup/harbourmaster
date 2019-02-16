#!/bin/bash

# Run command in running container.
# Start the container with 'docker-compose up' first

if [ -z "$TERM" -o "$TERM" = "" ];then
    EXEC_OPTS="-T"
fi

if [ -z "$@" ];then
  args=bash
else
  args="$@"
fi

docker exec -ti $EXEC_OPTS harbourmaster_dev bash -c "$args"

