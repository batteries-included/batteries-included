---
title: Knative
description: Deploy and manage serverless workloads with Knative.
tags: ['serverless', 'knative', 'web-services']
category: batteries
draft: false
---

Knative is a Kubernetes-based platform that provides serverless capabilities,
enabling you to run stateless containers that automatically scale based on
traffic - including scaling to zero when there's none. It works in conjunction
with Istio, an open-source service mesh that provides a unified way to control
how microservices share data with each another.

With Batteries Included, deploying and managing Knative services is
straightforward and seamlessly integrated with the rest of your infrastructure.

## Installing Knative

To get started with Knative:

1. Navigate to the `DevTools` section in the control server.
2. Click `Manage Batteries`.
3. Find the `Knative` battery and click `Install`.

The Knative battery includes all necessary components like activators,
autoscalers, and controllers, all pre-configured for optimal performance and
integrated with the existing Istio installation.

<video src="/videos/docs/knative/knative-install.mp4" controls></video>

## Creating a New Service

Once Knative is installed, you can create new services:

1. Go to the `DevTools` section.
2. Find the new `Knative` subsection.
3. Click `New Service`.
4. Configure your service as necessary and save your changes; this means adding
   containers, setting environment variables (e.g. database connection URLs),
   assigning it to a project, etc.

<video src="/videos/docs/knative/knative-add-service.mp4" controls></video>

## Environment Integration

Knative services automatically integrate with other components in your
installation.

For example, you can get automatically generated database connection strings as
environment variables, and monitoring and logging batteries (e.g.
VictoriaMetrics and Grafana) will integrate automatically.

## Additional Resources

- Check our [Projects](/docs/projects) for ready-to-use templates that go even
  further in out-of-the-box integration.
- Visit [Monitoring](/docs/monitoring) for observability setup.
- Explore [Security](/docs/security) for network policies and access control.
