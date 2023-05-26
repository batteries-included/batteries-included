---
title: 'Snapshot Apply'
date: 2022-12-02
tags: ['overview', 'code', 'control-server', 'kubernetes', 'keycloak']
draft: false
---

We need a repeatable process that can take current database state and the
current system state, use those to create a plan of action, then apply that plan
to the current cluster.

The snapshot apply process in the `control-server` binary is that system.

- Take a point in time snapshot of everything. (Prepare)
- Feed that snapshot into functional code that generate desired system states.
  (Generate)
- Apply any changes need to go from the current state to the desired state on
  all systems. (Apply)
- Record the status for all desired state pieces (Report)
- Broadcast the result of the overall atempt (Broadcast)

## Prepare

- We need a summary of everything in the database and everything in the current
  system state. For that we use the system state summarizer.
- Then we need to create the target snapshots for the different systems.
  (KubeSnapshot and KeyCloakSnapshot)

## Generation

- For each target snapshot use the summarized system state with functional
  modules to generate the target system specifications.
- Store each kube or keycloak target resource in the database (ResourcePath for
  kube)

## Apply

- Remove any target system configuration or resource that already match with
  what's there. For kubernetes this is done via sha hmac `KubeExt.Hashing`
- Update any matching resources are successfuly applied
- Push each of the kube resource targets to kubernetes via
  `KubeExt.ApplyResource`
- Push each of the keycloak resource targets to keycloak.
- Trigger any post apply operations needed for keycloak

## Report

- Record the per resource target results
- Compute an overal result

## Broadcast

- Send the latest result via Phoenix pub sub and `EventCenter`
