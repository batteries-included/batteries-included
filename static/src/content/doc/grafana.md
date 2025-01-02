---
title: Grafana
description:
  Deploy and manage Grafana dashboards for comprehensive monitoring
  visualization.
tags: ['monitoring', 'grafana', 'visualization']
category: batteries
draft: false
---

Grafana is an open-source analytics and monitoring platform that transforms your
metrics into insightful visualizations and dashboards. With Batteries Included,
Grafana comes pre-configured with dashboards for all your services, making it a
perfect choice for monitoring everything from database performance to kubernetes
cluster health.

## Installing Grafana

Installing Grafana in your cluster is straightforward:

1. Navigate to the `Monitoring` tab in the control server.
2. Click `Manage Batteries` to view available monitoring components.

<video src="/videos/docs/grafana/installing-grafana.mp4" controls></video>

## Accessing Grafana

Once installed, accessing Grafana is simple:

1. Go to the `Monitoring` tab in the control server.
2. Click on the `Grafana` entry to open the Grafana interface in a new tab.

<video src="/videos/docs/grafana/opening-grafana.mp4" controls></video>

## Pre-configured Dashboards

Batteries Included automatically creates and maintains dashboards for your
services.

For example, database dashboards are created automatically when you deploy a
database:

1. Navigate to `Datastores` in the control server.
2. Select your database instance.
3. Click the `Grafana Dashboard` button.

<video src="/videos/docs/grafana/opening-pg-grafana.mp4" controls></video>

Similarly, other clusters will have their own dashboards automatically
configured.

## Additional Resources

- Read the official [Grafana documentation](https://grafana.com/docs/) for
  advanced usage.
- Visit our [Monitoring overview](/docs/monitoring) for general monitoring
  setup.
- Check the [VictoriaMetrics guide](/docs/victoria-metrics) for metrics
  collection.
