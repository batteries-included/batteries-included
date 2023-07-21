defmodule KubeServices.PodLogs.Run do
  def hello do
    {:ok, logger_pid} =
      KubeServices.PodLogs.Logger.start_link()

    {:ok, _worker_pid} =
      KubeServices.PodLogs.Worker.start_link(
        namespace: "battery-base",
        name: "pg-control-0",
        target: logger_pid
      )

    Process.sleep(600_000)

    :world
  end
end
