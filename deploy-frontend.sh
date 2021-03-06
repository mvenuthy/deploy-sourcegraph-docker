#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Serves the frontend of Sourcegraph via HTTP(S).
#
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: HTTP GET http://sourcegraph-frontend:3080/healthz
# Ports exposed to other Sourcegraph services: 6060/TCP
# Ports exposed to the public internet: 3080 (HTTP) and/or 3443 (HTTPS)
#
docker run --detach \
    --name=sourcegraph-frontend-$1 \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=8g \
    -e GOMAXPROCS=12 \
    -e JAEGER_AGENT_HOST='jaeger-agent' \
    -e PGHOST=pgsql \
    -e SRC_GIT_SERVERS="$(addresses "gitserver-" $NUM_GITSERVER ":3178")" \
    -e SRC_SYNTECT_SERVER=http://syntect-server:9238 \
    -e SEARCHER_URL="$(addresses "http://searcher-" $NUM_SEARCHER ":3181")" \
    -e SYMBOLS_URL="$(addresses "http://symbols-" $NUM_SYMBOLS ":3184")" \
    -e INDEXED_SEARCH_SERVERS="$(addresses "zoekt-webserver-" $NUM_INDEXED_SEARCH ":6070")" \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e REPO_UPDATER_URL=http://repo-updater:3182 \
    -e REPLACER_URL=http://replacer:3185 \
    # remove after 3.15
    -e LSIF_SERVER_URL=http://lsif-server:3186 \
    # used after 3.15
    -e LSIF_API_SERVER_URL=http://lsif-server:3186 \
    -e GRAFANA_SERVER_URL=http://grafana:3370 \
    -e GITHUB_BASE_URL=http://github-proxy:3180 \
    -v ~/sourcegraph-docker/sourcegraph-frontend-$1-disk:/mnt/cache \
    -p 0.0.0.0:$((3080 + $1)):3080 \
    index.docker.io/sourcegraph/frontend:3.14.2@sha256:44b0221dd9ee60393b3c7273b1214b7ae64cbbb4a8e2b5bcf9d06e521557f0c6

# Note: SRC_GIT_SERVERS, SEARCHER_URL, and SYMBOLS_URL are space-separated
# lists which each allow you to specify more container instances for scaling
# purposes. Be sure to also apply such a change here to the frontend-internal
# service.

echo "Deployed sourcegraph-frontend $1 service"
