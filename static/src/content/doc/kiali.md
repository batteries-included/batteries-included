---
title: Kiali
description: Access and use the Kiali service mesh dashboard.
tags: ['network', 'security', 'kiali', 'istio']
category: batteries
draft: false
---

Kiali provides a visualization and monitoring dashboard for your Istio service
mesh, allowing you to observe service mesh topology, view traffic flows, and
monitor the health of your services.

Batteries Included makes deploying and accessing Kiali straightforward, with
automatic integration into your service mesh and monitoring stack.

## Installing Kiali

To set up Kiali in your cluster:

1. Navigate to the `Net/Sec` section in the control server.
2. Click `Manage Batteries` and install the Kiali battery.

<video src="/videos/docs/kiali/kiali-install.mp4" controls></video>

## Accessing Kiali

Once installed, you'll see a `Kiali` link in the `Net/Sec` section. Clicking it
will open the Kiali interface in a new tab.

Once in the Kiali dashboard, you'll see your services organized by Batteries
Included namespaces (like battery-ai, battery-data, etc.)

The dashboard provides a comprehensive view of your service mesh topology, where
you can monitor both inbound and outbound traffic flows between services,
inspect configuration health status, analyze detailed service metrics, and more!

<video src="/videos/docs/kiali/kiali-open.mp4" controls></video>

## Additional Resources

- Check out the official [Kiali documentation](https://kiali.io/docs/) for usage
  details.
- Check our [Monitoring](/docs/monitoring) guide for additional observability
  tools.
- Read our [Istio](/docs/istio) documentation to learn about the service mesh
  batteries powering your cluster.
