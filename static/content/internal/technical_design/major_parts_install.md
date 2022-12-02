---
title: Major Parts Tour via Install
date: '2022-11-30'
tags: ['overview', 'code', 'install', 'control-server', 'home-base']
draft: false
images: []
---

# Major Parts Tour via Install

Batteries Included's platform has four significant architectural elements. Those
are the Static, Control Server, Home Base, and CLI. Below we'll walk through
them in the same order a customer would first encounter them.

## Static

This code generates the static HTML front site for Batteries Included. It's got
the landing pages, the internal documentation, the blog posts, any documentation
we write, and the Hugo code needed to generate them.

The www website will be lots of people's first landing place. It should be
speedy loading and easy on the eyes. Lots of white space. Lots of brand
recognition through small pops of color.

If we convince them that they want to register and spin up their first instance,
it will link to the registration page on Home Base.

## Home Base

Home Base is the web app attached to home.batteriesincl.com. It's the place
where customers can sign up for Batteries Included. All billing, reporting,
onboarding new installations, centralized settings, and support are powered by
code in this application.

It's a Phoenix web app that heavily utilizes Live Views and WebSockets to
emphasize the fun, fast, and accessible nature of Batteries Included.

### Directories

- `home_base` This directory contains the structs for everything the home base
  server stores in DBS and the code to retrieve, create and mutate them.
- `home_base_web` This directory contains: The API that control-servers, CLI,
  and use The front UI for billing and billing user creation/auth/etc The front
  end for onboarding a new cluster installation (choose options -> copy pastable
  install instruction)
- `home_base_web/assets/` This directory contains the CSS and javascript of the
  home base. It also includes the tailwind CSS config.

Assuming the customer registers a new account, then configures their desired
cluster install options, they get a copy past-able command that will download,
install or upgrade and then run the bootstrap procedure via the CLI.

## CLI

This elixir app gets packaged into a fat binary, and `ZSTD` compressed. The
CLI's primary purpose is to bootstrap our complete set of tools onto a cluster
with no dependencies and no YAML.

For this, it contacts the home base to get the starting config of the cluster;
then, the CLI generates the resources needed and pushes them to Kubernetes.

The CLI should remain small and lightweight, have zero dependencies, and be
focused on installing and debugging.

### Directories

- `cli` is the code to parse command line, and to run the desired code. Because
  parsing the command line requires exiting, we put that code here and don't
  load it when developing or running servers.
- `cli_core` is the code to do anything on the command line. It's the majority
  of the cli code and used for dev bootstrapping.

## Control Server

Control Server is a Phoenix web app and OTP app. It combines the desired state
in the Postgres database, the current state in Kubernetes, the settings from the
home base, and the recent history to automate all infrastructure running on a
cluster.

We deploy it as a containerized Kubernetes 'Deployment.'

### Directories

- `control_server` is the set of struct definitions of everything held in the
  database. Including desired state, timelines, and a content addressable system
  for resources
- `control_server_web` is the web UI for everything in the control server
  binary. It's a status UI, an editing UI, and an opinionated portal to all the
  tools.
- `kube_resources` is the code for templatizing the desired resource state in
  Kubernetes. So this contains the code that says current databse settings have
  an image version at `Foo,` create a Pod with image `Foo.`
- `kube_ext` is code to make dealing with Kube more palatable.
- `kube_services` is the code that runs every OTP genserver interacting with
  Kubernetes. So watching state and putting it into ETS, or pushing a snapshot
  or desired state to Kubernetes.
