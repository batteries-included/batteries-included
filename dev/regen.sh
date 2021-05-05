#!/bin/env bash

set -xe

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PRIV_DIR="${SCRIPT_DIR}/../control_server_umbrella/apps/control_server/priv/"
SVC_DIR="${SCRIPT_DIR}/../control_server_umbrella/apps/control_server/lib/control_server/services/"

helm template "battery-cert-manager" jetstack/cert-manager \
    --namespace battery-security --include-crds --set installCRDs=true \
    --create-namespace | ${SCRIPT_DIR}/from_yaml.py CertManager SecuritySettings \
    >${SVC_DIR}/cert_manager.ex 2> ${PRIV_DIR}/manifests/cert_manager-crds.yaml
sed -i s/'"namespace" => "battery-security"'/'"namespace" => namespace'/g ${SVC_DIR}/cert_manager.ex


helm template "battery" actions-runner-controller/actions-runner-controller \
    --namespace battery-devtools --include-crds --set installCRDs=true \
    --create-namespace | ${SCRIPT_DIR}/from_yaml.py GithubActionsRunner DevtoolsSettings \
    >${SVC_DIR}/github_actions_runner.ex 2> ${PRIV_DIR}/manifests/github_actions_runner-crds.yaml
sed -i s/'"namespace" => "battery-devtools"'/'"namespace" => namespace'/g ${SVC_DIR}/github_actions_runner.ex

helm template battery ${PRIV_DIR}/postgres-operator/charts/postgres-operator \
    -f ${SCRIPT_DIR}/postgres_operator-values.yaml \
    --namespace battery-db --include-crds --set installCRDs=true \
    --create-namespace | ${SCRIPT_DIR}/from_yaml.py PostgresOperator DatabaseSettings \
    >${SVC_DIR}/postgres_operator.ex 2> ${PRIV_DIR}/manifests/postgres_operator-crds.yaml
sed -i s/'"namespace" => "battery-db"'/'"namespace" => namespace'/g ${SVC_DIR}/postgres_operator.ex

pushd "${SCRIPT_DIR}/../control_server_umbrella"
mix format
popd
