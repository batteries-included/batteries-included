---
title: VictoriaMetrics
description:
  Deploy VictoriaMetrics for efficient and scalable metrics collection and
  storage.
tags: ['monitoring', 'metrics', 'victoriametrics']
draft: false
---

VictoriaMetrics is a fast, cost-effective time series database and monitoring
solution. It serves as an optional metrics collection service in Batteries
Included, providing efficient storage and retrieval for all your monitoring data
while maintaining high performance even with large amounts of metrics.

## Installing VictoriaMetrics

1. Navigate to the `Monitoring` tab in the control server.
2. Click `Manage Batteries` to view available monitoring components.
3. Find the `VictoriaMetrics` battery and click `Install`.

When installing VictoriaMetrics, you can configure the replication factor,
number of nodes for different operations, and storage size based on your needs.
For most installations, the default settings work well out of the box.

Installing the `VictoriaMetrics` battery will also automatically install the
`VM Agent` battery.

<video src="/videos/docs/vm/installing-vm.mp4" controls></video>

## VMUI Query Interface

The VMUI (VictoriaMetrics User Interface) provides a powerful web interface for
querying and exploring your metrics. Access it through the `Monitoring` tab by
clicking `VM Select`:

- Write and execute [MetricsQL](https://docs.victoriametrics.com/metricsql/)
  queries.
- View results in graph, table, or JSON formats.
- Explore metric names and labels.

<video src="/videos/docs/vm/vm-query.mp4" controls></video>

## VM Agent

The VM Agent handles metrics collection and scraping. Access its interface
through the `Monitoring` tab by clicking `VM Agent`. This provides several
useful endpoints:

- `/targets` - View status of discovered active targets.
- `/service-discovery` - Explore labels before and after relabeling.
- `/metric-relabel-debug` - Debug metric relabeling.
- `/api/v1/targets` - Get detailed tar-get information in JSON format.

You can access these endpoints directly through the VM Agent URL, for example:
`http://vmagent.<your-cluster>/api/v1/targets`

## Additional Resources

- Visit the official
  [VictoriaMetrics documentation](https://docs.victoriametrics.com/) for usage
  details.
- Check the [Grafana docs](/docs/grafana) for metrics dashboards and
  visualization.
