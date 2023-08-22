---
title: 'Internal Dev Tools'
date: 2022-12-01
tags: ['code', 'tools', 'internal']
draft: false
images: []
---

## Bootstrap

Example:

```sh
./dev/bootstrap.sh
```

This script calls into the rust `cli` binary with auto-discovered paths and
command line arguments. The end result is calling `cli dev` that will:

- Ensure that a Kind Kubernetes cluster is started in docker
- Download an Installation spec that tells us what to start. Since bootstrap is
  for development, we don't get a real configured spec from a running `home`
  app. Instead, we get a static pre-configured version served via Netlify. See
  the Gen Static Specs section of this document
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

##

## Nuke Platform

Example:

```sh
../dev/nuke-platform.sh && mix do deps.get, compile --force, test
```

Every once in a while, there is some caching issue that will cause tests to
fail, saying some struct doesn't have a protocol implementation that it does
have. This is a bug in the compiler. It's a nagging issue that only hits
umbrella apps, so it doesn't get reproduced. (Open source developers swap repos
all the time == "Works for me")

## Nuke Clusters

Example:

```sh
./dev/nuke-clusters.sh && ./dev/bootstrap.sh
```

Sometimes things on the kind cluster get all messed up, and you don't want to
wait to see how to clean it up. What's the saying, "When you're holding a
hammer, you go looking for nails to nuke from orbit and turn everything off and
back on”? That's what this script does.

Yes, I did start my career at Microsoft. Why are you getting me sidetracked from
the Nuke Clusters discussion?

## Gen Static Specs

```sh
./dev/gen-static-specs.sh
```

While developing, we want the bootstrapping process to be stable and free from
troublesome dependencies as possible while still looking like what a customer
will see. So rather than run a home application sending the installation spec
for our dev environments, we have some pre-generated and served with the static
HTTP content via Netlify.

## Nix Tests

Nix has a check command that will perform all the checks that don't need a
database.

Example:

```sh
nix flake check
```

## Formatting

Rather than wire up markdown, shell, and rust formatters Nix gives it to us.

Example:

```sh
nix fmt
```

This command will format all source code in the directory. Elixir's formatter
doesn't play as well with treefmt. So we will need some wrapping shell script.
Until then this command formats everything except for elixir code.

### Format Elixir

Example:

```sh
cd platform_umbrella && mix format
```

## Run Mix Test

Sometimes you don't want to remember if the Test database is migrated, or you
want to see all the details on test speed or coverage. If you said yes to any of
those, do I have a deal for you? The run mix test does all that for the price of
one shell command.

Example

```
./dev/run-mix-test.sh
```

## Mix Server

The platform umbrella has 2 different Phoenix elixir servers in it. After making
a database available on the correct port (Usually via the bootstrap script or
cli command).

Example:

```sh
mix phx.server
```

## Mix Server With REPL

Elixir has an excellent command `iex` that takes an argument for what to run.
Combining this knowledge with the previous, we get a handy command.

```sh
iex -S mix phx.server
```

That will start the Phoenix servers and give you a REPL with access to the
process trees, the ETS, and the database connections.

## Dashboard

Example: The URL is usually
[http://control.127.0.0.1.ip.batteriesincl.com:4000/dashboard/home](http://control.127.0.0.1.ip.batteriesincl.com:4000/dashboard/home)

`/dashboard` will get you a view into the ecto db, the Erlang VM, the process
trees, and HTTP request logger for Phoenix. It's super cool stuff.
