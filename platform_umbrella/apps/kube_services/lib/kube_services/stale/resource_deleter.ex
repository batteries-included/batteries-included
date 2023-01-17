defmodule KubeServices.ResourceDeleter do
  use GenServer

  alias K8s.Resource.FieldAccessors
  alias ControlServer.Stale.DeleteArchivist

  require Logger

  @me __MODULE__

  def start_link(opts) do
    {:ok, pid} = result = GenServer.start_link(@me, opts, name: @me)
    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.")
    result
  end

  @impl GenServer
  def init(opts) do
    conn_func = Keyword.get(opts, :connection_func, fn -> KubeExt.ConnectionPool.get() end)
    conn = Keyword.get_lazy(opts, :connection, conn_func)

    Logger.debug("Starting ResourceDeleter")
    {:ok, %{conn: conn}}
  end

  @spec delete(map) :: {:ok, map() | reference()} | {:error, any()}
  def delete(resource) do
    Logger.debug("delete res")
    GenServer.call(@me, {:delete, resource})
  end

  def undelete(deleted_resourcce_id) do
    GenServer.call(@me, {:undelete, deleted_resourcce_id})
  end

  @impl GenServer
  def handle_call({:delete, resource}, _from, %{conn: conn} = state) do
    Logger.debug("Delete of resource #{inspect(summarize(resource))}")
    delete_operation = K8s.Client.delete(resource)
    {:ok, _} = record_delete(conn, resource)
    {:reply, K8s.Client.run(conn, delete_operation), state}
  end

  @impl GenServer
  def handle_call({:undelete, deleted_resource_id}, _from, %{conn: conn} = state) do
    deleted_resource = DeleteArchivist.get_deleted_resource!(deleted_resource_id)

    op =
      deleted_resource.content_addressable_resource.value
      |> clean_undeleted()
      |> K8s.Client.apply()

    res = K8s.Client.run(conn, op)

    {:ok, _} = update_with_result(deleted_resource, res)

    {:reply, res, state}
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

  defp clean_undeleted(resource) do
    resource
    |> update_in([Access.key("metadata", %{})], fn meta ->
      Map.drop(meta || %{}, ~w(managedFields creationTimestamp uid resourceVersion))
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
      |> Map.drop(["battery/hash"])
      |> Map.put("battery/undeleted", "true")
    end)
    |> Map.drop(~w(status))
    |> KubeExt.CopyLabels.copy_labels_downward()
  end

  defp summarize(resource) do
    %{
      api_version: FieldAccessors.api_version(resource),
      kind: FieldAccessors.kind(resource),
      name: FieldAccessors.name(resource)
    }
  end
end
