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

## Setup

### Install Nix

Nix is what we use to ensure that all dev environments have all the software
needed. It's a packaging system and more. The Determinate Systems installer is
the recommended approach for installing.

No, seriously. We hate piping from curl and having random stuff installed on our
machines as well but you'll have some issues if you use your distro's package.
Don't say you haven't been warned!

If you are using a different installer Batteries Included will need experimental
[nix-command and flakes](https://nixos.wiki/wiki/Flakes) support turned on.

https://github.com/DeterminateSystems/nix-installer

`curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`

If you are on linux consider NixOS.

### Install Docker

Please install docker. For linux make sure to use a recent version of docker.
For mac users Rancher Desktop has been widely recommended.

If the `docker` group is present, then Docker Engine will create its socket with
that group, otherwise it's owned by root. To fix this, just add a `docker` group
and add yourself to it:

```bash
sudo groupadd docker && sudo usermod -aG docker $USER
```

**NB** You need to either `newgrp docker` docker or log out and back in for the
group changes to be visible.

### Optional: Install direnv

While it's optional it's highly recommended to use direnv. It allows easy use of
all the things nix installs.

## Code Orgnaization

### Static

`static` contains the code that builds and deploys
[Batteries Included](https://www.batteriesincl.com)

Public posts are in `static/src/content/posts`

There are other non-public pages in `static/src/content/company_docs` and
`static/src/content/technical_design`

## Platform Umbrella

This is the main directory. It contains two different
[Phoenix Framework](https://phoenixframework.org/) There are different elixir
`Application`'s in `platform_umbrella/apps` while the configuration is in
`platform_ubrella/config`

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

In one shell start the kind cluster, compile the rust bootstrap binary, run it,
installing postgres and istiod, then start a port forward to the postgres
process.

```bash
bix bootstrap
```

Then in another shell (or tmux pane) start the control, and home web servers and
background processes.

```bash
bix dev
```

Now there are two web servers accessible.
`http://home.127.0.0.1.ip.batteriesincl.com:4900` for the home server and
`http://control.127.0.0.1.ip.batteriesincl.com:4000` for the control server.

### VSCode

To open a fully configured editor simply cd into the main dir and then open the
everything workspace. `cd main && code .vscode/everything.code-workspace`
