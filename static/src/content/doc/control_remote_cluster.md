---
title: 'Run control-server locally against a remote cluster'
description: How to run control server locally against a remote cluster.
tags: ['code', 'tools', 'internal']
category: development
draft: false
---

## Network connectivity

Follow the instructions in the [access documentation](../docs/access) to set up
network connectivity to remote cluster.

## Bootstrap cluster

For a cluster that isn't already running, start it using `bi` with the
`--skip-bootstrap` option.

```bash
bi start --skip-bootstrap $PATH_TO_INSTALL_SPEC
```

Setup environment

```bash
export KUBE_CONFIG_FILE="$(bi debug kube-config-path $CLUSTER_NAME)"
export INSTALL_SUMMARY="$(bi debug install-summary-path $CLUSTER_NAME)"
```

Bootstrap the cluster based on local changes. It may need to be ran multiple
times to complete fully.

```bash
pushd platform_umbrella
KUBE_CONFIG_FILE="${KUBE_CONFIG_FILE}" mix kube.bootstrap "${INSTALL_SUMMARY}"
```

It is probably valuable to remove the `controlserver` deployment from the
running cluster.

```bash
kubectl delete deployment -n battery-core controlserver
```

## Port forward control-server DB

In a separate process, start port-forwarding the database.

```bash
bi postgres port-forward $CLUSTER_NAME controlserver -n battery-base
```

## Run control-server

Setup additional environment variables for the postgres connection.

```bash
export POSTGRES_USER="$(bi postgres access-info $CLUSTER_NAME controlserver battery-control-user -l -j -n battery-base | jq -r '.username')"
export POSTGRES_PASSWORD="$(bi postgres access-info $CLUSTER_NAME controlserver battery-control-user -l -j -n battery-base | jq -r '.password')"
```

Setup and seed the DB.

```bash
pushd platform_umbrella

mix do setup, seed.control "${INSTALL_SUMMARY}"
```

It may be valuable to prevent control-server from trying to install itself into
the cluster. This can be done by, for example, preventing the `:deployment`
resource from being created by requiring `false`.

```
    :deployment
    |> B.build_resource()
    |> B.name(name)
    ...
    |> F.require(false)
```

Finally, it's now possible to start the control server against the remote
cluster.

```bash
KUBE_CONFIG_FILE="${KUBE_CONFIG_FILE}" iex -S mix phx.server
```
