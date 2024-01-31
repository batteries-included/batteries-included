defmodule CommonCore.ConnectionPool do
  @moduledoc false
  use Supervisor

  alias K8s.Conn

  require Logger

  @me __MODULE__
  @default_cluster :default
  @config_application :common_core

  def start_link(opts \\ []) do
    name = name(opts)
    {:ok, pid} = result = Supervisor.start_link(__MODULE__, opts, name: name)
    Logger.debug("#{@me} Supervisor started with# #{inspect(pid)} name #{name}.")
    result
  end

  def init(opts) do
    name = name(opts)

    children = [
      {Registry, keys: :unique, name: registry_name(name)},
      {Task.Supervisor, name: task_supervisor_name(name)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def get, do: get(@me, @default_cluster)
  def get(cluster_name), do: get(@me, cluster_name)

  def get! do
    with {:ok, conn} <- get() do
      conn
    end
  end

  def get(pool_name, cluster_name) do
    connection = pool_name |> registry_name() |> Registry.lookup(cluster_name) |> List.first(nil)

    case connection do
      {_pid, connection} ->
        connection

      _ ->
        register_new(pool_name, cluster_name)
    end
  end

  defp register_new(pool_name, cluster_name) do
    registry = registry_name(pool_name)
    task_sup = task_supervisor_name(pool_name)

    conn_task =
      Task.Supervisor.async(task_sup, fn -> connection_from_name(cluster_name) end)

    with {:ok, connection} <- Task.await(conn_task),
         {:ok, _} <- Registry.register(registry, cluster_name, connection) do
      Logger.debug("Registered new Connection pool #{inspect(connection)}")
      connection
    else
      {:error, {:already_registered, _pid}} -> get_no_register(pool_name, cluster_name)
    end
  end

  defp get_no_register(pool_name, cluster_name) do
    registry = registry_name(pool_name)

    with {_pid, connection} <- registry |> Registry.lookup(cluster_name) |> List.first(nil) do
      connection
    end
  end

  defp connection_from_name(cluster_name) do
    @config_application
    |> Application.get_env(:clusters, [])
    |> Keyword.get(cluster_name, {:file, "~/.kube/config"})
    |> new_connection()
  end

  defp new_connection({:file, path}) do
    Conn.from_file(path, insecure_skip_tls_verify: true)
  end

  defp new_connection({:service_account, path}), do: Conn.from_service_account(path)
  defp new_connection(:service_account), do: Conn.from_service_account()

  defp name(opts), do: Keyword.get(opts, :name, @me)

  defp registry_name(cluster_name) when is_atom(cluster_name) do
    registry_name(Atom.to_string(cluster_name))
  end

  defp registry_name(cluster_name), do: String.to_atom("#{cluster_name}.Registry")

  defp task_supervisor_name(cluster_name) when is_atom(cluster_name) do
    task_supervisor_name(Atom.to_string(cluster_name))
  end

  defp task_supervisor_name(cluster_name), do: String.to_atom("#{cluster_name}.TaskSupervisor")
end
