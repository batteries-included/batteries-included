---
title: 'Cluster Access'
description: How to access a running cluster.
tags: ['code', 'tools', 'internal']
category: development
draft: false
---

# Cluster Access

## Set up network connectivity (wireguard)

As clusters use private networking and the K8s API isn't publicly accessible, we
use wireguard to connect.

The wireguard config is available using the `bi` tool.

```bash
[bix] bi vpn config $CLUSTER_NAME
```

That config will need to be saved to `/etc/wireguard` so that wireguard can read
it. e.g.

```bash
bi vpn config $CLUSTER_NAME | sudo tee /etc/wireguard/wg0.conf
```

Then the interface can be brought up.

```bash
wg-quick up wg0.conf
```

## Kubeconfig

The path to the K8s config file is also available using the `bi` tool.

```bash
[bix] bi debug kube-config-path $CLUSTER_NAME
```

That can be used either as an env var or `kubectl` flag.

```bash
# env var
KUBECONFIG=$(bi debug kube-config-path $CLUSTER_NAME) kubectl cluster-info

# flag
kubectl --kubeconfig=$(bi debug kube-config-path $CLUSTER_NAME) cluster-info
```
