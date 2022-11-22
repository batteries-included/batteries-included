# Welcome

Welcome to Batteries Included's repo. Everything to run the company should be in
here.

This is all confidential and proprietary code.

## Requirements

This code works best on a linux machine. However it should work on anything with
a docker daemon and a unix like shell.

## Set up operating system

### The Basics

Read and run the helper script in `./dev/ubuntu.sh`, it will install the
commonly used packages and other first-time stuff you might need.

### Install Docker

[Follow the Docker Engine install instructions](https://docs.docker.com/engine/install/)
Mac nerds, you'll be getting Docker Desktop and living life on your own terms.
At least you can use brew?

If the `docker` group is present, then Docker Engine will create its socket with
that group, otherwise it's owned by root. To fix this, just add a `docker` group
and add yourself to it:

```sh
sudo groupadd docker
sudo usermod -aG docker $USER
```

**NB** you'll need to either `newgrp docker` docker or log out and back in for
the group changes to be visible.

## Install Toolchains

There's a bunch of stuff (ostensibly) needed for development and we use common
community tools to do the management of them.

[Homebrew](https://brew.sh) and [ASDF](http://asdf-vm.com/) both have been
fiddled with. Install one or the other. Or both, but you're on your own

### (option 1) Homebrew

[Go install homebrew](https://docs.brew.sh/Installation)

Following that, you should be able to run the following to install the necessary
dependencies

```sh
brew install k3d k9s erlang elixir nodejs kubectl
```

### (option 2) ASDF

I don't want to have to remember how to install all the dependencies. So install
asdf and it will do that for us.

```
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.9.0

#
# Follow http://asdf-vm.com/guide/getting-started.html#_1-install-dependencies
# Or if you're using bash just do the following.
#
echo ". $HOME/.asdf/asdf.sh" >> ~/.bashrc
echo ". $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc
exec bash
```

Go to the main directory and run

```
asdf plugin add kind
asdf plugin add kubectl
asdf plugin add k9s
asdf plugin add erlang
asdf plugin add elixir
asdf plugin add nodejs
asdf plugin add hugo

asdf install
```

That should install elixir, erlang, k3d, k9s, kubectl, nodejs, and tmux. There
might be system dependencies that are needed.

### Elixir Dependencies

```
cd platform_umbrella
mix local.hex --force && \
  mix local.rebar --force && \
  mix deps.get && \
  mix deps.compile --force

```

## Code Orgnaization

### Dev

The dev folder contains scripts to use in developing and running the platform.
`dev/cloc.sh` is the script that I use to get stats about the current repo size.
Some parties have been comforted that the project is real via line count.

`dev/bootstrap.sh` This is the folder to start up a kubernetes cluster and
install the parts of Batteries Included that is necessary for developing or
running.

### Static Pages

`static_pages` contains the code that builds and deploys
[Batteries Included](https://www.batteriesincl.com)

There are other non-public pages in `static_pages/posts`

## Platform Umbrella

This is the main directory. It contains two different
[Phoenix Framework](https://phoenixframework.org/) There are different elixir
`Application`'s in `platform_umbrella/apps` while the configuration is in
`platform_ubrella/config`

#### Kube Raw Resources

These are the elixir files that contain kubernetes resources needed before the
ecto.sql connection is there. This application is shared between `cli` and
`kube_resources`.

#### Kube Resources

The main kubernetes resources. This will query ecto to get all the latest
configurations, databases, etc. It needs postgres up and running.

### Control Server

This is the main ecto repo for the control server that gets installed on the
customer's kubernetes.

### Control Server Web

This is the phoenix web aplication. It's mostly `Phoenix.Component`,
`Phoenix.LiveComponent` and `Phoenix.LiveView`. Extensively using
[Tailwind CSS](https://tailwindcss.com/) as the styling.

### Kube State

This contains all the code for getting the current kubernetes state. It doesn't
start the workers running. Instead that's done by
`platform_umbrella/apps/kube_services`

### Kube Services

These are the running processes that actually touch kubernetes. This containes
the code to sync resources, the code that starts `kube_state` watchers, and code
that reports billing usage.

### Home Server

This is the code for getting the billing usage and storing it. It will be the
centralized home server that all clusters report into for version updates and
billing.

### Home Server Web

This is the UI.

## Running It

### Development

In this method you run the elixir daeamon not in a docker container. This allows
live code changes and fast redeploys.

In one tmux pane start the k3d cluster, compile the rust bootstrap binary, run
it, installing postgres and istiod, then start a port forward to the postgres
process.

```bash
./dev/bootstrap.sh
```

Then in another tmux pane start the daeamon

```bash
cd platform_umbrella
mix do setup, phx.server
```

Now there are two web servers accessible. `http://localhost:5000` for the
control server and `http://localhost:4000` for the home server.

The drawback of this method is that no iframes work. All tools will be accessed
in their own window.

### In Cluster

This is the method of running it with `platform_umbrella/apps/control_server`
running in a container in the cluster.

```
git checkout in_cluster_demo
git rebase master
```

Open up
`platform_umbrella/apps/kube_raw_resources/lib/kube_raw_resources/battery/battery_settings.ex`
change the string next to `@contol_version` to be blank

Get the version that we want it to be

```
git describe --always --dirty --broken
```

Now put that value back in the string next to `@contol_version`

Now that we have specified the version it's time to start everything and build
the software, pushing it to the local docker registry.

```
./dev/bootstrap.sh -B
```

That will take a while, it will build and push a lot to the docker registry and
then the control server will be started. However the cluster is also starting
postgres so the total start time can take ~10 minutes.

Ater a while you should come back to control server running in your kubernetes
cluster

Assuming there haven't been any networking changes recently the server will be
available at `http://control.172.30.0.4.sslip.io/`

### Smaller Machines

If you want to conserve resources then the `dev/bootstrap.sh` script takes in a
`-S` flag with a number of servers. You can set this to 1 which should lower the
resource usage.
