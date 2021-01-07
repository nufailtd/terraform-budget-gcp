#!/usr/bin/env bash
set -e
chisel client --auth \
$(berglas access $PROXY_USER):$(berglas access $PROXY_PASS) \
--keepalive 1m $PROXY_SERVER 127.0.0.1:1080:socks 127.0.0.1:3306:127.0.0.1:3306 &

# This should always be `berglas exec -- + ENTRYPOINT + CMD`
berglas exec -- env \
HTTP_PROXY=$PROXY_URI \
HTTPS_PROXY=$PROXY_URI \
docker-entrypoint.sh \
node current/index.js &

wait -n