defmodule KubeServices.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
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
      {Task.Supervisor, name: @task_supervisor},
      {Oban, Application.fetch_env!(:kube_services, Oban)},
      KubeServices.KubeState,
      KubeServices.Timeline,
      KubeServices.SystemState,
      KubeServices.SnapshotApply,
      KubeServices.ResourceDeleter
    ]
  end

  def children(_run), do: [KubeServices.SystemState]
end
