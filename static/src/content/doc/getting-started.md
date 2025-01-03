---
title: Getting Started
description: Getting started with Batteries Included.
tags: ['getting-started', 'overview']
category: getting-started
draft: false
---

## Getting Started with Batteries Included

Whether you're building web services, running AI workloads, or managing
databases, getting started takes just a few minutes!

### Create Your Installation

Start by logging in or creating an account at
[https://home.batteriesincl.com/login](https://home.batteriesincl.com/login).
Once logged in, click `Create an installation` and provide some basic details
for your environment.

Then, choose your preferred deployment type:

- **Local Development**: Perfect for testing locally using Kind (requires
  Docker).
- **Cloud Deployment**: Seamless automated setup on AWS with EKS.
- **Existing Cluster**: Simple installation on your current Kubernetes
  infrastructure, whether it's running on AWS, Azure, or any other cloud
  provider.

<div align="center">
   <img src="/images/docs/getting-started/install-1.png" width="80%">
</div>

### Run Installation

After configuring your installation details, you'll receive a simple one-line
shell script. Just copy and run this command - we'll take care of all the
configuration, security, and integration automatically!

<div align="center">
   <img src="/images/docs/getting-started/install-2.png" width="50%">
</div>

## Post-Installation

That's it! Once installation completes, the control server becomes your central
hub for:

### Battery Management

Choose from our wide arsenal of batteries to include in your installation:

- **Databases**: Deploy and manage PostgreSQL, FerretDB/MongoDB, and Redis
  instances.
- **Monitoring**: Set up VictoriaMetrics with Grafana dashboards.
- **Web Services**: Deploy with Knative for automatic serverless scaling.
- **AI/ML**: Add Jupyter notebooks, vector databases, and LLMs (Ollama).
- **Security**: Configure OAuth and SSO with Keycloak, SSL certificates, mTLS,
  and more.

### Project Management

Build and manage your infrastructure through our intuitive project system:

- Choose specialized project templates for Web, AI/ML, Database, or custom
  needs.
- Access monitoring, logging, and management through a unified dashboard.

### System Overview

Monitor and manage your entire infrastructure from one place:

- Monitor resource usage across your cluster(s).
- Check service health and status.
- Access centralized logging.
- Manage configurations and settings.
- View performance metrics and alerts.

<img src="/images/docs/getting-started/dashboard.png">

## Next Steps

- Visit our [Projects guide](/docs/projects) to learn about organizing your
  services.
- Check out [Monitoring](/docs/monitoring) for setting up observability.
- Explore [PGVector](/docs/pgvector) for AI/ML capabilities.

## Need Help?

We're here to support you every step of the way:

- Browse our comprehensive [documentation](/docs) for guides and information on
  available batteries.
- Connect with us on
  [Slack](https://join.slack.com/t/batteries-included/shared_invite/zt-2qw1pm9pz-egaqvjbMuzKNvCpG1QXXHg) -
  we're always happy to help!
- Found something that needs fixing? Submit an issue on
  [GitHub](https://github.com/batteries-included/batteries-included/issues) to
  help us improve.
