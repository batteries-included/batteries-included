---
title: 'Gen Resource - Yaml to Elixir'
description: Convert Kubernetes YAML definitions into Elixir source modules.
tags: ['overview', 'code', 'control-server', 'yaml']
draft: false
---

Mix.Tasks.Gen.Resource is an Elixir Mix task that allows you to generate Elixir
source modules from Kubernetes resource definitions. To use
Mix.Tasks.Gen.Resource, you will need a YAML file containing Kubernetes resource
definitions.

## Example

You can generate this file by running `kubectl get -o yaml` on the command line.
Once you have your YAML file, you can use the Mix.Tasks.Gen.Resource task to
generate an Elixir source module.

```sh
# Generate a YAML dump of your Kubernetes resources in some way
$ kubectl get pods -o yaml >> kube_dump.yaml

# Use Mix.Tasks.Gen.Resource to generate an Elixir source module
$ mix gen.resource kube_dump.yaml battery_name

# Generate the module in a directory
$ mix gen.resource kube_dump.yaml directory/battery_name
```

The above will decode the YAML file, use macro expansion to generate a new
Elixir source module that utilizes `KubeExt.Builder`, and dump the
CustomResourceDefinition (CRD) to `priv/manifests` for use with
`KubeExt.IncludeResource`. The final result is an Elixir source module called
BatteryName that you can use with the [`snapshot_apply`]({< ref
"snapshot_apply" >}} "Snapshot Apply") system.

There will be some post generation cleanup. The generation should place the
resources in a consistent directory structure between the module and the source
files; however, they were not originally generated this way.
