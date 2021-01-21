#!/usr/bin/env bash

read -p "Are you sure? This will destroy all your resources.Type 'yes' to destroy: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Destroy vault-config then remove vault-config.tf
    terraform destroy --auto-approve -target module.vault-config && \
    rm -rf vault-config.tf && \
    # Destroy resources then reset terraform.tfvars
    terraform destroy --auto-approve && \
    sed -i '/run_post_install/s/true/false/g' terraform.tfvars
else
    echo "Skipping terraform destroy."
fi
