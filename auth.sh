#!/usr/bin/env bash

case $1 in
clear)
 unset GOOGLE_OAUTH_ACCESS_TOKEN
 unset GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
 # Remove user hosts entries
 sed '/##\[USER/{:a;N;/END\]##/!ba};//d' /etc/hosts | sudo tee /etc/hosts
 ;;
*)
 # Set the project
 if gcloud -q projects describe $1 && gcloud -q config set project $1; then
    SERVICE_ACCOUNT=$(gcloud iam service-accounts list  --filter="email ~ project-service-account" --format='value(email)')
    PROJECT=$(echo $SERVICE_ACCOUNT | grep -o -P '(?<=@).*(?=.iam)')
    # Set the token
    export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$SERVICE_ACCOUNT
    export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
    # Error: dial tcp ... connect: cannot assign requested address
    # https://github.com/hashicorp/terraform-provider-google/issues/6782
    APIS="googleapis.com www.googleapis.com storage.googleapis.com iam.googleapis.com container.googleapis.com cloudresourcemanager.googleapis.com"
    sed '/##\[USER/{:a;N;/END\]##/!ba};//d' /etc/hosts | sudo tee /etc/hosts.temp
    echo '##[USER_HOSTS_START]##' | sudo tee -a /etc/hosts.temp
    for i in $APIS
    do
        echo "199.36.153.10 $i" | sudo tee -a /etc/hosts.temp
    done
    echo '##[USER_HOSTS_END]##' | sudo tee -a /etc/hosts.temp
    sudo cp /etc/hosts.temp /etc/hosts
 else
    echo "Run . ./auth.sh [project_id]."
 fi
esac
