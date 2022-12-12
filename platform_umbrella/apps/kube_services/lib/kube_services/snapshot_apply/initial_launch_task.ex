defmodule KubeServices.SnapshotApply.InitialLaunchTask do
  use Task
  require Logger

  alias KubeServices.SnapshotApply.Worker

  @inital_sleep :timer.seconds(10)
  @task_supervisor KubeServices.TaskSupervisor

  def start_link(_arg), do: Task.Supervisor.start_child(@task_supervisor, &run/0)

  def run do
    Logger.debug("Sleeping before starting initial snapshot apply", time: @inital_sleep)
    Process.sleep(@inital_sleep)

    job = Worker.start!()
    Logger.info("Starting job #{job.id}", id: job.id)
    :ok
  end
end
