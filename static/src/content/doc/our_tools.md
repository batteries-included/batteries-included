---
title: 'Internal Dev Tools'
description:
  Overview of development tools and utilities in the platform codebase.
tags: ['code', 'tools', 'internal']
draft: false
---

## `bix`

Example:

```sh
[2024-08-22T13:08:14-0500]: Missing script arguments
Usage: bix [-h] [-v] [-f] command [arg1...]

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info

Available commands:

**Install Related Commands**
- start             Start a new installation
- stop              Stop a running installation
- bootstrap         Bootstrap a new installation

**Phoenix Related Commands**
- dev               Start a development environment with iex
- phx-server        Start a phoenix server

**Source Commands**
- fmt               Format all code in the project
- check-fmt         Check if all code in the project is formatted
- gen-static-specs  Generate static installation specs

**Go Commands**
- go-build-bi       Build the bi binary
- go-test           Run go tests
- go-test-int       Run go integration tests
- go-update-deps    Update go dependencies
- go-clean-build    Clean the temporary BI build directory

**Elixir Commands**
- ex-test-deep      Run all tests with coverage and reset the database
- ex-test           Run all tests
- ex-lint           Run all linters (dialexir, credo, format)
- ex-credo          Run credo linter
- ex-dialyzer       Run dialyzer linter

**Docker Commands**
- build-image       Build a docker image
- push-images       Push all the container images to a registry
```

Most of the scripts will `set -x` if `$TRACE` is set for additional debugging
assistance.

Example:

```sh
TRACE=1 bin/bix go-test
```

## Bootstrap

Example:

```sh
bix bootstrap
```

This script calls into the go `bi` binary with auto-discovered paths and command
line arguments. The end result is calling `bi start` that will:

- Ensure that a Kind Kubernetes cluster is started in docker
- Create any resources needed to bootstrap the control server in the Kubernetes
  cluster
- Wait until there is a healthy master Postgres cluster.
- Start port forwarding to the master Postgres cluster on `127.0.0.1:5432`
- Write the intended database seeding state to a temp file.
- Prepare the database in that Postgres cluster for developing the elixir
  phoenix in `platform_umbrella` by doing the following (with retries for all
  steps):
  - `mix deps.get` ensuring that this works even if it's a clean clone
  - `mix compile` Elixir or mix seems to have a bug where they don't always
    compile the protocols for forms. It happens around compiling for different
    environments. Compiling this early is a workaround to solve the issue. If
    you see tests failing or other weird issues, see this document's Nuke
    Platform section.
  - `mix setup` runs the mix command that runs ecto migrations creating tables
    needed and downloading the node dependencies needed for css and js.
  - `mix seed.control` with the path to the temp file from the static install
    spec. This mimics how installs will happen without needing to package any
    docker.

## Deep clean (f.k.a Nuke Platform)

Example:

## Gen Static Specs

```sh
bix gen-static-specs
```

While developing, we want the bootstrapping process to be stable and free from
troublesome dependencies as possible while still looking like what a customer
will see. So rather than run a home application sending the installation spec
for our dev environments, we have some pre-generated

## Formatting

Rather than wire up markdown, shell, and rust formatters our command line tool
has it wired together

Example:

```sh
bix fmt
```

This command will format all source code in the directory. It uses `treefmt` for
formatting everything besides elixir and then uses `mix format`.

### Format Elixir

If you only want to format the elixir code, there's a command for that.

Example:

```sh
bix ex-fmt
```

## Run Mix Tests

### Stale

This runs "stale" tests - tests that have changed or where the output could have
changed based on your code changes. This is nice for a fast, inner-loop.

Example

```sh
bix ex-test
```

### Quick

There are a few tests in the codebase that take a little bit longer (roughly >
100ms). We tag those `slow` so we can identify them. We can also use the tag to
exclude those tests. This still provides pretty good coverage while saving a bit
of time.

Example

```sh
bix ex-test-quick
```

### Deep

Sometimes you don't want to remember if the Test database is migrated, or you
want to see all the details on test speed or coverage. If you said yes to any of
those, do I have a deal for you? The run mix test does all that for the price of
one shell command.

This is also the command that is used in CI.

Example

```sh
bix ex-test-deep
```

## Mix Server w/ REPL

The platform umbrella has 2 different Phoenix elixir servers in it. After making
a database available on the correct port (Usually via the bootstrap script or
cli command).

This also starts the elixir REPL, `iex`, with access to the process trees, ETS,
and database connections.

Example:

```sh
bix dev       # essentially, iex -S mix phx.server
```

## Mix Server Without REPL

Example:

```sh
bix dev-no-iex  # essentially, mix phx.server
```

## Mix

We provide a convenient alias for `mix` so that any mix command can be ran from
any directory in the repo.

Example:

```sh
cd bi && bix m help test
```

## Dashboard

Example: The URL is usually
[http://control.127-0-0-1.batrsinc.co:4000/dev/dashboard](http://control.127-0-0-1.batrsinc.co:4000/dev/dashboard)

`/dev/dashboard` will get you a view into the ecto db, the Erlang VM, the
process trees, and HTTP request logger for Phoenix. It's super cool stuff.
