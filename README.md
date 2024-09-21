# Welcome

Welcome to Batteries Included's all-inclusive software infrastructure platform!

In this repo, you'll find everything you need to contribute to the development.
From code and scripts to documentation and information, this is the hub of all
things Batteries Included.

To get started, make sure your operating system is set up and ready to go. We
recommend using a Linux machine, but our code should work on any system with a
docker daemon and a Unix-like shell. Follow the steps in the Set up operating
system section to get started.

Let's build something amazing together!

## Setup

### ASDF

ASDF is a version manager for multiple languages. We use it to manage the tools
that are useful in the project. You will need to install asdf and a few plugins.

#### Linux Dependencies

For ubuntu based systems you will need to install the following dependencies

```bash
sudo apt-get install -y docker.io docker-buildx build-essential curl \
    git cmake libssl-dev pkg-config autoconf m4 libncurses5-dev \
    inotify-tools direnv jq chromium-browser chromium-chromedriver
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

#### ASDF Installation

```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
```

Then add the following to your bash profile (other shells will vary slightly)

```bash
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash
eval "$(direnv hook bash)"
```

Then install all the needed software and plugins

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

## Code Orgnaization

This monorepo contains multiple parts that come togher to build the Batteries
Included platform. `bix` is our development tool that helps manage the different
parts of the project.

TLDR: `bix bootstrap && bix dev`

### Static

`static` contains the code that builds and deploys
[Batteries Included](https://www.batteriesincl.com)

Public posts are in `static/src/content/posts`

There are other docs pages in `static/src/content/docs`.

## Platform Umbrella

This is the main directory. It contains two different
[Phoenix Framework](https://phoenixframework.org/) There are different elixir
`Application`'s in `platform_umbrella/apps` while the configuration is in
`platform_ubrella/config`

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
can explore the process status

```bash
bix dev
```

Now there are two web servers accessible.
[http://control.127-0-0-1.batrsinc.co:4000](http://control.127-0-0-1.batrsinc.co:4000)
for the control server,
[http://home.127-0-0-1.batrsinc.co:4100](http://home.127-0-0-1.batrsinc.co:4100)
for the home base server, and
[http://common.127-0-0-1.batrsinc.co:4200](http://common.127-0-0-1.batrsinc.co:4200)
for the common UI server.

### VSCode

To open a fully configured editor simply cd into the main dir and then open the
everything workspace.
`cd batteries-included && code .vscode/everything.code-workspace`
