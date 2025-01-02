---
title: Projects
description: Create and manage projects to organize your services and resources.
tags: ['projects', 'overview', 'management']
category: getting-started
draft: false
---

Projects in Batteries Included help you organize related services and resources
together. Each project automatically configures and integrates all necessary
components, making it easy to manage complex infrastructure setups.

## Creating a New Project

To start a new project:

1. Click `New Project` in the top right of your dashboard.
2. Enter your project name.
3. Select a project type.
4. Configure project-specific settings.
5. Add any additional batteries you might need.

> **Note:** You can add additional batteries to your project post-creation, so
> don't worry if you missed something!

<video src="/videos/docs/projects/creating-project.mp4" controls></video>

## Project Types

### Web Projects

Perfect for web applications and services. Features include:

- Knative (serverless) deployment for automatic scaling.
- Traditional deployment for more control.
- Optional database and cache integration.
- Environment variables automatically configured.

### AI Projects

Built for machine learning and interactive data science work. Features include:

- Jupyter notebook environment.
- Ollama Large Language Model (LLM).
- Optional database integration(s) and pre-configured environment variables.

### Database Only

For projects primarily requiring a database. Databases include PostgreSQL,
Redis, and FerretDB/MongoDB.

### Bare Project

A minimal project without pre-configured components.

## Project Management

Once created, your project appears in the dashboard with:

- Overview of all project resources.
- Integrated Grafana dashboards.
- Database status and management.
- Service configurations and logs.
- Pod status and metrics.

Each project component can be managed directly from the project overview page,
giving you a central place to monitor and control your infrastructure.

<img src="/images/docs/projects/dashboard.png">

## Additional Resources

- Check our [PGVector guide](/docs/pgvector) for a full-fledged AI application
  example.
- Visit [Monitoring](/docs/monitoring) for metrics and logging.
