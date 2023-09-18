defmodule KubeServices.SnapshotApply do
  @moduledoc false
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      # A GenServer to push to Kubernetes.
      #
      # Control server is always on Kubernetes. So
      # assume that this needs to be running. No
      # Wrangler needed unlike sso
      #
      # Only one of these so pushing to kube is
      # locked per apply (Though it's multi
      # threaded inside once the lock is held).
      KubeServices.SnapshotApply.KubeApply,
      # This is the worker that does umbrella snapshot starting kube or keycloak
      KubeServices.SnapshotApply.Worker,
      # A genserver that subscribes to events and re-configures the worker
      KubeServices.SnapshotApply.WorkerKeycloakWrangler,
      # A genserver the watches for failed kube applys. Starting
      # a new atempt with every increasing delays.
      KubeServices.SnapshotApply.FailedKubeLauncher,
      # A genserver that watches for database changes that
      # likely cause a deploy to be needed.
      KubeServices.SnapshotApply.EventLauncher,
      # Remove old UmbrellaSnapshot and dependent rows after they are too old.
      KubeServices.SnapshotApply.Reaper
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
