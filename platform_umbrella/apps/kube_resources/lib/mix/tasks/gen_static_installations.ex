defmodule Mix.Tasks.Gen.Static.Installations do
  @moduledoc "Create the json for static installations that can be used during dev cluster bring up."
  @shortdoc "Just enough to get a dev cluster up and running."

  use Mix.Task

  alias CommonCore.StateSummary.SeedState
  alias KubeResources.ConfigGenerator
  alias CommonCore.InstallSpec

  @installations ~w(dev dev_cluster)a

  def run(args) do
    [directory] = args

    File.mkdir_p!(directory)

    @installations
    |> Enum.map(fn type ->
      {Path.join(directory, "#{type}.json"), installation(type)}
    end)
    |> Enum.each(fn {path, installation} ->
      write!(path, installation)
    end)
  end

  def write!(path, installation) do
    data = Jason.encode_to_iodata!(installation, pretty: true, escape: :javascript_safe)

    File.write!(path, data)
  end

  @doc """
  Given an installation type we generate the initial config needed
  to bootstrap. At some point this should be the same type as an API to
  home_base_web offers as a plug endpoint for customer bootstrapping.
  """
  def installation(type)

  def installation(:dev), do: dev_installation(%{provider: :kind}, SeedState.seed(:dev))

  def installation(:dev_cluster),
    do: dev_installation(%{provider: :provided}, SeedState.seed(:dev))

  def dev_installation(kube_cluster, summary) do
    res_map =
      ConfigGenerator.materialize(summary)
      |> Enum.sort_by(fn {path, _} -> path end)
      |> Map.new()

    InstallSpec.new(
      kube_cluster: kube_cluster,
      target_summary: summary,
      initial_resources: res_map
    )
  end
end
