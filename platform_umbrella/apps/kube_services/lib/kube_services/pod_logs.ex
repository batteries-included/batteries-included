defmodule KubeServices.PodLogs do
  @moduledoc """
  This is the module to get access to logs of Pods running in a kubernetes cluster. It uses the `K8s.Client` under the hood to get the logs via kubernetes api server.any()

  - If you need single time access then you should look at `KubeServices.PodLogs.get_logs()`
  - If you want to get messages of each log line then look at `KubeServices.PodLogs.Worker`
  - If you want to get messages of log lines, and a starting set of recent
    logs (for example for UI display) then use `KubeServices.PodLogs.monitor()`
  """
  alias CommonCore.ApiVersionKind

  require Logger

  @spec monitor(keyword()) :: {:ok, pid, list}
  @doc """
  Monitor the log lines by spawning a `KubeServices.PodLogs.Worker` that will `send`
  each new log of a pod and get the latest set of lines.
  """
  def monitor(opts \\ [tailLines: 50]) do
    {:ok, worker_pid} = KubeServices.PodLogs.Worker.start_link(opts)
    {:ok, logs} = get_logs(opts)
    {:ok, worker_pid, logs}
  end

  def stop(pid) do
    GenServer.cast(pid, :stop_please)
  end

  @spec get_logs(keyword()) :: {:error, atom | binary | struct} | {:ok, list}
  @doc """
  Get the log of a pod specified by `namespace` and `name` default opts
  `get` the last 100 lines from the tail of the stdout logs.
  """
  def get_logs(opts \\ [tailLines: 100]) do
    conn = CommonCore.ConnectionPool.get!()

    with {:ok, log_str} <- K8s.Client.run(conn, get_operation(opts)) do
      {:ok,
       log_str
       |> decode()
       |> String.split(~r{\n+})
       |> Enum.filter(&(&1 != ""))}
    end
  end

  defp decode(b) do
    b
    |> String.chunk(:printable)
    |> Enum.filter(fn s -> String.printable?(s) end)
    |> Enum.join()
  end

  @spec get_operation(keyword()) :: K8s.Operation.t()
  defp get_operation(opts) do
    {api_version, _kind} = ApiVersionKind.from_resource_type(:pod)

    # Use name namespace and container for targeting
    {get_opts, other_params} = Keyword.split(opts, ~w|name namespace|a)

    # The target option is used for which pid to send info
    # It's never for kubernetnes
    {_bad_opts, query_params} = Keyword.split(other_params, ~w|target|a)

    # Use that to get the subresource log off of a specific pod
    #
    # This is using the convention that slashes after plural kind leads to subresource. This
    # was found after too long.
    api_version
    |> K8s.Client.get("pods/log", get_opts)
    |> Map.put(:query_params, query_params)
  end
end
