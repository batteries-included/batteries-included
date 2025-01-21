---
title: Redis
description: Deploy and manage Redis databases with Batteries Included.
tags: ['database', 'redis', 'datastore']
category: batteries
draft: false
---

Redis is an open-source, in-memory data store that can be used as a database,
cache, message broker, and queue.

Batteries Included leverages
[Redis Operator](https://ot-redis-operator.netlify.app/docs/getting-started/standalone/)
to provide robust Redis support, complete with multiple deployment options to
suit your needs!

## Installing Redis

To set up Redis support in your cluster:

1. Navigate to the `Datastores` section in the control server.
2. Click `Manage Batteries` and install the Redis battery.
3. Once installed, you'll see a new `Redis` section in the Datastores area.

<video src="/videos/docs/redis/redis-install.mp4" controls></video>

## Creating a Redis Database

To create a new Redis instance:

1. Click `New Redis` in the Redis section.
2. Configure your instance settings by choosing a deployment type (standalone,
   replication, or cluster), memory size, and optionally associating it with a
   project.

<video src="/videos/docs/redis/redis-create.mp4" controls></video>

## Accessing Your Redis Database

To view your Redis instance details:

1. Navigate to the `Datastores` section in the control server.
2. Find your Redis cluster under the Redis section.
3. Click the `Services` tab to view connection information, such as the service
   name/namespace, cluster IP, and port number.

<video src="/videos/docs/redis/redis-view.mp4" controls></video>

## Additional Resources

- Visit the official [Redis documentation](https://redis.io/documentation) for
  detailed usage information.
- Check our [Projects](/docs/projects) guide for setting up Redis as part of
  larger applications.
- Visit [Monitoring](/docs/monitoring) for setting up observability.
