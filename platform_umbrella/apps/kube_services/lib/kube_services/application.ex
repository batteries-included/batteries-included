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

  def start_services?, do: Application.get_env(:kube_services, :start_services)

  def children(true = _run) do
    [
      CommonCore.ConnectionPool,
      {Task.Supervisor, name: @task_supervisor},
      KubeServices.RoboSRE.Registry,
      KubeServices.KubeState,
      KubeServices.Batteries
    ]
  end

  def children(_run),
    do: [
      {KubeServices.KubeState, [should_watch: false]},
      {KubeServices.ET.InstallStatusWorker, [home_client_pid: nil, install_id: nil]},
      {KubeServices.ET.StableVersionsWorker, [home_client_pid: nil]},
      {KubeServices.SystemState, [should_refresh: false]}
    ]
end
