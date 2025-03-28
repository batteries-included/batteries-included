---
title: Single-Node Batteries Included
description:
  Learn how running Batteries Included locally makes development a breeze.
tags: ['architecture']
category: getting-started
draft: false
---

Modern development cycles should allow users to move between local and
production as seamlessly as possible. Batteries Included makes this possible by
providing a consistent toolset that works across environments—from your laptop
all the way up to enterprise production.

## The Development Journey

With Batteries Included, developers can progress through a natural iterative
journey:

1. **Local Development**: Start with a lightweight environment locally.
2. **Staging Testing**: Deploy to staging with the same configuration.
3. **Production Deployment**: Confidently launch to production using the same
   familiar tools.

Using Batteries Included like this eliminates the common frustration of "works
on my machine" problems, not only reducing onboarding time for new team members
but also ensuring what works locally works in production as well.

## Getting Started Locally

Unlike traditional approaches that require developers to set up a bunch of
dependencies or write complex Docker Compose files or Kubernetes manifests,
Batteries Included provides a streamlined setup process:

1. Visit [home.batteriesincl.com](https://home.batteriesincl.com) and create a
   new installation.
2. Copy the provided command, which looks something like:
   ```bash
   /bin/bash -c "$(curl -fsSL https://home.batteriesincl.com/api/v1/installations/<slug>/script)"
   ```
3. Run the command, which automatically downloads and configures the `bi` CLI
   tool for you.
4. Access your local environment through the provided URL at the end of setup.

The script handles everything—downloading the right binary for your system,
setting up paths, and starting the local Kubernetes cluster. Within minutes, you
have a fully functional environment on your own PC.

## Meet the `bi` CLI Tool

The `bi` command-line interface is your control center for managing Batteries
Included installations. This powerful tool abstracts away the complexity of
Kubernetes, networking, and database management into simple, intuitive commands.

Regardless of your deployment environment, `bi` provides a consistent interface
for:

- **Managing installations**: Starting, stopping, and configuring environments.
- **Database operations**: Creating connections, port forwarding, and retrieving
  credentials.
- **Network management**: Configuring VPN access to secure cluster resources.
- **Debugging**: Collecting logs and diagnostic information.
- **Cluster operations**: Interacting with your Kubernetes resources.

`bi` combines multiple specialized tools into one streamlined interface that
works the same way across all environments. As you progress through development
to production, the same commands you've mastered locally will apply to your
production environment.

## Debugging Made Easy

Connecting to databases is simple with built-in port forwarding:

```bash
bi postgres port-forward my-installation my-database-cluster -l 5432
```

For connection details:

```bash
bi postgres access-info my-installation my-database-cluster my-username --localhost
```

Troubleshooting is an essential part of development. Batteries Included provides
multiple ways to debug your applications:

- **Integrated Kubernetes views**: Access logs and resource usage directly from
  the Control Panel.
- **Access to pod logs**: View application output without complex kubectl
  commands.
- **Diagnostic tools**: Collect comprehensive debug information using the `rage`
  command:

```bash
bi rage my-installation
```

## Enterprise-Ready Security

Even in local development, Batteries Included maintains enterprise-grade
security practices:

- Each installation has a unique elliptic curve key for signing and encryption.
- Communication between components uses public key encryption.
- Credentials are handled securely with short-lived URLs that expire after
  successful installation.

## The Power of Consistency

The real magic happens when your entire team uses the same tools and
configurations. Code that runs locally will behave the same way in production
because:

- The same Kubernetes configurations are used across environments.
- Service/battery configurations and versions remain consistent.
- Networking configurations mirror production setups.
- Security policies are enforced consistently.

When it's time to deploy to production, you're not learning a new system—you're
using the same familiar tools with different resource settings.

## Beyond Local Development

As your application grows, Batteries Included scales with you. You can retrieve
WireGuard VPN configurations using:

```bash
bi vpn config my-production-installation
```

Batteries Included provides this consistent, easy-to-use toolset across all
stages of development, making the transition from local to production as smooth
as possible, and ensuring that what works locally will work in production just
the same.
