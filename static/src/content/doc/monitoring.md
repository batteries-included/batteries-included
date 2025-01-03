---
title: Monitoring
description:
  Set up comprehensive monitoring using Grafana and VictoriaMetrics in your
  cluster.
tags: ['monitoring', 'grafana', 'victoriametrics']
category: getting-started
draft: false
---

Batteries Included offers robust monitoring capabilities, with built-in Grafana
and VictoriaMetrics support. Let's go over setting up these tools and accessing
monitoring dashboards for your clusters.

## Setting Up Monitoring

[Grafana](https://grafana.com/docs/grafana/latest/introduction/) is an
open-source, web-based analytics and monitoring platform. It provides powerful
visualization tools, allowing you to create charts, graphs, and alerts for your
infrastructure and applications.

[VictoriaMetrics](https://docs.victoriametrics.com/) is a fast, scalable time
series database and monitoring solution. It efficiently collects, stores, and
processes metrics from your Kubernetes clusters and applications.

To set up monitoring for your environment:

1. Navigate to the `Monitoring` tab in the control server.
2. Click on `Install Batteries` or `Manage Batteries`. You'll see a list of
   available monitoring batteries, including:

   - Grafana
   - Victoria Metrics
   - Kube Monitoring
   - Loki
   - Promtail

3. To install any of these components, simply click the `Install` button next to
   the desired battery.
4. For a well-rounded monitoring setup, we recommend installing both Grafana and
   VictoriaMetrics batteries. Installing the `Victoria Metrics` battery will
   also install the `VM Operator`, `VM Agent`, and `VM Cluster` batteries.

<video src="/videos/monitoring/installing-monitoring.webm" controls></video>

## Accessing the Dashboards

Once you've installed Grafana and the necessary VictoriaMetrics components:

1. Return to the `Monitoring` tab in the control server.
2. Click on the either the `Grafana` or `VM Select` entry. This will open the
   Grafana or VictoriaMetrics dashboard in a new tab.

## Cluster-Specific Grafana Dashboards

Batteries Included automatically creates Grafana dashboards for your clusters.
To access these:

1. Navigate to the `Kubernetes` tab in the control server. This shows all active
   pods with their status.
2. Click on a pod you wish to monitor (e.g. a Jupyter Notebook pod.)
3. Look for the `Grafana Dashboard` button. Clicking this will open a
   pre-configured Grafana dashboard specific to that cluster.

Database cluster dashboards can also be accessed in their own page:

1. Go to the `Datastores` section.
2. Select the database cluster you want to monitor.
3. Click the `Grafana Dashboard` button to view metrics for that specific
   instance.

<video src="/videos/monitoring/database-grafana.webm" controls></video>
