---
title: 'Robo SRE'
description:
  Automated Site Reliability Engineering system for detecting, diagnosing, and
  remediating infrastructure issues in Kubernetes environments.
tags: ['overview', 'automation', 'sre', 'kubernetes', 'remediation']
category: development
draft: false
---

The Robo SRE system provides automated detection, diagnosis, and remediation of
infrastructure issues across our Kubernetes clusters.

## System Overview

The Robo SRE consists of several interconnected components:

1. **Issue Detection**: Continuous monitoring and health assessment
2. **Issue Management**: Tracking and state management of detected problems
3. **Analysis and Planning**: Plugable handlers determine the context and plan
   remediation steps
4. **Remediation Execution**: Automated remediation workflows
5. **Learning System**: _(Coming Soon)_ Feedback loops for improving automation

## Core Components

All of the RoboSRE is built into the control server. So the RoboSRE is a battery
in the elixir container. Starting the battery will write the configuration to
the database, and then start the kube services process tree.

The CommonCore.Batteries.RoboSREConfig contains things like global configuration
options, thresholds, and other settings that affect the behavior of the Robo SRE
system. That configuration is then used to spawn an OTP supervisor and process
tree in the KubeServices application.

As much as possible the handlers and verification should be coded as testable
functional components - take in some context state and then return the
appropriate result. testable functional components. Take in some context state
and then return the appropriate result.

## Issue Management

The central data structure is `CommonCore.RoboSRE.Issue` which tracks:

- **Subject**: A hierarchical identifier for the resource affected by the issue,
  formatted as `cluster.type.resource[.subresource]`. Examples:
  - `some-cluster-name.node.node-40`
  - `some-cluster-name.control-server.kube-state`
  - `some-cluster-name.control-server.sso`
  - `some-cluster-name.pod.battery-istio.ztunnel`
- **Subject Type**: The type of resource affected (e.g., pod, node, volume,
  control server)
- **Issue Type**: Classification of the problem (e.g., pod_crash,
  node_not_ready, disk_full)
- **Trigger**: What detected the issue (e.g., kubernetes_event,
  metric_threshold, health_check)
- **Trigger Params**: Contextual data about the detection (stored as map)
- **Status**: Current state of the issue (detected, analyzing, remediating,
  resolved, failed)
- **Parent Issue**: Reference to parent issue for cascading problems
- **Handler**: Current remediation handler attempting to resolve the issue
- **Handler State**: Handler-specific state data (stored as map)

### Lifecycle

```
detected → analyzing → remediating → resolved
    ↓         ↓           ↓
  failed ←─ failed ←─── failed
```

Issues can have parent-child relationships:

- Node failure (parent) → Pod crashes (children)
- Disk full (parent) → Application errors (children)
- Reopens (parent) → Closes repeat issues (children) after auto close

### Issue Types

- PodCrash - Pods are crashing. This type can be raised by metrics of number of
  restarts, or through a watcher on kubestate.
- DiskFull - Disks are full.
- StuckKubeState - Kube state is stuck and not getting updates from the watcher.

#### Remediation/Analysis History

Every time an issue is analyzed or remediated, a record is kept of the actions
taken and their outcomes. This history allows for ratelimiting, learning from
past issues, and improving future responses.

## Handler System

Handlers are pluggable remediation modules that:

1. **Analyze**: Gather context and determine if they can handle the issue
2. **Plan**: Plan automated remediation steps, in sequence or in parallel
3. **Verify**: Verify if the issue is resolved after remediation

## Issue Worker

Each Issue when it's reported will get a `KubeServices.RoboSRE.IssueWorker`
started to process the entire lifecycle of the issue. Each worker will be
responsible for one issue at a time.

### Process Model

Issue Workers are implemented as GenServer processes with the following
characteristics:

- **One worker per issue**: Each detected issue gets its own dedicated worker
  process
- **Supervision**: Workers are supervised by a `DynamicSupervisor` under the
  KubeServices supervision tree
- **Process registry**: Workers register themselves with a unique name based on
  issue ID for easy lookup
- **State persistence**: Worker state is synced to the database for crash
  recovery after each action
- **Timeout handling**: Workers have configurable timeouts for each phase of
  remediation

### Lifecycle

The Issue Worker follows a state machine pattern:

```
:initializing → :analyzing → :remediating → :verifying → :resolved
      ↓             ↓            ↓            ↓            ↓
   :failed ←─── :failed ←─── :failed ←─── :failed ───→ :cleanup
```

#### State Transitions

1. **:initializing**: Worker starts, loads issue data, validates configuration
2. **:analyzing**: Runs appropriate analyzer to validate and gather context
3. **:remediating**: Executes handler and remediations in sequence
4. **:verifying**: Polls/watches for issue resolution or failure
5. **:resolved**: Issue successfully resolved, cleanup and termination
6. **:failed**: Issue could not be resolved, escalation and cleanup
7. **:cleanup**: Final state before process termination

### Responsibilities

- **Analysis Coordination**: Calls the appropriate analyzer for the issue type
- **Handler Execution**: Manages the execution of remediation handlers
- **State Management**: Maintains issue state and updates the database
- **Progress Tracking**: Records all actions taken and their outcomes
- **Timeout Management**: Enforces timeouts for each remediation phase
- **Escalation**: Triggers escalation when remediation fails or times out
- **Cleanup**: Ensures proper cleanup of resources when work is complete

## Issue Detection

Starting RoboSRE battery will start many processes that will detect different
issues. Each process will be responsible for monitoring a specific aspect of the
infrastructure and reporting any anomalies or problems it detects.

The first few will be:

- Stale Resource monitoring
- KubeState monitoring

### Event Correlation and Deduplication

- **Time-based correlation**: Group events that occur within a time window
- **Resource-based correlation**: Link issues affecting the same resource
- **Causal relationship detection**: Identify parent-child issue relationships
- **Duplicate prevention**: Avoid creating multiple issues for the same problem
- **Issue reopening**: Reopen resolved issues if problems recur

This happens after detection in the analysis phase. Doing this allows events
that all trigger at the same time to be grouped together after the initial
analysis delay.

This is TODO, and will be implemented as a later PR.

## Remediation Workers

Remediation Workers are individual GenServer processes that execute specific
remediation actions. Each worker type is responsible for a particular kind of
remediation action and implements its own rate limiting and safety controls.

### Remediation Architecture

Each remediation executor is spawned as a separate GenServer process under the
KubeServices supervision tree. Executors are started with the battery.

### Types

### Delete Resource Executor

Deletes a Kubernetes resource (pod, deployment, service, etc.) and saves the
state before deletion for potential rollback.
