---
title: Istio
description: Understanding Istio service mesh and gateway in your cluster.
tags: ['network', 'security', 'istio', 'service-mesh']
category: batteries
draft: false
---

Istio is a foundational component of Batteries Included, providing the service
mesh infrastructure that powers secure communication between services.

Both the Istio and Istio Gateway batteries come pre-installed by default in your
cluster, requiring no setup while delivering powerful networking capabilities.

## What is Istio?

The Istio battery is an open-source service mesh that manages communication
between services in your cluster. It provides:

- Traffic management and routing control.
- Service-to-service authentication and encryption.
- Detailed monitoring and tracing of service communications.
- Access control and traffic policies.

## Istio Gateway

The Istio Gateway battery, installed alongside Istio by default, serves as the
entry point for external traffic into your cluster's service mesh. It acts as a
smart load balancer that:

- Routes incoming traffic to the appropriate services.
- Manages TLS termination for secure connections.
- Enforces traffic policies and access controls.
- Provides a unified entry point for all external requests.

In most cases, you won't need to interact directly with either of these
batteries - Batteries Included handles all configuration and management
automatically, letting you focus on building your applications!

## Additional Resources

- Visit [Monitoring](/docs/monitoring) for observability setup.
- See [Knative](/docs/knative) for serverless deployment integration with Istio.
