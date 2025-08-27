---
title: Announcing Batteries Included v1
date: 2025-08-27
draft: false
tags: ['release', 'v1', 'kubernetes', 'ai', 'self-hosting', 'open source']
excerpt:
  'Batteries Included v1 is here: a production‑ready, open‑source platform that
  makes self‑hosted AI and modern cloud infrastructure simple—on your laptop or
  in AWS.'
image: ./covers/charlesdeluvio-YJxAy2p_ZJ4-unsplash.jpg
---

TLDR: If you want have a magical open source platform experience with a push
button, start here: https://www.batteriesincl.com/docs/getting-started Then
reach out via email, video call, slack, or smoke signals.

## Why v1 matters

Batteries Included gives you a production‑grade, open‑source platform that makes
running serious software (and AI) feel effortless—without handing your data or
roadmap to someone else’s SaaS. Same tools, same configs, same UX from local to
prod.

## Self‑hosting AI, without the pain

If you have an NVIDIA GPU locally, the developer experience is… kind of magical:

- We automatically set up Kubernetes, the NVIDIA Container Toolkit, and the
  device plugins on your machine
- Ollama runs beautifully for local model work
- Jupyter Notebooks are included for rapid prototyping and evaluation
- PGVector is built‑in so RAG systems are a first‑class citizen from day one

If you want details on the local NVIDIA setup, we documented it here:
https://www.batteriesincl.com/docs/nvidia-container-toolkit

When you’re ready for more horsepower, move to the cloud with AWS GPUs. From the
UI you pick the instance/GPU you want, and we provision, configure, and join
those nodes to your Kubernetes cluster—drivers, runtime, and scheduling
included. No yak shaving. Your local notebooks and services scale the same way
in the cloud.

## The open‑source “batteries” you can turn on

Everything runs on Kubernetes and is built from battle‑tested open source. A few
of the highlights in the catalog:

- PostgreSQL (CloudNativePG) and Redis for core data
- PGVector for embeddings and RAG
- Grafana for dashboards and observability
- VictoriaMetrics for metrics at scale
- Istio + Gateway API for L7 traffic and ingress
- Cert‑Manager + Trust Manager to automate certificates and trust bundles
- Keycloak for SSO and identity
- Knative for scale‑to‑zero HTTP services
- Karpenter to autoscale nodes on demand (AWS, Azure PR is in progress)
- Ollama and NVIDIA Device Plugin for on‑cluster model runtime

You can browse and enable batteries from the catalog in the UI—pick what you
need, skip what you don’t.

## Security, SSO, and networking by default

Identity and transport security are first‑class:

- Keycloak is included for SSO; we wire up OAuth/OIDC for platform services and
  handle OAuth tokens and network settings automatically
- eBPF‑powered mesh networking via Istio with mTLS by default, anchored to our
  own certificate authority chain (Cert‑Manager + Battery CA + Trust Manager)
- Gateway API‑based ingress for consistent, policy‑driven routing
- Optional deep visibility with Kiali for traffic, health, and config

## Built for teams and collaboration during operations

Batteries Included is designed with collaboration in mind. Whether you’re a
developer, data scientist, or operations engineer, our platform provides the
tools you need to work together effectively. Operational tools are integrated
into the platform, enabling seamless collaboration across different roles and
functions. Click from AI model UI to Kubernetes resource, pod logs, and
graphical dashboards from the same interface.

Projects allow teams to organize their work, share insights, and collaborate
more effectively. Each project can have its own set of resources, permissions,
and workflows, making it easy to manage complex AI initiatives. Then this
structure can be synced and replicated exactly from local dev machine to cloud
test environment, and on to production.
