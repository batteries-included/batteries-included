<p align="center">
  <img src="./.github/header-dark.png#gh-dark-mode-only" />
  <img src="./.github/header-light.png#gh-light-mode-only" />
</p>

Welcome to [Batteries Included](https://www.batteriesincl.com/)—the ultimate platform for modern service development! Built on Kubernetes and open-source, our software platform gives you an incredible, all-inclusive infrastructure experience thanks to an intuitive UI and advanced automation.

In this repo, you'll find everything you need to contribute to development. From
code and scripts to documentation and information, this is the hub of all things
_Batteries Included_.

Let's build something amazing together!

## Getting Started

### Easiest Method

The easiest method is to use our hosted UI to configure an installation. Then
use the no-dependencies installation script to download our `bi` tool which will
start Kubernetes (locally via Kind or on a cloud provider via Pulumi), all open
source container based dependencies, and the Batteries Included Control Server.

- Go to [batteriesincl.com](https://www.batteriesincl.com) and
  log in or sign up for a new account.
- Create an installation choosing the Kubernetes provider (AWS, Kind, or an
  already provided cluster) and the intended use.
- Run the custom install script that will (if needed) download the latest `bi`
  version and start the installation from jwk signed by home base.

### Manual Method

If you want to try all this out for a short time without signing up, that's
possible. However, the installation will stop working after a few hours of not
being able to report status.

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

This is the main directory. It uses the [Phoenix framework](https://phoenixframework.org/), and there are several different Elixir applications in `platform_umbrella/apps` while the global configuration is in `platform_umbrella/config`.

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

To start the kind kubernetes cluster, start the services including postgres,
create the db's, and seed them with target summary.

```bash
bix bootstrap
```

Then start the control, and home web servers and background processes. This will
also open up a
[iex console](https://elixirschool.com/en/lessons/basics/iex_helpers) where you
can explore the process status:

```bash
bix dev
```

Now there are three web servers accessible:

- [http://control.127-0-0-1.batrsinc.co:4000](http://control.127-0-0-1.batrsinc.co:4000)
  for the control server,
- [http://home.127-0-0-1.batrsinc.co:4100](http://home.127-0-0-1.batrsinc.co:4100)
  for the home base server, and
- [http://common.127-0-0-1.batrsinc.co:4200](http://common.127-0-0-1.batrsinc.co:4200)
  for the common UI server.

### VSCode

To open a fully configured editor simply cd into the main dir and then open the
`everything` workspace:

`cd batteries-included && code .vscode/everything.code-workspace`
