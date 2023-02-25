# Welcome

Welcome to Batteries Included's all-inclusive software infrastructure platform!
We're excited to have you as a part of our all-remote team.

In this repo, you'll find everything you need to contribute to the development
and growth of our company. From code and scripts to confidential and proprietary
information, this is the hub of all things Batteries Included.

To get started, make sure your operating system is set up and ready to go. We
recommend using a Linux machine, but our code should work on any system with a
docker daemon and a Unix-like shell. Follow the steps in the Set up operating
system section to get started.

We can't wait to see what you'll bring to the table as a member of the Batteries
Included team. Let's build something amazing together!

## Set up operating system

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

**NB** You need to either `newgrp docker` docker or log out and back in for the
group changes to be visible.

## Install Toolchains

There's a bunch of stuff needed for development and we use common community
tools to do the management of them.

### ASDF

I don't want to have to remember how to install all the dependencies. So install
asdf and it will do that for us.

```
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2

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
asdf plugin add elixir
asdf plugin add erlang
asdf plugin add hugo
asdf plugin add k9s
asdf plugin add kind
asdf plugin add kubectl
asdf plugin add nodejs
asdf plugin add rebar3
asdf plugin add zig

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

`dev/bootstrap.sh` This is the folder to start up a kubernetes cluster and
install the parts of Batteries Included that is necessary for developing or
running.

### Static

`static` contains the code that builds and deploys
[Batteries Included](https://www.batteriesincl.com)

There are other non-public pages in `static/content`

## Platform Umbrella

This is the main directory. It contains two different
[Phoenix Framework](https://phoenixframework.org/) There are different elixir
`Application`'s in `platform_umbrella/apps` while the configuration is in
`platform_ubrella/config`

### Control Server

This is the main ecto repo for the control server that gets installed on the
customer's kubernetes.

### Control Server Web

This is the phoenix web aplication. It's mostly `Phoenix.Component`,
`Phoenix.LiveComponent` and `Phoenix.LiveView`. Extensively using
[Tailwind CSS](https://tailwindcss.com/) as the styling.

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

Now there are two web servers accessible.
`http://home.127.0.0.1.ip.batteriesincl.com:4900` for the home server and
`http://control.127.0.0.1.ip.batteriesincl.com:4000` for the control server.

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
