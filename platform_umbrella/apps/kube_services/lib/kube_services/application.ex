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
      # Start up the K8s Client connection pool
      CommonCore.ConnectionPool,
      # Start the Task Supervisor for async tasks
      {Task.Supervisor, name: @task_supervisor},
      # Start the KubeState so we know what is in the cluster
      KubeServices.KubeState.Supervisor,
      # Everything else is part of the batteries
      #
      # Each battery that needs processes will start a supervisor in
      # the batteries dynamic supervisor.
      KubeServices.Batteries
    ]
  end

  def children(_run),
    do: [
      {KubeServices.KubeState.Supervisor, [should_watch: false]},
      {KubeServices.ET.StableVersionsWorker, [home_client_pid: nil]},
      {KubeServices.SystemState, [should_refresh: false]}
    ]
end
