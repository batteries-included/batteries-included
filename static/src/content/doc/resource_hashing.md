---
title: 'Resource Hashing'
description:
  Implementation of cryptographic hashing for tracking and comparing resources
  in the control system.
tags: ['overview', 'code', 'control-server', 'kubernetes']
category: development
draft: false
---

Kubernetes resources are challenging to compare versus the resources that
created them. For example, some resources get status fields that are constantly
changing, while others will get managed fields added to their metadata. So
resources might not be equal when compared directly, but they still are
functionally equivalent. However, we need a fast way to tell if a resource is
functionally the same as a proposed new resource (Very useful when syncing
changes to Kubernetes).

This is where `platform_umbrella/apps/common_core/lib/common_core/hashing.ex`
shines. It ties together all the code needed to derive object equivalency on
Kubernetes resources stored using annotations.

# Adding the Hash

- Sanitize the resource, removing any fields that are machine-generated or
  contain mutable state.
- Then perform an in-order recursive traversal of the resource.
- Along the way, update a Sha3 -256 MAC treating everything as a stream of data
  to convert to string and pass to mac update.
- Finalize the mac
- place the computed hash in `battery/hash` annotation

# Comparing Resources

- For each resource, check if there's an annotation. If both are present, then
  string-compare the hashes.
- If the annotations are missing, follow the above algorithm to get the hash.
  Compare the two computed hashes.
