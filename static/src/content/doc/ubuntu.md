---
title: 'Ubuntu Dev prepare'
description: Set up an Ubuntu development environment for platform development.
tags: ['code', 'tools', 'internal']
---

## Install Ubuntu

Ubuntu's a nice friendly distro, so lets set it up for development.

### Install Docker

```sh
sudo apt-get update
sudo apt-get install -y docker.io docker-buildx
sudo systemctl enable docker
sudo systemctl start docker
```

### Add your user to the docker group

```sh
sudo usermod -aG docker $USER
newgrp docker
```

### Install APT packages

```sh
sudo apt install build-essential curl git cmake libssl-dev pkg-config autoconf m4 libncurses5-dev inotify-tools
```

### Install ASDF

```sh
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
```

Then add the following to your bash profile:

```sh
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash
```

### Install ASDF Plugins

```sh
asdf plugin-add erlang
asdf plugin-add elixir
asdf plugin-add nodejs
asdf plugin-add golang
asdf plugin-add shfmt
```

### Install Direnv

```sh
sudo apt install direnv
```

Then add the following to your bash profile:

```sh
eval "$(direnv hook bash)"
```

If you're using zsh, add this to your zshrc:

```sh
eval "$(direnv hook zsh)"
```

### Direnv allow

```sh
direnv allow
```

### ASDF Install all tool versions

```sh
asdf install
```
