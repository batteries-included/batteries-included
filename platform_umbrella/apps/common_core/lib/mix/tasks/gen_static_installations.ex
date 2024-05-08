defmodule Mix.Tasks.Gen.Static.Installations do
  @shortdoc "Just enough to get a dev cluster up and running."

  @moduledoc "Create the json for static installations that can be used during dev cluster bring up."
  use Mix.Task

  alias CommonCore.Installation
  alias CommonCore.InstallSpec

  def run(args) do
    [directory] = args

    File.mkdir_p!(directory)

    [
      # Our install that we use for dev
      {"dev.json", Installation.new!("dev", provider_type: :kind, usage: :internal_dev)},

      # An example of a dev install that customers could use for local testing
      {"local.json", Installation.new!("local", provider_type: :kind, usage: :development)},
      # AWS Clusters for testing things that require networking and other AWS services
      {"elliott.json", Installation.new!("elliott", provider_type: :aws, usage: :internal_dev)},
      # JasonT is currently working on bootstrapping the control server
      # so his aws cluster gets the control server installed in the kube cluster
      {"jason.json", Installation.new!("jason", provider_type: :aws, usage: :development)},
      {"damian.json", Installation.new!("damian", provider_type: :aws, usage: :internal_dev)},

      # Internal Integration tests
      {"int_test.json", Installation.new!("integration-test", provider_type: :kind, usage: :internal_int_test)}
    ]
    |> Enum.map(fn {name, install} ->
      {Path.join(directory, name), InstallSpec.from_installation(install)}
    end)
    |> Enum.each(fn {path, installation} ->
      write!(path, installation)
    end)
  end

  def write!(path, installation) do
    data = Jason.encode_to_iodata!(installation, pretty: true, escape: :javascript_safe)

    File.write!(path, data)
  end
end
