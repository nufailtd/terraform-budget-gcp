#!/usr/bin/env bash

set -e

chisel client --auth $(berglas access $PROXY_USER):$(berglas access $PROXY_PASS) \
--keepalive 1m $PROXY_SERVER 127.0.0.1:1080:socks 127.0.0.1:3306:127.0.0.1:3306 &

# start web server in the background
# TODO: use gunicorn here as 'flask' command is not
# production ready, and should be used only for dev purposes

env HTTP_PROXY=socks5://127.0.0.1:1080 HTTPS_PROXY=socks5://127.0.0.1:1080 \
gunicorn --bind ":${PORT:-8080}" --workers 1 --threads 8 app:app &

# wait -n helps us exit immediately if one of the processes above exit.
# this way, Cloud Run can restart the container to be healed.
wait -n
