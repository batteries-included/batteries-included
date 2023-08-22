---
title: 'Batteries Included Code Repository and Nix'
date: 2022-11-30
tags: ['code', 'nix', 'onboarding']
draft: false
images: []
---

# Batteries Included Code Repository and Nix

Welcome to the Batteries Included team! This document will guide you through
setting our code repository and how we use the Nix tool for software
development, building, packaging, and testing.

## What is this code?

Nix is a powerful package manager for Linux and other Unix systems, making
package management reliable and reproducible. It provides a consistent
environment for our developers, ensuring the software works the same way in
development, testing, and production.

### What is a Nix Flake?

A Nix Flake is a new feature in Nix that aims to improve the reproducibility,
composability, and discoverability of Nix projects. It's a structured, purely
functional build system that allows for easy dependency management and
composition of packages and configurations.

The Batteries Included `main` repository is a Nix Flake, which contains several
packages specified from docker images to static rust binaries. Each package in
the repo has its dependencies and build instructions, all managed by Nix.

## Installing Nix

The recommended installer for Nix is the determinate installer. On Linux, you
can do this by running the following command in your terminal:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix
| sh -s -- install
```

This command downloads the Nix installation script and runs it.

## Nix Provides a Devshell

One of the things that we use Nix for is to provide everyone the same
development environment tied to the git repository sha. No more ensuring you
used the latest docker image for this or that. No making sure you updated to the
latest, and what happens when going back in repository history?

For that, you have two options:

- Direnv
- Manual

### Manual

Nix takes the requested devshell specified in `nix/shell.nix` and the package
version in `flake.lock` and builds every library and binary needed. To get all
of those onto the `PATH` and usable, enter into the root of the `main`
repository. Then run `nix develop` to check that all versions are built, build
any missing ones, and drop you in a bash shell with all tools ready and
installed.

The manual method is easy to use as there are no dependencies. However, it's a
pain to remember and only sometimes plays nicely with vscode that will spawn
other processes that don't always inherit all the paths, or update when doing a
git pull.

#### TLDR

Run:

```
nix develop
```

### Direnv

Direnv is the alternative. It's another tool that will watch a directory's
contents and then run a script, updating the shell environment for all other
shells. The nice part of this is you install direnv once, install the vscode
addon and you are done.

#### Install direnv

We need at least 2.30.0.

Ubuntu 22.10 and later are up-to-date enough. Older ubuntu are still stuck on
2.25 and do not have the ability to work with nix.

For most ubuntus:

```
curl -sfL https://direnv.net/install.sh | bash

# Add the direnv binary to PATH
echo 'export PATH=$PATH:${HOME}/.bun/bin/' >> ~/.bashrc
echo 'export PATH=$PATH:${HOME}/.bun/bin/' >> ~/.zshrc
```

If you're on a newer version of Ubuntu then you can install via apt.

```
sudo apt install direnv
```

#### Install the Hook

Finally for direnv to run when entering a new directory, it needs to be hooked
into the shell. Installing the hook is easy just add a single line.

```
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
```

#### Allow Direnv in main

After all of that everything should work. In order to test it out, open a new
shell in the `main` repository. You should see one of two things:

- A log message saying that direnv isn't allowed. If you see that then this is
  the first time you are running the contents of .envrc and it's making sure
  that you know it's about to run code. Allow it since that code comes is
  versioned here.
- Log messages saying that direnv was loaded and it changed a bunch of
  environment variables.

#### Setup `cachix`

We have a binary cache of everything that's build on `master`. You may use this
cache to speed up local tasks. The `cachix` tool is already installed and
available via `direnv`.

- [Sign in](https://app.cachix.org) using Github SSO.
- Create a [personal auth token](https://app.cachix.org/personal-auth-tokens)
- Use `cachix authtoken` to authenticate. You'll need to be in the main repo.
  You may paste the token as part of the command or use e.g.
  `pbpaste | cachix authtoken` to read from stdin.
- `cachix use batteries-included` to start using the cache. Depending on how you
  installed `nix`, there may be additional setup required. If that's the case,
  the command will tell you exactly what to do.
- Profit!

#### Install VSCode Extension

In order for VSCode to follow along with what nix and direnv think, install the
direnv addon: `ext install mkhl.direnv`
https://marketplace.visualstudio.com/items?itemName=mkhl.direnv

## Nix Builds Packages

The bcli package produces a statically linked rust binary cli. The
control-server package that builds an elixir release binary containing the code
needed to run our Phoenix Live View ui and Kubernetes automating processes. The
home-base package builds an elixir release binary containing the code to run our
Phoneix central server for billing, metrics, etc. The pastebin binary. A rust
binary is an example project made to deploy on knative showcasing our UI. The
pastebin-docker image. A docker image with the correct HTML and static files in
the proper place.

To build any of these with the production setting, the following command is
used:

```bash
nix build .#bcl
```

That will build the `bcli` package in the. `.` current flake. If you need extra
status log,`-L` will make this more verbose.

Please note that if you're running zsh as your shell it probably won't like the
hash character unescaped. In that case you can use quotes.

```bash
nix build '.#bcli'
```

https://stackoverflow.com/questions/12303805/oh-my-zsh-hash-pound-symbol-bad-pattern-or-match-not-found

## Nix provides tools

`nix flake check` will run check formatting, all tests except elixir (it
requires db), and ensure the dev environment is clean.

`nix fmt` This command will format all the code except the elixir code.

## Learning More About Nix

You can refer to the Zero to Nix Quick Start guide for a more comprehensive
introduction to Nix. It provides a step-by-step tutorial on how to use Nix, from
installation to advanced usage. You can access it here:
https://zero-to-nix.com/start

## Nix Packaging Code in the Repository

The Nix packaging code for the Batteries Included repository lives in the
repository's root. You'll find it in the flake. Nix and flake.lock files, as
well as in the Nix directory.

    flake.nix: This is the main file that describes the structure of our project. It contains references to all the packages in the repository and their dependencies.

    flake.lock: This file is automatically generated by Nix and contains the exact versions of all the dependencies used in the project. This ensures that everyone working on the project uses identical versions of dependencies, making the builds reproducible.

    Nix directory: This directory contains the bulk of the Nix used in the project.

Welcome aboard! We hope this guide helps you get started with our code
repository and Nix. If you have any questions or issues, please get in touch
with me.

## Upgrading Nix Dependencies

Since we use nix to build all the final packages, it also knows about the
desired versions. We rely on each languages' package manager as much as
possible.

### Update Nix Dependencies

If you want to upgrade the tools that nix provides, there's a simple nix command
to run. Be sure to run tests and formatting as new versions often cause changes.

```sh
nix flake update
nix fmt
nix flake check
```

### Update Mix Dependencies

Elixir is the only language that we can't rely 100% on the language dependency
resolution. Elixir's `mix deps.get` reaches out to the network and isn't
determinitic; so we have to specify the expected hash value of all dependencies
to nix.

That means when updating mix dependencies we need to change nix code as well.

```sh

mix hex.outdated
# Change any specified versions needed
# in mix.exs in the apps of umbrella

# Then change the .lock file
mix deps.unlock --all
mix deps.get
```

Next, in `nix/platform.nix`, change the `sha256` for `mixFodDeps` and
`mixTestFodDeps` to the fake value provided by `lib` like this:

```nix
      mixTestFodDeps = beamPackages.fetchMixDeps {
        pname = "mix-deps-platform-test";
        inherit src version LANG;
        mixEnv = "test";
        #sha256 = "TO BE RECOMPUTED";
        sha256 = lib.fakeSha256;
      };

      mixFodDeps = beamPackages.fetchMixDeps {
        pname = "mix-deps-platform";
        inherit src version LANG;
        #sha256 = "TO BE RECOMPUTED";
        sha256 = lib.fakeSha256;
      };


```

Then get nix to recompute the expected hash value, removing the fake value and
replacing it with the expected value

First find the non-test hash

```sh
nix build -L ".#control-server"
```

Then the test hash

```sh
nix flake check -L
```

Finally ending up with something like this:

```nix
      mixTestFodDeps = beamPackages.fetchMixDeps {
        pname = "mix-deps-platform-test";
        inherit src version LANG;
        mixEnv = "test";
        sha256 = "sha256-a290WCJZetXA6NIoZNQj//dDO7Pj02PTSV0IOZzOEd8=";
        #sha256 = lib.fakeSha256;
      };

      mixFodDeps = beamPackages.fetchMixDeps {
        pname = "mix-deps-platform";
        inherit src version LANG;
        sha256 = "sha256-ddfioRONtL3nfO5wp6ocX3RzRWTLElZMH3GNnZS6PoI=";
        #sha256 = lib.fakeSha256;
      };
```
