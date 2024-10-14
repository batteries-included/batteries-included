---
title: 'Improving Kubernetes Deployments: The Snapshot and Apply Pattern'
excerpt:
  While Kubernetes' reconciliation loop is ubiquitous, our experience shows that
  the snapshot and apply pattern offers superior debuggability, introspection,
  and user experience, especially at scale.
publishDate: 2024-08-27
tags: ['kubernetes', 'devops', 'deployment', 'scalability']
image: /public/images/posts/post-18.jpg
draft: true
---

As far as Kubernetes deployments go, the reconciliation loop (or observation
loop) is the most popular way of updating desired state. This approach, where
controllers continuously observe the current state and reconcile it with the
desired state, has been "good enough" for many deployments. However, as systems
grow in scale and complexity, we've found many areas that could be significantly
improved.

At Batteries Included, we take a different approach: the _snapshot and apply_
pattern. This article explores why we've made this choice, and how it addresses
various challenges faced by large-scale, complex Kubernetes deployments.

## Point-in-Time Snapshots

Our approach centers around point-in-time snapshots. Unlike the continuous
reconciliation model, we capture a complete snapshot of the system state prior
to making any changes. This snapshot includes both the current database state
and the current system state.

This offers various advantages:

- **Improved Debuggability**: By capturing a snapshot before any changes are
  made, we create a clear "before" picture. This proves incredibly useful when
  trying to understand what changed and why, especially in complex systems where
  the ripple effects of a change aren't immediately apparent.
- **Enhanced Introspection**: Snapshots provide a comprehensive view of the
  system at a specific moment, allowing for deeper analysis and understanding of
  the system's state.
- **Easier Onboarding**: New engineers can explore these snapshots to understand
  the system's state and recent changes. This "learn by observation" approach
  significantly reduces the learning curve for complex systems.

## How it Works

So, how do we implement the snapshot and apply pattern? At a high-level, the
process we use is pretty simple to understand,
[consisting of five steps](https://www.batteriesincl.com/docs/snapshot_apply):

1. **Prepare**: Take a point-in-time snapshot of everything.
2. **Generate**: Feed that snapshot into functional code that generate the
   desired system states.
3. **Apply**: Apply any changes needed to go from the current state to the
   desired state on all systems.
4. **Record**: Record the status for all desired state pieces.
5. **Broadcast**: Broadcast the result of the overall attempt.

Users, especially those less familiar with Kubernetes internals, often find it
easier to understand a pipeline model: prepare, store for future introspection,
apply the plan, then broadcast the result.

This mental model aligns more closely with traditional deployment pipelines,
making it easier for teams to predict system behavior and respond effectively
during operational issues. In contrast, the reconciliation loop, while elegant
from a software engineering perspective, can be less intuitive for end-users
trying to understand what will happen next.

## Rollbacks and History

We store each resource in a content-addressable storage system within our
database. Paired with snapshotting, this yields multiple benefits:

- **Efficient Rollbacks**: By treating each resource as a dictionary and
  generating a unique ID through a recursive `SHA2` hash, we can easily roll
  back to any previous state (i.e. revert any Kubernetes resource to a previous
  value).
- **Historical Context**: Content-addressable storage provides a clear
  historical record of changes. This is useful for understanding how the system
  evolved over time as well as for auditing purposes.
- **Deduplication**: This storage method naturally deduplicates identical
  resources, saving storage space and simplifying comparisons between states.

For on-call engineers and SREs, the value of systems that prioritize
debuggability and introspection cannot be overstated.

Having clear, accessible information about what just changed and the current
state of internals is a life-saver. The snapshot and apply pattern, coupled with
comprehensive logging and introspection tools, provides exactly this kind of
invaluable context.

## Takeaway

While the reconciliation loop is ubiquitous, our experience has repeatedly
demonstrated that for large-scale, complex deployments, the snapshot and apply
pattern offers superior debuggability, introspection, and user experience.

As with any architectural decision, there are trade-offs. This approach
naturally introduces some additional complexity in implementation compared to a
simple reconciliation loop.

Fortunately, platforms like Batteries Included have already tackled this
complexity, offering a turnkey solution that seamlessly integrates the snapshot
and apply pattern. By leveraging such a platform, teams can immediately benefit
from enhanced operational clarity and powerful rollback capabilities, while also
gaining access to a comprehensive suite of logging and introspection tools.
