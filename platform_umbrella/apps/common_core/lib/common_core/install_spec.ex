defmodule CommonCore.InstallSpec do
  @moduledoc """
  A struct holding the information needed the bootstrap
  an instalation of Batteries included control server
  onto a kubernetes cluster.
  """
  use TypedStruct

  @derive Jason.Encoder
  typedstruct do
    @typedoc ""
    field :kube_cluster, map()
    field :target_summary, CommonCore.StateSummary.t()
    field :initial_resources, map(), default: %{}
  end

  def new(m) do
    struct!(__MODULE__, m)
  end
end
