defmodule KubeServices.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = children(start_services?())

    opts = [strategy: :one_for_one, name: KubeServices.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_services?, do: Application.get_env(:kube_services, :start_services)

  def children(true = _run) do
    conn = KubeExt.ConnectionPool.get()
    [
      {Registry, [keys: :unique, name: KubeServices.Registry.Worker]},
      {Bella.Watcher.Worker, [watcher: KubeState.NamespaceWatcher, connection: conn]},
      KubeServices.BaseServicesSupervisor,
      KubeServices.BaseServicesHydrator
    ]
  end

  def children(_run), do: []
end
