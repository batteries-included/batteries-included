defmodule PodLogs do
  @moduledoc """
  Documentation for `PodLogs`.
  """

  def run(namespace, name) do
    {:ok, conn} = K8s.Conn.from_file("~/.kube/config", insecure_skip_tls_verify: true)

    {:ok, _worker_pid} =
      PodLogs.Watcher.start_link(api_version: "v1", kind: "Pod", connection: conn)

    {:ok, _worker_pid} =
      PodLogs.Watcher.start_link(api_version: "v1", kind: "Event", connection: conn)

    {:ok, _worker_pid} =
      PodLogs.LogWatcher.start_link(
        namespace: namespace,
        name: name,
        target: self(),
        connection: conn
      )

    Process.sleep(600_000)

    :world
  end
end
