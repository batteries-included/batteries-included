defmodule KubeServices.Application do
  @moduledoc false

  use Application

  @task_supervisor KubeServices.TaskSupervisor

  @impl Application
  def start(_type, _args) do
    should_start_services = start_services?()
    children = children(should_start_services)

    opts = [strategy: :one_for_one, name: KubeServices.Supervisor]
    res = Supervisor.start_link(children, opts)

    res
  end

  defp start_services?, do: Application.get_env(:kube_services, :start_services)

  def children(true = _run) do
    [
      CommonCore.ConnectionPool,
      {Task.Supervisor, name: @task_supervisor},
      KubeServices.KubeState,
      KubeServices.SystemState,
      KubeServices.Batteries
    ]
  end

  def children(_run),
    do: [{KubeServices.KubeState, [should_watch: false]}, {KubeServices.SystemState, [should_refresh: false]}]
end
