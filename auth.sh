#!/usr/bin/env bash

case $1 in
clear)
 ##gcloud -q config unset auth/impersonate_service_account
 unset GOOGLE_OAUTH_ACCESS_TOKEN
 unset GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
 ;;
*)
 # Set the project
 if gcloud -q projects describe $1 && gcloud -q config set project $1; then
    SERVICE_ACCOUNT=$(gcloud iam service-accounts list  --filter="email ~ project-service-account" --format='value(email)')
    PROJECT=$(echo $SERVICE_ACCOUNT | grep -o -P '(?<=@).*(?=.iam)')
    # Impersonate the service account
    ##gcloud -q config set auth/impersonate_service_account $SERVICE_ACCOUNT
    # Set the token
    export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$SERVICE_ACCOUNT
    export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
 else
    echo "Run . ./auth.sh [project_id]."
 fi
esac
