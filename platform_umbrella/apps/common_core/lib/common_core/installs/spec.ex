defmodule CommonCore.InstallSpec do
  @moduledoc """
  A struct holding the information needed the bootstrap
  an installation of Batteries Included control server
  onto a kubernetes cluster.
  """
  use TypedStruct

  alias CommonCore.Installation

  @derive Jason.Encoder
  typedstruct do
    @typedoc ""

    field :slug, :string

    field :kube_cluster, map()
    field :target_summary, CommonCore.StateSummary.t()

    field :initial_resources, map(), default: %{}
  end

  def new(m) do
    struct!(__MODULE__, m)
  end

  def from_installation(%Installation{} = installation) do
    {:ok, target_summary} = CommonCore.StateSummary.target_summary(installation)

    initial_resources = CommonCore.Resources.BootstrapRoot.materialize(target_summary)

    new(
      slug: installation.slug,
      kube_cluster: kube_cluster(installation),
      target_summary: target_summary,
      initial_resources: initial_resources
    )
  end

  defp kube_cluster(installation) do
    Map.put(installation.kube_provider_config, :provider, installation.kube_provider)
  end
end
