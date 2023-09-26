#!/usr/bin/env bash

set -exuo pipefail

echo '==== BEGIN GITEA CONFIGURATION ===='

{ # try
  gitea migrate
} || { # catch
  echo "Gitea migrate might fail due to database connection...This init-container will try again in a few seconds"
  exit 1
}
function configure_admin_user() {
  local ACCOUNT_ID=$(gitea admin user list --admin | grep -e "\s\+${GITEA_ADMIN_USERNAME}\s\+" | awk -F " " '{printf $1}')
  if [[ -z ${ACCOUNT_ID} ]]; then
    echo "No admin user '${GITEA_ADMIN_USERNAME}' found. Creating now..."
    gitea admin user create --admin --username "${GITEA_ADMIN_USERNAME}" --password "${GITEA_ADMIN_PASSWORD}" --email "gitea@batteriesincl.com" --must-change-password=false
    echo '...created.'
  else
    echo "Admin account '${GITEA_ADMIN_USERNAME}' already exist. Running update to sync password..."
    gitea admin user change-password --username "${GITEA_ADMIN_USERNAME}" --password "${GITEA_ADMIN_PASSWORD}"
    echo '...password sync done.'
  fi
}

configure_admin_user

function configure_ldap() {
  echo 'no ldap configuration... skipping.'
}

configure_ldap

function configure_oauth() {
  if [[ -z ${OAUTH_NAME:-""} ]]; then
    echo 'no oauth configuration... skipping.'
    return 0
  fi

  local AUTH_ID=$(gitea admin auth list --vertical-bars | grep -E "\|${OAUTH_NAME}\s+\|" | grep -iE '\|OAuth2\s+\|' | awk -F " " '{print $1}')

  if [[ -z ${AUTH_ID} ]]; then
    echo "No oauth configuration found with name '${OAUTH_NAME}'. Installing it now..."
    gitea admin auth add-oauth \
      --provider "openidConnect" \
      --auto-discover-url "${AUTODISCOVER_URL}" \
      --name "${OAUTH_NAME}" \
      --key "${CLIENT_ID}" \
      --secret "${CLIENT_SECRET}"
    echo '...installed.'
  else
    echo "Existing oauth configuration with name '${OAUTH_NAME}': '${AUTH_ID}'. Running update to sync settings..."
    gitea admin auth update-oauth \
      --id "${AUTH_ID}" \
      --provider "openidConnect" \
      --auto-discover-url "${AUTODISCOVER_URL}" \
      --name "${OAUTH_NAME}" \
      --key "${CLIENT_ID}" \
      --secret "${CLIENT_SECRET}"
    echo '...sync settings done.'
  fi
}

configure_oauth

echo '==== END GITEA CONFIGURATION ===='
