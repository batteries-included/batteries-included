---
title: Build/Packaging Our Software
date: '2022-12-21'
tags: ['overview', 'code', 'production', 'build']
draft: false
images: []
---

# Build/Packaging Our Software

## Elixir

For packaging elixir we depend on
[elixir mix releases](https://hexdocs.pm/mix/1.14/Mix.Tasks.Release.html)

These releases take an erlang distribution, dependencies, and erlang code as
input. From the input `mix release` will create a unified directory with
everything needed to run the application. Including flags for VM tuning and bash
startup scripts.

Releases are listed in the `platform_umbrella/mix.exs` in the `&releases/0`
method. There we specify overrides for configs to use in the release,
dependencies, and steps of creating the release.

To run a release you choose the build profile you want (likely prod if this is
for real use). Then we need to compile and release.

`MIX_ENV= <<YOUR_ENV>> mix do clean, compile, release <<REL_NAME>> --overwrite`

### CLI

The CLI is released as a fat binary that includes all dependencies and elixir
together. The hope is that it's a single binary with no install instructions.

In order to create a new production cli you need to cd into `platform_umbrella`.
Then run `MIX_ENV=prod mix do clean, compile, release cli --overwrite`

This runs the normal release process. Then it calls into
[`Burrito`](https://github.com/burrito-elixir/burrito) that will wrap this whole
thing into a fat binary for just about any architecture. One issue is that the
fat binary doesn't like runtime file overrides. So we can't use them here, and
have to use them for home_base and control_server instead.

The final result ends up in `platform_umbrella/burrito_out/` as
`cli_<<arch_name>>`

### Docker Based

Control server and HomeBase also include CSS and JS that need to be packaged up
for use on the browser. Those static files then get compressed and digested. All
of this gets handled in the `Dockerfile` in `platform_umbrella`. That takes in
arguments for what binary to run and what release to build like this:

```
docker build --build-arg RELEASE=home_base \
  --build-arg BINARY=bin/home_base \
  -t battery/home:MY_TEST_TAG \
  platform_umbrella
```

This will need to all be pushed to a publicly accessible but authenticated
docker container host. However that is not yet ready.
