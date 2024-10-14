---
title: 'When GitOps Fails to Scale'
excerpt:
  While GitOps has revolutionized infrastructure management, years of experience
  reveal significant tradeoffs when scaling at large.
publishDate: 2024-12-01
tags: []
image: /public/images/posts/post-4.jpg
draft: true
---

[_GitOps_](https://about.gitlab.com/topics/gitops/) is a modern approach to
infrastructure management and deployment that leverages Git as its single source
of truth. GitOps uses Git repositories to store and version all infrastructure
configurations, application manifests, and deployment specifications.

In recent years, GitOps has gained popularity thanks to its promise of improved
collaboration, traceability, and consistency in managing infrastructure.
However, our many years of experience managing large-scale systems have revealed
that GitOps practices come with some significant trade-offs.

In this article, we'll be exploring pain points that surface when GitOps is
applied to extensive and complex systems, drawing on practical insights from
real-world implementations.

## Speed and Efficiency: The Lag of Large Repositories

GitOps relies on storing operational configurations in Git repositories. While
simple and effective for smaller projects, it becomes a significant challenge as
the repository grows and change frequency increases. Issues inherent to Git's
architecture end up contributing to performance issues:

- Git uses linear linked lists of commits, resulting in serialized writes and
  time-consuming history searches.
- Since most DSLs are turing-complete or near-equivalent, extensive testing is
  required to understand the impact of any change.
- The deployment process itself introduces further delays; commit to a branch,
  merge the branch, wait for the production merge, and finally wait for
  deployment to complete for the last revision.

All these factors combine to create a system with a deceptive slowness that
gradually emerges as it scales.

## Knowledge Barriers for Inexperienced Developers

GitOps repositories are filled with text-based _DSLs_ (domain-specific
languages) to define operational configurations. While allowing for high
sophistication and flexibility, it's particularly disadvantageous for
inexperienced developers:

- The schema for configuration files is often ill-defined or unclear, making
  seemingly simple changes like modifying a label in a YAML file potentially
  risky.
- The text-based nature of git allows for numerous ways to solve problems,
  making it tougher for those not deeply embedded in the domain to understand
  and verify changes.
- Standard text editors lack context-aware features for these files, offering
  little to no feedback on the potential impact of modifying a field or
  suggesting valid values.

These barriers add considerable onboarding friction and increase the risk of
errors in development and deployment processes.

## Automation Challenges in the Software Development Lifecycle

Implementing GitOps at scale requires robust automation, but several factors add
friction to this process:

- GitOps tools must integrate with the entire software development lifecycle;
  this involves everything from code creation to deployment via various
  command-line tools and automation mechanisms.
- Automation tools must interface with various components, including CI/CD
  pipelines, deployment environments, and monitoring systems. Achieving seamless
  integration across these tools can be difficult, leading to fragmentation and
  other inefficiencies.
- The flexibility of GitOps leads to diverse implementations across projects and
  companies, forcing automation tools to handle a wide variety of code styles,
  project layouts, and naming conventions.

These challenges can result in fragmented toolchains and reduced efficiency,
countering the streamlined processes GitOps aims to create.

## Takeaway

While GitOps remains a popular approach for managing infrastructure, our
experience has demonstrated that it faces significant challenges at scale. These
issues have guided us towards a more robust solution: using a database as the
source of truth for configuration.

Databases have some unique advantages compared to text configuration; they offer
fine-grained locking, strongly-typed schemas with built-in validation and
references, as well as user-friendly interfaces for non-technical users. At the
cost of some flexibility, this approach also addresses the performance
bottlenecks and automation challenges present in large-scale GitOps
implementations.

As we continue to evolve our infrastructure management practices, it's crucial
to recognize that no single approach is perfect for all scenarios-- adaptability
in the face of scaling challenges is key to maintaining efficient and reliable
systems.
