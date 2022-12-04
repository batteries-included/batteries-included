---
title: Snapshot Apply
date: '2022-12-2'
tags: ['overview', 'code', 'control-server', 'kubernetes']
draft: false
images: []
---

# Snapshot Apply

Since the ControlServer is running on Kubernetes, we need some way to go from
our desired state, stored in the database as ecto battery settings, to running
functional Deployments, Pods, and Services, etc. Snapshot Apply is the code
responsible for doing that database to k8s transition. The process takes
`KubeExt.SystemState.StateSummary` as input and pushes all updated or added
resources to Kubernetes as output.

## Process

- Insert a new `ControlServer.SnapshotApply.KubeSnapshot` in the database, where
  we will keep track of the status and record the final snapshot of the
  resources requested.
- `KubeServices.SnapshotApply.Apply` a genserver in the `kube_services` app gets
  a call to `&run/1` with the `KubeSnapshot.` Take a new StateSummary, getting a
  list of all installed batteries and current configs, among other things.
- For each `SystemBattery` installed, iterated through them, combining the
  battery and the `StateSummary` to get a map of path string to resources. Most
  of this is in `KubeResources.ConfigGenerator`
- Merge all of those maps into a total snapshot of all resources requested
- Store a copy of each resource in the addressable content system
- Push any resources to Kubernetes if the resource hashes don't match
- Report the final result for each path and overall
