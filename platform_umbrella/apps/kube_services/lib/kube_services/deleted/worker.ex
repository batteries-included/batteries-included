defmodule KubeServices.ResourceDeleter.Worker do
  @moduledoc """
  The `KubeServices.ResourceDeleter` module is a GenServer that is responsible for deleting resources
  in a Kubernetes cluster.
  """

  use GenServer

  alias CommonCore.Resources.CopyDown
  alias CommonCore.Resources.FieldAccessors
  alias ControlServer.Deleted.DeleteArchivist

  require Logger

  @me __MODULE__

  @doc """
    Starts the `KubeServices.ResourceDeleter` GenServer with the provided options.
    Returns a tuple of `{:ok, pid}` on success.

    ## Example
    ```elixir
    {:ok, pid} = KubeServices.ResourceDeleter.start_link(conn: connection)
    ```

  """
  def start_link(opts) do
    {state_opts, genserver_opts} = Keyword.split(opts, [:conn_func, :conn])

    {:ok, pid} = result = GenServer.start_link(@me, state_opts, Keyword.merge([name: @me], genserver_opts))

    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.")
    result
  end

  @impl GenServer
  def init(opts) do
    conn_func = Keyword.get(opts, :conn_func, &CommonCore.ConnectionPool.get!/0)
    conn = Keyword.get_lazy(opts, :conn, conn_func)

    Logger.debug("Starting ResourceDeleter")
    {:ok, %{conn: conn}}
  end

  @impl GenServer
  def handle_call({:delete, nil}, _from, state) do
    Logger.debug("Delete of resource nil resource")
    {:reply, {:ok, nil}, state}
  end

  @impl GenServer
  def handle_call({:delete, resource}, _from, %{conn: conn} = state) do
    Logger.debug("Delete of resource #{inspect(FieldAccessors.summary(resource))}")
    delete_operation = K8s.Client.delete(resource)

    result =
      case record_delete(conn, resource) do
        {:ok, _} ->
          K8s.Client.run(conn, delete_operation)

        nil ->
          # The resource may have already been deleted.
          {:error, :failed_to_record}
      end

    {:reply, result, state}
  end

  @impl GenServer
  def handle_call({:undelete, deleted_resource_id}, _from, %{conn: conn} = state) do
    deleted_resource = DeleteArchivist.get_deleted_resource!(deleted_resource_id)

    res = apply_undelete(deleted_resource, conn)
    {:reply, res, state}
  end

  defp apply_undelete(deleted_resource, conn) do
    op = undelete_apply_operation(deleted_resource.document.value)

    apply_result = K8s.Client.run(conn, op)
    {:ok, _} = update_with_result(deleted_resource, apply_result)
    apply_result
  end

  defp undelete_apply_operation(resource) do
    resource
    |> clean_meta_for_undelete()
    |> K8s.Client.apply()
  end

  defp record_delete(conn, res) do
    get_operation = K8s.Client.get(res)

    case K8s.Client.run(conn, get_operation) do
      {:ok, fresh_res} ->
        {:ok, _} = DeleteArchivist.record_delete(fresh_res)

      _ ->
        nil
    end
  end

  defp update_with_result(deleted_resource, {:ok, _} = _res) do
    DeleteArchivist.update_deleted_resource(deleted_resource, %{been_undeleted: true})
  end

  defp update_with_result(deleted_resource, _res) do
    DeleteArchivist.update_deleted_resource(deleted_resource, %{been_undeleted: false})
  end

  defp clean_meta_for_undelete(resource) do
    resource
    |> update_in([Access.key("metadata", %{})], fn meta ->
      Map.drop(meta || %{}, ~w(resourceVersion generation creationTimestamp uid managedFields))
    end)
    |> update_in([Access.key("metadata", %{}), Access.key("labels", %{})], fn labels ->
      (labels || %{})
      |> Map.put("battery/managed", "false")
      |> Map.put("battery/managed.direct", "false")
      |> Map.put("battery/managed.indirect", "false")
      |> Map.put("battery/owner", "undeleted")
    end)
    |> update_in([Access.key("metadata", %{}), Access.key("annotations", %{})], fn annotations ->
      (annotations || %{})
      |> Enum.reject(fn {name, _va} -> String.starts_with?(name, "battery") end)
      |> Map.new()
    end)
    |> Map.drop(~w(status))
    |> CopyDown.copy_labels_downward()
  end
end
