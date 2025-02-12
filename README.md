&nbsp;

<p align="center">
  <img src="static/public/images/logo-dark.png#gh-dark-mode-only" width="600"/>
  <img src="static/public/images/logo-light.png#gh-light-mode-only" width="600"/>
</p>

&nbsp;

Welcome! [Batteries Included](https://www.batteriesincl.com) is your all-in-one
platform for building and running modern applications. We take the complexity
out of cloud infrastructure, giving you production-ready capabilities through an
intuitive and easy-to-use interface.

## Why Batteries Included?

- 🚀 **Launch Production-Ready Infrastructure in Minutes**

  - Deploy databases, monitoring, and web services with just a few clicks
  - Automatic scaling, high availability, and security out of the box
  - Built on battle-tested open source technologies like Kubernetes

- 💻 **Focus on Building, Not Infrastructure**

  - No more wrestling with YAML or complex configurations
  - Automated setup of best practices for security, monitoring, and operations
  - Unified interface for managing all your services
  - Runs wherever you want it to!

- 🏢 **Enterprise-Grade Features, Developer-Friendly Interface**

  - AI/ML capabilities with integrated Jupyter notebooks and vector databases
  - Automated PostgreSQL, Redis, and MongoDB deployment and management
  - Built-in monitoring with Grafana dashboards and VictoriaMetrics
  - Secure networking with automatic SSL/TLS certificate management
  - OAuth/SSO integration with Keycloak

![README demo](static/public/images/readme-demo.gif)

## Quick Start

The fastest way to experience Batteries Included:

1. Visit [batteriesincl.com](https://www.batteriesincl.com) and create an
   account
2. Choose your installation type (cloud, local, or existing cluster)
3. Run the provided installation command
4. Access your ready-to-use infrastructure dashboard

## Features

### 🔋 Databases & Storage

- 🐘 PostgreSQL with automated backups and monitoring
- ⚡️ Redis for caching and message queues
- 🍃 MongoDB-compatible FerretDB
- 🎯 Vector database capabilities with pgvector

### 🔋 AI & Machine Learning

- 📓 Jupyter notebooks with pre-configured environments
- 🤖 Ollama for local LLM deployment (including DeepSeek, Phi-2, Nomic, and
  more)
- 🎮 GPU support and scaling (coming soon)

### 🔋 Web Services

- 🚀 Automated deployment and scaling
- 🔒 Built-in SSL/TLS certificate management
- ⚖️ Load balancing and traffic management
- 🔄 Zero-downtime updates and serverless deployment

### 🔋 Security

- 🛡️ Automated certificate management
- 🔐 OAuth/SSO integration
- 🌐 Network policies and mTLS
- 🗝️ Secure secret management

### 🔋 Monitoring

- 📊 Pre-configured Grafana dashboards
- 📈 Metrics collection with VictoriaMetrics
- 📝 Monitor all your clusters from one place!

## Installation Methods

## Manual Installation

If you want to try Batteries Included without creating an account, you can run
it locally. Note that the installation will stop working after a few hours
without being able to report status.

- Download `bi` from the
  [latest GitHub release](https://github.com/batteries-included/batteries-included/releases)
- Ensure your machine has Docker or compatible software running and configured
  (Linux is best supported)
- From `master`, run `bi start bootstrap/local.spec.json`

## Developer Setup

To get started developing or changing the code, make sure your operating system
is set up and ready to go. We recommend using a Linux machine, but our code
should work on any system with a docker daemon (or compatible) and a Unix-like
shell. We'll need a few dependencies, ASDF, and then to start a kubernetes
cluster configured for development.

### Linux Dependencies

Depending on your Linux distribution, you'll need to install the following
dependencies:

For Ubuntu/apt-based systems:

```bash
sudo apt-get install -y docker.io build-essential curl git cmake \
    libssl-dev pkg-config autoconf \
    m4 libncurses5-dev inotify-tools direnv jq

# Building and Testing deps not needed for most uses
sudo apt-get install -y chromium-browser chromium-chromedriver
```

For Fedora/dnf-based systems:

```bash
sudo dnf install -y docker gcc gcc-c++ make curl git \
    cmake openssl-devel pkgconfig autoconf m4 ncurses-devel \
    inotify-tools direnv jq

# Building/Testing deps
sudo dnf install -y chromium chromedriver
```

After installing the dependencies, ensure Docker is enabled and your user has
the right privileges:

```bash
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker
```

### MacOS Dependencies

For MacOS you will need to install the following dependencies in addition to
docker desktop or podman.

```bash
brew install cmake flock direnv
```

### `asdf` Installation

[asdf](https://asdf-vm.com/) is a version manager for multiple languages. We use
it to manage the tools that are useful in the project. You will need to install
`asdf` and a few plugins:

```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
```

Then add the following to your bash profile (other shells will vary slightly):

```bash
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash
eval "$(direnv hook bash)"
```

Then install all the needed plugins:

```bash
asdf plugin add erlang
asdf plugin add elixir
asdf plugin add nodejs
asdf plugin add golang
asdf plugin add goreleaser
asdf plugin add kubectl
asdf plugin add shfmt
asdf plugin add awscli
asdf plugin add kind
asdf install
```

## Code Organization

This monorepo contains multiple parts that come together to build the _Batteries
Included_ platform. `bix` is our development tool that helps manage the
different parts of the project.

TLDR: `bix bootstrap && bix dev`

### Static

`static` contains the code that builds and deploys
[_Batteries Included_](https://www.batteriesincl.com).

Public posts are in `static/src/content/posts`.

There are other docs pages in `static/src/content/docs`.

## Platform Umbrella

This is the main directory. It uses the
[Phoenix framework](https://phoenixframework.org/), and there are several
different Elixir applications in `platform_umbrella/apps` while the global
configuration is in `platform_umbrella/config`.

### Common UI

This is the application for shared components and UI. It is used in Control
Server Web and Home Server Web, and runs an instance of
[Storybook](https://github.com/phenixdigital/phoenix_storybook) in development.

### Control Server

This is the main ecto repo for the control server that gets installed on the
customer's kubernetes.

### Control Server Web

This is the phoenix web application. It's mostly `Phoenix.Component`,
`Phoenix.LiveComponent` and `Phoenix.LiveView`. Extensively using
[Tailwind CSS](https://tailwindcss.com/) as the styling.

### Home Server

This is the code for getting the billing usage and storing it. It will be the
centralized home server that all clusters report into for version updates and
billing.

### Home Server Web

This is the UI for billing, and starting new clusters.

## Running It

### Development

To start the development environment:

1. Initialize the Kind Kubernetes cluster, PostgreSQL services, and seed the
   databases:

```bash
bix bootstrap
```

2. Launch the web servers and background processes:

```bash
bix dev
```

This will start three web servers:

- [http://control.127-0-0-1.batrsinc.co:4000](http://control.127-0-0-1.batrsinc.co:4000) -
  Control server
- [http://home.127-0-0-1.batrsinc.co:4100](http://home.127-0-0-1.batrsinc.co:4100) -
  Home base server
- [http://common.127-0-0-1.batrsinc.co:4200](http://common.127-0-0-1.batrsinc.co:4200) -
  Common UI server

The `bix dev` command also opens an IEx console where you can explore the
process status.

### VSCode

To open the project in VSCode:

1. Navigate to the project directory:

```bash
cd batteries-included
```

2. Launch VSCode with the workspace configuration:

```bash
code .vscode/everything.code-workspace
```
