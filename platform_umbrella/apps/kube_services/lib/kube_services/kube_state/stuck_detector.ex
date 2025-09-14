defmodule KubeServices.KubeState.StuckDetector do
  @moduledoc """

  This detector periodically compares a snapshot of the current kubestate
  with the actual kubestate in the cluster. If there are there are differences,
  above a per-configured threshold (percentage of investigated resources
  that were drifted per type), then it will create a RoboSRE issue to investigate.

  For each API version kind (e.g. Pod, Deployment, Service) there is a
  configurable percentage of resource we will explore. For example we might
  do 15% of pods and 10% of most things.

  Currently we consider resources are drifting if:

  - They exist in the snapshot but not in the cluster
  - The Resource Hash has changed.
  """

  use GenServer
  use TypedStruct

  alias KubeServices.K8s.Client

  typedstruct module: State do
    field :check_interval, integer(), default: 3_600_000
    field :last_check_time, DateTime.t()
    field :kube_state, module(), default: KubeServices.KubeState
    field :client, module(), default: Client

    def new!(opts) do
      check_interval = Keyword.get(opts, :check_interval, 3_600_000)
      kube_state = Keyword.get(opts, :kube_state, KubeServices.KubeState)
      client = Keyword.get(opts, :client, Client)

      struct!(__MODULE__,
        check_interval: check_interval,
        kube_state: kube_state,
        client: client
      )
    end
  end

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  def init(_opts) do
    {:ok, %State{}}
  end
end
