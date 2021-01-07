#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail -o posix

boot_timestamp="$(date --iso-8601=ns)"

mkdir -p "$(dirname "${config_path}")"

cat > "${config_path}" << EOF
{
    "instance_name": "${instance_name}",
    "boot_timestamp": "$${boot_timestamp}",
}
EOF


# generate k8s token for traefik
docker run --rm -i -v /run/k8s-conf:/data \
-e TRAEFIK_TOKEN=${traefik_token} \
us-docker.pkg.dev/berglas/berglas/berglas:latest \
exec -- /data/traefik-token.sh

until (sudo iptables -t nat -L -n -v | grep "docker0" ); do
  echo 'waiting for docker iptable rules..';
  sleep 5;
done

sudo iptables -t nat -A POSTROUTING -s ${cluster_cidr} -o eth0 -j MASQUERADE
sudo iptables -I INPUT 1 -p tcp -m tcp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -I INPUT 1 -p udp -m udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo systemctl daemon-reload
sudo systemctl restart systemd-resolved.service
sudo systemctl start coredns
sudo systemctl start chisel
sudo systemctl start mysql