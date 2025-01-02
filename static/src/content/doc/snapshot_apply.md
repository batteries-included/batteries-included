---
title: 'Snapshot Apply'
description:
  Internal process for managing system state changes and applying them across
  the cluster.
tags: ['overview', 'code', 'control-server', 'kubernetes', 'keycloak']
category: development
draft: false
---

We need a repeatable process that can take current database and system states,
use those to create a plan of action, then apply that plan to the current
cluster.

The snapshot apply process in the `control-server` binary is that system. It
consists of five steps:

1. [**Prepare**](#prepare): Take a point-in-time snapshot of everything.
2. [**Generate**](#generate): Feed that snapshot into functional code that
   generate the desired system states.
3. [**Apply**](#apply): Apply any changes needed to go from the current state to
   the desired state on all systems.
4. [**Record**](#record): Record the status for all desired state pieces.
5. [**Broadcast**](#broadcast): Broadcast the result of the overall attempt.

## Prepare

The preparation phase involves creating a comprehensive snapshot of the current
system:

- Use the system state summarizer to compile a detailed summary of all database
  contents and the current system state.
- Generate target snapshots for different systems (KubeSnapshot and
  KeyCloakSnapshot).

## Generate

In the generation phase, we transform the snapshot into actionable plans:

- For each target snapshot, use the summarized system state with functional
  modules to generate target system specifications.
- Store each Kubernetes or Keycloak target resource in the database
  (ResourcePath for Kubernetes).

## Apply

The application phase is where changes are implemented:

- Compare target system configurations with existing resources, removing any
  that already match. For Kubernetes, this involves using `sha hmac` via
  `KubeExt.Hashing`.
- Update any matching resources that are successfully applied.
- Push each of the Kubernetes resource targets to kubernetes using
  `KubeExt.ApplyResource`.
- Push each of the Keycloak resource targets to Keycloak
- Trigger any necessary post-apply operations for Keycloak.

## Record

Accurate record-keeping improves system integrity, providing historical context
and features like rollbacks:

- Record the results for each individual resource target.
- Compute an overall result of the operation.

## Broadcast

Finally, we ensure all relevant parties are informed:

- Transmit the latest result via Phoenix pub sub and `EventCenter`.
