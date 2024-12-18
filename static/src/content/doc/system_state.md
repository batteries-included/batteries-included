---
title: 'System State Overview'
description:
  Internal system state management and caching mechanisms of the platform.
tags: ['overview', 'code', 'control-server']
draft: false
---

# What is System State

To have a stable system, you need a repeatable process, and to that end the
control server uses functional paradigms to decide the generated Kubernetes
resources, change database state, or report usage stats. Those decisions on what
to do next are derived from the summary state of the world. `System State` is
the system we use to get an atomic summary to drive other parts of the system.

The main struct is `KubeExt.SystemState.StateSummary`. The struct is a carrier
of many different parts that are all gathered together simultaneously when
`ControlServer.SystemState.Summarizer` is called.

If you need a fresh and up-to-date `StateSummary,` call `&new/1`. If your use
case tolerates staleness, you can use `&cached/1`. If you only need a small part
of the summary, then call `&cached_field/2`

Some code may need derived data from the system state. That code lives in
`platform_umbrella/apps/kube_services/lib/kube_services/system_state` and
notable examples include:

- What the current best service to connect to the kubelet is
  (`platform_umbrella/apps/kube_services/lib/kube_services/system_state/monitoring.ex`)
- What is the best hostname to give out of installed battery systems
  (`platform_umbrella/apps/kube_services/lib/kube_services/system_state/hosts.ex`)
- What the configured namespaces are
  (`platform_umbrella/apps/kube_services/lib/kube_services/system_state/namespaces.ex`)

## Internals

`ControlServer.SystemState.Summarizer` is a genserver started in the control
server app. Its leading utility is to run a transaction listing all of the
database tables containing requested or configured state and snapshotting the
current `kube_state` ETS table.

That result is then cached and sent to you.
