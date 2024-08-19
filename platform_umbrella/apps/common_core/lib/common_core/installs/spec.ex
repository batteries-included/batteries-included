defmodule CommonCore.InstallSpec do
  @moduledoc """
  A struct holding the information needed the bootstrap
  an installation of Batteries Included control server
  onto a kubernetes cluster.


  This is the specification for what should be running
  on the cluster after the installation has been started.
  It is not the input from the user though it is
  closely related.
  """
  use TypedStruct

  alias CommonCore.Installation

  @derive Jason.Encoder
  typedstruct do
    @typedoc "This is the specification of what should be running and how on the cluster."

    field :slug, :string

    # The information about what kind
    # of kubernetes cluster we are using.
    # If it's a cluster type that we are
    # responsible for staring then the field
    # will also contain the configuration.
    field :kube_cluster, map()

    # This is the summary of the target state.
    # KubeState can be ignored as it's empty
    field :target_summary, CommonCore.StateSummary.t()

    # These are the resource that are needed to get
    # bootstrapped along with the spec
    field :initial_resources, map(), default: %{}
  end

  def new(m) when is_list(m) do
    {:ok, struct!(__MODULE__, m)}
  end

  def new(%Installation{} = installation, opts \\ []) do
    case CommonCore.StateSummary.target_summary(installation, opts) do
      {:ok, target_summary} ->
        initial_resources = CommonCore.Resources.BootstrapRoot.materialize(target_summary)

        new(
          slug: installation.slug,
          kube_cluster: kube_cluster(installation),
          target_summary: target_summary,
          initial_resources: initial_resources
        )

      {:error, e} ->
        {:error, "Failed to create target summary for installation: #{inspect(installation)}: #{inspect(e)}"}
    end
  end

  def new!(%Installation{} = installation, opts \\ []), do: with({:ok, spec} <- new(installation, opts), do: spec)

  defp kube_cluster(%{kube_provider: kube_provider, kube_provider_config: config} = _installation) do
    %{provider: kube_provider, config: config}
  end
end
