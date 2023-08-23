---
title: 'Welcome to your devserver'
date: 2023-05-09
tags: ['onboarding', 'linux']
draft: false
images: []
---

Welcome to your shiny new devserver. This cloud based linux machine should make
it easy to develop the Batteries Included platform without worrying about
dependencies.

## Prerequisites

- A ssh key. You should have an ssh key that was added to your account, we'll
  use that from now on when connecting.
- A wireguard config. You should be given this file.
- A devserver IP

## Wireguard

### Mac GUI

Install the [WireGuard](https://apps.apple.com/us/app/wireguard/id1451685025)
app. Then click the icon in the tray. Select 'Import Tunnel(s) from file' then
choose the file from pre-reqs.

### Mac Command line

If you prefer the command line then it's possible to do that. Install wireguard
`brew install wireguard-tools` Put the file in `/opt/homebrew/etc/wireguard` as
some file. For example `wg0.conf`

Run `wg-quick up wg0`

### Linux

Install wireguard.`sudo apt install wireguard` Put the provided wg config in
`/usr/local/etc/wireguard` as some file. For example `wg0.conf`

Run `wg-quick up wg0`

## SSH Config

Since our ssh is here, but we're going to be cloning from github, lets set up
ssh to forward our key agent. Add the following to your ssh config
`~/.ssh/config`

```
Host devserver
  HostName <<YOUR DEVSERVER IP>>
  User <<YOUR USERNAME>>
  ForwardAgent yes
```

## Repository

Before we can connect to a running set of the code, we need the code to be on
the devserver (hopefully this is automated soon). Lets clone the repo, then
allow direnv to work in that repository.

```sh
ssh devserver
git clone git@github.com:batteries-included/main.git
cd main
direnv allow
```

That last direnv allow should take a while. It compiles all of the dependencies
for the cli, the control server, the home server, and example projects.

## VSCode

First add the
[Remote SSH extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)

For example running the following in vscode:
`ext install ms-vscode-remote.remote-ssh`

# Success

Everything should be able to be connected now. Open Vscode Choose the Remote
Explore tab on the left. `devserver` should be an option there, and the `main`
repo should be selectable.

You can continue with the Developing section from the readme, by running
`bi bootstrap` in one shell, and after everything's ready `bi dev` in another
server.

## Limitations

There's one limitation of this currently. The kubernetes loadbalancer IP will
only be accessible on the linux machine and not on your laptop.
