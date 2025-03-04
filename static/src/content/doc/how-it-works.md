---
title: How does Batteries Included work?
description:
  A comprehensive overview of the Batteries Included architecture and how it
  works.
tags: ['architecture']
category: batteries
draft: false
---

## Introduction

Modern software infrastructure has become increasingly complex, requiring
specialized knowledge and significant resources to deploy and manage
effectively. Teams often struggle with integrating various tools, maintaining
configuration consistency, and ensuring security across their stack - challenges
that can slow development and increase operational overhead.

Batteries Included was designed to solve these challenges by providing a
comprehensive, integrated platform that simplifies infrastructure management
while leveraging the power of modern technologies like Kubernetes.

Batteries Included follows a layered architecture that combines traditional web
applications with Kubernetes-native components to create a seamless
infrastructure management experience:

<div align="center">
  <img src="/images/docs/how-it-works/general-flow.png" alt="High-level user flow" width="60%"/>
</div>

By separating user-facing components from the underlying infrastructure,
Batteries Included makes complex operations accessible to users with varying
levels of technical expertise. This setup also facilitates easy updates and
maintenance, as components can be updated independently without disrupting the
entire system.

## Core Components

Batteries Included consists of two primary components that work together to
provide a seamless user experience:

- **Home Base**: This web application serves as the central management portal
  for user registration, billing, and installation management. Home Base is the
  first point of contact for users and provides the interface for creating new
  installations and managing existing ones. It handles user authentication,
  subscription management, and serves as the gateway to individual Control
  Server instances, allowing users to manage multiple environments from one
  place.
- **Control Server**: The heart of Batteries Included, the Control Server
  manages the desired state of the instance. It provides a user-friendly web
  interface for managing batteries/resources, monitoring system health, and
  configuring services. Built on Elixir and OTP for reliability and scalability,
  the Control Server maintains the state of the entire system in its database,
  using this information to generate Kubernetes resources and apply changes. It
  acts as a bridge between the user's intent and the actual infrastructure,
  translating high-level goals into concrete resources.
- **BI CLI**: The `bi` CLI tool provides intelligent bootstrapping, deployment
  management, and programmatic interaction with Batteries Included. It contains
  significant built-in intelligence - for example, when running locally, it
  automatically configures IP ranges to use addresses that Docker already
  routes, simplifying local development. The CLI handles complex tasks like
  cluster creation, certificate management, and service discovery while
  abstracting away the underlying complexity from users.

Batteries Included is built on top of Kubernetes, leveraging its container
orchestration capabilities while abstracting away most of its complexity. The
platform can be deployed on local Kubernetes clusters (i.e. using Kind) or
production clusters in cloud environments (e.g. AWS, Azure, etc.)

Kubernetes uses a declarative approach where you specify your desired system
state through resources like Deployments and Services, while Batteries Included
works behind the scenes to maintain that state. This foundation provides
essential capabilities including service discovery, health monitoring, and
automatic scaling that ensure your applications remain reliable and responsive
under varying workloads.

<div align="center">
  <img src="/images/docs/how-it-works/kubernetes.png" alt="Kubernetes" width="60%"/>
</div>

## Batteries

The idea of "batteries" is central to the Batteries Included platform, giving it
both its name and distinctive architecture. In traditional infrastructure
setups, developers often have to configure and integrate various components
manually. Batteries Included changes this paradigm by providing pre-configured,
modular components that can be easily added to or removed from an installation.

Think of batteries as modular, self-contained infrastructure components that
provide specific functionality to the platform; each of these having the
following features:

- **Modularity**: Each battery is a self-contained unit that can be installed,
  updated, or removed independently.
- **Standardization**: Batteries follow consistent patterns for installation,
  configuration, and integration.
- **Pre-configuration**: Batteries come pre-configured with sensible defaults,
  reducing the need for manual setup.
- **Integration**: Batteries are designed to work together, with automatic
  discovery and configuration of dependencies.

Examples of batteries include:

- Database batteries (PostgreSQL, Redis, FerretDB)
- Monitoring batteries (Grafana, VictoriaMetrics)
- AI/ML batteries (Jupyter Notebooks, Ollama)
- Web service batteries (Knative, Traditional Services)
- Security batteries (Keycloak, SSO, Certificate Management)

Batteries follow a consistent installation and integration pattern that makes it
easy for users to add new functionality to their installation. The process
combines user interaction through the web interface with automated background
processes:

- **Discovery**: The Control Server maintains a registry of available batteries
  that can be installed. Users can browse this registry to find batteries that
  meet their needs.
- **Installation**: When a user selects a battery for installation, the Control
  Server generates the necessary Kubernetes resources using templates and
  user-provided configuration.
- **Configuration**: The battery is configured based on user inputs and platform
  defaults. Configuration is stored in the Control Server database and used to
  generate Kubernetes resources.
- **Integration**: The battery is integrated with other installed batteries as
  needed. For example, a new database battery might be automatically configured
  to export metrics to the monitoring system.
- **Validation**: Batteries Included verifies that the battery is running
  correctly by checking health endpoints and monitoring resource usage.

<video src="/videos/docs/jupyter/installing-jupyter.mp4" controls></video>

This simplified process abstracts away the complexity of manual installation and
configuration, allowing users to focus on their applications rather than
infrastructure.

## Configuration and Dependency Management

Batteries often have dependencies on other batteries, creating a complex web of
relationships that must be managed correctly for the system to function.
Batteries Included handles these dependencies through several mechanisms:

- **Dependency Resolution**: When installing a battery, the platform checks if
  its dependencies are already installed or need to be installed first.
  Dependencies can be hard requirements (must be installed) or optional
  integrations (enhanced functionality if present).
- **Configuration Discovery**: Batteries expose their configuration through
  Kubernetes resources (Services, ConfigMaps, Secrets) which other batteries can
  discover. This allows batteries to find and connect to each other
  automatically.
- **Secrets Management**: Credentials and sensitive configuration is stored in
  Kubernetes Secrets and automatically shared between batteries that need to
  communicate. This ensures secure communication between components without
  exposing sensitive information.
- **Network Isolation**: Batteries are organized into logical namespaces (e.g.,
  `battery-data`, `battery-monitoring`) to provide network isolation and access
  control, helping maintain security while allowing controlled communication
  between batteries. Istio service mesh is used to implement sophisticated
  network policies and traffic management between these namespaces. When the
  Certificate Authority battery is installed, the system automatically
  configures full mTLS with a local auditable certificate chain, providing
  encrypted communication between services and strong authentication.

By removing much of the complexity traditionally associated with integrating
different software components, it becomes easier for users to build complex
systems without deep expertise in each component.

## Snapshot and Apply Pattern

Batteries Included uses a distinctive "Snapshot and Apply" pattern for
deployments, which differs from the traditional Kubernetes reconciliation loop.
While Kubernetes controllers continuously observe the current state and
reconcile it with the desired state, the snapshot and apply pattern takes a more
structured approach.

This approach was developed to address several limitations of the reconciliation
loop, particularly in complex environments with many interdependent resources.
In our experience, the snapshot and apply pattern provides better debuggability,
introspection, and user experience, especially at scale.

The Control Server maintains the desired state of the entire system in its
database. This desired state includes the configuration of all installed
batteries, user-provided settings, and generated resources. This comprehensive
state data is used to generate the necessary Kubernetes resources during the
snapshot and apply process, consisting of five steps:

1. **Prepare**: Take a point-in-time snapshot of the entire system state,
   including both the database state and the current Kubernetes state.
2. **Generate**: Use functional code to generate the desired system state based
   on the snapshot. This involves transforming the database state into concrete
   Kubernetes resources.
3. **Apply**: Apply changes to move from the current state to the desired state.
   This involves creating, updating, or deleting Kubernetes resources as needed.
4. **Record**: Record the status of all applied resources in the database,
   including any errors or warnings encountered during the apply phase.
5. **Broadcast**: Notify the system about the completed operation through an
   event system, allowing components to react accordingly.

<div align="center">
  <img src="/images/docs/how-it-works/snapshot-apply.png" alt="Snapshot and Apply"/>
</div>

For change detection, Batteries Included uses a clever approach that balances
efficiency with reliability:

- Each Kubernetes resource gets a cryptographic hash annotation based on its
  content.
- When resources are applied, the platform compares the hash of the existing
  resource with the hash of the desired resource.
- If the hashes match, no update is needed; if they differ, the resource is
  updated.

With this hash-based approach, we enable efficient reconciliation without
constantly applying unnecessary updates. It also provides a clear indication of
which resources have changed and how, making it easier to debug issues when they
occur.

In addition to the hash-based change detection, Batteries Included also stores
the complete history of each resource in its content-addressable storage system.
This history allows for rollbacks and audit trails, providing a complete picture
of how the system has evolved over time.

As a result, using the snapshot and apply pattern yields various high-level
benefits:

- **Functional, Deterministic Changes**: Each deployment is based on a complete
  snapshot of the system, making changes more predictable and repeatable. By
  treating the deployment process as a functional pipeline where specific inputs
  (the current system state) deterministically produce specific outputs (the new
  desired state), we gain predictability and consistency in deployments.
- **Visibility Into Plans**: Users can see the intended plan in real-time during
  the snapshot and application phases, making it easier to understand what's
  changing and why. In production environments, this visibility into both the
  intended actions and final status has repeatedly proven invaluable for
  troubleshooting.
- **Improved Debugging**: If something goes wrong, having a complete
  before-and-after snapshot makes it easier to diagnose the issue.
- **Atomic Updates**: Changes are applied as a single logical unit, reducing the
  risk of partial updates.
- **Audit Trail**: The history of snapshots provides a complete audit trail of
  changes to the system.

This pattern extends beyond just Kubernetes. For example, when the OAuth battery
is enabled, the snapshot and apply process coordinates change across both
Kubernetes and Keycloak. A unified approach like this allows for sophisticated
behaviors like scheduling shorter retry times when Keycloak is creating user
credentials needed by an oauth_proxy resource in Kubernetes.

## Resources (Generated/Applied)

Batteries Included generates and manages several types of Kubernetes resources
to create a complete infrastructure environment:

- **Core Resources**: Standard Kubernetes resources like Deployments, Services,
  ConfigMaps, and Secrets. These resources define the basic components of the
  system.
- **Custom Resources**: Resources defined by Custom Resource Definitions (CRDs)
  for specific batteries. For example, PostgreSQL clusters are defined using
  custom resources provided by the PostgreSQL operator.
- **Integration Resources**: Resources that connect different batteries, such as
  ServiceMonitors for Prometheus integration, network policies for controlling
  communication between batteries, and Keycloak realms for self-hosted OAuth
  authentication across services. These integration resources ensure secure and
  consistent authentication throughout the platform.

Templates are used to generate these resources based on user configuration and
platform defaults. The templates use a combination of static values and dynamic
input to create resources that meet the specific needs of each installation.

For efficient resource management, Batteries Included uses content-addressable
storage to track resource versions. Each resource is hashed based on its
content, and this hash is used as an identifier. This approach allows for
efficient comparison and change detection, as the platform can quickly determine
if a resource has changed by comparing its hash.

## Automated Service Deployment and Scaling

One of the key advantages of Batteries Included is its ability to automate
service deployment and scaling, reducing the manual effort required to manage
infrastructure:

- **Serverless Workloads**: Web services deployed via Knative automatically
  scale based on incoming traffic, even scaling to zero when not in use. This
  approach provides efficient resource usage while maintaining performance under
  load.
- **Resource-Based Scaling**: Database services can be scaled based on CPU,
  memory, and storage requirements. Batteries Included handles the complex
  process of scaling databases safely, including data migration and replication
  configuration.
- **Replica Management**: Traditional services can be manually or automatically
  scaled by adjusting the number of replicas. This approach provides
  fine-grained control over resource allocation and availability.

These automated scaling capabilities ensure that services have the resources
they need to perform well while minimizing waste. By scaling automatically based
on demand, the platform reduces both operational overhead and resource costs.

In addition to scaling, Batteries Included also automates service deployment
through templates and workflows. Users can deploy new services with minimal
configuration, as the platform automatically handles the details of creating the
necessary Kubernetes resources, configuring networking, and setting up
monitoring.

## Infrastructure as Code Principles

While Batteries Included provides a user-friendly web interface, it follows
Infrastructure as Code principles behind the scenes. This approach combines the
best of both worlds: ease of use for users and robust, repeatable infrastructure
management under the hood:

- **Declarative Configuration**: Defining resources declaratively specifies the
  desired end state rather than the steps to get there, making system reasoning
  easier and reducing configuration drift risk.
- **Version Control**: Resource definitions are stored in the Control Server
  database with versioning, allowing for rollbacks and audit trails. This
  versioning provides a complete history of changes to the system.
- **Reproducibility**: The entire installation can be reproduced from the stored
  configuration. This reproducibility ensures that environments can be recreated
  consistently if needed.
- **Automation**: Manual operations are minimized in favor of automated
  processes. Automation reduces the risk of human error and ensures that
  operations are performed consistently.

Rolling back via snapshot and apply ensures that the infrastructure is reliable,
reproducible, and maintainable, even as the system grows in complexity.

## Web Interface Workflow

The Batteries Included web interface goes far beyond simply making Kubernetes
more approachable - it fundamentally improves operational safety and efficiency
through context-aware editing and immediate feedback.

The main components of the web interface include:

- **Dashboard**: Overview of system health, resources, and recent activities.
  The dashboard provides a quick summary of the system's status and highlights
  any issues that need attention.
- **Batteries**: Browse, install, and configure available batteries. This
  section allows users to add new functionality to their installation with just
  a few clicks.
- **Projects**: Organize resources into logical projects (e.g., Web, AI,
  Database). Projects provide a way to group related resources and manage them
  as a unit.
- **Services**: Manage deployed services, view logs, and monitor performance.
  This section provides detailed information about individual services and
  allows users to manage them directly.
- **Settings**: Configure system-wide settings and user access. This section
  provides control over global configurations and user permissions.

![UI dashboard](/images/docs/getting-started/dashboard.png)

What sets the interface apart is its approach to how changes are made:

- **Contextual Information While Editing**: The interface provides critical
  information to engineers during the editing process. Instead of switching
  between documentation and configuration files, the system presents relevant
  metrics, dependencies, and best practices directly alongside edit forms,
  aiding decision-making in ways a traditional text editor cannot.
- **Type-Aware Validations**: Unlike Kubernetes' string-based configuration
  ("500" vs "500Mi" vs "500MB" vs "524288000"), the interface understands data
  types. This prevents common errors like mismatched units, invalid ranges, or
  incompatible settings before they occur.
- **Immediate Feedback Cycle**: When attempting changes that might cause issues
  (like requesting more instances than the cluster can handle), the interface
  immediately highlights problems and explains why. This real-time feedback
  leads to better decisions and more stable deployments compared to discovering
  problems only after changes are applied.

This approach evolved from observing a common pattern in production incidents:
an engineer's seemingly minor configuration change triggers an outage by
unknowingly affecting complex underlying systems. By providing a purpose-built
interface with fewer inputs, stronger validation, and more contextual
information, Batteries Included breaks this cycle and creates more stable
infrastructure.

## Project-Based Resource Management

Batteries Included can organize resources into projects, providing a logical
grouping of related services and resources.

A project might include a variety of resources working together to provide a
specific application or service:

- Web services handling user interfaces and API endpoints.
- Databases storing application data.
- Monitoring dashboards providing insights into project performance.
- AI notebooks for data analysis and model development.

A project-based approach makes it easier to manage complex systems by grouping
related resources together and providing a unified view of their status and
configuration. Users can see at a glance how different components of their
application are performing and make changes to related resources in a
coordinated way.

## Built-in Monitoring and Automated Maintenance

Batteries Included provides comprehensive monitoring and automated maintenance
capabilities out of the box, eliminating the need for separate setup while
minimizing operational overhead:

- **Metrics Collection**: VictoriaMetrics collects performance metrics from all
  services and infrastructure components, providing insights into resource usage
  and system health.
- **Visualizations**: Pre-configured Grafana dashboards offer immediate
  visibility into system performance across all components.
- **Health Checks**: Regular service availability and performance checks provide
  early warnings before issues impact users.
- **Alerting**: Configurable alerts notify administrators of potential issues
  through various channels, including email and messaging platforms.
- **Battery Updates**: Batteries can be updated automatically with zero downtime
  and minimal intervention.
- **Kubernetes Updates**: For managed installations, the underlying Kubernetes
  cluster receives automatic updates to maintain security and stability.
- **Routine Maintenance**: Batteries Included handles tasks like log rotation,
  certificate renewal, and database optimization automatically.

The combination of proactive monitoring and seamless maintenance creates a
self-sustaining environment where potential problems are identified early and
routine updates occur without disruption. By automating these traditionally
time-consuming aspects of infrastructure management, teams can focus on
application development rather than operational overhead.

## Rollback and Versioning Capabilities

Batteries Included's content-addressable storage system enables robust rollback
and versioning capabilities, providing a safety net for changes and a complete
history of the system's evolution.

Key aspects of the rollback and versioning system include:

- **Resource Versioning**: Each version of a resource is stored with a unique
  content-based identifier. This approach ensures that every change is tracked
  and can be referenced later.
- **Deployment History**: Batteries Included maintains a history of deployments
  that can be viewed and rolled back to. This history provides a complete audit
  trail of changes to the system.
- **Rollback Process**: Rolling back involves selecting a previous deployment
  state and applying it using the snapshot and apply pattern. This process
  ensures that rollbacks are performed safely and consistently.

<div align="center">
  <img src="/images/docs/how-it-works/rollback.png" alt="Rollback"/>
</div>

## An All-in-One DevOps Solution

In essence, Batteries Included transforms infrastructure management by combining
the power of Kubernetes with an intuitive interface. The platform's modular
battery system and snapshot-based deployments create a flexible foundation that
lets teams focus on building applications rather than wrestling with
infrastructure.

Haven't deployed your first installation yet?
[Get started with Batteries Included](/docs/getting-started) now!
