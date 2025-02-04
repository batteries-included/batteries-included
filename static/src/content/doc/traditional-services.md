---
title: Traditional Services
description:
  Deploy and manage traditional container workloads that don't follow the
  serverless model.
tags: ['devtools', 'containers', 'services']
category: batteries
draft: false
---

The Traditional Services battery enables you to run containers that don't
conform to the serverless HTTP model. This is particularly useful for running
long-running processes or services that need to be accessed by other services in
your cluster.

Batteries Included automates the deployment, scaling, and monitoring of these
services, making it easy to run any container workload with just a few clicks!

## Installing Traditional Services

To set up Traditional Services:

1. Navigate to the `DevTools` section in the control server.
2. Click `Manage Batteries`.
3. Find and install the `Traditional Services` battery.

<video src="/videos/docs/traditional-services/installing-traditional-services.mp4" controls></video>

## Creating a Service

After installation, you'll see a `Traditional Services` section in the DevTools
tab. To create a new service:

1. Click `New Service` in the Traditional Services section.
2. Configure your service by setting its name, size, and number of running
   instances. Add containers and their images, set up environment variables, and
   expose any needed ports.
3. Click `Save Traditional Service` to finalize creation.

That's it! Right away, your service will start spinning up and you can access it
by clicking the `Running Service` link in your service's page.

<video src="/videos/docs/traditional-services/creating-traditional-service.mp4" controls></video>
