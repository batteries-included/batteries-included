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
      {"dev.json", Installation.new("dev", provider_type: :kind, usage: :internal_dev)},
      {"elliott.json", Installation.new("elliott", provider_type: :aws, usage: :internal_dev)},
      {"jason.json", Installation.new("jason", provider_type: :aws, usage: :internal_dev)},
      {"damian.json", Installation.new("damian", provider_type: :aws, usage: :internal_dev)},
      {"int_test.json", Installation.new("integration-test", provider_type: :kind, usage: :internal_int_test)}
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
