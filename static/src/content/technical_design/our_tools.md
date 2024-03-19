---
title: 'Internal Dev Tools'
date: 2022-12-01
tags: ['code', 'tools', 'internal']
draft: false
images: []
---

## `bix`

We use [mission-control](https://github.com/Platonic-Systems/mission-control) to
provide consistent dev tooling.

If you're using `direnv`, you should see a menu listing all of our commands when
you enter the repo.

If not, you'll need to enter a nix shell by running something like
`nix develop`.

Example:

```sh
Available commands:

## code

  bix fmt  : Format the codebase

## dev

  bix bootstrap               : Bootstrap the dev environment
  bix build                   : Build the given flake.
  bix clean                   : Clean the working tree
  bix dev                     : Start dev environment
  bix dev-no-iex              : Start dev environment without iex
  bix force-remove-namespace  : Forcefully remove the given namespace by removing finalizers
  bix gen-static-specs        : Generate static specs
  bix nuke-test-db            : Reset test DB
  bix stop                    : Stop the kind cluster and all things
  bix uninstall               : Uninstall everything from the kube cluster

## elixir

  bix ex-deep-clean  : Really clean the elixir codebase
  bix ex-fmt         : Format elixir codebase
  bix ex-test        : Run stale tests
  bix ex-test-deep   : Run all tests with coverage and all that jazz
  bix ex-test-int    : Run integration tests. Used in CI as well.
  bix ex-test-quick  : Run tests excluding @tag slow
  bix ex-test-setup  : Run test setup
  bix ex-watch       : Watch for changes to elixir source
  bix m              : Run mix commands

## recruiting

  bix package-challenge  : Package up candidate challenge: "bix package-challenge candidate-name [destination-dir] [challenge]"
```

Most of the scripts will `set -x` if `$TRACE` is set for additional debugging
assistance.

Example:

```sh
TRACE=1 bix nuke-test-db
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

```sh
bix ex-deep-clean
```

Every once in a while, there is some caching issue that will cause tests to
fail, saying some struct doesn't have a protocol implementation that it does
have. This is a bug in the compiler. It's a nagging issue that only hits
umbrella apps, so it doesn't get reproduced. (Open source developers swap repos
all the time == "Works for me")

## Nuke Clusters

Example:

```sh
bix nuke-clusters && bix bootstrap
```

Sometimes things on the kind cluster get all messed up, and you don't want to
wait to see how to clean it up. What's the saying, "When you're holding a
hammer, you go looking for nails to nuke from orbit and turn everything off and
back on”? That's what this script does.

Yes, I did start my career at Microsoft. Why are you getting me sidetracked from
the Nuke Clusters discussion?

## Gen Static Specs

```sh
bix get-static-specs
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

```
bix ex-test
```

### Quick

There are a few tests in the codebase that take a little bit longer (roughly >
100ms). We tag those `slow` so we can identify them. We can also use the tag to
exclude those tests. This still provides pretty good coverage while saving a bit
of time.

Example

```
bix ex-test-quick
```

### Deep

Sometimes you don't want to remember if the Test database is migrated, or you
want to see all the details on test speed or coverage. If you said yes to any of
those, do I have a deal for you? The run mix test does all that for the price of
one shell command.

This is also the command that is used in CI.

Example

```
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
cd cli && bix m help test
```

## Dashboard

Example: The URL is usually
[http://control.127.0.0.1.ip.batteriesincl.com:4000/dashboard/home](http://control.127.0.0.1.ip.batteriesincl.com:4000/dashboard/home)

`/dashboard` will get you a view into the ecto db, the Erlang VM, the process
trees, and HTTP request logger for Phoenix. It's super cool stuff.
