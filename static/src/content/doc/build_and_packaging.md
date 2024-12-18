---
title: 'Build/Packaging Our Software'
description:
  Guide to building and packaging platform components with Docker and Mix
  releases.
tags: ['overview', 'code', 'production', 'build']
draft: false
---

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

### Docker Based

Control server and HomeBase also include CSS and JS that need to be packaged up
for use on the browser. Those static files then get compressed and digested. All
of this gets handled in the `Dockerfile` in `platform_umbrella`. That takes in
arguments for what binary to run and what release to build like this:

```sh
docker build --build-arg RELEASE=home_base \
  --build-arg BINARY=bin/home_base \
  -t battery/home:MY_TEST_TAG \
  platform_umbrella
```

This will need to all be pushed to a publicly accessible but authenticated
docker container host. However that is not yet ready.
