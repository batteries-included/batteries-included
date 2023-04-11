defmodule CommonCore.InstallSpec do
  @moduledoc """
  A struct to hold all information needed for
  bootstrapping a single kube cluster.
  """
  @derive Jason.Encoder
  defstruct [:kube_cluster, :target_summary, :initial_resources]

  @type t :: %__MODULE__{
          kube_cluster: map(),
          target_summary: CommonCore.StateSummary.t(),
          initial_resources: map()
        }

  def new(m) do
    struct!(__MODULE__, m)
  end
end
