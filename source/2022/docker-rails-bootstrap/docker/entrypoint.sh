#!/bin/bash -e

export PATH="$PATH:/app"

bundle check || bundle install -j "$(($(nproc) + 1))"

# then exec the container's main process
# what's set as CMD in the Dockerfile
exec "$@"
