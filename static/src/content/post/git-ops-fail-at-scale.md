---
title: 'GitOps Fail at Scale'
excerpt:
  After years of operating systems at scale, we have found that GitOps have
  serious tradeoffs at scale.
publishDate: 2024-12-01
tags: []
image: /images/posts/post-4.jpg
draft: true
---

## Speed and Efficiency: The Lag of Large Repositories

Storing operational configuration in Git works well for smaller projects, but as
repositories grow and changes become more frequent, GitOps can become a
bottleneck. Large repositories with highly dynamic configurations often suffer
from slow commit processes:

- _Single Log:_ Git is made of linear linked lists of commits. That means all
  writes are serialized on a single object. It also means that searching for the
  past involves operations on a long linear history with very little indexing.
- _Testing:_ Since most DSLs are turning complete or close, extensive tests are
  needed to understand the impact of any change.
- _Deploying:_ Merging changes and deploying them can introduce even more
  delays. Commit to a branch, merge the branch, and wait for a merge into the
  production branch. Then, wait for deployment to complete for the last
  revision.

## Knowledge Issues for Non-Expert Developers

GitOps repositories are filled with text-based domain-specific languages to
express what should be running where. The user interface for changes (text
files) is the same as the schema (YAML) shown to tools. While that approach to
configuration management allows for high sophistication and flexibility, it is a
double-edged sword. Non-expert developers often find themselves at a
disadvantage when dealing with GitOps:

- _Unknown Schema:_ Changing a label in a terraform or YAML file can be scary.
  There's little way of knowing which tags do what and how they are used.
- _Complex Solutions_: The text-based nature of Git allows for numerous ways to
  solve problems, making it challenging for those not deeply embedded in the
  operations domain to understand and verify changes.
- _Lack of Context:_ Text editors don't provide feedback about how one field
  will impact others or give suggestions of values. They lack a customized UI
  for each file.

## Automation Challenges in the Software Development Lifecycle

- _Lifecycle Complexity:_ Effective GitOps tools must be aware of and integrate
  with the entire software development lifecycle. This involves everything from
  creating working code to deploying it via command-line tools and other
  automation mechanisms.
- _Tooling Integration:_ Automation tools must interface with various
  components, including CI/CD pipelines, deployment environments, and monitoring
  systems. Achieving seamless integration across these tools can be difficult,
  leading to fragmentation and inefficiencies.
- _Flexiblity Required:_ Each project/company will have its own way of deploying
  GitOps since they are so flexible. That means automation tools are forced to
  deal with code styles, project layouts, and naming that is almost antagonistic
  to automated change.
