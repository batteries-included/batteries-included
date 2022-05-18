defmodule KubeServices.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias KubeExt.ConnectionPool
  alias KubeState.ResourceWatcher

  @impl true
  def start(_type, _args) do
    children = children(start_services?())

    opts = [strategy: :one_for_one, name: KubeServices.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_services?, do: Application.get_env(:kube_services, :start_services)

  def children(true = _run) do
    [
      KubeServices.Usage.Poller,
      KubeServices.SnapshotApply.Supervisor,
      KubeServices.SnapshotApply.Launcher,
      KubeServices.SnapshotApply.TimedLauncher,
      KubeServices.SnapshotApply.EventLauncher
    ] ++ resource_watchers()
  end

  def children(_run), do: []

  def resource_watchers do
    KubeState.ApiVersionKind.all_known()
    |> Enum.map(fn known ->
      {known, "ResourceWatcher.#{Macro.camelize(Atom.to_string(known))}"}
    end)
    |> Enum.map(&resource_worker_child_spec/1)
  end

  defp resource_worker_child_spec({resource_type, id}) do
    Supervisor.child_spec(
      {Bella.Watcher.Worker,
       [
         watcher: ResourceWatcher,
         connection_func: &ConnectionPool.get/0,
         should_retry_watch: true,
         extra: %{
           resource_type: resource_type,
           table_name: KubeState.default_state_table()
         }
       ]},
      id: id
    )
  end
end
